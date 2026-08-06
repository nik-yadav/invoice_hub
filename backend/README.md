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

## 📄 License & Copyright Notice

```text
Copyright (c) 2026 Transport Invoice Pro. All Rights Reserved.
Proprietary & Confidential Software.
```
