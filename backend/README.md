# Transport Invoice Pro - Node.js Express & Prisma Backend 🚚⚡

> **Node.js Express & Supabase PostgreSQL API Backend**  
> **Version**: `v1.0.0+1` (2026 Edition)  
> **Copyright**: `© 2026 Transport Invoice Pro. All rights reserved.`

---

## 📌 Features & API Capabilities

- **Multitenant User Auth**: Registration, Login, JWT authentication middleware, Logout.
- **Dynamic Profile Management**: Automatically generates user profile from registration inputs.
- **Multi-Firm Management**: User-wise CRUD for transport firm business profiles.
- **Customer Directory**: Full search support (`?search=`) and customer records.
- **Fleet Vehicle Tracking**: Vehicle status toggles (`available`, `busy`, `maintenance`).
- **Invoice & Trip Billing Engine**: Dynamic freight invoice creation, breakdown, and summaries.
- **Dashboard Analytics**: Revenue and active vehicle aggregations.
- **API Keys**: CLI-issued, read-only keys scoped per user (see [API Keys](#-api-keys)).

---

## 🛠 Tech Stack

- **Framework**: Express.js (v4.19+)
- **ORM**: Prisma ORM (`@prisma/client: ^5.18.0`)
- **Database**: Supabase PostgreSQL with Supavisor Connection Pooler
- **Auth**: JWT (`jsonwebtoken`) & password hashing (`bcryptjs`)

---

## 🚀 Running the Server

```bash
# Install dependencies
npm install

# Push Prisma schema to PostgreSQL database
npx prisma db push

# Generate Prisma Client
npx prisma generate

# Start Production API Server
npm start
```

---

## 🔑 API Keys

Read-only API keys (scope `invoices:read`) are issued from the command line. There is no UI for this.

```bash
# Create a key for a user (--name and --expires-days are optional)
npm run apikey -- create user@example.com --name "Claude Code" --expires-days 90

# List a user's keys (id, name, status, expiry, last used)
npm run apikey -- list user@example.com

# Revoke a key by id
npm run apikey -- revoke <keyId>
```

- The full key (`ih_...`) is printed **once** at creation. Only its SHA-256 hash is stored, so a lost key cannot be recovered; revoke it and create a new one.
- Revoking deactivates the key (`isActive = false`); it is not deleted.
- Keys can only be issued to existing, active users.

### Integration endpoints

Authenticate with `Authorization: Bearer ih_...`. A key only ever sees its owner's invoices.

| Endpoint | Description |
|---|---|
| `GET /api/v1/integrations/invoices` | List invoices, newest first |
| `GET /api/v1/integrations/invoices/:id` | One invoice by id **or** invoice number |

List query parameters (all optional):

| Param | Description |
|---|---|
| `status` | Exact `paymentStatus` match, e.g. `pending` |
| `from`, `to` | Filter on `invoiceDate`. `YYYY-MM-DD` or full ISO timestamp; a date-only `to` covers the whole day (UTC) |
| `customer` | Case-insensitive match on customer name |
| `limit` | 1–100, default 20 |
| `cursor` | Pass `nextCursor` from the previous page |

```bash
curl -H "Authorization: Bearer $API_KEY" \
  "http://localhost:3000/api/v1/integrations/invoices?status=pending&from=2026-10-01"
```

Responses use a fixed field allowlist: no user ids, internal ids, street addresses, PINs, GSTIN, phone numbers or driver details.

| Status | Meaning |
|---|---|
| 400 | Invalid query parameter |
| 401 | Missing, invalid, revoked or expired key, or inactive owner |
| 403 | Key lacks the `invoices:read` scope |
| 404 | Invoice not found (including invoices owned by other users) |
| 429 | More than 60 requests/minute for this key |

These endpoints are what the [MCP server](../mcp-server/README.md) calls on Claude's behalf.

Every request, including rejected ones, is recorded in the `api_audit_logs` table (key id, user id, method, path, query, status, IP, user agent, duration). API keys and response bodies are never logged.

---

## 📄 License & Copyright Notice

```text
Copyright (c) 2026 Transport Invoice Pro. All Rights Reserved.
Proprietary & Confidential Software.
```
