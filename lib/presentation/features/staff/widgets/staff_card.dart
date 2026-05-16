import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/presentation/features/staff/view/edit_profile_details_screen.dart';
import 'package:wowcare/shared/common/widgets/delete_confirmation_bottom_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

class StaffCard extends StatefulWidget {
  const StaffCard({
    super.key,
    required this.staffCode,
    required this.name,
    required this.classroom,
    this.avatarUrl,
    this.profilePhotoAssetCode,
    required this.allowedClassrooms,
    required this.schedule,
    required this.designation,
    this.email = '',
    required this.phoneNumber,
    required this.isActive,
    this.status,
    this.onPrimaryAction,
    this.onEdit,
    this.isSelected = false,
    this.onSelected,
    required this.availableClassrooms,
    required this.classroomCodeByName,
    this.workScheduleByDay = const <String, String>{},
    this.breakScheduleByDay = const <String, String>{},
  });

  final String staffCode;
  final String name;
  final String classroom;
  final String? avatarUrl;
  final String? profilePhotoAssetCode;
  final List<String> allowedClassrooms;
  final List<String> schedule;
  final String designation;
  final String email;
  final String phoneNumber;
  final bool isActive;
  final String? status;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onEdit;
  final bool isSelected;
  final ValueChanged<bool?>? onSelected;
  final List<String> availableClassrooms;
  final Map<String, String> classroomCodeByName;

  /// Day-of-week (MONDAY, TUESDAY, ...) → "start - end" work time.
  final Map<String, String> workScheduleByDay;

  /// Day-of-week (MONDAY, TUESDAY, ...) → "start - end" break time.
  final Map<String, String> breakScheduleByDay;

  @override
  State<StaffCard> createState() => _StaffCardState();
}

class _StaffCardState extends State<StaffCard> {
  bool isExpanded = false;

  /// Formats enum-style strings from the API into human readable labels.
  /// Examples:
  /// - "ASSOCIATE_TEACHER" -> "Associate Teacher"
  /// - "FULL_TIME" -> "Full-Time"
  /// - "PART_TIME" -> "Part-Time"
  String _formatEnumLabel(String? value) {
    if (value == null || value.trim().isEmpty) return '-';
    final upper = value.trim().toUpperCase();

    // Special cases for job type
    if (upper == 'FULL_TIME') return 'Full-Time';
    if (upper == 'PART_TIME') return 'Part-Time';

    // Generic: split on underscores/spaces and title‑case each part.
    final parts = upper.split(RegExp(r'[_\s]+'));
    final words = parts
        .map((part) {
          if (part.isEmpty) return '';
          final lower = part.toLowerCase();
          return lower[0].toUpperCase() + lower.substring(1);
        })
        .where((w) => w.isNotEmpty);
    return words.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final primaryClassroomName = widget.classroom.trim();
    final orderedAllowedClassrooms = <String>[
      if (primaryClassroomName.isNotEmpty) primaryClassroomName,
      ...widget.allowedClassrooms
          .map((name) => name.trim())
          .where(
            (name) =>
                name.isNotEmpty &&
                name.toLowerCase() != primaryClassroomName.toLowerCase(),
          ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        return IntrinsicHeight(
          child: Container(
            width: constraints.maxWidth,
            height: isExpanded ? null : 64.0,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorderColor, width: 1),
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    isExpanded = !isExpanded;
                  });
                },
                child: Column(
                  children: [
                    Container(
                      height: 60,
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 24 : 16,
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (!isExpanded)
                            CustomCheckbox(
                              value: widget.isSelected,
                              onChanged: widget.onSelected ?? (_) {},
                              scale: 1.2,
                              borderColor: null,
                              label: null,
                            ),
                          // Replaced the bubble circle and letter initials with DocumentImageWidget
                          /*
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF80A3DC),
                              image: (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty)
                                  ? DecorationImage(
                                      image: NetworkImage(widget.avatarUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: (widget.avatarUrl == null || widget.avatarUrl!.isEmpty)
                                ? Text(
                                    _getInitials(widget.name),
                                    style: const TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      height: 16 / 12,
                                    ),
                                  )
                                : null,
                          ),
                          */
                          DocumentImageWidget(
                            fileUuid: widget.staffCode,
                            imageUrl: widget.avatarUrl,
                            mediaAssetCode: widget.profilePhotoAssetCode,
                            name: widget.name,
                            staffCode: widget.staffCode,
                            staffEmploymentStatus: widget.status,
                            disableProfileLookupFallback: true,
                            size: 50,
                          ),
                          SizedBox(width: isTablet ? 16 : 9),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.name,
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
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    widget.classroom,
                                    style: TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: isTablet ? 16 : 14,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xff573353),
                                      height: 19 / 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isExpanded) ...[
                      const Divider(
                        height: 1,
                        thickness: 1,
                        indent: 16,
                        endIndent: 16,
                        color: Color(0xFFE9ECEF),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Allowed\nClassroom',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff573353),
                                    height: 16 / 13,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children: [
                                        if (orderedAllowedClassrooms.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0x4DB1AFE9),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              orderedAllowedClassrooms[0],
                                              style: const TextStyle(
                                                fontFamily: 'Manrope',
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                                color: Color(0xFF4B5B7A),
                                              ),
                                            ),
                                          ),
                                        if (orderedAllowedClassrooms.length > 1)
                                          Tooltip(
                                            message: orderedAllowedClassrooms
                                                .skip(1)
                                                .join(', '),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0x66D9FFCB),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                '+${orderedAllowedClassrooms.length - 1}',
                                                style: const TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w400,
                                                  color: Color(0xFF1B237E),
                                                  height: 15 / 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Schedule',
                                    style: TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xff573353),
                                      height: 16 / 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    alignment: WrapAlignment.start,
                                    children: [
                                      ...[
                                        'Mon',
                                        'Tue',
                                        'Wed',
                                        'Thu',
                                        'Fri',
                                      ].map((shortDay) {
                                        String enumDay;
                                        switch (shortDay) {
                                          case 'Mon':
                                            enumDay = 'MONDAY';
                                            break;
                                          case 'Tue':
                                            enumDay = 'TUESDAY';
                                            break;
                                          case 'Wed':
                                            enumDay = 'WEDNESDAY';
                                            break;
                                          case 'Thu':
                                            enumDay = 'THURSDAY';
                                            break;
                                          case 'Fri':
                                          default:
                                            enumDay = 'FRIDAY';
                                            break;
                                        }

                                        final work =
                                            widget.workScheduleByDay[enumDay];
                                        final brk =
                                            widget.breakScheduleByDay[enumDay];
                                        final hasWork =
                                            work != null &&
                                            work.trim().isNotEmpty;
                                        final hasBreak =
                                            brk != null &&
                                            brk.trim().isNotEmpty;
                                        final isActive = hasWork || hasBreak;

                                        final chip = Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isActive
                                                ? const Color(
                                                    0xFF6C7FD8,
                                                  ).withOpacity(0.12)
                                                : const Color(0xFFF3F4FB),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            shortDay,
                                            style: TextStyle(
                                              fontFamily: 'Manrope',
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: isActive
                                                  ? const Color(0xFF6C7FD8)
                                                  : const Color(0xFFB1AFC9),
                                            ),
                                          ),
                                        );

                                        if (!isActive) {
                                          // Greyed-out, non-interactive for days without schedule.
                                          return Opacity(
                                            opacity: 0.4,
                                            child: chip,
                                          );
                                        }

                                        final tooltipLines = <String>[];
                                        if (hasWork) {
                                          tooltipLines.add('Work: $work');
                                        }
                                        if (hasBreak) {
                                          tooltipLines.add('Break: $brk');
                                        }
                                        final tooltipText = tooltipLines.isEmpty
                                            ? '$shortDay: Scheduled'
                                            : '$shortDay\n${tooltipLines.join('\n')}';

                                        return Tooltip(
                                          message: tooltipText,
                                          child: chip,
                                        );
                                      }),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'Designation',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff573353),
                                    height: 16 / 13,
                                  ),
                                ),
                                Text(
                                  _formatEnumLabel(widget.designation),
                                  style: const TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xff573353),
                                    height: 19 / 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'Email',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff573353),
                                    height: 16 / 13,
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    widget.email.isNotEmpty
                                        ? widget.email
                                        : '-',
                                    style: const TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xff573353),
                                      height: 19 / 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'Phone Number',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff573353),
                                    height: 16 / 13,
                                  ),
                                ),
                                SelectableText(
                                  _formatUsPhone(widget.phoneNumber),
                                  contextMenuBuilder:
                                      (
                                        BuildContext context,
                                        dynamic editableState,
                                      ) {
                                        final List<ContextMenuButtonItem>
                                        items =
                                            List<ContextMenuButtonItem>.from(
                                              editableState
                                                  .contextMenuButtonItems,
                                            );
                                        items.add(
                                          ContextMenuButtonItem(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              _callPhone(widget.phoneNumber);
                                            },
                                            label: 'Call',
                                          ),
                                        );
                                        return AdaptiveTextSelectionToolbar.buttonItems(
                                          anchors:
                                              editableState.contextMenuAnchors,
                                          buttonItems: items,
                                        );
                                      },
                                  style: const TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xff573353),
                                    height: 19 / 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 40,
                                    child: OutlinedButton(
                                      onPressed: () {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (ctx) {
                                            return DeleteConfirmationBottomSheet(
                                              name: widget.name,
                                              type: widget.isActive
                                                  ? 'staff_deactivate'
                                                  : 'staff_reactivate',
                                              onDelete: () {
                                                widget.onPrimaryAction?.call();
                                                return Future.value();
                                              },
                                              onCancel: () {
                                                Navigator.of(ctx).pop();
                                              },
                                            );
                                          },
                                        );
                                      },
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: Color(0xFF6C7FD8),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: Text(
                                        widget.isActive
                                            ? 'Deactivate'
                                            : 'Reactivate',
                                        style: const TextStyle(
                                          fontFamily: 'Manrope',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF6C7FD8),
                                          height: 16 / 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      gradient:
                                          AppColors.buildPrimaryGradient(),
                                    ),
                                    child: TextButton(
                                      onPressed: () {
                                        // Invoke external handler if provided
                                        widget.onEdit?.call();

                                        // Derive first/last name from full name
                                        final parts = widget.name.trim().split(
                                          ' ',
                                        );
                                        final initialFirstName =
                                            parts.isNotEmpty ? parts.first : '';
                                        final initialLastName = parts.length > 1
                                            ? parts.sublist(1).join(' ')
                                            : '';

                                        // Map status from API format to UI format
                                        String? mappedStatus;
                                        if (widget.status != null) {
                                          final statusUpper = widget.status!
                                              .toUpperCase();
                                          if (statusUpper == 'ACTIVE') {
                                            mappedStatus = 'Active';
                                          } else if (statusUpper ==
                                              'INACTIVE') {
                                            mappedStatus = 'Inactive';
                                          } else if (statusUpper ==
                                              'UPCOMING') {
                                            mappedStatus = 'Upcoming';
                                          } else {
                                            mappedStatus = widget.status;
                                          }
                                        }

                                        Navigator.of(context)
                                            .push(
                                              MaterialPageRoute(
                                                builder: (_) => EditProfileDetailsScreen(
                                                  staffCode: widget.staffCode,
                                                  initialFirstName:
                                                      initialFirstName,
                                                  initialLastName:
                                                      initialLastName,
                                                  initialStatus: mappedStatus,
                                                  initialDesignation:
                                                      widget.designation,
                                                  initialAllowedClassrooms:
                                                      widget.allowedClassrooms,
                                                  initialPrimaryClassroom:
                                                      widget.classroom,
                                                  initialEmail: widget.email,
                                                  initialPhoneNumber:
                                                      widget.phoneNumber,
                                                  initialClassroomNames: widget
                                                      .availableClassrooms,
                                                  initialClassroomCodeByName: {
                                                    for (final entry
                                                        in widget
                                                            .classroomCodeByName
                                                            .entries)
                                                      entry.value: entry.key,
                                                  },
                                                ),
                                              ),
                                            )
                                            .then((_) {
                                              if (context.mounted) {
                                                context
                                                    .read<StaffCubit>()
                                                    .refresh();
                                              }
                                            });
                                      },
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                      ),
                                      child: const Text(
                                        'Edit',
                                        style: TextStyle(
                                          fontFamily: 'Manrope',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          height: 16 / 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatUsPhone(String input) {
    // Keep digits only
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return input;
    final area = digits.substring(0, 3);
    final mid = digits.substring(3, 6);
    final last = digits.substring(6, 10);
    return '($area) $mid-$last';
  }

  Future<void> _callPhone(String phone) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri(scheme: 'tel', path: digits);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
