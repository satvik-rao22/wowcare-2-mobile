import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';



class StudentHealthTabCard extends StatefulWidget {
  const StudentHealthTabCard({
    required this.scrollController,
    required this.name,
    required this.classroom,
    super.key,
  });

  final ScrollController scrollController;
  final String name;
  final String classroom;


  @override
  State<StudentHealthTabCard> createState() =>
      _StudentHealthTabCardState();
}

class _StudentHealthTabCardState extends State<StudentHealthTabCard> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: widget.scrollController,
      child: _HealthCard(
        allergies: "No allergies",
        medication: 'No medication',
        dietRestrictions: "Can not eat candy",
      ),
    );
  }

}

class _HealthCard extends StatelessWidget{
  const _HealthCard({required this.allergies, required this.medication, required this.dietRestrictions});
  final String allergies;
  final String? medication;
  final String? dietRestrictions;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    return IntrinsicHeight(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          // Match staff card styling: 12 radius on all non-shared corners,
          // 1px border with themed color.
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(12),
            bottomRight: Radius.circular(12),
          ),
          border: Border.all(color: AppColors.cardBorderColor, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                isTablet ? 24 : 16,
                16,
                isTablet ? 24 : 16,
                0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Allergies',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.primaryColor.withOpacity(0.5),
                          fontSize: 14,
                          letterSpacing: 14 * (-3 / 100),
                        ),
                      ),
                      Text(
                        allergies,
                        style: AppTextStyles.value.copyWith(
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Medication',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.primaryColor.withOpacity(0.5),
                          fontSize: 14,
                          letterSpacing: 14 * (-3 / 100),
                        ),
                      ),
                      Text(
                        medication!,
                        style: AppTextStyles.value.copyWith(
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Diet Restrictions',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.primaryColor.withOpacity(0.5),
                          fontSize: 14,
                          letterSpacing: 14 * (-3 / 100),
                        ),
                      ),
                      Text(
                        dietRestrictions!,
                        style: AppTextStyles.value.copyWith(
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                ],
              ),
            ),
          ],

        ),
      ),
    );

  }

}
















