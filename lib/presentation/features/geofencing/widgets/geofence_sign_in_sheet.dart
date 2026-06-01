import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/theme/colors.dart';

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
  });

  /// 'parent' | 'staff' | 'admin'
  final String role;

  /// Whether the user (or their child, for parent role) is already signed in.
  final bool isSignedIn;

  /// Child name for parent role display.
  final String? studentName;

  static Future<void> show(
    BuildContext context, {
    required String role,
    required bool isSignedIn,
    String? studentName,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => GeofenceSignInSheet(
        role: role,
        isSignedIn: isSignedIn,
        studentName: studentName,
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
        color: Colors.white,
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
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // ── icon ──────────────────────────────────────────────────────
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryColor.withValues(alpha: 0.1),
            ),
            child: Icon(
              Icons.location_on_rounded,
              color: AppColors.primaryColor,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),

          // ── headline ──────────────────────────────────────────────────
          Text(
            headline,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // ── subtitle ──────────────────────────────────────────────────
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
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
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.themeColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(context);
                context.go(route);
              },
              child: Text(
                action,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── dismiss ───────────────────────────────────────────────────
          // SizedBox(
          //   width: double.infinity,
          //   height: 48,
          //   child: TextButton(
          //     onPressed: () => Navigator.pop(context),
          //     child: Text(
          //       'Dismiss',
          //       style: TextStyle(fontSize: 14, color: AppColors.primaryColor),
          //     ),
          //   ),
          // ),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: AppColors.themeColor, width: 1),
                ),
              ),
              child: Text(
                'Dismiss',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w500,
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
      return isSignedIn
          ? '/dashboard/student-selection-sign-out-form'
          : '/dashboard/student-selection-sign-in-form';
    } else {
      // staff or admin
      return isSignedIn
          ? '/dashboard/staff-sign-out-form'
          : '/dashboard/staff-sign-in-form';
    }
  }
}
