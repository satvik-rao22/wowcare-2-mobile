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
  final String name;
  final String imageUrl;
  final DataMap icons;
  final bool isSelected;
  final ValueChanged<bool?> onSelectionChanged;
  final bool isSignedIn;
  final bool isAbsent;
  final bool isExpectedToday;
  final String studentStatus;

  const ClassroomStudentListItem({
    super.key,
    this.isSelected = false,
    required this.studentId,
    required this.onSelectionChanged,
    required this.isSignedIn,
    required this.isAbsent,
    required this.isExpectedToday,
    required this.name,
    required this.imageUrl,
    required this.icons,
    required this.studentStatus,
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        color: widget.isExpectedToday ? null : Colors.grey[100],
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
          Opacity(
            opacity: widget.isExpectedToday ? 1 : 0.5,
            child: AbsorbPointer(
              absorbing: !widget.isExpectedToday,
              child: GestureDetector(
                onTap: () => widget.onSelectionChanged(!widget.isSelected),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        // Use lightweight UI-only DocumentImageWidget (backend disabled inside)
                        DocumentImageWidget(
                          fileUuid: widget.imageUrl,
                          name: widget.name,
                          size: 50,
                        ),
                        if (widget.isSignedIn ||
                            widget.isAbsent ||
                            widget.studentStatus == 'Upcoming')
                          Positioned(
                            right: 0, // Moved to top right
                            top: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: widget.studentStatus == 'Upcoming'
                                    ? const Color.fromARGB(255, 253, 205, 22)
                                    : widget.isSignedIn
                                        ? const Color.fromRGBO(0, 177, 21, 1)
                                        : widget.isAbsent
                                            ? const Color.fromRGBO(
                                                200, 32, 32, 1)
                                            : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 15,
                                minHeight: 15,
                              ),
                            ),
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
                    Text(
                      widget.name.isNotEmpty
                          ? widget.name.split(' ').first
                          : '',
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        color: AppColors.primaryColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
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
