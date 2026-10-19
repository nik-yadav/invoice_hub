import bcrypt from 'bcryptjs';
import crypto from 'crypto';
import { prisma } from '../config/prisma.js';
import { generateApiKey, hashApiKey } from '../services/apiKeyService.js';

// OAuth 2.1 authorization server for the MCP server: dynamic client registration (RFC 7591),
// authorization code + PKCE, refresh token rotation, revocation (RFC 7009) and
// introspection (RFC 7662). Access tokens are ordinary API keys, so apiKeyAuth accepts them.

const SUPPORTED_SCOPES = ['invoices:read'];
const REQUEST_TTL_MS = 10 * 60 * 1000; // time the user has to sign in
const CODE_TTL_MS = 60 * 1000;
const ACCESS_TOKEN_TTL_MS = 60 * 60 * 1000;
const REFRESH_TOKEN_TTL_MS = 30 * 24 * 60 * 60 * 1000;

const getIssuer = () => (process.env.OAUTH_ISSUER || `http://localhost:${process.env.PORT || 3000}`).replace(/\/$/, '');
const getSignInUrl = () => process.env.MCP_FRONTEND_URL || 'http://localhost:3000';

const randomToken = () => crypto.randomBytes(32).toString('base64url');
const sha256 = value => crypto.createHash('sha256').update(value).digest();

const oauthError = (res, status, error, description) =>
  res.status(status).json({ error, error_description: description });

const LOOPBACK_HOSTS = ['localhost', '127.0.0.1', '[::1]'];

const parseUrl = value => {
  try {
    return new URL(value);
  } catch {
    return null;
  }
};

const isLoopback = url => url.protocol === 'http:' && LOOPBACK_HOSTS.includes(url.hostname);

// Native apps like Claude Code listen on a random local port, so loopback redirects match on
// everything but the port (RFC 8252 section 7.3). Anything else must match exactly.
const redirectUriMatches = (registered, requested) => {
  if (registered === requested) return true;
  const a = parseUrl(registered);
  const b = parseUrl(requested);
  if (!a || !b || !isLoopback(a) || !isLoopback(b)) return false;
  return a.hostname === b.hostname && a.pathname === b.pathname && a.search === b.search;
};

const withParams = (base, params) => {
  const url = new URL(base);
  for (const [key, value] of Object.entries(params)) {
    if (value) url.searchParams.set(key, value);
  }
  return url.toString();
};

const errorPage = (res, message) =>
  res.status(400).send(`
    <div style="font-family: Arial, sans-serif; text-align: center; padding: 50px;">
      <h1 style="color: #dc3545;">Authorization Failed ❌</h1>
      <p>${message}</p>
    </div>
  `);

// Same rules as POST /auth/login. Returns the user, or a message safe to show on the sign-in page.
const authenticateUser = async (email, password) => {
  if (!email || !password) return { error: 'Email and password are required' };

  const user = await prisma.user.findUnique({ where: { email: email.trim().toLowerCase() } });
  if (!user || !(await bcrypt.compare(password, user.password))) {
    return { error: 'Invalid email or password' };
  }
  if (!user.isActive) return { error: 'Your account has been deactivated. Please contact support.' };
  if (!user.isVerified && user.verificationToken) {
    return { error: 'Please verify your email address before signing in.' };
  }
  return { user };
};

// Pending /authorize requests the sign-in page may act on.
const findPendingRequest = id =>
  prisma.oAuthAuthorization.findFirst({
    where: { id, userId: null, usedAt: null, expiresAt: { gt: new Date() } },
    include: { client: true },
  });

// Creates the API key row that backs one OAuth connection, and the tokens for it.
const issueTokens = async ({ userId, clientId, clientName, scopes, resource }) => {
  const accessToken = generateApiKey();
  const refreshToken = randomToken();

  await prisma.apiKey.create({
    data: {
      keyHash: hashApiKey(accessToken),
      name: clientName || 'OAuth client',
      userId,
      clientId,
      scopes,
      resource,
      expiresAt: new Date(Date.now() + ACCESS_TOKEN_TTL_MS),
      refreshTokenHash: hashApiKey(refreshToken),
      refreshExpiresAt: new Date(Date.now() + REFRESH_TOKEN_TTL_MS),
    },
  });

  return tokenResponse(accessToken, refreshToken, scopes);
};

const tokenResponse = (accessToken, refreshToken, scopes) => ({
  access_token: accessToken,
  token_type: 'Bearer',
  expires_in: ACCESS_TOKEN_TTL_MS / 1000,
  refresh_token: refreshToken,
  scope: scopes.join(' '),
});

/**
 * @route   GET /.well-known/oauth-authorization-server
 * @desc    Authorization server metadata (RFC 8414)
 * @access  Public
 */
export const metadata = (req, res) => {
  const issuer = getIssuer();
  res.json({
    issuer,
    authorization_endpoint: `${issuer}/oauth/authorize`,
    token_endpoint: `${issuer}/oauth/token`,
    registration_endpoint: `${issuer}/oauth/register`,
    revocation_endpoint: `${issuer}/oauth/revoke`,
    introspection_endpoint: `${issuer}/oauth/introspect`,
    scopes_supported: SUPPORTED_SCOPES,
    response_types_supported: ['code'],
    grant_types_supported: ['authorization_code', 'refresh_token'],
    code_challenge_methods_supported: ['S256'],
    token_endpoint_auth_methods_supported: ['none'],
    revocation_endpoint_auth_methods_supported: ['none'],
  });
};

/**
 * @route   POST /oauth/register
 * @desc    Dynamic client registration (RFC 7591). Clients are public: no client secret.
 * @access  Public
 */
export const register = async (req, res, next) => {
  try {
    const { redirect_uris: redirectUris, client_name: clientName } = req.body ?? {};

    if (!Array.isArray(redirectUris) || !redirectUris.length) {
      return oauthError(res, 400, 'invalid_redirect_uri', 'redirect_uris must be a non-empty array');
    }
    for (const uri of redirectUris) {
      const url = typeof uri === 'string' ? parseUrl(uri) : null;
      if (!url || url.hash || !(isLoopback(url) || url.protocol === 'https:')) {
        return oauthError(res, 400, 'invalid_redirect_uri', 'Redirect URIs must be https or http://localhost');
      }
    }

    const client = await prisma.oAuthClient.create({
      data: {
        name: typeof clientName === 'string' ? clientName.slice(0, 100) : null,
        redirectUris,
      },
    });

    return res.status(201).json({
      client_id: client.id,
      client_id_issued_at: Math.floor(client.createdAt.getTime() / 1000),
      client_name: client.name ?? undefined,
      redirect_uris: client.redirectUris,
      grant_types: ['authorization_code', 'refresh_token'],
      response_types: ['code'],
      token_endpoint_auth_method: 'none',
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @route   GET /oauth/authorize
 * @desc    Validates the request, stores it and sends the browser to the sign-in page
 * @access  Public
 */
export const authorize = async (req, res, next) => {
  try {
    const {
      client_id: clientId,
      redirect_uri: redirectUri,
      response_type: responseType,
      code_challenge: codeChallenge,
      code_challenge_method: codeChallengeMethod,
      scope,
      state,
      resource,
    } = req.query;

    // Until client and redirect URI are known to be valid, errors are shown here, never redirected.
    const client = typeof clientId === 'string' ? await prisma.oAuthClient.findUnique({ where: { id: clientId } }) : null;
    if (!client) return errorPage(res, 'Unknown client. Try connecting again from your app.');

    if (typeof redirectUri !== 'string' || !client.redirectUris.some(uri => redirectUriMatches(uri, redirectUri))) {
      return errorPage(res, 'The redirect URI is not registered for this client.');
    }

    const fail = (error, description) =>
      res.redirect(withParams(redirectUri, { error, error_description: description, state }));

    if (responseType !== 'code') return fail('unsupported_response_type', 'response_type must be code');
    if (typeof codeChallenge !== 'string' || !codeChallenge || codeChallengeMethod !== 'S256') {
      return fail('invalid_request', 'PKCE with code_challenge_method S256 is required');
    }

    const scopes = typeof scope === 'string' && scope.trim() ? [...new Set(scope.trim().split(/\s+/))] : SUPPORTED_SCOPES;
    if (!scopes.every(s => SUPPORTED_SCOPES.includes(s))) return fail('invalid_scope', 'Unsupported scope requested');

    if (resource !== undefined && (typeof resource !== 'string' || !parseUrl(resource))) {
      return fail('invalid_target', 'resource must be an absolute URL');
    }

    // Opportunistic cleanup, so abandoned requests and used codes don't pile up.
    prisma.oAuthAuthorization
      .deleteMany({ where: { expiresAt: { lt: new Date() } } })
      .catch(err => console.error('Failed to clean up OAuth authorizations:', err.message));

    const request = await prisma.oAuthAuthorization.create({
      data: {
        clientId: client.id,
        redirectUri,
        state: typeof state === 'string' ? state : null,
        codeChallenge,
        scopes,
        resource: resource ?? null,
        expiresAt: new Date(Date.now() + REQUEST_TTL_MS),
      },
    });

    return res.redirect(withParams(getSignInUrl(), { request_id: request.id }));
  } catch (error) {
    next(error);
  }
};

/**
 * @route   GET /oauth/requests/:id
 * @desc    What the sign-in page shows: which client is asking, and for what
 * @access  Public (the request id is an unguessable, short-lived uuid)
 */
export const getRequest = async (req, res, next) => {
  try {
    const request = await findPendingRequest(req.params.id);
    if (!request) {
      return res.status(404).json({ success: false, message: 'This sign-in link has expired. Start again from your app.' });
    }

    return res.json({
      success: true,
      clientName: request.client.name || 'An application',
      scopes: request.scopes,
      redirectHost: new URL(request.redirectUri).host,
      expiresAt: request.expiresAt,
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @route   POST /oauth/requests/:id/approve
 * @desc    Signs the user in and approves the request. Returns where to send the browser.
 * @access  Public
 */
export const approveRequest = async (req, res, next) => {
  try {
    const request = await findPendingRequest(req.params.id);
    if (!request) {
      return res.status(404).json({ success: false, message: 'This sign-in link has expired. Start again from your app.' });
    }

    const { user, error } = await authenticateUser(req.body?.email, req.body?.password);
    if (error) return res.status(401).json({ success: false, message: error });

    const code = randomToken();
    // The userId: null condition makes approval single-use, even if two submissions race.
    const { count } = await prisma.oAuthAuthorization.updateMany({
      where: { id: request.id, userId: null },
      data: { userId: user.id, codeHash: hashApiKey(code), expiresAt: new Date(Date.now() + CODE_TTL_MS) },
    });
    if (!count) {
      return res.status(409).json({ success: false, message: 'This sign-in link was already used. Start again from your app.' });
    }

    return res.json({
      success: true,
      email: user.email,
      redirectTo: withParams(request.redirectUri, { code, state: request.state }),
    });
  } catch (error) {
    next(error);
  }
};

/**
 * @route   POST /oauth/requests/:id/deny
 * @desc    The user cancelled. Returns where to send the browser.
 * @access  Public
 */
export const denyRequest = async (req, res, next) => {
  try {
    const request = await findPendingRequest(req.params.id);
    if (!request) {
      return res.status(404).json({ success: false, message: 'This sign-in link has expired.' });
    }

    await prisma.oAuthAuthorization.delete({ where: { id: request.id } });

    return res.json({
      success: true,
      redirectTo: withParams(request.redirectUri, {
        error: 'access_denied',
        error_description: 'The user cancelled sign-in',
        state: request.state,
      }),
    });
  } catch (error) {
    next(error);
  }
};

const exchangeCode = async (req, res) => {
  const { code, redirect_uri: redirectUri, client_id: clientId, code_verifier: codeVerifier } = req.body;

  if (!code || !redirectUri || !clientId || !codeVerifier) {
    return oauthError(res, 400, 'invalid_request', 'code, redirect_uri, client_id and code_verifier are required');
  }

  const grant = await prisma.oAuthAuthorization.findUnique({
    where: { codeHash: hashApiKey(String(code)) },
    include: { client: true },
  });

  if (!grant || grant.usedAt || grant.expiresAt <= new Date() || !grant.userId) {
    return oauthError(res, 400, 'invalid_grant', 'Authorization code is invalid or expired');
  }

  // Single use: mark it used before anything else can fail.
  const { count } = await prisma.oAuthAuthorization.updateMany({
    where: { id: grant.id, usedAt: null },
    data: { usedAt: new Date() },
  });
  if (!count) return oauthError(res, 400, 'invalid_grant', 'Authorization code was already used');

  if (grant.clientId !== clientId || grant.redirectUri !== redirectUri) {
    return oauthError(res, 400, 'invalid_grant', 'Authorization code was issued to another client or redirect URI');
  }

  const challenge = sha256(String(codeVerifier)).toString('base64url');
  if (challenge.length !== grant.codeChallenge.length ||
      !crypto.timingSafeEqual(Buffer.from(challenge), Buffer.from(grant.codeChallenge))) {
    return oauthError(res, 400, 'invalid_grant', 'PKCE verification failed');
  }

  const user = await prisma.user.findUnique({ where: { id: grant.userId } });
  if (!user?.isActive) return oauthError(res, 400, 'invalid_grant', 'User is inactive');

  return res.json(
    await issueTokens({
      userId: grant.userId,
      clientId: grant.clientId,
      clientName: grant.client.name,
      scopes: grant.scopes,
      resource: grant.resource,
    }),
  );
};

const refresh = async (req, res) => {
  const { refresh_token: refreshToken, client_id: clientId } = req.body;

  if (!refreshToken || !clientId) {
    return oauthError(res, 400, 'invalid_request', 'refresh_token and client_id are required');
  }

  const apiKey = await prisma.apiKey.findUnique({
    where: { refreshTokenHash: hashApiKey(String(refreshToken)) },
    include: { user: { select: { isActive: true } } },
  });

  if (!apiKey || !apiKey.isActive || apiKey.clientId !== clientId ||
      !apiKey.refreshExpiresAt || apiKey.refreshExpiresAt <= new Date() || !apiKey.user.isActive) {
    return oauthError(res, 400, 'invalid_grant', 'Refresh token is invalid, revoked or expired');
  }

  // Rotate both tokens on the same row, so the connection keeps one id and one audit trail.
  // Matching on the old hash means a refresh token can only be used once.
  const accessToken = generateApiKey();
  const newRefreshToken = randomToken();
  const { count } = await prisma.apiKey.updateMany({
    where: { id: apiKey.id, refreshTokenHash: apiKey.refreshTokenHash },
    data: {
      keyHash: hashApiKey(accessToken),
      expiresAt: new Date(Date.now() + ACCESS_TOKEN_TTL_MS),
      refreshTokenHash: hashApiKey(newRefreshToken),
      refreshExpiresAt: new Date(Date.now() + REFRESH_TOKEN_TTL_MS),
    },
  });
  if (!count) return oauthError(res, 400, 'invalid_grant', 'Refresh token was already used');

  return res.json(tokenResponse(accessToken, newRefreshToken, apiKey.scopes));
};

/**
 * @route   POST /oauth/token
 * @desc    Exchanges an authorization code or a refresh token for tokens
 * @access  Public (PKCE / refresh token prove the caller)
 */
export const token = async (req, res, next) => {
  try {
    res.set('Cache-Control', 'no-store');
    const grantType = req.body?.grant_type;

    if (grantType === 'authorization_code') return await exchangeCode(req, res);
    if (grantType === 'refresh_token') return await refresh(req, res);
    return oauthError(res, 400, 'unsupported_grant_type', 'grant_type must be authorization_code or refresh_token');
  } catch (error) {
    next(error);
  }
};

const findKeyByToken = async token => {
  const hash = hashApiKey(String(token));
  return (
    (await prisma.apiKey.findUnique({ where: { keyHash: hash }, include: { user: { select: { isActive: true } } } })) ||
    (await prisma.apiKey.findUnique({ where: { refreshTokenHash: hash }, include: { user: { select: { isActive: true } } } }))
  );
};

/**
 * @route   POST /oauth/revoke
 * @desc    Revokes an access or refresh token, and with it the whole connection (RFC 7009)
 * @access  Public (holding the token is the proof)
 */
export const revoke = async (req, res, next) => {
  try {
    const { token: value } = req.body ?? {};
    if (!value) return oauthError(res, 400, 'invalid_request', 'token is required');

    const apiKey = await findKeyByToken(value);
    if (apiKey) await prisma.apiKey.update({ where: { id: apiKey.id }, data: { isActive: false } });

    // Per RFC 7009, unknown tokens are not an error.
    return res.status(200).end();
  } catch (error) {
    next(error);
  }
};

/**
 * @route   POST /oauth/introspect
 * @desc    Token introspection (RFC 7662), used by the MCP server to validate access tokens
 * @access  Public (tokens are 256-bit random, so this can't be used to guess them)
 */
export const introspect = async (req, res, next) => {
  try {
    res.set('Cache-Control', 'no-store');
    const { token: value } = req.body ?? {};
    if (!value) return oauthError(res, 400, 'invalid_request', 'token is required');

    const apiKey = await prisma.apiKey.findUnique({
      where: { keyHash: hashApiKey(String(value)) },
      include: { user: { select: { isActive: true } } },
    });

    const active = apiKey && apiKey.isActive && apiKey.user.isActive &&
      (!apiKey.expiresAt || apiKey.expiresAt > new Date());
    if (!active) return res.json({ active: false });

    return res.json({
      active: true,
      token_type: 'Bearer',
      scope: apiKey.scopes.join(' '),
      client_id: apiKey.clientId ?? undefined,
      exp: apiKey.expiresAt ? Math.floor(apiKey.expiresAt.getTime() / 1000) : undefined,
      aud: apiKey.resource ?? undefined,
    });
  } catch (error) {
    next(error);
  }
};
