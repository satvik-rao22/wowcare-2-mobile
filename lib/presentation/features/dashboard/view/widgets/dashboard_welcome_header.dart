import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';

/// Greeting block at the top of the dashboard feed: "Welcome {name}" plus the
/// "Need your attention" section label.
class DashboardWelcomeHeader extends StatelessWidget {
  const DashboardWelcomeHeader({super.key, required this.userName});

  final String userName;

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
    );
  }
}
