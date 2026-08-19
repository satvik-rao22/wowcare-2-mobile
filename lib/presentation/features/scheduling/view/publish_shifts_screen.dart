import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/staff/entities/staff_member.dart';
import 'package:wowcare/presentation/features/scheduling/cubit/publish_shifts_cubit.dart';
import 'package:wowcare/presentation/features/scheduling/utils/scheduling_school_time.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

enum PublishMode { untilDate, all }

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
/// then choose "Publish Until Date" or "Publish All". Submits to
/// `POST /api/v1/staff-shifts/publish` via [PublishShiftsCubit] and pops with
/// a [PublishShiftsResult] on success so the caller can refresh.
class PublishShiftsScreen extends StatelessWidget {
  const PublishShiftsScreen({
    super.key,
    required this.dateRangeStart,
    this.staff = const <StaffMember>[],
    this.initialUntilDate,
    this.initialStaffCodes = const <String>[],
  });

  static const String routeName = '/publish-shifts-screen';

  /// Roster of staff members to populate the multi-select dropdown.
  final List<StaffMember> staff;

  /// The day the publish range starts from (sent as `dateRangeStart`).
  /// Typically the day the caller has selected in the scheduling view.
  final DateTime dateRangeStart;

  final DateTime? initialUntilDate;
  final List<String> initialStaffCodes;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PublishShiftsCubit>(
      create: (_) => serviceLocator<PublishShiftsCubit>(),
      child: _PublishShiftsView(
        staff: staff,
        dateRangeStart: dateRangeStart,
        initialUntilDate: initialUntilDate,
        initialStaffCodes: initialStaffCodes,
      ),
    );
  }
}

class _PublishShiftsView extends StatefulWidget {
  const _PublishShiftsView({
    required this.staff,
    required this.dateRangeStart,
    required this.initialUntilDate,
    required this.initialStaffCodes,
  });

  final List<StaffMember> staff;
  final DateTime dateRangeStart;
  final DateTime? initialUntilDate;
  final List<String> initialStaffCodes;

  @override
  State<_PublishShiftsView> createState() => _PublishShiftsViewState();
}

class _PublishShiftsViewState extends State<_PublishShiftsView> {
  late List<String> _selectedStaffNames;
  PublishMode? _mode;
  DateTime? _untilDate;

  /// Display-name → staff code, built once from [widget.staff]. The
  /// multi-select dropdown only deals in display strings, so we map back to
  /// codes at submit time.
  late Map<String, String> _codeByName;

  @override
  void initState() {
    super.initState();
    _codeByName = _buildCodeByName(widget.staff);
    _selectedStaffNames = _namesFromCodes(widget.initialStaffCodes);
    _untilDate = widget.initialUntilDate;
    // ignore: discarded_futures
    bootstrapSchedulingSchoolTimezone();
  }

  @override
  void didUpdateWidget(covariant _PublishShiftsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.staff, oldWidget.staff)) {
      _codeByName = _buildCodeByName(widget.staff);
      // Drop any selections that no longer correspond to a known staff member.
      _selectedStaffNames = _selectedStaffNames
          .where(_codeByName.containsKey)
          .toList(growable: true);
    }
  }

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

  List<String> get _staffNames =>
      _codeByName.keys.toList(growable: false);

  // Publish stays disabled until at least one staff is picked, a mode is
  // chosen, and (for "Until Date") a date is set.
  bool get _isFormValid {
    if (_selectedStaffNames.isEmpty) return false;
    if (_mode == null) return false;
    if (_mode == PublishMode.untilDate && _untilDate == null) return false;
    return true;
  }

  Future<void> _onPublish() async {
    if (!_isFormValid) return;
    final mode = _mode!;
    final cubit = context.read<PublishShiftsCubit>();

    final selectedCodes = <String>[
      for (final name in _selectedStaffNames)
        if (_codeByName[name] != null) _codeByName[name]!,
    ];
    if (selectedCodes.isEmpty) return;

    final isAllStaff = _staffNames.isNotEmpty &&
        selectedCodes.length == _staffNames.length;

    await cubit.publish(
      dateRangeStart: widget.dateRangeStart,
      publishAll: mode == PublishMode.all,
      publishAllStaff: isAllStaff,
      publishUntilDate: mode == PublishMode.untilDate ? _untilDate : null,
      selectedStaffCodes: isAllStaff ? const <String>[] : selectedCodes,
    );

    if (!mounted) return;
    final state = cubit.state;
    if (state.status == PublishShiftsStatus.success) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: mode == PublishMode.all
            ? 'Shifts published.'
            : 'Shifts published until ${_formatDisplayDate(_untilDate!)}.',
        isSuccess: true,
      );
      Navigator.of(context).pop(
        PublishShiftsResult(
          mode: mode,
          staffCodes: selectedCodes,
          untilDate: mode == PublishMode.untilDate ? _untilDate : null,
        ),
      );
    } else if (state.errorMessage != null) {
      // logApiError both writes to AppLogger and surfaces the message in
      // CoreUtils' top error banner (isError variant), keeping success/error
      // visuals consistent.
      CoreUtils.logApiError(
        state.errorMessage!,
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
    final responsive = ResponsiveHelper(context);
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final bottomPadding = safeBottom > 0 ? safeBottom : 16.0;

    return BlocListener<PublishShiftsCubit, PublishShiftsState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (_, __) {},
      child: BlocBuilder<PublishShiftsCubit, PublishShiftsState>(
        buildWhen: (prev, curr) => prev.isSubmitting != curr.isSubmitting,
        builder: (context, state) {
          final isSubmitting = state.isSubmitting;

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
                onPressedConfirm:
                    (_isFormValid && !isSubmitting) ? _onPublish : null,
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
                  _buildStaffMultiSelect(responsive),
                  SizedBox(height: responsive.verticalSpacing),
                  _PublishOptionRow(
                    label: 'Publish Until Date',
                    selected: _mode == PublishMode.untilDate,
                    onTap: () =>
                        setState(() => _mode = PublishMode.untilDate),
                  ),
                  if (_mode == PublishMode.untilDate) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: EdgeInsets.only(
                        left: responsive.isTablet ? 36 : 32,
                      ),
                      child: _buildUntilDateField(responsive),
                    ),
                  ],
                  SizedBox(height: responsive.verticalSpacing),
                  _PublishOptionRow(
                    label: 'Publish All',
                    selected: _mode == PublishMode.all,
                    onTap: () => setState(() => _mode = PublishMode.all),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStaffMultiSelect(ResponsiveHelper responsive) {
    return CustomMultiSelectDropdown(
      label: 'Staff',
      hintText: 'Select',
      items: _staffNames,
      selectedItems: _selectedStaffNames,
      onChanged: (next) {
        setState(() {
          _selectedStaffNames = List<String>.from(next);
        });
      },
    );
  }

  Widget _buildUntilDateField(ResponsiveHelper responsive) {
    final labelStyle = TextStyle(
      fontSize: responsive.labelFontSize,
      fontFamily: 'Manrope',
      fontWeight: FontWeight.w400,
      color: const Color(0xFF0A1C5D),
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
            'publish-until-${_untilDate?.toIso8601String() ?? 'empty'}',
          ),
          hasLabel: false,
          fetchInitialTime: false,
          initialDate: _untilDate,
          onDateSelected: (d) => setState(() => _untilDate = d),
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
                fontFamily: 'Manrope',
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
