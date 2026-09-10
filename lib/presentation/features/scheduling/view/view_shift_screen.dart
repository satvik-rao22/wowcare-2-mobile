import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:wowcare/core/responsive/responsive_scope.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/delete_confirmation_bottom_sheet.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/gradient_time_picker_field.dart';
import 'package:wowcare/presentation/features/scheduling/model/scheduling_responsive.dart';
import 'package:wowcare/presentation/features/scheduling/widgets/scheduling_bottom_sheet_scaffold.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';

/// Read-only view of a single shift. Mirrors the form layout of [AddShiftScreen]
/// so the fields look familiar, but every field is non-interactive. The bottom
/// bar shows Delete (cancel slot) and Edit (confirm slot) via
/// [CustomButtonLayout]; both open a bottom sheet for the user to choose
/// between acting on this shift only or the entire recurring series.
class ViewShiftScreen extends StatelessWidget {
  const ViewShiftScreen({
    super.key,
    required this.date,
    required this.staff,
    required this.classroom,
    required this.shiftStart,
    required this.shiftEnd,
    this.breakStart,
    this.breakEnd,
    this.note,
    this.status = ShiftStatus.published,
    this.isRecurring = false,
    this.onEditThis,
    this.onEditSeries,
    this.onDeleteThis,
    this.onDeleteSeries,
    this.readOnly = false,
  });

  static const String routeName = '/view-shift-screen';

  final DateTime date;
  final String staff;
  final String classroom;
  final TimeOfDay shiftStart;
  final TimeOfDay shiftEnd;
  final TimeOfDay? breakStart;
  final TimeOfDay? breakEnd;
  final String? note;
  final ShiftStatus status;
  final bool isRecurring;

  /// Per-occurrence and series-level callbacks. For non-recurring shifts only
  /// the "this" callbacks are used; the bottom sheet still appears as a
  /// confirmation but the second option is hidden.
  ///
  /// Each callback returns `true` when the underlying edit / delete succeeds.
  /// On success this screen pops itself (with `true`) so the source screen
  /// — staff scheduling or classroom scheduling — receives the mutation
  /// signal and refreshes, instead of leaving the user stranded on View.
  final Future<bool> Function()? onEditThis;
  final Future<bool> Function()? onEditSeries;
  final Future<bool> Function()? onDeleteThis;
  final Future<bool> Function()? onDeleteSeries;

  /// STAFF persona opens this screen to inspect their own shift but cannot
  /// mutate it — the bottom Edit/Delete bar is suppressed entirely.
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final responsive = SchedulingResponsive(context);
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final bottomPadding = safeBottom > 0 ? safeBottom : 16.0;

    return StaffFormLayout(
      title: 'View Shift',
      bottomBar: readOnly
          ? const SizedBox.shrink()
          : Container(
              padding: EdgeInsets.only(
                bottom: bottomPadding,
                left: 16,
                right: 16,
                top: 8,
              ),
              decoration: AppSurfaces.card(borderRadius: BorderRadius.only( topLeft: Radius.circular(responsive.isTablet ? 40.0 : 24.0), topRight: Radius.circular(responsive.isTablet ? 40.0 : 24.0), )),
              child: CustomButtonLayout(
                cancelButtonLabel: 'Delete',
                confirmButtonLabel: 'Edit',
                onPressedCancel: () => _confirmAction(
                  context,
                  actionLabel: 'Delete',
                  onThis: onDeleteThis,
                  onSeries: onDeleteSeries,
                ),
                onPressedConfirm: () => _confirmAction(
                  context,
                  actionLabel: 'Edit',
                  onThis: onEditThis,
                  onSeries: onEditSeries,
                ),
                isForm: false,
              ),
            ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildStatusHeader(responsive),
          SizedBox(height: responsive.verticalSpacing),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildDateField(
                  responsive,
                  label: 'Date',
                  date: date,
                ),
              ),
              SizedBox(width: responsive.isTablet ? 24.0 : 16.0),
              Expanded(
                child: _buildReadOnlyDropdown(
                  responsive,
                  label: 'Staff',
                  value: staff,
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.verticalSpacing),
          _buildReadOnlyDropdown(
            responsive,
            label: 'Classroom',
            value: classroom,
          ),
          SizedBox(height: responsive.verticalSpacing),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTimeField(
                  label: 'Shift Start',
                  time: shiftStart,
                  isRequired: true,
                ),
              ),
              SizedBox(width: responsive.isTablet ? 24.0 : 16.0),
              Expanded(
                child: _buildTimeField(
                  label: 'Shift End',
                  time: shiftEnd,
                  isRequired: true,
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.verticalSpacing),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTimeField(
                  label: 'Break Start',
                  time: breakStart,
                ),
              ),
              SizedBox(width: responsive.isTablet ? 24.0 : 16.0),
              Expanded(
                child: _buildTimeField(
                  label: 'Break End',
                  time: breakEnd,
                ),
              ),
            ],
          ),
          if (note != null && note!.trim().isNotEmpty) ...[
            SizedBox(height: responsive.verticalSpacing),
            _buildNote(responsive),
          ],
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(SchedulingResponsive responsive) {
    final formatted = DateFormat('MMM d, yyyy').format(date);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.isTablet ? 8.0 : 4.0,
      ),
      child: Text(
        'Shift on $formatted (${status.label})',
        style: TextStyle(
          fontSize: responsive.titleFontSize * 0.85,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }

  Widget _buildDateField(
    SchedulingResponsive responsive, {
    required String label,
    required DateTime date,
  }) {
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
            children: [
              TextSpan(text: label),
              const TextSpan(text: ' *', style: TextStyle(color: MaterialHues.red)),
            ],
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        IgnorePointer(
          child: CustomDateTimeField(
            hasLabel: false,
            fetchInitialTime: false,
            initialDate: date,
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyDropdown(
    SchedulingResponsive responsive, {
    required String label,
    required String value,
  }) {
    return IgnorePointer(
      child: CustomDropdown(
        label: label,
        hintText: 'Select',
        items: <String>[value],
        selectedItem: value,
        labelStyle: TextStyle(
          fontSize: responsive.labelFontSize,
          fontWeight: FontWeight.w400,
          color: AppColors.primaryColor,
        ),
        showAsterisk: true,
        labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
        onSelect: (_) {},
      ),
    );
  }

  Widget _buildTimeField({
    required String label,
    required TimeOfDay? time,
    bool isRequired = false,
  }) {
    return IgnorePointer(
      child: GradientTimePickerField(
        label: label,
        isRequired: isRequired,
        time: time,
        onTimeSelected: (_) {},
      ),
    );
  }

  Widget _buildNote(SchedulingResponsive responsive) {
    final labelStyle = TextStyle(
      fontSize: responsive.labelFontSize,
      fontWeight: FontWeight.w400,
      color: AppColors.primaryColor,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Note', style: labelStyle),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(responsive.isTablet ? 16.0 : 12.0),
          decoration: AppSurfaces.well(radius: responsive.isTablet ? 12.0 : 8.0,),
          child: Text(
            note!,
            style: TextStyle(
              fontSize: responsive.inputFontSize,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
              height: 19 / 14,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmAction(
    BuildContext context, {
    required String actionLabel,
    required Future<bool> Function()? onThis,
    required Future<bool> Function()? onSeries,
  }) async {
    final isDelete = actionLabel == 'Delete';
    final lower = actionLabel.toLowerCase();
    // Always offer the scope choice — backend models every shift as part of
    // a series (even single-occurrence ones), so the user should be able to
    // pick "this shift" vs "entire series" on every edit / delete.
    final scope = await showModalBottomSheet<_SeriesScope>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ShiftScopeBottomSheet(
        title: '$actionLabel shift',
        subtitle: 'Choose what to $lower.',
        options: [
          _SeriesOption(
            scope: _SeriesScope.thisShift,
            label: '$actionLabel this shift',
            description:
                'Only the occurrence on this day will be ${lower}d.',
          ),
          _SeriesOption(
            scope: _SeriesScope.entireSeries,
            label: '$actionLabel entire series',
            description:
                'Every occurrence in the recurring series will be ${lower}d.',
          ),
        ],
      ),
    );
    if (scope == null) return;

    final chosen = scope;
    final onAction = chosen == _SeriesScope.thisShift ? onThis : onSeries;

    if (!isDelete) {
      final succeeded = await onAction?.call() ?? false;
      if (!context.mounted) return;
      if (succeeded) {
        Navigator.of(context).pop(true);
      }
      return;
    }

    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => DeleteConfirmationBottomSheet(
        name: '',
        type: chosen == _SeriesScope.thisShift ? 'shift' : 'shift_series',
        onCancel: () => Navigator.of(sheetCtx).pop(),
        onDelete: () async {
          Navigator.of(sheetCtx).pop();
          final succeeded = await onAction?.call() ?? false;
          if (!context.mounted) return;
          if (succeeded) {
            Navigator.of(context).pop(true);
          }
        },
      ),
    );
  }
}

enum _SeriesScope { thisShift, entireSeries }

class _SeriesOption {
  const _SeriesOption({
    required this.scope,
    required this.label,
    required this.description,
  });

  final _SeriesScope scope;
  final String label;
  final String description;
}

/// Radio-style chooser for the "this shift" vs "entire series" decision.
/// Tapping a tile immediately pops the sheet with that [_SeriesScope]; there
/// are no Cancel / Confirm buttons. Backdrop tap or back-gesture pops `null`.
class _ShiftScopeBottomSheet extends StatelessWidget {
  const _ShiftScopeBottomSheet({
    required this.title,
    required this.subtitle,
    required this.options,
  });

  final String title;
  final String subtitle;
  final List<_SeriesOption> options;

  @override
  Widget build(BuildContext context) {
    return SchedulingBottomSheetScaffold(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: SchedulingBottomSheetScaffold.titleFontSize(context),
            fontWeight: FontWeight.w700,
            color: AppColors.primaryColor,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppPalette.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: context.isTablet ? 24.0 : 16.0),
        for (final option in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ScopeRadioTile(
              option: option,
              onTap: () => Navigator.of(context).pop(option.scope),
            ),
          ),
      ],
    );
  }
}

class _ScopeRadioTile extends StatelessWidget {
  const _ScopeRadioTile({
    required this.option,
    required this.onTap,
  });

  final _SeriesOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: AppSurfaces.well(radius: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: _RadioDot(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.description,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppPalette.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: AppColors.primaryColor.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadioDot extends StatelessWidget {
  const _RadioDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.themeColor,
          width: 2,
        ),
      ),
    );
  }
}

enum ShiftStatus {
  draft('Draft'),
  published('Published');

  const ShiftStatus(this.label);
  final String label;
}

