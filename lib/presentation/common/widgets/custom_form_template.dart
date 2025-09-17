import 'package:flutter/material.dart';
import 'package:schoolerp/core/common/widgets/custom_button_layout.dart';
import 'package:schoolerp/core/common/widgets/custom_scaffold.dart';
import 'package:schoolerp/core/res/colors.dart';

class CustomFormTemplate extends StatelessWidget {
  const CustomFormTemplate({
    super.key,
    required this.title,
    this.isScrollable = true,
    this.hasBackButton = true,
    this.showCustomNavigationBar = false,
    this.showCancelButton = true,
    required this.confirmButtonLabel,
    required this.onPressedConfirm,
    required this.children,
  });

  final String title;
  final bool isScrollable;
  final bool hasBackButton;
  final bool showCustomNavigationBar;
  final bool showCancelButton;
  final String? confirmButtonLabel;
  final void Function()? onPressedConfirm;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final formContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );

    return GlobalScaffold(
      isGloballyScrollable: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.primaryColor,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: 17 * (-3 / 100),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: isScrollable
                      ? SingleChildScrollView(
                          child: formContent,
                        )
                      : formContent,
                ),
              ),
            ),
          ),
        ],
      ),
      customButtonLayout: CustomButtonLayout(
        showCancelButton: showCancelButton,
        confirmButtonLabel: confirmButtonLabel ?? '',
        onPressedConfirm: onPressedConfirm,
      ),
      hasBackButton: hasBackButton,
      showCustomNavigationBar: showCustomNavigationBar,
    );
  }
}
