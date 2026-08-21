import 'package:flutter/material.dart';
import '../../../../../app/theme/colors.dart';

/// Greeting block at the top of the dashboard feed: "Welcome {name}" plus an
/// optional "Need your attention" section label.
class DashboardWelcomeHeader extends StatelessWidget {
  const DashboardWelcomeHeader({
    super.key,
    required this.userName,
    this.showSectionLabel = true,
  });

  final String userName;

  /// Whether to show the "Need your attention" sub-label (admin dashboard
  /// only — the staff dashboard hides it).
  final bool showSectionLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome $userName',
          style: const TextStyle(
            color: AppColors.primaryColor,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (showSectionLabel) ...[
          const SizedBox(height: 16),
          const Text(
            'Need your attention',
            style: TextStyle(
              color: AppColors.primaryColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
