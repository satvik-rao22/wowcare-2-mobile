import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/core/widgets/text_link.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_sizes.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_strings.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_text_styles.dart';
import 'package:wowcare/redesign/features/dashboard/models/models.dart';

/// What a student has done today, four counts wide (3P1).
///
/// Counts rather than a feed: the feed is Activities, and this is the line
/// that sends a guardian there.
class ChildActivitiesCard extends StatelessWidget {
  const ChildActivitiesCard({
    required this.firstName,
    required this.tally,
    required this.onSeeAll,
    super.key,
  });

  final String firstName;
  final ActivityTally tally;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: DashboardSizes.activityGap,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  DashboardStrings.childActivities(firstName),
                  style: AppTextStyles.cardTitle.copyWith(color: c.ink),
                ),
              ),
              TextLink(
                label: DashboardStrings.seeAll,
                color: c.student,
                onTap: onSeeAll,
              ),
            ],
          ),
          if (tally.isEmpty)
            Text(
              DashboardStrings.noActivitiesYet,
              style: AppTextStyles.subLine.copyWith(color: c.ink3),
            )
          else
            Row(
              spacing: DashboardSizes.activityGap,
              children: <Widget>[
                Expanded(
                  child: _Tile(
                    icon: AppIcons.clock,
                    label: DashboardStrings.nap,
                    value: tally.napStartedLabel == null
                        ? AppStrings.notMarked
                        : DashboardStrings.startedAt(tally.napStartedLabel!),
                  ),
                ),
                Expanded(
                  child: _Tile(
                    icon: AppIcons.activities,
                    label: DashboardStrings.meals,
                    value: DashboardStrings.logged(tally.meals),
                  ),
                ),
                Expanded(
                  child: _Tile(
                    icon: AppIcons.image,
                    label: DashboardStrings.photos,
                    value: DashboardStrings.todayCount(tally.photos),
                  ),
                ),
                Expanded(
                  child: _Tile(
                    icon: AppIcons.checkCircle,
                    label: DashboardStrings.bathroom,
                    value: '${tally.bathroom}',
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Column(
      spacing: DashboardSizes.activityTextGap,
      children: <Widget>[
        SurfaceBox(
          surface: AppSurfaces.glyphTile(
            c,
            fill: c.studentBg,
            radius: DashboardSizes.activityCircle / 2,
          ),
          width: DashboardSizes.activityCircle,
          height: DashboardSizes.activityCircle,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: DashboardSizes.activityGlyph,
            color: c.student,
          ),
        ),
        Text(
          label,
          style: DashboardTextStyles.activityLabel.copyWith(color: c.ink),
        ),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: DashboardTextStyles.reminderSub.copyWith(color: c.ink3),
        ),
      ],
    );
  }
}
