#!/usr/bin/env node
// Read-only MCP server (Streamable HTTP) that exposes the backend's integration endpoints as tools.
// Each request carries the user's own bearer token, which is forwarded to the backend as is,
// so the backend's API key auth, scopes, rate limit and audit log still apply per user.

import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StreamableHTTPServerTransport } from '@modelcontextprotocol/sdk/server/streamableHttp.js';
import { createMcpExpressApp } from '@modelcontextprotocol/sdk/server/express.js';
import { getOAuthProtectedResourceMetadataUrl } from '@modelcontextprotocol/sdk/server/auth/router.js';
import { z } from 'zod';
import { createRequire } from 'module';

// Name and version this MCP server reports to clients (not the backend's version).
const { version } = createRequire(import.meta.url)('../package.json');

const REQUEST_TIMEOUT_MS = 10_000;

// Load mcp-server/.env if present. Variables already set in the environment win.
try {
  process.loadEnvFile?.(new URL('../.env', import.meta.url));
} catch (error) {
  if (error.code !== 'ENOENT') throw error;
}

const PORT = Number(process.env.PORT) || 4000;
const HOST = process.env.HOST || '127.0.0.1';
const API_URL = process.env.INVOICE_API_URL;
// Public URL clients use to reach this server, without the /mcp path.
const PUBLIC_URL = process.env.MCP_PUBLIC_URL || `http://localhost:${PORT}`;
// Where users log in to get a token. The backend will act as the OAuth authorization server.
const AUTH_SERVER_URL = process.env.AUTH_SERVER_URL || API_URL;
// Comma-separated Host headers to accept when bound to a public interface, e.g. "mcp.invoicepro.com".
const ALLOWED_HOSTS = process.env.ALLOWED_HOSTS?.split(',').map(host => host.trim()).filter(Boolean);

if (!API_URL) {
  console.error('INVOICE_API_URL must be set.');
  process.exit(1);
}

const MCP_URL = new URL('/mcp', PUBLIC_URL);
const RESOURCE_METADATA_URL = getOAuthProtectedResourceMetadataUrl(MCP_URL);

const ERROR_PREFIXES = {
  400: 'Invalid request',
  401: 'Authentication failed (the token may be invalid, revoked or expired)',
  403: 'Permission denied',
  404: 'Not found',
  429: 'Rate limit exceeded',
};

// Calls GET /api/v1/integrations/<path> with the caller's token. Throws an Error whose
// message is safe to show to the user; the token is never included.
const apiGet = async (token, path, query = {}) => {
  const url = new URL(`${API_URL}/api/v1/integrations${path}`);
  for (const [key, value] of Object.entries(query)) {
    if (value !== undefined && value !== '') url.searchParams.set(key, String(value));
  }

  let response;
  try {
    response = await fetch(url, {
      headers: { Authorization: `Bearer ${token}`, Accept: 'application/json' },
      signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
    });
  } catch (error) {
    throw new Error(`Could not reach the invoice API: ${error.message}`);
  }

  const body = await response.json().catch(() => null);

  if (!response.ok) {
    const prefix = ERROR_PREFIXES[response.status] || `Invoice API error (HTTP ${response.status})`;
    throw new Error(body?.message ? `${prefix}: ${body.message}` : prefix);
  }
  return body;
};

const toolResult = data => ({
  content: [{ type: 'text', text: JSON.stringify(data, null, 2) }],
});

const toolError = error => ({
  isError: true,
  content: [{ type: 'text', text: error.message }],
});

// Builds a server bound to one caller's token. The transport is stateless, so a fresh
// server is created per request and tokens never leak between users.
const createServer = token => {
  const server = new McpServer({ name: 'invoice-hub', version });

  server.registerTool(
    'list_invoices',
    {
      title: 'List invoices',
      description:
        "List the user's transport invoices, newest first. Returns a summary per invoice " +
        '(number, date, customer, firm, route, total amount, payment status) and a nextCursor for paging.\n\n' +
        'Payment status values are "paid", "pending" and "partial". The filter matches one value at a time, ' +
        'so for "unpaid" invoices call this tool once with "pending" and once with "partial" and combine the results.\n\n' +
        'Dates filter on the invoice date. For "this month", pass from = first day of the current month and ' +
        'to = today, as YYYY-MM-DD. Amounts are in INR.',
      inputSchema: {
        status: z.enum(['paid', 'pending', 'partial']).optional().describe('Payment status to filter by'),
        from: z.string().optional().describe('Earliest invoice date, inclusive (YYYY-MM-DD)'),
        to: z.string().optional().describe('Latest invoice date, inclusive (YYYY-MM-DD)'),
        customer: z.string().optional().describe('Part of the customer name, case-insensitive'),
        limit: z.number().int().min(1).max(100).optional().describe('Invoices per page, 1-100 (default 20)'),
        cursor: z.string().optional().describe('nextCursor from a previous call, to fetch the next page'),
      },
      annotations: { readOnlyHint: true, openWorldHint: false },
    },
    async args => {
      try {
        const { count, nextCursor, data } = await apiGet(token, '/invoices', args);
        return toolResult({ count, nextCursor, invoices: data });
      } catch (error) {
        return toolError(error);
      }
    },
  );

  server.registerTool(
    'get_invoice',
    {
      title: 'Get invoice',
      description:
        'Get full details of one invoice: customer, firm, vehicle, route, material, weight, ' +
        'charges breakdown, total, payment method and status. Accepts the invoice id or the invoice ' +
        'number (e.g. "INV-2026-1234").',
      inputSchema: {
        id: z.string().min(1).describe('Invoice id or invoice number'),
      },
      annotations: { readOnlyHint: true, openWorldHint: false },
    },
    async ({ id }) => {
      try {
        const { data } = await apiGet(token, `/invoices/${encodeURIComponent(id)}`);
        return toolResult(data);
      } catch (error) {
        return toolError(error);
      }
    },
  );

  return server;
};

const app = createMcpExpressApp({ host: HOST, allowedHosts: ALLOWED_HOSTS });

// OAuth 2.0 Protected Resource Metadata (RFC 9728): tells clients where to log in.
const protectedResourceMetadata = (req, res) => {
  res.json({
    resource: MCP_URL.href,
    authorization_servers: [AUTH_SERVER_URL],
    scopes_supported: ['invoices:read'],
    bearer_methods_supported: ['header'],
    resource_name: 'Invoice Hub',
  });
};
app.get('/.well-known/oauth-protected-resource', protectedResourceMetadata);
app.get(new URL(RESOURCE_METADATA_URL).pathname, protectedResourceMetadata);

// A missing token gets a 401 pointing at the metadata above, which starts the client's login flow.
// The token itself is validated by the backend on each tool call.
const requireToken = (req, res, next) => {
  const authHeader = req.headers.authorization;
  const token = authHeader?.startsWith('Bearer ') ? authHeader.slice('Bearer '.length).trim() : '';

  if (!token) {
    res.set(
      'WWW-Authenticate',
      `Bearer error="invalid_token", error_description="Missing access token", resource_metadata="${RESOURCE_METADATA_URL}"`,
    );
    return res.status(401).json({ error: 'invalid_token', error_description: 'Missing access token' });
  }

  req.token = token;
  next();
};

app.post('/mcp', requireToken, async (req, res) => {
  const server = createServer(req.token);
  const transport = new StreamableHTTPServerTransport({ sessionIdGenerator: undefined });

  res.on('close', () => {
    transport.close();
    server.close();
  });

  try {
    await server.connect(transport);
    await transport.handleRequest(req, res, req.body);
  } catch (error) {
    console.error('Error handling MCP request:', error);
    if (!res.headersSent) {
      res.status(500).json({
        jsonrpc: '2.0',
        error: { code: -32603, message: 'Internal server error' },
        id: null,
      });
    }
  }
});

// Stateless server: no SSE stream to resume and no session to end.
const methodNotAllowed = (req, res) => {
  res.status(405).set('Allow', 'POST').json({
    jsonrpc: '2.0',
    error: { code: -32000, message: 'Method not allowed.' },
    id: null,
  });
};
app.get('/mcp', methodNotAllowed);
app.delete('/mcp', methodNotAllowed);

app.listen(PORT, HOST, error => {
  if (error) {
    console.error('Failed to start MCP server:', error);
    process.exit(1);
  }
  console.log(`invoice-hub MCP server listening on ${MCP_URL.href} (API: ${API_URL})`);
});
