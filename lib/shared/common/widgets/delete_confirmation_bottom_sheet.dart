import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';

class DeleteConfirmationBottomSheet extends StatefulWidget {
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
  State<DeleteConfirmationBottomSheet> createState() =>
      _DeleteConfirmationBottomSheetState();
}

class _DeleteConfirmationBottomSheetState
    extends State<DeleteConfirmationBottomSheet> {
  late bool _isLoading;

  @override
  void initState() {
    super.initState();
    _isLoading = widget.isLoading;
  }

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

    final borderRadius = isLargeTablet
        ? 24.0
        : isTablet
        ? 20.0
        : 16.0;

    final bool isPlanAction =
        widget.type == 'plan_cancel' || widget.type == 'plan_pause';

    final String typeText = isPlanAction
        ? (widget.type == 'plan_cancel'
            ? 'Do you want to cancel this plan - "${widget.planName ?? ''}" for student ${widget.name}?'
            : 'Do you want to pause this plan - "${widget.planName ?? ''}" for student ${widget.name}?')
        : widget.type == 'user'
        ? "Do you want to delete this User"
        : widget.type == 'Activity'
        ? 'Do you want to delete this activity -\n"${widget.name}" ?'
        : widget.type == 'staff_deactivate'
        ? 'Do you want to deactivate this Staff -\n"${widget.name}" ?'
        : widget.type == 'staff_reactivate'
        ? 'Do you want to reactivate this Staff -\n"${widget.name}" ?'
        : widget.type == 'student'
        ? 'Do you want to deactivate this Student -\n"${widget.name}" ?'
        : widget.type == 'subsidy'
        ? 'Do you want to delete the subsidy -\n${widget.name} ?'
        : widget.type == 'classroom'
        ? "Do you want to delete this Classroom"
        : widget.type == 'vendor_category'
        ? "Do you want to delete this Vendor Category"
        : widget.type == 'vendor'
        ? "Do you want to delete this Vendor"
        : widget.type == 'product_category'
        ? "Do you want to delete this Product Category"
        : widget.type == 'product'
        ? "Do you want to delete this Product"
        : widget.type == 'request'
        ? "Do you want to delete request made for product name"
        : widget.type == 'purchase_order'
        ? "Do you want to delete this Purchase Order"
        : widget.type == 'complete_purchase'
        ? "Are you sure you want to mark this purchase \"${widget.name}\" as completed? This action cannot be reversed."
        : widget.type == 'order_purchase'
        ? "Are you sure you want to mark this purchase \"${widget.name}\" as ordered? This action cannot be reversed."
        : widget.type == 'reject_request'
        ? "Are you sure you want to reject this request for \"${widget.name}\"? This action cannot be reversed."
        : widget.type == 'attendance'
        ? "Do you want to delete ${widget.name}'s Attendance?"
        : '';

    String buttonText = widget.type == 'complete_purchase'
        ? "Mark Complete"
        : widget.type == 'Activity'
        ? 'Delete'
        : (widget.type == 'staff_deactivate' || widget.type == 'student')
        ? "Deactivate"
        : widget.type == 'staff_reactivate'
        ? "Reactivate"
        : widget.type == 'order_purchase'
        ? "Mark as Ordered"
        : widget.type == 'reject_request'
        ? "Reject Request"
        : (widget.type == 'plan_pause'
              ? 'Pause Plan'
              : (widget.type == 'plan_cancel' ? 'Cancel Plan' : "Delete"));

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
                          width: isLargeTablet
                              ? 32.0
                              : (isTablet ? 28.0 : 24.0),
                          height: isLargeTablet
                              ? 32.0
                              : (isTablet ? 28.0 : 24.0),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: verticalPadding),
              // Title text centered
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding / 2,
                ),
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
              // Buttons row (shared layout with built-in loader)
              CustomButtonLayout(
                confirmButtonLabel: buttonText,
                cancelButtonLabel: 'Cancel',
                onPressedConfirm: () {
                  if (_isLoading) return;
                  setState(() => _isLoading = true);
                  // onDelete is responsible for closing the bottom sheet.
                  widget.onDelete();
                },
                onPressedCancel: () {
                  if (_isLoading) return;
                  widget.onCancel();
                },
                isForm: false,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
