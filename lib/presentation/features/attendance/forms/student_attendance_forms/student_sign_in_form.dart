import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'student_entity.dart';

class StudentSignInForm extends StatelessWidget {
  const StudentSignInForm({
    super.key,
    required this.students,
    required this.refreshCallback,
  });

  final List<StudentEntity> students;
  final VoidCallback refreshCallback;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryColor),
          onPressed: () {
            refreshCallback();
            Navigator.pop(context);
          },
        ),
        title: const Text('Sign In', style: AppTextStyles.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selected Students (${students.length})',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: students.length,
                separatorBuilder: (_, __) =>
                    Divider(color: AppColors.primaryColor.withOpacity(0.1)),
                itemBuilder: (context, index) {
                  final s = students[index];
                  return Text(
                    s.fullName,
                    style: AppTextStyles.body,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          bottom: safeBottom,
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
        ),
        child: CustomButtonLayout(
          confirmButtonLabel: 'Confirm Sign In',
          onPressedConfirm: () async {
            // UI-only: just pop back for now.
            refreshCallback();
            Navigator.pop(context);
          },
          showCancelButton: false,
          isForm: false,
        ),
      ),
    );
  }
}

