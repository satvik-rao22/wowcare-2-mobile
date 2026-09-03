import 'package:flutter/material.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';

/// Stands in for a screen that is not built yet, so every route resolves from
/// day one and a tap never lands on a red error page. Deleted module by module
/// as the real screens land.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    return Scaffold(
      backgroundColor: c.page,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.screenGutter),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.moduleTitle.copyWith(color: c.ink),
                ),
                const SizedBox(height: AppSizes.space2),
                Text(
                  AppStrings.comingSoon,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.subLine.copyWith(color: c.ink3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
