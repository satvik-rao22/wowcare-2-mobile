import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/app_checkbox.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';

/// A row with a checkbox: one line of a multi-select sheet.
class CheckRow extends StatelessWidget {
  const CheckRow({
    required this.label,
    required this.checked,
    required this.onChanged,
    this.subtitle,
    this.padding = AppSizes.rowPad,
    super.key,
  });

  final String label;
  final String? subtitle;
  final bool checked;
  final ValueChanged<bool> onChanged;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Semantics(
      checked: checked,
      label: label,
      child: Pressable.surface(
        onTap: () => onChanged(!checked),
        child: Padding(
          padding: padding,
          child: Row(
            spacing: AppSizes.rowGap,
            children: <Widget>[
              AppCheckbox(checked: checked),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSizes.rowTextGap,
                  children: <Widget>[
                    Text(
                      label,
                      style: AppTextStyles.rowName.copyWith(color: c.ink),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: AppTextStyles.rowSub.copyWith(color: c.ink3),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
