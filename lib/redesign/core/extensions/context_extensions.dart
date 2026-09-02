import 'package:flutter/material.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';

/// Short reads for the things every widget needs off the theme.
///
/// `context.colours` is how a screen gets colour. There is no other way in:
/// [Colourway] is the swap point for the D1 colourway, so a widget that
/// reaches past it for a raw swatch is what would break the swap.
extension ColourwayContext on BuildContext {
  /// The active colourway. Present on every route: [AppTheme] installs it.
  Colourway get colours => Theme.of(this).extension<Colourway>()!;
}

/// Screen metrics, read once rather than through `MediaQuery.of` scattered
/// about. Each of these watches only the slice it needs, so a keyboard opening
/// does not rebuild a screen that only asked for the width.
extension MediaContext on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

  EdgeInsets get safeArea => MediaQuery.paddingOf(this);

  /// How much of the screen the keyboard is covering, if any.
  double get keyboardInset => MediaQuery.viewInsetsOf(this).bottom;

  bool get isKeyboardOpen => keyboardInset > 0;
}
