# Staff Attendance & Overtime — API Requirements (Frontend → Backend hand-off)

| | |
|---|---|
| **Purpose** | Define exactly what the new Attendance V2 module needs from the API: what already exists, what must change on existing endpoints, and what must be built new. |
| **Module** | `lib/modules/attendance_v2` (staff attendance detail + overtime) |
| **Base** | `https://uat-wowcare.childcarewow.app/api/v1/attendance` |
| **Date** | 2026-06-15 |
| **Author** | Frontend / Tech Lead |

---

## 1. TL;DR for the backend team

1. The three endpoints we have today (`sign-in`, `sign-out`, `PATCH daily/{code}`) are **write** endpoints returning a single raw attendance record. They are fine for mutations — **two small additions needed** (see §4).
2. The detail screen is **read-driven** and needs a **new GET "staff attendance profile"** endpoint that returns, for a date range: range **aggregations** (regular / overtime / break / attended days / absent days) + a **per-day rollup** + the **per-session rows**. This does not exist yet → **build new** (§5.1).
3. Raw records return **codes, not names** (`signedInByCode = USR-…`, `currentClassroomCode = CLS-…`). The UI shows *names* ("by PragnaSri", "4-Yellow-D"). Backend must return **denormalized display names** so the client does not do N+1 lookups (§3, §4).
4. **Regular vs Overtime is a per-day calculation** (worked minutes beyond the daily threshold). The frontend will **not** compute payroll numbers — the backend must return them as the single source of truth (§5.1, §6).
5. Also missing and required: **DELETE daily record**, **roster/list** endpoint (Screen 1), and **absence** read/mark endpoints (§5).

---

## 2. What we have today (write endpoints)

All three return the same raw `staff_attendance_record` object (sign-in/out wrap it in a `data` **array**; PATCH returns a `data` **object** — see §4.4).

| Endpoint | Method | Use | Returns |
|---|---|---|---|
| `/staff-attendance-records/sign-in` | POST | Create a sign-in | `data: [record]` |
| `/staff-attendance-records/sign-out` | POST | Close a session | `data: [record]` |
| `/staff-attendance-records/daily/{code}` | PATCH | Edit a session's in/out times | `data: record` |

### 2.1 The raw record shape we receive

```jsonc
{
  "code": "STAR_C9E010A2-C",            // session id — maps to our AttendanceSession.recordCode
  "organizationCode": "ORG_…",
  "schoolCode": "SCH_…",
  "staffCode": "STF_…",
  "attendanceDate": "2026-06-15",       // school-local date — our day bucket key
  "dayOfWeek": 1,
  "signedInAt": "2026-06-15T11:33:00Z", // UTC — good
  "signedInByCode": "USR-822574d1",     // ⚠ code only, no name
  "isExpectedToday": true,
  "signedInMethod": "WEB",              // GPS | QR | PIN | APP | WEB (| SYSTEM?)
  "signedInLocationLat": 0,
  "signedInLocationLong": 0,
  "signedInWithinGeofence": true,
  "clockPinUsed": null,
  "signedOutAt": "2026-06-15T11:36:00Z",// null while open
  "signedOutByCode": "USR-822574d1",    // ⚠ code only, no name
  "signedOutMethod": "WEB",             // ⚠ no SYSTEM value yet (auto-close)
  "signedOutLocationLat": 0,
  "signedOutLocationLong": 0,
  "signedOutWithinGeofence": true,
  "primaryClassroomCode": "CLS_…",      // ⚠ code only, no name
  "currentClassroomCode": "CLS_…",      // ⚠ code only, no name
  "status": "SIGNED_OUT",               // SIGNED_IN | SIGNED_OUT
  "totalWorkedMinutes": 3,              // per-session worked minutes
  "createdAt": "…", "updatedAt": "…",
  "createdBy": null, "updatedBy": null,
  "deletedAt": null, "deletedBy": null
}
```

**This gives us the per-session raw data. It does NOT give us:** display names, a SYSTEM-close marker, per-day regular/overtime/break, range aggregations, or anything for the roster and absence views.

---

## 3. What the frontend actually needs (data contract)

The detail screen binds to these entities (`lib/modules/attendance_v2/domain/entities`). Each field below must come from the API.

### `StaffOvertimeProfile` (whole screen)
| Field | Source today | Status |
|---|---|---|
| `staffName`, `designation`, `classroomName` | — | ❌ need (staff identity) |
| `todayStatus` (present/signedOut/absent/notMarked) | derivable from today's record `status` | ⚠ derive/return |
| `dailyRegularMinutes` (the 8h threshold) | — | ❌ need (overtime config) |
| `rangeStart`, `rangeEnd` | request params | ✅ |
| `aggregation` | — | ❌ need (§5.1) |
| `days[]` | — | ❌ need (§5.1) |

### `OvertimeAggregation` (hero card)
| Field | Status |
|---|---|
| `attendedDays`, `absentDays` | ❌ need (count) |
| `totalRegularMinutes`, `totalOvertimeMinutes` | ❌ need (server-computed) |
| `totalBreakMinutes` | ❌ need (or client-derived from sessions) |

### `AttendanceDay` (per-day card / table row)
| Field | Source | Status |
|---|---|---|
| `date` | `attendanceDate` | ✅ |
| `isAbsent` | absence record | ❌ need (absence read) |
| `regularMinutes`, `overtimeMinutes` | — | ❌ need (per-day rollup, server-computed) |
| `breakMinutes` | gaps between sessions | ⚠ client-derivable, but prefer server total |
| `sessions[]` | raw records grouped by date | ✅ (data exists) |
| `hasSystemClosedSession` | session `signedOutMethod == SYSTEM` | ❌ depends on §4.2 |

### `AttendanceSession` (expanded session row)
| Field | Source today | Status |
|---|---|---|
| `recordCode` | `code` | ✅ |
| `classroomName` | `currentClassroomCode` only | ⚠ need name (§4.1) |
| `signInAt` / `signOutAt` | `signedInAt` / `signedOutAt` | ✅ |
| `signedInBy` / `signedOutBy` (names) | `signedInByCode` / `signedOutByCode` | ⚠ need names (§4.1) |
| `signOutSource` (staff/system/open) | `signedOutMethod` + null check | ⚠ need SYSTEM (§4.2) |
| `workedMinutes` | `totalWorkedMinutes` | ✅ |

---

## 4. Changes needed on EXISTING endpoints

> These apply to the records returned by sign-in / sign-out / PATCH **and** to the new read endpoint (§5). Keep one consistent record shape everywhere.

### 4.1 ❗ Return denormalized display names (highest priority — performance)
The UI renders names, not codes. Returning only codes forces the client to fetch the user list and classroom list and join in memory (N+1 / extra round-trips on every screen). Add to every record:

```jsonc
"signedInByName": "PragnaSri Kokala",
"signedOutByName": "PragnaSri Kokala",     // "System" when auto-closed
"currentClassroomName": "4-Yellow-D",
"primaryClassroomName": "4-Yellow-D"
```
Keep the `…Code` fields too (for navigation/actions); just add the names.

### 4.2 ❗ Mark system auto-closures distinctly
When the nightly job auto-signs-out an open record at school end time, the record must be distinguishable from a real punch (this is the overtime-correctness issue). Either:
- add `"SYSTEM"` to the `signedOutMethod` enum, **or**
- add `"closeType": "NORMAL" | "SYSTEM_CLOSED" | "ADMIN_CORRECTED"`.

The UI flags these (amber "by System", "needs attention"). Without it we cannot show or filter them.

### 4.3 ⚠ Add optimistic-locking to PATCH (correctness)
`PATCH daily/{code}` currently last-write-wins — two admins (or an edit racing the auto-close job) silently clobber each other. Accept the record's `version` (or `updatedAt`) in the PATCH body/header and reject with **409** on mismatch. Add `"version": <int>` to the record shape.

### 4.4 ⚠ Make the response envelope consistent
`sign-in`/`sign-out` return `data: [ … ]` (array); `PATCH` returns `data: { … }` (object). Pick one rule (e.g. single-record ops → object, bulk → array) and document it so the client parses predictably.

### 4.5 ℹ Confirm the method enum
Document the full set: `GPS | QR | PIN | APP | WEB | SYSTEM`. The client maps these to icons/badges.

---

## 5. NEW endpoints to build

### 5.1 ❗ GET staff attendance profile (the core read — blocks the whole screen)

```
GET /staff-attendance/profile
    ?staffCode=STF_…
    &fromAttendanceDate=2026-06-01
    &toAttendanceDate=2026-06-30
    &page=0&size=31
```

Returns identity + overtime config + range aggregations + **per-day rollup** (`summarised`) + **per-session rows** (`separate`). Minutes are integers; the client formats. **Regular/overtime are per-day and computed server-side.**

```jsonc
{
  "success": true,
  "data": {
    "staff": {
      "staffCode": "STF_…",
      "staffName": "PragnaSri Kokala",
      "designation": "Teacher",
      "currentClassroomName": "4-Yellow-D",
      "todayStatus": "PRESENT"          // PRESENT | SIGNED_OUT | ABSENT | NOT_MARKED
    },
    "overtimeConfig": {
      "calculationMethod": "DAILY",     // DAILY | WEEKLY
      "dailyRegularMinutes": 480,       // the 8h threshold the UI labels
      "weeklyRegularMinutes": null,
      "otMultiplier": 1.5               // display only for now
    },
    "timeZone": "America/New_York",     // UI formats UTC timestamps in this tz
    "aggregations": {
      "attendedDays": 10,
      "absentDays": 0,
      "totalRegularMinutes": 4635,      // 77h 15m
      "totalOvertimeMinutes": 207,      // 3h 27m
      "totalBreakMinutes": 0
    },
    "summarised": {                     // one row per attended day — drives the day cards/table + OT bar
      "content": [
        {
          "attendanceDate": "2026-06-12",
          "regularMinutes": 480,
          "overtimeMinutes": 55,
          "breakMinutes": 0,
          "hasOvertime": true,
          "hasSystemClosedSession": true
        }
      ],
      "page": 0, "size": 31, "totalElements": 10, "totalPages": 1
    },
    "separate": {                       // raw session rows (same shape as §2.1 + §4 additions)
      "content": [ /* records, grouped by attendanceDate on the client */ ],
      "page": 0, "size": 50, "totalElements": 18, "totalPages": 1
    }
  }
}
```

Notes:
- `summarised` and `separate` paginate independently.
- If per-day `breakMinutes` is hard to compute server-side, the client can derive breaks from the session gaps — but `regularMinutes`/`overtimeMinutes` **must** be server-provided.
- `hasSystemClosedSession` depends on §4.2.

### 5.2 ❗ DELETE daily record (the ⋯ → Delete action)
```
DELETE /staff-attendance-records/daily/{code}      // soft delete
```
Returns success + the soft-deleted record (or 204). The UI's row action menu offers Edit (PATCH, exists) and Delete (this).

### 5.3 ❗ GET staff roster / list (Screen 1 — the staff attendance list)
```
GET /staff-attendance/view/daily
    ?attendanceDate=2026-06-15
    &classroomCodes=…&search=…&page=0&size=20
```
Per-staff row: `staffCode, staffName, currentClassroomName, isExpectedToday, todayStatus, signedInAt, signedOutAt, signedInByName, signedOutByName, attendedMinutesToday`. Plus the summary-card counts (total / signed-in / signed-out / absent / not-marked). (Confirm if a list endpoint already exists in the new system — align to it if so.)

### 5.4 ⚠ Absence read + mark (the Absent filter, Show-Absent, absent cards)
```
GET  /staff-absence-records?staffCode=&fromDate=&toDate=&page=&size=
POST /staff-absence-records/mark-absent
PATCH/DELETE /staff-absence-records/{code}
```
Absence row needs: `code, absenceDate, currentClassroomName, markedAbsentAt, markedByName, absenceNote, absenceType`.

### 5.5 ℹ Overtime config (if not embedded in 5.1)
If `overtimeConfig` isn't returned inside the profile, expose:
```
GET /schools/{schoolCode}/overtime-config
```
so the UI can label "Regular 8h / day" and (later) compute estimated pay.

---

## 6. Bad practices / performance concerns to fix

| # | Concern | Impact | Fix |
|---|---|---|---|
| B1 | Codes returned, names not (`USR-…`, `CLS-…`) | Client must fetch + join user/classroom lists → extra round-trips, slow lists | Denormalize names (§4.1) |
| B2 | No per-day regular/OT rollup | Client would have to compute payroll-grade numbers → wrong place for it, drift risk | Server computes, returns in `summarised` (§5.1) |
| B3 | No SYSTEM-close marker | Can't surface "needs attention" or correct lost overtime | Add `SYSTEM`/`closeType` (§4.2) |
| B4 | No pagination contract on reads | Unbounded payloads for long ranges | Page `summarised` + `separate` (§5.1) |
| B5 | PATCH last-write-wins | Lost corrections under concurrency | `version` + 409 (§4.3) |
| B6 | Inconsistent `data` array vs object | Fragile client parsing | One envelope rule (§4.4) |
| B7 | Sending all raw records for the detail screen | Heavy + client computation | Pre-aggregated `summarised` is the primary read; `separate` lazy/paged |

**Frontend commitments (so backend can rely on them):** the client only *formats* server numbers (no payroll math); sends all timestamps in UTC and formats via the returned `timeZone`; sends `attendanceDate` as the school-local date; will page `separate` rows on demand.

---

## 7. Field mapping (frontend entity ← API)

| Frontend (entity.field) | API field | Action |
|---|---|---|
| `AttendanceSession.recordCode` | `code` | ✅ |
| `AttendanceSession.classroomName` | `currentClassroomName` | ➕ add (§4.1) |
| `AttendanceSession.signInAt` / `signOutAt` | `signedInAt` / `signedOutAt` | ✅ |
| `AttendanceSession.signedInBy` / `signedOutBy` | `signedInByName` / `signedOutByName` | ➕ add (§4.1) |
| `AttendanceSession.signOutSource` | `signedOutMethod` (+ `SYSTEM`) / null | ➕ add (§4.2) |
| `AttendanceSession.workedMinutes` | `totalWorkedMinutes` | ✅ |
| `AttendanceDay.regularMinutes` / `overtimeMinutes` | `summarised[].regularMinutes` / `overtimeMinutes` | 🆕 (§5.1) |
| `AttendanceDay.hasSystemClosedSession` | `summarised[].hasSystemClosedSession` | 🆕 (§5.1/§4.2) |
| `OvertimeAggregation.*` | `aggregations.*` | 🆕 (§5.1) |
| `StaffOvertimeProfile.dailyRegularMinutes` | `overtimeConfig.dailyRegularMinutes` | 🆕 (§5.1/§5.5) |
| `StaffOvertimeProfile.todayStatus` | `staff.todayStatus` | 🆕 (§5.1) |

---

## 8. Backend checklist

**Change existing (records returned by sign-in / sign-out / PATCH):**
- [ ] B1 Add `signedInByName`, `signedOutByName`, `currentClassroomName`, `primaryClassroomName`
- [ ] B3 Add `SYSTEM` method (or `closeType`) for auto-closures
- [ ] B5 Add `version` + 409 on stale PATCH
- [ ] B6 Consistent `data` envelope; document method enum

**Build new:**
- [ ] 5.1 `GET /staff-attendance/profile` — aggregations + summarised (per-day OT) + separate (sessions) **← unblocks the screen**
- [ ] 5.2 `DELETE /staff-attendance-records/daily/{code}`
- [ ] 5.3 `GET /staff-attendance/view/daily` — roster + summary counts
- [ ] 5.4 Absence read + mark/edit/delete
- [ ] 5.5 Overtime config (if not embedded in 5.1)

**Priority order:** 5.1 + 4.1 + 4.2 (the screen can't render correctly without these) → 5.2 (edit/delete actions) → 5.3 (roster) → 5.4 (absences) → 4.3/4.4 (hardening).
