import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/core/responsive/responsive_scope.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/presentation/features/reports/reports_strings.dart';
export 'package:wowcare/presentation/features/reports/widgets/report_month_year_field.dart';

class ReportFormLayout extends StatelessWidget {
  const ReportFormLayout({
    super.key,
    required this.title,
    required this.child,
    required this.onGenerate,
    this.isLoading = false,
    this.generateLabel = ReportsStrings.generateReport,
    this.showButton = true,
  });

  final String title;
  final Widget child;
  final VoidCallback? onGenerate;
  final bool isLoading;
  final String generateLabel;
  final bool showButton;

  @override
  Widget build(BuildContext context) {
    // §7.5: paddingOf subscribes to padding only — `.of` re-ran this whole
    // form layout whenever the keyboard opened.
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;

    return Scaffold(
      backgroundColor: AppColors.pageBackgroundColor,
      appBar: const CustomAppBar(hasBackButton: true),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(color: AppColors.pageBackgroundColor),
            ),
            Column(
              children: [
                const SizedBox(height: AppSizes.md),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.responsive(compact: 16.0, medium: 32.0),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      title,
                      style: AppTextStyles.reportsHeading(
                        fontSize: context.responsive(
                          compact: 18.0,
                          medium: 24.0,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: context.isTablet ? 32.0 : 20.0),
                Expanded(
                  child: Container(
                    width: context.responsive(
                      compact: MediaQuery.sizeOf(context).width,
                      expanded: 1200.0,
                    ),
                    margin: EdgeInsets.symmetric(
                      horizontal: context.responsive(
                        compact: 16.0,
                        medium: 32.0,
                      ),
                    ),
                    padding: EdgeInsets.all(context.isTablet ? 32.0 : 16.0),
                    decoration: BoxDecoration(
                      color: AppColors.cardColor,
                      borderRadius: BorderRadius.all(
                        Radius.circular(context.isTablet ? 40.0 : 24.0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.blackColor.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [child],
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.sm),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: !showButton
          ? null
          : Container(
              padding: EdgeInsets.only(
                bottom: safeAreaBottom,
                left: 16,
                right: 16,
                top: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blackColor.withValues(alpha: 0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 16,
                  ),
                ],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(context.isTablet ? 40.0 : 24.0),
                  topRight: Radius.circular(context.isTablet ? 40.0 : 24.0),
                ),
              ),
              child: CustomButtonLayout(
                confirmButtonLabel: generateLabel,
                onPressedConfirm: onGenerate,
                showCancelButton: false,
                isForm: false,
                isLoading: isLoading,
              ),
            ),
    );
  }
}

/// Reusable required-asterisk label used in report forms.
class ReportFieldLabel extends StatelessWidget {
  const ReportFieldLabel({
    super.key,
    required this.label,
    this.isRequired = true,
  });

  final String label;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.isTablet ? 8.0 : 6.0),
      child: RichText(
        text: TextSpan(
          style: AppTextStyles.reportsFieldLabel(
            fontSize: context.responsive(compact: 14.0, medium: 16.0),
          ),
          children: [
            TextSpan(text: label),
            if (isRequired)
              const TextSpan(
                text: ' *',
                style: AppTextStyles.reportsRequiredMarker,
              ),
          ],
        ),
      ),
    );
  }
}

/// Month + year picker styled to match [CustomDateTimeField]: same light field
/// background, padding, calendar icon, and selected-text style. Opens a
class ReportDefaultNote extends StatelessWidget {
  const ReportDefaultNote({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(text, style: AppTextStyles.reportsNote),
    );
  }
}

/// Report format selector dropdown (PDF/XLSX)
class ReportFormatSelector extends StatelessWidget {
  const ReportFormatSelector({
    super.key,
    required this.selectedFormat,
    required this.onFormatChanged,
    this.showLabel = true,
  });

  final String selectedFormat;
  final ValueChanged<String> onFormatChanged;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: selectedFormat,
      decoration: InputDecoration(
        labelText: showLabel ? 'Export Format *' : null,
        filled: true,
        fillColor: AppColors.fieldBackgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        labelStyle: AppTextStyles.reportsFieldLabel(
          fontSize: context.responsive(compact: 14.0, medium: 16.0),
        ),
        hintText: !showLabel ? ReportsStrings.selectFormat : null,
        hintStyle: AppTextStyles.reportsFieldLabel(
          fontSize: context.responsive(compact: 14.0, medium: 16.0),
        ).copyWith(color: AppColors.primaryColor.withValues(alpha: 0.5)),
      ),
      items: const [
        DropdownMenuItem(value: 'PDF', child: Text('PDF')),
        DropdownMenuItem(value: 'XLSX', child: Text('XLSX')),
      ],
      onChanged: (value) {
        if (value != null) {
          onFormatChanged(value);
        }
      },
    );
  }
}
