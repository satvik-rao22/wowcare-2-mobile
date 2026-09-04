import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/secondary_key.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/attendance/attendance_sizes.dart';
import 'package:wowcare/redesign/features/attendance/attendance_text_styles.dart';

/// Nothing matched (4e): the well-backed glyph, what happened, and the two
/// ways out.
///
/// Core's `EmptyState` carries one key, because most empty states have one
/// thing to do. A search that found nobody has two: widen it, or drop the
/// filter that is hiding them.
class AttendanceEmptyCard extends StatelessWidget {
  const AttendanceEmptyCard({
    required this.icon,
    required this.title,
    required this.body,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;

  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppCard(
      padding: AttendanceSizes.emptyCardPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSizes.emptyGap,
        children: <Widget>[
          Center(
            child: SurfaceBox(
              surface: AppSurfaces.emptyIcon(c),
              width: AppSizes.emptyIcon,
              height: AppSizes.emptyIcon,
              alignment: Alignment.center,
              child: Icon(icon, size: AppSizes.emptyGlyph, color: c.ink3),
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AttendanceTextStyles.edgeTitle.copyWith(color: c.ink),
          ),
          Text(
            body,
            textAlign: TextAlign.center,
            style: AttendanceTextStyles.edgeBody.copyWith(color: c.ink2),
          ),
          if (primaryLabel != null || secondaryLabel != null)
            Row(
              spacing: AttendanceSizes.edgeKeyGap,
              children: <Widget>[
                if (primaryLabel != null)
                  Expanded(
                    child: PrimaryKey(label: primaryLabel!, onTap: onPrimary),
                  ),
                if (secondaryLabel != null)
                  Expanded(
                    child: SecondaryKey(
                      label: secondaryLabel!,
                      onTap: onSecondary,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
