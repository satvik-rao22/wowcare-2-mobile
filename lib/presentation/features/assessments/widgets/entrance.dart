import 'package:flutter/material.dart';

/// A lightweight staggered entrance animation: children fade in and rise a few
/// pixels, offset by their [index] so a list/grid cascades into view. Used to
/// give the assessment lists a polished mobile feel without any extra package.
class Entrance extends StatefulWidget {
  const Entrance({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = const Duration(milliseconds: 380),
    this.stagger = const Duration(milliseconds: 55),
    this.beginOffset = 0.10,
  });

  final Widget child;
  final int index;
  final Duration duration;
  final Duration stagger;

  /// Vertical start offset as a fraction of the child's height.
  final double beginOffset;

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    // Cap the cascade so very long lists don't wait seconds for the tail.
    final steps = widget.index.clamp(0, 12);
    Future<void>.delayed(widget.stagger * steps, () {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _shown ? Offset.zero : Offset(0, widget.beginOffset),
      duration: widget.duration,
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: _shown ? 1 : 0,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
