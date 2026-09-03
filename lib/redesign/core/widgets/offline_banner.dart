import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';

/// The navy strip across the top of a screen while the device is offline
/// (1a). A sun dot, then the line in warm white.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({this.message = AppStrings.offlineBanner, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return SurfaceBox(
      surface: AppSurfaces.banner(c),
      padding: AppSizes.bannerPad,
      child: Row(
        spacing: AppSizes.bannerGap,
        children: <Widget>[
          Container(
            width: AppSizes.toastDot,
            height: AppSizes.toastDot,
            decoration: BoxDecoration(shape: BoxShape.circle, color: c.staff),
          ),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bannerText.copyWith(color: c.onImpact),
            ),
          ),
        ],
      ),
    );
  }
}
