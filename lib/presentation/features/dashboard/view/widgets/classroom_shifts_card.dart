import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/classroom_shifts_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_card_toggle.dart';
import 'package:wowcare/presentation/features/scheduling/utils/scheduling_block_status_style.dart';
import 'package:wowcare/presentation/features/scheduling/model/scheduling_models.dart';

/// Dashboard card listing each classroom's ratio status for the selected day.
///
/// Status is driven exclusively by [ClassroomShiftEntry.blockStatus] from the
/// forecast API — no frontend ratio calculations.
class ClassroomShiftsCard extends StatefulWidget {
  const ClassroomShiftsCard({super.key});

  @override
  State<ClassroomShiftsCard> createState() => _ClassroomShiftsCardState();
}

class _ClassroomShiftsCardState extends State<ClassroomShiftsCard> {
  static const int _initialDisplayCount = 7;

  DateTime _selectedDate = DateTime.now();
  bool _showAllClassrooms = false;
  bool _minimized = false;

  double get _bodyFontSize =>
      MediaQuery.of(context).size.width > 600 ? 16 : 14;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(context.read<ClassroomShiftsCubit>().load(_selectedDate));
      }
    });
  }

  void _changeDate(int days) {
    final newDate = _selectedDate.add(Duration(days: days));
    setState(() => _selectedDate = newDate);
    unawaited(context.read<ClassroomShiftsCubit>().load(newDate));
  }

  Widget _buildDateNavigator() {
    final formattedDate = DateFormat('EEE, MMM d').format(_selectedDate);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _changeDate(-1),
            borderRadius: BorderRadius.circular(100),
            splashColor: AppColors.primaryColor.withValues(alpha: 0.1),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.arrow_back_ios_new,
                size: 18,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ),
        const SizedBox(width: 2),
        Text(
          formattedDate,
          style: TextStyle(
            color: AppColors.primaryColor,
            fontSize: _bodyFontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _changeDate(1),
            borderRadius: BorderRadius.circular(100),
            splashColor: AppColors.primaryColor.withValues(alpha: 0.1),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClassroomShiftsCubit, ClassroomShiftsState>(
      builder: (context, state) {
        final entries = state.entries;
        final displayEntries = _showAllClassrooms
            ? entries
            : entries.take(_initialDisplayCount).toList();
        final hasMoreToShow = entries.length > _initialDisplayCount;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.cardBorderColor),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Classroom Shifts',
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  DashboardCardToggle(
                    minimized: _minimized,
                    onTap: () => setState(() => _minimized = !_minimized),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Legend ────────────────────────────────────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: _minimized
                    ? const SizedBox.shrink()
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _legendItem(
                            ClassroomRatioStatus.underRatio,
                            'Not In Ratio',
                          ),
                          const SizedBox(width: 16),
                          _legendItem(
                            ClassroomRatioStatus.inRatio,
                            'In Ratio',
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),

              // ── Table ─────────────────────────────────────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: _minimized
                    ? const SizedBox.shrink()
                    : Column(
                        children: [
                          Table(
                            border: TableBorder(
                              horizontalInside: BorderSide(
                                color: Colors.grey[300]!,
                                width: 1.0,
                              ),
                            ),
                            columnWidths: const {
                              0: FlexColumnWidth(1),
                              1: FlexColumnWidth(1),
                            },
                            children: [
                              TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    child: Text(
                                      'Classroom',
                                      style: TextStyle(
                                        fontSize: _bodyFontSize,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primaryColor,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [_buildDateNavigator()],
                                    ),
                                  ),
                                ],
                              ),
                              if (state.isLoading)
                                ..._buildShimmerRows()
                              else
                                ...displayEntries.map(_buildTableRow),
                            ],
                          ),
                          if (state.isError)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                state.errorMessage ?? 'Failed to load data.',
                                style: const TextStyle(
                                    color: AppColors.errorColor),
                              ),
                            ),
                          if (!state.isLoading && hasMoreToShow)
                            InkWell(
                              onTap: () => setState(
                                  () => _showAllClassrooms = !_showAllClassrooms),
                              child: Container(
                                width: double.infinity,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor
                                      .withValues(alpha: 0.03),
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _showAllClassrooms
                                          ? 'Show Less'
                                          : 'Show More',
                                      style: const TextStyle(
                                        color: AppColors.primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      _showAllClassrooms
                                          ? Icons.keyboard_arrow_up
                                          : Icons.keyboard_arrow_down,
                                      color: AppColors.primaryColor,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  TableRow _buildTableRow(ClassroomShiftEntry entry) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 15.0),
          child: Text(
            entry.name,
            style: const TextStyle(
              fontSize: 18.0,
              color: AppColors.primaryColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 15.0),
          child: Center(
            child: SchedulingBlockStatusStyle.weekViewIconForClassroomStatus(
              entry.ratioStatus,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  List<TableRow> _buildShimmerRows() {
    return List.generate(
      5,
      (_) => TableRow(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15.0),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 16,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15.0),
            child: Center(
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  height: 20,
                  width: 20,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(ClassroomRatioStatus status, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SchedulingBlockStatusStyle.weekViewIconForClassroomStatus(status, size: 16),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: _bodyFontSize)),
      ],
    );
  }
}
