import 'package:flutter/widgets.dart';

import 'app_breakpoints.dart';

/// Mounted once, near the root (see `app/app.dart`). Publishes the current
/// [ScreenSize] to the whole tree through an [InheritedWidget] so feature
/// code reads [ResponsiveContext.screenSize] instead of measuring
/// `MediaQuery` itself.
class ResponsiveScope extends StatelessWidget {
  const ResponsiveScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => _ResponsiveData(
          screenSize: AppBreakpoints.of(constraints.maxWidth),
          width: constraints.maxWidth,
          child: child,
        ),
      );
}

class _ResponsiveData extends InheritedWidget {
  const _ResponsiveData({
    required this.screenSize,
    required this.width,
    required super.child,
  });

  final ScreenSize screenSize;
  final double width;

  @override
  bool updateShouldNotify(_ResponsiveData old) =>
      old.screenSize != screenSize; // rebuild only when the CLASS changes
}

/// Accessor for `responsive_ext.dart` — kept here since [_ResponsiveData] is
/// private to this library.
ScreenSize screenSizeOf(BuildContext context) => context
    .dependOnInheritedWidgetOfExactType<_ResponsiveData>()!
    .screenSize;
