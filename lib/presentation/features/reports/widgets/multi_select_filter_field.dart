import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

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

  /// Note text displayed below field (e.g., "All items will be selected by default")
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
  late List<T> _localSelectedItems;
  late List<T> _filteredItems;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool isDropdownOpen = false;
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _fieldKey = GlobalKey();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _initializeSelection();
  }

  void _initializeSelection() {
    _localSelectedItems = _synchronizeSelection(widget.selectedItems);
    _updateFilteredItems();
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

  void _updateFilteredItems() {
    if (_searchQuery.isEmpty) {
      _filteredItems = widget.items;
    } else {
      _filteredItems = widget.items
          .where(
            (item) => widget
                .itemToString(item)
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }
  }

  String _getDisplayText() {
    if (_localSelectedItems.isEmpty) {
      return widget.hintText;
    }

    if (_localSelectedItems.length == widget.items.length) {
      return 'All ${widget.pluralLabel} Selected';
    }

    if (_localSelectedItems.length == 1) {
      return '1 ${widget.singularLabel} Selected';
    }

    return '${_localSelectedItems.length} ${widget.pluralLabel} Selected';
  }

  void _toggleDropdown() {
    if (isDropdownOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    _searchQuery = '';
    _searchController.clear();
    _updateFilteredItems();
    _overlayEntry = _createOverlayEntry();
    if (mounted) {
      Overlay.of(context).insert(_overlayEntry!);
      setState(() {
        isDropdownOpen = true;
      });
    }
  }

  void _closeDropdown({bool updateState = true}) {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (updateState && mounted) {
      setState(() {
        isDropdownOpen = false;
      });
    }
  }

  void _toggleItemSelection(T item) {
    setState(() {
      final index = _localSelectedItems.indexWhere((i) => _itemsEqual(i, item));
      if (index >= 0) {
        _localSelectedItems.removeAt(index);
      } else {
        _localSelectedItems.add(item);
      }
      widget.onChanged(List.from(_localSelectedItems));
    });
  }

  void _selectAll() {
    setState(() {
      _localSelectedItems = List.from(widget.items);
      widget.onChanged(List.from(_localSelectedItems));
    });
  }

  void _clearAll() {
    setState(() {
      _localSelectedItems.clear();
      widget.onChanged([]);
    });
  }

  bool _isItemSelected(T item) {
    return _localSelectedItems.any((i) => _itemsEqual(i, item));
  }

  bool _isAllSelected() {
    return _localSelectedItems.length == widget.items.length &&
        widget.items.isNotEmpty;
  }

  Widget _buildCheckbox(bool isSelected) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected ? AppColors.themeColor : Colors.grey.shade400,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(4),
        color: isSelected ? AppColors.themeColor : Colors.transparent,
      ),
      child: isSelected
          ? const Icon(Icons.check, size: 14, color: Colors.white)
          : null,
    );
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
              child: Container(color: Colors.transparent),
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
                shadowColor: Colors.black26,
                child: Container(
                  constraints: BoxConstraints(maxHeight: 350),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300, width: 1),
                  ),
                  child: StatefulBuilder(
                    builder: (context, setOverlayState) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Search field
                          if (widget.enableSearch)
                            Padding(
                              padding: const EdgeInsets.all(8),
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
                                onChanged: (value) {
                                  setOverlayState(() {
                                    _searchQuery = value;
                                    _updateFilteredItems();
                                  });
                                },
                              ),
                            ),
                          // Select All / Clear All buttons
                          if (widget.showSelectAll)
                            InkWell(
                              onTap: () {
                                setOverlayState(() {
                                  if (_isAllSelected()) {
                                    _clearAll();
                                  } else {
                                    _selectAll();
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    _buildCheckbox(_isAllSelected()),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Text(
                                        'Select All',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          // Items list
                          Expanded(
                            child: _filteredItems.isEmpty
                                ? Center(
                                    child: Text(
                                      'No ${widget.pluralLabel.toLowerCase()} found',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: EdgeInsets.zero,
                                    itemCount: _filteredItems.length,
                                    itemBuilder: (context, index) {
                                      final item = _filteredItems[index];
                                      final isSelected = _isItemSelected(item);
                                      return InkWell(
                                        onTap: () {
                                          setOverlayState(
                                            () => _toggleItemSelection(item),
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 12,
                                          ),
                                          child: Row(
                                            children: [
                                              _buildCheckbox(isSelected),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Text(
                                                  widget.itemToString(item),
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black87,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      );
                    },
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
    _searchController.dispose();
    _closeDropdown(updateState: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final displayText = _getDisplayText();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: responsive.labelFontSize,
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w400,
              color: const Color(0xFF0A1C5D),
            ),
            children: [
              TextSpan(text: widget.label),
              if (widget.showAsterisk || widget.isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        // Field
        CompositedTransformTarget(
          link: _layerLink,
          child: GestureDetector(
            key: _fieldKey,
            onTap: _toggleDropdown,
            child: Container(
              constraints: BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.fieldBackgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      displayText,
                      style: TextStyle(
                        color: _localSelectedItems.isEmpty
                            ? Colors.grey.shade600
                            : Colors.black87,
                        fontSize: responsive.labelFontSize,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    isDropdownOpen
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 24,
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
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xff4F46E5),
              ),
            ),
          ),
      ],
    );
  }
}

/// Select All button component
class _SelectAllButton extends StatelessWidget {
  final bool isAllSelected;
  final VoidCallback onSelectAll;

  const _SelectAllButton({
    required this.isAllSelected,
    required this.onSelectAll,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onSelectAll,
      icon: Icon(
        isAllSelected ? Icons.check_box : Icons.check_box_outline_blank,
        size: 20,
      ),
      label: Text(isAllSelected ? 'Clear All' : 'Select All'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }
}

/// Clear All button component
class _ClearAllButton extends StatelessWidget {
  final bool isEmpty;
  final VoidCallback onClearAll;

  const _ClearAllButton({required this.isEmpty, required this.onClearAll});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: isEmpty ? null : onClearAll,
      icon: const Icon(Icons.clear, size: 20),
      label: const Text('Clear'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }
}
