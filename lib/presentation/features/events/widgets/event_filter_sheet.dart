import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/domain/features/events/entities/calendar_feed_item.dart';
import 'package:wowcare/domain/features/events/entities/event.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_ui_utils.dart';
import 'package:wowcare/presentation/features/events/cubit/events_cubit.dart';
import 'package:wowcare/presentation/features/events/utils/event_ui_utils.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';

/// Bottom-drawer filter panel for events. Short, fixed dimensions (scope,
/// event types) stay inline as chips; the open-ended Classrooms dimension
/// drills into a second searchable stage *within the same sheet* so it scales
/// to large lists without a wall of chips. Options are sourced from the
/// already-loaded events (offline-safe, no extra network calls) and changes
/// apply live through [EventsCubit].
Future<void> showEventFilterSheet(BuildContext context) {
  final cubit = context.read<EventsCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: const _EventFilterSheet(),
    ),
  );
}

/// Which second-stage list (if any) the sheet is currently showing.
enum _FilterStage { root, classrooms }

class _EventFilterSheet extends StatefulWidget {
  const _EventFilterSheet();

  @override
  State<_EventFilterSheet> createState() => _EventFilterSheetState();
}

class _EventFilterSheetState extends State<_EventFilterSheet> {
  _FilterStage _stage = _FilterStage.root;

  void _open(_FilterStage stage) => setState(() => _stage = stage);
  void _back() => setState(() => _stage = _FilterStage.root);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EventsCubit, EventsState>(
      builder: (context, state) {
        final cubit = context.read<EventsCubit>();
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.82,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, animation) => SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(child.key == const ValueKey(_FilterStage.root)
                      ? -0.15
                      : 0.15, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: _stage == _FilterStage.root
                  ? _root(context, state, cubit)
                  : _classroomStage(context, state, cubit),
            ),
          ),
        );
      },
    );
  }

  // ----------------------------------------------------------------- root

  Widget _root(BuildContext context, EventsState state, EventsCubit cubit) {
    return Padding(
      key: const ValueKey(_FilterStage.root),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _grabber(),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
              if (state.activeFilterCount > 0)
                TextButton(
                  onPressed: cubit.clearAllFilters,
                  child: const Text('Clear all',
                      style: TextStyle(fontSize: 12.5)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 4),
              children: [
                // Scope toggle (FR-SC-07). Parents always see their own feed.
                if (!context.watch<RoleCubit>().isParent) ...[
                  _sectionLabel('Showing'),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _chip(
                        label: 'All events',
                        color: AppColors.themeColor,
                        selected: !state.showMineOnly,
                        onTap: () => cubit.setShowMineOnly(false),
                      ),
                      _chip(
                        label: 'My events',
                        color: AppColors.themeColor,
                        selected: state.showMineOnly,
                        onTap: () => cubit.setShowMineOnly(true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                // Calendar "Show" filter — applies to the unified feed
                // (events + tasks + holidays) on the calendar view.
                _sectionLabel('Show on calendar'),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final kind in CalendarFeedKind.values)
                      if (kind != CalendarFeedKind.unknown)
                        _chip(
                          label: _kindLabel(kind),
                          color: _kindColor(kind),
                          // Empty filter = everything shown.
                          selected: state.calendarKindFilter.isEmpty ||
                              state.calendarKindFilter.contains(kind),
                          onTap: () => cubit.toggleCalendarKindFilter(kind),
                        ),
                  ],
                ),
                const SizedBox(height: 14),
                _sectionLabel('Event Types'),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final type in EventType.values)
                      _chip(
                        label: type.label,
                        color: EventUiUtils.typeColor(type),
                        selected: state.typeFilter.contains(type),
                        onTap: () => cubit.toggleTypeFilter(type),
                      ),
                  ],
                ),
                if (state.classroomOptions.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _sectionLabel('Classrooms'),
                  _navRow(
                    icon: EventUiUtils.typeIcon(EventType.classroom),
                    color: EventUiUtils.typeColor(EventType.classroom),
                    label: 'Classrooms',
                    selectedCount: state.classroomFilter.length,
                    onTap: () => _open(_FilterStage.classrooms),
                  ),
                ],
                const SizedBox(height: 14),
                _sectionLabel('Date Range'),
                Row(
                  children: [
                    Expanded(
                      child: _dateField(
                        context: context,
                        label: 'From',
                        value: state.dateFrom,
                        onPicked: (date) => cubit.setDateRange(
                            from: date, to: state.dateTo),
                        onCleared: () => cubit.setDateRange(
                            from: null, to: state.dateTo),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _dateField(
                        context: context,
                        label: 'To',
                        value: state.dateTo,
                        onPicked: (date) => cubit.setDateRange(
                            from: state.dateFrom, to: date),
                        onCleared: () => cubit.setDateRange(
                            from: state.dateFrom, to: null),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _primaryButton(
            label: state.activeFilterCount > 0
                ? 'Apply (${state.activeFilterCount})'
                : 'Done',
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------ classroom stage

  Widget _classroomStage(
    BuildContext context,
    EventsState state,
    EventsCubit cubit,
  ) {
    return _CategoryFilterList(
      key: const ValueKey(_FilterStage.classrooms),
      title: 'Classrooms',
      options: [
        for (final classroom in state.classroomOptions)
          (code: classroom.code, name: classroom.name),
      ],
      selected: state.classroomFilter,
      accent: EventUiUtils.typeColor(EventType.classroom),
      onToggle: cubit.toggleClassroomFilter,
      onBack: _back,
    );
  }

  // --------------------------------------------------------------- shared

  Widget _grabber() => Center(
        child: Container(
          width: 38,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: Colors.black54,
        ),
      ),
    );
  }

  static String _kindLabel(CalendarFeedKind kind) {
    switch (kind) {
      case CalendarFeedKind.event:
        return 'Events';
      case CalendarFeedKind.task:
        return 'Tasks';
      case CalendarFeedKind.holiday:
        return 'Holidays';
      case CalendarFeedKind.unknown:
        return '';
    }
  }

  static Color _kindColor(CalendarFeedKind kind) {
    switch (kind) {
      case CalendarFeedKind.task:
        return TaskUiUtils.accent;
      case CalendarFeedKind.holiday:
        return const Color(0xFFD32F2F);
      case CalendarFeedKind.event:
      case CalendarFeedKind.unknown:
        return AppColors.themeColor;
    }
  }

  Widget _chip({
    required String label,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? color : color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }

  /// Forward-arrow row that drills into a second-stage list (mirrors the
  /// assignee picker used inside the event form).
  Widget _navRow({
    required IconData icon,
    required Color color,
    required String label,
    required int selectedCount,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  selectedCount == 0
                      ? 'Any ${label.toLowerCase()}'
                      : '$selectedCount selected',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color:
                        selectedCount == 0 ? Colors.grey[600] : Colors.black87,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[500]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateField({
    required BuildContext context,
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime> onPicked,
    required VoidCallback onCleared,
  }) {
    return Material(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () async {
          // Both fields open one range picker — from/to are set together.
          final cubit = context.read<EventsCubit>();
          final state = cubit.state;
          final range = await showDateRangePicker(
            context: context,
            initialDateRange: state.dateFrom != null && state.dateTo != null
                ? DateTimeRange(start: state.dateFrom!, end: state.dateTo!)
                : null,
            firstDate: DateTime(DateTime.now().year - 2),
            lastDate: DateTime(DateTime.now().year + 3),
          );
          if (range != null) {
            cubit.setDateRange(
              from: DateTime(
                range.start.year, range.start.month, range.start.day),
              to: DateTime(range.end.year, range.end.month, range.end.day),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 15, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  value == null
                      ? label
                      : DateFormat('MMM d, yyyy').format(value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: value == null ? Colors.grey[600] : Colors.black87,
                  ),
                ),
              ),
              if (value != null)
                GestureDetector(
                  onTap: onCleared,
                  child:
                      Icon(Icons.close, size: 15, color: Colors.grey[600]),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.buildPrimaryGradient(),
          borderRadius: BorderRadius.circular(10),
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: onTap,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// Lightweight (code, name) option used by the second-stage list.
typedef _FilterOption = ({String code, String name});

/// Second-stage searchable, scrollable multi-select list shown inside the
/// filter sheet. Selections toggle live through the cubit so the screen
/// behind updates as the user taps; "Done" returns to the root stage.
class _CategoryFilterList extends StatefulWidget {
  const _CategoryFilterList({
    required this.title,
    required this.options,
    required this.selected,
    required this.accent,
    required this.onToggle,
    required this.onBack,
    super.key,
  });

  final String title;
  final List<_FilterOption> options;
  final Set<String> selected;
  final Color accent;
  final ValueChanged<String> onToggle;
  final VoidCallback onBack;

  @override
  State<_CategoryFilterList> createState() => _CategoryFilterListState();
}

class _CategoryFilterListState extends State<_CategoryFilterList> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.options
        .where((o) =>
            _query.isEmpty ||
            o.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 20),
                color: AppColors.primaryColor,
                onPressed: widget.onBack,
              ),
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              if (widget.selected.isNotEmpty)
                Text(
                  '${widget.selected.length} selected',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Search ${widget.title.toLowerCase()}…',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
                prefixIcon: const Icon(Icons.search, size: 19),
                isDense: true,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No matches',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final option = filtered[index];
                      final checked = widget.selected.contains(option.code);
                      return CheckboxListTile(
                        dense: true,
                        value: checked,
                        activeColor: widget.accent,
                        controlAffinity: ListTileControlAffinity.trailing,
                        title: Text(
                          option.name.isNotEmpty ? option.name : option.code,
                          style: const TextStyle(fontSize: 13.5),
                        ),
                        onChanged: (_) => widget.onToggle(option.code),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.buildPrimaryGradient(),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: widget.onBack,
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
