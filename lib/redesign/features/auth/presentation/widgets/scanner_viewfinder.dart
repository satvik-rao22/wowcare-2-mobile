import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/features/auth/auth_sizes.dart';

/// 2a's viewfinder: a glass square with four sun brackets and a line that
/// sweeps it.
///
/// The camera is not wired during the UI phase, so this is the frame the
/// design draws and nothing behind it. Tapping it stands in for a code
/// arriving, which is what makes the rest of the kiosk lane walkable.
class ScannerViewfinder extends StatefulWidget {
  const ScannerViewfinder({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  State<ScannerViewfinder> createState() => _ScannerViewfinderState();
}

class _ScannerViewfinderState extends State<ScannerViewfinder>
    with SingleTickerProviderStateMixin {
  /// How long the line takes to cross the square once.
  static const Duration _sweep = Duration(milliseconds: 1800);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _sweep,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: AuthSizes.viewfinder,
        height: AuthSizes.viewfinder,
        decoration: BoxDecoration(
          color: c.onImpact.withValues(alpha: AuthSizes.scannerGlassAlpha),
          borderRadius: BorderRadius.circular(AuthSizes.viewfinderRadius),
        ),
        child: Stack(
          children: <Widget>[
            for (final corner in _Corner.values)
              corner.build(colours: c),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => Positioned(
                left: AuthSizes.scanLineInset,
                right: AuthSizes.scanLineInset,
                top:
                    _controller.value *
                    (AuthSizes.viewfinder - AuthSizes.scanLine),
                child: Container(
                  height: AuthSizes.scanLine,
                  decoration: BoxDecoration(
                    color: c.staff,
                    borderRadius: BorderRadius.circular(AuthSizes.scanLine),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: c.staff.withValues(
                          alpha: AuthSizes.scanLineGlowAlpha,
                        ),
                        blurRadius: AuthSizes.scanLineGlow,
                        spreadRadius: AuthSizes.scanLine,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One of the viewfinder's four brackets.
enum _Corner {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight;

  bool get _isTop => this == _Corner.topLeft || this == _Corner.topRight;
  bool get _isLeft => this == _Corner.topLeft || this == _Corner.bottomLeft;

  Widget build({required Colourway colours}) {
    final side = BorderSide(
      color: colours.staff,
      width: AuthSizes.viewfinderStroke,
    );
    const radius = Radius.circular(AuthSizes.viewfinderCornerRadius);
    const zero = Radius.zero;

    return Positioned(
      top: _isTop ? 0 : null,
      bottom: _isTop ? null : 0,
      left: _isLeft ? 0 : null,
      right: _isLeft ? null : 0,
      child: Container(
        width: AuthSizes.viewfinderCorner,
        height: AuthSizes.viewfinderCorner,
        decoration: BoxDecoration(
          border: Border(
            top: _isTop ? side : BorderSide.none,
            bottom: _isTop ? BorderSide.none : side,
            left: _isLeft ? side : BorderSide.none,
            right: _isLeft ? BorderSide.none : side,
          ),
          borderRadius: BorderRadius.only(
            topLeft: this == _Corner.topLeft ? radius : zero,
            topRight: this == _Corner.topRight ? radius : zero,
            bottomLeft: this == _Corner.bottomLeft ? radius : zero,
            bottomRight: this == _Corner.bottomRight ? radius : zero,
          ),
        ),
      ),
    );
  }
}
