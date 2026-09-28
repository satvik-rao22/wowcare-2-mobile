import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/theme/app_radius.dart';
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/domain/features/app_update/entities/app_update_status.dart';
import 'package:wowcare/presentation/features/app_update/app_update_strings.dart';
import 'package:wowcare/presentation/features/app_update/view_model/app_update_cubit.dart';
import 'package:wowcare/presentation/features/app_update/widgets/pulsing_logo_mark.dart';
import 'package:wowcare/presentation/features/app_update/widgets/update_key.dart';

/// S2: the required update, a layer *over* the app with the screen still
/// visible behind the scrim, so it reads as the app paused rather than a
/// dead end.
///
/// No cross and no Not now, by design: nobody should be signing a child in
/// on a version the school can no longer hear. Screen readers are held here
/// too ([BlockSemantics]); the only way out is the store key.
class RequiredUpdateOverlay extends StatelessWidget {
  const RequiredUpdateOverlay({super.key});

  /// Wide enough for the phone design, and no wider on a tablet.
  static const double _maxCardWidth = 440;

  @override
  Widget build(BuildContext context) {
    return BlockSemantics(
      child: Material(
        type: MaterialType.transparency,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: AppMotion.panel,
          curve: AppMotion.easeOut,
          builder: (BuildContext context, double t, Widget? child) =>
              Opacity(opacity: t, child: child),
          child: ColoredBox(
            color: AppPalette.scrim.withValues(alpha: .62),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _maxCardWidth),
                    child: BlocBuilder<AppUpdateCubit, AppUpdateState>(
                      buildWhen: (AppUpdateState a, AppUpdateState b) =>
                          a.status != b.status ||
                          a.storeUnavailable != b.storeUnavailable,
                      builder: (BuildContext context, AppUpdateState state) {
                        final AppUpdateStatus? status = state.status;
                        if (status == null) return const SizedBox.shrink();
                        return _RequiredCard(
                          status: status,
                          storeUnavailable: state.storeUnavailable,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RequiredCard extends StatelessWidget {
  const _RequiredCard({required this.status, required this.storeUnavailable});

  final AppUpdateStatus status;
  final bool storeUnavailable;

  @override
  Widget build(BuildContext context) {
    final String? latest = status.policy.latestVersionName;
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s18,
        AppSpacing.lg,
        AppSpacing.s18,
        AppSpacing.s18,
      ),
      decoration: AppSurfaces.panel(radius: AppRadius.r28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Center(child: PulsingLogoMark(spec: PulsingMarkSpec.required)),
          const SizedBox(height: AppSpacing.s14),
          Text(
            AppUpdateStrings.requiredEyebrow.toUpperCase(),
            textAlign: TextAlign.center,
            style: AppTextStyles.appUpdateEyebrow.copyWith(
              color: AppPalette.statusErrorStrong,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            status.policy.title ?? AppUpdateStrings.requiredTitle(latest),
            textAlign: TextAlign.center,
            style: AppTextStyles.appUpdateRequiredTitle,
          ),
          const SizedBox(height: 7),
          Text(
            status.policy.message ?? AppUpdateStrings.requiredBody,
            textAlign: TextAlign.center,
            style: AppTextStyles.appUpdateRequiredBody,
          ),
          const SizedBox(height: AppSpacing.s14),
          _VersionStep(
            now: status.installed.name,
            next: latest ?? AppUpdateStrings.latestVersion,
          ),
          const SizedBox(height: AppSpacing.s14),
          UpdateKey(
            label: AppUpdateStrings.getFrom(status.store, latest),
            radius: AppRadius.r18,
            padding: const EdgeInsets.all(AppSpacing.md),
            style: AppTextStyles.appUpdateKeyLarge,
            onTap: context.read<AppUpdateCubit>().openStore,
          ),
          if (storeUnavailable) ...<Widget>[
            AppSpacing.gapVSm,
            Text(
              AppUpdateStrings.storeUnavailable(status.store),
              textAlign: TextAlign.center,
              style: AppTextStyles.appUpdateFoot.copyWith(
                color: AppPalette.statusErrorStrong,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// "2.2.21 → 3.0.0", the arrow pulsing gently between the two.
class _VersionStep extends StatelessWidget {
  const _VersionStep({required this.now, required this.next});

  final String now;
  final String next;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: AppSurfaces.sub(radius: AppRadius.r18, bordered: true),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Flexible(child: Text(now, style: AppTextStyles.appUpdateVersionNow)),
          const SizedBox(width: AppSpacing.s10),
          const _PulsingArrow(),
          const SizedBox(width: AppSpacing.s10),
          Flexible(
            child: Text(next, style: AppTextStyles.appUpdateVersionNext),
          ),
        ],
      ),
    );
  }
}

/// `wcTick`: the arrow's opacity breathes between 35% and full over 2.4s.
/// Still, at full, under reduce motion.
class _PulsingArrow extends StatefulWidget {
  const _PulsingArrow();

  @override
  State<_PulsingArrow> createState() => _PulsingArrowState();
}

class _PulsingArrowState extends State<_PulsingArrow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tick = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  late final Animation<double> _opacity = Tween<double>(
    begin: .35,
    end: 1,
  ).animate(CurvedAnimation(parent: _tick, curve: Curves.easeInOut));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _tick.value = 1;
    } else if (!_tick.isAnimating) {
      _tick.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _tick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: const Icon(
        Icons.arrow_forward_rounded,
        size: 16,
        color: AppPalette.textMuted,
      ),
    );
  }
}
