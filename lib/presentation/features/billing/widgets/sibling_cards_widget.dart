import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_floating_text_button.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

/// Reusable widget for displaying sibling cards with balance and payment buttons
class SiblingCardsWidget extends StatelessWidget {
  final List<Map<String, String>> siblings;
  final double currentBalance;
  final bool isPaymentLoading;
  final VoidCallback? onPayNow;
  final VoidCallback? onAutoPay;

  const SiblingCardsWidget({
    super.key,
    required this.siblings,
    this.currentBalance = 0.0,
    this.isPaymentLoading = false,
    this.onPayNow,
    this.onAutoPay,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Card(
        elevation: 0,
        color: AppColors.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: AppColors.primaryColor.withValues(alpha: 0.1),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // Student grid - 2 columns
              GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 0,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2,
                ),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: siblings.length,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  final item = siblings[index];
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DocumentImageWidget(
                          fileUuid: '',
                          name: item['name'] ?? '',
                          size: 30,
                          fontSize: 12,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppText.value(
                                item['name'] ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.value.copyWith(
                                  color: AppColors.primaryColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              AppText.value(
                                item['room'] ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.value.copyWith(
                                  fontSize: 12,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              // Balance and payment buttons
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Text(
                          '\$${currentBalance.toStringAsFixed(2)}',
                          style: AppTextStyles.title.copyWith(
                            color: AppColors.themeColor,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Current\nBalance',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.title.copyWith(
                            color: AppColors.primaryColor.withValues(alpha: 0.8),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: isPaymentLoading
                        ? Container(
                            height: 45,
                            decoration: BoxDecoration(
                              gradient: AppColors.buildPrimaryGradient(),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(AppColors.cardColor),
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: CustomFloatingTextButton(
                                  height: 45,
                                  onPressed: onPayNow,
                                  label: 'Pay Now',
                                  textStyle: AppTextStyles.button(
                                    color: AppColors.themeColor,
                                  ).copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  isFilled: false,
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: CustomFloatingTextButton(
                                  height: 45,
                                  onPressed: onAutoPay,
                                  label: 'Auto Pay',
                                  textStyle: AppTextStyles.button(
                                    color: AppColors.themeColor,
                                  ).copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  isFilled: false,
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

