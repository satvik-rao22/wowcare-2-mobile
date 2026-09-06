import 'package:flutter/widgets.dart';
import 'package:wowcare/core/responsive/app_breakpoints.dart';

/// Publishes the current [ScreenSizeClass] to the subtree (Mandate M7).
///
/// Mount once, above the routed screens. Feature code then reads
/// `context.screenSize`, `context.isTablet` or `context.responsive(...)`
/// instead of measuring.
///
/// ## Why this reads MediaQuery instead of using a LayoutBuilder
///
/// §7.2 describes "one LayoutBuilder at the top of the tree". That is not safe
/// in this app: `app.dart` documents a GlobalKey crash
/// ("GlobalKey used multiple times", go_router builder.dart:457) caused by
/// inflating `MaterialApp.router` inside a nested LayoutBuilder buildScope —
/// the reason the old `Sizer(LayoutBuilder)` wrapper was removed. Adding a
/// LayoutBuilder back around the Router would reintroduce it.
///
/// `MediaQuery.sizeOf` gives the same width at the top of the tree, and
/// subscribes to size only (§7.5), so this is both safer and narrower.
class ResponsiveScope extends StatelessWidget {
  const ResponsiveScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return _ResponsiveData(
      sizeClass: AppBreakpoints.classify(width),
      child: child,
    );
  }
}

class _ResponsiveData extends InheritedWidget {
  const _ResponsiveData({required this.sizeClass, required super.child});

  final ScreenSizeClass sizeClass;

  /// §7.3: compares the size CLASS, not the width. Comparing widths would
  /// rebuild every dependant on each frame of a rotation or keyboard
  /// transition, which is the cost this scope exists to avoid.
  @override
  bool updateShouldNotify(_ResponsiveData oldWidget) =>
      oldWidget.sizeClass != sizeClass;
}

extension ResponsiveContext on BuildContext {
  /// The current size class.
  ///
  /// Falls back to measuring MediaQuery when no [ResponsiveScope] is mounted,
  /// so a widget rendered outside the app shell (e.g. in a widget test) still
  /// resolves rather than throwing.
  ScreenSizeClass get screenSize {
    final data = dependOnInheritedWidgetOfExactType<_ResponsiveData>();
    if (data != null) return data.sizeClass;
    return AppBreakpoints.classify(MediaQuery.sizeOf(this).width);
  }

  /// True at [AppBreakpoints.compactMaxWidth] and above.
  bool get isTablet => screenSize.isTablet;

  /// True on very small phones (< 360). A sub-compact tweak that sits below
  /// the size classes, so it reads the width directly rather than the scope.
  bool get isNarrow => AppBreakpoints.isNarrow(MediaQuery.sizeOf(this).width);

  /// True at 900 and above. A legacy sub-boundary inside `medium` — see
  /// [AppBreakpoints.wideMinWidth].
  bool get isWide => AppBreakpoints.isWide(MediaQuery.sizeOf(this).width);

  /// Pick a value per size class. [medium] and [expanded] fall back to the
  /// next narrower value when omitted, so callers only specify what differs.
  T responsive<T>({required T compact, T? medium, T? expanded}) {
    switch (screenSize) {
      case ScreenSizeClass.compact:
        return compact;
      case ScreenSizeClass.medium:
        return medium ?? compact;
      case ScreenSizeClass.expanded:
        return expanded ?? medium ?? compact;
    }
  }
}
