import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/events/entities/event.dart';
import 'package:wowcare/domain/features/events/entities/holiday.dart';
import 'package:wowcare/presentation/features/events/cubit/events_cubit.dart';
import 'package:wowcare/presentation/features/events/utils/event_access.dart';
import 'package:wowcare/presentation/features/events/utils/event_ui_utils.dart';
import 'package:wowcare/presentation/features/events/view/event_detail_screen.dart';
import 'package:wowcare/presentation/features/events/view/event_form_screen.dart';
import 'package:wowcare/presentation/features/events/widgets/event_card.dart';
import 'package:wowcare/presentation/features/events/widgets/event_filter_sheet.dart';
import 'package:wowcare/presentation/features/events/widgets/event_grid_card.dart';
import 'package:wowcare/presentation/features/events/widgets/holiday_card.dart';
import 'package:wowcare/presentation/features/events/widgets/holiday_form_sheet.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/gradient_add_button.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';

/// How the Events tab lays out its content, mirroring the web design's
/// calendar / grid / list switcher.
enum _EventsViewMode { calendar, grid, list }

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  static const String routeName = '/dashboard/events';

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  static const Color _holidayRed = Color(0xFFD32F2F);

  int _tabIndex = 0; // 0 = Events, 1 = Holidays
  _EventsViewMode _viewMode = _EventsViewMode.calendar;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week;
  final TextEditingController _searchController = TextEditingController();

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
        child: BlocBuilder<EventsCubit, EventsState>(
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(context, roles),
                  const SizedBox(height: 10),
                  _tabSwitcher(),
                  const SizedBox(height: 10),
                  if (_tabIndex == 0)
                    Expanded(child: _eventsTab(context, state, roles))
                  else
                    Expanded(child: _holidaysTab(context, state, roles)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ------------------------------------------------------------ header

  Widget _header(BuildContext context, RoleCubit roles) {
    // Staff may add events but not holidays; parents may add neither.
    final canAdd = _tabIndex == 0
        ? EventAccess.canCreateEvents(roles)
        : EventAccess.canManageHolidays(roles);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Events',
          style: TextStyle(
            color: AppColors.primaryColor,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        Row(
          children: [
            if (_tabIndex == 0 && _viewMode == _EventsViewMode.calendar)
              TextButton(
                onPressed: () {
                  setState(() {
                    _focusedDay = DateTime.now();
                    _selectedDay = DateTime.now();
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.themeColor,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Today'),
              ),
            if (canAdd) ...[
              const SizedBox(width: 4),
              GradientAddButton(
                onTap: () {
                  if (_tabIndex == 0) {
                    _openForm(context);
                  } else {
                    showHolidayFormSheet(context);
                  }
                },
              ),
            ],
          ],
        ),
      ],
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
            if (index == 1) {
              context.read<EventsCubit>().refreshHolidays();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              gradient: selected ? AppColors.buildPrimaryGradient() : null,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: selected ? Colors.white : AppColors.primaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppColors.primaryColor,
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.08),
        ),
      ),
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
    if (state.isLoading) {
      return const Center(child: PrimaryCircularLoader());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _toolbar(context, state),
        const SizedBox(height: 10),
        if (state.isSearching)
          Expanded(child: _searchResults(context, state, roles))
        else ...[
          switch (_viewMode) {
            _EventsViewMode.calendar => Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _calendarCard(context, state),
                  const SizedBox(height: 10),
                  Expanded(child: _dayList(context, state, roles)),
                ],
              ),
            ),
            _EventsViewMode.grid => Expanded(
              child: _gridView(context, state, roles),
            ),
            _EventsViewMode.list => Expanded(
              child: _listView(context, state, roles),
            ),
          },
        ],
      ],
    );
  }

  /// Search field + filter button + view-mode switcher.
  Widget _toolbar(BuildContext context, EventsState state) {
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
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 18,
                  color: Colors.grey,
                ),
                suffixIcon: state.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          cubit.setSearchQuery('');
                        },
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.themeColor),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _filterButton(context, state),
        const SizedBox(width: 8),
        _viewSwitcher(),
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
              : Colors.white,
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
                      : Colors.grey.shade300,
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
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _viewSwitcher() {
    Widget option(_EventsViewMode mode, IconData icon, String tooltip) {
      final selected = _viewMode == mode;
      return Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: () => setState(() => _viewMode = mode),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: selected ? AppColors.buildPrimaryGradient() : null,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          option(
            _EventsViewMode.calendar,
            Icons.calendar_month_outlined,
            'Calendar',
          ),
          option(_EventsViewMode.grid, Icons.grid_view_outlined, 'Grid'),
          option(_EventsViewMode.list, Icons.view_agenda_outlined, 'List'),
        ],
      ),
    );
  }

  // ----------------------------------------------------- calendar view

  Widget _calendarCard(BuildContext context, EventsState state) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TableCalendar<Event>(
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
        holidayPredicate: state.isHoliday,
        eventLoader: state.eventsOn,
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onFormatChanged: (format) => setState(() => _calendarFormat = format),
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
          context.read<EventsCubit>().ensureHolidaysForYear(focusedDay.year);
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
        calendarBuilders: CalendarBuilders<Event>(
          markerBuilder: (context, day, events) {
            if (events.isEmpty) return null;
            return Positioned(
              bottom: 4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final event in events.take(3))
                    Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: EventUiUtils.typeColor(event.type),
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
    final dayEvents = state.eventsOn(_selectedDay);
    final dayHolidays = state.holidaysOn(_selectedDay);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          DateFormat('EEEE, MMM d').format(_selectedDay),
          style: const TextStyle(
            color: AppColors.primaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: dayEvents.isEmpty && dayHolidays.isEmpty
              ? _emptyState('Nothing scheduled for this day')
              : RefreshIndicator(
                  color: AppColors.themeColor,
                  onRefresh: () =>
                      context.read<EventsCubit>().load(silent: true),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 90),
                    children: [
                      for (final holiday in dayHolidays) ...[
                        _holidayBanner(holiday),
                        const SizedBox(height: 8),
                      ],
                      for (final event in dayEvents) ...[
                        EventCard(
                          event: event,
                          showRsvpCounts: EventAccess.canSeeRsvpSummary(roles),
                          onTap: () => _openDetail(context, event),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _holidayBanner(Holiday holiday) {
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
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  holiday.name,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: _holidayRed,
                  ),
                ),
                Text(
                  '${holiday.type.label} holiday • All day',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: _holidayRed.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------- grid & list view

  Widget _gridView(BuildContext context, EventsState state, RoleCubit roles) {
    final events = _upcomingFirst(state.filteredEvents);
    if (events.isEmpty) {
      return _emptyState('No events match the current filters');
    }
    return RefreshIndicator(
      color: AppColors.themeColor,
      onRefresh: () => context.read<EventsCubit>().load(silent: true),
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 90),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.95,
        ),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          final canRsvp = EventAccess.canRsvp(
            roles: roles,
            event: event,
            userCode: state.currentUserCode,
            staffCode: state.currentStaffCode,
          );
          return EventGridCard(
            event: event,
            myRsvp: event.rsvpFor(state.currentUserCode)?.status,
            showRsvpCounts: EventAccess.canSeeRsvpSummary(roles),
            onTap: () => _openDetail(context, event),
            onRsvp: canRsvp
                ? (status) => _respond(context, event, status, roles.isParent)
                : null,
          );
        },
      ),
    );
  }

  Widget _listView(BuildContext context, EventsState state, RoleCubit roles) {
    final events = _upcomingFirst(state.filteredEvents);
    if (events.isEmpty) {
      return _emptyState('No events match the current filters');
    }
    return RefreshIndicator(
      color: AppColors.themeColor,
      onRefresh: () => context.read<EventsCubit>().load(silent: true),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 90),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          final showHeader =
              index == 0 || !_sameMonth(events[index - 1].date, event.date);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showHeader)
                Padding(
                  padding: EdgeInsets.only(top: index == 0 ? 0 : 10, bottom: 8),
                  child: Text(
                    DateFormat('MMMM yyyy').format(event.date),
                    style: const TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: EventCard(
                  event: event,
                  showRsvpCounts: EventAccess.canSeeRsvpSummary(roles),
                  onTap: () => _openDetail(context, event),
                ),
              ),
            ],
          );
        },
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
          style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
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

          // Pending Federal Holidays — admin-only accordion (FR-HL-02).
          if (canManage && pending.isNotEmpty) ...[
            _holidaySectionHeader('Pending Federal Holidays'),
            for (final holiday in pending)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: HolidayCard(
                  holiday: holiday,
                  onStatusChanged: (status) => _changeHolidayStatus(
                    context,
                    cubit,
                    holiday.code,
                    status,
                  ),
                ),
              ),
          ],

          // Active Holidays — considered federal + all school (FR-HL-09).
          if (active.isNotEmpty) ...[
            _holidaySectionHeader('Active Holidays'),
            for (final holiday in active)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: HolidayCard(
                  holiday: holiday,
                  onEdit: canManage && holiday.type == HolidayType.school
                      ? () => showHolidayFormSheet(context, holiday: holiday)
                      : null,
                  onDelete: canManage && holiday.type == HolidayType.school
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
          ],

          // Rejected Federal Holidays — admin-only, re-approvable (FR-HL-04/05).
          if (canManage && rejected.isNotEmpty) ...[
            _holidaySectionHeader('Rejected Federal Holidays'),
            for (final holiday in rejected)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: HolidayCard(
                  holiday: holiday,
                  onStatusChanged: (status) => _changeHolidayStatus(
                    context,
                    cubit,
                    holiday.code,
                    status,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  /// Year dropdown — current year ±2 (5 years total), default current year
  /// (FR-HL-07/08).
  Widget _yearSelector(BuildContext context, EventsState state) {
    final currentYear = DateTime.now().year;
    final years = [for (var y = currentYear - 2; y <= currentYear + 2; y++) y];
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: years.contains(state.selectedYear)
                ? state.selectedYear
                : currentYear,
            isDense: true,
            icon: const Icon(Icons.arrow_drop_down, size: 20),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
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

  Widget _holidaySectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 2),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.primaryColor,
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _confirmDeleteHoliday(
    BuildContext context,
    Holiday holiday,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete holiday?'),
        content: Text('"${holiday.name}" will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
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
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
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
      eventCode: event.code,
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
      extra: <String, dynamic>{'eventCode': event.code},
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

  static bool _sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;
}
