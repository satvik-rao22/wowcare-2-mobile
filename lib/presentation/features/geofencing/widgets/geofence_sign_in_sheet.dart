import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme/colors.dart';

/// Bottom sheet shown to ALL roles (parent, staff, admin) when they enter
/// the school geofence zone.
///
/// Caller is responsible for showing this via [GeofenceSignInSheet.show] when
/// the [GeofenceCubit] transitions to [GeofenceCubitStatus.withinRange].
class GeofenceSignInSheet extends StatelessWidget {
  const GeofenceSignInSheet({
    super.key,
    required this.role,
    required this.isSignedIn,
    this.studentName,
    this.studentCode,
  });

  /// 'parent' | 'staff' | 'admin'
  final String role;

  /// Whether the user (or their child, for parent role) is already signed in.
  final bool isSignedIn;

  /// Child name for parent role display.
  final String? studentName;

  /// Child student code — pre-selects this child in the sign-in form (parent only).
  final String? studentCode;

  static Future<void> show(
    BuildContext context, {
    required String role,
    required bool isSignedIn,
    String? studentName,
    String? studentCode,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: true,
      builder: (_) => GeofenceSignInSheet(
        role: role,
        isSignedIn: isSignedIn,
        studentName: studentName,
        studentCode: studentCode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final String action = isSignedIn ? 'Sign-Out' : 'Sign-In';
    final String headline = isSignedIn
        ? 'You\'re inside the school zone'
        : 'You\'ve entered the school zone';
    final String subtitle = _buildSubtitle(action);
    final String route = _resolveRoute();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 20 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── drag handle ───────────────────────────────────────────────
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // ── icon ──────────────────────────────────────────────────────
          // Soft gradient-tinted circle with the pin painted in the same
          // primary gradient (via ShaderMask) so it matches the buttons.
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.buildPrimaryGradient(
                colors: AppColors.primaryGradientColors
                    .map((c) => c.withValues(alpha: 0.12))
                    .toList(),
              ),
            ),
            child: ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) =>
                  AppColors.buildPrimaryGradient().createShader(
                    Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                  ),
              child: const Icon(
                Icons.location_on_rounded,
                color: AppColors.white, // painted over by the gradient
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── headline ──────────────────────────────────────────────────
          Text(
            headline,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xff573353), // AppColors.primaryColor
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // ── subtitle ──────────────────────────────────────────────────
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.grey[600],
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // ── status chip ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF22C55E).withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF22C55E),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Inside School Radius',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    color: Color(0xFF16A34A),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── primary action ────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.buildPrimaryGradient(),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.transparent,
                  shadowColor: AppColors.transparent,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed: () {
                  final router = GoRouter.of(context);
                  Navigator.of(context).pop();
                  router.go(route);
                },
                child: Text(
                  action,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── dismiss ───────────────────────────────────────────────────
          // Gradient-bordered button with gradient text (the app's standard
          // secondary-button treatment, see CustomCancelButton) so it matches
          // the primary Sign-Out gradient instead of a flat maroon outline.
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: AppColors.buildPrimaryGradient(),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(1.5),
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: ShaderMask(
                    blendMode: BlendMode.srcIn,
                    shaderCallback: (bounds) =>
                        AppColors.buildPrimaryGradient().createShader(
                          Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                        ),
                    child: const Text(
                      'Dismiss',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.white, // painted over by the gradient
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildSubtitle(String action) {
    if (role == 'parent') {
      final name = studentName != null && studentName!.isNotEmpty
          ? studentName!
          : 'your child';
      return 'GPS attendance is enabled. You can $action $name now.';
    } else {
      return 'GPS attendance is enabled. You can $action now.';
    }
  }

  String _resolveRoute() {
    if (role == 'parent') {
      final base = isSignedIn
          ? '/dashboard/student-selection-sign-out-form'
          : '/dashboard/student-selection-sign-in-form';
      // Pass the currently-viewed child so the form pre-selects them.
      final code = (studentCode ?? '').trim();
      return code.isNotEmpty
          ? '$base?studentCode=${Uri.encodeComponent(code)}'
          : base;
    } else {
      // staff or admin: gps=1 tells the form to always self-fill (incl. admin).
      return isSignedIn
          ? '/dashboard/staff-sign-out-form?gps=1'
          : '/dashboard/staff-sign-in-form?gps=1';
    }
  }
}
