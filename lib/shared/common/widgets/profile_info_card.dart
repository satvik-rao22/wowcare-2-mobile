import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';

/// Profile card shell aligned with [StaffProfileTab]: white card, theme border,
/// vertical radii 12/12, scroll padding 8×16, inner padding 16, title + gradient edit row.
class ProfileInfoCard extends StatelessWidget {
  const ProfileInfoCard({
    super.key,
    this.title = 'Profile Information',
    this.onEdit,
    this.scrollController,
    required this.children,
    this.outerPadding = const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
    this.innerPadding = const EdgeInsets.all(16),
    this.showHeaderEdit = true,
  });

  final String title;
  final VoidCallback? onEdit;
  final ScrollController? scrollController;
  final List<Widget> children;
  final EdgeInsets outerPadding;
  final EdgeInsets innerPadding;
  final bool showHeaderEdit;

  static const BorderRadius _borderRadius = BorderRadius.vertical(
    top: Radius.circular(12),
    bottom: Radius.circular(16),
  );

  static const TextStyle _titleStyle = TextStyle(
    color: AppColors.primaryColor,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: outerPadding,
      child: Container(
        width: double.infinity,
        padding: innerPadding,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.themeColor),
          borderRadius: _borderRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _titleStyle),
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

/// Label/value column matching staff profile [_Field]: label 16 w600 #573353,
/// 6px gap, value 15 w400 #573353.
class ProfileField extends StatelessWidget {
  const ProfileField({
    super.key,
    required this.label,
    this.value,
    this.valueWidget,
  });

  final String label;
  final String? value;
  final Widget? valueWidget;

  static const TextStyle _labelStaff = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Color(0xff573353),
  );

  static const TextStyle _valueStaff = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 15,
    color: Color(0xff573353),
    fontWeight: FontWeight.w400,
  );

  @override
  Widget build(BuildContext context) {
    final String resolved = () {
      if (valueWidget != null) return '';
      final v = value;
      if (v == null || v.trim().isEmpty) return '-';
      return v;
    }();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStaff),
        const SizedBox(height: 6),
        valueWidget ??
            Text(
              resolved,
              style: _valueStaff,
            ),
      ],
    );
  }
}
