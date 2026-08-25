import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';

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
    this.borderRadius = _defaultBorderRadius,
  });

  final String title;
  final VoidCallback? onEdit;
  final ScrollController? scrollController;
  final List<Widget> children;
  final EdgeInsets outerPadding;
  final EdgeInsets innerPadding;
  final bool showHeaderEdit;

  /// Card corner radius. Override to square the top when the card sits flush
  /// under a tab bar so it reads as one continuous surface.
  final BorderRadius borderRadius;

  static const BorderRadius _defaultBorderRadius = BorderRadius.vertical(
    top: Radius.circular(12),
    bottom: Radius.circular(16),
  );

  static TextStyle _titleStyle = AppTextStyles.title.copyWith(color: AppColors.primaryColor);

  @override
  Widget build(BuildContext context) {
    // Fixed bordered box: the title header stays pinned and the fields scroll
    // INSIDE the box (clipped by the border radius), so cards slide under the
    // box instead of the whole box scrolling away.
    return Padding(
      padding: outerPadding,
      child: Container(
        width: double.infinity,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.themeColor),
          borderRadius: borderRadius,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Pinned header ──────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(
                innerPadding.left,
                innerPadding.top,
                innerPadding.right,
                12,
              ),
              child: Row(
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
            ),
            // ── Scrollable content (slides under the pinned header) ────────
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  innerPadding.left,
                  0,
                  innerPadding.right,
                  innerPadding.bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...children.map(
                      (child) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: child,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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

  static TextStyle _labelStaff = AppTextStyles.title.copyWith(color: Color(0xff573353));

  static TextStyle _valueStaff = AppTextStyles.body.copyWith(color: Color(0xff573353));

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
        valueWidget ?? Text(resolved, style: _valueStaff),
      ],
    );
  }
}
