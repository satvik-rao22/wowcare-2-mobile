import 'package:flutter/material.dart';

import '../res/colors.dart';

class DeleteConfirmationBottomSheetWithImage extends StatelessWidget {
  final String name; // student name or generic subject name
  final String type;
  final String? planName; // optional plan name for plan actions
  final VoidCallback onDelete;
  final VoidCallback onCancel;
  final bool isLoading;

  const DeleteConfirmationBottomSheetWithImage({
    Key? key,
    required this.name,
    required this.type,
    required this.onDelete,
    required this.onCancel,
    this.planName,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeTablet = screenWidth > 900;
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    // Responsive dimensions
    final horizontalPadding = isLargeTablet
        ? 32.0
        : isTablet
        ? 24.0
        : 16.0;

    final verticalPadding = isLargeTablet
        ? 32.0
        : isTablet
        ? 24.0
        : 16.0;

    final titleFontSize = isLargeTablet
        ? 20.0
        : isTablet
        ? 18.0
        : 16.0;

    final buttonHeight = isLargeTablet
        ? 56.0
        : isTablet
        ? 48.0
        : 40.0;

    final buttonFontSize = isLargeTablet
        ? 18.0
        : isTablet
        ? 16.0
        : 14.0;

    final borderRadius = isLargeTablet
        ? 24.0
        : isTablet
        ? 20.0
        : 16.0;

    final imageSize = isLargeTablet
        ? 80.0
        : isTablet
        ? 70.0
        : 60.0;

    final bool isPlanAction =
        type == 'plan_cancel' || type == 'plan_pause' || type == 'plan_resume';

    final String typeText = isPlanAction
        ? (type == 'plan_cancel'
              ? 'Do you want to cancel this plan - "${planName ?? ''}" for student $name?'
              : type == 'plan_resume'
              ? 'Do you want to resume this plan - "${planName ?? ''}" for student $name?'
              : 'Do you want to pause this plan - "${planName ?? ''}" for student $name?')
        : type == 'user'
        ? "Do you want to delete this User"
        : type == 'classroom'
        ? "Do you want to delete this Classroom"
        : type == 'vendor_category'
        ? "Do you want to delete this Vendor Category"
        : type == 'vendor'
        ? "Do you want to delete this Vendor"
        : type == 'product_category'
        ? "Do you want to delete this Product Category"
        : type == 'product'
        ? "Do you want to delete this Product"
        : type == 'request'
        ? "Do you want to delete request made for product name"
        : type == 'purchase_order'
        ? "Do you want to delete this Purchase Order"
        : type == 'ledger'
        ? "Do you want to delete this Ledger Account"
        : type == 'subsidy'
        ? "Do you want to delete this Subsidy"
        : type == 'complete_purchase'
        ? "Are you sure you want to mark this purchase \"$name\" as completed? This action cannot be reversed."
        : type == 'order_purchase'
        ? "Are you sure you want to mark this purchase \"$name\" as ordered? This action cannot be reversed."
        : type == 'reject_request'
        ? "Are you sure you want to reject this request for \"$name\"? This action cannot be reversed."
        : '';

    String buttonText;
    if (type == 'complete_purchase') {
      buttonText = "Mark Complete";
    } else if (type == 'order_purchase') {
      buttonText = "Mark as Ordered";
    } else if (type == 'reject_request') {
      buttonText = "Reject Request";
    } else if (type == 'plan_resume') {
      buttonText = 'Resume Plan';
    } else if (type == 'plan_pause') {
      buttonText = 'Pause Plan';
    } else if (type == 'plan_cancel') {
      buttonText = 'Cancel Plan';
    } else {
      buttonText = "Delete";
    }

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isLargeTablet ? 1200.0 : double.infinity,
        ),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            left: horizontalPadding,
            right: horizontalPadding,
            top: verticalPadding,
            bottom: verticalPadding + bottomSafe,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(borderRadius),
              topRight: Radius.circular(borderRadius),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: verticalPadding / 2),

              // Delete Image
              Container(
                width: imageSize,
                height: imageSize,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5F5),
                  borderRadius: BorderRadius.circular(imageSize / 2),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/icons/delete-icon.png', // Make sure this path exists
                    width: imageSize * 0.5,
                    height: imageSize * 0.5,
                    color: const Color(0xFFE53E3E),
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback icon if image is not found
                      return Icon(
                        Icons.delete_outline,
                        size: imageSize * 0.5,
                        color: const Color(0xFFE53E3E),
                      );
                    },
                  ),
                ),
              ),

              SizedBox(height: verticalPadding),

              // Title
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding / 2,
                ),
                child: Column(
                  children: [
                    Text(
                      typeText,
                      style: TextStyle(
                        fontFamily: "Manrope",
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xff573353),
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: verticalPadding / 4),
                    if (!isPlanAction &&
                        type != 'complete_purchase' &&
                        type != 'reject_request' &&
                        type != 'order_purchase')
                      Text(
                        '"$name"?',
                        style: TextStyle(
                          fontFamily: "Manrope",
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xff573353),
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                  ],
                ),
              ),
              SizedBox(height: verticalPadding * 1.5),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: buttonHeight,
                      child: OutlinedButton(
                        onPressed: isLoading ? null : onCancel,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF6C7FD8)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              borderRadius / 2,
                            ),
                          ),
                        ),
                        child: Text(
                          "Cancel",
                          style: TextStyle(
                            fontFamily: "Manrope",
                            fontSize: buttonFontSize,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryColor,
                            height: 1.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: horizontalPadding / 2),
                  Expanded(
                    child: Container(
                      height: buttonHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(borderRadius / 2),
                        gradient: AppColors.buildPrimaryGradient(),
                      ),
                      child: TextButton(
                        onPressed: isLoading ? null : onDelete,
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              borderRadius / 2,
                            ),
                          ),
                        ),
                        child: isLoading
                            ? SizedBox(
                                width: isLargeTablet
                                    ? 24.0
                                    : (isTablet ? 20.0 : 16.0),
                                height: isLargeTablet
                                    ? 24.0
                                    : (isTablet ? 20.0 : 16.0),
                                child: const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                buttonText,
                                style: TextStyle(
                                  fontFamily: "Manrope",
                                  fontSize: buttonFontSize,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.0,
                                ),
                                textAlign: TextAlign.center,
                              ),
                      ),
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
