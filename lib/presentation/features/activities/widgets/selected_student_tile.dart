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
    this.onTap,
    this.isViewActivityScreen = false
  });
  final String name;
  final String? avatarUrl;
  final VoidCallback? onTap;
  final bool isViewActivityScreen;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        //height: 60,
        padding: EdgeInsets.symmetric(horizontal: isViewActivityScreen? 14: 12, vertical: isViewActivityScreen? 6 :4),
        decoration: BoxDecoration(
          color: isViewActivityScreen ? Colors.white : Color(0xFFB1AFE9).withOpacity(0.102),
          //color:  const Color(0xFFF8F7FA) ,
          borderRadius: BorderRadius.circular(isViewActivityScreen ? 24 :12),
          border: Border.all(color:  AppColors.themeColor, width: 1),
        ),
        child: Row(
          mainAxisSize:
          isViewActivityScreen ? MainAxisSize.min : MainAxisSize.max,
          mainAxisAlignment: isViewActivityScreen ? MainAxisAlignment.center : MainAxisAlignment.spaceEvenly,
          children: [
            DocumentImageWidget(
              fileUuid: '',
              name: name,
              size: 35,
            ),
            SizedBox(width: isViewActivityScreen ? 8 :4,),
            if(isViewActivityScreen)
              Flexible(
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
            if(!isViewActivityScreen)
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
            if(!isViewActivityScreen)
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
