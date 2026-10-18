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

Until the OAuth login flow is in place, pass a key from `npm run apikey -- create <email>` (run in `backend/`) as a header:

```bash
claude mcp add --transport http invoice-hub http://localhost:4000/mcp \
  --header "Authorization: Bearer ih_your_key_here"
```

Check it with `claude mcp list`. Once OAuth is available, drop the `--header` and authenticate from `/mcp` in Claude Code instead.

> With `--header`, the key is stored in your Claude Code config in plain text. Revoke it (`npm run apikey -- revoke <keyId>`) if it leaks.

### Auth behaviour

- A request without a token gets `401` with `WWW-Authenticate: Bearer resource_metadata="…"`, pointing to `/.well-known/oauth-protected-resource/mcp`. That document names the authorization server where clients log in.
- The token itself is validated by the backend on each tool call. An invalid, revoked or expired token comes back as a tool error.

## Testing without Claude

Start the server, then run `npm run inspect`. In the Inspector, choose transport **Streamable HTTP**, URL `http://localhost:4000/mcp`, and add the header `Authorization: Bearer ih_...`.

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
| `401` with "Missing access token" | No `Authorization` header was sent. Re-add the server with `--header`. |
| `INVOICE_API_URL must be set` | Missing from `mcp-server/.env` or the environment. |
| `403` "Invalid Host header" | `HOST` isn't localhost and the request's host isn't in `ALLOWED_HOSTS`. |
| `Could not reach the invoice API` | Backend not running, or wrong URL or port. |
| `Authentication failed` | Key mistyped, revoked or expired, or its user was deactivated. Issue a new key. |
| `Rate limit exceeded` | More than 60 requests per minute for this key. Wait a minute. |
