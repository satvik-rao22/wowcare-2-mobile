import 'package:flutter/widgets.dart';
import 'av2_breakpoints.dart';

/// Builds different widget trees per form factor without each call site
/// repeating MediaQuery math. `tablet`/`desktop` fall back to the next
/// smaller builder when not supplied.
class Av2Responsive extends StatelessWidget {
  const Av2Responsive({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final WidgetBuilder mobile;
  final WidgetBuilder? tablet;
  final WidgetBuilder? desktop;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final f = Av2Breakpoints.of(constraints.maxWidth);
        switch (f) {
          case Av2FormFactor.desktop:
            return (desktop ?? tablet ?? mobile)(context);
          case Av2FormFactor.tablet:
            return (tablet ?? mobile)(context);
          case Av2FormFactor.mobile:
            return mobile(context);
        }
      },
    );
  }
}
