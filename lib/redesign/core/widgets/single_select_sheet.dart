import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/app_bottom_sheet.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/radio_ring.dart';
import 'package:wowcare/redesign/core/widgets/search_field.dart';
import 'package:wowcare/redesign/core/widgets/select_option.dart';

/// A pick-one list in a sheet. Tapping a row chooses it and closes the
/// sheet, so there is no footer.
///
/// Open it with [show], which resolves to the chosen value, or null when the
/// sheet is dismissed.
class SingleSelectSheet<T> extends StatefulWidget {
  const SingleSelectSheet({
    required this.title,
    required this.options,
    this.subtitle,
    this.selected,
    this.searchable = false,
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<SelectOption<T>> options;
  final T? selected;
  final bool searchable;

  static Future<T?> show<T>(
    BuildContext context, {
    required String title,
    required List<SelectOption<T>> options,
    String? subtitle,
    T? selected,
    bool searchable = false,
  }) => showAppSheet<T>(
    context,
    builder: (_) => SingleSelectSheet<T>(
      title: title,
      subtitle: subtitle,
      options: options,
      selected: selected,
      searchable: searchable,
    ),
  );

  @override
  State<SingleSelectSheet<T>> createState() => _SingleSelectSheetState<T>();
}

class _SingleSelectSheetState<T> extends State<SingleSelectSheet<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final visible = widget.options.where((o) => o.matches(_query)).toList();

    return AppBottomSheet(
      title: widget.title,
      subtitle: widget.subtitle,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSizes.sheetGap,
        children: <Widget>[
          if (widget.searchable)
            SearchField(onChanged: (q) => setState(() => _query = q)),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: visible.length,
              itemBuilder: (context, i) {
                final option = visible[i];
                final isSelected = option.value == widget.selected;
                return Semantics(
                  button: true,
                  selected: isSelected,
                  label: option.label,
                  child: Pressable.surface(
                    onTap: () => Navigator.of(context).pop(option.value),
                    child: Padding(
                      padding: AppSizes.rowPad,
                      child: Row(
                        spacing: AppSizes.rowGap,
                        children: <Widget>[
                          RadioRing(selected: isSelected),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: AppSizes.rowTextGap,
                              children: <Widget>[
                                Text(
                                  option.label,
                                  style: AppTextStyles.rowName.copyWith(
                                    color: c.ink,
                                  ),
                                ),
                                if (option.subtitle != null)
                                  Text(
                                    option.subtitle!,
                                    style: AppTextStyles.rowSub.copyWith(
                                      color: c.ink3,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
