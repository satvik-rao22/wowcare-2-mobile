import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/shared/common/widgets/custom_confirm_button.dart';
import '../../core/theme/av2_colors.dart';
import '../../core/theme/av2_spacing.dart';
import '../../core/theme/av2_text_styles.dart';
import '../../core/utils/av2_date_formatter.dart';
import '../controllers/av2_period.dart';

/// Bottom sheet to choose the reporting period: a whole month (via a month
/// stepper) or a custom date interval (via the platform range picker).
/// Returns the chosen [Av2Period], or null if dismissed.
Future<Av2Period?> showAv2PeriodSheet(
  BuildContext context, {
  required Av2Period current,
}) {
  return showModalBottomSheet<Av2Period>(
    context: context,
    isScrollControlled: true,
    // Ground and corners come from ThemeData.bottomSheetTheme.
    builder: (context) => _Av2PeriodSheet(current: current),
  );
}

class _Av2PeriodSheet extends StatefulWidget {
  const _Av2PeriodSheet({required this.current});

  final Av2Period current;

  @override
  State<_Av2PeriodSheet> createState() => _Av2PeriodSheetState();
}

class _Av2PeriodSheetState extends State<_Av2PeriodSheet> {
  late bool _wholeMonth = widget.current.isWholeMonth;
  late DateTime _month = DateTime(
    widget.current.start.year,
    widget.current.start.month,
  );
  late DateTime _customStart = widget.current.start;
  late DateTime _customEnd = widget.current.end;

  void _stepMonth(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  Future<void> _pickCustom() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: DateTimeRange(start: _customStart, end: _customEnd),
      helpText: 'Select date range',
    );
    if (picked != null) {
      setState(() {
        _customStart = picked.start;
        _customEnd = picked.end;
      });
    }
  }

  void _apply() {
    final period = _wholeMonth
        ? Av2Period.month(_month)
        : Av2Period.custom(_customStart, _customEnd);
    Navigator.pop(context, period);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Av2Spacing.md,
          Av2Spacing.sm,
          Av2Spacing.md,
          Av2Spacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Av2Colors.border,
                  borderRadius: BorderRadius.circular(Av2Spacing.radiusPill),
                ),
              ),
            ),
            const SizedBox(height: Av2Spacing.md),
            Text('Select period', style: Av2Text.title),
            const SizedBox(height: Av2Spacing.sm),
            _segmented(),
            const SizedBox(height: Av2Spacing.md),
            _wholeMonth ? _monthStepper() : _customPicker(),
            const SizedBox(height: Av2Spacing.lg),
            _applyButton(),
          ],
        ),
      ),
    );
  }

  Widget _segmented() {
    return Container(
      padding: const EdgeInsets.all(3),
      // The segmented control's trough is a well; the selected segment
      // sits proud of it.
      decoration: AppSurfaces.well(radius: Av2Spacing.radiusSm),
      child: Row(
        children: [
          _segment('Whole month', _wholeMonth, () {
            setState(() => _wholeMonth = true);
          }),
          _segment('Custom range', !_wholeMonth, () {
            setState(() => _wholeMonth = false);
          }),
        ],
      ),
    );
  }

  Widget _segment(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? Av2Colors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(Av2Spacing.radiusSm - 2),
            border: Border.all(
              color: selected ? Av2Colors.border : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Av2Text.chip.copyWith(
              color: selected ? Av2Colors.textPrimary : Av2Colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _monthStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Av2Spacing.xs,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Av2Colors.border),
        borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => _stepMonth(-1),
            icon: const Icon(
              Icons.chevron_left,
              color: Av2Colors.textSecondary,
            ),
            tooltip: 'Previous month',
          ),
          Expanded(
            child: Text(
              Av2DateFormatter.monthYear(_month),
              textAlign: TextAlign.center,
              style: Av2Text.bodyMedium,
            ),
          ),
          IconButton(
            onPressed: () => _stepMonth(1),
            icon: const Icon(
              Icons.chevron_right,
              color: Av2Colors.textSecondary,
            ),
            tooltip: 'Next month',
          ),
        ],
      ),
    );
  }

  Widget _customPicker() {
    return InkWell(
      onTap: _pickCustom,
      borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Av2Spacing.sm,
          vertical: Av2Spacing.sm,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: Av2Colors.border),
          borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.date_range_outlined,
              size: 18,
              color: Av2Colors.textSecondary,
            ),
            const SizedBox(width: Av2Spacing.sm),
            Expanded(
              child: Text(
                Av2DateFormatter.range(_customStart, _customEnd),
                style: Av2Text.body,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              'Change',
              style: Av2Text.label.copyWith(color: Av2Colors.theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _applyButton() =>
      CustomConfirmButton(label: 'Apply', onPressed: _apply);
}
