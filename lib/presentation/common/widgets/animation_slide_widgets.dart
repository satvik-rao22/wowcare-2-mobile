import 'package:flutter/material.dart';
import 'dart:math' as math;

enum SlideDirection {
  left,
  right,
  top,
  bottom,
}

class SlideAnimationWrapper extends StatefulWidget {
  final Widget child;
  final SlideDirection direction;
  final Duration animationDuration;
  final double slideOffset;
  final Curve curve;
  final bool fadeEffect;

  const SlideAnimationWrapper({
    super.key,
    required this.child,
    this.direction = SlideDirection.left,
    this.animationDuration = const Duration(milliseconds: 800),
    this.slideOffset = 100.0,
    this.curve = Curves.easeOutCubic,
    this.fadeEffect = true,
  });

  @override
  State<SlideAnimationWrapper> createState() => _SlideAnimationWrapperState();
}

class _SlideAnimationWrapperState extends State<SlideAnimationWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _initializeAnimations();
    _controller.forward();
  }

  void _initializeAnimations() {
    // Configure slide animation based on direction
    Offset beginOffset = _getBeginOffset();

    _slideAnimation = Tween<Offset>(
      begin: beginOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));
  }

  Offset _getBeginOffset() {
    switch (widget.direction) {
      case SlideDirection.left:
        return Offset(-widget.slideOffset / 100, 0);
      case SlideDirection.right:
        return Offset(widget.slideOffset / 100, 0);
      case SlideDirection.top:
        return Offset(0, -widget.slideOffset / 100);
      case SlideDirection.bottom:
        return Offset(0, widget.slideOffset / 100);
    }
  }

  @override
  void didUpdateWidget(SlideAnimationWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.direction != widget.direction ||
        oldWidget.slideOffset != widget.slideOffset ||
        oldWidget.curve != widget.curve) {
      _initializeAnimations();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: widget.fadeEffect
          ? FadeTransition(
              opacity: _fadeAnimation,
              child: widget.child,
            )
          : widget.child,
    );
  }
}




// Copy// With any widget
// SlideAnimationWrapper(
//   direction: SlideDirection.bottom,
//   curve: Curves.bounceOut,
//   child: YourCustomWidget(),
// )

// // With different durations for staggered effect
// SlideAnimationWrapper(
//   direction: SlideDirection.left,
//   animationDuration: Duration(milliseconds: 800 + index * 200),
//   child: YourListItem(),
// )

// // Without fade effect
// SlideAnimationWrapper(
//   direction: SlideDirection.right,
//   fadeEffect: false,
//   child: YourWidget(),
// )




enum AnimationType {
  slide,
  scale,
  fade,
  rotate,
  flip,
  bounce,
  pulse,
  shake,
}

class AnimationWrapper extends StatefulWidget {
  final Widget child;
  final AnimationType type;
  final Duration duration;
  final Duration delay;
  final bool infinite;
  final Curve curve;

  const AnimationWrapper({
    super.key,
    required this.child,
    this.type = AnimationType.fade,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
    this.infinite = false,
    this.curve = Curves.easeOut,
  });

  @override
  State<AnimationWrapper> createState() => _AnimationWrapperState();
}

class _AnimationWrapperState extends State<AnimationWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _initializeAnimation();

    Future.delayed(widget.delay, () {
      if (widget.infinite) {
        _controller.repeat(reverse: true);
      } else {
        _controller.forward();
      }
    });
  }

  void _initializeAnimation() {
    switch (widget.type) {
      case AnimationType.fade:
        _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: widget.curve),
        );
        break;
      case AnimationType.scale:
        _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: widget.curve),
        );
        break;
      case AnimationType.rotate:
        _rotateAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
          CurvedAnimation(parent: _controller, curve: widget.curve),
        );
        break;
      case AnimationType.flip:
        _animation = Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(parent: _controller, curve: widget.curve),
        );
        break;
      case AnimationType.bounce:
        _animation = Tween<double>(begin: -20.0, end: 0.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.bounceOut),
        );
        break;
      case AnimationType.pulse:
        _animation = Tween<double>(begin: 1.0, end: 1.2).animate(
          CurvedAnimation(parent: _controller, curve: widget.curve),
        );
        break;
      case AnimationType.shake:
        _animation = Tween<double>(begin: -10.0, end: 10.0).animate(
          CurvedAnimation(parent: _controller, curve: widget.curve),
        );
        break;
      case AnimationType.slide:
        _slideAnimation = Tween<Offset>(
          begin: const Offset(-1.0, 0.0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
        break;
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
      builder: (context, child) {
        Widget animatedChild = widget.child;

        // Apply animations in the correct order
        switch (widget.type) {
          case AnimationType.fade:
            animatedChild = Opacity(
              opacity: _animation.value,
              child: animatedChild,
            );
            break;

          case AnimationType.scale:
            animatedChild = ScaleTransition(
              scale: _animation,
              child: animatedChild,
            );
            break;

          case AnimationType.rotate:
            animatedChild = RotationTransition(
              turns: _rotateAnimation,
              child: animatedChild,
            );
            break;

          case AnimationType.flip:
            animatedChild = Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(_animation.value * math.pi),
              alignment: Alignment.center,
              child: animatedChild,
            );
            break;

          case AnimationType.bounce:
            animatedChild = Transform.translate(
              offset: Offset(0, _animation.value),
              child: animatedChild,
            );
            break;

          case AnimationType.pulse:
            animatedChild = ScaleTransition(
              scale: _animation,
              child: animatedChild,
            );
            break;

          case AnimationType.shake:
            animatedChild = Transform.translate(
              offset: Offset(_animation.value, 0),
              child: animatedChild,
            );
            break;

          case AnimationType.slide:
            animatedChild = SlideTransition(
              position: _slideAnimation,
              child: animatedChild,
            );
            break;
        }

        return animatedChild;
      },
    );
  }
}

// Extension for staggered animations
class StaggeredAnimationList extends StatelessWidget {
  final List<Widget> children;
  final AnimationType type;
  final Duration initialDelay;
  final Duration staggerDuration;
  final Duration animationDuration;
  final Curve curve;
  final bool infinite;
  final Axis direction;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final bool expanded;

  const StaggeredAnimationList({
    super.key,
    required this.children,
    this.type = AnimationType.fade,
    this.initialDelay = Duration.zero,
    this.staggerDuration = const Duration(milliseconds: 100),
    this.animationDuration = const Duration(milliseconds: 500),
    this.curve = Curves.easeOut,
    this.infinite = false,
    this.direction = Axis.vertical,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final animatedChildren = List.generate(
      children.length,
      (index) => AnimationWrapper(
        type: type,
        delay: initialDelay + (staggerDuration * index),
        duration: animationDuration,
        curve: curve,
        infinite: infinite,
        child: expanded ? Expanded(child: children[index]) : children[index],
      ),
    );

    return direction == Axis.horizontal
        ? Row(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            children: animatedChildren,
          )
        : Column(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: crossAxisAlignment,
            children: animatedChildren,
          );
  }
}