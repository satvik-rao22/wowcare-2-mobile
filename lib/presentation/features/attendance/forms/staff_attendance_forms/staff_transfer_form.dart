import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'staff_entity.dart';

class StaffTransferForm extends StatefulWidget {
  const StaffTransferForm({super.key, this.staff});

  final StaffEntity? staff;

  static const String routeName = '/staff-transfer-form';

  @override
  State<StaffTransferForm> createState() => _StaffTransferFormState();
}

class _StaffTransferFormState extends State<StaffTransferForm> {
  String? selectedClassroom;
  String currentClassroom = 'Classroom A';
  List<String> availableClassrooms = [
    'Classroom B',
    'Classroom C',
    'Classroom D',
  ];
  StaffEntity? currentStaff;

  @override
  void initState() {
    super.initState();
    currentStaff =
        widget.staff ??
        StaffEntity(id: 1, name: 'Staff Member', primaryRoomId: 1);
  }

  void _handleSubmit() {
    if (selectedClassroom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a classroom to transfer to'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    // UI-only: Just show success and navigate back
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transferred successfully'),
        backgroundColor: AppColors.successColor,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return StaffFormLayout(
      title: 'Transfer',
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (currentStaff != null)
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 3.5,
                ),
                itemCount: 1,
                itemBuilder: (context, index) =>
                    RemoveStaffTile(staff: currentStaff!),
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText.label('Current Classroom'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                                color: const Color.fromRGBO(177, 175, 233, 0.1),
                              ),
                              child: AppText.value(
                                currentClassroom,
                                style: TextStyle(
                                  color: AppColors.primaryColor.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText.label('Transfer to Classroom'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: const Color.fromRGBO(177, 175, 233, 0.1),
                        ),
                        child: DropdownButton<String>(
                          value: selectedClassroom,
                          hint: const Text('Select classroom'),
                          style: TextStyle(
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.5,
                            ),
                            fontSize: 15,
                          ),
                          isExpanded: true,
                          icon: SvgPicture.asset(MediaRes.arrow_drop_down),
                          underline: Container(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedClassroom = newValue!;
                            });
                          },
                          items: availableClassrooms.map((String classroom) {
                            return DropdownMenuItem<String>(
                              value: classroom,
                              child: Text(classroom),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomBar: CustomButtonLayout(
        confirmButtonLabel: 'Submit',
        onPressedConfirm: _handleSubmit,
        showCancelButton: false,
      ),
    );
  }
}

class RemoveStaffTile extends StatelessWidget {
  final StaffEntity staff;

  const RemoveStaffTile({super.key, required this.staff});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.themeColor),
        borderRadius: BorderRadius.circular(10),
        color: const Color.fromRGBO(249, 245, 250, 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                DocumentImageWidget(
                  fileUuid: staff.photoUuid ?? '',
                  name: staff.name,
                  size: 30,
                  fontSize: 12,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    staff.name.split(' ').first,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                    style: const TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
