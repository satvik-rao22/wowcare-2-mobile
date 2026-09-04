import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/core/widgets/impact_card.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/attendance/attendance_formats.dart';
import 'package:wowcare/redesign/features/attendance/attendance_sizes.dart';
import 'package:wowcare/redesign/features/attendance/attendance_strings.dart';
import 'package:wowcare/redesign/features/attendance/attendance_text_styles.dart';
import 'package:wowcare/redesign/features/attendance/models/models.dart';
import 'package:wowcare/redesign/features/attendance/presentation/widgets/attendance_avatar.dart';

/// A teacher's own day, first on their own screen (4d, and 4a's staff lens).
///
/// The single impact surface on this screen: their shift outranks the
/// classroom under it, because until they have signed themselves in they
/// cannot sign anyone else in either. Location is checked once, here, and
/// nowhere else.
class SelfShiftCard extends StatelessWidget {
  const SelfShiftCard({
    required this.shift,
    required this.now,
    required this.onSignIn,
    required this.onSignOut,
    this.isWorking = false,
    super.key,
  });

  final SelfShift shift;

  /// The school's clock, for how long they have been on it.
  final ClockTime now;

  final VoidCallback onSignIn;
  final VoidCallback onSignOut;
  final bool isWorking;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final signedInAt = shift.signedInAt;

    return ImpactCard(
      padding: AttendanceSizes.selfCardPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AttendanceSizes.selfCardGap,
        children: <Widget>[
          Row(
            spacing: AttendanceSizes.sheetHeaderGap,
            children: <Widget>[
              AttendanceAvatar(
                initials: shift.initials,
                status: signedInAt == null
                    ? AttendanceStatus.notMarked
                    : AttendanceStatus.signedIn,
                size: AttendanceSizes.headerAvatar,
                onImpact: true,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSizes.rowTextGap,
                  children: <Widget>[
                    Text(
                      signedInAt == null
                          ? AttendanceStrings.notSignedInYet
                          : AttendanceStrings.selfSignedIn(signedInAt.label),
                      style: AttendanceTextStyles.heroLine.copyWith(
                        color: c.onImpact,
                      ),
                    ),
                    Text(
                      signedInAt == null
                          ? AttendanceStrings.shiftStarts(
                              shift.shiftStart.label,
                              shift.classroomName,
                            )
                          : AttendanceStrings.selfOnTheClock(
                              shift.classroomName,
                              AttendanceFormats.between(signedInAt, now),
                            ),
                      style: AttendanceTextStyles.heroSub.copyWith(
                        color: c.onImpactSoft,
                      ),
                    ),
                  ],
                ),
              ),
              if (signedInAt != null)
                _QuietKey(label: AppStrings.signOut, onTap: onSignOut),
            ],
          ),
          if (signedInAt == null)
            PrimaryKey(
              label: AttendanceStrings.signMyselfIn,
              enabled: shift.canSignSelfIn,
              isLoading: isWorking,
              padding: AttendanceSizes.selfCardPad,
              onTap: onSignIn,
            ),
          if (signedInAt == null) _geofence(c) else _ratioLine(c),
        ],
      ),
    );
  }

  /// Their own sign-in is the only geofenced one in the module.
  Widget _geofence(Colourway c) => SurfaceBox(
    surface: AppSurfaces.glyphTile(
      c,
      fill: c.onImpactSub,
      radius: AppRadii.inner,
    ),
    padding: AttendanceSizes.selfNotePad,
    child: Row(
      spacing: AttendanceSizes.selfNoteGap,
      children: <Widget>[
        Icon(
          AppIcons.mapPin,
          size: AttendanceSizes.selfNoteGlyph,
          color: shift.isInsideGeofence ? c.staff : c.dangerBg,
        ),
        Expanded(
          child: Text(
            switch ((shift.isCheckingLocation, shift.isInsideGeofence)) {
              (true, _) => AttendanceStrings.geofenceChecking,
              (false, true) => AttendanceStrings.geofenceInside,
              (false, false) => AttendanceStrings.geofenceOutside,
            },
            style: AttendanceTextStyles.heroNote.copyWith(
              color: c.onImpactSoft,
            ),
          ),
        ),
      ],
    ),
  );

  /// What signing another student in would cost the classroom.
  Widget _ratioLine(Colourway c) {
    if (!shift.hasCover) return const SizedBox.shrink();
    return Text(
      AttendanceStrings.ratioWarning(
        shift.classroomName,
        shift.coverName!,
        shift.coverArrives!.label,
      ),
      style: AttendanceTextStyles.heroNote.copyWith(color: c.onImpactSoft),
    );
  }
}

/// A key on the navy card: the tint inverts, so it is neither pink nor a
/// card face.
class _QuietKey extends StatelessWidget {
  const _QuietKey({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Semantics(
      button: true,
      label: label,
      child: Pressable.surface(
        onTap: onTap,
        child: SurfaceBox(
          surface: AppSurfaces.glyphTile(
            c,
            fill: c.onImpactSub,
            radius: AppRadii.inner,
          ),
          padding: AttendanceSizes.selectKeyPad,
          child: Text(
            label,
            style: AttendanceTextStyles.heroKey.copyWith(color: c.onImpact),
          ),
        ),
      ),
    );
  }
}
