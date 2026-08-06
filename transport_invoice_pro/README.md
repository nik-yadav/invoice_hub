# Transport Invoice Pro - Flutter Application 🚚📱

> **Enterprise Transport Management & Invoicing Application**  
> **Version**: `v1.0.0+1` (2026 Edition)  
> **Copyright**: `© 2026 Transport Invoice Pro. All rights reserved.`

---

## 📖 Overview

The **Transport Invoice Pro** Flutter application is a cross-platform (Android, iOS, Web, macOS, Windows) client built with modern architectural principles:

- **State Management**: Riverpod (`flutter_riverpod`)
- **Navigation**: Declarative GoRouter (`go_router`)
- **Local Persistence**: Encrypted Hive (`hive_flutter`)
- **Document Engine**: PDF and Printing (`pdf`, `printing`)
- **Networking**: `http` with `ApiService` Bearer Token handler

---

## ⚡ Application Architecture

```
lib/
├── app/                  # Application bootstrap, theme, environment & routing
│   ├── app_env.dart
│   ├── app_initializer.dart
│   └── router/
├── core/                 # Core utilities, services, widgets & database setup
│   ├── constants/
│   ├── database/
│   ├── services/
│   └── widgets/
└── features/             # Feature modules (Domain-Driven Clean Architecture)
    ├── authentication/   # Login, Register, Forgot Password
    ├── customers/        # Customer directory & search
    ├── dashboard/        # Executive financial metrics & charts
    ├── firms/            # Transport firm profile manager
    ├── invoices/         # Invoices CRUD, trip billing & PDF generator
    ├── profile/          # User business profile
    ├── splash/           # Splash screen & auth routing guard
    └── vehicles/         # Fleet vehicle management & status tracking
```

---

## 🚀 Running the App

```bash
# Fetch pub dependencies
flutter pub get

# Run on web
flutter run -d chrome

# Run on macOS desktop
flutter run -d macos

# Run on mobile simulator
flutter run
```

---

## 📄 License & Copyright Notice

```text
Copyright (c) 2026 Transport Invoice Pro. All Rights Reserved.
Proprietary & Confidential Software.
```
