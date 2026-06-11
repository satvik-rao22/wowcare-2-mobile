import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/domain/features/events/entities/event.dart';
import 'package:wowcare/domain/features/events/entities/holiday.dart';
import 'package:wowcare/presentation/features/events/cubit/events_cubit.dart';
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
    final isParent = context.watch<RoleCubit>().isParent;

    return GlobalScaffold(
      hasBackButton: false,
      showCustomNavigationBar: true,
      body: BlocBuilder<EventsCubit, EventsState>(
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(context, isParent),
                const SizedBox(height: 10),
                _tabSwitcher(),
                const SizedBox(height: 10),
                if (_tabIndex == 0)
                  Expanded(child: _eventsTab(context, state, isParent))
                else
                  Expanded(child: _holidaysTab(context, state, isParent)),
              ],
            ),
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------ header

  Widget _header(BuildContext context, bool isParent) {
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
            if (!isParent) ...[
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
          onTap: () => setState(() => _tabIndex = index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              gradient:
                  selected ? AppColors.buildPrimaryGradient() : null,
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
                    color:
                        selected ? Colors.white : AppColors.primaryColor,
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

  Widget _eventsTab(BuildContext context, EventsState state, bool isParent) {
    if (state.isLoading) {
      return const Center(child: PrimaryCircularLoader());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _toolbar(context, state),
        const SizedBox(height: 10),
        if (state.isSearching)
          Expanded(child: _searchResults(context, state, isParent))
        else ...[
          switch (_viewMode) {
            _EventsViewMode.calendar => Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _calendarCard(context, state),
                    const SizedBox(height: 10),
                    Expanded(child: _dayList(context, state, isParent)),
                  ],
                ),
              ),
            _EventsViewMode.grid =>
              Expanded(child: _gridView(context, state, isParent)),
            _EventsViewMode.list =>
              Expanded(child: _listView(context, state, isParent)),
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
                prefixIcon:
                    const Icon(Icons.search, size: 18, color: Colors.grey),
                suffixIcon: state.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close,
                            size: 16, color: Colors.grey),
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
                  borderSide:
                      const BorderSide(color: AppColors.themeColor),
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
              gradient:
                  selected ? AppColors.buildPrimaryGradient() : null,
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
          option(_EventsViewMode.calendar, Icons.calendar_month_outlined,
              'Calendar'),
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
        onFormatChanged: (format) =>
            setState(() => _calendarFormat = format),
        onPageChanged: (focusedDay) => _focusedDay = focusedDay,
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

  Widget _dayList(BuildContext context, EventsState state, bool isParent) {
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
                          showRsvpCounts: !isParent,
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
          const Icon(Icons.beach_access_outlined,
              size: 18, color: _holidayRed),
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

  Widget _gridView(BuildContext context, EventsState state, bool isParent) {
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
          return EventGridCard(
            event: event,
            myRsvp: event.rsvpFor(state.currentUserCode)?.status,
            showRsvpCounts: !isParent,
            onTap: () => _openDetail(context, event),
            onRsvp: (status) => _respond(context, event, status, isParent),
          );
        },
      ),
    );
  }

  Widget _listView(BuildContext context, EventsState state, bool isParent) {
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
          final showHeader = index == 0 ||
              !_sameMonth(events[index - 1].date, event.date);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showHeader)
                Padding(
                  padding: EdgeInsets.only(
                      top: index == 0 ? 0 : 10, bottom: 8),
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
                  showRsvpCounts: !isParent,
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
    bool isParent,
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
                      showRsvpCounts: !isParent,
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
    bool isParent,
  ) {
    if (state.isLoading) {
      return const Center(child: PrimaryCircularLoader());
    }
    if (state.holidays.isEmpty) {
      return _emptyState('No holidays added yet');
    }
    final cubit = context.read<EventsCubit>();
    final school = state.holidays
        .where((h) => h.type == HolidayType.school)
        .toList();
    final federal = state.holidays
        .where((h) => h.type == HolidayType.federal)
        .toList();
    return RefreshIndicator(
      color: AppColors.themeColor,
      onRefresh: () => cubit.load(silent: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 90),
        children: [
          if (school.isNotEmpty) ...[
            _holidaySectionHeader('School Holidays'),
            for (final holiday in school)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: HolidayCard(
                  holiday: holiday,
                  onEdit: isParent
                      ? null
                      : () =>
                          showHolidayFormSheet(context, holiday: holiday),
                  onDelete: isParent
                      ? null
                      : () => _confirmDeleteHoliday(context, holiday),
                ),
              ),
          ],
          if (federal.isNotEmpty) ...[
            _holidaySectionHeader('Federal Holidays'),
            for (final holiday in federal)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: HolidayCard(
                  holiday: holiday,
                  onStatusChanged: isParent
                      ? null
                      : (status) =>
                          cubit.setHolidayStatus(holiday.code, status),
                ),
              ),
          ],
        ],
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
            style: TextButton.styleFrom(
              foregroundColor: AppColors.errorColor,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<EventsCubit>().deleteHoliday(holiday.code);
    }
  }

  // ------------------------------------------------------------ shared

  Widget _emptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available_outlined,
              size: 44, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _respond(
    BuildContext context,
    Event event,
    EventRsvpStatus status,
    bool isParent,
  ) {
    context.read<EventsCubit>().respond(
          eventCode: event.code,
          status: status,
          userType: isParent ? 'PARENT' : 'STAFF',
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
      extra: <String, dynamic>{
        'initialDate': _selectedDay.toIso8601String(),
      },
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
