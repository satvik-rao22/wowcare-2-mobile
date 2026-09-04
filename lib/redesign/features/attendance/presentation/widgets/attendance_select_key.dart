import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/attendance/attendance_sizes.dart';
import 'package:wowcare/redesign/features/attendance/attendance_strings.dart';
import 'package:wowcare/redesign/features/attendance/attendance_text_styles.dart';

/// The header key that puts the list into select mode, and takes it out
/// again (4a, 4d).
///
/// On, it goes navy: the list is in a mode, and the key that put it there is
/// the way back out. Off and inert, it is the well ground, which is what 4d
/// draws while a teacher has not signed themselves in yet.
class AttendanceSelectKey extends StatelessWidget {
  const AttendanceSelectKey({required this.isOn, this.onTap, super.key});

  final bool isOn;

  /// Null draws the refused key: in place, at the same size, and dead.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final label = isOn
        ? AttendanceStrings.doneKey
        : AttendanceStrings.selectKey;

    final face = SurfaceBox(
      surface: switch ((isOn, onTap == null)) {
        (true, _) => AppSurfaces.glyphTile(
          c,
          fill: c.impact,
          radius: AppRadii.inner,
        ),
        (false, true) => AppSurfaces.glyphTile(
          c,
          fill: c.sub,
          radius: AppRadii.inner,
        ),
        (false, false) => AppSurfaces.keySecondary(c),
      },
      padding: AttendanceSizes.selectKeyPad,
      child: Text(
        label,
        style: AttendanceTextStyles.stripKey.copyWith(
          color: switch ((isOn, onTap == null)) {
            (true, _) => c.onImpact,
            (false, true) => c.ink3,
            (false, false) => c.ink,
          },
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: onTap != null,
      selected: isOn,
      label: label,
      child: Pressable.surface(onTap: onTap, child: face),
    );
  }
}
