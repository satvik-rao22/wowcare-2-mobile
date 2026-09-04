import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/app_bottom_sheet.dart';
import 'package:wowcare/redesign/core/widgets/app_well.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/radio_ring.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/attendance/attendance_formats.dart';
import 'package:wowcare/redesign/features/attendance/attendance_sizes.dart';
import 'package:wowcare/redesign/features/attendance/attendance_strings.dart';
import 'package:wowcare/redesign/features/attendance/attendance_text_styles.dart';
import 'package:wowcare/redesign/features/attendance/models/models.dart';

/// 4b. Which day the list is showing, or a range of them instead.
///
/// A past day opens read only, with Edit times still open to Admins; a range
/// leaves the day behind entirely and becomes totals, which is 4f. Nothing is
/// applied until the key at the foot.
class DayPickerSheet extends StatefulWidget {
  const DayPickerSheet({
    required this.today,
    required this.day,
    required this.range,
    this.allowRange = true,
    super.key,
  });

  /// The school's own day.
  final DateTime today;

  /// The day the list is on now.
  final DateTime day;

  /// The range the range view is on now, so reopening the sheet remembers it.
  final DateRange range;

  /// A guardian has no range view: their own month is on the attendance
  /// screen already.
  final bool allowRange;

  static Future<DaySelection?> show(
    BuildContext context, {
    required DateTime today,
    required DateTime day,
    required DateRange range,
    bool allowRange = true,
  }) => showAppSheet<DaySelection>(
    context,
    builder: (_) => DayPickerSheet(
      today: today,
      day: day,
      range: range,
      allowRange: allowRange,
    ),
  );

  @override
  State<DayPickerSheet> createState() => _DayPickerSheetState();
}

class _DayPickerSheetState extends State<DayPickerSheet> {
  late DayChoice _choice = _initialChoice;
  late DateTime _picked = widget.day;
  late DateRange _range = widget.range;

  DayChoice get _initialChoice {
    final back = AttendanceFormats.daysBetween(widget.day, widget.today);
    return switch (back) {
      0 => DayChoice.today,
      1 => DayChoice.yesterday,
      _ => DayChoice.pickADay,
    };
  }

  DateTime get _firstDate =>
      DateTime(widget.today.year - 1, widget.today.month, widget.today.day);

  Future<void> _pickDay() async {
    final chosen = await showDatePicker(
      context: context,
      initialDate: _picked,
      firstDate: _firstDate,
      lastDate: widget.today,
      helpText: AttendanceStrings.pickADayOption,
    );
    if (chosen == null || !mounted) return;
    setState(() {
      _picked = chosen;
      _choice = DayChoice.pickADay;
    });
  }

  Future<void> _pickRangeEnd({required bool isFrom}) async {
    final chosen = await showDatePicker(
      context: context,
      initialDate: isFrom ? _range.from : _range.to,
      firstDate: _firstDate,
      lastDate: widget.today,
      helpText: AttendanceStrings.rangeOption,
    );
    if (chosen == null || !mounted) return;
    setState(() {
      _range = isFrom
          ? _range.copyWith(from: chosen)
          : _range.copyWith(to: chosen);
      _choice = DayChoice.range;
    });
  }

  void _apply() {
    Navigator.of(context).pop<DaySelection>(
      DaySelection(
        choice: _choice,
        day: switch (_choice) {
          DayChoice.today => widget.today,
          DayChoice.yesterday => widget.today.subtract(const Duration(days: 1)),
          _ => _picked,
        },
        range: _range,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final yesterday = widget.today.subtract(const Duration(days: 1));

    return AppBottomSheet(
      title: AttendanceStrings.whichDay,
      // Four options, one of which carries two fields: on a short screen the
      // sheet scrolls rather than clipping the last of them.
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AttendanceSizes.optionGap,
          children: <Widget>[
            _Option(
              title: AttendanceStrings.todayOption,
              subtitle: AttendanceStrings.todaySub(
                AttendanceFormats.weekdayDate(widget.today),
              ),
              isSelected: _choice == DayChoice.today,
              onTap: () => setState(() => _choice = DayChoice.today),
            ),
            _Option(
              title: AttendanceStrings.yesterdayOption,
              subtitle: AttendanceStrings.yesterdaySub(
                AttendanceFormats.weekdayDate(yesterday),
              ),
              isSelected: _choice == DayChoice.yesterday,
              onTap: () => setState(() => _choice = DayChoice.yesterday),
            ),
            _Option(
              title: AttendanceStrings.pickADayOption,
              subtitle: _choice == DayChoice.pickADay
                  ? AttendanceStrings.pickedDaySub(
                      AttendanceFormats.weekdayDate(_picked),
                    )
                  : AttendanceStrings.pickADaySub,
              isSelected: _choice == DayChoice.pickADay,
              onTap: () => unawaited(_pickDay()),
            ),
            if (widget.allowRange) _rangeOption(c),
          ],
        ),
      ),
      footer: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AttendanceSizes.rangeFieldGap,
          children: <Widget>[
            PrimaryKey(
              label: _choice == DayChoice.range
                  ? AttendanceStrings.showThisRange
                  : AttendanceStrings.showThisDay,
              onTap: _apply,
            ),
            Text(
              AttendanceStrings.dayFooter,
              textAlign: TextAlign.center,
              style: AttendanceTextStyles.footnote.copyWith(color: c.ink3),
            ),
          ],
        ),
      ],
    );
  }

  Widget _rangeOption(Colourway c) => _Option(
    title: AttendanceStrings.rangeOption,
    subtitle: AttendanceStrings.rangeSub,
    isSelected: _choice == DayChoice.range,
    onTap: () => setState(() => _choice = DayChoice.range),
    child: Row(
      spacing: AttendanceSizes.rangeFieldGap,
      children: <Widget>[
        Expanded(
          child: _RangeWell(
            label: AttendanceFormats.shortDate(_range.from),
            onTap: () => unawaited(_pickRangeEnd(isFrom: true)),
          ),
        ),
        Text(
          AttendanceStrings.rangeTo,
          style: AttendanceTextStyles.stripKey.copyWith(color: c.ink3),
        ),
        Expanded(
          child: _RangeWell(
            label: AttendanceFormats.shortDate(_range.to),
            onTap: () => unawaited(_pickRangeEnd(isFrom: false)),
          ),
        ),
      ],
    ),
  );
}

/// One of the four choices: a ring, a title over a sub-line, and optionally
/// the fields that belong to it.
class _Option extends StatelessWidget {
  const _Option({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    this.child,
  });

  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Semantics(
      button: true,
      selected: isSelected,
      label: title,
      child: Pressable.surface(
        onTap: onTap,
        child: SurfaceBox(
          surface: AppSurfaces.radioCard(c, selected: isSelected),
          padding: AttendanceSizes.optionPad,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AttendanceSizes.rangeFieldGap,
            children: <Widget>[
              Row(
                spacing: AttendanceSizes.optionGlyphGap,
                children: <Widget>[
                  RadioRing(selected: isSelected),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: AttendanceTextStyles.optionTitle.copyWith(
                            color: c.ink,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: AttendanceTextStyles.optionSub.copyWith(
                            color: c.ink3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              ?child,
            ],
          ),
        ),
      ),
    );
  }
}

/// One end of the range, recessed into its option.
class _RangeWell extends StatelessWidget {
  const _RangeWell({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable.surface(
    onTap: onTap,
    child: AppWell(
      padding: AttendanceSizes.rangeKeyPad,
      child: Text(
        label,
        style: AttendanceTextStyles.stripKey.copyWith(
          color: context.colours.ink2,
        ),
      ),
    ),
  );
}
