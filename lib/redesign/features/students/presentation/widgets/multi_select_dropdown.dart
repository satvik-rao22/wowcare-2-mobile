import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_motion.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/app_well.dart';
import 'package:wowcare/redesign/core/widgets/check_row.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/search_field.dart';
import 'package:wowcare/redesign/features/students/students_sizes.dart';
import 'package:wowcare/redesign/features/students/students_text_styles.dart';

/// A well that opens its list where it stands (5b Tags).
///
/// Core's `MultiSelectSheet` is the right control when a picker gets its own
/// sheet; inside a sheet it would be a sheet over a sheet, so this one opens
/// downward instead, which is what the frame draws.
class MultiSelectDropdown extends StatefulWidget {
  const MultiSelectDropdown({
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.emptySummary,
    required this.summaryOf,
    required this.searchHint,
    super.key,
  });

  final List<String> options;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  /// What the well reads when nothing is picked: "Any tag".
  final String emptySummary;

  /// How a picked set reads: the names, or "5 of 25 selected".
  final String Function(Set<String>) summaryOf;

  final String searchHint;

  @override
  State<MultiSelectDropdown> createState() => _MultiSelectDropdownState();
}

class _MultiSelectDropdownState extends State<MultiSelectDropdown> {
  bool _isOpen = false;
  String _query = '';

  List<String> get _visible {
    final term = _query.trim().toLowerCase();
    if (term.isEmpty) return widget.options;
    return <String>[
      for (final option in widget.options)
        if (option.toLowerCase().contains(term)) option,
    ];
  }

  void _toggle(String option) {
    final next = <String>{...widget.selected};
    if (!next.remove(option)) next.add(option);
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final isEmpty = widget.selected.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: StudentsSizes.filterOptionGap,
      children: <Widget>[
        Semantics(
          button: true,
          expanded: _isOpen,
          child: Pressable.surface(
            onTap: () => setState(() => _isOpen = !_isOpen),
            child: AppWell(
              padding: AppSizes.dropdownPad,
              child: Row(
                spacing: AppSizes.dropdownGap,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      isEmpty
                          ? widget.emptySummary
                          : widget.summaryOf(widget.selected),
                      style: StudentsTextStyles.wellValue.copyWith(
                        color: isEmpty ? c.ink3 : c.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  AnimatedRotation(
                    duration: AppMotion.fast,
                    curve: AppMotion.ease,
                    turns: _isOpen ? .5 : 0,
                    child: Icon(
                      AppIcons.chevronDown,
                      size: AppSizes.caret,
                      color: c.ink2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_isOpen)
          AppCard(
            padding: EdgeInsets.zero,
            clipContent: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: AppSizes.rowPad,
                  child: SearchField(
                    hintText: widget.searchHint,
                    onChanged: (q) => setState(() => _query = q),
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: StudentsSizes.dropdownListHeight,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _visible.length,
                    itemBuilder: (context, i) {
                      final option = _visible[i];
                      return CheckRow(
                        label: option,
                        checked: widget.selected.contains(option),
                        onChanged: (_) => _toggle(option),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
