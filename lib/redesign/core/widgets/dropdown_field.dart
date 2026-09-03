import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/field_label.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';

/// A well that opens a picker. Components page `.dropdown`: a deeper well
/// than a field, a summary or placeholder, and a caret.
///
/// It does not pick anything itself. [onTap] opens a `SingleSelectSheet` or
/// `MultiSelectSheet`, and the caller writes the result back into [value].
class DropdownField extends StatelessWidget {
  const DropdownField({
    required this.onTap,
    this.label,
    this.isRequired = false,
    this.value,
    this.placeholder,
    this.helpText,
    this.errorText,
    this.leadingIcon,
    this.enabled = true,
    super.key,
  });

  final VoidCallback onTap;
  final String? label;
  final bool isRequired;

  /// What is picked, summarised. Null shows the [placeholder] in ink3.
  final String? value;

  final String? placeholder;
  final String? helpText;
  final String? errorText;
  final IconData? leadingIcon;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final hasError = errorText != null;
    final isEmpty = value == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSizes.fieldGap,
      children: <Widget>[
        if (label != null) FieldLabel(text: label!, isRequired: isRequired),
        Semantics(
          button: true,
          enabled: enabled,
          label: label,
          value: value ?? placeholder,
          child: Pressable.surface(
            onTap: enabled ? onTap : null,
            child: SurfaceBox(
              surface: hasError
                  ? AppSurfaces.field(c, hasError: true)
                  : AppSurfaces.well(c),
              padding: AppSizes.dropdownPad,
              child: Row(
                spacing: AppSizes.dropdownGap,
                children: <Widget>[
                  if (leadingIcon != null)
                    Icon(leadingIcon, size: AppSizes.fieldIcon, color: c.ink2),
                  Expanded(
                    child: Text(
                      value ?? placeholder ?? '',
                      style: AppTextStyles.fieldText.copyWith(
                        color: isEmpty ? c.ink3 : c.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    AppIcons.chevronDown,
                    size: AppSizes.caret,
                    color: c.ink3,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (hasError)
          Text(
            errorText!,
            style: AppTextStyles.fieldError.copyWith(color: c.dangerFg),
          )
        else if (helpText != null)
          Text(
            helpText!,
            style: AppTextStyles.fieldHelp.copyWith(color: c.ink3),
          ),
      ],
    );
  }
}
