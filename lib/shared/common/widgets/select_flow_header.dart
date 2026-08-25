import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';

class SelectFlowHeader extends StatelessWidget {
  const SelectFlowHeader({
    super.key,
    required this.userName,
    required this.userRole,
    this.logoAsset = MediaRes.logo_wow,
    this.avatar,
  });

  final String userName;
  final String userRole;
  final String logoAsset;
  final ImageProvider? avatar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 8),
        Image.asset(logoAsset, height: 82, fit: BoxFit.contain),
        const SizedBox(height: 2),
        AppText.title('WowCare!', textAlign: TextAlign.center),
        const SizedBox(height: 16),
        CircleAvatar(
          radius: 28,
          backgroundImage: avatar ?? const AssetImage(MediaRes.userImageFemale),
        ),
        const SizedBox(height: 10),
        AppText.title(userName, textAlign: TextAlign.center),
        const SizedBox(height: 4),
        AppText.small(
          userRole,
          style: AppTextStyles.body.copyWith(color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
