import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';

class StaffScreen extends StatelessWidget {
  const StaffScreen({super.key});

  static const String routeName = '/staff';

  @override
  Widget build(BuildContext context) {
    final double titleFontSize = ResponsiveSizing.titleFontSize(context);
    final double titleLineHeight = ResponsiveSizing.titleLineHeight(context);

    return GlobalScaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: ResponsiveSizing.contentPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Staff List',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff573353),
                  height: titleLineHeight,
                ),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 16),
              // Placeholder for staff list content
            ],
          ),
        ),
      ),
      showCustomNavigationBar: true,
    );
  }
}


