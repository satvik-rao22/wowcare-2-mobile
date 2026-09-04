import 'dart:async' show unawaited;

import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/select_option.dart';
import 'package:wowcare/redesign/core/widgets/single_select_sheet.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/staff/models/models.dart';
import 'package:wowcare/redesign/features/staff/staff_sizes.dart';
import 'package:wowcare/redesign/features/staff/staff_strings.dart';
import 'package:wowcare/redesign/features/staff/staff_text_styles.dart';

/// The working week, a row a day: work start, work end, then the lunch break
/// start (6d step three, and the whole of the schedule screen).
///
/// Times are picked from a sheet in quarter hours rather than typed. The
/// existing screen uses a spinner; a sheet is the app's own control and keeps
/// a shift on the same 15-minute grid the schedules API stores.
class ShiftEditorCard extends StatelessWidget {
  const ShiftEditorCard({
    required this.week,
    required this.onChanged,
    required this.onCopyToAllDays,
    this.errorText,
    super.key,
  });

  final List<StaffShift> week;
  final ValueChanged<StaffShift> onChanged;
  final ValueChanged<int> onCopyToAllDays;

  /// The one thing that can be wrong with a week.
  final String? errorText;

  /// A quarter-hour grid from six in the morning to seven at night, which is
  /// every hour a center is open.
  static const int _firstSlot = 6 * 60;
  static const int _lastSlot = 19 * 60;
  static const int _step = 15;

  /// What a picker returns for "this day is off" or "no break".
  static const int _none = -1;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: StaffSizes.shiftCardGap,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  StaffStrings.shiftAndBreak,
                  style: AppTextStyles.cardTitle.copyWith(color: c.ink),
                ),
              ),
              _CopyKey(
                onTap: week.isEmpty
                    ? null
                    : () => onCopyToAllDays(week.first.weekday),
              ),
            ],
          ),
          for (final shift in week) _ShiftRow(shift: shift, card: this),
          Text(
            StaffStrings.shiftHint,
            style: StaffTextStyles.sheetNote.copyWith(color: c.ink3),
          ),
          if (errorText != null)
            Text(
              errorText!,
              style: AppTextStyles.fieldError.copyWith(color: c.dangerFg),
            ),
        ],
      ),
    );
  }

  Future<void> _pickStart(BuildContext context, StaffShift shift) async {
    final picked = await _pick(
      context,
      title: StaffStrings.workStart,
      selected: shift.startMinutes,
      noneLabel: StaffStrings.markDayOff,
    );
    if (picked == null) return;
    onChanged(
      picked == _none
          ? shift.copyWith(clearStart: true, clearEnd: true, clearBreak: true)
          : shift.copyWith(startMinutes: picked),
    );
  }

  Future<void> _pickEnd(BuildContext context, StaffShift shift) async {
    final picked = await _pick(
      context,
      title: StaffStrings.workEnd,
      selected: shift.endMinutes,
      noneLabel: StaffStrings.markDayOff,
    );
    if (picked == null) return;
    onChanged(
      picked == _none
          ? shift.copyWith(clearStart: true, clearEnd: true, clearBreak: true)
          : shift.copyWith(endMinutes: picked),
    );
  }

  Future<void> _pickBreak(BuildContext context, StaffShift shift) async {
    final picked = await _pick(
      context,
      title: StaffStrings.breakStart,
      selected: shift.breakStartMinutes,
      noneLabel: StaffStrings.noBreakOption,
    );
    if (picked == null) return;
    onChanged(
      picked == _none
          ? shift.copyWith(clearBreak: true)
          : shift.copyWith(
              breakStartMinutes: picked,
              breakEndMinutes: picked + _breakLength,
            ),
    );
  }

  /// Half an hour, which is what every break in the demo world and in the
  /// frames is. The end is derived so a break can never invert.
  static const int _breakLength = 30;

  static Future<int?> _pick(
    BuildContext context, {
    required String title,
    required int? selected,
    required String noneLabel,
  }) => SingleSelectSheet.show<int>(
    context,
    title: title,
    selected: selected,
    options: <SelectOption<int>>[
      SelectOption<int>(value: _none, label: noneLabel),
      for (var minutes = _firstSlot; minutes <= _lastSlot; minutes += _step)
        SelectOption<int>(value: minutes, label: StaffStrings.clock(minutes)),
    ],
  );
}

/// One day: the label, then the three wells.
class _ShiftRow extends StatelessWidget {
  const _ShiftRow({required this.shift, required this.card});

  final StaffShift shift;
  final ShiftEditorCard card;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final isOff = shift.isDayOff;

    return Row(
      spacing: StaffSizes.shiftRowGap,
      children: <Widget>[
        SizedBox(
          width: StaffSizes.shiftDayWidth,
          child: Text(
            StaffStrings.weekday(shift.weekday),
            style: StaffTextStyles.shiftDay.copyWith(
              color: isOff ? c.ink3 : c.ink,
            ),
          ),
        ),
        Expanded(
          child: _TimeWell(
            label: isOff
                ? StaffStrings.off
                : StaffStrings.clock(shift.startMinutes!),
            isQuiet: isOff,
            onTap: () => unawaited(card._pickStart(context, shift)),
          ),
        ),
        Expanded(
          child: _TimeWell(
            label: isOff
                ? StaffStrings.off
                : StaffStrings.clock(shift.endMinutes!),
            isQuiet: isOff,
            onTap: () => unawaited(card._pickEnd(context, shift)),
          ),
        ),
        Expanded(
          child: _TimeWell(
            label: shift.hasBreak
                ? StaffStrings.clock(shift.breakStartMinutes!)
                : StaffStrings.dash,
            isQuiet: isOff || !shift.hasBreak,
            onTap: isOff
                ? null
                : () => unawaited(card._pickBreak(context, shift)),
          ),
        ),
      ],
    );
  }
}

class _TimeWell extends StatelessWidget {
  const _TimeWell({
    required this.label,
    required this.isQuiet,
    required this.onTap,
  });

  final String label;
  final bool isQuiet;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    final well = SurfaceBox(
      surface: AppSurfaces.well(c),
      padding: StaffSizes.shiftWellPad,
      alignment: Alignment.center,
      child: Text(
        label,
        style: StaffTextStyles.shiftTime.copyWith(
          color: isQuiet ? c.ink3 : c.ink,
        ),
      ),
    );

    return Semantics(
      button: onTap != null,
      label: label,
      child: onTap == null
          ? well
          : Pressable.surface(onTap: onTap, child: well),
    );
  }
}

/// "Copy to all days": the sun-tinted key on the card's heading row.
class _CopyKey extends StatelessWidget {
  const _CopyKey({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    final key = SurfaceBox(
      surface: AppSurfaces.tile(c, fill: c.staffBg, line: c.staffLine),
      padding: StaffSizes.smallKeyPad,
      child: Text(
        StaffStrings.copyToAllDays,
        style: StaffTextStyles.smallKey.copyWith(color: c.staffFg),
      ),
    );

    return Semantics(
      button: onTap != null,
      label: StaffStrings.copyToAllDays,
      child: onTap == null ? key : Pressable.surface(onTap: onTap, child: key),
    );
  }
}
