import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/dashboard/view/QR_Code_scanner.dart';

/// Tappable icon that opens the full-screen QR scanner.
///
/// Role detection, sign-in status, and useCase resolution are handled
/// internally by [QrValidationCubit] — no args needed here.
class QrScanButton extends StatelessWidget {
  const QrScanButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => const QrScanScreen(),
          ),
        );
      },
      icon: SvgPicture.asset(MediaRes.scannerGradientIcon),
    );
  }
}
