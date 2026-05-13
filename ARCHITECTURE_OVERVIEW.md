# Wowcare App – Architecture & Folder Structure Overview

## 1. Project Architecture & Patterns

### a. MVVM (Model-View-ViewModel)
- **Model:** Handles data, business logic, API/database communication.
- **View:** UI widgets, screens, and components.
- **ViewModel:** Connects Model and View, manages UI state and logic.

### b. Bloc & Cubit
- **Bloc:** Manages complex, event-driven state logic.
- **Cubit:** Simpler state management for straightforward flows.

### c. Isar
- Used as a local NoSQL database (currently for communication models).
- Can be extended for caching, offline support, and more.

---

## 2. Folder Structure & Purpose

```
Root/
│
├── android/           # Android native project files
│   └── app/           # Android app-specific files
│
├── assets/            # Static assets (images, fonts, lottie, etc.)
│   ├── bgImages/      # Background images
│   ├── fonts/         # Custom fonts
│   ├── icons/         # Icon assets
│   ├── images/        # General images
│   ├── languages/     # Localization files (en.json, hi.json, ur.json)
│   ├── lottie/        # Lottie animation files
│   └── vectors/       # Vector graphics
│
├── build/             # Build outputs (auto-generated, do not edit)
│
├── ios/               # iOS native project files
│
├── lib/               # Main Dart source code
│   ├── app/           # App-level configuration, entry points
│   ├── core/          # Core utilities, services, constants
│   ├── data/          # Data sources, repositories, models
│   ├── domain/        # Business logic, use cases, entities
│   ├── presentation/  # UI screens, widgets, ViewModels
│   ├── shared/        # Shared components/utilities
│   └── src/           # (Optional) Additional source code
│
├── linux/             # Linux platform files
├── macos/             # macOS platform files
├── test/              # Unit and widget tests
│
├── pubspec.yaml       # Dart/Flutter dependencies and project config
├── analysis_options.yaml # Linting and analysis rules
├── README.md          # Project overview and instructions
├── API_INTEGRATION_PLAN.md # API integration details
├── UI_COMPONENT_PLAN.md    # UI component planning
├── ...other files     # Miscellaneous configs, scripts, docs
```

---

## 3. Folder/Component Details

### android/, ios/, linux/, macos/
- Platform-specific code and configuration for building native apps.

### assets/
- **bgImages/**: Background images for screens.
- **fonts/**: Custom font files used in the app.
- **icons/**: App and UI icons.
- **images/**: General images (e.g., logos, banners).
- **languages/**: Localization files for multi-language support.
- **lottie/**: Lottie animation files for animated UI elements.
- **vectors/**: SVG or other vector assets.

### build/
- Auto-generated build outputs. Not for manual editing.

### lib/
- **app/**: App-level setup (main.dart, routing, themes).
- **core/**: Core services (API, network, utilities, constants).
- **data/**: Data models, repositories, data sources (API, local DB).
- **domain/**: Business logic, use cases, domain entities.
- **presentation/**: UI screens, widgets, ViewModels, Bloc/Cubit logic.
- **shared/**: Shared widgets, helpers, and utilities.
- **src/**: (Optional) Additional source code, can be used for experimental or legacy code.

### test/
- Unit, integration, and widget tests for all app layers.

### pubspec.yaml
- Declares dependencies, assets, and project metadata.

### analysis_options.yaml
- Linting and static analysis rules for code quality.

### README.md
- Project overview, setup instructions, and usage notes.

### API_INTEGRATION_PLAN.md, UI_COMPONENT_PLAN.md
- Documentation for API endpoints and UI component planning.

---

## 4. Scalability & Future Scope
- **Modular structure** allows easy addition of new features/modules.
- **MVVM + Bloc/Cubit** ensures maintainable, testable, and scalable code.
- **Isar** can be expanded for more local storage needs.
- **Separation of concerns** makes onboarding new developers easier.
- **Ready for multi-platform** (web, desktop) with minimal changes.
- **Extensible** for new services, APIs, and state management solutions.

---

## 5. Best Practices
- Keep business logic out of UI (use ViewModels, Bloc, Cubit).
- Use repositories for data access (API, local DB).
- Write tests for all critical logic.
- Document new modules and features.

---

For more details, refer to the inline comments in each directory and the specific documentation files provided in the project.
