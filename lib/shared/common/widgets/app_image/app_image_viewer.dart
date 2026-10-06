part of 'app_image.dart';

/// Full-screen viewer behind [AppImageInteraction.openFullScreen] and
/// [AppImage.openFullScreen]: pinch, pan and double-tap zoom via
/// [_ZoomableImage], so SVG and Lottie zoom the same way rasters do.
class _AppImageViewer extends StatelessWidget {
  const _AppImageViewer({required this.source, this.heroTag});

  final Object? source;
  final Object? heroTag;

  static Future<void> open(
    BuildContext context,
    Object? source, {
    Object? heroTag,
  }) {
    return Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: AppPalette.scrim,
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (_, _, _) =>
            _AppImageViewer(source: source, heroTag: heroTag),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.scrim,
      body: Stack(
        children: [
          // No width/height: the viewer decodes at full resolution so zooming
          // stays sharp, and AppImage's size-based decode hint switches off.
          Positioned.fill(
            child: _ZoomableImage(source: source, heroTag: heroTag),
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
