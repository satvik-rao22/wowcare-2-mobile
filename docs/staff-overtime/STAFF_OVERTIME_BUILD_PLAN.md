# Staff Overtime — One-Day Build Plan (Mobile)

| | |
|---|---|
| **Goal** | Add Regular vs Overtime breakdown to the staff attendance profile, reusing existing components. UI-first with mock data today; wire real API tomorrow. |
| **Strategy** | (1) Build responsive UI with static mock data → (2) verify & iterate UI → (3) add domain/data layer + cubit + DI → swap mock for API. |
| **Date** | 2026-06-13 |

---

## 0. Reality check — mobile ≠ web

The web screenshots show a **table** UI with a **Summarised ⇄ Separate** toggle. The mobile app is **card/expansion-tile based** and currently has a **Present ⇄ Absent** toggle. We are NOT copying the web table to mobile — we adapt the same data to the mobile card idiom.

### What already exists (reuse, don't rebuild)

| Thing | File | Note |
|---|---|---|
| Profile screen (cards + list + date range + action menu) | `lib/presentation/features/attendance/view/staff_attendance_profile.dart` | **The screen to modify.** Uses `setState()` + inline JSON parsing (lines 519–680), NOT cubit. |
| Attended Days / Attended Hours / Absent Days cards | same file, `_buildStats()` 1009–1087, `_buildAttendedHoursStat()` 1089–1140 | "Attended Hours" card = plain h/m circles, **no OT split yet**. |
| Present ⇄ Absent toggle | same file, 838–861 (`CustomToggle`) | Switches present-day list vs absent-day list. |
| Per-session day card (expansion tile) | same file, `_buildAttendanceItem()` 1302–1368 | Classroom / Sign In / Sign Out / Attended Time. |
| Absent day card | same file, `_buildAbsentDayItem()` 1370–1425 | Already wired to a working absent endpoint. |
| Duration formatting | `lib/core/util/attendance_attended_duration.dart` | `formatAttendedDurationLabel()`, `attendedLabelFromMoments()`. |

### What's NEW (the actual work)

1. **Regular vs Overtime stacked bar** on the Attended Time card (e.g. `71h 3m` → `Regular 64h` + `Overtime 7h 3m`).
2. **Per-day Summarised breakdown** — each day shows Regular / Overtime / Total / Break (the "overtime screen").
3. **New data fields** end-to-end: `regularMinutes`, `overtimeMinutes`, `breakMinutes`, `totalMinutes` (per day) + `totalRegularMinutes`, `totalOvertimeMinutes` (aggregation).
4. **A typed model/entity + cubit** for the profile (today it's untyped inline JSON — we upgrade it while here).

---

## 1. Components to REUSE (confirmed paths)

| Need | Reuse | Path |
|---|---|---|
| **Regular/OT stacked bar + legend** | `CustomStatBarCard` (params: `title`, `number`, `items`, `embedded`) | `lib/shared/common/widgets/custom_stat_bar_card.dart` |
| Date-range picker | `CustomDateTimeField` (`isRangePicker: true`) | `lib/shared/common/widgets/custom_date_time_field.dart` |
| Summarised ⇄ Separate toggle | `CustomToggle` | `lib/shared/common/widgets/custom_toggle.dart` |
| Section/stat card container | `CustomSectionCard` | `lib/shared/common/widgets/custom_section_card.dart` |
| Text styles | `AppText.*` / `AppTextStyles` | `lib/shared/common/widgets/app_text_styles.dart` |
| Colors (incl. progress-bar palette) | `AppColors` (`lightBlueProgressBar`, `mustardProgressBar`, `errorColor`) | `lib/app/theme/colors.dart` |
| Responsive sizing | `ResponsiveHelper`, `ResponsiveSizing` | `lib/shared/utils/` |
| Loading skeletons | `ShimmerLoaderCard`, `AttendanceCardShimmer` | `lib/shared/common/widgets/custom_shimmer_loader.dart` |
| Pull-to-refresh | `CustomRefreshIndicator` | `lib/shared/common/widgets/custom_refresh_indicator.dart` |
| Avatar/initials | `DocumentImageWidget` (already used in profile) | (imported in profile) |

> **The OT bar is essentially free:** `CustomStatBarCard` already renders a stacked horizontal bar with a tappable legend — exactly the `Regular (blue) | Overtime (mustard)` visual from the screenshots. Feed it two `ProgressItemHelper` items.

---

## 2. One-day execution path

### Phase 1 — Responsive UI with static mock data (morning)

Build against an in-memory mock so there's zero API dependency. Files to add:

```
lib/presentation/features/attendance/overtime/
  mock/staff_overtime_mock.dart        // static StaffOvertimeProfile sample (see §4)
  model/staff_overtime_view_data.dart  // plain UI models (no JSON yet): StaffOvertimeProfile,
                                        //   StaffOvertimeAggregation, StaffOvertimeDay, StaffOvertimeSession
  widgets/overtime_summary_bar.dart     // wraps CustomStatBarCard for Regular/OT
  widgets/overtime_day_card.dart        // per-day Summarised card (Regular/OT/Total/Break)
```

UI changes in `staff_attendance_profile.dart`:
- Replace `_buildAttendedHoursStat()` body with `OvertimeSummaryBar` (stacked bar).
- Add a **Summarised ⇄ Separate** `CustomToggle` next to the existing Show-Absent row.
- Summarised → list of `OvertimeDayCard`; Separate → existing per-session expansion tiles.
- Feed everything from `StaffOvertimeMock.sample` for now.

**Exit:** screen renders fully with mock data on phone + tablet widths; no backend.

### Phase 2 — Verify & iterate UI (midday)

- Run on device/emulator, eyeball against the web screenshots (Devi Vempati: `71h 3m`, Regular 64h, OT 7h 3m, 8 attended, 2 absent).
- Tune spacing, colors (OT in `AppColors.errorColor`/mustard), bar proportions, empty/loading states.
- Lock the **UI model shape** (`StaffOvertimeProfile` etc.) — this becomes the contract the JSON must map to.

### Phase 3 — Domain/data layer + cubit + DI (afternoon)

Follow the existing attendance slice pattern exactly (plain classes, Equatable state, `call()` usecases, no Either):

```
domain/features/attendance/
  entities/staff_overtime_profile.dart           // promote the Phase-1 UI models to entities
  usecases/get_staff_overtime_profile_usecase.dart
  (add method to) repositories/attendance_repository.dart

data/features/attendance/
  models/staff_overtime_models.dart              // fromJson/toJson, maps to entity
  (add method to) datasources/attendance_remote_datasource.dart   // Dio GET
  (add method to) repositories/attendance_repository_impl.dart    // map model→entity (+cache)

presentation/features/attendance/overtime/cubit/
  staff_overtime_cubit.dart                      // loadInitial / refresh / setRange
  staff_overtime_state.dart                      // Equatable + copyWith + named ctors
```

DI in `lib/app/di/di.dart` (mirror lines 319/408/1137):
```dart
// usecase (factory)
serviceLocator.registerFactory(() => GetStaffOvertimeProfileUseCase(serviceLocator()));
// cubit (factory)
serviceLocator.registerFactory<StaffOvertimeCubit>(
  () => StaffOvertimeCubit(getStaffOvertimeProfileUseCase: serviceLocator()),
);
```

**Swap:** in the profile screen, replace `StaffOvertimeMock.sample` with `serviceLocator<StaffOvertimeCubit>()` + `BlocBuilder`. Keep a `kUseOvertimeMock` bool flag so you can flip back instantly if the API is late.

**Exit:** real data flows; mock retained behind a flag.

---

## 3. JSON contract for the backend dev (hand over today)

Extends the **existing** `fetchStaffAttendanceProfile` response (today: `data.aggregations` + `data.records.content[]`). New fields are **bolded** in comments. Minutes are integers (clients format display). Times in school timezone, ISO-8601.

```jsonc
GET /api/v1/staff-attendance/profile?staffCode=DV001&fromAttendanceDate=2026-06-01&toAttendanceDate=2026-06-30&page=0&size=10
{
  "data": {
    "staff": {
      "staffCode": "DV001",
      "staffName": "Devi Vempati",
      "designation": "Teacher",
      "classroomName": "4-Yellow-D",
      "photoUuid": null
    },
    "overtimeConfig": {                 // NEW — echo so the UI can label "Regular 8h/day"
      "calculationMethod": "DAILY",     // DAILY | WEEKLY
      "dailyRegularMinutes": 480,
      "weeklyRegularMinutes": null,
      "otMultiplier": 1.5               // display only for now
    },
    "aggregations": {
      "attendedDays": 8,
      "absentDays": 2,
      "totalAttendedMinutes": 4263,     // NEW (was only "totalAttendedTime" label)
      "totalRegularMinutes": 3840,      // NEW
      "totalOvertimeMinutes": 423,      // NEW
      "totalBreakMinutes": 0,           // NEW
      "totalAttendedLabel": "71h 3m",   // optional convenience label
      "regularLabel": "64h",
      "overtimeLabel": "7h 3m"
    },
    "summarised": {                     // NEW — per-DAY rollup (Summarised view + OT bar)
      "content": [
        {
          "attendanceDate": "2026-06-11",
          "regularMinutes": 480,
          "overtimeMinutes": 16,
          "totalMinutes": 496,
          "breakMinutes": 71,
          "hasOvertime": true,
          "hasSystemClosedSession": true   // a session was auto-closed (signedOutMethod=SYSTEM)
        }
        // ... one per attended day
      ],
      "page": 0, "size": 10, "totalElements": 8, "totalPages": 1
    },
    "separate": {                       // per-SESSION rows (Separate view) — today's records + new fields
      "content": [
        {
          "attendanceRecordCode": "AR_88231",   // needed for edit/delete
          "attendanceDate": "2026-06-11",
          "classroomCode": "CR_6YP",
          "classroomName": "6-Yellow-P",
          "signedInTime": { "hour": 14, "minute": 14 },
          "signedInBy": "Spandana",
          "signedInMethod": "APP",
          "signedOutTime": { "hour": 17, "minute": 30 },
          "signedOutBy": "System",
          "signedOutMethod": "SYSTEM",          // NEW — distinguishes auto-close (see tech doc §4.1)
          "closeType": "SYSTEM_CLOSED",         // NEW — NORMAL | SYSTEM_CLOSED | ADMIN_CORRECTED
          "attendedMinutes": 196,               // per-session worked minutes
          "sequenceNumber": 1,
          "totalSequenceCount": 1,
          "version": 3                          // NEW — optimistic lock for edit
        }
      ],
      "page": 0, "size": 10, "totalElements": 12, "totalPages": 2
    }
  }
}
```

**Key contract notes for the backend dev:**
- **Regular/Overtime are per-DAY, not per-session.** OT = `max(0, dayWorked − dailyRegularMinutes)`. Put them in `summarised`, not `separate`.
- `summarised` and `separate` are independently paginated (Summarised shows ≤31 day rows; Separate shows many session rows).
- Absent days stay on the **existing** absent-toggle endpoint — no change there.
- Send integer minutes; labels optional. Don't send pre-rounded hours only — the client needs minutes for the bar proportions.
- `signedOutMethod=SYSTEM` + `closeType` are the honest-missing-punch fields from the tech doc; if backend can't add them day-1, default `closeType:"NORMAL"` and the UI degrades gracefully.

---

## 4. Mock data (drop-in for Phase 1)

Mirror the JSON exactly so the swap in Phase 3 is mechanical. Sketch:

```dart
// lib/presentation/features/attendance/overtime/mock/staff_overtime_mock.dart
class StaffOvertimeMock {
  static StaffOvertimeProfile get sample => StaffOvertimeProfile(
    staffName: 'Devi Vempati',
    designation: 'Teacher',
    classroomName: '4-Yellow-D',
    attendedDays: 8,
    absentDays: 2,
    dailyRegularMinutes: 480,
    totalRegularMinutes: 3840,   // 64h
    totalOvertimeMinutes: 423,   // 7h 3m
    totalBreakMinutes: 0,
    days: const [
      StaffOvertimeDay(date: '2026-06-11', regular: 480, overtime: 16, total: 496, breaks: 71, systemClosed: true),
      StaffOvertimeDay(date: '2026-06-10', regular: 480, overtime: 85, total: 565, breaks: 0),
      StaffOvertimeDay(date: '2026-06-08', regular: 480, overtime: 81, total: 561, breaks: 0),
      StaffOvertimeDay(date: '2026-06-05', regular: 480, overtime: 88, total: 568, breaks: 0),
      StaffOvertimeDay(date: '2026-06-04', regular: 480, overtime: 150, total: 630, breaks: 0),
      // ...
    ],
    sessions: const [/* per-session rows for Separate view */],
  );
}
```

---

## 5. The one decision to make during Phase 2

On mobile, how should **Summarised vs Separate** be presented? (Recommendation below; confirm when you eyeball the UI.)

- **Recommended:** add a `Summarised ⇄ Separate` toggle (matching web). Summarised = per-day cards with Regular/OT/Total/Break; Separate = existing per-session expansion tiles. The existing `Show Absent` toggle stays as a third state or a separate switch.
- Alternative: skip the toggle, show Regular/OT/Break inline inside each existing day card (simpler, less faithful to web).

---

## 6. Risk notes

- The profile screen currently parses JSON inline with no model. Upgrading it to cubit+entity is the right call (you asked for it) but touches a working screen — keep the `kUseOvertimeMock` flag and the old code path until the new one is verified.
- The mobile screen has multi-session/transfer logic (sequenceNumber/totalSequenceCount, lines 542–574). The Summarised per-day rollup must sum across those sessions — make sure the backend's `summarised` already does this so the client doesn't re-derive it.
