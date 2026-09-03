import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_sizes.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_text_styles.dart';
import 'package:wowcare/redesign/features/dashboard/models/models.dart';

/// A newsletter, on the guardian's dashboard (3P2).
class NewsletterCard extends StatelessWidget {
  const NewsletterCard({
    required this.newsletter,
    required this.onTap,
    super.key,
  });

  final NewsletterRow newsletter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppCard(
      onTap: onTap,
      child: Row(
        spacing: DashboardSizes.newsletterGap,
        children: <Widget>[
          SurfaceBox(
            surface: AppSurfaces.glyphTile(
              c,
              fill: c.studentBg,
              radius: DashboardSizes.newsletterIconTile / 2,
            ),
            width: DashboardSizes.newsletterIconTile,
            height: DashboardSizes.newsletterIconTile,
            alignment: Alignment.center,
            child: Icon(
              AppIcons.newsletter,
              size: DashboardSizes.newsletterGlyph,
              color: c.student,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  newsletter.title,
                  style: DashboardTextStyles.newsletterTitle.copyWith(
                    color: c.ink,
                  ),
                ),
                Text(
                  newsletter.meta,
                  style: DashboardTextStyles.invoiceSub.copyWith(
                    color: c.ink3,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            AppIcons.chevronRight,
            size: AppSizes.rowChevron,
            color: c.ink3,
          ),
        ],
      ),
    );
  }
}
