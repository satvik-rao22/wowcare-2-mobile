import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';


class ProfileInfoCard extends StatelessWidget {
  const ProfileInfoCard({
    super.key,
    required this.cardType,
    this.title = 'Profile Information',
    this.onEdit,
    this.scrollController,
    required this.children,
    this.outerPadding = const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
    this.innerPadding = const EdgeInsets.all(16),
    this.showHeaderEdit = true,
    this.studentFirstField
  });

  final String cardType;
  final String title;
  final VoidCallback? onEdit;
  final ScrollController? scrollController;
  final List<Widget> children;
  final EdgeInsets outerPadding;
  final EdgeInsets innerPadding;
  final bool showHeaderEdit;
  final Widget? studentFirstField;

  @override
  Widget build(BuildContext context) {
    final isStudent = cardType.toLowerCase() == 'student';

    final borderRadius = isStudent
        ? const BorderRadius.only(
      topRight: Radius.circular(8),
      bottomLeft: Radius.circular(8),
      bottomRight: Radius.circular(8),
    )
        : const BorderRadius.vertical(
      top: Radius.circular(12),
      bottom: Radius.circular(16),
    );

    final headerTextStyle = TextStyle(
      color: AppColors.primaryColor,
      fontSize: isStudent ? 17 : 16,
      fontWeight: FontWeight.w600,
    );

    return SingleChildScrollView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      //padding: outerPadding,
      child: Container(
        width: double.infinity,
        padding: innerPadding,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.themeColor),
          borderRadius: borderRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if(isStudent)
                  studentFirstField!
                else
                  Text(title, style: headerTextStyle),
                if (showHeaderEdit && onEdit != null)
                  GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: AppColors.buildPrimaryGradient(),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.edit,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            ...children.map((child) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: child,
            )),
          ],
        ),
      ),
    );
  }


}

class ProfileField extends StatelessWidget {
  const ProfileField({
    super.key,
    required this.label,
    this.value,
    this.valueWidget,
    this.isStudentStyle = false,
  });

  final String label;
  final String? value;
  final Widget? valueWidget;
  final bool isStudentStyle;

  @override
  Widget build(BuildContext context) {
    final labelStyle = isStudentStyle
        ? const TextStyle(
      fontFamily: 'Manrope',
      fontSize: 15,
      letterSpacing: -0.03 * 15,
      fontWeight: FontWeight.w400,
      color: Color(0xFF6C6377),
    )
        : const TextStyle(
      fontFamily: 'Manrope',
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Color(0xff573353),
    );

    final valueStyle = isStudentStyle
        ? const TextStyle(
      fontFamily: 'Manrope',
      fontSize: 15,
      color: Color(0x99573353),
      fontWeight: FontWeight.w400,
      letterSpacing: -0.03 * 15,
    )
        : const TextStyle(
      fontFamily: 'Manrope',
      fontSize: 15,
      color: Color(0xff573353),
      fontWeight: FontWeight.w400,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 6),
        valueWidget ??
            Text(
              value ?? '- -',
              style: valueStyle,
            ),
      ],
    );
  }
}





