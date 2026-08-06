# Transport Invoice Pro - Node.js Express Backend

Full-featured Node.js Express & Supabase backend server for Transport Invoice Pro, supporting JWT authentication, profile management, and CRUD operations for Firms, Customers, Vehicles, Invoices, and Dashboard metrics.

## Features

- **JWT Authentication**: Sign up, Login, Logout, Current User (`/me`), Forgot Password, Reset Password.
- **Supabase Integration**: Connected using `@supabase/supabase-js` with graceful fallback handling for local offline development.
- **Firms API**: Full CRUD management with default firm selection.
- **Customers API**: Full CRUD with search support.
- **Vehicles API**: Fleet vehicle management with status updates (`available`, `busy`, `maintenance`).
- **Invoices API**: Invoice creation, filtering by date/customer/firm/status, invoice summary endpoint.
- **Dashboard API**: Real-time revenue, invoice count, and recent invoice data.
- **Security & Logging**: CORS enabled, Morgan logging, standardized error handling.

---

## Setup & Running

### 1. Install Dependencies
```bash
cd backend
npm install
```

### 2. Environment Variables
Create or update `.env`:
```env
PORT=5000
NODE_ENV=development

SUPABASE_URL=https://vbprsmfretgcwfjcomux.supabase.co
SUPABASE_ANON_KEY=your-supabase-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-supabase-service-role-key

JWT_SECRET=super-secret-jwt-key-transport-invoice-pro-2026
JWT_EXPIRES_IN=7d
```

### 3. Start Server
```bash
# Production mode
npm start

# Development mode (watch changes)
npm run dev
```

---

## API Endpoints Summary

### Authentication (`/api/v1/auth`)
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/api/v1/auth/register` | Register a new user | No |
| POST | `/api/v1/auth/login` | Log in user & return JWT | No |
| GET | `/api/v1/auth/me` | Get current user details | Yes (Bearer Token) |
| POST | `/api/v1/auth/forgot-password` | Request password reset | No |
| POST | `/api/v1/auth/reset-password` | Reset password | No |
| POST | `/api/v1/auth/logout` | Log out user | Yes |

### User Profile (`/api/v1/profile`)
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/v1/profile` | Get business profile | Yes |
| PUT | `/api/v1/profile` | Update profile details | Yes |

### Firms (`/api/v1/firms`)
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/v1/firms` | List all firms | Yes |
| GET | `/api/v1/firms/:id` | Get firm details | Yes |
| POST | `/api/v1/firms` | Create new firm | Yes |
| PUT | `/api/v1/firms/:id` | Update firm | Yes |
| PATCH | `/api/v1/firms/:id/set-default` | Set default firm | Yes |
| DELETE | `/api/v1/firms/:id` | Delete firm | Yes |

### Customers (`/api/v1/customers`)
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/v1/customers` | List all customers (`?search=`) | Yes |
| GET | `/api/v1/customers/:id` | Get customer by ID | Yes |
| POST | `/api/v1/customers` | Create new customer | Yes |
| PUT | `/api/v1/customers/:id` | Update customer | Yes |
| DELETE | `/api/v1/customers/:id` | Delete customer | Yes |

### Vehicles (`/api/v1/vehicles`)
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/v1/vehicles` | List vehicles (`?status=`) | Yes |
| GET | `/api/v1/vehicles/:id` | Get vehicle details | Yes |
| POST | `/api/v1/vehicles` | Add new vehicle | Yes |
| PUT | `/api/v1/vehicles/:id` | Update vehicle | Yes |
| PATCH | `/api/v1/vehicles/:id/status` | Update vehicle status | Yes |
| DELETE | `/api/v1/vehicles/:id` | Delete vehicle | Yes |

### Invoices (`/api/v1/invoices`)
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/v1/invoices` | List invoices (`?status=&search=`) | Yes |
| GET | `/api/v1/invoices/:id` | Get invoice details | Yes |
| GET | `/api/v1/invoices/:id/summary` | Get invoice summary | Yes |
| POST | `/api/v1/invoices` | Create new invoice | Yes |
| PUT | `/api/v1/invoices/:id` | Update invoice | Yes |
| DELETE | `/api/v1/invoices/:id` | Delete invoice | Yes |

### Dashboard (`/api/v1/dashboard`)
| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/api/v1/dashboard/metrics` | Revenue & counts summary | Yes |
| GET | `/api/v1/dashboard/recent-invoices` | Latest invoices list | Yes |
