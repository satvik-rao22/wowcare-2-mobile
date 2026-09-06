import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';

/// Wrapping grid of labelled checkboxes used by the report field pickers —
/// two columns, three above 480px.
///
/// Was declared privately, byte-for-byte identically, in both
/// `staff_details_report_screen.dart` and
/// `students_and_family_report_screen.dart` (§6.2).
class ReportCheckboxGrid extends StatelessWidget {
  const ReportCheckboxGrid({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
  });

  final List<String> items;
  final Set<String> selected;
  final void Function(String field, bool checked) onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 480;
        final columns = isWide ? 3 : 2;
        return Wrap(
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.start,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in items)
              SizedBox(
                width: (constraints.maxWidth - (columns - 1) * 8) / columns,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: CustomCheckbox(
                    value: selected.contains(item),
                    label: item,
                    onChanged: (v) => onChanged(item, v ?? false),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
