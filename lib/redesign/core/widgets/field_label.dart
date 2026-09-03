import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';

/// The label above a field, with its pink asterisk when the field is
/// required. Components page `.field__label`.
class FieldLabel extends StatelessWidget {
  const FieldLabel({required this.text, this.isRequired = false, super.key});

  final String text;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    return Text.rich(
      TextSpan(
        text: text,
        style: AppTextStyles.fieldLabel.copyWith(color: c.ink2),
        children: <InlineSpan>[
          if (isRequired)
            TextSpan(
              text: ' ${AppStrings.requiredMark}',
              style: TextStyle(color: c.pink),
            ),
        ],
      ),
    );
  }
}
