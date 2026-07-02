import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/presentation/features/assessments/cubit/assessments_cubit.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_ui_utils.dart';

/// Bottom-sheet filter panel for the Students tab: a Status toggle (Active /
/// Inactive) and a Tags toggle built from whatever tags exist across the
/// loaded students (mirrors the Assignee filter in `task_filter_sheet.dart` —
/// options come from already-loaded data, no extra fetch). Both dimensions
/// are small and fixed/derived, so they stay inline chips rather than
/// drilling into a second stage.
Future<void> showAssessmentFilterSheet(BuildContext context) {
  final cubit = context.read<AssessmentsCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: const _AssessmentFilterSheet(),
    ),
  );
}

class _AssessmentFilterSheet extends StatelessWidget {
  const _AssessmentFilterSheet();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssessmentsCubit, AssessmentsState>(
      builder: (context, state) {
        final cubit = context.read<AssessmentsCubit>();
        final hasNonDefaultFilters = state.tagFilter.isNotEmpty ||
            !(state.statusFilter.length == 1 &&
                state.statusFilter.contains('ACTIVE'));
        return SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2DFEC),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AssessmentUi.ink,
                        ),
                      ),
                      if (hasNonDefaultFilters)
                        TextButton(
                          onPressed: cubit.clearAssessmentFilters,
                          child: const Text('Clear all',
                              style: TextStyle(fontSize: 12.5)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _sectionLabel('Status'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _chip(
                        label: 'Active',
                        selected: state.statusFilter.contains('ACTIVE'),
                        onTap: () => cubit.toggleStatusFilter('ACTIVE'),
                      ),
                      _chip(
                        label: 'Inactive',
                        selected: state.statusFilter.contains('INACTIVE'),
                        onTap: () => cubit.toggleStatusFilter('INACTIVE'),
                      ),
                    ],
                  ),
                  if (state.allTags.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _sectionLabel('Tags'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in state.allTags)
                          _chip(
                            label: tag,
                            selected: state.tagFilter.contains(tag),
                            onTap: () => cubit.toggleTagFilter(tag),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(14),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: AssessmentUi.accentGradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: Text(
                              'Done',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
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
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: AssessmentUi.inkMuted,
        ),
      ),
    );
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? AssessmentUi.brand : const Color(0xFFF1EFF8),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : const Color(0xFF574F66),
            ),
          ),
        ),
      ),
    );
  }
}
