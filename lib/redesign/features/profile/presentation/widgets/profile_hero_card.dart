import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/profile/cubit/profile_cubit.dart';
import 'package:wowcare/redesign/features/profile/presentation/widgets/hero_avatar.dart';
import 'package:wowcare/redesign/features/profile/presentation/widgets/photo_block.dart';
import 'package:wowcare/redesign/features/profile/profile_sizes.dart';
import 'package:wowcare/redesign/features/profile/profile_strings.dart';
import 'package:wowcare/redesign/features/profile/profile_text_styles.dart';

/// The card at the top of 13a, 13c and 13f: who is signed in, which roles
/// this account holds here, how fresh the record is, and the photo.
///
/// The roles line is all 13d's Switch Profile leaves behind here. Switching
/// belongs to the Account page, and this screen only reports.
class ProfileHeroCard extends StatelessWidget {
  const ProfileHeroCard({
    required this.state,
    required this.onChangePhoto,
    required this.onRetryPhoto,
    super.key,
  });

  final ProfileState state;
  final VoidCallback onChangePhoto;
  final VoidCallback onRetryPhoto;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final record = state.record!;
    final isGuardian = state.isGuardianLens;

    return AppCard(
      raised: true,
      padding: ProfileSizes.heroPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: ProfileSizes.heroGap,
        children: <Widget>[
          Row(
            spacing: ProfileSizes.heroGap,
            children: <Widget>[
              HeroAvatar(
                initials: record.initials,
                hasPhoto: record.hasPhoto,
                photo: state.photo,
                isGuardian: isGuardian,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: ProfileSizes.heroTextGap,
                  children: <Widget>[
                    Text(
                      record.fullName,
                      style: AppTextStyles.detailTitle.copyWith(color: c.ink),
                    ),
                    Text(
                      ProfileStrings.roleLine(
                        record.designation,
                        record.schoolName,
                      ),
                      style: ProfileTextStyles.heroRole.copyWith(color: c.ink3),
                    ),
                    if (record.roleLabels.isNotEmpty)
                      Wrap(
                        spacing: ProfileSizes.roleChipGap,
                        runSpacing: ProfileSizes.roleChipGap,
                        children: <Widget>[
                          for (final label in record.roleLabels)
                            _RoleChip(label: label),
                        ],
                      ),
                    Text(
                      state.isOffline
                          ? ProfileStrings.savedOnPhone(
                              state.cachedAtLabel ?? '',
                            )
                          : ProfileStrings.loadedJustNow,
                      style: ProfileTextStyles.heroNote.copyWith(
                        color: state.isOffline ? c.staffFg : c.successFg,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          PhotoBlock(
            photo: state.photo,
            hasPhoto: record.hasPhoto,
            progress: state.photoProgress,
            onChange: onChangePhoto,
            onRetry: onRetryPhoto,
          ),
        ],
      ),
    );
  }
}

/// One role this account holds at this school. Neutral: role carries no
/// colour, so Admin and Parent are the same material.
class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    return SurfaceBox(
      surface: AppSurfaces.pill(fill: c.neutralBg),
      padding: ProfileSizes.roleChipPad,
      child: Text(
        label,
        style: ProfileTextStyles.roleChip.copyWith(color: c.ink2),
      ),
    );
  }
}
