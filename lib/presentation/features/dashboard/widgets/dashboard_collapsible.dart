import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';

/// Opens and closes a dashboard card body in one motion: the body slides
/// shut under a clip while it fades, instead of vanishing and leaving the
/// card to snap to its new height. Fully closed, the body is not built.
class DashboardCollapsible extends StatefulWidget {
  const DashboardCollapsible({
    super.key,
    required this.collapsed,
    required this.child,
  });

  final bool collapsed;
  final Widget child;

  @override
  State<DashboardCollapsible> createState() => _DashboardCollapsibleState();
}

class _DashboardCollapsibleState extends State<DashboardCollapsible>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.panel,
    value: widget.collapsed ? 0 : 1,
  );

  late final Animation<double> _height = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.easeInOut,
  );

  // The body is gone before the card finishes closing, and shows up once
  // there is room for it when opening.
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.25, 1, curve: Curves.easeOut),
  );

  @override
  void didUpdateWidget(DashboardCollapsible oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.collapsed == widget.collapsed) return;
    if (widget.collapsed) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        if (widget.collapsed && _controller.isDismissed) {
          return const SizedBox(width: double.infinity);
        }
        // Clip only while moving, so a key's rim or a card's shadow at the
        // foot of an open body is never cut off.
        final bool resting = !widget.collapsed && _controller.isCompleted;
        return ClipRect(
          clipBehavior: resting ? Clip.none : Clip.hardEdge,
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: _height.value,
            child: FadeTransition(
              opacity: _opacity,
              child: SizedBox(width: double.infinity, child: child),
            ),
          ),
        );
      },
    );
  }
}
