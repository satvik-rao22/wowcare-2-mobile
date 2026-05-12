import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
// The following imports depend on backend/bloc not available now. Keeping commented.
// import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
// import 'package:wowcare/src/documents/presentation/bloc/document_bloc.dart';
// import 'package:wowcare/core/services/injection_container.dart';
// import 'package:wowcare/core/util/typedefs.dart';

// Local fallback typedef since global typedefs are not available here
typedef DataMap = Map<String, dynamic>;

class ClassroomStudentListItem extends StatefulWidget {
  final int studentId;
  final String studentCode;
  final String name;
  final String imageUrl;
  final DataMap icons;
  final bool isSelected;
  final ValueChanged<bool?> onSelectionChanged;
  final bool isSignedIn;
  final bool isAbsent;
  final bool isExpectedToday;
  final String studentStatus;
  final String? todayAttendanceStatusRaw;

  const ClassroomStudentListItem({
    super.key,
    this.isSelected = false,
    required this.studentId,
    required this.studentCode,
    required this.onSelectionChanged,
    required this.isSignedIn,
    required this.isAbsent,
    required this.isExpectedToday,
    required this.name,
    required this.imageUrl,
    required this.icons,
    required this.studentStatus,
    this.todayAttendanceStatusRaw,
  });

  @override
  State<ClassroomStudentListItem> createState() =>
      _ClassroomStudentListItemState();
}

class _ClassroomStudentListItemState extends State<ClassroomStudentListItem> {
  @override
  void initState() {
    super.initState();
    // Backend dependent. Disabled for now; UI uses static placeholder.
    // getStudentProfile();
  }

  // Backend dependent. Disabled for now; UI uses static placeholder.
  // void getStudentProfile() {
  //   DataMap parameters = {
  //     'fileUuid.equals': widget.imageUrl,
  //   };
  //   context.read<DocumentBloc>().add(DownloadDocument(parameters));
  // }

  @override
  Widget build(BuildContext context) {
    final normalizedAttendance =
        (widget.todayAttendanceStatusRaw ?? '').trim().toUpperCase();
    final hasAttendanceStatus =
        normalizedAttendance == 'SIGNED_IN' || normalizedAttendance == 'ABSENT';
    final shouldGreyOut = !widget.isExpectedToday &&
        !widget.isSignedIn &&
        !widget.isAbsent &&
        !hasAttendanceStatus;
    final enrollmentStatus = widget.studentStatus.trim();
    final Color? attendanceDotColor = normalizedAttendance == 'SIGNED_IN'
        ? Colors.green
        : (normalizedAttendance == 'ABSENT' ? Colors.red : null);
    final String? attendanceTooltip = normalizedAttendance == 'SIGNED_IN'
        ? 'Student is signed in'
        : (normalizedAttendance == 'ABSENT' ? 'Student is absent' : null);
    final rawPhoto = widget.imageUrl.trim();
    final bool looksLikeUrl =
        rawPhoto.startsWith('http://') || rawPhoto.startsWith('https://');
    final String? directUrl = looksLikeUrl ? rawPhoto : null;
    final String? assetCode =
        (!looksLikeUrl && rawPhoto.isNotEmpty) ? rawPhoto : null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        color: shouldGreyOut ? Colors.grey[100] : null,
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: CustomCheckbox(
              borderColor: AppColors.primaryColor.withValues(alpha: 0.2),
              value: widget.isSelected,
              onChanged: widget.onSelectionChanged,
            ),
          ),
          Expanded(
            child: Opacity(
              opacity: shouldGreyOut ? 0.5 : 1,
              child: AbsorbPointer(
                absorbing: shouldGreyOut,
                child: GestureDetector(
                  onTap: () => widget.onSelectionChanged(!widget.isSelected),
                  child: Row(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          DocumentImageWidget(
                            fileUuid: widget.studentCode.trim().isNotEmpty
                                ? widget.studentCode
                                : widget.studentId.toString(),
                            imageUrl: directUrl,
                            mediaAssetCode: assetCode,
                            name: widget.name,
                            studentCode: widget.studentCode.trim().isNotEmpty
                                ? widget.studentCode.trim()
                                : null,
                            studentEnrollmentStatus: enrollmentStatus,
                            statusColor: attendanceDotColor,
                            statusTooltip: attendanceTooltip,
                            disableAttendanceStatusLookup: true,
                            size: 50,
                          ),
                          if (widget.icons.containsKey('napping'))
                            Positioned(
                              right: 0, // Moved to top right
                              top: 0,
                              child: Tooltip(
                                message: 'Student is currently napping',
                                child: SvgPicture.asset(
                                  // Guard against empty path in assets
                                  MediaRes.napIcon.isNotEmpty
                                      ? MediaRes.napIcon
                                      : MediaRes.sleepIcon,
                                  height: 18,
                                  width: 18,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.name.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            color: AppColors.primaryColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            height: 1.25,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text(
                    'Details',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      color: AppColors.primaryColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: widget.icons.entries.map((entry) {
                      final String iconPath = entry.value["icon"];
                      final bool isSvg =
                          iconPath.toLowerCase().endsWith('.svg');

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            isSvg
                                ? SvgPicture.asset(iconPath, height: 24)
                                : Image.asset(iconPath, height: 24),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                entry.value["info"] ??
                                    getDefaultIconDetail(entry.key),
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 14,
                                  color: Color(0xff573353),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            child: Row(
              children: widget.icons.entries.map((entry) {
                final String iconPath = entry.value["icon"];
                final bool isSvg = iconPath.toLowerCase().endsWith('.svg');
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Tooltip(
                    message:
                        entry.value["info"] ?? getDefaultIconDetail(entry.key),
                    child: isSvg
                        ? SvgPicture.asset(iconPath, height: 18)
                        : Image.asset(iconPath, height: 18),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

String getDefaultIconDetail(String key) {
  Map<String, String> details = {
    "photo": "Photo Permission not given by parent",
    "medication": "Student has health concerns",
    "note": "Documents not submitted",
    "allergies": "Observe first aid",
    "dietRestriction": "Observe first aid",
    "napping": "Student is currently napping",
  };

  return details[key] ?? 'Details not available';
}
