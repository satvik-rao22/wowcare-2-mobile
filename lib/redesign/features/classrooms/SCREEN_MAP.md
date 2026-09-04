# M07 Classrooms — design to code

Ten phone screens, `7a`–`7j`. Classrooms owns the third shell branch, so its
list is a slot root and everything else drills down from it. Paths relative to
`lib/presentation/features/` in the "Existing source" column; the design folder
writes `classrooom/`, which is `classroom/` on `develop`.

| ID | Design title | Screen here | Cubit | Existing source | Usecase / repository | ApiPaths | Role gate |
|---|---|---|---|---|---|---|---|
| 7a | Classrooms list · live | `presentation/pages/classrooms_page.dart` + `widgets/school_impact_card.dart`, `classroom_card.dart` | `ClassroomsCubit` | `classroom/views/screens/classroom_screen.dart`, `classroom_overview_screen.dart`, `classroom/cubit/classroom_cubit.dart` | `GetActiveClassroomsUseCase`, school capacity / FTE / by-classrooms attendance summary | `classroomPaginated`, `classroomAll`, `studentAttendanceExpectedSummaryCardByClassrooms` | Admin sees the floor; Staff never reach it (see 7e); the create key is dead for everyone else |
| 7b | No classrooms yet | same page, `_EmptyFloor` | `ClassroomsCubit` (`ready`, empty board) | `classroom_overview_screen.dart` empty branch | same list call | `classroomPaginated` | Admin only for the key |
| 7c | One classroom · live, every tab | `presentation/pages/classroom_page.dart` + `widgets/classroom_head_card.dart`, `classroom_tabs.dart`, `students_tab.dart`, `staff_tab.dart`, `notes_tab.dart`, `roster_row.dart`, `staff_row.dart`, `select_action_bar.dart` | `ClassroomCubit` | `classroom/views/classroom_tab_cards/classroom_students_tab_card.dart`, `classroom_staff_tab_card.dart`, `classroom_notes_tab_card.dart`, `views/widgets/classroom_student_list_item.dart`, `cubit/classroom_staff_cubit.dart`, `classroom_students_cubit.dart` | `GetStaffClassroomsUseCase`, student-classroom list, classroom notes | `staffClassrooms`, `studentClassroom` | Admin: three tabs, Select and the two refusals. Staff and Guardian: read only |
| 7d | Filter, over the classroom · live | `widgets/student_filter_sheet.dart`, `widgets/staff_filter_sheet.dart` (opened with `showAppSheet`) | `ClassroomCubit` (`studentFilters`, `staffFilters`) | `classroom/views/filters/classroom_student_filter_screen.dart`, `classroom_staff_filter_screen.dart`, `designation_display_utils.dart` | the same two list calls, re-queried | `staffClassrooms`, `studentClassroom` | all |
| 7e | A teacher's classroom · live | same `classroom_page.dart` (`isOwn: true`) + `widgets/teacher_clock_card.dart`, `over_ratio_alert.dart`, `classroom_mini_card.dart`, `locked_overlay.dart` | `ClassroomCubit` (`isTeacherView`, `isLocked`) | `classroom_students_tab_card.dart`, `attendance/util/attendance_permission_service.dart`, the staff-attendance self clock-in form | staff attendance sign-in | staff attendance endpoints | Staff, on their own classroom. It is what the Classrooms slot opens for them |
| 7f | Classroom profile · live upload | `presentation/pages/classroom_profile_page.dart` + `widgets/photo_well.dart`, `places_card.dart`, `day_breakdown_card.dart`, `movements_card.dart`, `center_ratio_card.dart` | `ClassroomProfileCubit` | `classroom/views/screens/classroom_info_screen.dart`, `classroom/utils/classroom_age_range.dart`, entities `classroom_details.dart`, `ratio_monitoring_classroom.dart`, `school_capacity.dart`, `school_fte.dart` | classroom details, school capacity, school FTE, by-classrooms attendance summary, movements by classroom | `classroomPaginated`, `studentAttendanceExpectedSummaryCardByClassrooms` | Admin edits; everybody else looks |
| 7g | Assign students · live, both steps | `presentation/pages/assign_page.dart` (`AssignKind.students`) + `widgets/assign_step_rail.dart`, `assign_candidate_row.dart`, `changes_card.dart` | `AssignCubit` | `classroom/forms/assign_student_to_classroom_form.dart` | assign student to classroom | `studentClassroomAssignStudent` | Admin |
| 7h | Assign Staff · review step | same page (`AssignKind.staff`) + `widgets/info_well.dart` | `AssignCubit` | `classroom/forms/assign_staff_to_classroom_form.dart`, entities `staff_classroom/entities/staff_classroom_item.dart` | assign staff to classroom | `staffClassroomsAssignStaff`, `staffClassroomsManageStaffList` | Admin |
| 7i | When it says no · live | `widgets/move_blocked_sheet.dart`, `widgets/remove_student_sheet.dart`, and the view-only toast on every refused key | `ClassroomCubit` (`canEdit`, `moveStudent`, `removeStudent`) | `classroom_students_tab_card.dart` remove and transfer paths, `attendance/util/attendance_permission_service.dart` | student-classroom update and delete | `studentClassroom` | Admin. A refused persona gets the toast rather than the sheet |
| 7j | Four states · live | `widgets/classroom_state_view.dart`, plus `OfflineBanner` on a cached screen and `ErrorState` on a failed one | `ClassroomsCubit` / `ClassroomCubit` `Status` | `classroom_students_tab_card.dart` empty and error branches | — | — | The view-only screen is what a non-Admin gets on a classroom with nobody on the roll |

## The cubits, and the states they drive

| Cubit | Status | What it holds |
|---|---|---|
| `ClassroomsCubit` | `loading · ready · cached · failed` | the board, the search box, the three chips |
| `ClassroomCubit` | `loading · ready · cached · failed` | one classroom, its tab, its filters, select mode, the open row, the teacher's clock |
| `ClassroomProfileCubit` | `loading · ready · cached · failed` plus `PhotoUploadStatus idle · uploading · done · failed` | the record and its photo well |
| `AssignCubit` | `loading · ready · failed · submitting · done` | both assign flows: the candidates, the picks, the step |
| `CreateClassroomCubit` | `editing · saving · saved · failed` | the create form and its per-field errors |

`cached` is 7j's offline screen: a call that failed with something already on
screen keeps it and says how old it is, and only a call that failed with
nothing to show fails outright.

## Ratio

Never a figure. `ClassroomSummary` carries `allowedRatio` and does the
arithmetic the dashboard's `RatioMonitoringClassroom` does:

```
staffNeeded = max(0, ceil(studentsPresent / allowedRatio) - staffPresent)
```

Two live states come out of it — In Ratio, or `+N staff` — plus the two quiet
ones a classroom with nobody in it is allowed to be: **No staff in** (students
on the roll, nobody on the clock) and **Empty** (nobody on the roll). Counts
are written students first everywhere they are read out: `19 in · 2 staff`.

## Routes

`classroomsRoutes` are relative children of the `/classrooms` branch root.
They stay relative even where they cover the tab bar: go_router concatenates a
child's path onto its parent's, so an absolute `/classrooms/new` under
`/classrooms` would resolve to `/classrooms/classrooms/new`. What lifts a
screen over the tab bar is `parentNavigatorKey: rootNavigatorKey`.

| Path in `AppRoutes` | Route | Over the tab bar |
|---|---|---|
| `/classrooms` | `buildClassroomsRoot` → `ClassroomsPage` | no, it is a slot |
| `/classrooms/new` | `new` → `CreateClassroomPage` | yes |
| `/classrooms/:id` | `:id` → `ClassroomPage` | no |
| `/classrooms/:id/profile` | `profile` → `ClassroomProfilePage` | no |
| `/classrooms/:id/assign-students` | `assign-students` → `AssignPage` | yes |
| `/classrooms/:id/assign-staff` | `assign-staff` → `AssignPage` | yes |

`new` is declared before `:id`, because go_router matches in order and
`/classrooms/new` would otherwise open a classroom whose code is "new".
Nothing was appended to `AppRoutes`: its M07 section already carried all six.

## Added, beyond the frames

* **Create a classroom** (`presentation/pages/create_classroom_page.dart`).
  7a and 7b both lead with the key and the frames stop there, so this is the
  smallest step it can open: name, the two age bounds in months, capacity and
  students per staff, validated, then back to the floor with a toast. It is
  the only place in the module a ratio is typed as a number.
* **Assign students from the roster.** 7c draws the Assign Staff key on the
  Staff tab and nothing on the Students tab, which leaves no way into 7g for a
  classroom that already has students. The Students tab carries the same
  extended key.
* **More actions** on an open roster row opens a two-line sheet, Move
  classroom and Remove from classroom, which is what leads into 7i's two
  refusals. The frame draws the key and not what it opens.
* **A move picker.** 7i refuses the move and names the alternatives; picking
  which classroom a student who is not signed in moves to is a plain
  single-select sheet over the other classrooms.

## Not built

The module's `costly` list, in full:

* A future-dated classroom move from the assign flow. Assign applies now, and
  the review step says so out loud: "Applies · Immediately, on submit". A move
  already booked in Movements is *shown* on the roster row and on the profile,
  and neither screen books one.
* A per-weekday capacity or ratio projection.
* Sign-in PINs on classroom staff rows.

The `free` entry — the classroom forecast's expected students, ratio rule,
required staff and scheduled staff per thirty-minute block — belongs to
Scheduling's forecast call (`staffShiftClassroomForecast`), which M14 owns. It
is read here as the one line the Staff tab already draws: how many staff there
are for how many students, and how many are wanted.

## Fixtures

`PreviewClassroomsSource` builds Maple View's five classrooms from
`DemoData.classroomNames`. Sunflower and Bluebell carry the demo school's own
rosters (`DemoData.sunflower`, `DemoData.bluebell`) and every staff member is
somebody the rest of the app already knows; Acorn, Willow and Maple carry the
frames' counts and are drawn on the floor rather than opened.

The school-level figures on the navy card are the frames' own and are not a
sum of the cards below them, which is also how the real screen gets them:
capacity, FTE and the attendance summary are three separate calls, none of
them the classroom list.
