import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/widgets/counting_tile.dart';
import 'package:wowcare/redesign/features/staff/staff_sizes.dart';
import 'package:wowcare/redesign/features/staff/staff_strings.dart';

/// The two figures over the roster (6a): how many staff are on the books, and
/// how many have been hired but have not started.
///
/// The active tile is sun-tinted because staff are sun; "Starting soon" is a
/// plain card face, because a hire who has not arrived is not yet part of the
/// team the tint stands for.
class StaffCounts extends StatelessWidget {
  const StaffCounts({
    required this.activeCount,
    required this.upcomingCount,
    super.key,
  });

  final int activeCount;
  final int upcomingCount;

  @override
  Widget build(BuildContext context) => Row(
    spacing: StaffSizes.countsGap,
    children: <Widget>[
      Expanded(
        child: CountingTile(
          value: '$activeCount',
          label: StaffStrings.activeStaff,
          tone: TileTone.staff,
        ),
      ),
      Expanded(
        child: CountingTile(
          value: '$upcomingCount',
          label: StaffStrings.startingSoon,
        ),
      ),
    ],
  );
}
