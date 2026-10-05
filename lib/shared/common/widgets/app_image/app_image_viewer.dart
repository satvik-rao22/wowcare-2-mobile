import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';

import 'app_image.dart';

/// Full-screen, pinch-to-zoom viewer for any [AppImage] source.
///
/// Uses [InteractiveViewer] rather than `photo_view` so SVG and Lottie zoom the
/// same way rasters do.
class AppImageViewer extends StatelessWidget {
  const AppImageViewer({super.key, required this.source, this.heroTag});

  final AppImageSource source;
  final Object? heroTag;

  /// Pushed on the root navigator so it covers the go_router shell's bottom
  /// navigation bar.
  static Future<void> open(
    BuildContext context,
    AppImageSource source, {
    Object? heroTag,
  }) {
    return Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: AppPalette.scrim,
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, _, _) =>
            AppImageViewer(source: source, heroTag: heroTag),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // No width/height: the viewer must decode at full resolution so zooming
    // stays sharp, and the size-based decode hint in AppImage switches off.
    Widget image = AppImage(source: source, fit: BoxFit.contain);
    if (heroTag != null) image = Hero(tag: heroTag!, child: image);

    return Scaffold(
      backgroundColor: AppPalette.scrim,
      body: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Center(child: image),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                icon: const Icon(Icons.close, color: AppPalette.iconOnBrand),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
