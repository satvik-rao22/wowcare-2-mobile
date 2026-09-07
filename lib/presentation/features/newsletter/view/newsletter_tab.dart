import 'package:flutter/material.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/core/constants/app_strings.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/newsletter/view/sent_newsletter_tab.dart';

class NewsLatterTab extends StatefulWidget {
  const NewsLatterTab({super.key});

  @override
  State<NewsLatterTab> createState() => _NewsLatterTabState();
}

class _NewsLatterTabState extends State<NewsLatterTab>
    with SingleTickerProviderStateMixin {
  late TabController newsLetterTabController;

  @override
  void initState() {
    super.initState();
    newsLetterTabController = TabController(
      length: 1, // Only Sent tab is currently available
      vsync: this,
    );
    newsLetterTabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    newsLetterTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Transform.translate(
          offset: const Offset(0, 5),
          child: _NewsletterTabBar(controller: newsLetterTabController),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: TabBarView(
            controller: newsLetterTabController,
            physics: const NeverScrollableScrollPhysics(),
            children: const [
              SentNewsLetterTab(),
            ],
          ),
        ),
      ],
    );
  }
}

/// The newsletter tab bar.
///
/// A private widget rather than a `_build…()` method: a method returning a
/// Widget cannot be const, cannot take a key, and rebuilds with its whole
/// enclosing widget (§6).
class _NewsletterTabBar extends StatelessWidget {
  const _NewsletterTabBar({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final TabBar tabBar = TabBar(
      tabs: [
        Padding(
          padding: const EdgeInsets.only(right: AppSizes.md),
          child: _NewsletterTabChip(
            label: AppStrings.newsletterSentTab,
            isSelected: controller.index == 0,
          ),
        ),
      ],
      controller: controller,
      isScrollable: true,
      labelColor: AppColors.blackColor,
      unselectedLabelColor: AppColors.newsletterTabUnselectedLabel,
      tabAlignment: TabAlignment.center,
      indicatorColor: AppColors.transparentColor,
      labelPadding: const EdgeInsets.symmetric(horizontal: 0),
      dividerHeight: 0,
      indicator: const BoxDecoration(),
    );
    return Padding(
      padding: const EdgeInsets.all(AppSizes.xxs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [tabBar],
      ),
    );
  }
}

/// One selectable tab chip in [_NewsletterTabBar].
///
/// Near-identical to `_ParentNewsletterTabChip` in `parent_newsletter_screen`
/// — see the note there before merging them.
class _NewsletterTabChip extends StatelessWidget {
  const _NewsletterTabChip({required this.label, required this.isSelected});

  final String label;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Container(
        height: 40,
        // §7.6: `sizeOf`, not `of` — `.of` subscribes to the whole
        // MediaQueryData, so a width read re-runs on every keyboard open.
        // A continuous proportion, not a breakpoint choice, so it stays a
        // measurement rather than becoming `context.responsive(...)`.
        width: MediaQuery.sizeOf(context).width * 0.20,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.classroomStudentTabColor
              : AppColors.newsletterTabUnselectedBackground,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          border: Border.all(
            color: isSelected
                ? AppColors.themeColor
                : AppColors.transparentColor,
            width: 1.25,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.newsletterTabLabel.copyWith(
              color: isSelected
                  ? AppColors.primaryColor
                  : AppColors.primaryColor.withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
    );
  }
}
