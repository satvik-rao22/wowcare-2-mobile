import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';

class DeleteConfirmationBottomSheet extends StatelessWidget {
  final String name; // student name or generic subject name
  final String type;
  final String? planName; // optional plan name for plan actions
  final VoidCallback onDelete;
  final VoidCallback onCancel;
  final bool isLoading;

  const DeleteConfirmationBottomSheet({
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

    final bool isPlanAction = type == 'plan_cancel' || type == 'plan_pause';

    final String typeText = isPlanAction
        ? (type == 'plan_cancel'
            ? 'Do you want to cancel this plan - "${planName ?? ''}" for student $name?'
            : 'Do you want to pause this plan - "${planName ?? ''}" for student $name?')
            : type == 'user'
            ? "Do you want to delete this User"
            : type == 'staff'
                ? 'Do you want to deactivate this Staff -\n"$name" ?'
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
                                        : type == 'complete_purchase'
                                            ? "Are you sure you want to mark this purchase \"$name\" as completed? This action cannot be reversed."
                                            : type == 'order_purchase'
                                                ? "Are you sure you want to mark this purchase \"$name\" as ordered? This action cannot be reversed."
                                            : type == 'reject_request'
                                                ? "Are you sure you want to reject this request for \"$name\"? This action cannot be reversed."
                                                : type == 'attendance'
                                                    ? "Do you want to delete $name's Attendance?"
                                                    : '';

    String buttonText = type == 'complete_purchase'
        ? "Mark Complete"
        : type == 'order_purchase'
            ? "Mark as Ordered"
            : type == 'reject_request'
                ? "Reject Request"
                : (type == 'plan_pause' ? 'Pause Plan' : (type == 'plan_cancel' ? 'Cancel Plan' : "Delete"));

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
              // Delete icon at the top center
              Center(
                child: Image.asset(
                  'assets/icons/delete.png',
                  width: isLargeTablet ? 80.0 : (isTablet ? 70.0 : 60.0),
                  height: isLargeTablet ? 80.0 : (isTablet ? 70.0 : 60.0),
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback icon if image is not found
                    return Container(
                      width: isLargeTablet ? 80.0 : (isTablet ? 70.0 : 60.0),
                      height: isLargeTablet ? 80.0 : (isTablet ? 70.0 : 60.0),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF85A5A),
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SvgPicture.asset(
                          MediaRes.formDeleteIcon,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                          width: isLargeTablet ? 32.0 : (isTablet ? 28.0 : 24.0),
                          height: isLargeTablet ? 32.0 : (isTablet ? 28.0 : 24.0),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: verticalPadding),
              // Title text centered
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding / 2),
                child: Text(
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
              ),
              SizedBox(height: verticalPadding * 1.5),
              // Buttons row
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
                            borderRadius: BorderRadius.circular(borderRadius / 2),
                          ),
                          backgroundColor: Colors.white,
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
                            borderRadius: BorderRadius.circular(borderRadius / 2),
                          ),
                        ),
                        child: isLoading
                            ? SizedBox(
                                width: isLargeTablet ? 24.0 : (isTablet ? 20.0 : 16.0),
                                height: isLargeTablet ? 24.0 : (isTablet ? 20.0 : 16.0),
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