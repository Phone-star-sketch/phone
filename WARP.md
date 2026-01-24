# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview
`phone_system_app` - A Flutter application for managing phone subscription systems and client accounts. The app supports Arabic RTL interface and runs on Web, Android, and iOS platforms.

## Technology Stack
- **Framework**: Flutter 3.3.2+ with Material 3
- **Backend**: Supabase (authentication, database, realtime)
- **State Management**: GetX
- **Language/Locale**: Arabic (RTL)

## Build & Run Commands

```bash
# Get dependencies
flutter pub get

# Run in debug mode
flutter run

# Run on specific device
flutter run -d chrome    # Web
flutter run -d android   # Android emulator

# Analyze code (uses flutter_lints)
flutter analyze

# Build for production
flutter build apk --release --no-tree-shake-icons  # Android
flutter build web --release --web-renderer html     # Web

# Generate launcher icons
flutter pub run flutter_launcher_icons
```

## Architecture

### Repository Pattern
The app uses a clean repository pattern with abstract interfaces and Supabase implementations:

```
lib/repositories/
├── {entity}/
│   ├── {entity}_repository.dart      # Abstract interface
│   └── supabase_{entity}_repository.dart  # Implementation
└── crud_mixin.dart                   # Base CRUD operations
```

Entities: `account`, `client`, `phone`, `system`, `system_type`, `log`, `profit`, `user`

### Service Layer
Backend services accessed via singleton:
```dart
BackendServices.instance.clientRepository  // Access any repository
BackendServices.instance.supabaseAuthentication  // Auth service
```

### Data Models
All models extend `Model` base class in `lib/models/`:
- Include `fromJson()` constructor and `toJson()` method
- Use static constants for column names (e.g., `static const String nameColumn = "name"`)

### View Layer Structure
```
lib/views/
├── pages/           # Full screen pages
├── widgets/         # Reusable widgets
├── bottom_sheet_dialogs/  # Modal sheets
└── *.dart          # Main view files (account_view, client_list_view, etc.)
```

### GetX Controllers
Located in `lib/controllers/` - use `Get.put()` for dependency injection and `Obx()` for reactive UI.

## Key Patterns

### Platform-Specific Code
The app has conditional logic for web vs mobile:
```dart
import 'package:flutter/foundation.dart';

if (kIsWeb) {
  // Web-specific code
} else {
  // Mobile-specific code
}
```

### Authentication Flow
Uses two-factor auth: username/password + secondary password (`secpass`). Current user accessed via `SupabaseAuthentication.myUser`.

### User Roles
Defined in `lib/services/backend/auth.dart`:
- `admin`
- `manager`
- `assistant`

## Domain Model Relationships
- **Account** → has many **Clients**
- **Client** → has many **PhoneNumbers** → each has many **Systems**
- **System** → belongs to **SystemType** (defines pricing)
- **Client** → has many **Logs** (transaction history)

## CI/CD
GitHub Actions workflow (`.github/workflows/build-android.yml`) builds:
- Beta APK (`com.foe.phone_system_app.beta`)
- Production APK (`com.foe.phone_system_app`)

Triggered on push to `main` or `ramy/updates` branches.
