import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'skeu_press.dart';
import 'skeu_surface.dart';
import 'skeu_tokens.dart';

/// A text input sunk into the page.
///
/// Anything you type into is a recessed well (`--well-md` on `--surface-field`)
/// with a teal leading glyph, so an editable field is distinguishable from a
/// raised, pressable one at a glance. Focus adds the teal ring; a validation
/// message swaps it for the danger ring and prints below the well, outside it,
/// so the well never changes height as you type.
class SkeuTextField extends StatefulWidget {
  const SkeuTextField({
    this.controller,
    this.label,
    this.hintText,
    this.icon,
    this.suffix,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.inputFormatters,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.required = false,
    this.showDivider = false,
    this.radius = SkeuRadius.lg,
    this.focusNode,
    this.onTap,
    super.key,
  });

  final TextEditingController? controller;

  /// Rendered above the well as a small heading, with a pink asterisk when
  /// [required] — matching the app's existing required-field convention.
  final String? label;
  final String? hintText;
  final IconData? icon;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final bool readOnly;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final TextCapitalization textCapitalization;
  final bool required;

  /// The hairline rule between the glyph and the value, used on the auth
  /// screens' single-purpose fields.
  final bool showDivider;
  final double radius;
  final FocusNode? focusNode;
  final VoidCallback? onTap;

  @override
  State<SkeuTextField> createState() => _SkeuTextFieldState();
}

class _SkeuTextFieldState extends State<SkeuTextField> {
  FocusNode? _ownNode;
  FocusNode get _node => widget.focusNode ?? (_ownNode ??= FocusNode());
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocus);
  }

  void _onFocus() {
    if (mounted && _focused != _node.hasFocus) {
      setState(() => _focused = _node.hasFocus);
    }
  }

  @override
  void dispose() {
    _node.removeListener(_onFocus);
    _ownNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final multiline = (widget.maxLines ?? 1) > 1;
    return FormField<String>(
      initialValue: widget.controller?.text ?? '',
      validator: widget.validator,
      builder: (state) {
        final hasError = state.hasError;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.label != null) ...[
              SkeuFieldLabel(widget.label!, required: widget.required),
              const SizedBox(height: 8),
            ],
            SkeuWell(
              radius: widget.radius,
              focused: _focused && !hasError,
              error: hasError,
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: multiline ? 12 : 15,
              ),
              child: Row(
                crossAxisAlignment: multiline
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      size: 20,
                      color: hasError
                          ? SkeuColors.danger500
                          : SkeuColors.teal600,
                    ),
                    SizedBox(width: widget.showDivider ? 12 : 12),
                    if (widget.showDivider) ...[
                      Container(
                        width: 1,
                        height: 26,
                        color: SkeuColors.borderHairline,
                      ),
                      const SizedBox(width: 12),
                    ],
                  ],
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _node,
                      obscureText: widget.obscureText,
                      enabled: widget.enabled,
                      readOnly: widget.readOnly,
                      onTap: widget.onTap,
                      maxLines: widget.maxLines,
                      minLines: widget.minLines,
                      maxLength: widget.maxLength,
                      keyboardType: widget.keyboardType,
                      textInputAction: widget.textInputAction,
                      inputFormatters: widget.inputFormatters,
                      autofillHints: widget.autofillHints,
                      textCapitalization: widget.textCapitalization,
                      cursorColor: SkeuColors.teal600,
                      style: SkeuText.field(),
                      onChanged: (v) {
                        state.didChange(v);
                        widget.onChanged?.call(v);
                      },
                      onSubmitted: widget.onSubmitted,
                      decoration: InputDecoration(
                        isDense: true,
                        counterText: '',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        hintText: widget.hintText,
                        hintStyle: SkeuText.field(color: SkeuColors.inkFaint),
                      ),
                    ),
                  ),
                  if (widget.suffix != null) ...[
                    const SizedBox(width: 10),
                    widget.suffix!,
                  ],
                ],
              ),
            ),
            if (hasError) SkeuFieldError(state.errorText!),
          ],
        );
      },
    );
  }
}

/// The small heading above a field. A pink asterisk marks a required field,
/// the app's existing convention carried into the new language.
class SkeuFieldLabel extends StatelessWidget {
  const SkeuFieldLabel(this.label, {this.required = false, super.key});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      text: label,
      style: SkeuText.small(
        color: SkeuColors.inkSoft,
        weight: SkeuText.weightHeading,
      ),
      children: required
          ? [
              TextSpan(
                text: ' *',
                style: SkeuText.small(
                  color: SkeuColors.pink600,
                  weight: SkeuText.weightBold,
                ),
              ),
            ]
          : null,
    ),
  );
}

/// A validation message. Danger red, never brand pink: pink means "recommended
/// action" and must never double as a warning.
class SkeuFieldError extends StatelessWidget {
  const SkeuFieldError(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, top: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          size: 14,
          color: SkeuColors.danger600,
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            message,
            style: SkeuText.caption(color: SkeuColors.danger600),
          ),
        ),
      ],
    ),
  );
}

/// A field that opens a picker rather than a keyboard. Same well as
/// [SkeuTextField] so the two read as one family, with a chevron that flips
/// while the list below is open.
class SkeuSelectField extends StatelessWidget {
  const SkeuSelectField({
    required this.value,
    this.hintText,
    this.label,
    this.icon,
    this.onTap,
    this.isOpen = false,
    this.enabled = true,
    this.required = false,
    this.errorText,
    this.radius = SkeuRadius.lg,
    super.key,
  });

  final String? value;
  final String? hintText;
  final String? label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isOpen;
  final bool enabled;
  final bool required;
  final String? errorText;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    final hasError = errorText != null && errorText!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          SkeuFieldLabel(label!, required: required),
          const SizedBox(height: 8),
        ],
        Opacity(
          opacity: enabled ? 1 : .55,
          child: SkeuWell(
            radius: radius,
            error: hasError,
            onTap: enabled ? onTap : null,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 20,
                    color: hasValue ? SkeuColors.ink : SkeuColors.inkFaint,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    hasValue ? value! : (hintText ?? ''),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SkeuText.field(
                      color: hasValue ? SkeuColors.ink : SkeuColors.inkFaint,
                      weight: hasValue
                          ? SkeuText.weightHeading
                          : SkeuText.weightBody,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: isOpen ? .5 : 0,
                  duration: SkeuMotion.quick,
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 22,
                    color: SkeuColors.inkFaint,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasError) SkeuFieldError(errorText!),
      ],
    );
  }
}

/// The list a [SkeuSelectField] opens into: a raised panel floating above the
/// page (`--elev-3`), holding one tappable row per option.
class SkeuOptionList extends StatelessWidget {
  const SkeuOptionList({
    required this.children,
    this.padding = const EdgeInsets.all(8),
    super.key,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => SkeuPanel(
    radius: 20,
    shadows: SkeuElevation.elev3,
    padding: padding,
    child: Column(mainAxisSize: MainAxisSize.min, children: children),
  );
}

/// One row of a [SkeuOptionList]. Selected rows sink into a soft pink wash and
/// gain a check, so selection reads as state rather than as a highlight.
class SkeuOptionRow extends StatelessWidget {
  const SkeuOptionRow({
    required this.label,
    this.subtitle,
    this.leading,
    this.selected = false,
    this.onTap,
    super.key,
  });

  final String label;
  final String? subtitle;
  final Widget? leading;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SkeuPressable.surface(
    onTap: onTap,
    child: AnimatedContainer(
      duration: SkeuMotion.quick,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        gradient: selected ? SkeuSurfaces.pinkSoft : null,
        borderRadius: BorderRadius.circular(SkeuRadius.md),
      ),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 12)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: SkeuText.body(
                    color: selected ? SkeuColors.pink700 : SkeuColors.ink,
                    weight: SkeuText.weightHeading,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: SkeuText.caption()),
                ],
              ],
            ),
          ),
          if (selected)
            const Icon(
              Icons.check_rounded,
              size: 17,
              color: SkeuColors.pink700,
            ),
        ],
      ),
    ),
  );
}

/// A search well — the recessed trough a query is typed into. Distinct from
/// [SkeuTextField] only in its pill shape and magnifier glyph.
class SkeuSearchField extends StatelessWidget {
  const SkeuSearchField({
    this.controller,
    this.hintText = 'Search',
    this.onChanged,
    this.onClear,
    this.focusNode,
    super.key,
  });

  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) => SkeuWell(
    radius: SkeuRadius.pill,
    insets: SkeuElevation.wellSm,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
    child: Row(
      children: [
        const Icon(Icons.search_rounded, size: 19, color: SkeuColors.inkFaint),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            cursorColor: SkeuColors.teal600,
            style: SkeuText.body(),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintText: hintText,
              hintStyle: SkeuText.body(color: SkeuColors.inkFaint),
            ),
          ),
        ),
        if ((controller?.text.isNotEmpty ?? false) && onClear != null)
          SkeuPressable.surface(
            onTap: onClear,
            child: const Icon(
              Icons.close_rounded,
              size: 18,
              color: SkeuColors.inkFaint,
            ),
          ),
      ],
    ),
  );
}

/// A checkbox as a physical object: a small well that fills with a pink face
/// and a check when it is on.
class SkeuCheckbox extends StatelessWidget {
  const SkeuCheckbox({
    required this.value,
    this.onChanged,
    this.size = 24,
    super.key,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final double size;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(8);
    return SkeuPressable.surface(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: AnimatedContainer(
        duration: SkeuMotion.quick,
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: value ? SkeuSurfaces.facePink : SkeuSurfaces.field,
          borderRadius: br,
          boxShadow: value
              ? [
                  const BoxShadow(
                    color: SkeuColors.pink800,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: value
            ? Icon(Icons.check_rounded, size: size * .68, color: Colors.white)
            : SkeuWell(
                radius: 8,
                insets: SkeuElevation.wellSm,
                child: const SizedBox.expand(),
              ),
      ),
    );
  }
}

/// A physical toggle: a recessed track with a raised knob that slides in it.
class SkeuSwitch extends StatelessWidget {
  /// Flat pass: the off track is one flat colour, like every other surface.
  static const _offTrack = LinearGradient(
    colors: [SkeuColors.cream200, SkeuColors.cream200],
  );

  const SkeuSwitch({
    required this.value,
    this.onChanged,
    this.width = 46,
    this.height = 26,
    super.key,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onChanged == null ? null : () => onChanged!(!value),
    child: SkeuWell(
      radius: SkeuRadius.pill,
      width: width,
      height: height,
      gradient: value ? SkeuSurfaces.faceTeal : _offTrack,
      insets: SkeuElevation.wellSm,
      child: AnimatedAlign(
        duration: SkeuMotion.quick,
        curve: SkeuMotion.easeOut,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Container(
            width: height - 6,
            height: height - 6,
            decoration: BoxDecoration(
              gradient: SkeuSurfaces.faceNeutral,
              shape: BoxShape.circle,
              boxShadow: SkeuElevation.elev2,
              border: Border.all(color: SkeuColors.borderHairline),
            ),
          ),
        ),
      ),
    ),
  );
}
