import 'package:flutter/material.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_today_sign_in_status_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_today_sign_in_status_usecase.dart';

/// The small dot on a [ProfileAvatar] saying where a person is today:
/// green signed in, red absent, amber upcoming (not started yet).
///
/// ```dart
/// // The screen already knows the status:
/// AttendanceStatusDot(color: dotColor, tooltip: 'Signed in')
/// // Ask the server for today's status:
/// AttendanceStatusDot(staffCode: staff.code)
/// ```
///
/// [profileStatus] `UPCOMING` wins over everything else. Otherwise a given
/// [color] is shown as is; with no [color] and [lookUp] on, today's status is
/// fetched for [staffCode] or [studentCode]. Nothing to show → nothing drawn.
class AttendanceStatusDot extends StatefulWidget {
  const AttendanceStatusDot({
    super.key,
    this.staffCode,
    this.studentCode,
    this.profileStatus,
    this.color,
    this.tooltip,
    this.lookUp = true,
    this.onlyAbsent = false,
  });

  final String? staffCode;
  final String? studentCode;

  /// The staff employment / student enrollment status, e.g. `UPCOMING`.
  final String? profileStatus;
  final Color? color;
  final String? tooltip;

  /// False when the screen supplies [color] itself (avoids one request per
  /// row in a list).
  final bool lookUp;

  /// Shows only an absent dot, not a signed-in one.
  final bool onlyAbsent;

  static final ValueNotifier<int> _refresh = ValueNotifier<int>(0);

  /// Call after any attendance change (sign in/out, edit, delete, transfer,
  /// mark absent) so every dot on screen fetches today's status again.
  static void refreshAll() => _refresh.value++;

  @override
  State<AttendanceStatusDot> createState() => _AttendanceStatusDotState();
}

class _AttendanceStatusDotState extends State<AttendanceStatusDot> {
  /// Today's status from the server: SIGNED_IN, ABSENT, or null.
  String? _status;

  String get _staff => widget.staffCode?.trim() ?? '';
  String get _student => widget.studentCode?.trim() ?? '';

  bool get _upcoming =>
      widget.profileStatus?.trim().toUpperCase() == 'UPCOMING';

  bool get _shouldLookUp =>
      !_upcoming &&
      widget.color == null &&
      widget.lookUp &&
      (_staff.isNotEmpty || _student.isNotEmpty);

  @override
  void initState() {
    super.initState();
    AttendanceStatusDot._refresh.addListener(_load);
    _load();
  }

  @override
  void didUpdateWidget(AttendanceStatusDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.staffCode != widget.staffCode ||
        oldWidget.studentCode != widget.studentCode ||
        oldWidget.lookUp != widget.lookUp) {
      _status = null;
      _load();
    }
  }

  @override
  void dispose() {
    AttendanceStatusDot._refresh.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    if (!_shouldLookUp) return;
    final staff = _staff;
    final student = _student;
    String? status;
    try {
      status = staff.isNotEmpty
          ? await serviceLocator<GetStaffTodaySignInStatusUseCase>()(
              staffCode: staff,
            )
          : await serviceLocator<GetStudentTodaySignInStatusUseCase>()(
              studentCode: student,
            );
    } catch (_) {
      // Hide the dot rather than show a stale status.
      status = null;
    }
    if (!mounted || staff != _staff || student != _student) return;
    setState(() => _status = status?.toUpperCase());
  }

  /// "Staff" or "Student", for the tooltip.
  String get _who => _staff.isNotEmpty ? 'Staff' : 'Student';

  ({Color color, String tooltip})? get _dot {
    if (_upcoming) {
      return (
        color: AppColors.mustardProgressBar,
        tooltip: 'Upcoming ${_who.toLowerCase()}',
      );
    }
    final given = widget.color;
    if (given != null) {
      final tooltip = widget.tooltip?.trim() ?? '';
      return (color: given, tooltip: tooltip.isEmpty ? 'Status' : tooltip);
    }
    if (!_shouldLookUp) return null;
    return switch (_status) {
      'SIGNED_IN' when !widget.onlyAbsent => (
        color: MaterialHues.green,
        tooltip: '$_who is signed in',
      ),
      'ABSENT' => (color: MaterialHues.red, tooltip: '$_who is absent'),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final dot = _dot;
    if (dot == null) return const SizedBox.shrink();
    return Tooltip(
      message: dot.tooltip,
      waitDuration: const Duration(milliseconds: 100),
      showDuration: const Duration(seconds: 2),
      decoration: BoxDecoration(
        color: AppPalette.surfaceInverse.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(
        color: AppPalette.textOnDark,
        fontSize: 12,
        fontFamily: AppFonts.body,
        fontWeight: FontWeight.w600,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: dot.color,
          shape: BoxShape.circle,
          border: Border.all(color: AppPalette.surfaceCard, width: 1),
        ),
      ),
    );
  }
}
