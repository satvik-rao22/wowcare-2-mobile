# M12 Notifications — design to code

Five phone frames, `12a`–`12e`. One of them is a screen: `12a` is the
notification center, `12b` is that same screen in its six states, and `12c`,
`12d` and `12e` are annotations about where a tap lands, what the bell does,
and who is told what. So this module ships one route, and the other three
frames are behaviour built into it.

The center is reached from the bell in the dashboard header. Its route is a
child of the dashboard branch, it stays inside the shell, and no tab lights
up while it is open.

| ID | Design title | Screen here | Cubit | Existing source | Repository / usecase method | ApiPaths | Role gate |
|---|---|---|---|---|---|---|---|
| 12a | The center — live: filter, unread, mark all, tap to read | `presentation/pages/notification_center_page.dart` + `widgets/notification_row.dart`, `notification_filter_chips.dart`, `notification_toolbar.dart`, `notification_tone_colors.dart` | `NotificationCenterCubit` | `notifications/view/notification_center_screen.dart`, `widgets/notification_card.dart`, `widgets/notification_category_style.dart`, `cubit/notification_center_cubit.dart` | `GetNotificationsUseCase(page, size, module, onlyUnread)`, `GetNotificationUnreadCountsUseCase`, `MarkNotificationReadUseCase`, `MarkAllNotificationsReadUseCase` | `notificationInbox`, `notificationInboxUnreadCounts`, `notificationInboxRead(code)`, `notificationInboxReadAll` | Everyone signed in, for their own inbox. The server scopes the feed by role and school before it arrives |
| 12b | Five list states, live | same page + `widgets/notification_skeleton.dart`, `loading_more_footer.dart`, core's `EmptyState`, `ErrorState` and `OfflineBanner` | `NotificationCenterCubit` | `notification_center_cubit.dart`'s `isLoading` / `isLoadingMore` / `errorMessage` branches, `core/util/notification_events.dart` (the arrival signal) | same, plus `NotificationEvents.inboxChanged` for "one arrives" | same | its six states are the answers one paged fetch can give |
| 12c | Where a tap lands — three live cases | `notification_routing.dart` + the page's `_open` | — (a pure function) | `notifications/routing/notification_route_resolver.dart`, `view/notification_navigator.dart`, `core/util/active_school_switcher.dart` | none: the table is pure, and the destination screens are other modules' | `notificationInboxClick(code)` is the shipped click ping, not called here | the persona is an argument: a guardian is routed to what is theirs |
| 12d | The bell, and a push arriving | core's `IconKey` badge and `core/session/BadgeCubit`, driven by this page's `BlocListener` | `NotificationCenterCubit` feeds `BadgeCubit` | `notifications/cubit/notification_badge_cubit.dart`, `push_notification_cubit.dart`, `data/features/notifications/realtime/notification_realtime_data_source.dart` | `GetNotificationUnreadCountsUseCase`, `RegisterDeviceFcmTokenUseCase` | `notificationInboxUnreadCounts`, `notificationFcmRegister` | a kiosk has no bell at all, and the router already locks a kiosk out of every route but the door |
| 12e | Who gets what — live personas | `models/notification_filter.dart` (`forPersona`) and `source/preview_notifications_source.dart` (`reaches`) | `NotificationCenterCubit.state.chips` | `shared/common/app/cubit/role_cubit.dart`, `presentation/features/students/module_access.dart` | the inbox call is already role-scoped server side | same | Admin, Staff and Guardian each get their own feed and their own chip row |

The two frames that are not screens (`12d`, `12e`) are built as behaviour
rather than as pages: there is nothing on `12d` but the bell, the badge and a
push, all of which already exist in the chrome, and `12e` is a table of what
each persona is told, which is the source's scoping and the chip row.

`12T1` is the iPad frame. It is not built: the redesign is phone-first and no
responsive layer exists yet.

## Routes

Relative to the dashboard branch root, so back returns to the dashboard and no
tab lights up. It stays on the shell navigator: the center is a list you read
on the way somewhere else, it does not own the bottom of its own screen, and
the five slots are still where you would want to go next.

| Path | Absolute | Screen | Navigator |
|---|---|---|---|
| `notifications` | `/dashboard/notifications` | 12a, 12b | shell (the tab bar stays, nothing lit) |

`AppRoutes` already carried `notifications` in its M12 section. **Nothing was
appended to `AppRoutes`**, and no path parameter is introduced, so nothing
collides with M05's `:studentId` or M07's `:id`.

## Cubits

| Cubit | Status enum | What it is for |
|---|---|---|
| `NotificationCenterCubit` | `NotificationCenterStatus { loading, ready, cached, failed }` | 12a and 12b, and the count 12d's bell carries |

Four states rather than six. An inbox with nothing in it is `ready` with an
empty list, because "nothing has ever arrived" and "nothing under that filter"
are the same fetch with different answers and the screen tells them apart by
looking at the filter. Paging and marking read are flags on the state
(`isLoadingMore`, `isWorking`, `hasArrived`) rather than statuses, because each
of them happens *with* a list on screen, and a status would take that list
away.

`cached` is the house rule about a failed fetch: with rows already on screen a
failure is the navy banner over a list still worth reading, and only a failure
with nothing to fall back on is `failed` with the retry key.

## Paging

`_pageSize` in the shipped cubit is 10 and the shipped screen fetches the next
page within 400px of the bottom, with nothing on screen to say so. Both
numbers are kept (`NotificationCenterCubit.pageSize`,
`NotificationsSizes.pageTrigger`) and the footer is the module's one free
finding, drawn as the frame draws it.

The filter chips and the unread switch are **server-side** filters in the
shipped app (`module` and `onlyShowUnread` query parameters), so either one
refetches from page one rather than hiding rows the phone already holds. That
is also the only way the unread total stays honest: `unreadCount` spans every
page, not the rows loaded.

## Where a tap lands (12c)

`NotificationRouting.destinationOf` is the redesign's half of the shipped
`NotificationRouteResolver`: one row per action, keyed by the same constants,
imported from `lib/domain/features/notifications/entities/notification_action.dart`
rather than retyped, so the two tables cannot drift and Phase 5 is a binding
rather than a rewrite. `NotificationAction.canonical` normalizes the backend's
aliases (`STUDENT_SIGN_IN` and `STUDENT_SIGN_OUT` both land as
`STUDENT_SIGN_IN_OUT`) before the table is read.

| Action group | With a code | Without one |
|---|---|---|
| `STUDENT_SIGN_IN_OUT`, `STUDENT_MARKED_ABSENT` | `AppRoutes.student(code)` | `AppRoutes.attendance` |
| `STAFF_SIGN_IN_OUT`, `STAFF_MARKED_ABSENT` | `AppRoutes.staffMember(code)` | `AppRoutes.attendance` |
| `RATIO_BREACHED`, `CAPACITY_EXCEEDED` | `AppRoutes.classroom(code)` | `AppRoutes.attendance` |
| `ATTENDANCE_NOT_MARKED` | — | `AppRoutes.attendance` |
| the six classroom actions | `AppRoutes.classroom(code)` | `AppRoutes.classrooms` |
| the eleven student actions, and `BIRTHDAY` | `AppRoutes.student(code)` | `AppRoutes.students` |
| the four staff actions | `AppRoutes.staffMember(code)` | `AppRoutes.staff` |
| `SCHOOL_SETTINGS_CHANGED` | — | `AppRoutes.notificationSettings` |
| `GEOFENCE_ENTER` | — | `AppRoutes.dashboard` |
| billing, scheduling, availability, activity, messaging, newsletter | — | the "being rebuilt" toast (`AppStrings.comingSoon`) |
| anything else | falls back to the notification's own module, and then to `AppRoutes.dashboard` | |

Three things worth knowing:

* **A notification about one child opens that child**, not the day's list,
  which is 12c's own rule. M04 Attendance is a placeholder, so the student's
  record is the nearest built destination and the attendance list is the
  fallback when the payload carries no code.
* **A module that is not rebuilt yet toasts** rather than opening a
  placeholder screen. A placeholder looks like the tap worked; the toast says
  what actually happened.
* **A guardian is routed to what is theirs.** Their child's code opens that
  child (M05's profile does not refuse a guardian, and their own dashboard
  already opens it). A list-level notification lands on the dashboard instead,
  because the roster refuses them and a refusal screen is a worse answer than
  their own day.

## The bell (12d)

`BadgeCubit.notifications` is the count, and the page keeps it honest: a
`BlocListener` calls `setNotifications(state.unreadCount)` whenever the total
changes on a loaded list, so reading one row drops the badge by one and Mark
all as read takes it to nothing at once. The listener is deliberately gated on
`!isFailed && !isLoading`, so a fetch that failed never silently empties the
bell.

A kiosk has no bell, no center and no route: `SessionStatus.kiosk` is locked to
the door screen by the router's own redirect, so there was nothing to build for
that half of the frame.

## Personas (12e)

Read off `SessionCubit` in the page and passed into the cubit as a factory
parameter, so the lens is fixed for the life of the screen.

* **Admin** gets the whole school and all eleven chips.
* **Staff** get their own classroom, their own record and their own shifts,
  and never money: the Billing chip is not offered and no billing row reaches
  them.
* **Guardian** gets their children, their own invoices, and what was written
  to them. Their chip row drops Classroom, Staff, Scheduling and Availability.

Scoping is applied in the source rather than in the cubit, because that is
where it really happens: the server decides what a role may be told about
before it reaches the phone. In Phase 5 the same call is already role-scoped
and `reaches` simply goes away.

## Free, and costly

From the module's rule-zero audit:

* **Free, and built.** The inbox pages ten at a time and fetches the next page
  as you scroll, already wired, with nothing on screen to say so. The
  *Loading more* footer is that fetch, admitted.
* **Costly, and not built.** A notifications-are-off panel for a refused OS
  permission, per-child scoping of a guardian's inbox, counts on the filter
  chips, and swipe to dismiss. The chips carry no counts for the same reason
  the audit called it costly: a per-module count is not a number any call
  returns, so a chip carrying one would be a number the app made up.

## Added beyond the frames

* **An EARLIER day band.** The frames draw TODAY and YESTERDAY only, because
  the frame's feed is two days deep. A real inbox pages back past that, so
  `NotificationDay` has a third value and the band is labelled Earlier.
* **The offline banner over the list.** 12b draws no cached state. The house
  rule is that a failed refetch with rows on screen keeps the rows and says
  they are not live, so the same navy strip 12b uses for "one arrived" carries
  the offline line too.
* **Pull to refresh.** The frames draw no gesture, and the error copy already
  says "pull down", so the gesture the copy promises is wired.
* **A toast after Mark all as read.** The frame draws the key but not what
  happens after it. It toasts, and a write that fails rolls the whole list
  back and toasts the failure instead.
* **Relative time measured against the school's clock.** The feed carries the
  moment it was answered (`NotificationFeed.asOf`) and every row is aged
  against that one value, so the whole list ages together rather than each row
  drifting on the device clock. Time in this app is school-timezone based,
  which is what Phase 5 will bind `asOf` to.

## Deliberate departures from the frames

* **The unread line sits in the body, not under the title.** The frame puts
  "7 unread" under the header's title in pink. `AppHeaderBar`'s only variant
  with a line under the title is the dashboard greeting, which fixes that line
  at `ink3` and drops the title a size. So the title stays a module title and
  the unread line is the first thing in the body, where it can be the pink it
  needs to be.
* **A disabled key, not a dimmed one.** The frame draws Mark all as read at
  45% opacity when there is nothing unread. Here it takes the component's
  disabled recipe (well fill, ink3 label, no rim, no sink), because that is
  what a key that cannot be pressed looks like everywhere else in this app.
* **The module tag is a pill.** The frame draws an 8px-cornered tag. Eight is
  not on the radius ladder, and `StatusPill` is the core component for a
  tinted tag, so the tag is a small pill in the module's tint.
* **The read row is the quiet inner ground.** The frame paints it `#F5F8FE`,
  between the card and the sub ground. It is drawn on `sub` with no shadow,
  which is the token the ladder actually carries and the same material every
  other quiet row in the app uses.
* **No counts on the chips**, per the costly list above.

## Colour

The module tint is the design's own map, and it says what a notification is
about rather than who is looking: teal for a student, sun for staff, green for
money, pink for something a person wrote, and the neutral alt-well for the
rest. The pink is a tint, never a key: the one pink action on this screen is
Mark all as read, and the unread dot is the pink accent the frame gives it.

## Not wired yet

* **The way in.** `dashboard_page.dart`'s bell still shows the "being rebuilt"
  toast (`onOpenNotifications: () => _notReady(context)`). That file is M03's
  and not this module's to edit; the route is live at
  `/dashboard/notifications` in the meantime, and the one-line change is to
  push `AppRoutes.notifications` there.
* **The arrival signal.** `NotificationsSource.arrivals` is the interface for
  `NotificationEvents.inboxChanged`, which the FCM foreground handler already
  fires. Nothing fires it in the redesign yet, because push registration is
  M01's and the FCM handler lives outside `lib/redesign/`. The preview source
  fires one in `arriving` mode so the state is real and tested.
* **The click ping.** The shipped inbox has
  `notificationInboxClick(code)` beside the read call and the shipped screen
  never calls it. It is left alone rather than invented: nothing in the design
  depends on it.

## Reaching 12b's states in the preview

`PreviewNotificationsSource` takes a `PreviewNotificationsMode`, registered as
`ready` in `notifications_di.dart`. Changing that one line walks the rest:

| Mode | What it draws |
|---|---|
| `ready` | twenty-six rows, seven of them unread, over three pages |
| `empty` | an account nothing has ever arrived for |
| `failed` | the failed state, with nothing to fall back on |
| `offline` | the first page lands, every later fetch throws: the banner over a list still worth reading |
| `arriving` | `ready`, and a push lands four seconds after the first page |

The filtered empty state needs no mode: pick a chip nothing matches.
