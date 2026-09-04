import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/attendance/attendance_sizes.dart';

/// The row of keys docked under a screen: 4a's select bar and the two forms'
/// confirm key.
///
/// The [IntrinsicHeight] is load-bearing: a key's face is centred inside its
/// own surface, so given a tall bounded slot it would stretch to fill it, and
/// a `Scaffold`'s bottom slot is exactly that. Measuring the keys first pins
/// the bar to their height.
class AttendanceDockedBar extends StatelessWidget {
  const AttendanceDockedBar({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => SurfaceBox(
    surface: AppSurfaces.tabBar(context.colours),
    padding: AttendanceSizes.selectBarPad,
    child: IntrinsicHeight(child: child),
  );
}
