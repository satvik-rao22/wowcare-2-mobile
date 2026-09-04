import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/features/students/presentation/widgets/dashed_outline_box.dart';
import 'package:wowcare/redesign/features/students/students_sizes.dart';
import 'package:wowcare/redesign/features/students/students_text_styles.dart';

/// The dashed row at the foot of a list that adds one more of whatever the
/// list holds: a parent, a pickup person, a document (5c, 5f).
///
/// It is pink because on those tabs it is the one action. The dash says it is
/// a place for something rather than something.
class DashedAddRow extends StatelessWidget {
  const DashedAddRow({required this.label, this.onTap, super.key});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      child: DashedOutlineBox(
        padding: StudentsSizes.dashedRowPad,
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: StudentsSizes.dashedRowGap,
          children: <Widget>[
            Icon(AppIcons.plus, size: StudentsSizes.dashedGlyph, color: c.pink),
            Text(
              label,
              style: StudentsTextStyles.actionLabel.copyWith(color: c.pink),
            ),
          ],
        ),
      ),
    );
  }
}
