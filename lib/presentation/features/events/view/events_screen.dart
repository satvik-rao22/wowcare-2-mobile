import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_radius.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/domain/features/events/entities/calendar_feed_item.dart';
import 'package:wowcare/domain/features/events/entities/event.dart';
import 'package:wowcare/domain/features/events/entities/holiday.dart';
import 'package:wowcare/presentation/features/events/view_model/events_cubit.dart';
import 'package:wowcare/presentation/features/events/utils/event_access.dart';
import 'package:wowcare/presentation/features/events/utils/holiday_year_window.dart';
import 'package:wowcare/presentation/features/events/view/event_detail_screen.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/presentation/features/events/utils/calendar_feed_mappers.dart';
import 'package:wowcare/presentation/features/students/module_access.dart';
import 'package:wowcare/presentation/features/tasks/view_model/tasks_cubit.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_access.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_option_picker.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_ui_utils.dart';
import 'package:wowcare/presentation/features/tasks/view/task_detail_screen.dart';
import 'package:wowcare/presentation/features/tasks/widgets/task_card.dart';
import 'package:wowcare/presentation/features/events/view/event_form_screen.dart';
import 'package:wowcare/presentation/features/events/widgets/event_card.dart';
import 'package:wowcare/presentation/features/events/widgets/event_filter_sheet.dart';
import 'package:wowcare/presentation/features/events/widgets/event_grid_card.dart';
import 'package:wowcare/presentation/features/events/widgets/holiday_card.dart';
import 'package:wowcare/presentation/features/events/widgets/holiday_dialogs.dart';
import 'package:wowcare/presentation/features/events/widgets/holiday_form_sheet.dart';
import 'package:wowcare/presentation/features/events/widgets/holiday_highlight.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';
import 'package:wowcare/shared/common/widgets/access_restricted_view.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/expandable_section.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';

/// How the Events tab lays out its content, mirroring the web design's
/// calendar / grid / list switcher.
enum _EventsViewMode { calendar, grid, list }

/// The screen's two tabs. Also the deep-link vocabulary: holiday notifications
/// route to `/dashboard/events?tab=holidays` (see `NotificationRouteResolver`),
/// since the Holiday List is a tab here rather than a route of its own.
enum EventsTab {
  events('events'),
  holidays('holidays');

  const EventsTab(this.queryValue);

  final String queryValue;

  /// Parses the `tab` query parameter. Anything unrecognised — including the
  /// null of an event/task deep link that carries no `tab` at all — keeps the
  /// screen on its default [EventsTab.events].
  static EventsTab fromQueryValue(String? raw) {
    final value = (raw ?? '').trim().toLowerCase();
    // Tolerate the singular, matching the payload's `module: HOLIDAY`.
    if (value == holidays.queryValue || value == 'holiday') return holidays;
    return events;
  }
}

class EventsScreen extends StatefulWidget {
  const EventsScreen({
    super.key,
    this.initialTab = EventsTab.events,
    this.initialYear,
    this.highlightHolidayName,
  });

  /// Builds the screen from a go_router query map — the one place a holiday
  /// notification's `?tab=&year=&highlightHoliday=` (produced by
  /// `NotificationRouteResolver`) is turned into screen state. An empty map
  /// yields the plain default screen, which is what in-app navigation and
  /// event/task deep links pass.
  factory EventsScreen.fromQuery(Map<String, String> query, {Key? key}) {
    return EventsScreen(
      key: key,
      initialTab: EventsTab.fromQueryValue(query['tab']),
      initialYear: int.tryParse(query['year'] ?? ''),
      highlightHolidayName: query['highlightHoliday'],
    );
  }

  static const String routeName = '/dashboard/events';

  /// Tab to open on. Defaults to Events, so in-app navigation is unchanged.
  final EventsTab initialTab;

  /// Holiday year to select on open (a holiday notification's year). Ignored
  /// when outside [HolidayYearWindow], which the year selector cannot show.
  final int? initialYear;

  /// Name of the holiday to scroll to and flash — holiday payloads carry no
  /// entity code, so the name is the deep link's only handle on a row (see
  /// [HolidayHighlight]).
  final String? highlightHolidayName;

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  static const Color _holidayRed = AppPalette.statusError;

  /// Per-tab / per-view read permission. The screen opens when *any* of the
  /// three modules is readable (see `EventAccess.canOpenModule`), so each
  /// surface must still check its own before rendering data.
  bool _canReadEvents(RoleCubit roles) =>
      roles.canReadModule(AppAccessModules.event);
  bool _canReadHolidays(RoleCubit roles) =>
      roles.canReadModule(AppAccessModules.holiday);
  bool _canReadCalendar(RoleCubit roles) =>
      roles.canReadModule(AppAccessModules.calendar);

  /// Whether the RSVP control should be offered for [event]: the user is on
  /// its roster (existing rule) **and** `EVENT_RSVP` permits responding.
  bool _canRespond(EventsState state, RoleCubit roles, Event event) =>
      state.isParticipant(event) &&
      EventAccess.canRsvp(
        roles: roles,
        event: event,
        userCode: state.currentUserCode,
        staffCode: state.currentStaffCode,
      );

  /// The view the events tab can actually show. Calendar is the default, so a
  /// user without `CALENDAR` read is moved to the list rather than landing on
  /// a restricted screen.
  _EventsViewMode _effectiveViewMode(RoleCubit roles) {
    if (_viewMode == _EventsViewMode.calendar && !_canReadCalendar(roles)) {
      return _EventsViewMode.list;
    }
    return _viewMode;
  }

  static const int _eventsTabIndex = 0;
  static const int _holidaysTabIndex = 1;

  late int _tabIndex = widget.initialTab == EventsTab.holidays
      ? _holidaysTabIndex
      : _eventsTabIndex;
  _EventsViewMode _viewMode = _EventsViewMode.calendar;

  /// When true, every view shows completed events (most recently completed
  /// first) instead of the upcoming-event content.
  bool _showCompleted = false;

  /// Month keys ('y-m') the user collapsed on the grid/list views.
  final Set<String> _collapsedMonths = {};
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load the current month's unified calendar feed once the widget is
    // mounted (calendar is the default view). Skipped without `CALENDAR` read
    // — no point fetching rows the screen may not show.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_tabIndex == _holidaysTabIndex) _openHolidayDeepLink();
      final roles = context.read<RoleCubit>();
      if (!_canReadCalendar(roles)) return;
      context.read<EventsCubit>().loadCalendarFeed(
            _focusedDay,
            scope: _feedScope(roles),
          );
    });
  }

  /// Applies the holiday notification deep link: select the notified year (when
  /// the selector can show it) and refetch, so the flashed card is actually in
  /// the list. `setSelectedYear` already refetches; only the same-year case
  /// needs the explicit refresh the Holidays tab does on every open.
  void _openHolidayDeepLink() {
    final cubit = context.read<EventsCubit>();
    final year = widget.initialYear;
    if (year != null &&
        year != cubit.state.selectedYear &&
        HolidayYearWindow.contains(year)) {
      cubit.setSelectedYear(year);
      return;
    }
    cubit.refreshHolidays();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roles = context.watch<RoleCubit>();

    return GlobalScaffold(
      hasBackButton: false,
      showCustomNavigationBar: true,
      floatingActionButton: _addFab(context, roles),
      body: BlocListener<EventsCubit, EventsState>(
        // Background fetches (initial load, Holidays tab refresh, year
        // switch) have no call site to await and show a toast directly —
        // this is their only feedback path. Save/delete/status-change
        // actions show their own toast at the call site instead.
        listenWhen: (previous, current) =>
            current.errorMessage != null &&
            current.errorMessage != previous.errorMessage,
        listener: (context, state) {
          CoreUtils.showTopSnackBar(
            context: context,
            message: state.errorMessage!,
            isError: true,
          );
        },
        // RoleCubit resolves permissions asynchronously. initState skips the
        // feed fetch while `CALENDAR` read is unknown, so run it once the
        // permissions land (loadCalendarFeed dedupes by month + scope).
        child: BlocListener<RoleCubit, RoleState>(
          listener: (context, _) {
            final resolved = context.read<RoleCubit>();
            if (!_canReadCalendar(resolved)) return;
            context.read<EventsCubit>().loadCalendarFeed(
                  _focusedDay,
                  scope: _feedScope(resolved),
                );
          },
          child: BlocBuilder<EventsCubit, EventsState>(
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // _header(context, roles),
                    // const SizedBox(height: 10),
                    _tabSwitcher(),
                    const SizedBox(height: 10),
                    if (_tabIndex == _eventsTabIndex)
                      Expanded(child: _eventsTab(context, state, roles))
                    else
                      Expanded(child: _holidaysTab(context, state, roles)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Bottom-right FAB for creating an event (Events tab) or a school holiday
  /// (Holidays tab). Returns null when the current tab/role can't add, so no
  /// button renders. Staff may add events but not holidays; parents neither.
  Widget? _addFab(BuildContext context, RoleCubit roles) {
    final VoidCallback? onTap = _tabIndex == _eventsTabIndex
        ? (EventAccess.canCreateEvents(roles) ? () => _openForm(context) : null)
        : (EventAccess.canManageHolidays(roles)
              ? () => showHolidayFormSheet(context)
              : null);
    if (onTap == null) return null;

    return Container(
      width: 64,
      height: 64,
      margin: const EdgeInsets.only(bottom: 6),
      decoration: AppSurfaces.fab(),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.r14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: const Center(
            child: Icon(Icons.add, color: AppPalette.onBrand, size: 32),
          ),
        ),
      ),
    );
  }

  Widget _tabSwitcher() {
    Widget tab(int index, String label, IconData icon) {
      final selected = _tabIndex == index;
      return Expanded(
        child: GestureDetector(
          onTap: () {
            setState(() => _tabIndex = index);
            // Holidays are the scheduler API's source of truth — fetch fresh
            // whenever the tab is opened so the list can't go stale.
            if (index == _holidaysTabIndex) {
              context.read<EventsCubit>().refreshHolidays();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: selected
                ? AppSurfaces.key(KeyVariant.primary, radius: 9)
                : null,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: selected ? AppPalette.onBrand : AppColors.primaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? AppPalette.onBrand : AppColors.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: AppSurfaces.segmented(radius: 11),
      child: Row(
        children: [
          tab(0, 'Events', Icons.event_outlined),
          tab(1, 'Holidays', Icons.beach_access_outlined),
        ],
      ),
    );
  }

  // -------------------------------------------------------- events tab

  Widget _eventsTab(BuildContext context, EventsState state, RoleCubit roles) {
    // Neither the event list nor the calendar is readable — nothing on this
    // tab can render.
    if (!_canReadEvents(roles) && !_canReadCalendar(roles)) {
      return const AccessRestrictedView(
        message: 'You do not have access to events for your selected school.',
      );
    }
    if (state.isLoading) {
      return const Center(child: PrimaryCircularLoader());
    }
    // Search runs over event data, so it needs `EVENT` read of its own.
    if (state.isSearching && !_canReadEvents(roles)) {
      return const AccessRestrictedView(
        message: 'You do not have access to events for your selected school.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _toolbar(context, state, roles),
        const SizedBox(height: 10),
        if (state.isSearching)
          Expanded(child: _searchResults(context, state, roles))
        else ...[
          _completedToggle(state),
          const SizedBox(height: 10),
          Expanded(child: _eventsContent(context, state, roles)),
        ],
      ],
    );
  }

  /// Main content for the events tab. The calendar keeps its full layout in
  /// both modes — in completed mode it marks only past completed events and
  /// defaults to the latest one. Grid/list swap their data source between
  /// upcoming and completed (the latter descending by occurrence date).
  Widget _eventsContent(
    BuildContext context,
    EventsState state,
    RoleCubit roles,
  ) {
    final viewMode = _effectiveViewMode(roles);
    if (viewMode == _EventsViewMode.calendar) {
      // Defence in depth: _effectiveViewMode already diverts to the list when
      // `CALENDAR` is unreadable, so this only fires if that fallback is ever
      // changed or bypassed. Cheap insurance against the calendar rendering
      // rows the user has no permission for.
      if (!_canReadCalendar(roles)) {
        return const AccessRestrictedView(
          message:
              'You do not have access to the calendar for your selected school.',
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _calendarCard(context, state, roles),
          const SizedBox(height: 10),
          Expanded(child: _dayList(context, state, roles)),
        ],
      );
    }
    if (!_canReadEvents(roles)) {
      return const AccessRestrictedView(
        message: 'You do not have access to events for your selected school.',
      );
    }
    final events = _showCompleted
        ? state.completedEvents
        : state.upcomingEvents;
    final emptyMessage = _showCompleted
        ? 'No completed events'
        : 'No upcoming events';
    return viewMode == _EventsViewMode.grid
        ? _gridView(context, state, roles, events, emptyMessage: emptyMessage)
        : _listView(context, state, roles, events, emptyMessage: emptyMessage);
  }

  /// Pill toggle (shared by all three views) that switches the content
  /// between upcoming and completed events. In calendar mode, turning it on
  /// jumps the calendar to the most recently completed event.
  Widget _completedToggle(EventsState state) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: _showCompleted
            ? AppColors.themeColor.withValues(alpha: 0.12)
            : AppColors.cardColor,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => setState(() {
            _showCompleted = !_showCompleted;
            if (_showCompleted && _viewMode == _EventsViewMode.calendar) {
              _jumpToLatestCompleted(state);
            }
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _showCompleted
                    ? AppColors.themeColor
                    : AppPalette.borderStrong,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _showCompleted ? Icons.history : Icons.history_outlined,
                  size: 16,
                  color: _showCompleted
                      ? AppColors.themeColor
                      : AppPalette.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'View Completed',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _showCompleted
                        ? AppColors.themeColor
                        : AppPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Search field + filter button + view-mode switcher.
  Widget _toolbar(BuildContext context, EventsState state, RoleCubit roles) {
    final cubit = context.read<EventsCubit>();
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 38,
            child: TextField(
              controller: _searchController,
              onChanged: cubit.setSearchQuery,
              decoration: InputDecoration(
                hintText: 'Search events…',
                hintStyle: TextStyle(fontSize: 13, color: AppPalette.textMuted),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 18,
                  color: AppPalette.iconMuted,
                ),
                suffixIcon: state.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 16,
                          color: AppPalette.iconMuted,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          cubit.setSearchQuery('');
                        },
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor: AppSurfaces.fieldFill,
                contentPadding: EdgeInsets.zero,
                border: AppSurfaces.fieldBorder(radius: 10),
                enabledBorder: AppSurfaces.fieldBorder(radius: 10),
                focusedBorder: AppSurfaces.fieldBorder(radius: 10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _filterButton(context, state),
        const SizedBox(width: 8),
        _viewSwitcher(state, roles),
      ],
    );
  }

  Widget _filterButton(BuildContext context, EventsState state) {
    final hasFilters = state.activeFilterCount > 0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: hasFilters
              ? AppColors.themeColor.withValues(alpha: 0.12)
              : AppColors.cardColor,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => showEventFilterSheet(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: hasFilters
                      ? AppColors.themeColor
                      : AppPalette.borderStrong,
                ),
              ),
              child: const Icon(
                Icons.tune,
                size: 18,
                color: AppColors.themeColor,
              ),
            ),
          ),
        ),
        if (hasFilters)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.themeColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${state.activeFilterCount}',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.onBrand,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _viewSwitcher(EventsState state, RoleCubit roles) {
    Widget option(_EventsViewMode mode, IconData icon, String tooltip) {
      final selected = _effectiveViewMode(roles) == mode;
      return Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: () => setState(() {
            _viewMode = mode;
            // Entering the calendar while viewing completed events should
            // land on the most recently completed event.
            if (_showCompleted && mode == _EventsViewMode.calendar) {
              _jumpToLatestCompleted(state);
            }
          }),
          child: Container(
            width: 30,
            height: 30,
            decoration: selected
                ? AppSurfaces.key(KeyVariant.primary, radius: 7)
                : null,
            child: Icon(
              icon,
              size: 16,
              color: selected ? AppPalette.onBrand : AppPalette.textSecondary,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: AppSurfaces.segmented(radius: 10),
      child: Row(
        // A view the user cannot read is not offered — switching to it would
        // only ever show the restricted placeholder.
        children: [
          if (_canReadCalendar(roles))
            option(
              _EventsViewMode.calendar,
              Icons.calendar_month_outlined,
              'Calendar',
            ),
          if (_canReadEvents(roles)) ...[
            option(_EventsViewMode.grid, Icons.grid_view_outlined, 'Grid'),
            option(_EventsViewMode.list, Icons.view_agenda_outlined, 'List'),
          ],
        ],
      ),
    );
  }

  // ----------------------------------------------------- calendar view

  /// Admins may view the whole school; everyone else is limited to their
  /// own items (server also enforces this).
  String _feedScope(RoleCubit roles) =>
      roles.isAdmin ? 'ALL_ITEMS' : 'MY_ITEMS';

  Color _feedColor(CalendarFeedItem item) {
    final hex = item.colorHint.replaceAll('#', '');
    if (hex.length == 6) {
      final v = int.tryParse('FF\$hex', radix: 16);
      if (v != null) return Color(v);
    }
    return item.isTask
        ? AppPalette.dataSun
        : item.isHoliday
            ? _holidayRed
            : AppColors.themeColor;
  }

  /// Renders a feed row with the owning module's own card so the calendar
  /// matches the Events and Tasks tabs: [TaskCard] (inline status/priority)
  /// for tasks, [EventCard] (RSVP bar) for events, and a compact banner for
  /// holidays.
  Widget _feedItemCard(
    BuildContext context,
    EventsState state,
    RoleCubit roles,
    CalendarFeedItem item,
  ) {
    if (item.isTask) {
      final task = item.toTask();
      final canManage = TaskAccess.canManageTask(
        roles: roles,
        task: task,
        userCode: state.currentUserCode,
        staffCode: state.currentStaffCode,
        userName: state.currentUserName,
      );
      return TaskCard(
        key: ValueKey(task.code),
        task: task,
        schoolTimeZone: context.read<TasksCubit>().state.schoolTimeZone,
        onTap: () => _openFeedItem(context, item),
        onStatusTap: canManage ? () => _pickTaskStatus(context, task) : null,
        // onPriorityTap:
        //     canManage ? () => _pickTaskPriority(context, task) : null,
      );
    }
    if (item.isHoliday) return _feedHolidayBanner(item);

    // Event — reuse the Events list card so the calendar matches the other
    // views. The feed row has no roster/myRsvp, so prefer the rich
    // occurrence when it is loaded; RSVP is hidden for past occurrences and
    // for non-participants.
    final rich = state.eventByOccurrence(item.code, eventCode: item.eventCode);
    final event = rich ?? item.toEvent();
    final canRsvp =
        !event.isPast && rich != null && _canRespond(state, roles, rich);
    return EventCard(
      event: event,
      myRsvp: event.myRsvpStatus,
      onRsvp: canRsvp
          ? (status) => _respond(context, event, status, roles.isParent)
          : null,
      showRsvpCounts: EventAccess.canSeeRsvpSummary(roles),
      onTap: () => _openFeedItem(context, item),
    );
  }

  Future<void> _pickTaskStatus(BuildContext context, Task task) async {
    final cubit = context.read<TasksCubit>();
    final picked = await showTaskOptionPicker<TaskStatus>(
      context: context,
      title: 'Move task to',
      options: TaskStatus.values,
      current: task.status,
      colorOf: TaskUiUtils.statusColor,
      iconOf: TaskUiUtils.statusIcon,
      labelOf: (s) => s.label,
    );
    if (picked == null) return;
    await cubit.changeStatus(task.code, picked);
    if (!context.mounted) return;
    // The feed row carries its own copy of the status — refresh it.
    context.read<EventsCubit>().resetCalendarFeed();
    await context.read<EventsCubit>().loadCalendarFeed(
          _focusedDay,
          scope: _feedScope(context.read<RoleCubit>()),
        );
  }

  // Future<void> _pickTaskPriority(BuildContext context, Task task) async {
  //   final cubit = context.read<TasksCubit>();
  //   final picked = await showTaskOptionPicker<TaskPriority>(
  //     context: context,
  //     title: 'Set priority',
  //     options: TaskPriority.values,
  //     current: task.priority,
  //     colorOf: TaskUiUtils.priorityColor,
  //     iconOf: TaskUiUtils.priorityIcon,
  //     labelOf: (p) => p.label,
  //   );
  //   if (picked == null) return;
  //   await cubit.changePriority(task.code, picked);
  //   if (!context.mounted) return;
  //   context.read<EventsCubit>().resetCalendarFeed();
  //   await context.read<EventsCubit>().loadCalendarFeed(
  //         _focusedDay,
  //         scope: _feedScope(context.read<RoleCubit>()),
  //       );
  // }

  Widget _feedHolidayBanner(CalendarFeedItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _holidayRed.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _holidayRed.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.beach_access_outlined, size: 18, color: _holidayRed),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              item.name,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _holidayRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openFeedItem(BuildContext context, CalendarFeedItem item) {
    if (item.isEvent) {
      context.push(
        EventDetailScreen.routeName,
        extra: <String, dynamic>{
          'eventCode': item.eventCode,
          'occurrenceCode': item.code,
        },
      );
    } else if (item.isTask) {
      // TaskDetailScreen resolves via TasksState.taskByCode, which matches
      // the ASSIGNMENT code (TSA_…) — the feed's `code` — not the series
      // code (TSK_…). The tasks list must be loaded for the lookup to hit.
      context.push(
        TaskDetailScreen.routeName,
        extra: <String, dynamic>{'taskCode': item.code},
      );
    }
    // Holidays are read-only on the calendar — no navigation.
  }

  Widget _calendarCard(BuildContext context, EventsState state, RoleCubit roles) {
    final allowedKinds = EventAccess.readableCalendarKinds(roles);
    return Container(
      decoration: AppSurfaces.card(radius: 12),
      child: TableCalendar<CalendarFeedItem>(
        firstDay: DateTime(DateTime.now().year - 2),
        lastDay: DateTime(DateTime.now().year + 3),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        availableCalendarFormats: const {
          CalendarFormat.month: 'Week',
          CalendarFormat.week: 'Month',
        },
        startingDayOfWeek: StartingDayOfWeek.monday,
        selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
        holidayPredicate: (day) =>
            state.calendarItemsOn(day, allowedKinds: allowedKinds)
                .any((i) => i.isHoliday),
        eventLoader: (day) =>
            state.calendarItemsOn(day, allowedKinds: allowedKinds),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onFormatChanged: (format) => setState(() => _calendarFormat = format),
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
          // Load the newly visible month's unified feed (events + tasks +
          // holidays) on demand.
          context.read<EventsCubit>().loadCalendarFeed(
                focusedDay,
                scope: _feedScope(roles),
              );
        },
        headerStyle: HeaderStyle(
          titleCentered: true,
          titleTextStyle: const TextStyle(
            color: AppColors.primaryColor,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          formatButtonTextStyle: const TextStyle(
            fontSize: 12,
            color: AppColors.themeColor,
          ),
          formatButtonDecoration: BoxDecoration(
            border: Border.all(
              color: AppColors.themeColor.withValues(alpha: 0.4),
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          leftChevronIcon: const Icon(
            Icons.chevron_left,
            color: AppColors.primaryColor,
          ),
          rightChevronIcon: const Icon(
            Icons.chevron_right,
            color: AppColors.primaryColor,
          ),
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: AppColors.themeColor.withValues(alpha: 0.25),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: AppColors.themeColor,
            shape: BoxShape.circle,
          ),
          holidayDecoration: BoxDecoration(
            color: _holidayRed.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          holidayTextStyle: const TextStyle(color: _holidayRed),
          markersMaxCount: 3,
          markerSize: 5,
          markerDecoration: const BoxDecoration(
            color: AppColors.themeColor,
            shape: BoxShape.circle,
          ),
          outsideDaysVisible: false,
        ),
        calendarBuilders: CalendarBuilders<CalendarFeedItem>(
          markerBuilder: (context, day, items) {
            if (items.isEmpty) return null;
            return Positioned(
              bottom: 4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final item in items.take(3))
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: _feedColor(item),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _dayList(BuildContext context, EventsState state, RoleCubit roles) {
    final items = state.calendarItemsOn(
      _selectedDay,
      allowedKinds: EventAccess.readableCalendarKinds(roles),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              DateFormat('EEEE, MMM d').format(_selectedDay),
              style: const TextStyle(
                color: AppColors.primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            if (state.calendarLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: items.isEmpty
              ? _emptyState(
                  state.calendarLoading
                      ? 'Loading…'
                      : 'Nothing scheduled for this day',
                )
              : RefreshIndicator(
                  color: AppColors.themeColor,
                  onRefresh: () async {
                    context.read<EventsCubit>().resetCalendarFeed();
                    await context.read<EventsCubit>().loadCalendarFeed(
                          _focusedDay,
                          scope: _feedScope(roles),
                        );
                  },
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 90),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) =>
                        _feedItemCard(context, state, roles, items[index]),
                  ),
                ),
        ),
      ],
    );
  }

  // --------------------------------------------------- grid & list view

  Widget _gridView(
    BuildContext context,
    EventsState state,
    RoleCubit roles,
    List<Event> events, {
    required String emptyMessage,
  }) =>
      _groupedView(context, state, roles, events,
          grid: true, emptyMessage: emptyMessage);

  Widget _listView(
    BuildContext context,
    EventsState state,
    RoleCubit roles,
    List<Event> events, {
    required String emptyMessage,
  }) =>
      _groupedView(context, state, roles, events,
          grid: false, emptyMessage: emptyMessage);

  /// Shared month-grouped layout for the grid and list views: one
  /// collapsible "Month Year" section per month containing that month's
  /// occurrence cards, a single scrollable (so the pagination trigger and
  /// bottom spinner behave identically in both views).
  Widget _groupedView(
    BuildContext context,
    EventsState state,
    RoleCubit roles,
    List<Event> events, {
    required bool grid,
    required String emptyMessage,
  }) {
    if (events.isEmpty) {
      return _emptyState(emptyMessage);
    }

    // Group by month preserving the incoming (date-sorted) order.
    final months = <DateTime, List<Event>>{};
    for (final event in events) {
      final key = DateTime(event.date.year, event.date.month);
      months.putIfAbsent(key, () => []).add(event);
    }

    Widget card(Event event) => grid
        ? EventGridCard(
            event: event,
            myRsvp: event.myRsvpStatus,
            showRsvpCounts: EventAccess.canSeeRsvpSummary(roles),
            onTap: () => _openDetail(context, event),
            onRsvp: _canRespond(state, roles, event)
                ? (status) => _respond(context, event, status, roles.isParent)
                : null,
          )
        : EventCard(
            event: event,
            myRsvp: event.myRsvpStatus,
            onRsvp: _canRespond(state, roles, event)
                ? (status) => _respond(context, event, status, roles.isParent)
                : null,
            showRsvpCounts: EventAccess.canSeeRsvpSummary(roles),
            onTap: () => _openDetail(context, event),
          );

    String monthKey(DateTime d) => '${d.year}-${d.month}';

    return RefreshIndicator(
      color: AppColors.themeColor,
      onRefresh: () => context.read<EventsCubit>().load(silent: true),
      child: NotificationListener<ScrollNotification>(
          onNotification: (n) {
            if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
              context.read<EventsCubit>().loadMoreEvents();
            }
            return false;
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 90),
            children: [
              for (final entry in months.entries) ...[
                // Minimal month separator: "July 2026" + collapse chevron.
                InkWell(
                  onTap: () {
                    final key = monthKey(entry.key);
                    setState(() {
                      if (!_collapsedMonths.remove(key)) {
                        _collapsedMonths.add(key);
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            DateFormat('MMMM yyyy').format(entry.key),
                            style: const TextStyle(
                              color: AppColors.primaryColor,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          _collapsedMonths.contains(monthKey(entry.key))
                              ? Icons.keyboard_arrow_down
                              : Icons.keyboard_arrow_up,
                          size: 20,
                          color: AppPalette.iconMuted,
                        ),
                      ],
                    ),
                  ),
                ),
                if (!_collapsedMonths.contains(monthKey(entry.key)))
                  grid
                      ? GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.95,
                          children: [
                            for (final event in entry.value) card(event),
                          ],
                        )
                      : Column(
                          children: [
                            for (final event in entry.value)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: card(event),
                              ),
                          ],
                        ),
              ],
              // Always-visible footer so the user knows whether more
              // data exists — even with every month collapsed.
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Center(
                  child: state.isLoadingMore
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : state.hasMoreEvents
                          ? OutlinedButton.icon(
                              onPressed: () => context
                                  .read<EventsCubit>()
                                  .loadMoreEvents(),
                              icon: const Icon(Icons.expand_more, size: 18),
                              label: const Text('Load more events'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.themeColor,
                                visualDensity: VisualDensity.compact,
                              ),
                            )
                          : Text(
                              "You're all caught up",
                              style: TextStyle(
                                fontSize: 12,
                                color: AppPalette.textSecondary,
                              ),
                            ),
                ),
              ),
            ],
        ),
      ),
    );
  }

  Widget _searchResults(
    BuildContext context,
    EventsState state,
    RoleCubit roles,
  ) {
    final results = _upcomingFirst(state.searchResults);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${results.length} result${results.length == 1 ? '' : 's'} for '
          '"${state.searchQuery}"',
          style: TextStyle(fontSize: 12.5, color: AppPalette.textSecondary),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: results.isEmpty
              ? _emptyState('No events match your search')
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: results.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final event = results[index];
                    return EventCard(
                      event: event,
                      myRsvp: event.myRsvpStatus,
                      onRsvp: _canRespond(state, roles, event) &&
                              !event.isPast
                          ? (status) =>
                              _respond(context, event, status, roles.isParent)
                          : null,
                      showRsvpCounts: EventAccess.canSeeRsvpSummary(roles),
                      onTap: () => _openDetail(context, event),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // -------------------------------------------------------- holidays tab

  Widget _holidaysTab(
    BuildContext context,
    EventsState state,
    RoleCubit roles,
  ) {
    if (!_canReadHolidays(roles)) {
      return const AccessRestrictedView(
        message: 'You do not have access to holidays for your selected school.',
      );
    }
    if (state.isLoading) {
      return const Center(child: PrimaryCircularLoader());
    }
    // Staff and parents see the holiday list read-only (PRD FR-HL-12).
    final canManage = EventAccess.canManageHolidays(roles);
    final cubit = context.read<EventsCubit>();

    final pending = state.pendingFederalHolidays;
    final active = state.activeHolidays;
    final rejected = state.rejectedFederalHolidays;

    return RefreshIndicator(
      color: AppColors.themeColor,
      onRefresh: () => cubit.load(silent: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 90),
        children: [
          _yearSelector(context, state),
          const SizedBox(height: 4),
          if (pending.isEmpty && active.isEmpty && rejected.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 60),
              child: _emptyState('No holidays for ${state.selectedYear}'),
            ),

          // Pending Federal Holidays — admin-only, expanded by default since
          // they need a decision (FR-HL-02).
          if (canManage && pending.isNotEmpty) ...[
            ExpandableSection(
              title: 'Pending Federal Holidays',
              count: pending.length,
              icon: Icons.hourglass_bottom,
              accentColor: AppPalette.statusWarning,
              initiallyExpanded: true,
              child: Column(
                children: [
                  for (final holiday in pending)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _highlightable(
                        holiday,
                        HolidayCard(
                          holiday: holiday,
                          onStatusChanged: (status) => _changeHolidayStatus(
                            context,
                            cubit,
                            holiday.code,
                            status,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Active Holidays — considered federal + all school (FR-HL-09).
          if (active.isNotEmpty) ...[
            ExpandableSection(
              title: 'Active Holidays',
              count: active.length,
              icon: Icons.event_available_outlined,
              accentColor: AppColors.themeColor,
              initiallyExpanded: true,
              child: Column(
                children: [
                  for (final holiday in active)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _highlightable(
                        holiday,
                        HolidayCard(
                          holiday: holiday,
                          onEdit: canManage && holiday.type == HolidayType.school
                              ? () => showHolidayFormSheet(
                                  context,
                                  holiday: holiday,
                                )
                              : null,
                          onDelete:
                              canManage && holiday.type == HolidayType.school
                              ? () => _confirmDeleteHoliday(context, holiday)
                              : null,
                          onStatusChanged:
                              canManage && holiday.type == HolidayType.federal
                              ? (status) => _changeHolidayStatus(
                                  context,
                                  cubit,
                                  holiday.code,
                                  status,
                                )
                              : null,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Rejected Federal Holidays — admin-only, re-approvable, collapsed
          // by default as they're less frequently revisited (FR-HL-04/05).
          if (canManage && rejected.isNotEmpty)
            ExpandableSection(
              title: 'Rejected Federal Holidays',
              count: rejected.length,
              icon: Icons.cancel_outlined,
              accentColor: AppPalette.textMuted,
              child: Column(
                children: [
                  for (final holiday in rejected)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _highlightable(
                        holiday,
                        HolidayCard(
                          holiday: holiday,
                          onStatusChanged: (status) => _changeHolidayStatus(
                            context,
                            cubit,
                            holiday.code,
                            status,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Flashes [card] when a holiday notification deep link named this holiday.
  /// A no-op (zero-cost passthrough) in normal navigation, where
  /// `highlightHolidayName` is null.
  Widget _highlightable(Holiday holiday, Widget card) => HolidayHighlight(
    holiday: holiday,
    highlightName: widget.highlightHolidayName,
    child: card,
  );

  /// Year dropdown — current year ±2 (5 years total), default current year
  /// (FR-HL-07/08).
  Widget _yearSelector(BuildContext context, EventsState state) {
    final currentYear = DateTime.now().year;
    final years = HolidayYearWindow.options();
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: AppSurfaces.key(KeyVariant.primary, radius: 10),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: years.contains(state.selectedYear)
                ? state.selectedYear
                : currentYear,
            isDense: true,
            dropdownColor: AppColors.cardColor,
            icon: const Icon(
              Icons.arrow_drop_down,
              size: 20,
              color: AppPalette.onBrand,
            ),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
            // The closed pill sits on the gradient, so its label is white;
            // the open menu is on white, so items keep the dark style above.
            selectedItemBuilder: (context) => [
              for (final year in years)
                Center(
                  child: Text(
                    '$year',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppPalette.onBrand,
                    ),
                  ),
                ),
            ],
            items: [
              for (final year in years)
                DropdownMenuItem<int>(value: year, child: Text('$year')),
            ],
            onChanged: (year) {
              if (year != null) {
                context.read<EventsCubit>().setSelectedYear(year);
              }
            },
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteHoliday(
    BuildContext context,
    Holiday holiday,
  ) async {
    final confirmed = await showDeleteHolidayConfirmation(context, holiday);
    if (!confirmed || !context.mounted) return;
    final (ok, message) = await context.read<EventsCubit>().deleteHoliday(
      holiday.code,
    );
    if (!context.mounted) return;
    CoreUtils.showTopSnackBar(
      context: context,
      message: message,
      isSuccess: ok,
      isError: !ok,
    );
  }

  Future<void> _changeHolidayStatus(
    BuildContext context,
    EventsCubit cubit,
    String code,
    HolidayStatus status,
  ) async {
    final (ok, message) = await cubit.setHolidayStatus(code, status);
    if (!context.mounted) return;
    CoreUtils.showTopSnackBar(
      context: context,
      message: message,
      isSuccess: ok,
      isError: !ok,
    );
  }

  // ------------------------------------------------------------ shared

  Widget _emptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available_outlined,
            size: 44,
            color: AppPalette.iconMuted,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: AppPalette.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Future<void> _respond(
    BuildContext context,
    Event event,
    EventRsvpStatus status,
    bool isParent,
  ) async {
    final (ok, message) = await context.read<EventsCubit>().respond(
      occurrence: event,
      status: status,
      userType: isParent ? 'PARENT' : 'STAFF',
    );
    if (!context.mounted) return;
    CoreUtils.showTopSnackBar(
      context: context,
      message: message,
      isSuccess: ok,
      isError: !ok,
    );
  }

  void _openDetail(BuildContext context, Event event) {
    context.push(
      EventDetailScreen.routeName,
      extra: <String, dynamic>{
        'eventCode': event.code,
        'occurrenceCode': event.occurrenceCode,
      },
    );
  }

  void _openForm(BuildContext context) {
    context.push(
      EventFormScreen.routeName,
      extra: <String, dynamic>{'initialDate': _selectedDay.toIso8601String()},
    );
  }

  /// Upcoming events first (today onward ascending), past events after
  /// (most recent first) — keeps grid/list/search focused on what's next.
  List<Event> _upcomingFirst(List<Event> events) {
    final today = DateTime.now();
    final cutoff = DateTime(today.year, today.month, today.day);
    final upcoming = <Event>[];
    final past = <Event>[];
    for (final event in events) {
      (event.date.isBefore(cutoff) ? past : upcoming).add(event);
    }
    upcoming.sort((a, b) => a.date.compareTo(b.date));
    past.sort((a, b) => b.date.compareTo(a.date));
    return [...upcoming, ...past];
  }

  /// Moves the calendar's focus/selection to the most recently completed
  /// event so it (and its day) are shown first. No-op when there are none.
  /// Must be called inside [setState].
  void _jumpToLatestCompleted(EventsState state) {
    final completed = state.completedEvents;
    if (completed.isEmpty) return;
    final latest = completed.first.date;
    _selectedDay = latest;
    _focusedDay = latest;
  }
}
