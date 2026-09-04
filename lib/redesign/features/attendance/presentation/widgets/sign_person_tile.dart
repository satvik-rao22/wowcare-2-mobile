import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/status_pill.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/attendance/attendance_sizes.dart';
import 'package:wowcare/redesign/features/attendance/attendance_strings.dart';
import 'package:wowcare/redesign/features/attendance/attendance_text_styles.dart';
import 'package:wowcare/redesign/features/attendance/models/models.dart';

/// One of the people a form is about, with the cross that takes them off it.
///
/// Somebody who is not expected today wears a flag, so the acknowledgement
/// under the tiles is about a name that is visible rather than an abstraction.
class SignPersonTile extends StatelessWidget {
  const SignPersonTile({
    required this.record,
    required this.onRemove,
    super.key,
  });

  final AttendanceRecord record;

  /// Null on the last tile: an empty form has nothing to submit.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppCard(
      padding: AttendanceSizes.personTilePad,
      child: Row(
        spacing: AttendanceSizes.personTileGap,
        children: <Widget>[
          SurfaceBox(
            surface: AppSurfaces.avatar(
              c,
              fill: record.audience.isStudents ? c.studentBg : c.staffBg,
              size: AttendanceSizes.personTileAvatar,
            ),
            width: AttendanceSizes.personTileAvatar,
            height: AttendanceSizes.personTileAvatar,
            alignment: Alignment.center,
            child: Text(
              record.initials,
              style: AttendanceTextStyles.smallInitials.copyWith(
                color: record.audience.isStudents ? c.student : c.staffFg,
              ),
            ),
          ),
          Expanded(
            child: Text(
              record.fullName,
              style: AttendanceTextStyles.tileName.copyWith(color: c.ink),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!record.isExpectedToday)
            const StatusPill(
              label: AttendanceStrings.expectedNotToday,
              tone: PillTone.danger,
              small: true,
            ),
          _RemoveKey(onTap: onRemove, label: record.fullName),
        ],
      ),
    );
  }
}

/// The cross on a tile. Inert on the last one, and it keeps its place.
class _RemoveKey extends StatelessWidget {
  const _RemoveKey({required this.onTap, required this.label});

  final VoidCallback? onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    final face = SurfaceBox(
      surface: AppSurfaces.glyphTile(c, fill: c.sub, radius: AppRadii.chip),
      width: AttendanceSizes.removeKey,
      height: AttendanceSizes.removeKey,
      alignment: Alignment.center,
      child: Icon(
        AppIcons.close,
        size: AttendanceSizes.removeGlyph,
        color: c.ink3,
      ),
    );

    if (onTap == null) {
      return Opacity(opacity: AttendanceSizes.keyOffOpacity, child: face);
    }
    return Semantics(
      button: true,
      label: '${AttendanceStrings.removeTile} $label',
      child: Pressable.surface(onTap: onTap, child: face),
    );
  }
}
