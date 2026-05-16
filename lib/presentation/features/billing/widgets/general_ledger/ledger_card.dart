import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';

class LedgerCard extends StatefulWidget {
  const LedgerCard({
    super.key,
    required this.ledgerName,
    required this.type,
    required this.openBalance,
    this.onEdit,
    this.onDelete,
  });

  final String ledgerName;
  final String type;
  final double openBalance;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  State<LedgerCard> createState() => _LedgerCardState();
}

class _LedgerCardState extends State<LedgerCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return IntrinsicHeight(
          child: Container(
            width: constraints.maxWidth,
            height: _isExpanded ? null : 64,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.billingCardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.billingBorderLight, width: 1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.billingCardShadowColor,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: AppColors.billingTransparentColor,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Column(
                  children: [
                    Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.center,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              widget.ledgerName,
                              style: AppTextStyles.value.copyWith(
                                color: AppColors.billingTextColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isExpanded) ...[
                      const Divider(
                        height: 1,
                        thickness: 1,
                        indent: 16,
                        endIndent: 16,
                        color: AppColors.billingDividerLight,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Type',
                                  style: AppTextStyles.small.copyWith(
                                    color: AppColors.billingTextColor,
                                  ),
                                ),
                                ShaderMask(
                                  shaderCallback: (bounds) {
                                    return AppColors.buildPrimaryGradient()
                                        .createShader(
                                          Rect.fromLTWH(
                                            0,
                                            0,
                                            bounds.width,
                                            bounds.height,
                                          ),
                                        );
                                  },
                                  child: Text(
                                    widget.type,
                                    style: AppTextStyles.label.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.billingCardColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Open Balance',
                                  style: AppTextStyles.small.copyWith(
                                    color: AppColors.billingTextColor,
                                  ),
                                ),
                                Text(
                                  '\$${widget.openBalance.toStringAsFixed(0)}',
                                  style: AppTextStyles.label.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.billingTextColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 40,
                                    child: OutlinedButton(
                                      onPressed: widget.onDelete,
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: AppColors.themeColor,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: Text(
                                        'Delete',
                                        style: AppTextStyles.button(
                                          color: AppColors.themeColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      gradient:
                                          AppColors.buildPrimaryGradient(),
                                    ),
                                    child: TextButton(
                                      onPressed: widget.onEdit,
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: Text(
                                        'Edit',
                                        style: AppTextStyles.button(
                                          color:
                                              AppColors.billingButtonTextColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
