import 'package:flutter/material.dart';

import '../../../../../shared/common/widgets/custom_button_layout.dart';

class ActivityAdminApproveRejectBar extends StatelessWidget {
  const ActivityAdminApproveRejectBar({
    super.key,
    required this.visible,
    required this.isLoading,
    required this.onApprove,
    required this.onReject,
  });

  final bool visible;
  final bool isLoading;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CustomButtonLayout(
        confirmButtonLabel: 'Approve',
        cancelButtonLabel: 'Reject',
        onPressedConfirm: isLoading ? null : onApprove,
        onPressedCancel: isLoading ? null : onReject,
        showCancelButton: true,
        isForm: false,
        isLoading: isLoading,
      ),
    );
  }
}
