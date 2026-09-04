import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/features/profile/profile_sizes.dart';
import 'package:wowcare/redesign/features/profile/profile_strings.dart';

/// 13f's loading state: the shape of the record before the record arrives.
///
/// A skeleton rather than a bare spinner because the profile is one fixed
/// layout every time, so the page can be drawn before it is filled.
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: ProfileSizes.cardGap,
      children: <Widget>[
        AppCard(
          padding: ProfileSizes.heroPad,
          child: Row(
            spacing: ProfileSizes.heroGap,
            children: <Widget>[
              Container(
                width: ProfileSizes.heroAvatar,
                height: ProfileSizes.heroAvatar,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.well,
                ),
              ),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: ProfileSizes.skeletonGap,
                  children: <Widget>[
                    _Bar(
                      widthFactor: ProfileSizes.skeletonNameWidth,
                      height: ProfileSizes.skeletonLine,
                    ),
                    _Bar(
                      widthFactor: ProfileSizes.skeletonRoleWidth,
                      height: ProfileSizes.skeletonSub,
                      isFaint: true,
                    ),
                    _Bar(
                      widthFactor: ProfileSizes.skeletonNoteWidth,
                      height: ProfileSizes.skeletonSub,
                      isFaint: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const AppCard(
          padding: ProfileSizes.detailCardPad,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: ProfileSizes.detailGap,
            children: <Widget>[
              _Bar(widthFactor: 1, height: ProfileSizes.skeletonWell),
              _Bar(widthFactor: 1, height: ProfileSizes.skeletonWell),
              _Bar(widthFactor: 1, height: ProfileSizes.skeletonWell),
            ],
          ),
        ),
        Text(
          ProfileStrings.loadingProfile,
          textAlign: TextAlign.center,
          style: AppTextStyles.subLine.copyWith(color: c.ink3),
        ),
      ],
    );
  }
}

/// One placeholder bar. [isFaint] is the shallower of the two greys.
class _Bar extends StatelessWidget {
  const _Bar({
    required this.widthFactor,
    required this.height,
    this.isFaint = false,
  });

  final double widthFactor;
  final double height;
  final bool isFaint;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    return Align(
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: widthFactor,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: isFaint ? c.altWell : c.well,
            borderRadius: BorderRadius.circular(
              height > ProfileSizes.skeletonLine
                  ? ProfileSizes.valueRadius
                  : ProfileSizes.skeletonLineRadius,
            ),
          ),
        ),
      ),
    );
  }
}
