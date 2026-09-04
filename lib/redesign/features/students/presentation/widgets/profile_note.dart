import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/alt_well_tile.dart';
import 'package:wowcare/redesign/features/students/students_sizes.dart';
import 'package:wowcare/redesign/features/students/students_text_styles.dart';

/// The quiet note under a detail card on 5c, explaining a rule the fields
/// above it cannot say for themselves: who else may edit them, or what the
/// five dates are for.
class ProfileNote extends StatelessWidget {
  const ProfileNote({required this.title, required this.body, super.key});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AltWellTile(
      padding: StudentsSizes.notePad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSizes.rowTextGap,
        children: <Widget>[
          Text(title, style: AppTextStyles.subLine.copyWith(color: c.ink)),
          Text(body, style: StudentsTextStyles.itemSub.copyWith(color: c.ink2)),
        ],
      ),
    );
  }
}
