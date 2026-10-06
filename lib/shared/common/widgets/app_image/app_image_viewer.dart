import 'package:flutter/material.dart';

import 'app_image.dart';

/// Full-screen viewer for any [AppImage] source: pinch, pan and double-tap
/// zoom via [AppZoomableImage], so SVG and Lottie zoom the same way rasters do.
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
        barrierColor: Colors.black,
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // No width/height: the viewer decodes at full resolution so zooming
          // stays sharp, and AppImage's size-based decode hint switches off.
          Positioned.fill(
            child: AppZoomableImage(source: source, heroTag: heroTag),
          ),
          SafeArea(
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: IconButton(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
