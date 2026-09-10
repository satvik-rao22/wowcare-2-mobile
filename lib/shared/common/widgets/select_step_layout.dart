import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';

class SelectStepLayout extends StatelessWidget {
  const SelectStepLayout({
    super.key,
    required this.header,
    required this.title,
    this.subtitle,
    required this.selector,
    required this.onNext,
    this.nextLabel = 'Next',
    this.isNextEnabled = false,
    this.showBackButton = false,
  });

  final Widget header;
  final String title;
  final String? subtitle;
  final Widget selector;
  final VoidCallback? onNext;
  final String nextLabel;
  final bool isNextEnabled;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 600,
                    minHeight: MediaQuery.of(context).size.height - 
                        MediaQuery.of(context).padding.top - 
                        MediaQuery.of(context).padding.bottom - 48,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      header,
                  const SizedBox(height: 28),
                  if (subtitle != null) ...[
                    Center(
                      child: AppText.subtitle(
                        subtitle!,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Center(
                    child: AppText.sectionHeader(
                      title,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      child: const Divider(height: 1, color: Color(0xFFE8E8E8)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      child: selector,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      child: CustomButtonLayout(
                        confirmButtonLabel: nextLabel,
                        onPressedConfirm: isNextEnabled ? onNext : null,
                        showCancelButton: false,
                        isForm: false,
                      ),
                    ),
                  ),
                    ],
                  ),
                ),
              ),
            ),
            if (showBackButton)
              Positioned(
                top: 8,
                left: 8,
                child: IconButton(
                  icon: SvgPicture.asset(MediaRes.backButton),
                  onPressed: () => Navigator.maybePop(context),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
