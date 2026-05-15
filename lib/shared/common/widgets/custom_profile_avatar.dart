import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:wowcare/core/common/app/providers/profile_photo_provider.dart';
// import 'package:wowcare/core/common/widgets/simmer_loader.dart';
// import 'package:wowcare/core/extentions/context_extentions.dart';
// import 'package:wowcare/core/res/decorations.dart';
// import 'package:wowcare/core/util/color_utils.dart';
// import 'package:wowcare/core/util/string_utils.dart';

class CustomProfileAvatar extends StatelessWidget {
  const CustomProfileAvatar({
    required this.radius,
    required this.hasStatus,
    required this.statusSize,
    required this.statusPositionTop,
    required this.statusPositionRight,
    required this.initials,
    required this.statusBorder,
    this.fontSize,
    this.onTap,
    super.key,
  });

  final String initials;

  final double radius;
  final bool hasStatus;
  final double statusSize;
  final double statusPositionTop;
  final double statusPositionRight;
  final double statusBorder;
  final double? fontSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // TODO: Re-enable when ProfilePhotoProvider is available
    // return Consumer<ProfilePhotoProvider>(
    //   builder: (context, photoProvider, _) {
    //     final shimmerLoader = ShimmerLoaderCard(
    //       borderRadius: BorderRadius.circular(1000),
    //       margin: const EdgeInsets.all(0),
    //       child: Container(
    //         height: radius * 2,
    //         width: radius * 2,
    //         decoration: ContainerDecorations.decoration0,
    //       ),
    //     );

    //     if (photoProvider.isLoading) {
    //       return shimmerLoader;
    //     }

    //     final bool showStatus = context.isPersonnel &&
    //         hasStatus &&
    //         (context.currentStaff!.isSignedIn ||
    //             context.currentStaff!.isAbsent ||
    //             context.currentStaff!.profileStatus == 'Upcoming');

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // TODO: Re-enable when context extensions are available
          // context.currentStaffProfilePhoto != null &&
          //         context.currentStaffProfilePhoto!.isNotEmpty
          //     ? ClipRRect(
          //         borderRadius: BorderRadius.circular(100),
          //         child: Image.memory(
          //           context.currentStaffProfilePhoto!,
          //           fit: BoxFit.cover,
          //           width: radius * 2,
          //           height: radius * 2,
          //           frameBuilder:
          //               (context, child, frame, wasSynchronouslyLoaded) {
          //             if (wasSynchronouslyLoaded || frame != null) {
          //               return child;
          //             }
          //             return shimmerLoader;
          //           },
          //         ),
          //       )
          //     :
          CircleAvatar(
            backgroundColor: Colors.blue, // ColorUtils.getColorFromName(
            // context.isPersonnel
            //     ? context.currentStaff!.name
            //     : context.currentGuardian!.fullName,
            // ),
            radius: radius,
            child: Text(
              initials, // StringUtils.getInitials(
              // context.isPersonnel
              //     ? context.currentStaff!.name
              //     : context.currentGuardian!.fullName,
              // ),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: fontSize,
                color: Colors.white,
              ),
            ),
          ),
          // TODO: Re-enable when context extensions are available
          // if (showStatus)
          //   Positioned(
          //     top: statusPositionTop,
          //     right: statusPositionRight,
          //     child: Container(
          //       width: statusSize,
          //       height: statusSize,
          //       decoration: BoxDecoration(
          //         color: context.currentStaff!.profileStatus == 'Upcoming'
          //             ? const Color.fromARGB(255, 253, 205, 22)
          //             : context.currentStaff!.isSignedIn
          //                 ? const Color.fromRGBO(0, 177, 21, 1)
          //                 : context.currentStaff!.isAbsent
          //                     ? const Color.fromRGBO(200, 32, 32, 1)
          //                     : null,
          //         borderRadius: BorderRadius.circular(100),
          //         border: Border.all(
          //           color: Colors.white,
          //           width: statusBorder,
          //         ),
          //       ),
          //     ),
          //   ),
        ],
      ),
    );
    //   },
    // );
  }
}
