import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/app_avatar.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/secondary_key.dart';
import 'package:wowcare/redesign/core/widgets/status_pill.dart';
import 'package:wowcare/redesign/features/students/models/models.dart';
import 'package:wowcare/redesign/features/students/students_sizes.dart';
import 'package:wowcare/redesign/features/students/students_text_styles.dart';

/// A parent, guardian or pickup contact on a student's record (5c Family and
/// Pickup).
///
/// The badge is what makes this person different from the others: called
/// first, allowed on Fridays, or a pass that has run out. The two keys are
/// what you would want to do about them.
class PersonCard extends StatelessWidget {
  const PersonCard({
    required this.person,
    required this.actionLabel,
    this.onAction,
    this.onEdit,
    super.key,
  });

  final StudentPerson person;

  /// "Message" for a guardian, "Call" or "Renew" for a pickup contact.
  final String actionLabel;

  final VoidCallback? onAction;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppCard(
      padding: StudentsSizes.personCardPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: StudentsSizes.fieldsGap,
        children: <Widget>[
          Row(
            spacing: AppSizes.rowGap,
            children: <Widget>[
              AppAvatar(
                initials: person.initials,
                tone: person.kind == PersonKind.guardian
                    ? AvatarTone.neutral
                    : AvatarTone.student,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSizes.rowTextGap,
                  children: <Widget>[
                    Text(
                      person.name,
                      style: AppTextStyles.rowName.copyWith(color: c.ink),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      person.relation,
                      style: AppTextStyles.rowSub.copyWith(color: c.ink3),
                    ),
                  ],
                ),
              ),
              if (person.badge != null)
                StatusPill(
                  label: person.badge!,
                  tone: switch (person.badgeTone) {
                    PersonBadgeTone.emergency => PillTone.danger,
                    PersonBadgeTone.arrangement => PillTone.student,
                    PersonBadgeTone.lapsed => PillTone.neutral,
                  },
                  small: true,
                ),
            ],
          ),
          Container(height: AppSizes.hairline, color: c.divider),
          for (final row in person.rows)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: StudentsSizes.fieldRowGap,
              children: <Widget>[
                Text(
                  row.label,
                  style: StudentsTextStyles.fieldKey.copyWith(color: c.ink3),
                ),
                Flexible(
                  child: Text(
                    row.value,
                    textAlign: TextAlign.end,
                    style: StudentsTextStyles.detailValue.copyWith(
                      color: row.tone == InfoTone.muted ? c.ink3 : c.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          Row(
            spacing: StudentsSizes.detailKeyGap,
            children: <Widget>[
              Expanded(
                child: SecondaryKey(
                  label: actionLabel,
                  padding: StudentsSizes.personKeyPad,
                  onTap: onAction,
                ),
              ),
              Expanded(
                child: SecondaryKey(
                  label: AppStrings.edit,
                  padding: StudentsSizes.personKeyPad,
                  onTap: onEdit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
