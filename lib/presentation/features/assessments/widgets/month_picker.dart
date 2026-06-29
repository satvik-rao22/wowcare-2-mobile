import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_ui_utils.dart';

/// Assessment-period selector (PRD §15.5). Shows the selected month with
/// prev/next steppers and a tap-to-open month grid. When [blockFuture] is true
/// (assessment-entry contexts) future months cannot be selected (VR-MP-01); the
/// year range is limited to current year ±5 (VR-MP-02).
class MonthPicker extends StatelessWidget {
  const MonthPicker({
    super.key,
    required this.month,
    required this.onChanged,
    this.blockFuture = false,
  });

  /// First day of the selected month.
  final DateTime month;
  final ValueChanged<DateTime> onChanged;
  final bool blockFuture;

  bool get _canGoNext {
    if (!blockFuture) return true;
    final now = DateTime.now();
    final nextStart = DateTime(month.year, month.month + 1, 1);
    return !nextStart.isAfter(DateTime(now.year, now.month, 1));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B2559).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            iconSize: 22,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Previous month',
            onPressed: () =>
                onChanged(DateTime(month.year, month.month - 1, 1)),
          ),
          InkWell(
            onTap: () => _openGrid(context),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today, size: 15),
                  const SizedBox(width: 6),
                  Text(
                    AssessmentUi.monthLabel(month),
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            iconSize: 22,
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Next month',
            onPressed: _canGoNext
                ? () => onChanged(DateTime(month.year, month.month + 1, 1))
                : null,
          ),
        ],
      ),
    );
  }

  Future<void> _openGrid(BuildContext context) async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => _MonthGridSheet(month: month, blockFuture: blockFuture),
    );
    if (picked != null) onChanged(picked);
  }
}

class _MonthGridSheet extends StatefulWidget {
  const _MonthGridSheet({required this.month, required this.blockFuture});

  final DateTime month;
  final bool blockFuture;

  @override
  State<_MonthGridSheet> createState() => _MonthGridSheetState();
}

class _MonthGridSheetState extends State<_MonthGridSheet> {
  late int _year = widget.month.year;

  static const _labels = <String>[
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final minYear = now.year - 5;
    final maxYear = now.year + 5;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed:
                      _year > minYear ? () => setState(() => _year--) : null,
                ),
                Text('$_year',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed:
                      _year < maxYear ? () => setState(() => _year++) : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              childAspectRatio: 2.1,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: List.generate(12, (i) {
                final candidate = DateTime(_year, i + 1, 1);
                final isFuture = widget.blockFuture &&
                    candidate.isAfter(DateTime(now.year, now.month, 1));
                final selected = candidate.year == widget.month.year &&
                    candidate.month == widget.month.month;
                return OutlinedButton(
                  onPressed: isFuture
                      ? null
                      : () => Navigator.pop(context, candidate),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: selected
                        ? AppColors.themeColor.withValues(alpha: 0.12)
                        : null,
                    side: BorderSide(
                      color: selected
                          ? AppColors.themeColor
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    _labels[i],
                    style: TextStyle(
                      color: selected ? AppColors.themeColor : null,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
