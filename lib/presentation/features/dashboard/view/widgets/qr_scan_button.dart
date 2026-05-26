import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/qr_validation_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view/QR_Code_scanner.dart';

class QrScanButton extends StatelessWidget {
  const QrScanButton({super.key, required this.args});

  final QrScannerArgs args;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => QrScanScreen(args: args),
          ),
        );
      },
      icon: SvgPicture.asset(MediaRes.scannerGradientIcon),
    );
  }
}
