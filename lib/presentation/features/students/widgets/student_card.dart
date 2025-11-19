import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

import '../../../../shared/common/widgets/delete_confirmation_bottom_sheet.dart';

class StudentCard extends StatefulWidget {
  const StudentCard({
    super.key,
    required this.name,
    required this.classroom,
    this.avatarUrl,
    required this.tags,
    required this.sibling,
    required this.schedule,
    required this.birthDate,
    required this.movementDate,
    required this.status,
    this.onDeactivate,
    this.onEdit,
    this.isSelected = false,
    this.onSelected,
  });

  final String name;
  final String classroom;
  final String? avatarUrl;
  final List<String> tags;
  final Map<String, dynamic> sibling;
  final List<String> schedule;
  final String birthDate;
  final String movementDate;
  final String status;
  final VoidCallback? onDeactivate;
  final VoidCallback? onEdit;
  final bool isSelected;
  final ValueChanged<bool?>? onSelected;

  @override
  State<StudentCard> createState() => _StudentCardState();
}

class _StudentCardState extends State<StudentCard> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

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
                          Stack(
                            children: [
                              DocumentImageWidget(
                                fileUuid: '',
                                name: widget.name,
                                size: 45,
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: widget.status == 'upcoming'
                                        ? const Color.fromARGB(255, 253, 205, 22)
                                        : widget.status == 'signedIn'
                                        ? const Color.fromRGBO(0, 177, 21, 1)
                                        : widget.status == 'isAbsent'
                                        ? const Color.fromRGBO(200, 32, 32, 1)
                                        : Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),

                                ),
                              ),

                            ],
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
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Tags',
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
                                        if (widget.tags.isNotEmpty)
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
                                              widget.tags[0],
                                              style: const TextStyle(
                                                fontFamily: 'Manrope',
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                                color: Color(0xFF4B5B7A),
                                              ),
                                            ),
                                          ),
                                        if (widget.tags.length > 1)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0x66CBF6FF),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              widget.tags[1],
                                              style: const TextStyle(
                                                fontFamily: 'Manrope',
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                                color: Color(0xFF4B5B7A),
                                              ),
                                            ),
                                          ),
                                        if (widget.tags.length > 2)
                                          Tooltip(
                                            message: widget.tags
                                                .skip(2)
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
                                                '+${widget.tags.length - 2}',
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
                                        Tooltip(
                                          message: 'Edit tags',
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.mode_edit_outline_outlined,
                                              color: const Color(0xFFCECECE),
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
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                      ].map((day) {
                                        final isActive = widget.schedule
                                            .contains(day);
                                        final dayChip = Container(
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
                                            day,
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
                                        if (!isActive) return dayChip;
                                        return Tooltip(
                                          message: '',
                                          child: dayChip,
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
                                  'Birth Date',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff573353),
                                    height: 16 / 13,
                                  ),
                                ),
                                Text(
                                  widget.birthDate,
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
                                  'Movement Date',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff573353),
                                    height: 16 / 13,
                                  ),
                                ),
                                Text(
                                  widget.movementDate,
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
                            const SizedBox(height: 20),
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
                                              type: 'student',
                                              onDelete: () {
                                                Navigator.of(ctx).pop();
                                                //widget.onDelete?.call();
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
                                      child: const Text(
                                        'Deactivate',
                                        style: TextStyle(
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
                                        // final parts = widget.name.trim().split(' ');
                                        // final initialFirstName = parts.isNotEmpty ? parts.first : '';
                                        // final initialLastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
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
}
