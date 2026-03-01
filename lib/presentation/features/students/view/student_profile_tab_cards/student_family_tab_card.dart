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
  State<StudentFamilyTabCard> createState() => _StudentFamilyTabCardState();
}

class _StudentFamilyTabCardState extends State<StudentFamilyTabCard> {
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
          children: const [
            _FamilyCard(
              name: 'Parent name',
              relation: 'Father',
              email: 'father@mail.com',
              phone: '(986) 027-1627',
              pin: '263630',
            ),
            SizedBox(height: 12),
            _FamilyCard(
              name: 'Parent name',
              relation: 'Mother',
              email: 'mother@mail.com',
              phone: '(986) 027-1627',
              pin: '263630',
            ),
          ],
        ),
      ),
    );
  }
}

class _FamilyCard extends StatelessWidget {
  const _FamilyCard({
    required this.name,
    required this.relation,
    required this.email,
    required this.phone,
    required this.pin,
  });

  final String name;
  final String relation;
  final String email;
  final String phone;
  final String pin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(8),
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        border: Border.fromBorderSide(
          BorderSide(color: AppColors.themeColor, width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DocumentImageWidget(
                  fileUuid: '',
                  name: name,
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$name ($relation)',
                    style: AppTextStyles.value.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.03 * 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: AppColors.buildPrimaryGradient(),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFFE5E5F0),
            ),
            const SizedBox(height: 12),
            const _FamilyInfoRow(
              label: 'Name',
              valueKey: 'name',
            ),
            const _FamilyInfoRow(
              label: 'Relationship',
              valueKey: 'relation',
            ),
            const _FamilyInfoRow(
              label: 'Email ID',
              valueKey: 'email',
            ),
            const _FamilyInfoRow(
              label: 'Phone',
              valueKey: 'phone',
            ),
            const _FamilyInfoRow(
              label: 'Sign-in Pin',
              valueKey: 'pin',
            ),
            const SizedBox(height: 16),
            CustomButtonLayout(
              confirmButtonLabel: 'Edit',
              cancelButtonLabel: 'Delete',
              onPressedConfirm: null,
              onPressedCancel: null,
              isForm: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _FamilyInfoRow extends StatelessWidget {
  const _FamilyInfoRow({
    required this.label,
    required this.valueKey,
  });

  final String label;
  final String valueKey;

  @override
  Widget build(BuildContext context) {
    // Read values from the nearest _FamilyCard using InheritedWidget pattern if needed.
    // For now, keep it simple and just show placeholder-style values.
    String value;
    switch (valueKey) {
      case 'relation':
        value = 'Father';
        break;
      case 'email':
        value = 'parent@mail.com';
        break;
      case 'phone':
        value = '(986) 027-1627';
        break;
      case 'pin':
        value = '263630';
        break;
      case 'name':
      default:
        value = 'Parent name';
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.label.copyWith(
              color: AppColors.primaryColor.withOpacity(0.6),
              fontSize: 14,
              letterSpacing: 14 * (-3 / 100),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.value.copyWith(
                fontSize: 15,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
















