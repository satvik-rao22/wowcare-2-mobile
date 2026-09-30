import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Initialises the sizer [Device] globals (width, height, screenType, etc.)
/// during the BUILD phase — before screens call `.h` / `.w` / `.sp` —
/// by reading from the ambient [MediaQuery] instead of a [LayoutBuilder].
/// Rebuilds automatically when [MediaQuery] changes (e.g. device rotation),
/// keeping [Device] in sync without nesting [MaterialApp.router] inside a
/// [LayoutBuilder] buildScope.
class SizerInit extends StatelessWidget {
  const SizerInit({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Aspect reads, not MediaQuery.of: this only cares about size and
    // orientation, and a full read would also rebuild it on every frame of
    // a keyboard animation (viewInsets).
    final Size size = MediaQuery.sizeOf(context);
    Device.setScreenSize(
      context,
      BoxConstraints(maxWidth: size.width, maxHeight: size.height),
      MediaQuery.orientationOf(context),
      599,
    );
    return child;
  }
}
