import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/secondary_key.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';

/// Something went wrong. Same shape as `EmptyState`, with a danger glyph and
/// a secondary Try again key: recovering is not the screen's one action.
class ErrorState extends StatelessWidget {
  const ErrorState({
    this.title = AppStrings.somethingWentWrong,
    this.message,
    this.onRetry,
    this.retryLabel = AppStrings.retry,
    this.icon = AppIcons.alertTriangle,
    super.key,
  });

  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSizes.emptyGap,
      children: <Widget>[
        SurfaceBox(
          surface: AppSurfaces.emptyIcon(c),
          width: AppSizes.emptyIcon,
          height: AppSizes.emptyIcon,
          alignment: Alignment.center,
          child: Icon(icon, size: AppSizes.emptyGlyph, color: c.dangerFg),
        ),
        Text(
          title,
          style: AppTextStyles.cardTitle.copyWith(color: c.ink),
          textAlign: TextAlign.center,
        ),
        if (message != null)
          Text(
            message!,
            style: AppTextStyles.subLine.copyWith(color: c.ink3),
            textAlign: TextAlign.center,
          ),
        if (onRetry != null)
          SecondaryKey(
            label: retryLabel,
            icon: AppIcons.refresh,
            onTap: onRetry,
            expand: false,
          ),
      ],
    );
  }
}
