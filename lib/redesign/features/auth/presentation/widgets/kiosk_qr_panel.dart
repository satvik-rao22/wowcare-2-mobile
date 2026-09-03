import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/redesign/core/constants/app_assets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/icon_key.dart';
import 'package:wowcare/redesign/core/widgets/inline_alert.dart';
import 'package:wowcare/redesign/core/widgets/loading_ring.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/auth/auth_sizes.dart';
import 'package:wowcare/redesign/features/auth/auth_strings.dart';
import 'package:wowcare/redesign/features/auth/cubit/kiosk_cubit.dart';

/// The QR half of the door screen, with 2e's four states inside it.
///
/// 2e is not a screen of its own: it is this panel drawn four ways, and the
/// frame's title says so. Pulling the door screen down cycles it, which is
/// what the frame demonstrates.
class KioskQrPanel extends StatelessWidget {
  const KioskQrPanel({
    required this.schoolName,
    required this.status,
    required this.onRefresh,
    this.errorMessage,
    super.key,
  });

  final String schoolName;
  final KioskQrStatus status;
  final VoidCallback onRefresh;

  /// The line 2e's red alert carries. Null unless the fetch threw.
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Padding(
      padding: AuthSizes.qrHeadPad,
      child: Column(
        spacing: AuthSizes.qrHeadGap,
        children: <Widget>[
          Text(
            schoolName,
            style: AppTextStyles.detailTitle.copyWith(color: c.ink),
          ),
          Text(
            _caption,
            style: AppTextStyles.body.copyWith(color: c.ink2),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AuthSizes.qrTopGap),
            child: _panel(c),
          ),
          if (errorMessage != null) InlineAlert(message: errorMessage!),
        ],
      ),
    );
  }

  String get _caption => switch (status) {
    KioskQrStatus.loading => AuthStrings.loadingQr,
    KioskQrStatus.ready => AuthStrings.scanTheQr,
    KioskQrStatus.notGenerated => AuthStrings.qrNotGenerated,
    KioskQrStatus.failed => AuthStrings.qrFailed,
  };

  Widget _panel(Colourway c) => switch (status) {
    KioskQrStatus.ready => _QrFrame(colours: c),
    KioskQrStatus.loading => const SizedBox.square(
      dimension: AuthSizes.qrPlaceholder,
      child: Center(
        child: LoadingRing(
          size: AuthSizes.qrRing,
          strokeWidth: AuthSizes.qrRingStroke,
        ),
      ),
    ),
    KioskQrStatus.notGenerated => _Placeholder(
      label: AuthStrings.qrNotGenerated,
      colours: c,
    ),
    KioskQrStatus.failed => Column(
      spacing: AuthSizes.qrCardGap,
      children: <Widget>[
        _Placeholder(label: AuthStrings.qrFailed, colours: c),
        IconKey(
          icon: AppIcons.refresh,
          semanticLabel: AuthStrings.refreshQr,
          onTap: onRefresh,
        ),
      ],
    ),
  };
}

/// The live code, in the white frame the door screen puts it in.
class _QrFrame extends StatelessWidget {
  const _QrFrame({required this.colours});

  final Colourway colours;

  @override
  Widget build(BuildContext context) => Container(
    padding: AuthSizes.qrFramePad,
    decoration: BoxDecoration(
      color: colours.onImpact,
      borderRadius: AppRadii.innerR,
      border: Border.all(
        color: colours.ink,
        width: AuthSizes.qrFrameBorder,
      ),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(AuthSizes.qrImageRadius),
      child: SvgPicture.asset(
        AppAssets.kioskQr,
        width: AuthSizes.qr,
        height: AuthSizes.qr,
        semanticsLabel: AuthStrings.scanTheQr,
      ),
    ),
  );
}

/// The recessed square that stands in for a code there is no code for.
class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.label, required this.colours});

  final String label;
  final Colourway colours;

  @override
  Widget build(BuildContext context) => SurfaceBox(
    surface: AppSurfaces.well(
      colours,
      radius: AuthSizes.qrPlaceholderRadius,
    ),
    width: AuthSizes.qrPlaceholder,
    height: AuthSizes.qrPlaceholder,
    padding: AuthSizes.qrPlaceholderPad,
    alignment: Alignment.center,
    child: Text(
      label,
      textAlign: TextAlign.center,
      style: AppTextStyles.cardTitle.copyWith(color: colours.ink),
    ),
  );
}
