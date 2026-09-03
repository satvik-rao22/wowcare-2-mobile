import 'package:flutter/material.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_motion.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';

/// Opens [builder]'s widget as a bottom sheet over the dimmed screen.
///
/// The Material sheet is stripped to a transparent host: the scrim colour,
/// the sub ground, the 28px top radius and the safe-area pad are all drawn by
/// [AppBottomSheet]. The sheet is scroll-controlled so it can grow to the
/// content, and it lifts clear of the keyboard.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isDismissible = true,
}) => showModalBottomSheet<T>(
  context: context,
  backgroundColor: Colors.transparent,
  barrierColor: context.colours.scrim,
  elevation: 0,
  shape: const RoundedRectangleBorder(),
  clipBehavior: Clip.none,
  isScrollControlled: true,
  isDismissible: isDismissible,
  enableDrag: isDismissible,
  sheetAnimationStyle: const AnimationStyle(
    duration: AppMotion.panel,
    curve: AppMotion.ease,
  ),
  builder: (context) => Padding(
    padding: EdgeInsets.only(bottom: context.keyboardInset),
    child: builder(context),
  ),
);

/// The sheet itself. Components page `.sheet`: a grabber, a `detailTitle`,
/// an optional subtitle, the body, and an optional docked row of keys.
///
/// The body is [Flexible], so a long list inside it scrolls within the sheet
/// while a short one lets the sheet hug its content.
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    required this.body,
    this.title,
    this.subtitle,
    this.header,
    this.footer,
    this.showGrabber = true,
    super.key,
  }) : assert(
         title == null || header == null,
         'Pass a title or a custom header, not both.',
       );

  final Widget body;
  final String? title;
  final String? subtitle;

  /// Replaces the title block with something richer (5a's avatar header).
  final Widget? header;

  /// Keys docked under the body, laid out in one row of equals.
  final List<Widget>? footer;

  final bool showGrabber;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final maxHeight =
        context.screenHeight -
        context.safeArea.top -
        AppSizes.sheetTopClearance;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SurfaceBox(
        surface: AppSurfaces.sheet(c),
        padding: AppSizes.sheetPad.copyWith(
          bottom: AppSizes.sheetPad.bottom + context.safeArea.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSizes.sheetGap,
          children: <Widget>[
            if (showGrabber) const _Grabber(),
            ?header,
            if (title != null) _titleBlock(c),
            Flexible(child: body),
            if (footer != null && footer!.isNotEmpty) _footerRow(),
          ],
        ),
      ),
    );
  }

  Widget _titleBlock(Colourway c) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: AppSizes.rowTextGap,
    children: <Widget>[
      Text(title!, style: AppTextStyles.detailTitle.copyWith(color: c.ink)),
      if (subtitle != null)
        Text(subtitle!, style: AppTextStyles.subLine.copyWith(color: c.ink2)),
    ],
  );

  Widget _footerRow() => Padding(
    padding: const EdgeInsets.only(top: AppSizes.sheetFooterTopPad),
    child: Row(
      spacing: AppSizes.sheetFooterGap,
      children: <Widget>[for (final key in footer!) Expanded(child: key)],
    ),
  );
}

class _Grabber extends StatelessWidget {
  const _Grabber();

  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: AppSizes.grabberWidth,
      height: AppSizes.grabberHeight,
      decoration: BoxDecoration(
        color: context.colours.grabber,
        borderRadius: AppRadii.grabberR,
      ),
    ),
  );
}
