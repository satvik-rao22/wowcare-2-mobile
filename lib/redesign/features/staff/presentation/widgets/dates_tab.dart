import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/features/staff/models/models.dart';
import 'package:wowcare/redesign/features/staff/presentation/widgets/fact_card.dart';
import 'package:wowcare/redesign/features/staff/staff_sizes.dart';
import 'package:wowcare/redesign/features/staff/staff_strings.dart';
import 'package:wowcare/redesign/features/staff/staff_text_styles.dart';

/// 6c's Dates tab: the five dates a center keeps, under a dashed panel that
/// says what they are before the values do.
///
/// First aid is the one that can lapse, so an expired one is the only value
/// on the card that goes red.
class DatesTab extends StatelessWidget {
  const DatesTab({required this.profile, super.key});

  final StaffProfile profile;

  @override
  Widget build(BuildContext context) {
    final dates = profile.dates;
    final today = profile.asOf;
    final firstAidExpired = today != null && dates.isFirstAidExpired(today);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: StaffSizes.sectionGap,
      children: <Widget>[
        const _StructurePanel(),
        FactCard(
          facts: <StaffFact>[
            StaffFact(StaffStrings.hireDate, _value(dates.hireDate)),
            StaffFact(StaffStrings.cdaExam, _value(dates.cdaExamDate)),
            StaffFact(
              StaffStrings.backgroundCheck,
              _value(dates.backgroundCheckDate),
            ),
            StaffFact(
              StaffStrings.firstAidExpiry,
              _value(dates.firstAidExpiry),
              tone: firstAidExpired ? StaffFactTone.bad : StaffFactTone.plain,
            ),
            StaffFact(
              StaffStrings.physicalCheckup,
              _value(dates.physicalCheckupDate),
            ),
          ],
        ),
      ],
    );
  }

  static String _value(DateTime? date) =>
      date == null ? StaffStrings.notRecorded : StaffStrings.date(date);
}

/// The dashed panel over the dates: what this tab is, before it is anything.
class _StructurePanel extends StatelessWidget {
  const _StructurePanel();

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Container(
      padding: StaffSizes.structurePad,
      decoration: BoxDecoration(
        color: c.neutralBg,
        borderRadius: AppRadii.cardR,
        border: Border.all(color: c.dashedLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: StaffSizes.noteGap,
        children: <Widget>[
          Text(
            StaffStrings.datesOnRecord.toUpperCase(),
            style: StaffTextStyles.structureEyebrow.copyWith(color: c.ink2),
          ),
          Text(
            StaffStrings.datesOnRecordBody,
            style: StaffTextStyles.structureBody.copyWith(color: c.ink2),
          ),
        ],
      ),
    );
  }
}
