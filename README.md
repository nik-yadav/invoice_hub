# Transport Invoice Pro 🚚🧾

> **Enterprise Transport Management, Billing & Invoicing System**  
> **Version**: `v1.0.0+1` (2026 Edition)  
> **Copyright**: `© 2026 Transport Invoice Pro. All rights reserved.`

---

## 📌 Executive Overview

**Transport Invoice Pro** is a production-ready, full-stack enterprise transport management and invoicing platform designed for logistics operators, fleet owners, and freight forwarding businesses. It provides seamless multitenant user authentication, multi-firm profile configuration, dynamic PDF transport bill generation, real-time fleet vehicle tracking, customer directory management, and financial dashboard analytics.

---

## 🏗️ System Architecture & Technology Stack

```
invoice_hub/
├── transport_invoice_pro/     # Cross-Platform Flutter Frontend Application
└── backend/                   # Node.js, Express.js & Prisma ORM Backend API
```

### 📱 Frontend (Mobile, Desktop & Web)
- **Framework**: Flutter SDK (v3.2.0+)
- **State Management**: Flutter Riverpod (`flutter_riverpod: ^2.5.1`)
- **Navigation & Routing**: GoRouter (`go_router: ^14.2.0`)
- **Local Storage & Session Caching**: Encrypted Hive (`hive_flutter: ^1.1.0`)
- **Document Rendering**: PDF & Printing Engine (`pdf: ^3.10.10`, `printing: ^5.13.1`)
- **HTTP Client**: Centralized `ApiService` with automatic Bearer Token injection

### ⚡ Backend API Service
- **Runtime**: Node.js (v20+) & Express.js
- **Database ORM**: Prisma ORM (`@prisma/client: ^5.18.0`)
- **Cloud Database**: Supabase PostgreSQL with Supavisor Connection Pooler
- **Security & Authentication**: JSON Web Tokens (JWT) & `bcryptjs` password hashing
- **Middleware**: Custom JWT auth guard, CORS enforcer, Morgan HTTP logger, and standardized error handler

---

## ✨ Core Application Features

1. **User Authentication & Session Management**:
   - Secure Sign Up, Login, Token Refresh, Password Recovery, and Sign Out.
   - Centralized `UserSession` persistence with automatic cache clearing on account switch.

2. **Multi-Firm Management**:
   - Create and manage multiple transport business profiles under a single user account.
   - Configure Business Name, Owner Name, Phone, Email, GSTIN, PAN, Address, Logo, and Digital Signatures.
   - Set active Default Firm for rapid bill generation.

3. **Client Customer Directory**:
   - Manage customer profiles, contact numbers, delivery addresses, and GSTIN details.
   - Real-time instant search and filtering.

4. **Fleet Vehicle Tracking**:
   - Vehicle registry with vehicle numbers, truck types (Open Truck, Container, Trailer), capacity in Tons, driver contacts, insurance numbers, and fitness expiry dates.
   - Real-time fleet status toggle (`Available`, `Busy`, `Maintenance`).

5. **Transport Billing & Invoice Engine**:
   - Trip freight invoices with source & destination routing, material descriptions, freight charges, toll charges, loading/unloading fees, and dynamic custom fields.
   - PDF Invoice generation, preview, printing, and sharing.
   - Payment status tracking (`Paid`, `Pending`, `Partial`).

6. **Executive Dashboard Analytics**:
   - Aggregate metrics: Total Revenue, Monthly Earnings, Pending Balances, Active Fleet Count, and Recent Invoices.

---

## 🚀 Quick Start Guide

### Prerequisite Requirements
- **Node.js**: v18.0.0 or higher
- **Flutter SDK**: v3.2.0 or higher
- **Database**: Supabase PostgreSQL database connection

---

### 1. Backend API Server Setup

```bash
# Navigate to backend directory
cd backend

# Install Node.js dependencies
npm install

# Push database schema to Supabase PostgreSQL
npx prisma db push

# Generate Prisma Client
npx prisma generate

# Start Express Server
npm start
```
*Backend runs on `http://127.0.0.1:3001` (or `http://localhost:3001`).*

---

### 2. Frontend Application Setup

```bash
# Navigate to Flutter application directory
cd transport_invoice_pro

# Fetch Flutter dependencies
flutter pub get

# Run on connected device or simulator
flutter run
```

---

## 📜 API Endpoint Reference

| Method | Endpoint | Description | Authentication |
|--------|----------|-------------|----------------|
| `POST` | `/api/v1/auth/register` | Register new business user | Public |
| `POST` | `/api/v1/auth/login` | Authenticate user & return JWT token | Public |
| `GET` | `/api/v1/auth/me` | Fetch authenticated user profile | Required |
| `POST` | `/api/v1/auth/logout` | End user session | Required |
| `GET` | `/api/v1/profile` | Get user business details | Required |
| `PUT` | `/api/v1/profile` | Update user business profile | Required |
| `GET` | `/api/v1/firms` | List user firms | Required |
| `POST` | `/api/v1/firms` | Create transport firm | Required |
| `PUT` | `/api/v1/firms/:id` | Update transport firm | Required |
| `DELETE` | `/api/v1/firms/:id` | Delete transport firm | Required |
| `GET` | `/api/v1/customers` | List customers (supports `?search=`) | Required |
| `POST` | `/api/v1/customers` | Add customer record | Required |
| `GET` | `/api/v1/vehicles` | List vehicles (supports `?status=`) | Required |
| `POST` | `/api/v1/vehicles` | Add fleet vehicle | Required |
| `PATCH` | `/api/v1/vehicles/:id/status` | Update vehicle status | Required |
| `GET` | `/api/v1/invoices` | List invoices | Required |
| `POST` | `/api/v1/invoices` | Create transport trip invoice | Required |
| `GET` | `/api/v1/dashboard/metrics` | Executive dashboard analytics | Required |

---

## 📄 License & Copyright Notice

```text
===========================================================================
Copyright (c) 2026 Transport Invoice Pro. All Rights Reserved.

PROPRIETARY AND CONFIDENTIAL.
This software and associated documentation files contain proprietary 
trade secrets and intellectual property. Unauthorized copying, 
distribution, modification, or public display of this software is 
strictly prohibited without prior written consent.
===========================================================================
```
