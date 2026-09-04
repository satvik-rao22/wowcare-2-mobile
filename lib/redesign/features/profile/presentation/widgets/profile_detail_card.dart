import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/features/profile/models/models.dart';
import 'package:wowcare/redesign/features/profile/presentation/widgets/value_field.dart';
import 'package:wowcare/redesign/features/profile/profile_sizes.dart';
import 'package:wowcare/redesign/features/profile/profile_strings.dart';

/// Name, email, phone and address, read-only. 13a and 13c draw the same card.
///
/// Email carries the "Cannot be edited" tag rather than being left out: it is
/// the sign-in, and knowing what it is matters more than a tidier card.
class ProfileDetailCard extends StatelessWidget {
  const ProfileDetailCard({required this.record, super.key});

  final ProfileRecord record;

  @override
  Widget build(BuildContext context) {
    final address = record.address;
    final lines = <String>[
      address.streetLine,
      address.localityLine,
    ].where((l) => l.isNotEmpty).join('\n');

    return AppCard(
      padding: ProfileSizes.detailCardPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: ProfileSizes.detailGap,
        children: <Widget>[
          ValueField(label: ProfileStrings.name, value: record.fullName),
          ValueField(
            label: ProfileStrings.email,
            value: record.email,
            isLocked: true,
            showLockTag: true,
          ),
          ValueField(label: ProfileStrings.phoneNumber, value: record.phone),
          ValueField(label: ProfileStrings.address, value: lines),
        ],
      ),
    );
  }
}
