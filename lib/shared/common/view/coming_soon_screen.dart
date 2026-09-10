import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';

class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key});

  static const String routeName = '/coming-soon-screen';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.asset(
              MediaRes.comingSoonLottie,
              width: MediaQuery.of(context).size.width * 0.8,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.1),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: AppSurfaces.key(KeyVariant.primary, radius: 16),
                child: const Text(
                  'Go Back',
                  style: TextStyle(
                    color: AppColors.whiteColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

