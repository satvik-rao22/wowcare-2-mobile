import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/field_label.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';

/// A well-backed text field. Components page `.field`, and 1a's sign-in.
///
/// The label sits above with a pink asterisk when [isRequired]; a help line
/// or an error line sits below. An error also draws the 1.5px danger border.
/// [leadingIcon] is the teal glyph 1a puts before the value; [obscureText]
/// adds the eye that toggles it. The Material `TextField` inside is
/// undecorated: the well is the decoration.
class AppTextField extends StatefulWidget {
  const AppTextField({
    this.label,
    this.isRequired = false,
    this.hintText,
    this.helpText,
    this.errorText,
    this.leadingIcon,
    this.leadingIconColor,
    this.trailing,
    this.obscureText = false,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.enabled = true,
    this.autofocus = false,
    this.maxLines = 1,
    this.padding = AppSizes.fieldPad,
    super.key,
  });

  final String? label;
  final bool isRequired;
  final String? hintText;
  final String? helpText;

  /// Set, the field draws the error recipe and this line in danger ink.
  final String? errorText;

  final IconData? leadingIcon;

  /// Defaults to the student teal, which is what 1a draws.
  final Color? leadingIconColor;

  /// A glyph or key at the end of the well. Ignored while [obscureText] is
  /// on, when the eye takes that slot.
  final Widget? trailing;

  final bool obscureText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final bool autofocus;
  final int? maxLines;
  final EdgeInsetsGeometry padding;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.obscureText;

  void _toggleObscured() => setState(() => _obscured = !_obscured);

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSizes.fieldGap,
      children: <Widget>[
        if (widget.label != null)
          FieldLabel(text: widget.label!, isRequired: widget.isRequired),
        SurfaceBox(
          surface: AppSurfaces.field(c, hasError: hasError),
          padding: widget.padding,
          child: Row(
            spacing: AppSizes.fieldIconGap,
            children: <Widget>[
              if (widget.leadingIcon != null)
                Icon(
                  widget.leadingIcon,
                  size: AppSizes.fieldIcon,
                  color: widget.leadingIconColor ?? c.student,
                ),
              Expanded(child: _input(c)),
              if (widget.obscureText)
                _EyeKey(obscured: _obscured, onTap: _toggleObscured)
              else if (widget.trailing != null)
                widget.trailing!,
            ],
          ),
        ),
        if (hasError)
          Text(
            widget.errorText!,
            style: AppTextStyles.fieldError.copyWith(color: c.dangerFg),
          )
        else if (widget.helpText != null)
          Text(
            widget.helpText!,
            style: AppTextStyles.fieldHelp.copyWith(color: c.ink3),
          ),
      ],
    );
  }

  Widget _input(Colourway c) => TextField(
    controller: widget.controller,
    focusNode: widget.focusNode,
    onChanged: widget.onChanged,
    onSubmitted: widget.onSubmitted,
    keyboardType: widget.keyboardType,
    textInputAction: widget.textInputAction,
    textCapitalization: widget.textCapitalization,
    inputFormatters: widget.inputFormatters,
    enabled: widget.enabled,
    autofocus: widget.autofocus,
    maxLines: widget.maxLines,
    obscureText: _obscured,
    cursorColor: c.pink,
    style: AppTextStyles.fieldText.copyWith(color: c.ink),
    decoration: InputDecoration.collapsed(
      hintText: widget.hintText,
      hintStyle: AppTextStyles.placeholder.copyWith(color: c.ink3),
    ),
  );
}

class _EyeKey extends StatelessWidget {
  const _EyeKey({required this.obscured, required this.onTap});

  final bool obscured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: obscured ? AppStrings.showPassword : AppStrings.hidePassword,
    child: Pressable.surface(
      onTap: onTap,
      child: Icon(
        obscured ? AppIcons.eye : AppIcons.eyeOff,
        size: AppSizes.fieldTrailingIcon,
        color: context.colours.ink3,
      ),
    ),
  );
}
