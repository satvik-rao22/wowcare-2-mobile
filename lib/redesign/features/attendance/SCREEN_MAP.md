# M04 Attendance — design to code

Six phone frames, `4a`–`4f`. Attendance owns the second shell branch, so the
day list is a slot root and the two forms and the range view hang off it.
Paths relative to `lib/presentation/features/` in the "Existing source"
column.

| ID | Design title | Screen here | Cubit | Existing source | Usecase / repository | ApiPaths | Role gate |
|---|---|---|---|---|---|---|---|
| 4a | Attendance · live | `presentation/pages/attendance_page.dart` + `widgets/attendance_body.dart`, `attendance_row.dart`, `attendance_row_details.dart`, `attendance_group_section.dart`, `attendance_day_strip.dart`, `attendance_filter_chips.dart`, `attendance_select_key.dart`, `attendance_select_bar.dart`, `record_actions_sheet.dart`, `guardian_child_card.dart`, `guardian_day_row.dart` | `AttendanceCubit` | `attendance/view/student_attendance_tabbed_view.dart`, `view/screens/student_attendance_daily_view.dart`, `view/screens/widgets/student_attendance_card.dart`, `student_attendance_summary.dart`, `student_attendance_filters.dart`, `cubit/student_attendance_daily_cubit.dart`, `widgets/student_attendance_card.dart` | `getStudentAttendanceDaily`, `getStudentAttendanceExpectedSummary`, `getStaffAttendanceExpectedSummary` | `studentAttendanceDailyView`, `studentAttendanceExpectedSummaryCard`, `staffAttendanceExpectedSummaryCard` | Admin: both lists, every write key. Staff: their own classroom, and only once they have signed themselves in. Guardian: their own children, Sign Out only |
| 4b | Pick a day, or a range | `widgets/day_picker_sheet.dart`, opened from the day strip | `AttendanceCubit.chooseDay` / `stepDay` | `student_attendance_tabbed_view.dart` Daily / Custom tabs, `util/attendance_school_time.dart` | the same daily call with a different `attendanceDate`; a range goes to the custom call | `studentAttendanceDailyView`, `studentAttendanceCustomView` | Anyone who can read the list. A guardian gets three options, not four: their own month is already on 4a |
| 4c | Staff, and cover for a gap | same page, `audience: staff` + `widgets/staff_gap_card.dart`, `attendance_scope_note.dart` | `AttendanceCubit` (`AttendanceAudience.staff`) | `attendance/view/staff_attendance_tabbed_view.dart`, `view/screens/staff_attendance_daily_view.dart`, `view/screens/widgets/staff_attendance_card.dart`, `staff_attendance_summary.dart`, `cubit/staff_attendance_daily_cubit.dart` | `getStaffAttendanceDaily`, `getStaffAttendanceExpectedSummary` | `staffAttendanceDailyView`, `staffAttendanceExpectedSummaryCard` | Admin. A staff member never sees the staff list; they see their own card on 4d |
| 4d | Teacher · me first, then my classroom | same page, `Persona.staff` + `widgets/self_shift_card.dart`, `students_locked_card.dart` | `AttendanceCubit` (`isLocked`, `signSelfIn`, `signSelfOut`) | `util/attendance_permission_service.dart`, `forms/staff_attendance_forms/staff_sign_in_form.dart`, `presentation/features/geofencing/cubit/geofence_cubit.dart` | `submitStaffSignIn`, `submitStaffSignOut` | `staffAttendanceRecordsSignIn`, `staffAttendanceRecordsSignOut` | Staff, on their own shift. The classroom under it is legible and inert until they are signed in |
| 4e | Nothing to show, and nothing loaded | same page + `widgets/attendance_notice_card.dart`, `attendance_empty_card.dart`, and `ErrorState` on a failed fetch | `AttendanceCubit` `Status` | `student_attendance_daily_view.dart` empty and error branches, `student_attendance_shimmer.dart`, `loadCachedStudentAttendanceDaily` | the same daily call, and the cache behind it | `studentAttendanceDailyView` | all |
| 4f | A date range — attended days and time | `presentation/pages/attendance_range_page.dart` + `widgets/range_strip.dart`, `range_row.dart`, `loading_more_row.dart` | `AttendanceRangeCubit` | `attendance/view/screens/student_attendance_custom_view.dart`, `staff_attendance_custom_view.dart`, `cubit/student_attendance_custom_cubit.dart`, `staff_attendance_custom_cubit.dart` | `getStudentAttendanceCustom`, `getStaffAttendanceCustom` | `studentAttendanceCustomView`, `staffAttendanceCustomView` | Admin and Staff. A guardian has no range view |
| — | Sign In / Sign Out | `presentation/pages/sign_attendance_page.dart` + `widgets/sign_person_tile.dart`, `unexpected_sign_in_card.dart`, `attendance_date_field.dart`, `attendance_time_field.dart` | `SignAttendanceCubit` | `forms/student_attendance_forms/student_sign_in_form.dart`, `student_sign_out_form.dart`, `student_selection_sign_in_form.dart`, `widgets/unexpected_sign_in_attention_dialog.dart`, `forms/attendance_time_parse_util.dart` | `createStudentSignInRecords`, `submitStudentSignOut`, `submitStaffSignIn`, `submitStaffSignOut` | `studentAttendanceRecordsSignIn`, `studentAttendanceRecordsSignOut`, `staffAttendanceRecordsSignIn`, `staffAttendanceRecordsSignOut` | Admin, and Staff once signed in. Gated on the geofence and on the unexpected-sign-in acknowledgement |

## The cubits, and the states they drive

| Cubit | Status | What it holds |
|---|---|---|
| `AttendanceCubit` | `loading · ready · failed · offline` | one day: the audience, the day, the chip, the classroom filter, the search, the open row, select mode, the staff member's own shift |
| `AttendanceRangeCubit` | `loading · ready · failed` plus `isLoadingMore` | a range: the audience, the two dates, the classroom multi-select, the search, and the page it is on |
| `SignAttendanceCubit` | `loading · editing · submitting · done · failed` | the two forms: who, the Date, the Time, the geofence and the acknowledgement |

`offline` is 4e's third card: a call that failed with something already on
screen keeps it, says how old it is and goes read only; a call that failed
with nothing to show fails outright. The range has no offline state, because
a range is a report and nothing about it is written.

## Create attendance is Sign In

There is no create-attendance endpoint and the module does not pretend there
is one. The pink FAB on 4a does not open a form: it puts the list into
select mode, and the docked key under the selection opens the Sign In form
with whoever was picked already on it. A record is made by signing somebody
in and closed by signing them out; signing in somebody who already went home
makes a second row rather than overwriting the first, and the record sheet
says so.

Both forms take **exactly two fields, Date and Time**, over removable person
tiles. Nothing is behind a disclosure. `signedInBy` and `signedOutBy` are
never typed: the API takes them from the staff or guardian code on the call,
and the form says so in a footnote. Two gates stand in front of the key, both
of them the app's own: the device has to be on site, and a sign-in that
includes somebody who is not expected today has to be acknowledged first,
which is `unexpected_sign_in_attention_dialog.dart` written into the form
instead of on top of it.

## Free, and built

All three of the module's `free` entries are on screen:

* **The method on every row, and who took it.** `signedInMethod` and
  `signedOutMethod` come back as GPS, PIN, QR or APP on every daily row and
  no screen has ever drawn them. The row's second line reads
  `Sunflower · in 8:12 · PIN`, the open record puts `8:12 · PIN` against
  Signed In with the name under it, and the record sheet writes it out:
  "By Dana Whitfield on the kiosk pad."
* **The whole transfer trail.** From and to classroom, which stint of the day
  this is, when the next move is due, who moved them and why. Four more lines
  in the open record, on the rows that have a trail.
* **`isExpectedToday` on every daily row.** The honest replacement for an
  arrival time the API does not hold. It is the row's second line when nobody
  has been marked (`Sunflower · not expected today`), the Expected line in the
  open record, a flag on the person tile in the form, and the thing the
  acknowledgement gate is about.

**Time on the clock** is the fourth: `AttendanceFormats.between` subtracts the
two times the row already carries, so Duration in an open record, "1h 53m on
the clock" on a teacher's own card, and "Here 1h 29m so far" in the record
sheet are all worked out on the device with no server sum.

**Override Sign In** is wired: the form was already built and nothing opened
it. On an absent record the sheet's pink key says Override Sign In, deletes
the absence record and opens the sign-in form on that one student.

## Not built

The module's `costly` list, in full:

* A note field on Sign In and Sign Out. The two forms take a Date and a Time
  and nothing else. Only **Mark Absent** takes a reason, which is the one
  action in the module that needs one.
* An expected arrival time per student. `AttendanceRecord.expectedTime` is a
  staff member's rostered shift start, which the app does hold, and is null
  for a student. `isExpectedToday` stands in its place everywhere a frame
  drew "Expected 8:30" against a student.
* Any free-text reason on a row. An absence reason is shown because the
  absence record carries one; nothing else on a row is free text.
* An offline outbox. 4e says so out loud: "Nothing is queued — sign-ins will
  save once you are back online." An offline day is read only, and the state
  that draws it turns every write key off.

## Vocabulary

The frames write "Clocked in", "Clock out" and "Clock myself in" on the staff
side. This module does not: the app's own words are **Sign In / Signed In /
Sign Out / Signed Out / Not Marked / Absent / Mark Absent / Transfer /
Override Sign In**, `AppStrings` carries no "clock", and a staff member signs
in exactly the way a student does. That is the one place the copy departs
from a frame, and it is deliberate. "Check in" and "check out" appear
nowhere.

The frame's sheet also says "Move classroom" and "Sign In anyway"; the
canonical verbs are **Transfer** and **Override Sign In**, which is what the
sheet says here.

## Routes

`attendanceRoutes` are relative children of the `/attendance` branch root.
They stay relative even where they cover the tab bar: go_router concatenates
a child's path onto its parent's, so an absolute `/attendance/sign-in` under
`/attendance` would resolve to `/attendance/attendance/sign-in`. What lifts a
screen over the tab bar is `parentNavigatorKey: rootNavigatorKey`.

| Path in `AppRoutes` | Route | Over the tab bar |
|---|---|---|
| `/attendance` | `buildAttendanceRoot` → `AttendancePage` | no, it is a slot |
| `/attendance/sign-in` | `sign-in` → `SignAttendancePage` | yes |
| `/attendance/sign-out` | `sign-out` → `SignAttendancePage` | yes |
| `/attendance/range` | `range` → `AttendanceRangePage` | no, it is still a list |

`sign-in`, `sign-out` and `range` are all literal segments and nothing here
takes a path parameter, so none of them can be read as a record code. The two
forms are about a *set* of people, which travels as a typed
`SignAttendanceArgs` on `extra`; a deep link that arrives with nothing opens
an honest empty form rather than crashing. The range takes a typed
`DateRange` the same way and falls back to this month to date.

`attendanceSignOut` is the one constant appended to `AppRoutes`; the M04
section already carried `attendance`, `attendanceSignIn` and
`attendanceRange`.

## Added, beyond the frames

* **A Sign Out form.** 4a's sheet and 4f draw the Sign Out key and stop
  there. It is the sign-in form the other way round, which is what the two
  existing forms are, so it is one page with a `SignKind`.
* **Mark Absent** (`widgets/mark_absent_sheet.dart`). The frames draw the key
  in the record sheet and not what it opens. A Date and a Reason, which is
  what `student_mark_absent_form.dart` asks for, minus the per-student notes
  the audit prices as costly.
* **Transfer.** The frame draws the key; picking the classroom is a plain
  single-select over the others, from core.
* **Edit times** (`widgets/edit_times_sheet.dart`). The same two fields as
  the sign-in form, because it is the same pair of values, over the most
  recent recorded time. It stays open to Admins on a past day, which is what
  4b's footnote promises, and it says out loud that it leaves an audit note.
* **A classroom filter** on 4a, behind the header's filter key. 4e's copy is
  about a classroom filter hiding somebody, and the frame draws the key with
  a dot on it, so the filter it implies is built: a multi-select over the
  classrooms on the list, cleared by 4e's own two keys.
* **A guardian with more than one child.** 4a's parent lens draws one child.
  Ngozi Okafor has two, so the lens draws a section per child — the card,
  then that child's month — using the frame's own components. With one child
  the header still reads "Amara's attendance".
* **Self sign-out.** 4d signs a teacher in; the navy card on 4a's staff lens
  draws the key that ends the shift, which locks the classroom back up.
* **View**, on an open range row, opens that person's record
  (`/dashboard/students/:id` or `/dashboard/staff/:id`). The frame draws the
  key and not its destination; the totals are a summary, and the record
  behind them is the only honest place to go.
* **Open Scheduling** and **See who is free** on 4c raise a toast rather than
  navigating, because M14 Scheduling and M11 Availability are not built yet.

## Fixtures

`PreviewAttendanceSource` is Maple View's day on 20 August 2026, the day the
design draws. The people, their statuses and their times are `DemoData`'s, so
the Sunflower list here is the same Sunflower the roster shows: **23 students,
15 signed in; 10 staff, 7 signed in**. Sunflower's header reads
`9 of 14 in · 1 staff · 1 more needed` and Bluebell's `6 of 9 in · 1 staff ·
In Ratio`, both worked out from `max(0, ceil(present / allowedRatio) -
staffPresent)` and both written as counts.

What attendance adds on top of a roster row is written in the source, because
it belongs to this module: the method each sign in and sign out was taken on,
who took it, whether the person was expected today, two transfer trails, the
staff shifts, and the absence reasons. Writes land in the source and are
folded over the fixtures on the next load, so signing somebody in on 4a is
still true when the list reloads behind the form.

Three literals reach the edge states without unplugging anything, the way
`PreviewAuthSource` reaches 1a's:

* searching **`offline`** returns the saved-on-this-phone day, read only;
* searching **`empty`** returns a school with nobody on the roll;
* searching **`outside`** puts the staff member outside the geofence, so
  their own sign-in is refused.

4d's locked state is the staff lens's own first moment and needs no literal:
the shift starts unsigned, and **Sign myself in** flips the screen into 4a's
staff lens.
