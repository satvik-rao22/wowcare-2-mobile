import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/responsive/responsive_scope.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/presentation/features/reports/widgets/multi_select_overlay_panel.dart';
import 'package:wowcare/core/constants/app_sizes.dart';

/// Reusable multi-select filter field with search, select all, and smart display.
///
/// Features:
/// - Multi-select with checkboxes
/// - Search within dropdown
/// - Select All / Clear All functionality
/// - Smart display: "1 Item Selected", "All Items Selected", etc.
/// - Supports 1000+ items efficiently
/// - Generic support via custom item renderer
class MultiSelectFilterField<T> extends StatefulWidget {
  /// Label for the field (e.g., "Students", "Classrooms")
  final String label;

  /// Hint text when nothing is selected (e.g., "Select Students")
  final String hintText;

  /// All available items
  final List<T> items;

  /// Currently selected items
  final List<T> selectedItems;

  /// Callback when selection changes
  final ValueChanged<List<T>> onChanged;

  /// Convert item to display string
  final String Function(T item) itemToString;

  /// Optional: Custom item key for comparison
  /// If not provided, uses item.toString()
  final String Function(T item)? itemToKey;

  /// Singular form for count display (e.g., "Student")
  /// Used for "1 Student Selected"
  final String singularLabel;

  /// Plural form for count display (e.g., "Students")
  /// Used for "2 Students Selected"
  final String pluralLabel;

  /// Optional: Show select all checkbox
  final bool showSelectAll;

  /// Optional: Enable search functionality
  final bool enableSearch;

  /// Optional: Search hint text (e.g., "Search Students")
  final String? searchHintText;

  /// Optional: Required asterisk
  final bool showAsterisk;

  /// Optional: Alternative to showAsterisk
  final bool isRequired;

  /// Note text displayed below field (e.g., "All items are included unless
  /// you select specific ones")
  final String? defaultNote;

  const MultiSelectFilterField({
    super.key,
    required this.label,
    required this.hintText,
    required this.items,
    required this.selectedItems,
    required this.onChanged,
    required this.itemToString,
    required this.singularLabel,
    required this.pluralLabel,
    this.itemToKey,
    this.showSelectAll = true,
    this.enableSearch = true,
    this.searchHintText,
    this.showAsterisk = false,
    this.isRequired = false,
    this.defaultNote,
  });

  @override
  State<MultiSelectFilterField<T>> createState() =>
      _MultiSelectFilterFieldState<T>();
}

class _MultiSelectFilterFieldState<T> extends State<MultiSelectFilterField<T>> {
  /// §2.2 bucket B — the local selection mirror and the open/closed flag are
  /// UI micro-state owned by this field.
  ///
  /// Created once here rather than in [_initializeSelection], which also runs
  /// from didUpdateWidget — a `late final` would throw on the second call.
  final ValueNotifier<List<T>> _localSelectedItems = ValueNotifier<List<T>>(
    <T>[],
  );
  final ValueNotifier<bool> isDropdownOpen = ValueNotifier<bool>(false);
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _fieldKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _initializeSelection();
  }

  void _initializeSelection() {
    _localSelectedItems.value = _synchronizeSelection(widget.selectedItems);
  }

  /// Synchronize external selection with internal list, removing invalid items
  List<T> _synchronizeSelection(List<T> items) {
    final synchronized = List<T>.from(items);
    synchronized.removeWhere((item) => !_itemExists(item));
    return synchronized;
  }

  /// Check if an item exists in the items list
  bool _itemExists(T item) {
    final itemKey = widget.itemToKey?.call(item) ?? item.toString();
    return widget.items.any(
      (i) => (widget.itemToKey?.call(i) ?? i.toString()) == itemKey,
    );
  }

  /// Check if two items are equal
  bool _itemsEqual(T a, T b) {
    final aKey = widget.itemToKey?.call(a) ?? a.toString();
    final bKey = widget.itemToKey?.call(b) ?? b.toString();
    return aKey == bKey;
  }

  @override
  void didUpdateWidget(MultiSelectFilterField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.items, widget.items) ||
        !listEquals(oldWidget.selectedItems, widget.selectedItems)) {
      _initializeSelection();
    }
  }

  String _getDisplayText() {
    if (_localSelectedItems.value.isEmpty) {
      return widget.hintText;
    }

    if (_localSelectedItems.value.length == widget.items.length) {
      return 'All ${widget.pluralLabel} Selected';
    }

    if (_localSelectedItems.value.length == 1) {
      return '1 ${widget.singularLabel} Selected';
    }

    return '${_localSelectedItems.value.length} ${widget.pluralLabel} Selected';
  }

  void _toggleDropdown() {
    if (isDropdownOpen.value) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _overlayEntry = _createOverlayEntry();
    if (mounted) {
      Overlay.of(context).insert(_overlayEntry!);
      isDropdownOpen.value = true;
    }
  }

  void _closeDropdown({bool updateState = true}) {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (updateState && mounted) {
      isDropdownOpen.value = false;
    }
  }

  void _toggleItemSelection(T item) {
    // A new list, not an in-place mutation: ValueNotifier only notifies when
    // the reference changes.
    final next = List<T>.from(_localSelectedItems.value);
    final index = next.indexWhere((i) => _itemsEqual(i, item));
    if (index >= 0) {
      next.removeAt(index);
    } else {
      next.add(item);
    }
    _localSelectedItems.value = next;
    widget.onChanged(List<T>.from(next));
  }

  void _selectAll() {
    _localSelectedItems.value = List<T>.from(widget.items);
    widget.onChanged(List<T>.from(_localSelectedItems.value));
  }

  void _clearAll() {
    _localSelectedItems.value = <T>[];
    widget.onChanged(<T>[]);
  }

  bool _isItemSelected(T item) {
    return _localSelectedItems.value.any((i) => _itemsEqual(i, item));
  }

  bool _isAllSelected() {
    return _localSelectedItems.value.length == widget.items.length &&
        widget.items.isNotEmpty;
  }

  OverlayEntry _createOverlayEntry() {
    final renderObject =
        _fieldKey.currentContext?.findRenderObject() ??
        context.findRenderObject();
    final renderBox = renderObject as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Barrier to close on tap outside
          Positioned.fill(
            child: GestureDetector(
              onTap: _closeDropdown,
              child: Container(color: AppColors.transparentColor),
            ),
          ),
          // Dropdown
          Positioned(
            width: size.width,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0, size.height + 6),
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                shadowColor: AppColors.blackColor.withValues(alpha: 0.26),
                child: Container(
                  constraints: BoxConstraints(maxHeight: 350),
                  decoration: BoxDecoration(
                    color: AppColors.cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.reportsDisabledSurfaceColor,
                      width: 1,
                    ),
                  ),
                  child: MultiSelectOverlayPanel<T>(
                    items: widget.items,
                    itemToString: widget.itemToString,
                    enableSearch: widget.enableSearch,
                    showSelectAll: widget.showSelectAll,
                    pluralLabel: widget.pluralLabel,
                    searchHintText: widget.searchHintText,
                    selectedItems: _localSelectedItems,
                    isItemSelected: _isItemSelected,
                    isAllSelected: _isAllSelected,
                    onToggleItem: _toggleItemSelection,
                    onSelectAll: _selectAll,
                    onClearAll: _clearAll,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // Close the overlay BEFORE disposing the notifiers it reads.
    _closeDropdown(updateState: false);
    _localSelectedItems.dispose();
    isDropdownOpen.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayText = _getDisplayText();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        RichText(
          text: TextSpan(
            style: AppTextStyles.reportsFieldLabel(
              fontSize: context.responsive(compact: 14.0, medium: 16.0),
            ),
            children: [
              TextSpan(text: widget.label),
              if (widget.showAsterisk || widget.isRequired)
                const TextSpan(
                  text: ' *',
                  style: AppTextStyles.reportsRequiredMarker,
                ),
            ],
          ),
        ),
        SizedBox(height: context.isTablet ? 8.0 : 6.0),
        // Field
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            key: _fieldKey,
            onTap: _toggleDropdown,
            child: Container(
              constraints: BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
              decoration: BoxDecoration(
                color: AppColors.fieldBackgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ValueListenableBuilder<List<T>>(
                      valueListenable: _localSelectedItems,
                      builder: (context, selected, _) => Text(
                        displayText,
                        style:
                            AppTextStyles.reportsFieldValue(
                              fontSize: context.responsive(
                                compact: 14.0,
                                medium: 16.0,
                              ),
                            ).copyWith(
                              color: selected.isEmpty
                                  ? AppColors.reportsDisabledForegroundColor
                                  : AppColors.blackColor.withValues(
                                      alpha: 0.87,
                                    ),
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: isDropdownOpen,
                    builder: (context, open, _) => Icon(
                      open
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Default note
        if (widget.defaultNote != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              widget.defaultNote!,
              style: AppTextStyles.reportsFieldLabel(
                fontSize: 12,
              ).copyWith(color: AppColors.reportsAccentColor),
            ),
          ),
      ],
    );
  }
}

/// Square check indicator used by each row of the multi-select popup.
///
/// Was `Widget _buildCheckbox(bool)` on the State. A private widget class can
