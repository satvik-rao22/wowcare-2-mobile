import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import '../../../../app/theme/colors.dart';
import '../../../../shared/common/widgets/app_text_styles.dart';
import '../../../../shared/common/widgets/custom_add_notes_field.dart';
import '../../../../shared/common/widgets/custom_button_layout.dart';
import '../../../../shared/common/widgets/custom_repeat_on_days_selector.dart';
import '../../../../shared/utils/responsive_helper.dart';

class AddShiftScreen extends StatefulWidget {
  const AddShiftScreen({super.key});

  static const String routeName = '/add-shift';

  @override
  State<AddShiftScreen> createState() => _AddShiftScreenState();
}

class _AddShiftScreenState extends State<AddShiftScreen> {
  final TextEditingController _dateController = TextEditingController();
  bool _isSubmitting = false;
  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;
    return Scaffold(
      appBar: CustomAppBar(hasBackButton: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.body(
              'Add Shift',
              style: AppTextStyles.body.copyWith(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 24,
              ),
            ),

            SizedBox(height: 20),
            Card(
              elevation: 0,
              color: AppColors.cardColor,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// 🔹 ROW (2 fields side by side)
                    Row(
                      children: [
                        Expanded(
                          child: CustomDateTimeField(
                            label: 'Date',
                            isRequired: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomDropdown(
                            hintText: 'Room',
                            label: 'Room',
                            isRequired: true,
                            items: ['Room 1', 'Room 2', 'Room 3'],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    /// 🔹 FULL WIDTH FIELD
                    CustomDropdown(
                      hintText: 'Staff',
                      label: 'Staff',
                      isRequired: true,
                      items: ['Staff 1', 'Staff 2', 'Staff 3'],
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: CustomDateTimeField(
                            label: 'Shift Start',
                            isTime: true,
                            isRequired: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomDateTimeField(
                            label: 'Shift End',
                            isTime: true,
                            isRequired: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CustomDateTimeField(
                            label: 'Break Start',
                            isTime: true,
                            isRequired: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomDateTimeField(
                            label: 'Break End',
                            isTime: true,
                            isRequired: true,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    CustomRepeatOnDaysSelector(
                      selectedDays: [],
                      onSelectionChanged: (days) {},
                    ),

                    const SizedBox(height: 16),
                    CustomDateTimeField(label: 'Until Date', isRequired: true),

                    const SizedBox(height: 16),
                    CustomAddNoteButton(onTap: () {}),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          bottom: safeAreaBottom,
          left: 16,
          right: 16,
          top: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              offset: const Offset(0, -4),
              blurRadius: 16,
            ),
          ],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(responsive.isTablet ? 40.0 : 24.0),
            topRight: Radius.circular(responsive.isTablet ? 40.0 : 24.0),
          ),
        ),
        child: CustomButtonLayout(
          confirmButtonLabel: 'Confirm',
          onPressedConfirm: () {},
          showCancelButton: false,
          isForm: false,
          isLoading: _isSubmitting,
        ),
      ),
    );
  }
}
