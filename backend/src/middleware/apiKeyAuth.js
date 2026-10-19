import { prisma } from '../config/prisma.js';
import { KEY_PREFIX, hashApiKey } from '../services/apiKeyService.js';

// Only write lastUsedAt once per minute per key, not on every request.
const LAST_USED_THROTTLE_MS = 60 * 1000;

const deny = (res, status, message) => res.status(status).json({ success: false, message });

const apiKeyAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return deny(res, 401, 'Access denied. No API key provided.');
    }

    const key = authHeader.slice('Bearer '.length).trim();
    if (!key.startsWith(KEY_PREFIX)) {
      return deny(res, 401, 'Invalid API key.');
    }

    const apiKey = await prisma.apiKey.findUnique({
      where: { keyHash: hashApiKey(key) },
      include: { user: { select: { id: true, email: true, isActive: true } } },
    });

    if (!apiKey) return deny(res, 401, 'Invalid API key.');
    if (!apiKey.isActive) return deny(res, 401, 'API key has been revoked.');
    if (apiKey.expiresAt && apiKey.expiresAt <= new Date()) return deny(res, 401, 'API key has expired.');
    if (!apiKey.user.isActive) return deny(res, 401, 'API key owner is inactive.');

    if (!apiKey.lastUsedAt || Date.now() - apiKey.lastUsedAt.getTime() > LAST_USED_THROTTLE_MS) {
      prisma.apiKey
        .update({ where: { id: apiKey.id }, data: { lastUsedAt: new Date() } })
        .catch(err => console.error('Failed to update API key lastUsedAt:', err.message));
    }

    req.apiKey = { id: apiKey.id, scopes: apiKey.scopes, accessType: apiKey.accessType };
    req.user = { id: apiKey.user.id, email: apiKey.user.email };
    next();
  } catch (error) {
    next(error);
  }
};

// Must run after apiKeyAuth.
const requireScope = scope => (req, res, next) => {
  if (!req.apiKey?.scopes.includes(scope)) {
    return deny(res, 403, `API key is missing required scope: ${scope}.`);
  }
  next();
};

export default apiKeyAuth;
export { apiKeyAuth, requireScope };
