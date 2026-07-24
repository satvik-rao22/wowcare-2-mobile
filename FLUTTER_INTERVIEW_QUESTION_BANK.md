# Flutter / Mobile Engineer Interview Question Bank (2–10 YOE, Production-Grade Apps)

Grounded in patterns actually used in this codebase (repository pattern, remote/local data sources, caching, DI, offline-first, background sync, GPS/kiosk flows) so answers can be tied to real examples instead of textbook theory.

---

## 1. Dart Language Fundamentals
1. Explain `late`, nullable types, and null-safety migration pitfalls you've hit in a large codebase.
2. Difference between `const` and `final`. When does using `const` constructors actually improve performance?
3. Sync vs async generators (`sync*`/`async*`), `Stream` vs `Future` — when would you model an API as a `Stream`?
4. How does Dart's isolate model differ from threads? When have you used `compute()` or a full `Isolate` for CPU-bound work (e.g., JSON parsing, image processing)?
5. Explain mixins vs abstract classes vs interfaces in Dart. Give a real example of composing behavior with mixins.
6. What's the difference between `==` and `identical()`? How do you implement value equality correctly (and why `Equatable`/`freezed` matter for state classes)?
7. Extension methods — when are they appropriate vs a utility class?
8. Explain Dart's sound null safety and how `!`, `?.`, `??`, `??=` differ in production code — where have null-check abuses caused bugs?

## 2. Flutter Framework & Rendering
9. Walk through the Widget → Element → RenderObject tree and why it exists.
10. `StatelessWidget` vs `StatefulWidget` — what triggers a rebuild, and how does `setState` actually propagate?
11. Explain `BuildContext` — why can't you use a context after `await` without checking `mounted`?
12. Keys: `ValueKey`, `ObjectKey`, `GlobalKey` — give a real scenario where omitting a key caused a state bug (e.g., reordering list items with `Dismissible` or a `PageView`).
13. What causes unnecessary widget rebuilds, and how do you diagnose it (DevTools, `RepaintBoundary`, `const` widgets, `Builder` scoping)?
14. Explain `InheritedWidget` and how `Provider`/`Riverpod` build on top of it.
15. Difference between `didChangeDependencies`, `initState`, and `build` lifecycle — where do you put one-time async initialization safely?
16. How do you profile jank (dropped frames) in a production app? Walk through using the Performance/Timeline view in DevTools.
17. Explain `RepaintBoundary` and `ListView.builder` vs `ListView(children:)` for a long list of report cards or dashboard items.

## 3. State Management
18. Compare Provider, Riverpod, Bloc/Cubit, and GetX — trade-offs for a mid-size production app with 5–10 engineers.
19. How do you prevent business logic from leaking into widgets? Where does that boundary live in this codebase (e.g., `reports_repository_impl.dart` vs the screen widgets)?
20. Explain how you'd model a screen with: loading, empty, error, and loaded-with-stale-cache states (relevant to `generated_reports_screen.dart` style screens).
21. When would you use a `StreamController` / `ValueNotifier` directly instead of a full state management library?
22. How do you handle state that must survive navigation (e.g., filters selected in `filter_screen.dart` persisting back to `reports_screen.dart`)?
23. Explain unidirectional data flow and why it matters for debugging production issues reported by users you can't reproduce locally.

## 4. Architecture (Clean/Layered, DDD-lite)
24. Explain the responsibility split between `datasource → repository → entity/usecase → presentation` layers. Why map API response models to domain entities instead of using them directly in the UI (e.g., `_mapResponseModelToEntity`)?
25. Why keep `remoteDataSource` and `localDataSource`/`storageService` behind the same repository interface? How does that enable offline-first behavior?
26. Given a method like `_resolveSchoolName` that falls back across three sources (cached list → stored name → empty), how would you test it in isolation? What are the failure modes if the cached list is stale?
27. When should a repository *not* cache (e.g., "Always make fresh API call - no caching of generated reports")? What business/legal reasons justify bypassing cache?
28. How do you decide what belongs in a repository vs a use case/interactor vs a controller/bloc?
29. Explain dependency inversion in the context of `abstract class ReportsRepository` + `ReportsRepositoryImpl`. Why does this matter for testability and swapping implementations?
30. How would you version and migrate local cache/storage schemas (e.g., `StorageKeys`) without breaking existing installed app versions?

## 5. Networking & Data Layer
31. How do you handle token refresh/401 retries without duplicating logic across every repository call?
32. Explain idempotency — why does "always make a fresh API call" matter for something like `generateReport` (avoiding duplicate report generation on retry)?
33. How do you design a robust JSON parsing layer that doesn't crash on unexpected/missing fields from the backend (defensive parsing, `Map<String, dynamic>.from`, `whereType<Map>()`)?
34. Discuss request cancellation — how do you cancel an in-flight API call when a user navigates away mid-request (e.g., Dio's `CancelToken`)?
35. How would you implement exponential backoff + retry for flaky network calls without causing duplicate side effects (e.g., generating the same report twice)?
36. Explain pagination strategies (offset vs cursor) and how you'd implement infinite scroll for a reports/messages list.
37. How do you structure error handling so a `try/catch` around JSON decoding (like around `organizationsAndSchools`) degrades gracefully instead of crashing the screen?

## 6. Local Storage & Caching
38. Compare `shared_preferences`, `Hive`, `sqflite`/`drift`, and `secure_storage` — when is each appropriate (tokens vs cached lists vs structured relational data)?
39. How do you invalidate stale cached data (e.g., a cached org/school list) when the backend truth changes?
40. Discuss why storing a "code" vs a "name" inconsistently (as hinted by `_resolveSchoolName`'s comment) becomes a production bug magnet, and how you'd prevent similar bugs with typed models instead of raw strings.
41. How do you handle storage migrations across app versions (adding/renaming keys) without data loss?

## 7. Async Programming & Concurrency
42. Explain `Future.wait` vs sequential `await` — when does parallelizing independent calls (e.g., fetching org name + generating report) actually help vs risk race conditions?
43. What happens if two async operations both mutate the same cached value concurrently? How do you guard against races in a repository?
44. Explain `Completer` and a real use case (bridging a callback-based API into a `Future`).
45. Debounce vs throttle — where would you apply this in a filter/search screen to avoid spamming the API on every keystroke?
46. How do you avoid memory leaks from subscriptions/streams/timers not being disposed (e.g., in a `StatefulWidget`'s `dispose()`)?

## 8. Testing
47. How do you unit test a repository method like `_resolveSchoolName` that depends on `StorageService`? What do you mock, and what do you assert (including the "falls back to empty string" edge case)?
48. Widget testing vs integration testing vs golden tests — when do you use each, and what's your coverage strategy for a production app?
49. How do you test error/loading/empty states for a screen without hitting a real network call?
50. What's your approach to testing async code with `fake_async` or `mocktail`/`mockito` verifying call order (e.g., asserting `generateReport` is called with a freshly resolved `schoolName`)?
51. How do you structure tests so a refactor of the data layer doesn't break dozens of unrelated widget tests?

## 9. Performance & Production Readiness
52. How do you diagnose a slow report-generation flow — is it network latency, JSON parsing, or a rebuild storm in the UI?
53. What's your strategy for reducing app startup time (deferred initialization, lazy DI, splash screen orchestration)?
54. How do you monitor crash-free rate and performance in production (Firebase Crashlytics, Sentry, custom `AppLogger` patterns like `[REPORTS-REPO]` tags seen here)?
55. Explain how structured logging (tagged prefixes, log levels) helps triage production incidents versus scattered `print()` statements.
56. How do you handle large list rendering (hundreds of report entries) without jank — `ListView.builder`, `AutomaticKeepAliveClientMixin`, pagination?
57. What's your image-loading/caching strategy (`cached_network_image`, memory cache sizing) for a media-heavy screen like a dashboard?

## 10. Platform Integration
58. How do you handle platform channels for a native feature not covered by an existing plugin (e.g., GPS "always allow" permission flows, referenced in this repo's recent commit history)?
59. iOS vs Android permission model differences — how do you design a single Dart API surface that handles both gracefully?
60. How do you test/debug platform-channel code without needing to open Xcode/Android Studio for every iteration? *(Note: this repo's convention is to avoid `xcodebuild`/opening Xcode and prefer `swiftc -parse` for quick native syntax checks.)*
61. Background execution — how do you handle a background sync or kiosk-mode logout flow reliably across app lifecycle states (backgrounded, killed, relaunched)?

## 11. CI/CD, Release, and Code Quality
62. Walk through your Flutter CI pipeline: static analysis, tests, build, code signing, distribution (Fastlane/Codemagic/GitHub Actions).
63. How do you manage flavors/environments (dev/staging/prod) with different API base URLs and bundle IDs?
64. What's your strategy for feature flags/gradual rollout of a risky change (e.g., a new reports flow)?
65. How do you structure PRs and commits for a fast-moving mobile team (feature branches, merge vs squash, changelog discipline)?
66. Describe a production incident you diagnosed from a crash report/log alone, without being able to reproduce it locally.

## 12. Design Patterns in Flutter
67. Repository pattern — pros/cons, and how it enables swapping mock data for real API during development.
68. Factory pattern for creating platform-specific widgets or model parsing (`fromJson` factories).
69. Observer pattern — how do `ValueNotifier`, `Stream`, and `Bloc` all implement variations of this?
70. Singleton pattern for services like `StorageService`/`AppLogger` — risks (testability, hidden global state) and how to mitigate via DI.
71. Strategy pattern — e.g., swapping report-generation strategies per report type without an if/else ladder.

## 13. System Design (Mobile-Specific, for 5+ YOE)
72. Design an offline-first "generate report" feature: user requests a report with no connectivity — how do you queue, retry, and notify the user when it completes?
73. Design a caching layer for organization/school lookups shared across 10+ screens — invalidation strategy, TTL, and consistency guarantees.
74. Design a robust "resolve display name from possibly-stale local cache with API fallback" system (generalizing `_resolveSchoolName`) — how do you avoid silent data staleness bugs across a whole app?
75. Design push-notification-driven data refresh (e.g., a new report becomes available) — how do you reconcile with locally cached state without full-screen reloads?
76. Design a multi-tenant (multi-organization/school) session model — how do you prevent cross-tenant data leakage in cached storage after a user switches schools/logs out?
77. Design a kiosk-mode app that must securely log out and reset state between users on a shared device.

## 14. Behavioral / Senior-Track (5–10 YOE)
78. Tell me about a time you inherited a poorly architected data layer — how did you incrementally refactor it without a big-bang rewrite?
79. Describe a disagreement with a teammate over state management or architecture — how was it resolved?
80. How do you mentor a 2-YOE engineer through their first production incident?
81. Tell me about a time a "quick fix" (e.g., a fallback string, a silent catch block) caused a harder bug later. What did you change about your review habits afterward?
82. How do you decide when technical debt is acceptable to ship vs must be fixed before merge?

---

## Suggested Interview Structure by Level

| Level | Focus | Sections to weight heavily |
|---|---|---|
| 2–3 YOE | Dart/Flutter fundamentals, widget lifecycle, basic testing | 1, 2, 3, 8 |
| 4–6 YOE | Architecture, async correctness, caching, performance | 4, 5, 6, 7, 9 |
| 7–10 YOE | System design, platform integration, CI/CD, leadership | 10, 11, 12, 13, 14 |

## Tips for Using This Bank
- Pull 1–2 questions per section rather than running through all of them; depth beats breadth.
- For mid/senior candidates, present a real snippet (anonymized) like `_resolveSchoolName` and ask them to find the bug/edge case live — it reveals actual code-reading ability better than abstract questions.
- Follow every "how would you design X" question with "what breaks first at 10x scale?" to separate mid from senior candidates.
