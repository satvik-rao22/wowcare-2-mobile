# 🚀 WowCare Mobile App

<div align="center">

<img src="https://img.shields.io/badge/Flutter-3.x-blue?style=for-the-badge&logo=flutter" />
<img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart" />
<img src="https://img.shields.io/badge/Architecture-Clean%20Architecture-success?style=for-the-badge" />
<img src="https://img.shields.io/badge/State%20Management-BLoC%20%2F%20Cubit-purple?style=for-the-badge" />
<img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-orange?style=for-the-badge" />

### ✨ Enterprise Childcare Management & Attendance Platform

*A scalable enterprise Flutter application strictly built using Clean Architecture, MVVM Pattern, BLoC/Cubit State Management, Repository Pattern, Dependency Injection, Modular Feature-Based Development, and Secure API Architecture.*

</div>

---

# 📱 Application Overview

WowCare is a modern childcare and school management application designed to streamline:

* 👨‍👩‍👧 Child Management
* 🧑‍🏫 Staff Management
* 📅 Attendance Tracking
* 📍 Geofencing & Location Monitoring
* 🎵 Media & Audio Features
* 📦 Inventory & Requests
* 🔔 Notifications & Messaging
* 📊 Reports & Analytics
* 🔐 Authentication & Security
* 📷 QR Code Attendance Validation

---

# 🧠 Enterprise Architecture Overview

## 🏗️ Strict Clean Architecture + MVVM + BLoC/Cubit

```text

                    ┌─────────────────────────────┐
                    │         PRESENTATION        │
                    │─────────────────────────────│
                    │  Screens / Widgets / Pages  │
                    │  BLoC / Cubit / States      │
                    │  UI Components              │
                    └────────────┬────────────────┘
                                 │
                                 ▼
                    ┌─────────────────────────────┐
                    │           DOMAIN            │
                    │─────────────────────────────│
                    │  Entities                   │
                    │  Repository Contracts       │
                    │  UseCases                   │
                    └────────────┬────────────────┘
                                 │
                                 ▼
                    ┌─────────────────────────────┐
                    │             DATA            │
                    │─────────────────────────────│
                    │  Models                     │
                    │  Repository Implementation  │
                    │  Remote APIs                │
                    │  Local Storage              │
                    └────────────┬────────────────┘
                                 │
                                 ▼
                    ┌─────────────────────────────┐
                    │        CORE / SERVICES      │
                    │─────────────────────────────│
                    │  Network Layer              │
                    │  Secure Storage             │
                    │  Constants / Utils          │
                    │  Dependency Injection       │
                    └─────────────────────────────┘

```

---

# 🌌 3D Layered Architecture Visualization

```text

                   ╔══════════════════════════════╗
                 ╔═╝        UI LAYER             ╚═╗
               ╔═╝  Flutter Screens & Widgets      ╚═╗
             ╔═╝  Responsive UI + Animations         ╚═╗
             ╚═════════════════════════════════════════╝
                          ▲           ▲
                          │           │
                          ▼           ▼
             ╔═════════════════════════════════════════╗
           ╔═╝       STATE MANAGEMENT LAYER            ╚═╗
         ╔═╝      BLoC / Cubit / Clean Archicture      ╚═╗
         ╚═══════════════════════════════════════════════╝
                          ▲           ▲
                          │           │
                          ▼           ▼
             ╔═════════════════════════════════════════╗
           ╔═╝            DOMAIN LAYER                ╚═╗
         ╔═╝    Entities • UseCases • Repositories      ╚═╗
         ╚═══════════════════════════════════════════════╝
                          ▲           ▲
                          │           │
                          ▼           ▼
             ╔═════════════════════════════════════════╗
           ╔═╝             DATA LAYER                 ╚═╗
         ╔═╝ APIs • Models • Local DB • Cache          ╚═╗
         ╚═══════════════════════════════════════════════╝
                          ▲           ▲
                          │           │
                          ▼           ▼
             ╔═════════════════════════════════════════╗
           ╔═╝          INFRASTRUCTURE LAYER          ╚═╗
         ╔═╝  Network • Secure Storage • Services       ╚═╗
         ╚═══════════════════════════════════════════════╝

```

---

# 📂 Actual Project Folder Structure

```bash
lib/
├── app/                         # App level configuration
│   ├── di/                      # Dependency Injection setup
│   └── theme/                   # Global themes, colors, fonts
│
├── core/                        # Shared core infrastructure
│   ├── auth/                    # Session & authentication helpers
│   ├── cache/                   # Local caching services
│   ├── common/                  # Shared reusable widgets
│   ├── constants/               # Global constants
│   ├── errors/                  # Failure & exception handling
│   ├── network/                 # API client & interceptors
│   ├── storage/                 # Local storage services
│   └── util/                    # Utility/helper classes
│
├── data/                        # Data layer implementation
│   ├── features/
│   │   ├── activity/
│   │   │   ├── datasources/     # API & local data sources
│   │   │   ├── models/          # DTO/API models
│   │   │   └── repositories/    # Repository implementations
│   │   │
│   │   ├── attendance/
│   │   ├── auth/
│   │   ├── availability/
│   │   ├── classroom/
│   │   ├── communication/
│   │   ├── onboarding/
│   │   ├── scheduling/
│   │   ├── staff/
│   │   ├── student/
│   │   ├── staff_classroom/
│   │   └── student_classroom/
│   │
│   └── static/                  # Static local datasets
│
├── domain/                      # Business logic layer
│   └── features/
│       ├── activity/
│       │   ├── entities/        # Pure business entities
│       │   ├── repositories/    # Repository contracts
│       │   └── usecases/        # Business usecases
│       │
│       ├── attendance/
│       ├── auth/
│       ├── availability/
│       ├── classroom/
│       ├── communication/
│       ├── onboarding/
│       ├── scheduling/
│       ├── staff/
│       ├── student/
│       ├── staff_classroom/
│       └── student_classroom/
│
├── presentation/                # Complete UI layer
│   └── features/
│       ├── activities/
│       │   ├── cubit/           # State management
│       │   ├── view/            # Screens & UI
│       │   ├── widgets/         # Feature widgets
│       │   ├── forms/           # Forms & dialogs
│       │   ├── utils/           # Feature utilities
│       │   └── viewmodels/      # MVVM viewmodels
│       │
│       ├── attendance/
│       ├── auth/
│       ├── availability/
│       ├── billing/
│       ├── classroom/
│       ├── communication/
│       ├── dashboard/
│       ├── onboarding/
│       ├── scheduling/
│       ├── staff/
│       ├── student/
│       ├── students/
│       └── user-profile/
│
├── shared/                      # Shared reusable resources
│   ├── common/
│   │   ├── cubits/              # Global cubits
│   │   ├── views/               # Shared screens
│   │   └── widgets/             # Shared reusable widgets
│   │
│   ├── constants/
│   ├── services/
│   └── utils/
│
├── src/
│   └── app_router.dart          # Centralized app routing
│
├── firebase_options.dart        # Firebase configuration
├── main.dart                    # Application entry point
└── pubspec.yaml                 # Project dependencies
```

---

# 🧠 Detailed Architecture Explanation

## 🏗️ Why This Architecture?

This application follows a highly scalable enterprise architecture designed for:

* Large-scale Flutter applications
* Team collaboration
* Easy maintenance
* Reusable modules
* Testable business logic
* Independent feature development
* Long-term scalability

The architecture combines:

* ✅ Clean Architecture
* ✅ MVVM Pattern
* ✅ BLoC/Cubit State Management
* ✅ Repository Pattern
* ✅ Dependency Injection
* ✅ Feature-Based Modular Structure

---

# 🧩 Layer Wise Explanation

## 1️⃣ Presentation Layer

```bash
presentation/
```

This is the UI layer of the application.

### Responsibilities

* Render UI
* Handle user interaction
* Manage UI states
* Navigate between screens
* Show dialogs/snackbars/loaders

### Contains

| Folder      | Purpose                           |
| ----------- | --------------------------------- |
| cubit/      | State management using Cubit/BLoC |
| view/       | Screens & pages                   |
| widgets/    | Feature-specific widgets          |
| forms/      | Forms & bottom sheets             |
| viewmodels/ | MVVM ViewModels                   |
| utils/      | UI utilities                      |

### Example Flow

```text
User taps button
        ↓
Cubit method called
        ↓
UseCase executed
        ↓
State emitted
        ↓
UI rebuilt
```

---

## 2️⃣ Domain Layer

```bash
domain/
```

This is the pure business logic layer.

### Responsibilities

* Business rules
* Application logic
* UseCases
* Entity definitions
* Repository contracts

### Important Rule

❌ No Flutter imports
❌ No UI code
❌ No API implementation

✅ Pure Dart business logic only

### Contains

| Folder        | Purpose                       |
| ------------- | ----------------------------- |
| entities/     | Core business models          |
| repositories/ | Abstract repository contracts |
| usecases/     | Business operations           |

### Example

```text
LoginUseCase
GetAttendanceUseCase
CreateActivityUseCase
```

---

## 3️⃣ Data Layer

```bash
data/
```

Handles all external data communication.

### Responsibilities

* API calling
* Local storage
* Repository implementation
* DTO model mapping
* Remote/local datasource handling

### Contains

| Folder        | Purpose                     |
| ------------- | --------------------------- |
| datasources/  | Remote & local APIs         |
| repositories/ | Repository implementations  |
| models/       | API request/response models |
| mappers/      | Entity-model conversion     |

### Data Flow

```text
API Response
      ↓
Model Parsing
      ↓
Repository Implementation
      ↓
Entity Conversion
      ↓
UseCase
```

---

## 4️⃣ Core Layer

```bash
core/
```

Shared infrastructure used across the application.

### Responsibilities

* Networking
* Secure storage
* Cache management
* Error handling
* Session handling
* Global utilities
* API interceptors

### Important Modules

| Module   | Purpose                     |
| -------- | --------------------------- |
| network/ | API client & interceptors   |
| storage/ | Local storage services      |
| errors/  | Failure handling            |
| cache/   | Local caching               |
| auth/    | Session expiration handling |
| util/    | Shared utility helpers      |

---

## 5️⃣ Shared Layer

```bash
shared/
```

Contains globally reusable UI and services.

### Responsibilities

* Shared widgets
* Global cubits
* Responsive helpers
* Reusable dialogs
* Common components

### Examples

* Custom Buttons
* Custom Dropdowns
* App Bars
* Shared Dialogs
* Search Bars
* Shimmer Loaders
* Responsive Widgets

---

# 🔄 Complete MVVM + Clean Architecture Flow

```text
┌──────────────────────────┐
│        USER ACTION       │
└────────────┬─────────────┘
             │
             ▼
┌──────────────────────────┐
│       VIEW (SCREEN)      │
└────────────┬─────────────┘
             │
             ▼
┌──────────────────────────┐
│    CUBIT / VIEWMODEL     │
└────────────┬─────────────┘
             │
             ▼
┌──────────────────────────┐
│         USECASE          │
└────────────┬─────────────┘
             │
             ▼
┌──────────────────────────┐
│        REPOSITORY        │
└────────────┬─────────────┘
             │
             ▼
┌──────────────────────────┐
│   REMOTE / LOCAL DATA    │
└────────────┬─────────────┘
             │
             ▼
┌──────────────────────────┐
│         API / DB         │
└──────────────────────────┘
```

---

# 🏛️ Architecture Rules Followed In Entire Application

## ✅ Clean Architecture

The application strictly follows a layered Clean Architecture approach:

* Presentation Layer → UI + Cubit/BLoC
* Domain Layer → Business Logic + UseCases
* Data Layer → APIs + Repositories + Models
* Core Layer → Shared Infrastructure & Utilities

---

## ✅ MVVM Pattern

Every feature follows MVVM architecture:

```text
View
  ↓
Cubit / Bloc (ViewModel)
  ↓
UseCase
  ↓
Repository
  ↓
Datasource
```

### View Layer

Contains:

* Screens
* Widgets
* UI Components
* Forms
* Dialogs

### ViewModel Layer

Contains:

* Cubits
* Blocs
* States
* UI Business Logic

### Domain Layer

Contains:

* UseCases
* Repository Contracts
* Entities
* Business Rules

### Data Layer

Contains:

* Repository Implementations
* Remote Datasources
* Local Datasources
* DTO Models
* Mappers

---

# 🧩 State Management Standards

The entire application uses:

* ✅ Cubit
* ✅ BLoC
* ❌ No setState-based business logic
* ❌ No direct API handling inside UI
* ❌ No tightly coupled feature modules

All state handling is reactive and scalable.

---

# 🧱 Feature Module Structure

Every feature follows a modular scalable structure:

```bash
feature/
├── cubit/
├── bloc/
├── view/
├── widgets/
├── forms/
├── utils/
└── viewmodels/
```

---

# 🔄 Data Flow Architecture

```text
UI Layer
   ↓
Cubit / Bloc
   ↓
UseCase Layer
   ↓
Repository Interface
   ↓
Repository Implementation
   ↓
Remote / Local Datasource
   ↓
REST APIs / Cache / Storage
```

---

# ⚡ Dependency Injection

Dependency Injection is centralized using:

```bash
app/di/di.dart
```

Benefits:

* Loose Coupling
* Easy Testing
* Scalable Dependency Management
* Better Maintainability

---

# 🌐 Network Architecture

The network layer is fully centralized under:

```bash
core/network/
```

Includes:

* API Client
* Auth Interceptors
* Session Handling
* API Logger
* Network Info
* API Response Wrappers
* Error Handling

---

# 🗂️ Shared Component System

Reusable shared widgets are maintained under:

```bash
shared/common/widgets/
```

This ensures:

* Reusability
* UI Consistency
* Faster Development
* Modular Components
* Responsive UI Support

---

# 🎯 Scalability Principles

The application is designed for enterprise scalability:

* Modular Features
* Independent Business Domains
* Reusable Components
* Layer Separation
* Testable Architecture
* Environment-Based Configuration
* Expandable API Structure
* Multi-role User Support
* Production Ready Folder Structure

---bash
lib/
│
├── core/
│   ├── constants/
│   ├── enums/
│   ├── errors/
│   ├── extensions/
│   ├── network/
│   │   ├── api_client/
│   │   ├── interceptors/
│   │   ├── api_endpoints/
│   │   └── network_info/
│   ├── services/
│   ├── storage/
│   ├── theme/
│   ├── utils/
│   ├── widgets/
│   └── dependency_injection/
│
├── data/
│   ├── datasource/
│   │   ├── local/
│   │   └── remote/
│   ├── models/
│   ├── repositories/
│   └── mappers/
│
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
│
├── presentation/
│   ├── features/
│   │
│   │   ├── auth/
│   │   │   ├── bloc/
│   │   │   ├── cubit/
│   │   │   ├── screens/
│   │   │   ├── widgets/
│   │   │   └── viewmodels/
│   │   │
│   │   ├── attendance/
│   │   ├── dashboard/
│   │   ├── inventory/
│   │   ├── messaging/
│   │   ├── profile/
│   │   ├── requests/
│   │   └── geofencing/
│   │
│   ├── common_widgets/
│   ├── routes/
│   ├── localization/
│   └── theme/
│
├── config/
├── generated/
├── app.dart
└── main.dart

````

---

# ⚙️ Core Technical Stack

| Technology | Usage |
|---|---|
| Flutter | Cross Platform Development |
| Dart | Programming Language |
| BLoC / Cubit | State Management |
| BLoC / Cubit | Enterprise State Management |
| MVVM | Presentation Architecture |
| Clean Architecture | Scalable Application Structure |
| Dio | API Networking |
| Flutter Secure Storage | Encrypted Local Storage |
| Geolocator | Location & Geofencing |
| Firebase | Notifications & Analytics |
| Shared Preferences | Lightweight Local Storage |
| Equatable | State Comparison |
| GetIt | Dependency Injection |
| Audioplayers | Music & Audio Playback |
| Responsive Framework | Adaptive UI |

---

# 🧩 Architectural Principles

- ✅ Strict Clean Architecture Separation
- ✅ MVVM-Based Presentation Layer
- ✅ BLoC/Cubit for Predictable State Management
- ✅ Repository Pattern for Data Handling
- ✅ SOLID Principles
- ✅ Dependency Injection Architecture
- ✅ Feature-Based Modular Structure
- ✅ Reusable Shared Widgets
- ✅ Testable Business Logic
- ✅ Environment-Based Configuration
- ✅ Scalable API Layer
- ✅ Centralized Error Handling

---

# 🔐 Security Features

- ✅ JWT Authentication
- ✅ Token Refresh Mechanism
- ✅ Secure API Communication
- ✅ Encrypted Local Storage
- ✅ Role & Permission Management
- ✅ Environment-Based Configurations
- ✅ Secure Session Handling
- ✅ Request Interceptors
- ✅ Error & Exception Handling

---

# ✨ Core Features

## 👤 Authentication Module
- Login / Logout
- Role Based Access
- School Selection
- Secure Token Storage
- Session Management

## 📍 Attendance Module
- QR Attendance Validation
- Child Check-In / Check-Out
- Attendance Reports
- Geofence Detection
- Live Status Tracking

## 📦 Inventory Module
- Product Management
- Vendor Management
- Request Allocation
- Category Filtering
- Inventory Analytics

## 💬 Messaging Module
- Staff Messaging
- Parent Communication
- Real-Time Notifications

## 🎵 Audio Module
- Spotify Inspired Music Player
- Sleep Timer
- Offline Playback
- Favorite Management

## 📊 Dashboard & Reports
- Analytics Widgets
- Attendance Metrics
- Dynamic Charts
- Performance Monitoring

---

# 🛠️ Environment Configuration

## Create Environment File

```env
BASE_URL=https://your-api-url.com
API_VERSION=v1
ENV=development
````

---

# 🚀 Getting Started

## 1️⃣ Clone Repository

```bash
git clone https://github.com/your-org/wowcare.git
```

## 2️⃣ Move Into Project

```bash
cd wowcare
```

## 3️⃣ Install Dependencies

```bash
flutter pub get
```

## 4️⃣ Run Code Generation

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## 5️⃣ Run Application

```bash
flutter run
```

---

# 📦 Build APK

## Android APK

```bash
flutter build apk --release
```

## Android App Bundle

```bash
flutter build appbundle --release
```

## iOS Build

```bash
flutter build ios --release
```

---

# 🧪 Testing

## Run Unit Tests

```bash
flutter test
```

## Analyze Code

```bash
flutter analyze
```

---

# 🔄 MVVM + BLoC/Cubit Flow

```text
View (UI)
   ↓
ViewModel / Cubit / Bloc
   ↓
UseCases
   ↓
Repository Layer
   ↓
Remote API / Local Database
   ↓
State Emission
   ↓
Reactive UI Update
```

---

# 📡 Enterprise Data Flow Diagram

```text
┌─────────────┐
│ Flutter UI  │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ BLoC/Cubit  │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  UseCases   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Repository  │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Dio Client  │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ REST APIs   │
└─────────────┘
```

---

# 🎨 UI & Design Principles

* 🌗 Light & Dark Theme Support
* 📱 Fully Responsive Layouts
* 🧩 Reusable Widgets
* ✨ Smooth Animations
* 📐 Pixel Perfect UI
* ♿ Accessibility Friendly
* 🔄 Modular Components

---

# 🏢 Enterprise Development Standards

* Every feature must follow MVVM architecture
* All business logic must remain outside UI
* State management must use only BLoC/Cubit
* Repository pattern mandatory for data access
* No direct API calls from UI layer
* UseCases required for domain operations
* Dependency Injection required across modules
* Shared widgets must remain reusable and isolated
* All modules should support scalability and testability

---

# 📈 Scalability Highlights

* Feature-Based Architecture
* Reusable Shared Components
* Independent Modules
* Centralized Error Handling
* Easy API Expansion
* Multi-Environment Support
* CI/CD Ready Structure

---

# 👨‍💻 Development Guidelines

## Branch Naming

```bash
feature/module-name
bugfix/issue-name
hotfix/critical-fix
```

## Commit Message Style

```bash
feat: add attendance QR validation
fix: resolve login token refresh issue
refactor: optimize dashboard widgets
```

---

# 📷 Screens & Modules

| Module         | Status         |
| -------------- | -------------- |
| Authentication | ✅ Completed    |
| Attendance     | 🚧 In Progress |
| Messaging      | 🚧 In Progress |
| Inventory      | ✅ Active       |
| Reports        | 🚧 Ongoing     |
| Notifications  | ✅ Implemented  |
| Geofencing     | ✅ Integrated   |

---

# 🔥 Performance Optimizations

* Lazy Loading
* Cached Network Images
* Optimized Widget Rebuilds
* API Pagination
* State Isolation
* Efficient Memory Handling
* Background Processing

---

# 📚 Useful Commands

```bash
# Clean Project
flutter clean

# Get Packages
flutter pub get

# Run App
flutter run

# Build Release APK
flutter build apk --release

# Analyze Code
flutter analyze

# Run Tests
flutter test
```

---

# 🤝 Contribution Guidelines

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to your branch
5. Open a Pull Request

---

# 🧑‍💻 Maintained By

### WowCare Development Team

Built with ❤️ using Flutter & Clean Architecture.

---

# ⭐ Future Enhancements

* AI-Based Analytics
* Offline First Architecture
* Advanced Notifications
* Video Calling Support
* Real-Time Socket Integration
* Multi-Tenant Management
* Advanced Reporting Dashboard

---

<div align="center">

## 🚀 "Building scalable childcare experiences with Flutter" 🚀

</div>
