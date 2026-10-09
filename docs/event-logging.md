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
`forbidden`, `notFound`, `validation`, `server`, `blocked` and `unknown`.
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
   throwing, pass `failureOf` to `track`.

## Where to see them

Sentry, project `flutter`, Explore > Logs. Search by message, for example
`auth.login.failed`, or filter on `event`, `outcome` or `failure`.
