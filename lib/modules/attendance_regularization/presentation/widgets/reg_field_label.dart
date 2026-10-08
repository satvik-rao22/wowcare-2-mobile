import 'package:flutter/material.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_colors.dart';
import 'package:wowcare/modules/attendance_v2/core/theme/av2_text_styles.dart';

/// A form field's label, with the app's required marker.
///
/// The marker is a red `*` appended to the label, matching `CustomDropdown`,
/// `CustomDateTimeField` and every other form field in the app. The module
/// used to spell out "(required)", which read as a different convention on a
/// screen users reach from the same forms.
///
/// No marker means optional, so a field that cannot be left blank (a
/// pre-filled time) deliberately carries none — a `*` there would promise an
/// empty state that does not exist.
class RegFieldLabel extends StatelessWidget {
  const RegFieldLabel(this.text, {super.key, this.isRequired = false});

  final String text;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: Av2Text.bodyMedium,
        children: [
          TextSpan(text: text),
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Av2Colors.danger),
            ),
        ],
      ),
    );
  }
}
