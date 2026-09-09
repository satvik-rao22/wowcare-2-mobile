import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/presentation/features/communication/model/thread_info.dart';
import '../../../../../../shared/common/widgets/custom_text_widget.dart';
import '../../../../../../shared/common/widgets/profile_show_widget.dart';

class MessagingHeader extends StatelessWidget {
  final StaffThreadInfo staffInfo;

  const MessagingHeader({super.key, required this.staffInfo});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.transparentColor,
        border: Border(bottom: BorderSide(color: AppColors.messagingBorderSubtle, width: 1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Stack(
              children: [
                DocumentImageWidget(
                  disableAttendanceStatusLookup: true,
                  fileUuid: '',
                  imageUrl:
                      staffInfo.avatar.startsWith('http')
                      ? staffInfo.avatar
                      : null,
                  mediaAssetCode:
                      staffInfo.avatar.isNotEmpty &&
                          !staffInfo.avatar.startsWith(
                            'http',
                          )
                      ? staffInfo.avatar
                      : null,
                  name: staffInfo.name,
                  size: 45,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: staffInfo.isSigned
                          ? AppColors.messagingOnlineDot
                          : AppColors.transparentColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: staffInfo.isSigned
                            ? AppColors.cardColor
                            : AppColors.transparentColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Flexible(
              child: CustomTextWidget(
                text: staffInfo.name,
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
