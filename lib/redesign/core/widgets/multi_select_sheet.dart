import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/widgets/app_bottom_sheet.dart';
import 'package:wowcare/redesign/core/widgets/check_row.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/search_field.dart';
import 'package:wowcare/redesign/core/widgets/secondary_key.dart';
import 'package:wowcare/redesign/core/widgets/select_option.dart';
import 'package:wowcare/redesign/core/widgets/text_link.dart';

/// The searchable checkbox list a multi-select dropdown opens (tags,
/// classrooms, guardians).
///
/// Open it with [show], which resolves to the chosen set on Apply and null
/// on Cancel or dismiss. The working selection lives in this widget until
/// then; nothing is written back while the sheet is open.
class MultiSelectSheet<T> extends StatefulWidget {
  const MultiSelectSheet({
    required this.title,
    required this.options,
    this.subtitle,
    this.selected = const <Never>{},
    this.searchable = true,
    super.key,
  });

  final String title;
  final String? subtitle;
  final List<SelectOption<T>> options;
  final Set<T> selected;
  final bool searchable;

  static Future<Set<T>?> show<T>(
    BuildContext context, {
    required String title,
    required List<SelectOption<T>> options,
    String? subtitle,
    Set<T> selected = const <Never>{},
    bool searchable = true,
  }) => showAppSheet<Set<T>>(
    context,
    builder: (_) => MultiSelectSheet<T>(
      title: title,
      subtitle: subtitle,
      options: options,
      selected: selected,
      searchable: searchable,
    ),
  );

  @override
  State<MultiSelectSheet<T>> createState() => _MultiSelectSheetState<T>();
}

class _MultiSelectSheetState<T> extends State<MultiSelectSheet<T>> {
  late final Set<T> _selected = <T>{...widget.selected};
  String _query = '';

  List<SelectOption<T>> get _visible =>
      widget.options.where((o) => o.matches(_query)).toList();

  void _toggle(T value, bool on) =>
      setState(() => on ? _selected.add(value) : _selected.remove(value));

  void _selectAll() => setState(() {
    _selected.addAll(_visible.map((o) => o.value));
  });

  void _clearAll() => setState(_selected.clear);

  @override
  Widget build(BuildContext context) {
    final visible = _visible;

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
          Row(
            spacing: AppSizes.space4,
            children: <Widget>[
              TextLink(label: AppStrings.selectAll, onTap: _selectAll),
              TextLink(label: AppStrings.clearAll, onTap: _clearAll),
            ],
          ),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: visible.length,
              itemBuilder: (context, i) {
                final option = visible[i];
                return CheckRow(
                  label: option.label,
                  subtitle: option.subtitle,
                  checked: _selected.contains(option.value),
                  onChanged: (on) => _toggle(option.value, on),
                );
              },
            ),
          ),
        ],
      ),
      footer: <Widget>[
        SecondaryKey(
          label: AppStrings.cancel,
          onTap: () => Navigator.of(context).pop(),
        ),
        PrimaryKey(
          label: AppStrings.apply,
          onTap: () => Navigator.of(context).pop(Set<T>.of(_selected)),
        ),
      ],
    );
  }
}
