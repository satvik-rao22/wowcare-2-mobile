import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/alt_well_tile.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/features/students/models/models.dart';
import 'package:wowcare/redesign/features/students/students_sizes.dart';
import 'package:wowcare/redesign/features/students/students_text_styles.dart';

/// A card of label-and-value rows with an Edit key in its corner: About,
/// Health, Physician, Exam and Dates on 5c.
///
/// One card shape for five tabs, because they are the same thing: a record's
/// fields, read.
class DetailFieldsCard extends StatelessWidget {
  const DetailFieldsCard({
    required this.title,
    required this.rows,
    this.onEdit,
    super.key,
  });

  final String title;
  final List<InfoRow> rows;

  /// Null hides the key, which is what a persona that may not write sees.
  final VoidCallback? onEdit;

  Color _ink(Colourway c, InfoTone tone) => switch (tone) {
    InfoTone.ink => c.ink,
    InfoTone.danger => c.dangerFg,
    InfoTone.success => c.successFg,
    InfoTone.muted => c.ink2,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: StudentsSizes.fieldsGap,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.cardTitle.copyWith(color: c.ink),
                ),
              ),
              if (onEdit != null)
                AltWellTile(
                  subtle: true,
                  radius: AppRadii.chip,
                  padding: StudentsSizes.smallKeyPad,
                  onTap: onEdit,
                  child: Text(
                    AppStrings.edit,
                    style: StudentsTextStyles.fieldKey.copyWith(color: c.ink),
                  ),
                ),
            ],
          ),
          for (final row in rows)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: StudentsSizes.fieldRowGap,
              children: <Widget>[
                SizedBox(
                  width: StudentsSizes.fieldLabelWidth,
                  child: Text(
                    row.label,
                    style: StudentsTextStyles.fieldKey.copyWith(color: c.ink3),
                  ),
                ),
                Expanded(
                  child: Text(
                    row.value,
                    textAlign: TextAlign.end,
                    style: StudentsTextStyles.fieldValue.copyWith(
                      color: _ink(c, row.tone),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
