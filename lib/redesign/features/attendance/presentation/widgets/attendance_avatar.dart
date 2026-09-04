import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/attendance/attendance_sizes.dart';
import 'package:wowcare/redesign/features/attendance/attendance_text_styles.dart';
import 'package:wowcare/redesign/features/attendance/models/models.dart';

/// The initials bubble an attendance row leads with, inside a ring in the
/// colour of today.
///
/// This module rings the avatar rather than dotting it, which is how every
/// M04 frame draws it: the status has to be readable down a list of forty
/// rows without stopping on any of them. Not Marked is a dashed ring, because
/// nothing has happened yet.
class AttendanceAvatar extends StatelessWidget {
  const AttendanceAvatar({
    required this.initials,
    required this.status,
    this.audience = AttendanceAudience.students,
    this.size = AttendanceSizes.avatar,
    this.onImpact = false,
    super.key,
  });

  final String initials;
  final AttendanceStatus status;
  final AttendanceAudience audience;
  final double size;

  /// On the navy card, where the tints invert.
  final bool onImpact;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    const gap = AttendanceSizes.avatarRing + AttendanceSizes.avatarRingPad;
    final inner = size - gap * 2;

    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _RingPainter(
          color: onImpact ? c.onImpactSoft : status.colour(c),
          strokeWidth: AttendanceSizes.avatarRing,
          isDashed: status == AttendanceStatus.notMarked,
        ),
        child: Center(
          child: SurfaceBox(
            surface: AppSurfaces.avatar(c, fill: _fill(c), size: inner),
            width: inner,
            height: inner,
            alignment: Alignment.center,
            child: Text(
              initials,
              style: AttendanceTextStyles.bigInitials.copyWith(color: _ink(c)),
            ),
          ),
        ),
      ),
    );
  }

  Color _fill(Colourway c) {
    if (onImpact) return c.onImpactSub;
    return audience.isStudents ? c.studentBg : c.staffBg;
  }

  Color _ink(Colourway c) {
    if (onImpact) return c.onImpact;
    return audience.isStudents ? c.student : c.staffFg;
  }
}

/// The ring itself. Dashed means no record yet, which Flutter has no border
/// style for, so the arc is stepped round by hand.
class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.color,
    required this.strokeWidth,
    required this.isDashed,
  });

  final Color color;
  final double strokeWidth;
  final bool isDashed;

  /// Dash and gap, in radians, at the ring's own radius.
  static const int _dashCount = 14;
  static const double _dashShare = .6;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    if (!isDashed) {
      canvas.drawOval(rect, paint);
      return;
    }

    const step = 2 * math.pi / _dashCount;
    for (var i = 0; i < _dashCount; i++) {
      canvas.drawArc(rect, i * step, step * _dashShare, false, paint);
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.isDashed != isDashed;
}
