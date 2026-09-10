import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'custom_confirm_button.dart';

class ReusablePasswordActionButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppSurfaces.card(radius: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: CustomConfirmButton(
                label: 'Save Password',
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
