import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/app/theme/colors.dart';

class BillingScreen extends StatelessWidget {
  const BillingScreen({super.key});

  static const String routeName = '/billing';

  @override
  Widget build(BuildContext context) {
    final double titleFontSize = ResponsiveSizing.titleFontSize(context);
    final double titleLineHeight = ResponsiveSizing.titleLineHeight(context);

    return GlobalScaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: ResponsiveSizing.contentPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Billing',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff573353),
                  height: titleLineHeight,
                ),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.cardBorderColor),
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.cardColor,
                ),
                child: const Text(
                  'Your billing overview will appear here.',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff573353),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
      showCustomNavigationBar: true,
    );
  }
}


