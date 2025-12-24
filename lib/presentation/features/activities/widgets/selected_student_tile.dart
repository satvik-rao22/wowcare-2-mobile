import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/media_res.dart';
import '../../../../shared/common/widgets/profile_show_widget.dart';

class SelectedStudentTile extends StatelessWidget {
  const SelectedStudentTile({
    super.key,
    required this.name,
    this.avatarUrl,
    this.onTap
  });
  final String name;
  final String? avatarUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        //height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFB1AFE9).withOpacity(0.102),
          //color:  const Color(0xFFF8F7FA) ,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color:  AppColors.themeColor, width: 1),
        ),
        child: Row(
          children: [
            DocumentImageWidget(
              fileUuid: '',
              name: name,
              size: 35,
            ),
            const SizedBox(width: 4,),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: isTablet ? 16 : 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xff573353),
                  height: 19 / 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
                onPressed: onTap,
                icon: SvgPicture.asset(
                    MediaRes.delete_icon
                )
            )
          ],
        ),
      ),
    );
  }
}
