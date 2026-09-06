import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/presentation/features/reports/widgets/selection_row.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/presentation/features/reports/reports_strings.dart';

/// The dropdown popup of [MultiSelectFilterField]: an optional search box, an
/// optional "Select All" row, and the filtered item list.
///
/// Extracted from `multi_select_filter_field.dart` (§6.7). It owns the search
/// query and the filtered list — state that only the popup uses — which also
/// replaces the `StatefulBuilder` the overlay previously relied on.
class MultiSelectOverlayPanel<T> extends StatefulWidget {
  const MultiSelectOverlayPanel({
    super.key,
    required this.items,
    required this.itemToString,
    required this.enableSearch,
    required this.showSelectAll,
    required this.pluralLabel,
    required this.searchHintText,
    required this.selectedItems,
    required this.isItemSelected,
    required this.isAllSelected,
    required this.onToggleItem,
    required this.onSelectAll,
    required this.onClearAll,
  });

  final List<T> items;
  final String Function(T item) itemToString;
  final bool enableSearch;
  final bool showSelectAll;
  final String pluralLabel;
  final String? searchHintText;

  /// Listened to so the popup repaints when the selection changes.
  final ValueNotifier<List<T>> selectedItems;

  final bool Function(T item) isItemSelected;
  final bool Function() isAllSelected;
  final void Function(T item) onToggleItem;
  final VoidCallback onSelectAll;
  final VoidCallback onClearAll;

  @override
  State<MultiSelectOverlayPanel<T>> createState() =>
      _MultiSelectOverlayPanelState<T>();
}

class _MultiSelectOverlayPanelState<T>
    extends State<MultiSelectOverlayPanel<T>> {
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _query = ValueNotifier<String>('');

  @override
  void dispose() {
    _searchController.dispose();
    _query.dispose();
    super.dispose();
  }

  List<T> _filtered(String query) {
    if (query.isEmpty) return widget.items;
    final needle = query.toLowerCase();
    return widget.items
        .where((i) => widget.itemToString(i).toLowerCase().contains(needle))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<T>>(
      valueListenable: widget.selectedItems,
      builder: (context, _, __) => ValueListenableBuilder<String>(
        valueListenable: _query,
        builder: (context, query, __) {
          final filtered = _filtered(query);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.enableSearch)
                Padding(
                  padding: const EdgeInsets.all(AppSizes.xs),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText:
                          widget.searchHintText ??
                          'Search ${widget.pluralLabel}',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (value) => _query.value = value,
                  ),
                ),
              if (widget.showSelectAll)
                SelectionRow(
                  label: ReportsStrings.selectAll,
                  isSelected: widget.isAllSelected(),
                  onTap: () => widget.isAllSelected()
                      ? widget.onClearAll()
                      : widget.onSelectAll(),
                ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No ${widget.pluralLabel.toLowerCase()} found',
                          style: AppTextStyles.reportsSelectionEmptyLabel,
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return SelectionRow(
                            label: widget.itemToString(item),
                            isSelected: widget.isItemSelected(item),
                            isEmphasised: true,
                            onTap: () => widget.onToggleItem(item),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
