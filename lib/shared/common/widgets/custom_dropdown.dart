import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/skeu/skeu.dart';

/// The app-wide single-select field.
///
/// In the skeuomorphic language a dropdown is a recessed well — the same
/// material as a text field, because both hold a value you can change — with a
/// chevron at the end. The popup is a raised panel of option rows floating
/// above the page.
///
/// Every existing parameter is preserved so the 50-odd call sites keep working;
/// [onRail] is the one addition, for the child-picker that sits on the navy
/// header rail and therefore needs a translucent plate and light text.
class CustomDropdown extends StatefulWidget {
  const CustomDropdown({
    super.key,
    this.label,
    required this.hintText,
    required this.items,
    this.initialValue,
    this.isField = true,
    this.isEnabled = true,
    this.border,
    this.onSelect,
    this.selectedItem, // New parameter for the selected item
    this.controller,
    this.labelStyle,
    this.showAsterisk = true,
    this.labelBottomSpacing,
    this.fieldHeight,
    this.selectedTextStyle,
    this.popupItemTextStyle,
    this.isRequired = false,
    this.contentPadding,
    this.height,
    this.leadingIcon,

    /// Shows a search box at the top of the popup that filters [items] as you
    /// type. Off by default — opt in per-usage (e.g. the existing-parent picker).
    this.enableSearch = false,

    /// Renders for placement on the navy header rail: a translucent plate with
    /// a lit edge and white text, instead of a well on the light page.
    this.onRail = false,
  });

  final String? label;
  final String hintText;
  final bool isRequired;
  final List<String> items;
  final bool isField;
  final bool isEnabled;
  final InputBorder? border;
  final ValueChanged<String?>? onSelect;
  final String? selectedItem; // New parameter for the selected item
  final String? initialValue;
  final TextEditingController? controller;
  final TextStyle? labelStyle;
  final bool showAsterisk;
  final double? labelBottomSpacing;
  final double? fieldHeight;
  final TextStyle? selectedTextStyle;
  final TextStyle? popupItemTextStyle;
  final EdgeInsets? contentPadding;
  final double? height;

  /// Optional leading widget (e.g. an icon) shown before the text.
  final Widget? leadingIcon;
  final bool enableSearch;
  final bool onRail;

  @override
  State<CustomDropdown> createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<CustomDropdown> {
  String? selectedItem; // Local state for the selected item

  @override
  void initState() {
    super.initState();
    selectedItem = widget.selectedItem; // Initialize with the selected item
  }

  @override
  void didUpdateWidget(CustomDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update the selectedItem if the widget's selectedItem changes
    if (oldWidget.selectedItem != widget.selectedItem) {
      setState(() {
        selectedItem = widget.selectedItem;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          RichText(
            text: TextSpan(
              style: TextStyle(
                fontFamily: widget.labelStyle?.fontFamily ?? SkeuText.family,
                color: widget.labelStyle?.color ?? SkeuColors.inkSoft,
                fontSize: widget.labelStyle?.fontSize ?? 13,
                fontWeight:
                    widget.labelStyle?.fontWeight ?? SkeuText.weightHeading,
              ),
              children: [
                TextSpan(text: widget.label!),
                if (widget.showAsterisk)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(
                      color: SkeuColors.pink600,
                      fontWeight: SkeuText.weightBold,
                    ),
                  ),
              ],
            ),
          ),
        if (widget.label != null)
          SizedBox(height: widget.labelBottomSpacing ?? 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final minHeight =
                widget.height ??
                widget.fieldHeight ??
                (widget.isField ? 44.0 : 34.0);

            // Ensure dropdown interactions never trigger the software keyboard.
            // On some screens, after selecting an item the focus returns to a
            // text field, which causes the keyboard to pop open unexpectedly
            // (e.g. State/Country).
            final button = Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (_) {
                FocusManager.instance.primaryFocus?.unfocus();
              },
              child: Focus(
                canRequestFocus: false,
                descendantsAreFocusable: false,
                child: PopupMenuButton<String>(
                  enabled: widget.isEnabled,
                  padding: EdgeInsets.zero,
                  position: PopupMenuPosition.under,
                  color: Colors.transparent,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  constraints: BoxConstraints(
                    minWidth: constraints.maxWidth,
                    maxWidth: constraints.maxWidth,
                  ),
                  onSelected: (value) {
                    setState(() {
                      selectedItem = value;
                    });

                    // Call the onSelect callback if it's provided
                    if (widget.onSelect != null) {
                      widget.onSelect!(selectedItem);
                    }

                    // After the popup closes, ensure we don't restore focus to
                    // a text field.
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      FocusManager.instance.primaryFocus?.unfocus();
                    });
                  },
                  onCanceled: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      FocusManager.instance.primaryFocus?.unfocus();
                    });
                  },
                  itemBuilder: (BuildContext context) {
                    return <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        enabled: false,
                        padding: EdgeInsets.zero,
                        child: _DropdownMenuPanel(
                          items: widget.items,
                          selectedItem: selectedItem,
                          maxWidth: constraints.maxWidth,
                          enableSearch: widget.enableSearch,
                          isField: widget.isField,
                          itemTextStyle: widget.popupItemTextStyle,
                        ),
                      ),
                    ];
                  },
                  child: Padding(
                    padding:
                        widget.contentPadding ??
                        const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                    child: Row(
                      children: [
                        if (widget.leadingIcon != null) ...[
                          widget.leadingIcon!,
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Text(
                            selectedItem ?? widget.hintText,
                            style: widget.selectedTextStyle ?? _valueStyle(),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.left,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (widget.isEnabled)
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: widget.onRail
                                ? SkeuColors.white
                                : SkeuColors.inkFaint,
                            size: 22,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );

            if (widget.onRail) {
              // On the navy rail the field is a translucent plate, not a well:
              // a recess would disappear into the dark slab.
              return Container(
                constraints: BoxConstraints(minHeight: minHeight),
                decoration: BoxDecoration(
                  color: SkeuColors.white.withValues(alpha: .14),
                  borderRadius: BorderRadius.circular(SkeuRadius.md),
                  border: Border.all(
                    color: SkeuColors.white.withValues(alpha: .22),
                  ),
                ),
                child: button,
              );
            }

            return Opacity(
              opacity: widget.isEnabled ? 1 : .6,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minHeight),
                child: SkeuWell(
                  radius: SkeuRadius.field,
                  insets: SkeuElevation.wellSm,
                  child: button,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  TextStyle _valueStyle() {
    if (widget.onRail) {
      return SkeuText.body(
        color: SkeuColors.white,
        weight: selectedItem != null
            ? SkeuText.weightHeading
            : SkeuText.weightBody,
      );
    }
    return SkeuText.body(
      color: selectedItem != null ? SkeuColors.ink : SkeuColors.inkFaint,
      weight: selectedItem != null
          ? SkeuText.weightHeading
          : SkeuText.weightBody,
    );
  }
}

/// Scrollable popup body for [CustomDropdown]: a raised panel of option rows.
/// When [enableSearch] is on it adds a live filter well at the top; otherwise
/// it is just the plain item list.
///
/// Stateful so the search query can filter the list inside the popup route
/// (the parent dropdown's State does not rebuild the open popup).
class _DropdownMenuPanel extends StatefulWidget {
  const _DropdownMenuPanel({
    required this.items,
    required this.maxWidth,
    required this.enableSearch,
    required this.isField,
    this.selectedItem,
    this.itemTextStyle,
  });

  final List<String> items;
  final double maxWidth;
  final bool enableSearch;
  final bool isField;
  final String? selectedItem;
  final TextStyle? itemTextStyle;

  @override
  State<_DropdownMenuPanel> createState() => _DropdownMenuPanelState();
}

class _DropdownMenuPanelState extends State<_DropdownMenuPanel> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  late List<String> _filtered = widget.items;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    final query = value.trim().toLowerCase();
    setState(() {
      _filtered = query.isEmpty
          ? widget.items
          : widget.items
                .where((item) => item.toLowerCase().contains(query))
                .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: widget.maxWidth,
        maxHeight: widget.enableSearch ? 320 : 240,
      ),
      child: SkeuPanel(
        radius: 18,
        shadows: SkeuElevation.elev3,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.enableSearch)
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 4, 2, 8),
                child: SkeuSearchField(
                  controller: _searchController,
                  onChanged: _onQueryChanged,
                ),
              ),
            Flexible(
              child: _filtered.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Text(
                        'No matches found',
                        style: SkeuText.body(color: SkeuColors.inkSoft),
                      ),
                    )
                  : Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      thickness: 4,
                      radius: const Radius.circular(4),
                      child: ListView.builder(
                        controller: _scrollController,
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final item = _filtered[index];
                          return SkeuOptionRow(
                            label: item,
                            selected: item == widget.selectedItem,
                            onTap: () => Navigator.of(context).pop(item),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
