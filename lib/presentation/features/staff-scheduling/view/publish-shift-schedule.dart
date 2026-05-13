import 'package:flutter/material.dart';
import '../../../../app/theme/colors.dart';
import '../../../../core/util/core_utils.dart';
import '../../../../shared/common/widgets/app_text_styles.dart';
import '../../../../shared/common/widgets/custom_app_bar.dart';
import '../../../../shared/common/widgets/custom_button_layout.dart';
import '../widgets/publish_option_card.dart';

class PublishShiftScheduleScreen extends StatefulWidget {
  const PublishShiftScheduleScreen({super.key});

  static const String routeName = '/dashboard/publish-shift-schedule';

  @override
  State<PublishShiftScheduleScreen> createState() =>
      _PublishShiftScheduleScreenState();
}

class _PublishShiftScheduleScreenState
    extends State<PublishShiftScheduleScreen> {
  PublishType _selectedValue = PublishType.untilDate;
  bool _isSubmitting = false;

  void _handlePublish() async {
    setState(() => _isSubmitting = true);

    // TODO: Add your actual publish logic here
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (mounted) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Shifts published successfully',
        isSuccess: true,
      );

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: CustomAppBar(hasBackButton: true),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText.body(
                'Publish Shifts',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: PublishOptionCard(
                  untilDateTitle: 'Publish Until Date',
                  publishAllTitle: 'Publish All',
                  selectedValue: _selectedValue,
                  onChanged: (value) {
                    setState(() => _selectedValue = value);
                  },
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
        // Bottom Buttons with proper padding & shadow
        bottomNavigationBar: Container(
          padding: const EdgeInsets.fromLTRB(
            16,
            12,
            16,
            20,
          ), // ← Added proper padding
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: CustomButtonLayout(
              confirmButtonLabel: 'Publish',
              cancelButtonLabel: 'Cancel',
              onPressedConfirm: _handlePublish,
              onPressedCancel: () => Navigator.pop(context),
              showCancelButton: true,
              isForm: false,
              isLoading: _isSubmitting,
            ),
          ),
        ),
      ),
    );
  }
}
