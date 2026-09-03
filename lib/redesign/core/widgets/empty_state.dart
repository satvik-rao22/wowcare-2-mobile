import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';

/// Nothing here yet. Components page `.empty`: a 64px well-backed glyph, a
/// title, an optional line under it, and one key only, the pink one.
///
/// The icon is a well rather than a card because there is nothing to press.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    super.key,
  }) : assert(
         (actionLabel == null) == (onAction == null),
         'An action needs both a label and a handler.',
       );

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Defaults to ink3.
  final Color? iconColor;

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
          child: Icon(
            icon,
            size: AppSizes.emptyGlyph,
            color: iconColor ?? c.ink3,
          ),
        ),
        Text(
          title,
          style: AppTextStyles.cardTitle.copyWith(color: c.ink),
          textAlign: TextAlign.center,
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: AppTextStyles.subLine.copyWith(color: c.ink3),
            textAlign: TextAlign.center,
          ),
        if (actionLabel != null)
          PrimaryKey(label: actionLabel!, onTap: onAction, expand: false),
      ],
    );
  }
}
