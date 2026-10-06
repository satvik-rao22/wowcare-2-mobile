# Observability privacy: Sentry

Sentry owns non-fatal errors, logs, breadcrumbs and screens. Crashlytics keeps
fatal crashes and crash-free users. This page lists what the app enforces on
the device, what has to be set in the Sentry project itself, and how a build
gets a DSN.

## What the app enforces

All Sentry code lives in `lib/core/observability/`. Feature code calls the
`Telemetry` facade and never imports `sentry_flutter`.

Sentry starts only when all of these hold (`TelemetryConfig.isEnabled`):

- `--dart-define=SENTRY_DSN=...` is set. No DSN, no SDK.
- The build is release or profile, not debug.
- `ENVIRONMENT` is not `LOCAL` (and not unset, which defaults to `LOCAL`).
- `--dart-define=SENTRY_FORCE=true` overrides the last two for local checks.

Options fixed in code (`TelemetryPrivacy.configure`):

| Option | Value | Why |
| --- | --- | --- |
| `sendDefaultPii` | false | No IP, cookies, headers or device identifiers by default. |
| `enablePrintBreadcrumbs` | false | Release builds still carry `debugPrint` calls with coordinates and tokens. |
| `attachScreenshot` | false | Screens show children's names and photos. |
| `attachViewHierarchy` | false | Same reason; widget text would be sent. |
| `tracePropagationTargets` | empty | The gateway rejects unknown request headers. |
| `enableNativeCrashHandling` | false | Crashlytics owns native crashes and ANRs. The manifest also sets `io.sentry.ndk.enable=false`. |
| `markAutomaticallyCollectedErrorsAsFatal` | false | Uncaught Dart errors are kept for context but never compete with Crashlytics' crash-free number. |

Scrubbing hooks, applied to everything that is still sent:

- Exception messages: every URL becomes `<url>`, every absolute path `<path>`.
  A `DioException` message carries the presigned S3 URL, which is a bearer
  credential; a file exception carries a path whose basename is often a
  child's name.
- Breadcrumbs, logs, request data, span data: query strings and fragments are
  removed from URLs. Record codes travel in query parameters.
- Navigation data: `from_arguments`, `to_arguments` and
  `route_settings_arguments` are dropped. go_router copies every query
  parameter of a route into its arguments.
- Logs: `user.name` and `user.email` attributes are dropped. The app only
  ever sets a user id (the user code).
- Request data on an event is reduced to method and query-less URL. Headers,
  cookies and bodies are never sent.

The hooks are a safety net. The rule for callers is the same as for
`AppLogger.trail`: no path, name, email, token or record code in a message,
breadcrumb or attribute.

## What has to be set in the Sentry project

Project `flutter` in org `wiseowl-technology`. These are server-side and
cannot be enforced from the app.

1. Settings, Security and Privacy:
   - Turn on "Prevent Storing of IP Addresses".
   - Turn on "Data Scrubber" and "Use Default Scrubbers".
   - Add to "Additional Sensitive Fields": `userCode`, `studentCode`,
     `staffCode`, `guardianCode`, `schoolCode`, `orgCode`, `pin`, `token`,
     `authorization`, `email`, `phone`, `password`.
   - Leave "Safe Fields" empty.
2. Settings, General, Event Settings: keep "Enhanced Privacy" on for the org
   (hides event detail in emails and integrations).
3. Retention: leave errors at the plan default and set log retention to the
   shortest the plan allows. Logs are the highest-volume stream once Phase 3
   lands.
4. Do not enable Session Replay. It is a later phase and needs its own
   privacy sign-off (masking, no kiosk mode, autopay WebView masked).
5. Alert rules: none yet. Phase 4 covers them.

## Where the DSN and token go

- `SENTRY_DSN`: a dart-define. Locally, `SENTRY_DSN=... make dev-apk-optimized`
  (any `*-optimized` target). In GitHub Actions, the `SENTRY_DSN` repository
  secret; both stage workflows pass it to the build. An empty secret means
  the stage build ships with Sentry off.
- `SENTRY_AUTH_TOKEN`: only the symbol upload needs it. Locally, export it and
  run `make sentry-upload` right after the optimized build it belongs to
  (the prod targets run `flutter clean` first, so a later build wipes the
  previous symbols). In GitHub Actions, the `SENTRY_AUTH_TOKEN` secret; the
  upload step is skipped when it is empty. Create the token under
  Settings, Auth Tokens with the `project:releases` and `project:write`
  scopes. It is never written to the repo.
- Release naming: the SDK's runtime default is
  `com.wiseowl.wowcareapp@<version>+<build>`. The Makefile and CI export the
  same string as `SENTRY_RELEASE` for the upload so symbols and events line
  up. Override both sides together or neither.

## Verifying a build

A debug build on a development machine, reporting to DEV:

```bash
flutter run --dart-define=ENVIRONMENT=DEV --dart-define=SENTRY_DSN=<dsn> --dart-define=SENTRY_FORCE=true
```

Expected in Sentry: an event with environment `dev`, release
`com.wiseowl.wowcareapp@<version>+<build>`, no `*_arguments` keys in any
breadcrumb, no query strings in any URL. A forced crash must appear in
Crashlytics exactly once.
