# Staff Attendance & Overtime — API Response Spec (UI-ready)

| | |
|---|---|
| **Goal** | One endpoint returns everything the detail screen needs, already shaped for rendering. The frontend should only *format* (minutes → "8h 16m") — no grouping, no math, no code→name lookups. |
| **Endpoint** | `GET /api/v1/attendance/staff-attendance/overview` |
| **Params** | `staffCode` (required), `fromDate=YYYY-MM-DD`, `toDate=YYYY-MM-DD` (a staff-month by default) |
| **Audience** | Backend team building the new optimized API. |

---

## 1. Design principles (the "why")

1. **One call, whole screen.** Return identity + summary + the full day list (with sessions and breaks nested). No second request to render the page.
2. **Per-DAY is the primary unit.** The screen is a list of days; sessions live *inside* each day. Do the grouping server-side so the client never splits sessions across pages.
3. **Server computes the numbers.** `regularMinutes` / `overtimeMinutes` / `breakMinutes` are the single source of truth (payroll-grade). The client must not re-derive them.
4. **Durations as integer minutes.** Always send `*Minutes` integers; the UI formats them. Optional `*Label` strings only if convenient — never send hours/minutes split across two fields.
5. **Timestamps as ISO-8601 UTC + a `timeZone`.** Not clock-only strings like `"05:26:00"` (those are ambiguous and force the client to guess the date/zone).
6. **Names, not codes, for anything shown.** Send `signInByName`, `classroomName`. Keep `*Code` only where the client needs it for an action (edit/delete).
7. **Pre-compute the flags.** `hasOvertime`, `needsAttention`, `signOutSource`, `type` (attended/absent) — so the UI is pure presentation and filtering is a one-line predicate.

---

## 2. The response

```jsonc
{
  "success": true,
  "message": "Staff attendance overview retrieved",
  "data": {

    "staff": {
      "staffCode": "STF_C931A5E8-0",
      "staffName": "PragnaSri Kokala",
      "designation": "Lead Teacher",          // humanized, single string
      "classroomName": "4-Yellow-D",
      "photoUrl": null,                        // nullable
      "todayStatus": "PRESENT"                 // PRESENT | SIGNED_OUT | ABSENT | NOT_MARKED
    },

    "period": {
      "fromDate": "2026-06-01",
      "toDate": "2026-06-30",
      "timeZone": "America/New_York"           // client formats all *At fields in this zone
    },

    "config": {
      "calculationMethod": "DAILY",            // DAILY | WEEKLY
      "dailyRegularMinutes": 480,              // the 8h threshold the UI labels "Regular 8h/day"
      "weeklyRegularMinutes": null,
      "overtimeMultiplier": 1.5                // display only for now
    },

    "summary": {
      "attendedDays": 8,
      "absentDays": 2,
      "regularMinutes": 3840,                  // 64h  → bar (blue) + legend
      "overtimeMinutes": 423,                  // 7h 3m → bar (amber) + legend
      "breakMinutes": 71,
      "totalMinutes": 4263,                    // 71h 3m → big number (== regular + overtime)
      "averageMinutesPerDay": 533,             // 8h 53m → "Avg / day"
      "needsAttentionDays": 1                  // → the amber banner count
    },

    "days": [
      {
        "date": "2026-06-12",
        "type": "ABSENT",                      // ABSENT day → absence block, no sessions
        "regularMinutes": 0,
        "overtimeMinutes": 0,
        "breakMinutes": 0,
        "totalMinutes": 0,
        "hasOvertime": false,
        "needsAttention": false,
        "absence": {
          "recordCode": "SAR_11AA22-1",
          "markedByName": "Spandana Marri",
          "markedAt": "2026-06-12T09:33:00Z",
          "note": "",
          "type": "FULL_DAY"                   // FULL_DAY | HALF_DAY
        },
        "sessions": [],
        "breaks": []
      },
      {
        "date": "2026-06-11",
        "type": "ATTENDED",
        "regularMinutes": 480,                 // → "Regular" column (8h)
        "overtimeMinutes": 16,                 // → "Overtime" column (amber)
        "breakMinutes": 71,                    // → "Break" column / "Total break"
        "totalMinutes": 496,                   // → "Total" column (8h 16m)
        "hasOvertime": true,
        "needsAttention": true,                // a session was auto-closed
        "absence": null,
        "sessions": [
          {
            "recordCode": "STAR_1101",         // for edit / delete actions
            "classroomName": "Office",
            "signInAt":  "2026-06-11T12:00:00Z",
            "signInByName": "Spandana",
            "signInMethod": "WEB",
            "signOutAt": "2026-06-11T14:00:00Z",
            "signOutByName": "Spandana",
            "signOutMethod": "WEB",
            "signOutSource": "STAFF",          // STAFF | ADMIN | SYSTEM | OPEN
            "workedMinutes": 120,
            "version": 3                        // optimistic-lock token for edit
          },
          {
            "recordCode": "STAR_1103",
            "classroomName": "6-Yellow-P",
            "signInAt": "2026-06-11T17:31:00Z",
            "signInByName": "Spandana",
            "signInMethod": "WEB",
            "signOutAt": "2026-06-11T21:27:00Z",
            "signOutByName": "System",
            "signOutMethod": "SYSTEM",
            "signOutSource": "SYSTEM",         // auto-closed → amber "by System" + needs attention
            "workedMinutes": 236,
            "version": 1
          }
        ],
        "breaks": [
          { "startAt": "2026-06-11T14:00:00Z", "endAt": "2026-06-11T14:40:00Z", "minutes": 40 },
          { "startAt": "2026-06-11T17:00:00Z", "endAt": "2026-06-11T17:31:00Z", "minutes": 31 }
        ]
      }
    ]
  },
  "timestamp": "2026-06-16T09:29:21Z",
  "error": null
}
```

> `days` is sorted **newest first** and contains attended **and** absent days, so the client renders the list directly and the Absent filter just checks `type === "ABSENT"`.

---

## 3. Field reference (what it feeds, why)

### `staff`
| Key | Type | UI use / why |
|---|---|---|
| `staffCode` | string | identity; actions |
| `staffName` | string | header title |
| `designation` | string | header subtitle — **humanized** (not `["LEAD_TEACHER"]`) |
| `classroomName` | string | header subtitle |
| `photoUrl` | string? | avatar (fallback to initials) |
| `todayStatus` | enum | header status pill |

### `period`
| Key | Type | Why |
|---|---|---|
| `fromDate` / `toDate` | date | echo of the requested range (range chip) |
| `timeZone` | IANA string | **client formats every `*At` in this zone** — removes the current time-only ambiguity |

### `config`
| Key | Type | Why |
|---|---|---|
| `dailyRegularMinutes` | int | label "Regular 8h/day"; lets the client trust/show the threshold (currently **missing**, defaulted to 480) |
| `calculationMethod` | enum | DAILY vs WEEKLY OT semantics |
| `overtimeMultiplier` | number | future payout display |

### `summary` (hero card)
| Key | Type | UI |
|---|---|---|
| `attendedDays`, `absentDays` | int | metric tiles |
| `regularMinutes`, `overtimeMinutes` | int | bar widths + legend |
| `breakMinutes` | int | (optional surface) |
| `totalMinutes` | int | big "71h 3m" (== regular + overtime) |
| `averageMinutesPerDay` | int | "Avg / day" |
| `needsAttentionDays` | int | amber banner count |

### `days[]`
| Key | Type | UI |
|---|---|---|
| `date` | date | row date |
| `type` | enum `ATTENDED`/`ABSENT` | which row layout; **Absent filter** = `type==="ABSENT"` |
| `regularMinutes`, `overtimeMinutes`, `breakMinutes`, `totalMinutes` | int | the 4 summary columns |
| `hasOvertime` | bool | **Overtime filter** + OT chip visibility |
| `needsAttention` | bool | **Needs-attention filter** + flag |
| `absence` | object? | absent-row content (marked by / at / note) |
| `sessions[]` | array | expanded detail |
| `breaks[]` | array | break rows between sessions + "Total break" |

### `days[].sessions[]`
| Key | Type | UI |
|---|---|---|
| `recordCode` | string | edit/delete target |
| `classroomName` | string | session title |
| `signInAt` / `signOutAt` | ISO UTC / nullable | times (`signOutAt:null` = still open) |
| `signInByName` / `signOutByName` | string / nullable | "by Spandana" / "by System" |
| `signInMethod` / `signOutMethod` | enum | method icon |
| `signOutSource` | enum | **blue** (staff) / **amber "by System"** (auto-close) / red open |
| `workedMinutes` | int | session duration |
| `version` | int | optimistic-lock for PATCH |

### `days[].breaks[]`
| Key | Type | UI |
|---|---|---|
| `startAt` / `endAt` | ISO UTC | "40m break · 10:00a–10:40a" |
| `minutes` | int | break length |

---

## 4. Naming conventions (apply consistently)

| Pattern | Meaning | Example |
|---|---|---|
| `*Minutes` | integer duration in minutes | `overtimeMinutes`, `workedMinutes` |
| `*At` | ISO-8601 UTC instant | `signInAt`, `markedAt` |
| `*Date` | calendar date `YYYY-MM-DD` (no time) | `attendanceDate`, `fromDate` |
| `*Name` | denormalized display name | `signInByName`, `classroomName` |
| `*Code` | opaque id for actions | `staffCode`, `recordCode` |
| `is*` / `has*` / `needs*` | boolean | `hasOvertime`, `needsAttention` |
| enums | `UPPER_SNAKE_CASE` | `SIGNED_OUT`, `FULL_DAY`, `SYSTEM` |
| keys | `camelCase` | — |

Rules: never split a duration into hours+minutes fields; never send a code where a name is shown; nullable means "not applicable" (open session → `signOutAt:null`).

---

## 5. Enums

| Field | Values |
|---|---|
| `staff.todayStatus` | `PRESENT` · `SIGNED_OUT` · `ABSENT` · `NOT_MARKED` |
| `config.calculationMethod` | `DAILY` · `WEEKLY` |
| `day.type` | `ATTENDED` · `ABSENT` |
| `session.signInMethod` / `signOutMethod` | `GPS` · `QR` · `PIN` · `APP` · `WEB` · `SYSTEM` |
| `session.signOutSource` | `STAFF` · `ADMIN` · `SYSTEM` · `OPEN` |
| `absence.type` | `FULL_DAY` · `HALF_DAY` |

---

## 6. Edge cases the response must encode

| Case | How |
|---|---|
| Multiple sessions/day | multiple objects in `sessions[]`, chronological |
| Break (out then back later) | an entry in `breaks[]`; `breakMinutes` is their sum |
| Classroom transfer (no real gap) | two sessions, **no** `breaks[]` entry between them |
| Forgot to sign out | `signOutAt:null`, `signOutSource:"OPEN"`, day `needsAttention:true` |
| Auto-closed at school end | `signOutSource:"SYSTEM"`, `signOutByName:"System"`, day `needsAttention:true` |
| Absent day | `type:"ABSENT"`, populated `absence`, empty `sessions`/`breaks` |
| Overtime | `overtimeMinutes>0`, `hasOvertime:true` |

---

## 7. What this changes vs the current `/profile`

1. **Group by day server-side** (current API returns flat per-session rows) → no client grouping, no pagination hazard.
2. **Add `regularMinutes` / `overtimeMinutes` / `breakMinutes` per day + in summary** (currently absent) → the screen's core data.
3. **Add `config.dailyRegularMinutes`** (currently missing → client defaults to 480).
4. **Include absent days in `days[]`** (currently only an `absentDays` count) → Absent filter works.
5. **`signOutSource` / `SYSTEM`** marker (currently none) → needs-attention + correct overtime.
6. **ISO-UTC `*At` + `timeZone`** instead of clock-only strings → unambiguous times.
7. **Humanized `designation`, `*Name` fields, `version`** → no client lookups, safe edits.

Result: the frontend maps the response almost 1:1 to the screen — fetch, format minutes, render. No grouping, no overtime math, no joins.
