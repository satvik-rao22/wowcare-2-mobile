import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/billing/billing_strings.dart';
import 'package:wowcare/domain/features/billing/entities/family_ledger_entity.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

/// Reusable widget for displaying student cards with balance and payment buttons.
class SiblingCardsWidget extends StatelessWidget {
  final List<FamilyLedgerPersonEntity> students;
  final double currentBalance;
  final double paid;
  final double netPaid;
  final double refunded;
  final double unpaid;
  final double inProcess;
  final bool isPaymentLoading;
  final bool isAutoPayLoading;
  final VoidCallback? onPayNow;
  final VoidCallback? onAutoPay;

  const SiblingCardsWidget({
    super.key,
    required this.students,
    this.currentBalance = 0.0,
    this.paid = 0.0,
    this.netPaid = 0.0,
    this.refunded = 0.0,
    this.unpaid = 0.0,
    this.inProcess = 0.0,
    this.isPaymentLoading = false,
    this.isAutoPayLoading = false,
    this.onPayNow,
    this.onAutoPay,
  });

  /// Family billing totals from the ledger (paid / net paid / refunded / …).
  Widget _statsSection() {
    final items = <List<dynamic>>[
      [BillingStrings.paid, paid, const Color(0xFF2E9E5B)],
      [BillingStrings.netPaid, netPaid, AppColors.themeColor],
      [BillingStrings.refunded, refunded, const Color(0xFFE08600)],
      [BillingStrings.unpaid, unpaid, const Color(0xFFD64545)],
      [BillingStrings.inProcess, inProcess, AppColors.billingAccentBlue],
    ];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.billingSurfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorderColor),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final it in items)
            _statTile(it[0] as String, it[1] as double, it[2] as Color),
        ],
      ),
    );
  }

  Widget _statTile(String label, double value, Color color) {
    return SizedBox(
      width: 90,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\$${value.toStringAsFixed(2)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.value.copyWith(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.value.copyWith(
              color: AppColors.billingTextColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

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
            color: AppColors.cardBorderColor,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (students.isNotEmpty)
                GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 20,
                    childAspectRatio: 3.5,
                  ),
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: students.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return Row(
                      children: [
                        DocumentImageWidget(
                          fileUuid: '',
                          name: student.fullName,
                          size: 30,
                          fontSize: 12,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText.value(
                                student.fullName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.value.copyWith(
                                  color: AppColors.billingTextColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (student.role.isNotEmpty)
                                AppText.value(
                                  student.role,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.value.copyWith(
                                    fontSize: 12,
                                    color: AppColors.billingTextColor,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              const SizedBox(height: 16),
              _statsSection(),
              const SizedBox(height: 16),
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
                          BillingStrings.currentBalance,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.title.copyWith(
                            color: AppColors.billingTextColor,
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomButtonLayout(
                          confirmButtonLabel: BillingStrings.payNow,
                          onPressedConfirm: onPayNow,
                          showCancelButton: false,
                          isForm: false,
                          isLoading: isPaymentLoading,
                        ),
                        const SizedBox(height: 10),
                        CustomButtonLayout(
                          confirmButtonLabel: BillingStrings.autoPay,
                          onPressedConfirm: onAutoPay,
                          showCancelButton: false,
                          isForm: false,
                          isLoading: isAutoPayLoading,
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