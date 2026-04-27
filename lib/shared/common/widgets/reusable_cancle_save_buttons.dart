import 'package:flutter/material.dart';

import 'custom_cancel_button.dart';
import 'custom_confirm_button.dart';

class ReusableActionButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: CustomCancelButton(
                cancelButtonLabel: 'Cancle',
                onPressedCancel: () {},
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomConfirmButton(label: 'Save', onPressed: () {}),
            ),
          ],
        ),
      ),
    );
  }
}
