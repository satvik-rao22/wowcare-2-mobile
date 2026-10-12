# Event logging

The app logs one structured line per user-visible operation outcome through
`AppEvents` (`lib/core/observability/app_events.dart`). Lines go to Sentry Logs
and, as breadcrumbs, onto any later Sentry or Crashlytics error report. Nothing
is sent from a build without a `SENTRY_DSN`.

## Naming

`module.action.outcome`, all lower case, words joined with `_`.

- `module`: the feature area, e.g. `auth`, `attendance`, `billing`.
- `action`: what was attempted, e.g. `login`, `student_sign_in`.
- `outcome`: `succeeded`, `failed`, or `expired` (only `auth.session`).

Examples: `auth.login.failed`, `attendance.student_sign_in.succeeded`.

Each name is a value of the `AppEvent` enum (which holds `module.action`) plus
an `EventOutcome`. A new event is a new enum value, never a string at the call
site.

## Attributes

Every line carries `event` and `outcome`, and optionally:

| Attribute     | Meaning                                                   |
| ------------- | --------------------------------------------------------- |
| `failure`     | Bucket from `EventFailure`, on failed outcomes only        |
| `count`       | How many records the operation touched, e.g. students     |
| `duration_ms` | Wall time of the operation                                 |

`EventFailure` buckets are `network`, `timeout`, `cancelled`, `unauthorized`,
`forbidden`, `notFound`, `validation`, `server`, `blocked`, `permission` (a
device permission was denied), `unavailable` (location services off, no GPS
fix, the store would not open) and `unknown`.
Repository failures do not keep the HTTP status, so `server` covers any error
the server answered with; the write-request log for the same call has the
status code.

The signed-in user code and the persona, organisation, school and kiosk tags
come from the session scope (`RoleCubit`), not from the event.

## Personal data rule

An event never carries a name, email, phone number, address, free text, amount,
card detail, or any user, student, staff, guardian, invoice or record code.
Counts, durations and fixed enum values only.

The rule is enforced by the API: `AppEvents` takes no string or identifier
parameter, and the error passed to `AppEvents.failed` is only bucketed, never
sent. Keep it that way; if an event seems to need more detail, add an enum
value or a count, not a string.

## Adding an event

1. Add a value to `AppEvent` with its `module.action` key.
2. At the operation's single chokepoint (a use case `call`, or the repository
   method when there is no use case), wrap the call in `AppEvents.track`, or
   call `AppEvents.succeeded` / `AppEvents.failed` where the outcome is known.
3. For an operation that reports failure in its result rather than by
   throwing, pass `failureOf` to `track`. For a dartz `Either`, pass
   `failureOf: AppEvents.leftFailure`.
4. When only the result knows the count (shifts a repeat rule created), pass
   `countOf` instead of `count`.
5. If the use case already catches and converts errors (to a message string
   or a `Left`), put `track` inside that `try`, around the repository call, so
   the bucket is read from the raw Dio error.

## What is covered

Every user-initiated write in the app has an event, one per use case call:

| Module | Events |
| --- | --- |
| `auth` | login, logout, school switch, session expiry, forgot password |
| `attendance` | student and staff sign-in, sign-out, transfer, mark absent; record update and delete; absence delete; QR validate; the location check before a submit |
| `activity` | create, update, delete, approve, reject, acknowledge, parent signature, share, upload batch, recovered media |
| `event` | event create, update, delete; occurrence update and cancel; RSVP; attachment upload; holiday create, update, delete, status change |
| `task` | create, update, delete; assignment update and delete; unassign; status change; occurrence update and cancel; attachment upload and detach |
| `billing` | payment, guardian pay, payment method add, update, remove, set primary; autopay on, off, method; card tokenize; invoice create, update, issue, cancel, delete, resend; refund; credit; discount and ledger create, update, delete, deactivate, reactivate; ledger transaction |
| `student`, `guardian`, `user` | student create and every profile section; documents, physicians, pickups, siblings, physical exams; classroom assign; guardian create, link, update, delete, invite resend, PIN generate and change, own profile; login email change |
| `staff`, `scheduling`, `availability` | staff create, activate, deactivate, delete, org admin on and off, every profile section, documents, classroom assign; shift create, update, delete (single and series), publish; movement create, update, delete, status change |
| `communication` | conversation open (including a classroom chat created by its first message), message send, edit, delete, attachment delete, reaction add and remove, private mode |
| `kiosk`, `notification`, `geofence`, `report`, `app`, `classroom` | kiosk PIN verify and staff sign-in and sign-out; push token register and unregister, mark all read, preferences; location permission request; report generate, download, save; optional update dismissed, store opened; classroom logo upload |

Left out on purpose: reads, cache operations, and marking a single
notification or conversation read or delivered (one per tap or message). Push
token registration and the location permission request are logged although
the app starts them itself, because they explain why push or geofencing is not
working on a device.

Known limits:

- One save can log several events when the screen calls several use cases
  (staff and student profile sections, a payment method edit, bulk messages
  per recipient, "exempt all" immunizations per record).
- Messaging repositories turn every error into one failure type, so message
  events always show `network` (entity API) or `server` (legacy API). The
  write-request log for the same call has the real status.
- Report saves always fail as `unknown`: the file repository keeps no cause.
- A card rejected by Forte inside the autopay WebView is `unknown`; Forte's
  response codes are not mapped.

Every write request also gets its own log line from the API client (method,
path template, status, `duration_ms`), so a write with no event is still
visible.

## Where to see them

Sentry, project `flutter`, Explore > Logs. Search by message, for example
`auth.login.failed`, or filter on `event`, `outcome` or `failure`. Each event
is also a breadcrumb (category `event`, with its attributes) on any later
error report, and a Crashlytics log line in release builds.

## Debug console

In debug builds `AppLogger` prints through `AppConsole`
(`lib/core/utils/app_console.dart`), built on the `logger` package:

- `d`, `i`, `w`, `e`: a box coloured by level (cyan, green, orange, red) with
  the time, the time since launch, and the two calling frames, so the
  `package:wowcare/...dart:line` link opens the code that logged it. Errors
  show up to 12 frames of their own stack trace instead.
- API calls: one blue block per request and response with the status and
  the time it took; orange for a 4xx, red for a 5xx or no response. JSON is
  indented while it stays short.
- Events, trails and keys: one line each, green for a success and orange for
  a failure, followed by the code that recorded it.

Release and profile builds print none of this. `d`, `i` and `w` stay no-ops
there, because their callers pass raw API bodies and personal data.
