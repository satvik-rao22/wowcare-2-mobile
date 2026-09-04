# M13 My Profile — design to code

Six phone screens, `13a`–`13f`. My Profile is reached from the More page's
profile header, so every route here is a child of the dashboard branch and no
tab lights up while it is open. The record itself stays inside the shell; the
three screens under it cover the tab bar, because each owns the bottom of its
own body.

| ID | Design title | Screen here | Cubit | Existing source | Repository / usecase method | ApiPaths | Role gate |
|---|---|---|---|---|---|---|---|
| 13a | My Profile — persona and photo live | `presentation/pages/profile_page.dart` + `widgets/profile_hero_card.dart`, `hero_avatar.dart`, `photo_block.dart`, `profile_photo_sheet.dart`, `profile_detail_card.dart`, `value_field.dart`, `work_schedule_card.dart`, `profile_actions_card.dart`, `profile_action_row.dart`, `profile_note.dart` | `ProfileCubit` | `user-profile/view/user_profile_screen.dart`, `view_model/user_profile_cubit.dart`, `widgets/non_editable_info_widget.dart` | `StaffRepository.getStaffProfile`, the profile-photo upload session (open, stream, finalize), the photo delete | `staffProfilePath(staffCode)`, `staffProfilePhotoUploadSessionPath`, `staffProfilePhotoFinalizePath`, `staffDeleteProfilePhotoPath`, `staffMyProfilePinPath` | Admin and Staff read their own record; the schedule's Edit key is Admin only |
| 13a | Work Schedule card | `widgets/work_schedule_card.dart`, drawn by `profile_page.dart` | `ProfileCubit` | `user-profile/view/user_profile_screen.dart`, `staff/view/edit_schedule_screen.dart` | `getStaffProfile`'s `workSchedules` and `breakSchedules` (`StaffProfileWorkSchedule` / `StaffProfileBreakSchedule`); the write is M06's | `staffProfilePath(staffCode)`, `staffSchedules` | Admin edits, Staff get the locked "Admin only" chip |
| 13b | Edit My Profile — live refusals | `presentation/pages/edit_profile_page.dart` + `widgets/value_field.dart`, `docked_bar.dart` | `EditProfileCubit` | `user-profile/view/edit_user_profile_screen.dart`, `view_model/edit_user_profile_cubit.dart`, `shared/constants/location_constants.dart` | the my-profile PATCH (firstName, lastName, phoneNumber, addressStreet, addressLine2, addressCity, addressState, addressZipCode), `US_STATES` for the state picker | `staffProfilePath(staffCode)` (PATCH) | The signed-in person, whoever they are |
| 13c | A guardian's own record — the Me tab | `presentation/pages/profile_page.dart` (guardian lens) + `widgets/guardian_children_card.dart`, `profile_child_row.dart` | `ProfileCubit` | `user-profile/view/user_profile_screen.dart`, `shared/common/app/cubit/parent_child_cubit.dart` | `StudentRemoteDataSource.getGuardianProfile`, plus `ParentChildCubit`'s children and their sign-in status | `guardianProfile` | Guardian |
| 13d | The three account sheets | **not this module.** Switch Profile, the logout confirm and the change-password sheet are M03's, on `dashboard/presentation/pages/account_page.dart` | — | `shared/common/widgets/custom_app_bar.dart`, `auth/view/sign_out_screen.dart`, `core/util/user_details_school_roles.dart` | — | — | — |
| 13e | Notification Settings — live, saves on tick | `presentation/pages/notification_settings_page.dart` + `widgets/preference_table.dart`, `preference_group_row.dart`, `preference_notes.dart` | `NotificationSettingsCubit` | `user-profile/view/notification_settings_screen.dart`, `view_model/notification_preference_groups_cubit.dart`, `widgets/notification_preference_group_row.dart`, `notification_preference_category_header.dart` | `GetNotificationPreferenceGroupsUseCase`, `UpdateNotificationPreferenceGroupsUseCase` | `notificationPreferenceGroups` | Everyone, for their own account |
| 13f | Four profile states, live | `presentation/pages/profile_page.dart` + `widgets/profile_skeleton.dart`, `profile_failed_card.dart`, `profile_note.dart`, core's `OfflineBanner` | `ProfileCubit` | `user_profile_cubit.dart`'s cache fallback and `loadFailed` branch | same as 13a | same as 13a | its four states are the four answers one fetch can give |
| — | Change Password | `presentation/pages/change_password_page.dart` + `widgets/docked_bar.dart` | `ChangePasswordCubit` | `auth/view/change_password_screen.dart` | **none today** — the shipped screen's submit is a `TODO` that waits a second and reports success | none | The signed-in person |

The two iPad frames, `13T1` and `13T2`, are the same record and the same
preference table side by side. They are not built: the redesign is phone-first
and no responsive layer exists yet.

## Routes

All relative to the dashboard branch root, so back returns to the dashboard.
They stay relative even where they cover the tab bar, because go_router
concatenates a child's path onto its parent's — an absolute `/dashboard/profile/edit`
under `/dashboard/profile` would resolve to
`/dashboard/profile/dashboard/profile/edit`. What lifts a screen over the tab
bar is `parentNavigatorKey: rootNavigatorKey`.

| Path | Absolute | Screen | Navigator |
|---|---|---|---|
| `profile` | `/dashboard/profile` | 13a, 13c, 13f | shell (the tab bar stays) |
| `profile/edit` | `/dashboard/profile/edit` | 13b | root (`parentNavigatorKey`) |
| `profile/notification-settings` | `/dashboard/profile/notification-settings` | 13e | root |
| `profile/change-password` | `/dashboard/profile/change-password` | Change Password | root |

`AppRoutes` already carried all four in its M13 section (`profile`,
`editProfile`, `notificationSettings`, `changePassword`). **Nothing was
appended to `AppRoutes`.** There are no path parameters in this module, so
nothing collides with M05's `:studentId` or M07's `:id`.

## Cubits

| Cubit | Status enum | What it is for |
|---|---|---|
| `ProfileCubit` | `ProfileStatus { loading, ready, offline, failed }`, and `PhotoStatus { idle, uploading, failed }` beside it | 13a, 13c, 13f, and the photo |
| `EditProfileCubit` | `loading, ready, saving, saved, failed` | 13b |
| `NotificationSettingsCubit` | `loading, ready, failed` | 13e |
| `ChangePasswordCubit` | `editing, saving, saved, failed` | Change Password |

Two states are deliberately *not* statuses of their own. A school that has set
up no preference groups is `ready` with an empty list (`isEmpty`), because it
is the same fetch with a different answer. And the photo has its own status
rather than a `ProfileStatus` value, because an upload that fails must leave
the record on screen untouched, which is exactly what 13a's failed card
promises.

## Persona

Read off `SessionCubit` in the page and passed into `ProfileCubit` as a
factory parameter, so the lens is fixed for the life of the screen and no
widget has to ask who is looking.

* **Admin** gets the work schedule with its Edit key, the roles their account
  holds at this school as chips, and the masked PIN with a Show key.
* **Staff** get the same card with the locked "Admin only" chip where the Edit
  key would be. The card is shown rather than hidden, because a card that says
  who may change it is more use than a card that is not there.
* **Guardian** gets 13c: the title is "Me", the children card replaces the
  work schedule, the PIN is simply shown (it is theirs to type on the kiosk
  and the app never asks them for it), and the note explains why there is
  nothing else. The address is optional for a guardian on 13b and required for
  a staff member, which is the rule the shipped screen applies.

Role carries no colour anywhere here: the Admin and Parent chips are the same
neutral material.

## Free, and costly

From the module's rule-zero audit:

* **Free, and built.** A notification preference group returns a
  `description` and an `overridden` flag, and the shipped app ignores both.
  The description is now the second line of every row on 13e — it is the only
  thing that says what a group actually covers.
* **Costly, and not built.** Nothing. The audit proposes nothing for this
  module: every frame is buildable against endpoints the app already calls.

`overridden` is carried on the model and read nowhere: it means a school-level
default has been overridden for this account, and there is no frame that says
anything about it. Drawing a badge for it would be inventing UI, so it stays
available for whoever the design gives a place to put it.

## Added beyond the frames

* **A save confirmation.** 13b does not draw what happens after Save. It
  toasts and pops, and the record behind it is already the saved one.
* **A photo sheet.** 13a's Change photo key opens nothing on the frame. Here
  it opens a bottom sheet offering Choose from library and, when there is one
  to remove, Remove photo — which is the only place the frame's own
  `removePhoto` copy could live.
* **Change Password as a full screen.** The frames only draw 13d's sheet,
  which asks whether to send a reset link. `AppRoutes.changePassword` needed a
  screen behind it, so the shipped `change_password_screen.dart` form was
  rebuilt: three wells, the same four rules in the same order, and a toast.
  **Worth knowing before Phase 5:** that shipped screen has no API call. Its
  submit is a `TODO` that waits a second and reports success, so
  `ProfileSource.changePassword` has nothing real to bind to yet. Either an
  endpoint appears, or this route should send the reset link 13d's sheet
  describes, through the existing forgot-password call.
* **The hero's freshness line on every state.** 13a draws the role chips and
  13f draws "Loaded just now" / "Saved on this phone · 9:02 AM". Both are
  drawn: the chips say what the account is, the line says how old the record
  is, and merging them is what makes 13f's offline state legible from 13a.
* **`DockedBar`.** A key's face is centred inside its own surface, so given a
  tall bounded slot it stretches to fill it, and a `Scaffold`'s bottom slot is
  exactly that. This measures its keys first. It is M05's widget written
  again, because features may not import each other; it belongs in
  `core/widgets` the next time a third module wants it.
* **`PreferenceCategory`.** The endpoint returns a flat list with
  `categoryCode` on each group. The banding is done once in the state rather
  than in the widget tree.
* **Pull to refresh on 13a.** The frames draw no gesture, but the screen is a
  read of one record and there was nothing else to re-fetch it with.

## Deliberate departures from the frames

* **No Switch Profile control.** 13a draws one beside View Staff Profile, but
  13d's Switch Profile sheet belongs to M03's Account page and this screen only
  reports which roles the account holds, as the chips in the hero.
* **No Logout row.** 13a and 13c both draw one, and it needs the logout
  confirm sheet, which is 13d's and therefore M03's. Logout already sits at
  the foot of the Account page with the sheet that confirms it.
* **No View Staff Profile key.** M06 Staff is not built, so there is no staff
  record to open and the key would only toast. The frame also draws it navy,
  and there is no navy key in `core/widgets`: navy is the impact surface, not
  a key face.
* **A navy guardian hero avatar, not pink.** 13c paints it pink. Pink is the
  one action on a screen and 13c already spends it on the Edit key; the
  signed-in person is the impact avatar everywhere else in the app.
* **No grouped error box on 13b.** The frame draws both per-field messages and
  a red box listing them, with the note "each error sits on the field that
  caused it". The per-field messages are the mechanism; the box is the
  annotation explaining it.

## Not wired yet

* **The way in.** More's profile header pushes `/dashboard/more/account`, and
  the Account page's "My Profile" row still shows the "being rebuilt" toast.
  `more_page.dart` and `account_page.dart` belong to M03 and are not this
  module's to edit. The route is live at `/dashboard/profile` in the meantime.
* **The Work Schedule Edit key** opens M06's schedule editor, which does not
  exist yet, so it toasts.
* **A guardian's "Open"** pushes `AppRoutes.student(id)`, which M05 built, so
  that one is real.

## Reaching 13f's other states in the preview

`PreviewProfileSource` takes a `PreviewProfileMode`, registered as `ready` in
`profile_di.dart`. Changing that one line to `offline` answers off the copy
saved on this phone (banner, sun freshness line, the note about what needs a
connection), and `failed` answers with nothing at all (the failed card over
the little sign-in already knew). The loading state is whatever the latency
shows; every one of the four is covered by a widget test as well.
