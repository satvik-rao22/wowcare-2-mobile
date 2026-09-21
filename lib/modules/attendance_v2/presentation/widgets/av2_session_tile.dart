import 'package:flutter/material.dart';
import '../../core/theme/av2_colors.dart';
import '../../core/theme/av2_spacing.dart';
import '../../core/theme/av2_text_styles.dart';
import '../../core/utils/av2_date_formatter.dart';
import '../../core/utils/av2_duration_formatter.dart';
import '../../domain/entities/attendance_session.dart';

/// One session inside an expanded day. Shows the classroom, then a clear
/// in/out pair — each with its time and who recorded it — plus the worked
/// duration and an action affordance. A system (auto-closed) sign-out is
/// flagged in amber.
class Av2SessionTile extends StatelessWidget {
  const Av2SessionTile({
    super.key,
    required this.session,
    this.showDivider = true,
    this.onAction,
  });

  final AttendanceSession session;
  final bool showDivider;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: showDivider
          ? const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Av2Colors.border, width: 0.5),
              ),
            )
          : null,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _body()),
          const SizedBox(width: 8),
          _trailing(),
        ],
      ),
    );
  }

  Widget _body() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          session.classroomName,
          style: Av2Text.bodyMedium.copyWith(fontSize: 13),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        _inOutLine(
          icon: Icons.login_rounded,
          iconColor: Av2Colors.regular,
          time: Av2DateFormatter.compactTime(session.signInAt),
          by: session.signedInBy,
          byColor: Av2Colors.textSecondary,
        ),
        const SizedBox(height: 2),
        _signOutLine(),
      ],
    );
  }

  Widget _signOutLine() {
    if (session.isOpen) {
      return _inOutLine(
        icon: Icons.logout_rounded,
        iconColor: Av2Colors.textTertiary,
        time: 'Not signed out',
        by: null,
        byColor: Av2Colors.textTertiary,
      );
    }
    final isSystem = session.isSystemClosed;
    return _inOutLine(
      icon: Icons.logout_rounded,
      iconColor: isSystem ? Av2Colors.overtime : Av2Colors.danger,
      time: Av2DateFormatter.compactTime(session.signOutAt!),
      by: session.signedOutBy,
      byColor: isSystem ? Av2Colors.overtime : Av2Colors.textSecondary,
    );
  }

  Widget _inOutLine({
    required IconData icon,
    required Color iconColor,
    required String time,
    required String? by,
    required Color byColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 13, color: iconColor),
        const SizedBox(width: 6),
        Text(
          time,
          style: Av2Text.caption.copyWith(color: Av2Colors.textPrimary),
        ),
        if (by != null && by.isNotEmpty) ...[
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '· by $by',
              style: Av2Text.caption.copyWith(color: byColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  Widget _trailing() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          Av2DurationFormatter.hm(session.workedMinutes),
          style: Av2Text.bodyMedium.copyWith(fontSize: 13),
        ),
        if (onAction != null) ...[
          const SizedBox(height: 2),
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.more_vert,
                  size: 16, color: Av2Colors.textTertiary),
            ),
          ),
        ],
      ],
    );
  }
}
