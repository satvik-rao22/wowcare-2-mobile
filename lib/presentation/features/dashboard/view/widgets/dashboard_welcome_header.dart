import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';

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
          style: AppTextStyles.display.copyWith(color: AppColors.primaryColor),
        ),
        if (showSectionLabel) ...[
          const SizedBox(height: 16),
          Text(
            'Need your attention',
            style: AppTextStyles.heading.copyWith(
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ],
    );
  }
}
