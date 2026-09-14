import 'package:flutter/material.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/core/constants/app_strings.dart';
import 'package:wowcare/core/router/app_routes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/presentation/features/newsletter/view/parent_newsletter_list_tab.dart';
import 'package:wowcare/presentation/features/dashboard/view_model/student_newsletters_cubit.dart';
import 'package:wowcare/shared/common/app/cubits/parent_child_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/core/theme/app_colors.dart';

/// Parent-only newsletters screen (student-scoped API, separate from staff/admin sent list).
class ParentNewsletterScreen extends StatefulWidget {
  const ParentNewsletterScreen({super.key});

  static const String routeName = DashboardRoutes.parentNewsletter;

  @override
  State<ParentNewsletterScreen> createState() => _ParentNewsletterScreenState();
}

class _ParentNewsletterScreenState extends State<ParentNewsletterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _newsLetterTabController;
  String _trackedChildCode = '';

  @override
  void initState() {
    super.initState();
    _newsLetterTabController = TabController(length: 1, vsync: this);
    _newsLetterTabController.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSelectedChild();
  }

  void _syncSelectedChild() {
    final parentChild = context.read<ParentChildCubit>();
    if (!parentChild.isLoaded && !parentChild.isLoading) {
      Future.microtask(parentChild.ensureLoaded);
    }
    final nextCode = (parentChild.selectedChild?.code ?? '').trim();
    if (nextCode == _trackedChildCode) return;
    _trackedChildCode = nextCode;
    if (nextCode.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<StudentNewslettersCubit>().loadFirstPage(
        studentCode: nextCode,
      );
    });
  }

  @override
  void dispose() {
    _newsLetterTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ParentChildCubit, ParentChildState>(
      builder: (context, state) {
        final selectedCode = (state.selectedChild?.code ?? '').trim();
        if (selectedCode.isNotEmpty && selectedCode != _trackedChildCode) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _trackedChildCode = selectedCode;
            context.read<StudentNewslettersCubit>().loadFirstPage(
              studentCode: selectedCode,
            );
          });
        }

        return GlobalScaffold(
          hasBackButton: false,
          isParent: true,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(AppSizes.xxs, AppSizes.xxs, AppSizes.xxs, 0),
                child: Text(
                  AppStrings.newsletterTitle,
                  style: AppTextStyles.newsletterScreenTitle,
                ),
              ),
              const SizedBox(height: AppSizes.xs),
              Transform.translate(
                offset: const Offset(0, 5),
                child: _ParentNewsletterTabBar(
                  controller: _newsLetterTabController,
                ),
              ),
              const SizedBox(height: 14),
              const Expanded(child: ParentNewsletterListTab()),
            ],
          ),
        );
      },
    );
  }
}

/// The parent newsletter tab bar.
///
/// A private widget rather than a `_build…()` method (§6).
class _ParentNewsletterTabBar extends StatelessWidget {
  const _ParentNewsletterTabBar({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    final TabBar tabBar = TabBar(
      tabs: [
        Padding(
          padding: const EdgeInsets.only(right: AppSizes.md),
          child: _ParentNewsletterTabChip(
            label: AppStrings.newsletterTitle,
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

/// One selectable tab chip in [_ParentNewsletterTabBar].
///
/// NOT merged with `_NewsletterTabChip` in `newsletter_tab.dart`, though the
/// structure is the same. The two size and clip their label differently: this
/// one uses `minWidth: 118` plus horizontal padding and lets the text overflow
/// visibly on one line, the staff one takes a fixed 20% of screen width and
/// lets the text wrap. Merging them needs five configuration parameters to
/// keep both renderings byte-identical, which buys less than it costs (§6,
/// "do not abstract for its own sake"). Revisit if a third tab bar appears.
class _ParentNewsletterTabChip extends StatelessWidget {
  const _ParentNewsletterTabChip({
    required this.label,
    required this.isSelected,
  });

  final String label;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Tab(
      child: Container(
        height: 40,
        constraints: const BoxConstraints(minWidth: 118),
        padding: const EdgeInsets.symmetric(horizontal: 14),
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
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible,
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
