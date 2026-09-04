import 'package:flutter/widgets.dart';

import 'app_breakpoints.dart';
import 'responsive_scope.dart';

extension ResponsiveContext on BuildContext {
  ScreenSize get screenSize => screenSizeOf(this);

  bool get isTablet => screenSize != ScreenSize.compact;

  /// Picks a value for the current [ScreenSize], falling back to the next
  /// smaller tier when a larger one isn't given.
  T responsive<T>({required T compact, T? medium, T? expanded}) =>
      switch (screenSize) {
        ScreenSize.expanded => expanded ?? medium ?? compact,
        ScreenSize.medium => medium ?? compact,
        ScreenSize.compact => compact,
      };
}
