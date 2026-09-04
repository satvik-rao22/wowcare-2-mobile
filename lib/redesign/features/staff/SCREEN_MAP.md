# M06 Staff, design to code

Six phone screens, `6a` to `6f`. Staff is reached from More rather than from a
tab, so every screen here is a drill-down under the **dashboard** branch: back
returns to the dashboard and no tab lights up. Paths in the "Existing source"
column are relative to `lib/presentation/features/`.

| ID | Design title | Screen here | Cubit | Existing source | Usecase / repository | ApiPaths | Role gate |
|---|---|---|---|---|---|---|---|
| 6a | Staff roster, live | `presentation/pages/staff_page.dart` + `widgets/staff_row_card.dart`, `staff_counts.dart`, `upcoming_row.dart`, `staff_select_bar.dart`, `staff_actions_sheet.dart` | `StaffRosterCubit` | `staff/view/staff_screen.dart`, `staff/widgets/staff_list_item.dart`, `staff_card.dart`, `staff_action_panel.dart`, `staff/cubit/staff_cubit.dart` | `GetStaffPageUseCase`, `GetAllStaffUseCase`, `GetStaffCountUseCase` | `staffList`, `staffCount` | Admin gets the roster, Select and the pink FAB. Staff get 6e. Guardians are refused |
| 6b | Filter staff | `widgets/staff_filter_sheet.dart`, opened with `showAppSheet` | `StaffRosterCubit` (`filters`) | `staff/view/staff_filter_screen.dart` | the same list call, re-queried | `staffList` | Admin only, because only the roster has a filter key |
| 6c | Staff profile, live, every tab | `presentation/pages/staff_profile_page.dart` + `widgets/staff_profile_header.dart`, `staff_tabs.dart`, `profile_tab.dart`, `schedule_tab.dart`, `attendance_tab.dart`, `dates_tab.dart`, `documents_tab.dart`, `fact_card.dart`, `note_well.dart` | `StaffProfileCubit` | `staff/view/staff_profile_screen.dart`, `staff/widgets/staff_profile_tab.dart`, `staff_dates_tab.dart`, `staff_important_dates_tab.dart`, `staff_documents_tab.dart`, `staff/cubit/staff_profile_cubit.dart`, `important_dates_cubit.dart`, `staff_documents_list_cubit.dart`, `attendance/view/staff_attendance_profile.dart` | `GetStaffProfileUseCase`, `GetStaffShiftsUseCase`, `GetImportantDatesUseCase`, `GetStaffDocumentsUseCase`, `StaffRepository.getStaffSignInPin` | `staffProfile`, `staffSchedules`, `staffDates`, `staffDocuments`, `staffAttendanceProfile` | Admin reads it whole. A staff member reads their own whole and a colleague's down to the name, the classroom and a way to call |
| 6d | Add Admin or Staff, live, three steps | `presentation/pages/add_staff_page.dart` + `widgets/wizard_steps.dart`, `choice_row.dart`, `shift_editor_card.dart` | `CreateStaffCubit` | `staff/view/add_staff_screen.dart` (`_roleOptions`, `_adminDesignationOptions`, `_staffDesignationOptions`), `classroom_selection_widget_exact.dart`, `staff/cubit/create_school_user_cubit.dart` | `CreateSchoolUserUseCase` (`createSchoolAdminUser` / `createStaffUser`) | `schoolUsersStaff` | Admin |
| 6e | When staff is not yours to see, live | same `staff_page.dart` + `widgets/staff_banner.dart`, `own_record_card.dart`, `team_row.dart`, `staff_state_view.dart` | `StaffRosterCubit` (`denied`, `cached`, `failed`, and the view-only body) | `staff_screen.dart` role branches, `students/module_access.dart` | the same list call, scoped | `staffList` | Staff get the view-only screen, guardians the refusal, everybody the offline state |
| 6f | Deactivate a staff member | `widgets/deactivate_staff_sheet.dart` | `StaffRosterCubit.setActive` / `StaffProfileCubit.setActive` | `staff/widgets/staff_action_panel.dart` | `StaffRepository.deactivateSchoolUser` and `activateSchoolUser` | `schoolUsersStaff` | Admin, and never on their own record |

## Added beyond the frames

The frames draw the key and stop, so each of these is the smallest step that
key can lead to, built from the same components.

| What | Where | Why |
|---|---|---|
| Edit details, `/dashboard/staff/:id/edit` | `presentation/pages/edit_staff_page.dart` | 6c's fields card carries an Edit key. The form takes name, contact and address only: designation, role, classrooms and status decide what a staff member can reach, so an Admin sets them elsewhere. That is what lets a staff member keep their own details up to date safely |
| Work schedule, `/dashboard/staff/:id/schedule` | `presentation/pages/staff_schedule_page.dart` + `widgets/shift_editor_card.dart` | 6c's Schedule tab carries "Edit the week", and the roster's More actions sheet carries "Edit this week's shifts". **Admin only**, per the note on 13a: a work schedule is what a staff member is contracted to, not something they set for themselves. The cubit refuses before it fetches, so the route reached by hand is refused too |
| Add a document sheet | `widgets/add_document_sheet.dart` | 6c's Documents tab carries a dashed "Add a document" key. The sheet asks the two things the record needs, a name and a type; picking the file is the platform's job and no frame draws it |
| "Starting soon" section on 6a | `staff_page.dart`, `widgets/upcoming_row.dart` | The frame draws one dashed upcoming row under the roster. It is a section here because the roster's status filter defaults to Active, so a hire who has not started would otherwise be invisible until the filter was changed |

## The cubits, and the states they drive

| Cubit | Status | What it holds |
|---|---|---|
| `StaffRosterCubit` | `loading · ready · cached · failed · denied` | the roster, the search box, the filters and their chips, the open row, select mode |
| `StaffProfileCubit` | `loading · ready · saving · saved · failed` | one record, which tab is showing, the deactivate and the document write |
| `CreateStaffCubit` | `loading · editing · saving · saved · failed` | the wizard: the step, the draft, the options and the per-field errors |
| `EditStaffCubit` | `loading · editing · saving · saved · failed` | the edit form and its per-field errors |
| `StaffScheduleCubit` | `loading · editing · saving · saved · failed · denied` | the working week and the one thing that can be wrong with it |

`denied` is the refusal a persona gets before anything is fetched: a guardian
on the roster, and anybody but an Admin on a work schedule. `cached` is 6e's
offline banner over the team as it was; a call that failed with nothing on
screen fails outright into "Waiting for a signal".

## The read boundary

`StaffLens` is built once from `SessionCubit` and handed to every cubit as a
factory parameter, so a screen never has to remember to ask who is looking.
It is decided on the client and fails closed, exactly as `TaskPersona` does.

| Persona | Roster | A record | Writes |
|---|---|---|---|
| Admin | the school | whole | add, edit, classrooms, schedule, deactivate |
| Staff | their own record, and active colleagues who share one of their classrooms | their own whole; a colleague's down to the name, the classroom and a way to call | their own name, contact and address only |
| Guardian | refused, 6e's "Staff is closed for this school" | none | none |

A staff member with no classroom on the session sees no colleagues at all,
which is the closed side of failing closed.

## The Sign-In PIN

Read only, everywhere, and never called a Kiosk PIN or a clock PIN.

* 6c shows it on the Profile tab, to a viewer who may read the record whole.
* 6f names it in "What changes today", because deactivating stops it working.
* 6d has **no PIN field**, and the More actions sheet has **no "Change the
  Sign-In PIN" row**, although the frames draw both. `StaffRepository` exposes
  `getStaffSignInPin` and nothing that sets one, so resetting a PIN from the
  app is on the module's costly list and the app must not offer a key that
  cannot work.

## Rule zero, this module's audit

**Free, already returned and drawn nowhere:** nothing. Every field the
module's calls return is already drawn.

**Costly, not built:**

* Resetting a sign-in PIN from the app. The PIN endpoint is read only.
* Timesheets as a module. 6c's Attendance tab reports days and totals the
  month, and does no more: no export, no approval, no pay.

## Routes

`staffRoutes` are **relative** children of the `/dashboard` branch, including
the ones that cover the tab bar: go_router concatenates a child's path onto
its parent's, so an absolute `/dashboard/staff/new` declared under `/dashboard`
would resolve to `/dashboard/dashboard/staff/new`. What lifts a screen over
the tab bar is `parentNavigatorKey: rootNavigatorKey`. `new` is declared
before `:id`, or `/dashboard/staff/new` opens a staff member coded "new".

| Path in `AppRoutes` | Route | Over the tab bar |
|---|---|---|
| `/dashboard/staff` | `staff` → `StaffPage` | no |
| `/dashboard/staff/new` | `new` → `AddStaffPage` | yes |
| `/dashboard/staff/:id` | `:id` → `StaffProfilePage` | no |
| `/dashboard/staff/:id/edit` | `edit` → `EditStaffPage` | yes |
| `/dashboard/staff/:id/schedule` | `schedule` → `StaffSchedulePage` | yes |

Nothing was appended to `AppRoutes`: its M06 section already carried all five.

## Fixtures

`PreviewStaffSource` is Maple View's team. Every staff member is one of
`DemoData.staffMembers`, which already carries the name, the initials, the
designation, the scope, the Sign-In PIN and today's attendance. What the 6a
rows and the 6c tabs also draw, the phone, the email, the allowed classrooms,
the shift, the job tags and the dates, is added here from the frames' own
`_script.js`. One staff member is added beyond `DemoData`: Lena Fontaine,
upcoming, which is what the "Starting soon" tile and the dashed row need and
what the roster otherwise has nobody to show.

Two notes for Phase 5:

* The 6b designation chips are built from the designations the roster actually
  holds, while 6d offers `add_staff_screen.dart`'s two fixed lists. They are
  deliberately different questions: the filter offers what exists, the create
  form offers what the API accepts.
* Dates in fixtures are measured against `StaffProfile.asOf`, the school's own
  day, never `DateTime.now()`. Time in this app is school-timezone based.
