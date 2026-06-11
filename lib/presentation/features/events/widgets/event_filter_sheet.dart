import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/domain/features/events/entities/event.dart';
import 'package:wowcare/presentation/features/events/cubit/events_cubit.dart';
import 'package:wowcare/presentation/features/events/utils/event_ui_utils.dart';

/// Bottom-drawer filter panel (mobile counterpart of the web design's
/// filter dropdowns): event types, classrooms and a date range. Changes
/// apply live through [EventsCubit] so the screen behind updates as the
/// user taps.
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

class _EventFilterSheet extends StatelessWidget {
  const _EventFilterSheet();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EventsCubit, EventsState>(
      builder: (context, state) {
        final cubit = context.read<EventsCubit>();
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                        child: const Text(
                          'Clear all',
                          style: TextStyle(fontSize: 12.5),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
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
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final classroom in state.classroomOptions)
                        _chip(
                          label: classroom.name,
                          color:
                              EventUiUtils.typeColor(EventType.classroom),
                          selected: state.classroomFilter
                              .contains(classroom.code),
                          onTap: () =>
                              cubit.toggleClassroomFilter(classroom.code),
                        ),
                    ],
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
                          from: date,
                          to: state.dateTo,
                        ),
                        onCleared: () =>
                            cubit.setDateRange(from: null, to: state.dateTo),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _dateField(
                        context: context,
                        label: 'To',
                        value: state.dateTo,
                        onPicked: (date) => cubit.setDateRange(
                          from: state.dateFrom,
                          to: date,
                        ),
                        onCleared: () => cubit.setDateRange(
                            from: state.dateFrom, to: null),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
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
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        state.activeFilterCount > 0
                            ? 'Apply (${state.activeFilterCount})'
                            : 'Done',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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
          final picked = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now(),
            firstDate: DateTime(DateTime.now().year - 2),
            lastDate: DateTime(DateTime.now().year + 3),
          );
          if (picked != null) {
            onPicked(DateTime(picked.year, picked.month, picked.day));
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
}
