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
npm run apikey -- create user@example.com --name "Claude Desktop" --expires-days 90

# List a user's keys (id, name, status, expiry, last used)
npm run apikey -- list user@example.com

# Revoke a key by id
npm run apikey -- revoke <keyId>
```

- The full key (`ih_...`) is printed **once** at creation. Only its SHA-256 hash is stored, so a lost key cannot be recovered; revoke it and create a new one.
- Revoking deactivates the key (`isActive = false`); it is not deleted.
- Keys can only be issued to existing, active users.

---

## 📄 License & Copyright Notice

```text
Copyright (c) 2026 Transport Invoice Pro. All Rights Reserved.
Proprietary & Confidential Software.
```
