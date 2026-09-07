import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/router/app_routes.dart';

/// Shown by `appRouter`'s `errorBuilder` when no route matches a location.
///
/// Without this, go_router falls back to its own `ErrorScreen`: a red page
/// rendering the raw exception and the attempted URI — in release builds, not
/// just debug. The app's primary entry point is a notification- or
/// email-carried URL, so an unmatched location is a realistic production path
/// (a malformed deep link, a stale notification payload, a renamed segment),
/// not just a developer mistake.
///
/// Deliberately offers a way out rather than auto-redirecting: a silent bounce
/// to the dashboard would hide a broken link from the person best placed to
/// report it. The attempted location is shown so it can be quoted in a bug
/// report, and it is logged by the `errorBuilder` that builds this.
class RouteNotFoundScreen extends StatelessWidget {
  const RouteNotFoundScreen({required this.attemptedLocation, super.key});

  /// The location go_router could not match, e.g. `/dashboard/typo?code=1`.
  final String attemptedLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cardColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.link_off,
                  size: 48,
                  color: AppColors.primaryColor.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),
                const Text(
                  "This link didn't open",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'The page it points to no longer exists, or the link is '
                  'incomplete. You can go back to your dashboard and try again '
                  'from there.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: AppColors.primaryColor.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 20),
                // Shown so a user can quote it when reporting the broken link.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    attemptedLocation,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.primaryColor.withValues(alpha: 0.6),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go(DashboardRoutes.root),
                  child: const Text('Go to dashboard'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
