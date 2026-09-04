import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/features/staff/models/models.dart';
import 'package:wowcare/redesign/features/staff/presentation/widgets/fact_card.dart';
import 'package:wowcare/redesign/features/staff/presentation/widgets/note_well.dart';
import 'package:wowcare/redesign/features/staff/staff_sizes.dart';
import 'package:wowcare/redesign/features/staff/staff_strings.dart';

/// 6c's Profile tab: the record, and a note saying which half of it belongs
/// to the person it is about.
///
/// The Sign-In PIN is on this card and nowhere else, read only. The PIN
/// endpoint is a read, so the app shows it and never offers to change it.
class ProfileTab extends StatelessWidget {
  const ProfileTab({
    required this.profile,
    required this.showDetails,
    this.onEdit,
    super.key,
  });

  final StaffProfile profile;

  /// A colleague's record stops at the designation and the classroom. Phone
  /// numbers, addresses and PINs are private to each person.
  final bool showDetails;

  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final member = profile.member;
    final age = profile.age;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: StaffSizes.sectionGap,
      children: <Widget>[
        FactCard(
          title: member.name,
          actionLabel: onEdit == null ? null : AppStrings.edit,
          onAction: onEdit,
          facts: <StaffFact>[
            StaffFact(StaffStrings.status, _statusLine(member)),
            StaffFact(StaffStrings.designation, member.designation),
            StaffFact(StaffStrings.role, StaffStrings.roleLabel(member.role)),
            StaffFact(
              StaffStrings.primaryClassroom,
              StaffStrings.scopeOf(member),
            ),
            StaffFact(
              StaffStrings.allowedClassrooms,
              member.allowedClassrooms.isEmpty
                  ? StaffStrings.allClassrooms
                  : member.allowedClassrooms.join(', '),
            ),
            if (showDetails) ...<StaffFact>[
              StaffFact(StaffStrings.signInPin, member.signInPin),
              StaffFact(
                StaffStrings.email,
                member.email,
                tone: StaffFactTone.quiet,
              ),
              StaffFact(StaffStrings.phone, member.phone),
              StaffFact(
                StaffStrings.address,
                profile.address.isEmpty
                    ? StaffStrings.notRecorded
                    : profile.address.formatted,
              ),
              StaffFact(
                StaffStrings.birthDate,
                profile.birthDate == null || age == null
                    ? StaffStrings.notRecorded
                    : StaffStrings.birthDateWithAge(
                        StaffStrings.date(profile.birthDate!),
                        age,
                      ),
              ),
            ],
            StaffFact(
              StaffStrings.jobTag,
              member.jobTags.isEmpty
                  ? StaffStrings.notRecorded
                  : member.jobTags.join(', '),
            ),
          ],
        ),
        if (showDetails)
          NoteWell(
            title: StaffStrings.whatCanChange(member.firstName),
            body: StaffStrings.whatCanChangeBody,
          ),
      ],
    );
  }

  static String _statusLine(StaffMember member) {
    final since = member.since;
    if (since == null) return StaffStrings.statusLabel(member.status);
    final date = StaffStrings.date(since);
    return switch (member.status) {
      StaffStatus.active => StaffStrings.activeSince(date),
      StaffStatus.upcoming => StaffStrings.startsOn(date),
      StaffStatus.inactive => StaffStrings.inactiveSince(date),
    };
  }
}
