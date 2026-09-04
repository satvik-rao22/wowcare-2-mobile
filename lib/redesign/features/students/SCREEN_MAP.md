# M05 Students — design to code

Eight phone screens, `5a`–`5h`. Students is reached from More, so every route
here is a child of the dashboard branch and no tab lights up while it is open.
The roster stays inside the shell; everything under it covers the tab bar,
because each of those screens owns the bottom of its own body.

| ID | Design title | Screen here | Cubit | Existing source | Repository method | ApiPaths | Role gate |
|---|---|---|---|---|---|---|---|
| 5a | Student roster · live | `presentation/pages/students_page.dart` + `widgets/student_roster_row.dart`, `student_row_details.dart`, `roster_group_section.dart`, `upcoming_student_row.dart`, `bulk_action_bar.dart`, `select_mode_key.dart` | `StudentsRosterCubit` | `students/view/student_screen.dart`, `widgets/student_card.dart`, `widgets/student_action_panel.dart` | `getStudentPage`, plus `GetStudentTodaySignInStatusMapUseCase` and `GetStudentAttendanceExpectedSummaryUseCase` | `studentList`, `studentAttendanceProfile` | Admin writes, Staff reads own classroom, Guardian refused |
| 5a | More actions, over a row | `widgets/student_actions_sheet.dart` + `student_action_row.dart` | `StudentsRosterCubit` | `students/widgets/student_action_panel.dart`, `student_attendance_action_availability.dart` | — (four of the five doors belong to other modules) | — | Admin |
| 5b | Filter, over the list | `widgets/students_filter_sheet.dart` + `multi_select_dropdown.dart`, `students_filter_chip.dart`, `choice_row.dart` | `StudentsRosterCubit` | `students/view/student_filter_screen.dart`, `widgets/_tags_loader.dart`, `custom_multi_select_dropdown` | `getStudentPage`'s `status` / `classroomCodes` / `tagCodes` / `guardianCodes` / `attendanceStatuses`, `GetTagNamesForSchoolUseCase` | `studentList`, `studentTags` | Admin and Staff |
| 5c | Student profile · live, every tab | `presentation/pages/student_profile_page.dart` + `widgets/profile_tab_body.dart`, `profile_tab_pills.dart`, `student_profile_header.dart`, `detail_fields_card.dart`, `profile_note.dart`, `person_card.dart`, `immunization_row.dart`, `attendance_day_row.dart`, `document_row.dart`, `ringed_avatar.dart`, and `presentation/profile_fields.dart` | `StudentProfileCubit` | `students/view/student_profile_screen.dart`, `student_profile_tab_cards/*`, `student_health_tab_cards/*`, `student_profile_screen_tabs/*`, `attendance/view/student_attendance_profile.dart` | `getStudentProfile`, `getStudentRegularSchedules`, `getStudentGuardians`, `getStudentPickups`, `getStudentHealth`, `getStudentPhysician`, `getStudentPhysicalExams`, `getStudentImmunizations`, `getStudentImportantDates`, `getStudentDocuments` | `studentProfile`, `studentRegularSchedules`, `studentHealth`, `studentImmunization`, `studentPhysicalExams`, `studentImportantDates`, `studentDocuments`, `studentAttendanceProfile` | Admin edits, Staff reads; the family may edit Health when the center allows it |
| 5d | Add a student · live, three steps | `presentation/pages/add_student_page.dart` + `widgets/wizard_step_list.dart`, `add_student_details_step.dart`, `add_student_guardian_step.dart`, `add_student_schedule_step.dart`, `schedule_week_card.dart`, `sibling_link_sheet.dart`, `date_field.dart` | `AddStudentCubit` | `students/view/add_student_wizard_screen.dart`, `add_student_step1–3_screen.dart`, `widgets/same_last_name_siblings_dialog.dart` | `createStudent`, `addStudentSibling`, guardian create/link, regular-schedule write | `studentList`, `studentSiblings`, `studentRegularSchedules` | Admin |
| 5e | Edit details, with two problems | `presentation/pages/edit_student_page.dart` + `widgets/tag_editor_field.dart` | `EditStudentCubit` | `students/view/edit_student_profile_details_screen.dart`, `view/student_tags_edit_sheet.dart` | `updateStudentProfile`, `updateStudentAddress`, tag write | `studentProfileUpdate`, `studentAddress`, `studentTags` | Admin |
| 5f | Uploading a document · live | `presentation/pages/student_documents_page.dart` + `widgets/upload_document_card.dart`, `document_row.dart` | `StudentDocumentsCubit` | `students/view/add_document_screen.dart`, `cubit/student_document_cubit.dart`, `student_documents_list_cubit.dart` | `getStudentDocuments`, `addStudentDocument` | `studentDocuments` | Admin, and a parent where the center allows it |
| 5g | When the list has nothing to say · live | `widgets/students_edge_state.dart`, `students_banner.dart`, drawn by `students_page.dart` | `StudentsRosterCubit` | `student_screen.dart`'s empty and error branches, `students/module_access.dart` | same as 5a | same as 5a | its four states are the four personas and connections a roster can have |
| 5h | Deactivate, and what it costs | `widgets/deactivate_student_sheet.dart`, opened from 5a's actions sheet | `StudentsRosterCubit` | `student_screen.dart`'s deactivate flow | `deactivateStudent` (`reactivateStudent` and `deleteStudent` stay on the Inactive list) | `studentDeactivate` | Admin |

The two tablet frames, `T8 Tablet Students` and `T10 Tablet Add Student`, are
the same records side by side. They are not built: the redesign is phone-first
and no responsive layer exists yet.

## Routes

All relative to the dashboard branch root, so back returns to the dashboard.

| Path | Screen | Navigator |
|---|---|---|
| `students` | 5a, 5b, 5g, 5h | shell (the tab bar stays) |
| `students/new` | 5d | root (`parentNavigatorKey`) |
| `students/:studentId` | 5c | root |
| `students/:studentId/edit` | 5e | root |
| `students/:studentId/documents` | 5f | root |

`AppRoutes` already carried `students`, `addStudent`, `student(id)` and
`editStudent(id)`. One line was appended to its M05 section:
`studentDocuments(id)`.

The path parameter is `studentId` rather than `id` on purpose: go_router
checks path parameter names across the whole route tree, so a bare `id` would
collide with the next module that wants one.

## Cubits

| Cubit | Status enum | What it is for |
|---|---|---|
| `StudentsRosterCubit` | `loading, ready, failed, offline, restricted` | 5a, 5b, 5g, and 5h's write |
| `StudentProfileCubit` | `loading, ready, failed` | 5c |
| `AddStudentCubit` | `editing, saving, saved, failed` | 5d |
| `EditStudentCubit` | `loading, ready, saving, saved, failed` | 5e |
| `StudentDocumentsCubit` | `loading, ready, failed` for the list, `idle, sending, done, failed` for the upload | 5f |

"No students yet" and "nobody called Kowalski" are both `ready`: they are the
same fetch with different answers, and the state tells them apart with
`isEmptySchool` and `hasNoResults`.

## Persona

Read off `SessionCubit` and passed into the cubit, so a screen never asks who
is looking.

* **Admin** sees the school, gets the add key, select mode, More actions, the
  Edit keys and Deactivate.
* **Staff** see the classroom they are rostered to, with the recessed note
  saying so, and no write key anywhere.
* **Guardian** never reaches the module: the roster answers with 5g's
  view-only state rather than an empty list.

Persona is fixed for the life of a screen. If 13d flips it while the roster is
open, the roster returns to the dashboard rather than redrawing an Admin's
list with a Guardian's rights.

## Free, and costly

From the module's rule-zero audit:

* **Free, and built.** Today's attendance per student: the dot on each avatar
  and the tally on each classroom header both come off the sign-in status map
  the list already loads. The school's own tag list, which is why Tags is a
  searchable dropdown and not four chips. Immunization due date, status and
  exemption reason, which is what puts the overdue line at the top of the
  Immunization tab.
* **Costly, and not built.** A required-documents checklist or a "Missing"
  document status: only expiry counts are returned, so `StudentDocumentItem`
  has no missing state. An authorized-days schedule or a not-authorized flag
  on a pickup record: a pickup person's card says what is on the record and
  nothing more.

## Added beyond the frames

* **A save confirmation.** 5d and 5e do not draw what happens after Save. Both
  toast and pop, and the roster reloads silently behind them.
* **A parent search result list in 5b.** The frame draws the search field and
  a chosen parent, but not the step between. Matching names appear as chips
  under the field, capped at six so the section stays a filter.
* **A sibling picker on step one.** The frame's "Link a sibling" well opens
  nothing; here it opens the same candidates the wizard's own check found.
* **A document type and expiry on 5f are required before a file is sent.** The
  frame shows both filled in; the key is off until the type is picked, so an
  untyped file cannot be uploaded.
* **`DockedBar`.** A key's face is centred inside its own surface, so given a
  tall bounded slot it stretches to fill it, and a `Scaffold`'s bottom slot is
  exactly that. The docked bars measure their keys first.
* **`DashedOutlineBox`.** Flutter's `Border` has no dash, and three of these
  frames draw one. Painted, in the dashed-line token.
* **Tag chips are pills.** The frames give them a 9px corner, which is not on
  the radius ladder; at that height a pill reads as the same shape.

## Not wired yet

* **The way in.** More's Students tile still shows the "being rebuilt" toast:
  `more_page.dart` belongs to M03 and is not this module's to edit. The route
  is live at `/dashboard/students` in the meantime.
* **Four of the five doors in the actions sheet** (Sign In or Sign Out, Add an
  activity, Message the family, and every "Edit" on a section of 5c other than
  About) belong to M04, M08 and M09. They toast rather than pushing a route
  that does not exist.
* **Sign Out on 5c** and the bulk Sign In on 5a are the attendance form, which
  is M04's.

## Reaching the edge states in the preview

`PreviewStudentsSource` follows `PreviewAuthSource`'s precedent and answers to
two literals, so 5g can be seen without unplugging anything:

* searching **`offline`** returns the saved-on-this-phone roster;
* searching **`empty`** returns a school with no students yet;
* signing in as a **Guardian** is refused outright.

5f's failed upload is every other attempt, so Failed and its Retry are both
one tap away.
