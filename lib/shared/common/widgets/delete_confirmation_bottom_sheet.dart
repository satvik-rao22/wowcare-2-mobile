import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';

class DeleteConfirmationBottomSheet extends StatefulWidget {
  final String name; // student name or generic subject name
  final String type;
  final String? planName; // optional plan name for plan actions
  /// Awaited while the confirm button shows loading; use [Navigator.pop] on the
  /// sheet context when finished (success or handled error).
  final Future<void> Function() onDelete;
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
    final bool isActivityApprove = widget.type == 'activity_approve';
    final bool isActivityReject = widget.type == 'activity_reject';

    final String typeText = isPlanAction
        ? (widget.type == 'plan_cancel'
              ? 'Do you want to cancel this plan - "${widget.planName ?? ''}" for student ${widget.name}?'
              : 'Do you want to pause this plan - "${widget.planName ?? ''}" for student ${widget.name}?')
        : widget.type == 'guardian'
        ? 'Do you want to delete this Parent/Guardian -\n"${widget.name}" ?'
        : widget.type == 'pickup'
        ? 'Do you want to delete this Pickup -\n"${widget.name}" ?'
        : widget.type == 'user'
        ? 'Do you want to delete this User'
        : widget.type == 'Activity'
        ? 'Do you want to delete this activity -\n"${widget.name}" ?'
        : widget.type == 'staff_deactivate'
        ? 'Do you want to deactivate this Staff -\n"${widget.name}" ?'
        : widget.type == 'staff_reactivate'
        ? 'Do you want to reactivate this Staff -\n"${widget.name}" ?'
        : widget.type == 'staff_delete'
        ? 'Do you want to delete this Staff -\n"${widget.name}" ?'
        : widget.type == 'student_deactivate'
        ? 'Do you want to deactivate this Student -\n"${widget.name}" ?'
        : widget.type == 'student_reactivate'
        ? 'Do you want to reactivate this Student -\n"${widget.name}" ?'
        : widget.type == 'student_delete'
        ? 'Do you want to delete this Student -\n"${widget.name}" ?'
        : widget.type == 'subsidy'
        ? 'Do you want to delete the subsidy -\n${widget.name} ?'
        : widget.type == 'classroom'
        ? 'Do you want to delete this Classroom'
        : widget.type == 'vendor_category'
        ? 'Do you want to delete this Vendor Category'
        : widget.type == 'vendor'
        ? 'Do you want to delete this Vendor'
        : widget.type == 'product_category'
        ? 'Do you want to delete this Product Category'
        : widget.type == 'product'
        ? 'Do you want to delete this Product'
        : widget.type == 'request'
        ? 'Do you want to delete request made for product name'
        : widget.type == 'purchase_order'
        ? 'Do you want to delete this Purchase Order'
        : widget.type == 'complete_purchase'
        ? 'Are you sure you want to mark this purchase \"${widget.name}\" as completed? This action cannot be reversed.'
        : widget.type == 'order_purchase'
        ? 'Are you sure you want to mark this purchase \"${widget.name}\" as ordered? This action cannot be reversed.'
        : widget.type == 'reject_request'
        ? 'Are you sure you want to reject this request for \"${widget.name}\"? This action cannot be reversed.'
        : widget.type == 'activity_approve'
        ? 'Are you sure you want to approve this pending activity card?'
        : widget.type == 'activity_reject'
        ? 'Are you sure you want to reject this pending activity card?'
        : widget.type == 'attendance'
        ? "Do you want to delete ${widget.name}'s Attendance?"
        : widget.type == 'document'
        ? 'Do you want to delete this Document -\n"${widget.name}" ?'
        : widget.type == 'physician'
        ? 'Do you want to delete this Physician -\n"${widget.name}" ?'
        : widget.type == 'shift'
        ? (widget.name.isEmpty
              ? 'Do you want to delete this shift?'
              : 'Do you want to delete this shift -\n"${widget.name}" ?')
        : widget.type == 'shift_series'
        ? (widget.name.isEmpty
              ? 'Do you want to delete this entire shift series?'
              : 'Do you want to delete the entire shift series for\n"${widget.name}" ?')
        : widget.type == 'ledger_deactivate'
        ? 'Do you want to deactivate this Ledger -\n"${widget.name}" ?'
        : widget.type == 'ledger_reactivate'
        ? 'Do you want to reactivate this Ledger -\n"${widget.name}" ?'
        : widget.type == 'ledger_delete'
        ? 'Do you want to delete this Ledger -\n"${widget.name}" ?'
        : widget.type == 'invoice_cancel'
        ? 'Do you want to cancel this Invoice -\n"${widget.name}" ?\nThis action cannot be undone.'
        : widget.type == 'invoice_delete'
        ? 'Do you want to delete this Invoice -\n"${widget.name}" ?'
        : widget.type == 'payment_method'
        ? 'Do you want to remove this payment method -\n"${widget.name}" ?'
        : '';

    String buttonText = widget.type == 'complete_purchase'
        ? "Mark Complete"
        : widget.type == 'Activity'
        ? 'Delete'
        : (widget.type == 'staff_deactivate' ||
              widget.type == 'student_deactivate' ||
              widget.type == 'ledger_deactivate')
        ? 'Deactivate'
        : (widget.type == 'staff_reactivate' ||
              widget.type == 'student_reactivate' ||
              widget.type == 'ledger_reactivate')
        ? 'Reactivate'
        : widget.type == 'ledger_delete'
        ? 'Delete'
        : widget.type == 'invoice_cancel'
        ? 'Cancel Invoice'
        : widget.type == 'invoice_delete'
        ? 'Delete'
        : widget.type == 'payment_method'
        ? 'Remove'
        : widget.type == 'order_purchase'
        ? 'Mark as Ordered'
        : widget.type == 'reject_request'
        ? 'Reject Request'
        : widget.type == 'activity_approve'
        ? 'Approve'
        : widget.type == 'activity_reject'
        ? 'Reject'
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
                child: isActivityApprove
                    ? SvgPicture.asset(
                        MediaRes.greenCheckCircleIcon,
                        width: isLargeTablet ? 80.0 : (isTablet ? 70.0 : 60.0),
                        height: isLargeTablet ? 80.0 : (isTablet ? 70.0 : 60.0),
                      )
                    : isActivityReject
                    ? SvgPicture.asset(
                        MediaRes.redCrossCircleIcon,
                        width: isLargeTablet ? 80.0 : (isTablet ? 70.0 : 60.0),
                        height: isLargeTablet ? 80.0 : (isTablet ? 70.0 : 60.0),
                      )
                    : Image.asset(
                        'assets/icons/delete.png',
                        width: isLargeTablet ? 80.0 : (isTablet ? 70.0 : 60.0),
                        height: isLargeTablet ? 80.0 : (isTablet ? 70.0 : 60.0),
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback icon if image is not found
                          return Container(
                            width: isLargeTablet
                                ? 80.0
                                : (isTablet ? 70.0 : 60.0),
                            height: isLargeTablet
                                ? 80.0
                                : (isTablet ? 70.0 : 60.0),
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
              CustomButtonLayout(
                confirmButtonLabel: buttonText,
                cancelButtonLabel: 'Cancel',
                onPressedConfirm: () {
                  if (_isLoading) return;
                  setState(() => _isLoading = true);
                  widget.onDelete().whenComplete(() {
                    if (mounted) setState(() => _isLoading = false);
                  });
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
