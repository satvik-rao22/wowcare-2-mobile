import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/responsive/responsive_scope.dart';
import 'package:wowcare/core/theme/app_haptics.dart';
import 'package:wowcare/core/theme/app_radius.dart';
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/theme/skeu_decoration.dart';
import 'package:wowcare/domain/features/app_update/entities/app_update_status.dart';
import 'package:wowcare/presentation/features/app_update/app_update_strings.dart';
import 'package:wowcare/presentation/features/app_update/view_model/app_update_cubit.dart';
import 'package:wowcare/presentation/features/app_update/widgets/pulsing_logo_mark.dart';
import 'package:wowcare/presentation/features/app_update/widgets/update_key.dart';

/// S1: the optional update, sitting *in* the dashboard above the attention
/// deck. The app underneath stays fully usable. The cross and Not now do the
/// same thing, and it stays away for a week.
///
/// Renders nothing, not even its gap, unless there is an optional update to
/// show, so a dashboard with no update lays out exactly as it did.
class OptionalUpdateBanner extends StatelessWidget {
  const OptionalUpdateBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: AppMotion.panel,
      curve: AppMotion.easeOut,
      alignment: Alignment.topCenter,
      child: BlocBuilder<AppUpdateCubit, AppUpdateState>(
        buildWhen: (AppUpdateState a, AppUpdateState b) =>
            a.showsOptional != b.showsOptional ||
            a.status != b.status ||
            a.storeUnavailable != b.storeUnavailable,
        builder: (BuildContext context, AppUpdateState state) {
          final AppUpdateStatus? status = state.status;
          if (!state.showsOptional || status == null) {
            return const SizedBox(width: double.infinity);
          }
          final _BannerCopy copy = _BannerCopy(status, state.storeUnavailable);
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: context.isTablet
                ? _WideBanner(copy: copy)
                : _CompactBanner(copy: copy),
          );
        },
      ),
    );
  }
}

/// Everything the two layouts print, resolved once.
class _BannerCopy {
  _BannerCopy(AppUpdateStatus status, bool storeUnavailable)
    : title =
          status.policy.title ??
          AppUpdateStrings.optionalTitle(status.policy.latestVersionName),
      installed = AppUpdateStrings.youAreOn(status.installed.name),
      foot = status.policy.message ?? AppUpdateStrings.optionalFoot,
      storeKey = AppUpdateStrings.updateIn(status.store),
      unavailable = storeUnavailable
          ? AppUpdateStrings.storeUnavailable(status.store)
          : null;

  final String title;
  final String installed;
  final String foot;
  final String storeKey;
  final String? unavailable;
}

/// The banner's face: a card with a pink hairline, so it reads as a note
/// from the app rather than one more dashboard card.
SkeuDecoration _face(double radius) => AppSurfaces.card(
  radius: radius,
).copyWith(border: Border.all(color: AppPalette.brand.withValues(alpha: .28)));

class _CompactBanner extends StatelessWidget {
  const _CompactBanner({required this.copy});

  final _BannerCopy copy;

  @override
  Widget build(BuildContext context) {
    final AppUpdateCubit cubit = context.read<AppUpdateCubit>();
    return DecoratedBox(
      decoration: _face(AppRadius.r22),
      child: Stack(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 16, 15, 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const Center(
                  child: PulsingLogoMark(spec: PulsingMarkSpec.optional),
                ),
                AppSpacing.gapVSm,
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s6,
                  ),
                  child: Column(
                    children: <Widget>[
                      Text(
                        AppUpdateStrings.optionalEyebrow.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: AppTextStyles.appUpdateEyebrow,
                      ),
                      const SizedBox(height: AppSpacing.s6),
                      Text(
                        copy.title,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.appUpdateTitle,
                      ),
                      const SizedBox(height: AppSpacing.s6),
                      Text(
                        copy.installed,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.appUpdateMeta,
                      ),
                    ],
                  ),
                ),
                AppSpacing.gapVSm,
                Row(
                  children: <Widget>[
                    UpdateKey(
                      label: AppUpdateStrings.notNow,
                      variant: KeyVariant.secondary,
                      padding: const EdgeInsets.symmetric(
                        vertical: 13,
                        horizontal: AppSpacing.s18,
                      ),
                      onTap: cubit.dismissOptional,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: UpdateKey(
                        label: copy.storeKey,
                        onTap: cubit.openStore,
                      ),
                    ),
                  ],
                ),
                AppSpacing.gapVSm,
                Text(copy.foot, style: AppTextStyles.appUpdateFoot),
                if (copy.unavailable != null) _Unavailable(copy.unavailable!),
              ],
            ),
          ),
          Positioned(
            top: 3,
            right: 3,
            child: _DismissButton(size: 28, onTap: cubit.dismissOptional),
          ),
        ],
      ),
    );
  }
}

/// ST1: on a tablet the banner lies flat beside its mark, one row of keys.
class _WideBanner extends StatelessWidget {
  const _WideBanner({required this.copy});

  final _BannerCopy copy;

  @override
  Widget build(BuildContext context) {
    final AppUpdateCubit cubit = context.read<AppUpdateCubit>();
    const EdgeInsets keyPadding = EdgeInsets.symmetric(
      vertical: AppSpacing.sm,
      horizontal: AppSpacing.lg,
    );
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s18),
      decoration: _face(AppRadius.r24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const PulsingLogoMark(spec: PulsingMarkSpec.optionalWide),
          AppSpacing.gapHMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(copy.title, style: AppTextStyles.appUpdateTitle),
                AppSpacing.gapVXs,
                Text(
                  copy.installed,
                  style: AppTextStyles.appUpdateMeta.copyWith(fontSize: 13.4),
                ),
                const SizedBox(height: AppSpacing.s10),
                Row(
                  children: <Widget>[
                    UpdateKey(
                      label: copy.storeKey,
                      radius: AppRadius.r15,
                      padding: keyPadding,
                      onTap: cubit.openStore,
                    ),
                    const SizedBox(width: AppSpacing.s10),
                    UpdateKey(
                      label: AppUpdateStrings.notNow,
                      variant: KeyVariant.secondary,
                      radius: AppRadius.r15,
                      padding: keyPadding.copyWith(
                        left: AppSpacing.s18,
                        right: AppSpacing.s18,
                      ),
                      onTap: cubit.dismissOptional,
                    ),
                    const SizedBox(width: AppSpacing.s10),
                    Expanded(
                      child: Text(
                        copy.foot,
                        style: AppTextStyles.appUpdateFoot,
                      ),
                    ),
                  ],
                ),
                if (copy.unavailable != null) _Unavailable(copy.unavailable!),
              ],
            ),
          ),
          _DismissButton(size: 30, onTap: cubit.dismissOptional),
        ],
      ),
    );
  }
}

class _Unavailable extends StatelessWidget {
  const _Unavailable(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Text(
        message,
        style: AppTextStyles.appUpdateFoot.copyWith(
          color: AppPalette.statusErrorStrong,
        ),
      ),
    );
  }
}

/// The cross in the corner. Drawn at [size] but hit-tested over 44px, so it
/// is easy to reach without looking bigger than the design.
class _DismissButton extends StatelessWidget {
  const _DismissButton({required this.size, required this.onTap});

  final double size;
  final VoidCallback onTap;

  static const double _target = 44;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppUpdateStrings.dismiss,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptics.tap();
          onTap();
        },
        child: SizedBox.square(
          dimension: _target,
          child: Center(
            child: Container(
              width: size,
              height: size,
              decoration: AppSurfaces.well(
                radius: size / 2,
                color: AppPalette.surfaceMuted,
              ),
              child: Icon(
                Icons.close_rounded,
                size: size / 2,
                color: AppPalette.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
