import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/presentation/features/billing/model/billing_family_member.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

/// Widget displaying siblings, current balance, and generate button
class ParentStatementsWidget extends StatelessWidget {
  final List<BillingFamilyMember> familyChildren;
  final double currentBalance;
  final bool isLoading;
  final VoidCallback onGenerate;

  const ParentStatementsWidget({
    super.key,
    required this.familyChildren,
    required this.currentBalance,
    required this.isLoading,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    // The sibling list/balance is static data, so it stays visible at all times.
    // `isLoading` only reflects the (simulated) "Generate" action, which is shown
    // on the Generate button below — it must not blank out the panel.
    if (familyChildren.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorderColor, width: 1),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Students Grid - reuse sibling cards widget but without payment buttons
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: familyChildren.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 16,
              childAspectRatio: 3.5,
            ),
            itemBuilder: (context, index) {
              final child = familyChildren[index];
              final name = child.name ?? child.fullName ?? 'Unknown';
              final room = child.room ?? child.roomName ?? '';

              // Match the Student(s) tiles on the parent Billing screen
              // (SiblingCardsWidget): 30px avatar, name 14/w600, role 12.
              return Row(
                children: [
                  DocumentImageWidget(
                    fileUuid: '',
                    name: name,
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
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.value.copyWith(
                            color: AppColors.billingTextColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        if (room.isNotEmpty)
                          AppText.value(
                            room,
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
          const SizedBox(height: 24),
          // Balance + Generate button
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.value(
                    '\$${currentBalance.toStringAsFixed(2)}',
                    style: AppTextStyles.value.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.themeColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AppText.value(
                    'Current\nBalance',
                    style: AppTextStyles.value.copyWith(
                      fontSize: 16,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              OutlinedButton(
                onPressed: isLoading ? null : onGenerate,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.themeColor, width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.themeColor,
                          ),
                        ),
                      )
                    : AppText.value(
                        'Generate',
                        style: AppTextStyles.value.copyWith(
                          color: AppColors.themeColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

