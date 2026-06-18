# Staff Attendance & Overtime — Implementation Guide (for the Web build)

| | |
|---|---|
| **Purpose** | Let a web developer rebuild the exact logic the Flutter app uses, from the same API, so behavior matches 1:1. |
| **Audience** | Any engineer (React / Angular / Vue). Pseudocode is TypeScript-flavored and framework-agnostic. |
| **Screen** | Single page: header + summary card (with regular/overtime bar) + filter chips + an expandable day list. |
| **Endpoint** | `GET /api/v1/attendance/staff-attendance/profile` |

---

## 1. The screen at a glance

```
┌─────────────────────────────────────────────┐
│ HEADER: avatar · name · designation·room ·   │  ← StaffOvertimeProfile (identity)
│         [period chip ▾]            [Export]   │
├─────────────────────────────────────────────┤
│ SUMMARY CARD                                  │  ← OvertimeAggregation
│   80h 42m  Attended time                      │
│   [█████████████ regular | ▓ overtime ]       │  ← split bar (regular vs OT)
│   ● Regular (77h 15m)  ● Overtime (3h 27m)    │
│   Attended 8d · Absent 0d · Avg/day 8h        │
├─────────────────────────────────────────────┤
│ FILTER: [All days][Overtime][Absent][Needs…] │  ← client-side filter over days[]
├─────────────────────────────────────────────┤
│ DAY LIST (each row = 1 day, click to expand)  │  ← days[] (AttendanceDay)
│  ▸ Jun 11   +16m OT          8h 16m           │  collapsed = per-day summary
│  ▾ Jun 10   +1h25m OT        9h 25m           │
│      ↘ 08:03a by Suhas   ↗ 05:30p by System   │  expanded = sessions
│      ☕ 40m break · 10:00a–10:40a              │  + breaks
│      Total break 1h 11m                       │
└─────────────────────────────────────────────┘
```

---

## 2. How we call the API

One GET per staff per date-range. Default range = the current calendar month.

```
GET /api/v1/attendance/staff-attendance/profile
    ?staffCode={STAFF_CODE}
    &fromAttendanceDate={YYYY-MM-DD}   // inclusive range start
    &toAttendanceDate={YYYY-MM-DD}     // inclusive range end
    &page=0
    &size=500                          // pull ALL sessions in the range at once
    &sort=attendanceDate,desc
```

**Why `size=500`:** the API paginates by *session record*, not by day. We group records into days on the client, so a day must never be split across pages. A staff-month is at most ~100 sessions, so one big page is correct and cheap. Do **not** use the default `size=10`.

**Date range = "duration":**
- *Whole month* (default): `from = first day of month`, `to = last day of month`.
- *Custom range*: pass the two dates the user picked. Max 90 days is the product rule.

```typescript
function monthRange(anyDateInMonth: Date): { from: string; to: string } {
  const y = anyDateInMonth.getFullYear(), m = anyDateInMonth.getMonth();
  const first = new Date(y, m, 1);
  const last  = new Date(y, m + 1, 0);          // day 0 of next month = last day
  return { from: fmtDate(first), to: fmtDate(last) };
}
function fmtDate(d: Date): string {              // "2026-06-01"
  const p = (n: number) => String(n).padStart(2, "0");
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`;
}
```

---

## 3. What the API returns (raw)

```jsonc
{
  "success": true,
  "data": {
    "aggregations": {
      "totalAttendedTime": "0 Hrs 8 Mins",
      "totalAttendedHours": 0,
      "totalAttendedMinutes": 8,
      "attendedDays": 2,
      "absentDays": 0
    },
    "records": {
      "content": [
        {
          "code": "STAR_6BA3F8ED-5",        // session id (for edit/delete)
          "attendanceDate": "2026-06-16",   // school-local date → day bucket key
          "staffCode": "STF_C931A5E8-0",
          "staffName": "Zyan z",
          "classroomName": "2-Green-D",     // NAME present (no extra lookup needed)
          "classroomCode": "CLS_E2618D09-A",
          "signedInBy": "Suhas Biwalkar",   // NAME present
          "signedInTime": "05:26:00",       // TIME-ONLY (no date, no tz)
          "signedInMethod": "WEB",
          "signedOutBy": "",                // "" (empty) when not signed out
          "signedOutTime": null,            // null when open
          "signedOutMethod": null,
          "designation": ["LEAD_TEACHER"],  // array of enum codes
          "attendedTime": "0 Hrs 0 Mins",
          "attendedHours": 0,
          "attendedMinutes": 0,             // per-session worked minutes
          "isTransfer": false,
          "sequenceNumber": 1,
          "totalSequenceCount": 1,
          "nextActionTime": null,           // continuation time for transfers
          "fromClassroomName": null, "toClassroomName": null, "transferTime": null
        }
        // … one object PER SESSION (a staff can have several per day)
      ],
      "totalElements": 3, "totalPages": 1, "number": 0, "size": 10
    }
  }
}
```

**Mental model:** the API gives **per-session rows**. The UI needs **per-day rollups**. The whole transformation below exists to turn sessions → days.

---

## 4. The domain model the UI binds to

Build these objects once, then bind the UI to them (never bind directly to raw JSON).

```typescript
type SignOutSource = "staff" | "system" | "open";   // "system" = auto-closed; "open" = no sign-out yet

interface Session {
  recordCode: string;
  classroomName: string;
  signInAt: Date;
  signOutAt: Date | null;
  signedInBy: string;
  signedOutBy: string | null;
  signOutSource: SignOutSource;
  workedMinutes: number;
}

interface BreakInterval { start: Date; end: Date; minutes: number; }

interface Day {
  date: Date;
  isAbsent: boolean;
  regularMinutes: number;          // computed
  overtimeMinutes: number;         // computed
  sessions: Session[];
  hasSystemClosedSession: boolean;
  // derived getters:
  totalMinutes: number;            // regular + overtime
  breaks: BreakInterval[];         // gaps between sessions
  totalBreakMinutes: number;
  hasOvertime: boolean;            // overtimeMinutes > 0
  needsAttention: boolean;         // open session OR system-closed
  // absence-only:
  absenceMarkedBy?: string;
  absenceNote?: string;
}

interface Aggregation {
  attendedDays: number;
  absentDays: number;
  totalRegularMinutes: number;
  totalOvertimeMinutes: number;
  totalBreakMinutes: number;
  totalAttendedMinutes: number;    // regular + overtime
  averageMinutesPerDay: number;
  regularFraction: number;         // 0..1 → width of the regular part of the bar
}

interface StaffOvertimeProfile {
  staffCode: string;
  staffName: string;
  designation: string;             // humanized, e.g. "Lead Teacher"
  classroomName: string;
  todayStatus: "present" | "signedOut" | "absent" | "notMarked";
  dailyRegularMinutes: number;     // the overtime threshold (see §8 — MISSING from API)
  rangeStart: Date; rangeEnd: Date;
  aggregation: Aggregation;
  days: Day[];                     // newest first
}
```

---

## 5. The transformation — every function you need (12)

These are the complete set. Implement them as pure functions; the UI calls `loadProfile()` and binds to the result.

### 5.1 `loadProfile` — orchestrator
```typescript
async function loadProfile(staffCode: string, from: Date, to: Date): Promise<StaffOvertimeProfile> {
  const raw = await httpGet("/api/v1/attendance/staff-attendance/profile", {
    staffCode,
    fromAttendanceDate: fmtDate(from),
    toAttendanceDate: fmtDate(to),
    page: 0, size: 500, sort: "attendanceDate,desc",
  });
  return mapResponseToProfile(raw, staffCode, from, to);
}
```

### 5.2 `mapResponseToProfile` — raw JSON → domain
```typescript
function mapResponseToProfile(raw, fallbackStaffCode, from, to): StaffOvertimeProfile {
  const data    = raw?.data ?? {};
  const rawAgg  = data.aggregations ?? {};
  const rows    = data.records?.content ?? [];

  const first = rows[0] ?? {};

  // 1. each record → Session, grouped by attendanceDate
  const byDate = new Map<string, Session[]>();
  for (const r of rows) {
    const s = mapSession(r);
    if (!s) continue;
    const key = r.attendanceDate;
    (byDate.get(key) ?? byDate.set(key, []).get(key))!.push(s);
  }

  // 2. each date group → Day (with OT split + breaks)
  const days: Day[] = [];
  for (const [dateStr, sessions] of byDate) {
    days.push(buildDay(dateStr, sessions, DAILY_REGULAR_MINUTES));
  }
  days.sort((a, b) => b.date.getTime() - a.date.getTime());  // newest first

  // 3. aggregation (sum of per-day; counts from rawAgg)
  const aggregation = computeAggregation(days, rawAgg);

  return {
    staffCode: first.staffCode ?? fallbackStaffCode,
    staffName: (first.staffName ?? "").trim() || fallbackStaffCode,
    designation: humanizeDesignation(first.designation),
    classroomName: (first.classroomName ?? "").trim(),
    todayStatus: deriveTodayStatus(byDate),
    dailyRegularMinutes: DAILY_REGULAR_MINUTES,
    rangeStart: from, rangeEnd: to,
    aggregation,
    days,
  };
}
```

### 5.3 `mapSession` — one record → Session
```typescript
function mapSession(r): Session | null {
  const date = parseDate(r.attendanceDate);          // "2026-06-16" → Date
  if (!date) return null;
  const signInAt = combine(date, r.signedInTime);    // time-only + date → Date
  if (!signInAt) return null;                         // a session must have a sign-in

  const signOutAt = combine(date, r.signedOutTime);   // null when open
  const outMethod = (r.signedOutMethod ?? "").toUpperCase();
  let source: SignOutSource;
  if (!signOutAt)            source = "open";
  else if (outMethod === "SYSTEM") source = "system"; // (not sent yet — see §8)
  else                       source = "staff";

  const signedOutBy = (r.signedOutBy ?? "").trim();
  return {
    recordCode: r.code ?? "",
    classroomName: (r.classroomName ?? "").trim(),
    signInAt, signOutAt,
    signedInBy: (r.signedInBy ?? "").trim(),
    signedOutBy: signedOutBy === "" ? null : signedOutBy,
    signOutSource: source,
    workedMinutes: (r.attendedHours ?? 0) * 60 + (r.attendedMinutes ?? 0),
  };
}
```

### 5.4 `combine` — TIME-ONLY string + date → Date  ⚠ important
```typescript
function combine(date: Date, hms: string | null): Date | null {
  if (!hms || hms.trim() === "") return null;
  const [h, m] = hms.split(":");                 // "05:26:00"
  return new Date(date.getFullYear(), date.getMonth(), date.getDate(),
                  Number(h) || 0, Number(m) || 0);
}
```
> The API returns clock times only (`"05:26:00"`), no date or timezone. Attach the row's `attendanceDate`. Treat as school-local.

### 5.5 `buildDay` — sessions of one date → Day (OT split here)
```typescript
function buildDay(dateStr: string, sessions: Session[], threshold: number): Day {
  sessions.sort((a, b) => a.signInAt.getTime() - b.signInAt.getTime());  // chronological
  const worked   = sessions.reduce((t, s) => t + s.workedMinutes, 0);
  const regular  = Math.min(worked, threshold);
  const overtime = Math.max(0, worked - threshold);
  const breaks   = computeBreaks(sessions);
  return {
    date: parseDate(dateStr)!,
    isAbsent: false,
    regularMinutes: regular,
    overtimeMinutes: overtime,
    sessions,
    hasSystemClosedSession: sessions.some(s => s.signOutSource === "system"),
    totalMinutes: regular + overtime,
    breaks,
    totalBreakMinutes: breaks.reduce((t, b) => t + b.minutes, 0),
    hasOvertime: overtime > 0,
    needsAttention: sessions.some(s => s.signOutSource === "open" || s.signOutSource === "system"),
  };
}
```

### 5.6 `computeBreaks` — gaps between sessions
```typescript
function computeBreaks(sortedSessions: Session[]): BreakInterval[] {
  const out: BreakInterval[] = [];
  for (let i = 0; i < sortedSessions.length - 1; i++) {
    const prevOut = sortedSessions[i].signOutAt;
    if (!prevOut) continue;                                  // open → no break
    const nextIn = sortedSessions[i + 1].signInAt;
    const minutes = Math.round((nextIn.getTime() - prevOut.getTime()) / 60000);
    if (minutes > 0) out.push({ start: prevOut, end: nextIn, minutes });
  }
  return out;
}
```
> A back-to-back classroom **transfer** has a 0-minute gap → naturally excluded.

### 5.7 `computeAggregation`
```typescript
function computeAggregation(days: Day[], rawAgg): Aggregation {
  const totalRegular  = sum(days, d => d.regularMinutes);
  const totalOvertime = sum(days, d => d.overtimeMinutes);
  const totalBreak    = sum(days, d => d.totalBreakMinutes);
  const attendedDays  = rawAgg.attendedDays ?? days.length;
  const totalAttended = totalRegular + totalOvertime;
  return {
    attendedDays,
    absentDays: rawAgg.absentDays ?? 0,
    totalRegularMinutes: totalRegular,
    totalOvertimeMinutes: totalOvertime,
    totalBreakMinutes: totalBreak,
    totalAttendedMinutes: totalAttended,
    averageMinutesPerDay: attendedDays === 0 ? 0 : Math.round(totalAttended / attendedDays),
    regularFraction: totalAttended === 0 ? 1 : totalRegular / totalAttended,
  };
}
```

### 5.8 `deriveTodayStatus`
```typescript
function deriveTodayStatus(byDate: Map<string, Session[]>): TodayStatus {
  const today = byDate.get(fmtDate(new Date()));
  if (!today || today.length === 0) return "notMarked";
  if (today.some(s => s.signOutSource === "open")) return "present";
  return "signedOut";
}
```

### 5.9 `humanizeDesignation`  — `["LEAD_TEACHER"]` → `"Lead Teacher"`
```typescript
function humanizeDesignation(d: string[] | string | null): string {
  const raw = Array.isArray(d) ? (d[0] ?? "") : (d ?? "");
  if (!raw.trim()) return "Staff";
  return raw.split("_").filter(Boolean)
            .map(w => w[0].toUpperCase() + w.slice(1).toLowerCase())
            .join(" ");
}
```

### 5.10 `filterDays` — the All / Overtime / Absent / Needs-attention chips
```typescript
type DayFilter = "all" | "overtime" | "absent" | "needsAttention";

function filterDays(days: Day[], filter: DayFilter): Day[] {
  switch (filter) {
    case "all":            return days;
    case "overtime":       return days.filter(d => !d.isAbsent && d.hasOvertime);
    case "absent":         return days.filter(d => d.isAbsent);
    case "needsAttention": return days.filter(d => d.needsAttention);
  }
}
```

### 5.11 `formatHm` — minutes → label
```typescript
function formatHm(min: number): string {              // 496 → "8h 16m", 45 → "45m", 480 → "8h"
  if (min <= 0) return "0m";
  const h = Math.floor(min / 60), m = min % 60;
  if (h === 0) return `${m}m`;
  if (m === 0) return `${h}h`;
  return `${h}h ${m}m`;
}
function overtimeChip(min: number): string { return min <= 0 ? "" : `+${formatHm(min)}`; }
```

### 5.12 `formatClock` — Date → display time
```typescript
function formatClock(d: Date): string {               // → "08:03a" / "05:30p"
  let h = d.getHours(); const m = String(d.getMinutes()).padStart(2, "0");
  const mer = h >= 12 ? "p" : "a"; h = h % 12 || 12;
  return `${String(h).padStart(2, "0")}:${m}${mer}`;
}
```

**Constants**
```typescript
const DAILY_REGULAR_MINUTES = 480;   // 8h — DEFAULT until API sends it (see §8)
```

---

## 6. Field mapping (API → domain → UI)

| UI element | Domain field | From API |
|---|---|---|
| Header name | `profile.staffName` | `records[0].staffName` |
| Header sub-line | `profile.designation` · `profile.classroomName` | `records[0].designation[0]` (humanized) · `records[0].classroomName` |
| Header status pill | `profile.todayStatus` | derived (§5.8) |
| Summary big number | `aggregation.totalAttendedMinutes` → `formatHm` | Σ per-day (≈ `aggregations.totalAttendedMinutes`) |
| Bar — regular width | `aggregation.regularFraction` | computed |
| Legend "Regular (…)" | `aggregation.totalRegularMinutes` → `formatHm` | computed |
| Legend "Overtime (…)" | `aggregation.totalOvertimeMinutes` → `formatHm` | computed |
| "Attended Nd" | `aggregation.attendedDays` | `aggregations.attendedDays` |
| "Absent Nd" | `aggregation.absentDays` | `aggregations.absentDays` |
| "Avg/day" | `aggregation.averageMinutesPerDay` → `formatHm` | computed |
| Day row — date | `day.date` | `record.attendanceDate` |
| Day row — OT chip | `day.overtimeMinutes` → `overtimeChip` | computed |
| Day row — total | `day.totalMinutes` → `formatHm` | computed |
| Session — classroom | `session.classroomName` | `record.classroomName` |
| Session — sign-in | `session.signInAt` → `formatClock` + `session.signedInBy` | `record.signedInTime` + `record.signedInBy` |
| Session — sign-out | `session.signOutAt` → `formatClock` + `session.signedOutBy` | `record.signedOutTime` + `record.signedOutBy` |
| Session — duration | `session.workedMinutes` → `formatHm` | `record.attendedHours/Minutes` |
| Break row | `day.breaks[i]` → `formatHm` + `formatClock` | computed from session gaps |
| Total break | `day.totalBreakMinutes` → `formatHm` | computed |

---

## 7. Components & what each binds to (matches the Flutter widgets)

| Component | Binds to | Notes |
|---|---|---|
| **Header** | `profile` (name, designation, classroom, todayStatus) + selected period | Period chip opens a "Whole month / custom range" picker → re-call `loadProfile`. Export button → CSV. |
| **Summary card** | `profile.aggregation` | Big total + the **regular/overtime split bar** (blue = regular, amber = overtime; widths from `regularFraction`) + legend + Attended/Absent/Avg tiles. Optional "N days need attention" banner from `days.filter(d=>d.needsAttention).length` → sets filter to `needsAttention`. |
| **Filter chips** | current `DayFilter` | Single selected chip; calls `filterDays(profile.days, filter)`. Replaces separate toggles. |
| **Day list** | `filterDays(...)` result | **Collapsed row = per-day summary** (date, OT chip, total). **Click to expand → sessions** (in/out + by), **break rows** between sessions, and a **Total break** line. Absent days render inline with a red accent (when absence data exists — §8). |

### Visual rules to match
- Regular = **sky blue** `#9BE8FF`; Overtime = **mustard** `#FDCD16`; overtime text = amber `#DC9C13`.
- Sign-in icon **blue**, sign-out icon **red** (system auto-close = amber, labeled "by System").
- Break icon + text = **teal** `#1F9D8B` (a "happy break" color, not grey).
- All text color = brand plum `#573353` (never pure black). Headers bold.
- Auto-expand the first day where `needsAttention === true`.

---

## 8. Data MISSING from the API (required by the UI)

These are computed/defaulted on the client today and should be confirmed/added by backend (see `STAFF_OVERTIME_API_REQUIREMENTS.md`). **The web app must handle them the same way as Flutter so the two match.**

| # | Missing | UI impact | Current client handling (match this) |
|---|---|---|---|
| 1 | **Daily regular threshold** (`dailyRegularMinutes` / overtime config) | The whole regular-vs-overtime split | Default to **480** (8h). All OT math uses this constant until the API sends it. |
| 2 | **Per-day regular/overtime from server** | Same | We compute it client-side (§5.5). When the API sends `regularMinutes`/`overtimeMinutes` per day, prefer those and stop computing. |
| 3 | **Absence records** in the range | The **Absent** filter + absent rows are empty (only a count `absentDays` exists) | Show the count in the summary; the Absent filter yields no rows until backend returns absence entries (or a separate absence endpoint is called and merged into `days`). |
| 4 | **SYSTEM auto-close marker** (`signedOutMethod = "SYSTEM"` or `closeType`) | "Needs attention" + amber "by System" flag | Without it, `signOutSource` is only `staff`/`open`. We still flag **open** sessions (missing sign-out) as needs-attention; the auto-closed case lights up once the marker arrives. |
| 5 | **Today status / timezone** | Header pill; exact local times | Derive `todayStatus` from today's records (§5.8); treat times as school-local. |

**Filtering note (important for parity):** the *All / Overtime / Absent / Needs-attention* filtering is **100% client-side** over `days[]`. But:
- **Overtime** needs #1 (the threshold) — until then OT is 0 and that filter is empty.
- **Absent** needs #3 (absences aren't in this response).
- **Needs-attention** works today for *open* sessions; the *auto-closed* variant needs #4.

---

## 9. End-to-end flow (what the page does on load)

```
1. page mounts with staffCode (from route param)
2. period = monthRange(today)                 // default current month
3. profile = await loadProfile(staffCode, period.from, period.to)
4. render Header(profile, period)
5. render SummaryCard(profile.aggregation)
6. state.filter = "all"
7. render FilterChips(state.filter)
8. render DayList(filterDays(profile.days, state.filter))
   - row click → toggle expand → render sessions + breaks + total break
9. on filter chip click → state.filter = chip → re-render DayList only
10. on period change → period = picked → goto step 3
11. on error → show "Unable to load attendance data. Retry." with retry → step 3
12. while awaiting → show loading skeleton
```

That's the entire logic. Twelve pure functions (§5) + the field map (§6) + these flow steps reproduce the Flutter screen exactly.
