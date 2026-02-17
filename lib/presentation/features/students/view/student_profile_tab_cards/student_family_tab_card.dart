import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import '../../../../../shared/common/widgets/profile_show_widget.dart';


class StudentFamilyTabCard extends StatefulWidget {
  const StudentFamilyTabCard({
    required this.scrollController,
    required this.name,
    required this.classroom,
    this.onRefresh,
    super.key,
  });

  final ScrollController scrollController;
  final String name;
  final String classroom;
  final Future<void> Function()? onRefresh;


  @override
  State<StudentFamilyTabCard> createState() =>
      _StudentFamilyTabCardState();
}

class _StudentFamilyTabCardState extends State<StudentFamilyTabCard> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CustomRefreshIndicator(
      onRefresh: () async {
        await widget.onRefresh?.call();
      },
      child: SingleChildScrollView(
        controller: widget.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _FamilyCard(
              name: "Parent name",
              relation: 'Father',
              email: "father@mail.com",
            ),
            SizedBox(height: 20,),
            _FamilyCard(
              name: "Parent name",
              relation: 'Mother',
              email: "mother@mail.com",
            )
          ],
        ),
      ),
    );
  }

}

class _FamilyCard extends StatelessWidget{
  const _FamilyCard({required this.name, this.relation, this.email});
  final String name;
  final String? relation;
  final String? email;
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    return IntrinsicHeight(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          // Match staff card styling: radius 12, 1px border.
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorderColor, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
          Container(
          // Match staff card header height.
          height: 60,
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 24 : 16,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              DocumentImageWidget(
                fileUuid: '',
                name: name,
                size: 45,
              ),
              SizedBox(width: isTablet ? 16 : 9),
            Flexible(
              child: Text(
                name,
                style: AppTextStyles.value.copyWith(
                  fontSize: isTablet ? 16 : 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            )
            ],
          ),
        ),
            Divider(
              height: 1,
              thickness: 1,
              indent: 16,
              endIndent: 16,
              color: AppColors.dividerColor,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Relation',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.primaryColor.withOpacity(0.5),
                          fontSize: 14,
                          letterSpacing: 14 * (-3 / 100),
                        ),
                      ),
                      Text(
                        relation!,
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
                        'Email ID',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.primaryColor.withOpacity(0.5),
                          fontSize: 14,
                          letterSpacing: 14 * (-3 / 100),
                        ),
                      ),
                      Text(
                        email!,
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
                        'Phone Number',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.primaryColor.withOpacity(0.5),
                          fontSize: 14,
                          letterSpacing: 14 * (-3 / 100),
                        ),
                      ),
                      Text(
                        "(986) 027-1627",
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
                        'Sign-in Pin',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.primaryColor.withOpacity(0.5),
                          fontSize: 14,
                          letterSpacing: 14 * (-3 / 100),
                        ),
                      ),
                      Text(
                        '263630',
                        style: AppTextStyles.value.copyWith(
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  CustomButtonLayout(
                    confirmButtonLabel: 'Edit',
                    cancelButtonLabel: 'Delete',
                    onPressedConfirm: () {
                      // TODO: Implement Edit Family handler
                    },
                    onPressedCancel: () {
                      // TODO: Implement Delete Family handler
                    },
                    isForm: false,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ],

        ),
      ),
    );

  }

}
















