import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/utils/file_utils/file_picker_utils.dart';

import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_fonts.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/presentation/features/user_profile/view_model/profile_menu_header_cubit.dart';

class ProfileMenuHeader extends StatelessWidget {
  const ProfileMenuHeader({
    super.key,
    this.isParentPersona = false,
  });

  final bool isParentPersona;

  Future<void> _pickProfileImage(BuildContext context) async {
    try {
      final image = await FilePickerUtils.pickOne(
        type: PickType.image,
        source: PickSource.photos,
      );
      if (image == null) return;
      // TODO: wire this to upload/update avatar in your backend/state
      if (!context.mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Selected profile image',
        isSuccess: true,
      );
    } catch (e) {
      if (!context.mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Failed to pick image: $e',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileMenuHeaderCubit, ProfileMenuHeaderState>(
      builder: (context, state) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => _pickProfileImage(context),
              child: DocumentImageWidget(
                fileUuid:
                    state.displayName.isNotEmpty ? state.displayName : 'User',
                imageUrl: state.guardianPhotoUrl.isNotEmpty
                    ? state.guardianPhotoUrl
                    : null,
                mediaAssetCode: state.guardianAssetCode.isNotEmpty
                    ? state.guardianAssetCode
                    : null,
                staffCode: state.staffCode.isNotEmpty ? state.staffCode : null,
                name: state.displayName.isNotEmpty ? state.displayName : 'User',
                size: 48,
                fontSize: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.displayName.isNotEmpty ? state.displayName : 'User',
                    style: const TextStyle(
                      color: AppColors.userProfileTextColor,
                      fontFamily: AppFonts.body,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.persona.isNotEmpty ? state.persona : 'Profile',
                    style: const TextStyle(
                      color: AppColors.userProfileTextColor,
                      fontFamily: AppFonts.body,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
