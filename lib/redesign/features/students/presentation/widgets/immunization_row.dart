import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/status_pill.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/students/models/models.dart';
import 'package:wowcare/redesign/features/students/students_sizes.dart';
import 'package:wowcare/redesign/features/students/students_text_styles.dart';

/// One vaccine dose on a student's record (5c Health · Immunization).
///
/// The due date, the status and the exemption reason are all already
/// returned by the call the overdue line reads, so the whole tab costs
/// nothing beyond drawing it.
class ImmunizationRow extends StatelessWidget {
  const ImmunizationRow({required this.record, super.key});

  final ImmunizationRecord record;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return SurfaceBox(
      surface: AppSurfaces.keySecondary(c),
      padding: StudentsSizes.itemRowPad,
      child: Row(
        spacing: AppSizes.rowGap,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSizes.rowTextGap,
              children: <Widget>[
                Text(
                  record.name,
                  style: StudentsTextStyles.itemTitle.copyWith(color: c.ink),
                ),
                Text(
                  record.detail,
                  style: StudentsTextStyles.footnote.copyWith(color: c.ink3),
                ),
              ],
            ),
          ),
          StatusPill(
            label: record.status.label,
            tone: switch (record.status) {
              ImmunizationStatus.completed => PillTone.success,
              ImmunizationStatus.due => PillTone.staff,
              ImmunizationStatus.overdue => PillTone.danger,
              ImmunizationStatus.exempt => PillTone.neutral,
            },
            small: true,
          ),
        ],
      ),
    );
  }
}
