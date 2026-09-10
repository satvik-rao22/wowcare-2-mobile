import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';

/// Standardized "Relation" picker: a dropdown of common relation types plus
/// an "Other" option that reveals a free-text field for anything not
/// covered. Replaces raw free-text Relation inputs (e.g. Add/Edit Pickup)
/// so stored relation values stay consistent across the app instead of
/// accumulating arbitrary spellings/casings. Reusable anywhere a relation
/// needs to be captured — just swap in this widget instead of a plain text
/// field bound to a relation string.
class RelationSelector extends StatefulWidget {
  const RelationSelector({
    super.key,
    required this.onChanged,
    this.label = 'Relation',
    this.isRequired = true,
    this.initialRelation,
    this.options = defaultRelationOptions,
    this.otherOptionLabel = 'Other',
    this.customFieldLabel = 'Specify Relation',
    this.customFieldHint = 'E.g. Aunt, Family Friend',
    this.labelStyle,
    this.labelBottomSpacing,
    this.fieldHeight,
    this.contentPadding,
    this.spacing,
  });

  /// The predefined options shown in the dropdown, before the "Other" entry
  /// (which [otherOptionLabel] adds automatically — callers don't repeat it
  /// in this list).
  static const List<String> defaultRelationOptions = [
    'Mother',
    'Father',
    'Guardian',
    'Grandmother',
    'Grandfather',
    'Sibling',
  ];

  final String label;
  final bool isRequired;

  /// The relation value already on record (edit mode), in whatever raw form
  /// the backend stores (e.g. `GRANDMOTHER`, `FAMILY_FRIEND`). Matched
  /// case/format-insensitively against [options] on first build; when it
  /// doesn't match any predefined option, [otherOptionLabel] is
  /// pre-selected and a human-readable version of this value pre-fills the
  /// custom text field instead.
  final String? initialRelation;
  final List<String> options;
  final String otherOptionLabel;
  final String customFieldLabel;
  final String customFieldHint;

  /// Fires on every change with the RESOLVED relation value: the selected
  /// predefined option as-is, the custom text once [otherOptionLabel] is
  /// selected and the field is non-empty, or null while nothing valid is
  /// selected yet. Callers validate the same way they would a plain text
  /// field — null/empty means "not filled in".
  final ValueChanged<String?> onChanged;

  final TextStyle? labelStyle;
  final double? labelBottomSpacing;
  final double? fieldHeight;
  final EdgeInsets? contentPadding;
  final double? spacing;

  @override
  State<RelationSelector> createState() => RelationSelectorState();
}

class RelationSelectorState extends State<RelationSelector> {
  String? _selected;
  late final TextEditingController _customController;
  bool _userHasInteracted = false;

  List<String> get _dropdownItems => [
    ...widget.options,
    widget.otherOptionLabel,
  ];

  bool get _isOtherSelected => _selected == widget.otherOptionLabel;

  @override
  void initState() {
    super.initState();
    _customController = TextEditingController();
    _applyInitialRelation(widget.initialRelation);
  }

  @override
  void didUpdateWidget(RelationSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only re-apply while the user hasn't touched the field themselves —
    // e.g. edit-mode data arriving asynchronously after first build. Once
    // they've interacted, a parent rebuild must never clobber their pick.
    if (!_userHasInteracted &&
        oldWidget.initialRelation != widget.initialRelation) {
      setState(() => _applyInitialRelation(widget.initialRelation));
    }
  }

  /// Normalizes a relation string for comparison — matches regardless of
  /// case, spaces vs underscores (`GRANDMOTHER` vs `Grandmother`).
  static String _normalize(String s) =>
      s.trim().toUpperCase().replaceAll(RegExp(r'[\s_]+'), '_');

  /// Converts an enum-ish stored value (`FAMILY_FRIEND`) into a
  /// human-readable one (`Family Friend`) for the custom field pre-fill.
  static String _humanize(String raw) {
    final words = raw
        .trim()
        .toUpperCase()
        .replaceAll('_', ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty);
    return words
        .map((w) => w.substring(0, 1) + w.substring(1).toLowerCase())
        .join(' ');
  }

  void _applyInitialRelation(String? raw) {
    final trimmed = (raw ?? '').trim();
    if (trimmed.isEmpty) {
      _selected = null;
      _customController.text = '';
      return;
    }
    String? matched;
    for (final option in widget.options) {
      if (_normalize(option) == _normalize(trimmed)) {
        matched = option;
        break;
      }
    }
    if (matched != null) {
      _selected = matched;
      _customController.text = '';
    } else {
      _selected = widget.otherOptionLabel;
      _customController.text = _humanize(trimmed);
    }
  }

  void _notify() {
    if (_selected == null) {
      widget.onChanged(null);
      return;
    }
    if (_isOtherSelected) {
      final custom = _customController.text.trim();
      widget.onChanged(custom.isEmpty ? null : custom);
      return;
    }
    widget.onChanged(_selected);
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final effectiveLabelStyle =
        widget.labelStyle ??
        TextStyle(
          fontSize: responsive.labelFontSize,
          fontFamily: AppFonts.body,
          fontWeight: FontWeight.w400,
          color: AppColors.primaryColor,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomDropdown(
          label: widget.label,
          hintText: 'Select',
          items: _dropdownItems,
          selectedItem: _selected,
          showAsterisk: widget.isRequired,
          labelStyle: effectiveLabelStyle,
          labelBottomSpacing: widget.labelBottomSpacing,
          fieldHeight: widget.fieldHeight,
          contentPadding: widget.contentPadding,
          selectedTextStyle: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: responsive.inputFontSize,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryColor,
            height: 19 / 14,
          ),
          popupItemTextStyle: TextStyle(
            fontFamily: AppFonts.body,
            fontSize: responsive.inputFontSize,
            fontWeight: FontWeight.w400,
            color: AppColors.primaryColor,
          ),
          onSelect: (val) {
            setState(() {
              _userHasInteracted = true;
              _selected = val;
              if (!_isOtherSelected) {
                _customController.clear();
              }
            });
            _notify();
          },
        ),
        if (_isOtherSelected) ...[
          SizedBox(height: widget.spacing ?? responsive.verticalSpacing),
          _buildCustomField(responsive, effectiveLabelStyle),
        ],
      ],
    );
  }

  Widget _buildCustomField(ResponsiveHelper responsive, TextStyle labelStyle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: labelStyle,
            children: [
              TextSpan(text: widget.customFieldLabel),
              if (widget.isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: MaterialHues.red),
                ),
            ],
          ),
        ),
        SizedBox(
          height:
              widget.labelBottomSpacing ?? (responsive.isTablet ? 8.0 : 6.0),
        ),
        Container(
          constraints: BoxConstraints(
            minHeight: widget.fieldHeight ?? responsive.inputFieldHeight,
          ),
          decoration: AppSurfaces.well(radius: responsive.isTablet ? 12.0 : 8.0,),
          child: TextField(
            controller: _customController,
            textCapitalization: TextCapitalization.words,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z\s'-]")),
              LengthLimitingTextInputFormatter(50),
            ],
            onChanged: (_) {
              _userHasInteracted = true;
              _notify();
            },
            decoration: InputDecoration(
              hintText: widget.customFieldHint,
              hintStyle: labelStyle.copyWith(color: MaterialHues.grey500),
              border: InputBorder.none,
              contentPadding:
                  widget.contentPadding ??
                  EdgeInsets.symmetric(
                    horizontal: responsive.isTablet ? 16.0 : 12.0,
                    vertical: responsive.isTablet ? 16.0 : 12.0,
                  ),
            ),
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: responsive.inputFontSize,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
              height: 19 / 14,
            ),
          ),
        ),
      ],
    );
  }
}
