# WowCare 2 – Final Delivery Scope & Security Standards

## 1️⃣ Flutter Version Compliance (MANDATORY)
- All development must use Flutter 1.38.
- No features, fixes, or modules outside this version baseline.
- Widget lifecycle must strictly follow Flutter 1.38 standards.
- Any deviation requires architecture-level approval.

## 2️⃣ Full Widget Lifecycle Compliance (MANDATORY)
- `initState()` → data trigger only
- `didChangeDependencies()` → context-based updates
- `build()` → UI-only logic
- `dispose()` → cleanup (streams, controllers, listeners)
- **No business logic, API calls, or cache access inside Widgets.**

## 3️⃣ Enforced MVVM Architecture Mapping
| MVVM Layer   | Flutter Equivalent                |
|--------------|----------------------------------|
| View         | Widget (UI)                      |
| ViewModel    | Cubit / Bloc                     |
| Model        | Domain Models + Repositories     |
| Data Source  | API + Isar                       |

## 4️⃣ System Architecture Diagram
```
┌────────────────────┐
│   View (Widget)    │
│  - UI only         │
│  - Listens state   │
└─────────▲──────────┘
          │
          │ state
          │
┌─────────┴──────────┐
│ ViewModel (Cubit)  │
│ - Business logic   │
│ - State handling   │
└─────────▲──────────┘
          │
          │ calls
          │
┌─────────┴──────────┐
│    Repository      │
│ - Single source    │
│ - Decides source   │
└──────▲─────▲───────┘
       │     │
       │     │
┌──────┴───┐ ┌───────┴───────┐
│   API    │ │  Isar Cache   │
│ Remote   │ │  Local DB     │
└──────────┘ └───────────────┘
```

## 5️⃣ Isar Usage Rules (CRITICAL)
- Isar must **never** be accessed directly from Widgets, Cubits/Blocs, or UI logic.
- Isar is only used in cache repositories (e.g., `core/local/repositories/`).
- Ensures clean separation, predictable state, and testability.

## 6️⃣ ER Diagram (Cache Perspective)
```
┌──────────────────┐
│      Student     │
│------------------│
│ id (PK)          │
│ name             │
│ roomId (FK)      │
│ updatedAt        │
└─────────▲────────┘
          │
          │ belongs to
          │
┌─────────┴────────┐
│       Room       │
│------------------│
│ id (PK)          │
│ name             │
│ updatedAt        │
└──────────────────┘

┌──────────────────┐
│  CacheMetadata   │
│------------------│
│ entityName       │
│ lastSyncedAt     │
│ version          │
└──────────────────┘
```

## 7️⃣ Screen Lifecycle Flow (Expected Behavior)
- Screen opens → `initState()` → `Cubit.loadData()` → emit(cached data) → UI renders immediately → background API refresh → emit(fresh data) → only affected widgets rebuild.

## 8️⃣ Cache-Driven UI Update Strategy
- UI requests data from Cubit.
- Cubit fetches via Repository (cache first, API in background).
- Repository reads cache, updates UI, syncs API, updates cache/UI again.
- TTL-based cache invalidation.
- UI listens only to state changes (no API calls in `build()`).

## 9️⃣ Golden Architecture & Future-Ready Features
- Centralized theme system (light/dark/custom).
- Dynamic language & localization (runtime switching, RTL/LTR).
- Feature flag system (safe rollouts, A/B testing).
- Child-centric features, parent experience, center/staff efficiency, analytics, and compliance-ready design.

## 🔟 Common Widget & Design System Layer
- Centralized typography, shimmer/loading, network state handler, card/tab/button/profile widgets, error boundary, offline/cache-aware widgets, pagination, accessibility, analytics, feedback widgets, and more.

---

# 🔒 Security & Performance Additions (MANDATORY)

### A. Secure Storage
- All sensitive data (tokens, credentials, user info) must be stored using secure storage solutions (e.g., Flutter Secure Storage, Keychain/Keystore).
- No sensitive data in plain text or insecure storage.

### B. Security Stop / Reverse Engineering Prevention
- Implement anti-tampering and anti-reverse engineering measures:
  - Obfuscate Dart code (use `flutter build` with obfuscation).
  - Enable ProGuard/R8 for Android, Bitcode/obfuscation for iOS.
  - Detect rooted/jailbroken devices and block/limit app usage.
  - Integrate runtime integrity checks (e.g., checksum validation).
  - Remove debug logs and sensitive error messages in production builds.

### C. General Security Practices
- Enforce HTTPS for all API calls.
- Validate all inputs and outputs.
- Use strong authentication and authorization.
- Regularly update dependencies to patch vulnerabilities.

### D. Performance & Smoothness
- Optimize for fast startup and smooth navigation.
- Minimize main thread work and avoid jank.
- Use lazy loading, pagination, and efficient state management.
- Monitor and optimize memory and battery usage.

---

**All the above standards are mandatory for WowCare 2 final delivery.  
Any deviation must be reviewed and approved by architecture.  
Security, smoothness, and speed are non-negotiable.**


# In/Out of Scope (Current Audit)

## In Scope (Current Implementation)
- Storage of sensitive and non-sensitive data is handled via `SharedPreferences` (see `StorageServiceImpl` in `lib/core/storage/storage_service.dart`).
- ProGuard/minification is enabled for Android release builds.
- Bloc/Cubit, repository, and Isar cache patterns are followed as per architecture guidelines.
- No direct API or cache calls in widgets detected.
- Theme, localization, and common widget structure are present.

## Out of Scope / Gaps (To Be Addressed)
- **Secure Storage:**
  - `flutter_secure_storage`, Keychain (iOS), or Keystore (Android) are **not implemented** for sensitive data. Migration from `SharedPreferences` to secure storage is required for SaaS-grade compliance.
- **Reverse Engineering Protection:**
  - No explicit root/jailbreak detection or runtime integrity checks found.
  - No Dart code obfuscation or iOS obfuscation settings detected.
- **Other SaaS Security Standards:**
  - No explicit checks for secure API usage (e.g., HTTPS enforcement) in code.
  - No evidence of advanced anti-tampering or anti-debugging logic.

## Recommendation
- **Immediate:** Migrate all sensitive data storage to `flutter_secure_storage` (or platform equivalents) and deprecate `SharedPreferences` for such use cases.
- **Short Term:** Implement root/jailbreak detection, Dart/iOS code obfuscation, and runtime integrity checks.
- **Ongoing:** Regularly audit for compliance with SaaS security standards and update this section as improvements are made.

---

*Last updated: 12 May 2026*