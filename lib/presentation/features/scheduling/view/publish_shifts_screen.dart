import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/domain/features/staff/entities/staff_member.dart';
import 'package:wowcare/presentation/features/scheduling/view_model/publish_shifts_cubit.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/presentation/features/scheduling/model/scheduling_responsive.dart';

/// Result returned by [PublishShiftsScreen] on success. The screen also pops
/// with `true` if the caller only cares about "did we publish?". Kept for
/// callers that want to know what was published so they can refresh the
/// minimal slice of data.
class PublishShiftsResult {
  const PublishShiftsResult({
    required this.mode,
    required this.staffCodes,
    this.untilDate,
  });

  final PublishMode mode;
  final List<String> staffCodes;
  final DateTime? untilDate;
}

/// PRD §7 — Publish Shifts. Full-page form: pick a multi-select staff list,
/// then choose "Publish Until Date" or "Publish All". All form state
/// (mode, staff selection, until-date) lives in [PublishShiftsCubit]; this
/// widget is a pure view over that state, matching [AddShiftScreen] /
/// [EditShiftScreen] in the same feature. Submits to
/// `POST /api/v1/staff-shifts/publish` and pops with a [PublishShiftsResult]
/// on success so the caller can refresh.
///
/// The Staff multi-select deliberately opens EMPTY — publishing is a bulk,
/// hard-to-undo action, so who it applies to is always an explicit choice by
/// the user rather than something inherited from whatever row the scheduling
/// screen happened to have selected.
class PublishShiftsScreen extends StatelessWidget {
  const PublishShiftsScreen({
    super.key,
    required this.dateRangeStart,
    this.staff = const <StaffMember>[],
    this.initialUntilDate,
  });

  static const String routeName = '/publish-shifts-screen';

  /// Roster of staff members to populate the multi-select dropdown.
  final List<StaffMember> staff;

  /// The day the publish range starts from (sent as `dateRangeStart`).
  /// Typically the day the caller has selected in the scheduling view.
  final DateTime dateRangeStart;

  final DateTime? initialUntilDate;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PublishShiftsCubit>(
      create: (_) => serviceLocator<PublishShiftsCubit>()
        ..init(initialUntilDate: initialUntilDate),
      child: _PublishShiftsView(
        staff: staff,
        dateRangeStart: dateRangeStart,
      ),
    );
  }
}

class _PublishShiftsView extends StatefulWidget {
  const _PublishShiftsView({
    required this.staff,
    required this.dateRangeStart,
  });

  final List<StaffMember> staff;
  final DateTime dateRangeStart;

  @override
  State<_PublishShiftsView> createState() => _PublishShiftsViewState();
}

class _PublishShiftsViewState extends State<_PublishShiftsView> {
  /// Display-name → staff code, built once from [widget.staff]. The
  /// multi-select dropdown only deals in display strings; the cubit only
  /// deals in codes, so this widget translates at the boundary.
  late final Map<String, String> _codeByName = _buildCodeByName(widget.staff);

  static Map<String, String> _buildCodeByName(List<StaffMember> staff) {
    final map = <String, String>{};
    for (final s in staff) {
      final name = s.name.trim();
      final code = s.code.trim();
      if (name.isEmpty || code.isEmpty) continue;
      map[name] = code;
    }
    return map;
  }

  List<String> _namesFromCodes(List<String> codes) {
    if (codes.isEmpty) return <String>[];
    final wanted = codes.map((c) => c.trim()).toSet();
    return _codeByName.entries
        .where((e) => wanted.contains(e.value))
        .map((e) => e.key)
        .toList(growable: true);
  }

  List<String> _codesFromNames(List<String> names) => [
        for (final name in names)
          if (_codeByName[name] != null) _codeByName[name]!,
      ];

  List<String> get _staffNames => _codeByName.keys.toList(growable: false);

  Future<void> _onPublish(PublishShiftsState formState) async {
    if (!formState.isFormValid) return;
    final mode = formState.mode!;
    final cubit = context.read<PublishShiftsCubit>();

    await cubit.publish(
      dateRangeStart: widget.dateRangeStart,
      totalEligibleStaffCount: _staffNames.length,
    );

    if (!mounted) return;
    final result = cubit.state;
    if (result.status == PublishShiftsStatus.success) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: mode == PublishMode.all
            ? 'Shifts published.'
            : 'Shifts published until ${_formatDisplayDate(formState.untilDate!)}.',
        isSuccess: true,
      );
      Navigator.of(context).pop(
        PublishShiftsResult(
          mode: mode,
          staffCodes: formState.selectedStaffCodes,
          untilDate: mode == PublishMode.untilDate ? formState.untilDate : null,
        ),
      );
    } else if (result.errorMessage != null) {
      // logApiError both writes to AppLogger and surfaces the message in
      // CoreUtils' top error banner (isError variant), keeping success/error
      // visuals consistent.
      CoreUtils.logApiError(
        result.errorMessage!,
        showOnScreen: true,
        context: context,
      );
    }
  }

  static String _formatDisplayDate(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  @override
  Widget build(BuildContext context) {
    final responsive = SchedulingResponsive(context);
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final bottomPadding = safeBottom > 0 ? safeBottom : 16.0;

    return BlocBuilder<PublishShiftsCubit, PublishShiftsState>(
      builder: (context, state) {
        final isSubmitting = state.isSubmitting;
        final selectedNames = _namesFromCodes(state.selectedStaffCodes);

        return StaffFormLayout(
          title: 'Publish Shifts',
          bottomBar: Container(
            padding: EdgeInsets.only(
              bottom: bottomPadding,
              left: 16,
              right: 16,
              top: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, -4),
                  blurRadius: 16,
                ),
              ],
              borderRadius: BorderRadius.only(
                topLeft:
                    Radius.circular(responsive.isTablet ? 40.0 : 24.0),
                topRight:
                    Radius.circular(responsive.isTablet ? 40.0 : 24.0),
              ),
            ),
            child: CustomButtonLayout(
              confirmButtonLabel: isSubmitting ? 'Publishing…' : 'Publish',
              onPressedConfirm: (state.isFormValid && !isSubmitting)
                  ? () => _onPublish(state)
                  : null,
              onPressedCancel: isSubmitting
                  ? null
                  : () => Navigator.of(context).pop(),
              cancelButtonLabel: 'Cancel',
              showCancelButton: true,
              isForm: false,
            ),
          ),
          child: AbsorbPointer(
            absorbing: isSubmitting,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildStaffMultiSelect(responsive, selectedNames),
                SizedBox(height: responsive.verticalSpacing),
                _PublishOptionRow(
                  label: 'Publish Until Date',
                  selected: state.mode == PublishMode.untilDate,
                  onTap: () => context
                      .read<PublishShiftsCubit>()
                      .selectMode(PublishMode.untilDate),
                ),
                if (state.mode == PublishMode.untilDate) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: EdgeInsets.only(
                      left: responsive.isTablet ? 36 : 32,
                    ),
                    child: _buildUntilDateField(responsive, state.untilDate),
                  ),
                ],
                SizedBox(height: responsive.verticalSpacing),
                _PublishOptionRow(
                  label: 'Publish All',
                  selected: state.mode == PublishMode.all,
                  onTap: () => context
                      .read<PublishShiftsCubit>()
                      .selectMode(PublishMode.all),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStaffMultiSelect(
    SchedulingResponsive responsive,
    List<String> selectedNames,
  ) {
    return CustomMultiSelectDropdown(
      label: 'Staff',
      hintText: 'Select',
      items: _staffNames,
      selectedItems: selectedNames,
      onChanged: (next) {
        context.read<PublishShiftsCubit>().setSelectedStaffCodes(
              _codesFromNames(List<String>.from(next)),
            );
      },
    );
  }

  Widget _buildUntilDateField(SchedulingResponsive responsive, DateTime? untilDate) {
    final labelStyle = TextStyle(
      fontSize: responsive.labelFontSize,
      fontWeight: FontWeight.w400,
      color: AppColors.primaryColor,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: labelStyle,
            children: const [
              TextSpan(text: 'Until Date'),
              TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        CustomDateTimeField(
          key: ValueKey(
            'publish-until-${untilDate?.toIso8601String() ?? 'empty'}',
          ),
          hasLabel: false,
          fetchInitialTime: false,
          initialDate: untilDate,
          onDateSelected: (d) =>
              context.read<PublishShiftsCubit>().setUntilDate(d),
        ),
      ],
    );
  }
}

class _PublishOptionRow extends StatelessWidget {
  const _PublishOptionRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        children: [
          _RadioDot(selected: selected),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Same visual language as the radio dot in [view_shift_screen.dart], with a
/// selected state added so we can toggle between the two publish options.
class _RadioDot extends StatelessWidget {
  const _RadioDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected
              ? AppColors.themeColor
              : AppColors.primaryColor.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: selected
          ? Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.themeColor,
              ),
            )
          : null,
    );
  }
}
