import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/routing/app_routes.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/loading_ring.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/status_pill.dart';
import 'package:wowcare/redesign/features/auth/auth_sizes.dart';
import 'package:wowcare/redesign/features/auth/auth_strings.dart';
import 'package:wowcare/redesign/features/auth/cubit/kiosk_scanner_cubit.dart';
import 'package:wowcare/redesign/features/auth/models/models.dart';
import 'package:wowcare/redesign/features/auth/presentation/widgets/scanner_viewfinder.dart';

/// 2a. The scanner a signed-in phone opens from Scan QR on its dashboard.
///
/// The one screen in the app drawn on navy rather than the warm tray, because
/// a camera preview needs the chrome to get out of its way. Everything on it
/// is warm white at an alpha, which is the same lit-from-above rule the rest
/// of the app follows, read on a dark ground.
class KioskScannerPage extends StatelessWidget {
  const KioskScannerPage({super.key});

  /// What the fixture hands back when the viewfinder is tapped. The real
  /// scanner passes whatever the camera read.
  static const String _demoPayload = 'wowcare://kiosk/demo';

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final cubit = context.read<KioskScannerCubit>();

    return Scaffold(
      backgroundColor: c.impact,
      body: SafeArea(
        child: BlocConsumer<KioskScannerCubit, KioskScannerState>(
          listenWhen: (previous, current) =>
              previous.result != current.result && current.result != null,
          listener: (context, state) {
            final result = state.result!;
            context.pushReplacement(
              result.isMixed ? AppRoutes.kioskChoice : AppRoutes.kioskFamily,
              extra: result.isMixed
                  ? result
                  : KioskFamilyArgs(
                      result: result,
                      isSigningIn: result.signedInStudents.isEmpty,
                    ),
            );
          },
          builder: (context, state) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _header(context, c, state),
              Expanded(child: _viewfinder(c, state, cubit)),
              _footer(c, cubit),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, Colourway c, KioskScannerState state) =>
      Padding(
        padding: AuthSizes.scannerHeaderPad,
        child: Row(
          spacing: AuthSizes.scannerHeaderGap,
          children: <Widget>[
            _GlassKey(
              icon: AppIcons.close,
              semanticLabel: AuthStrings.closeScanner,
              onTap: () => context.pop(),
            ),
            Expanded(
              child: Text(
                AuthStrings.scanQrCode,
                style: AppTextStyles.moduleTitle.copyWith(color: c.onImpact),
              ),
            ),
            StatusPill(
              label: state.isUnreadable
                  ? AuthStrings.rescan
                  : AuthStrings.inRange,
              background: c.success.withValues(alpha: AuthSizes.inRangeAlpha),
              foreground: c.onImpact,
            ),
          ],
        ),
      );

  Widget _viewfinder(
    Colourway c,
    KioskScannerState state,
    KioskScannerCubit cubit,
  ) => Padding(
    padding: AuthSizes.scannerBodyPad,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: AuthSizes.scannerBodyGap,
      children: <Widget>[
        if (state.isReading)
          SizedBox.square(
            dimension: AuthSizes.viewfinder,
            child: Center(
              child: LoadingRing(size: AuthSizes.qrRing, color: c.staff),
            ),
          )
        else
          ScannerViewfinder(
            onTap: () => unawaited(cubit.scanned(_demoPayload)),
          ),
        Text(
          AuthStrings.pointCamera,
          textAlign: TextAlign.center,
          style: AppTextStyles.alertText.copyWith(
            color: c.onImpact.withValues(alpha: AuthSizes.scannerCaptionAlpha),
          ),
        ),
      ],
    ),
  );

  Widget _footer(Colourway c, KioskScannerCubit cubit) => Padding(
    padding: AuthSizes.scannerFooterPad,
    child: Row(
      spacing: AuthSizes.scannerKeyGap,
      children: <Widget>[
        Expanded(
          child: _GlassKey.wide(
            label: AuthStrings.torch,
            onTap: cubit.toggleTorch,
          ),
        ),
        Expanded(
          child: _GlassKey.wide(
            label: AuthStrings.flipCamera,
            onTap: cubit.flipCamera,
          ),
        ),
      ],
    ),
  );
}

/// A key on the navy ground: warm white at an alpha, lit along its top edge.
class _GlassKey extends StatelessWidget {
  const _GlassKey({
    required IconData this.icon,
    required this.semanticLabel,
    required this.onTap,
  }) : label = null;

  const _GlassKey.wide({required String this.label, required this.onTap})
    : icon = null,
      semanticLabel = null;

  final IconData? icon;
  final String? label;
  final String? semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final isTile = icon != null;

    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      child: Pressable.surface(
        onTap: onTap,
        child: Container(
          width: isTile ? AuthSizes.scannerCloseTile : null,
          height: isTile ? AuthSizes.scannerCloseTile : null,
          padding: isTile ? null : AuthSizes.scannerKeyPad,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: c.onImpact.withValues(alpha: AuthSizes.scannerTileAlpha),
            borderRadius: isTile ? AppRadii.innerR : AppRadii.cardR,
          ),
          child: isTile
              ? Icon(
                  icon,
                  size: AuthSizes.scannerCloseGlyph,
                  color: c.onImpact,
                )
              : Text(
                  label!,
                  style: AppTextStyles.keyLabel.copyWith(color: c.onImpact),
                ),
        ),
      ),
    );
  }
}
