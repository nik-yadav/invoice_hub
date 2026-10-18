# Invoice Hub MCP Server

A small, **read-only** [Model Context Protocol](https://modelcontextprotocol.io) server that lets Claude look up your invoices from the Transport Invoice Pro backend.

It runs as an HTTP service (Streamable HTTP, at `/mcp`). Every request carries the user's own bearer token, which is forwarded to the backend's `/api/v1/integrations` endpoints. The server never touches the database and holds no keys of its own, and a token only sees its owner's invoices.

## Tools

| Tool | What it does | Inputs |
|---|---|---|
| `list_invoices` | Lists invoices, newest first, with paging | `status` (`paid` / `pending` / `partial`), `from`, `to` (`YYYY-MM-DD`), `customer`, `limit` (1–100), `cursor` |
| `get_invoice` | Full details of one invoice | `id`: invoice id **or** invoice number |

Both tools are read-only. There are no create, update or delete tools.

## Setup

### 1. Install and configure

```bash
cd mcp-server
npm install
```

Requires Node.js 20.12 or newer. Create `mcp-server/.env`:

```bash
INVOICE_API_URL=http://localhost:3001   # backend base URL, without /api/v1
PORT=4000                               # optional, default 4000
# MCP_PUBLIC_URL=https://mcp.invoicepro.com   # public URL in production (default http://localhost:<PORT>)
# AUTH_SERVER_URL=https://api.invoicepro.com  # OAuth authorization server (default INVOICE_API_URL)
# HOST=0.0.0.0                                # bind address (default 127.0.0.1)
# ALLOWED_HOSTS=mcp.invoicepro.com            # Host headers to accept when HOST is not localhost
```

### 2. Start it

```bash
npm start      # or: npm run dev (restarts on file changes)
```

The MCP endpoint is `http://localhost:4000/mcp`. Keep the backend running too.

### 3. Connect Claude Code

Three services must be running: the backend (`backend/`, port 3001), the sign-in page (`mcp-frontend/`, `npm run dev`, port 3000) and this server.

```bash
claude mcp add --transport http invoice-hub http://localhost:4000/mcp
```

Then, in Claude Code, run `/mcp`, pick **invoice-hub** and choose **Authenticate**. A browser opens on the sign-in page, and you sign in with your Transport Invoice Pro account and allow access. Claude Code stores the tokens itself and refreshes them, so there are no keys to copy.

To disconnect, use `/mcp` → **Clear authentication**, or revoke the connection's key with `npm run apikey -- revoke <keyId>` in `backend/`. OAuth connections appear in `npm run apikey -- list <email>` under the client's name.

Keys from `npm run apikey -- create` still work, for clients without OAuth support:

```bash
claude mcp add --transport http invoice-hub http://localhost:4000/mcp \
  --header "Authorization: Bearer ih_your_key_here"
```

### How sign-in works

1. A request without a valid token gets `401` with `WWW-Authenticate: Bearer resource_metadata="…"`, which points to `/.well-known/oauth-protected-resource/mcp`. That document names the backend as the authorization server.
2. Claude Code reads the backend's `/.well-known/oauth-authorization-server` and registers itself at `/oauth/register`. Then it opens `/oauth/authorize` with PKCE.
3. The backend stores the request and redirects to the sign-in page (`MCP_FRONTEND_URL`) with `?request_id=…`. Approving signs the user in and sends the browser back to Claude Code's local callback with a one-time code.
4. Claude Code exchanges the code at `/oauth/token`. The access token is an `ih_` API key valid for 1 hour, and it comes with a 30-day refresh token. Both are rotated on every refresh.
5. On each request, this server checks the token with the backend's `/oauth/introspect`, caching the result for 60 seconds. Expired or revoked tokens get a `401`, which makes Claude Code refresh or ask you to sign in again.

## Testing without Claude

Start the server, then run `npm run inspect`. In the Inspector, choose transport **Streamable HTTP** and URL `http://localhost:4000/mcp`. Then either use its OAuth flow, or add the header `Authorization: Bearer ih_...`.

## End-to-end checklist

With the backend and this server running, and the server connected in Claude:

1. **List**: ask *"Show my pending invoices from this month."* Claude should call `list_invoices` with `status: "pending"` and this month's dates, and the results should match the app.
2. **Unpaid**: ask *"Show my unpaid invoices."* Claude should call `list_invoices` for both `pending` and `partial`.
3. **Detail**: ask *"Show me invoice INV-…"* using a real invoice number. Claude should call `get_invoice` and show the charges breakdown.
4. **Isolation**: ask for an invoice number that belongs to a **different** user. Claude should report it as not found.
5. **No sensitive data**: no response should contain user ids, street addresses, PINs, GSTIN, phone numbers or driver details.
6. **Revocation**: run `npm run apikey -- revoke <keyId>`, then ask again. Claude should report an authentication failure (the key is revoked).
7. **Audit log**: each call above should appear as a row in the `api_audit_logs` table.

## Troubleshooting

| Symptom | Likely cause |
|---|---|
| `claude mcp list` shows the server as failed | The MCP server isn't running, or the URL or port is wrong. |
| `401` and Claude Code keeps asking to authenticate | The token was revoked or the refresh token expired. Authenticate again from `/mcp`. |
| Sign-in page says the link expired | Sign-in requests last 10 minutes. Start again from `/mcp`. |
| Browser shows "The redirect URI is not registered" | Stale client registration. Run `/mcp` → **Clear authentication**, then authenticate again. |
| `INVOICE_API_URL must be set` | Missing from `mcp-server/.env` or the environment. |
| `403` "Invalid Host header" | `HOST` isn't localhost and the request's host isn't in `ALLOWED_HOSTS`. |
| `Could not reach the invoice API` | Backend not running, or wrong URL or port. |
| `Authentication failed` | Key mistyped, revoked or expired, or its user was deactivated. Issue a new key. |
| `Rate limit exceeded` | More than 60 requests per minute for this key. Wait a minute. |
