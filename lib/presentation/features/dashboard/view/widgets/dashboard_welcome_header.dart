import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/skeu/skeu.dart';
import 'package:wowcare/core/util/app_time.dart';

/// Greeting block at the top of the dashboard feed: "Welcome {name}", today's
/// date, and an optional "Need your attention" section label.
class DashboardWelcomeHeader extends StatelessWidget {
  const DashboardWelcomeHeader({
    super.key,
    required this.userName,
    this.showSectionLabel = true,
    this.subtitlePrefix,
  });

  final String userName;

  /// Whether to show the "Need your attention" sub-label (admin dashboard
  /// only — the staff dashboard hides it).
  final bool showSectionLabel;

  /// Optional leading half of the date line, normally the current school's
  /// name: "Sunshine Kids Academy · Monday, 17 August".
  final String? subtitlePrefix;

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, d MMMM').format(AppTime.now());
    final subtitle = (subtitlePrefix == null || subtitlePrefix!.isEmpty)
        ? today
        : '$subtitlePrefix · $today';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Welcome $userName', style: SkeuText.stat()),
        const SizedBox(height: 4),
        Text(subtitle, style: SkeuText.small()),
        if (showSectionLabel) ...[
          const SizedBox(height: 16),
          Text(
            'Need your attention',
            style: SkeuText.title(
              weight: SkeuText.weightHeading,
            ).copyWith(fontSize: 18),
          ),
        ],
      ],
    );
  }
}
