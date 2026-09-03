# M03 Dashboard and More — design to code

Eleven phone screens across three personas, plus More and Account. The design
folder's screen map still calls the dashboards `2A*` / `2S*` / `2P*`; the
module page renumbered them to `3A*` / `3S*` / `3P*`.

| ID | Design title | Screen here | Cubit | Existing source | Role gate |
|---|---|---|---|---|---|
| 3A1 | Admin dashboard, deck | `presentation/pages/dashboard_page.dart` + `widgets/admin_dashboard_body.dart` | `DashboardCubit` | `dashboard/view/admin_dashboard.dart`, `widgets/attention_grid.dart`, `my_day_card.dart`, `enrollment_card.dart` | Admin |
| 3A2 | Admin dashboard, scrolled | same body, further down | `DashboardCubit` | `widgets/ratio_monitoring_card.dart`, `classroom_shifts_card.dart`, `availability_card.dart`, `movements_card.dart`, `billing_card.dart` | Admin |
| 3A3 | Confirm sign out, time editable | `widgets/staff_day_sheet.dart` (`canAdjustTime: true`) | `DashboardCubit` | staff attendance forms, `attendance_permission_service.dart` | Admin |
| 3S1 | Staff dashboard | `widgets/staff_dashboard_body.dart` | `DashboardCubit` | `dashboard/view/staff_dashboard.dart`, `widgets/my_day_card.dart`, `ratio_monitoring_card.dart` | Staff |
| 3S2 | My shifts and my attendance | same body, further down | `DashboardCubit` | `widgets/my_shifts_card.dart`, `my_attendance_card.dart` | Staff |
| 3S3 | Confirm sign out, read-only | `widgets/staff_day_sheet.dart` (`canAdjustTime: false`) | `DashboardCubit` | staff attendance forms | Staff |
| 3P1 | My Child's day | `widgets/guardian_dashboard_body.dart` | `DashboardCubit` | `dashboard/view/parent_dashboard.dart`, `widgets/my_childs_day_card.dart`, `parent_child_cubit.dart` | Guardian |
| 3P2 | Attendance, billing, newsletters | same body, further down | `DashboardCubit` | `widgets/student_attendance_card.dart`, `student_billing_card.dart`, `student_newsletters_card.dart` | Guardian |
| 3P3 | Confirm sign out, parent | `widgets/child_sign_out_sheet.dart` | `DashboardCubit` | student attendance forms | Guardian |
| 3M | More | `presentation/pages/more_page.dart` | none, it reads the session | `shared/common/widgets/custom_drawer.dart`, `custom_navigation_bar.dart`, `students/module_access.dart` | Admin and Staff |
| 3M2 | Account | `presentation/pages/account_page.dart` | none, it reads the session | `custom_drawer.dart`'s account rows, `user_profile_screen.dart` | all |

## What the deck carries

`AttentionSummary.kinds` decides which cards exist, in this order: incidents,
ratio, shifts, movements, documents, checkups, billing. A card leaves the deck
when the thing behind it is dealt with and never because it was dismissed.

The `free` list in `_split/modules.json` adds one thing the attention cubit
already fetches and nothing drew: overdue and missing physical checkups for
students and staff, four counts. They are in `AttentionSummary` and get their
own card.

## Not wired yet

Every tile on More, and every card's own key, points at a module that has not
been rebuilt. Those show the "This screen is being rebuilt" toast rather than
pushing a route that does not exist. Kiosk mode and Scan QR are live, because
M01 is built.
