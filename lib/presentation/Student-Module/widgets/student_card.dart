import 'package:flutter/material.dart';
import '../../../shared/common/widgets/custom_checkbox.dart';

class StudentCard extends StatefulWidget {
  final String name;
  final String classroom;
  final String? avatarUrl;
  final List<String> tags;
  final List<String> schedule;
  final String birthdate;
  final String movementDate;
  final VoidCallback? onDeactivate;
  final VoidCallback? onEdit;
  final bool isSelected;
  final ValueChanged<bool?>? onSelected;

  const StudentCard({
    Key? key,
    required this.name,
    required this.classroom,
    this.avatarUrl,
    required this.tags,
    required this.schedule,
    required this.birthdate,
    required this.movementDate,
    this.onDeactivate,
    this.onEdit,
    this.isSelected = false,
    this.onSelected,
  }) : super(key: key);

  @override
  State<StudentCard> createState() => _StudentCardState();
}

class _StudentCardState extends State<StudentCard> {
  bool isExpanded = false;

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '';
    final parts = trimmed.split(' ');
    if (parts.length == 1) {
      final firstLetter = parts[0].isNotEmpty ? parts[0][0] : '';
      return (firstLetter + firstLetter).toUpperCase();
    } else {
      String first = parts[0].isNotEmpty ? parts[0][0] : '';
      String second = parts.length > 1 && parts[1].isNotEmpty
          ? parts[1][0]
          : '';
      return (first + second).toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeTablet = screenWidth > 900;
    final expandedHeight = isLargeTablet
        ? 240.0
        : isTablet
        ? 260.0
        : 250.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return IntrinsicHeight(
          child: Container(
            width: constraints.maxWidth,
            height: isExpanded ? null : 64.0,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x1A162831), width: 1),
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
                          // CustomCheckbox
                          CustomCheckbox(
                            value: widget.isSelected,
                            onChanged: widget.onSelected!,
                            scale: 1.2,
                            borderColor: null,
                            label: null,
                          ),
                          // Avatar
                          Container(
                            width: isTablet ? 38 : 38,
                            height: isTablet ? 38 : 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF80A3DC),
                              image:
                                  (widget.avatarUrl != null &&
                                      widget.avatarUrl!.isNotEmpty)
                                  ? DecorationImage(
                                      image: NetworkImage(widget.avatarUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: (() {
                              // Debug print for avatarUrl
                              // ignore: avoid_print
                              print(
                                'StudentCard avatarUrl: \'${widget.avatarUrl}\' for name: \'${widget.name}\'',
                              );
                              if (widget.avatarUrl == null ||
                                  widget.avatarUrl!.isEmpty) {
                                final initials = _getInitials(widget.name);
                                // ignore: avoid_print
                                print(
                                  'StudentCard showing initials: $initials',
                                );
                                return Text(
                                  initials,
                                  style: const TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    height: 16 / 12,
                                  ),
                                  textAlign: TextAlign.center,
                                );
                              }
                              // ignore: avoid_print
                              print(
                                'StudentCard showing image for: ${widget.name}',
                              );
                              return null;
                            })(),
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
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Tags row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  "Tags",
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff573353),
                                    height: 16 / 12,
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (widget.tags.isNotEmpty)
                                      Container(
                                        margin: const EdgeInsets.only(right: 6),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0x4DB1AFE9),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                                        margin: const EdgeInsets.only(right: 6),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0x66CBF6FF),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
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
                                      MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: Tooltip(
                                          message: widget.tags
                                              .skip(2)
                                              .join(', '),
                                          waitDuration: Duration(
                                            milliseconds: 200,
                                          ),
                                          showDuration: Duration(seconds: 3),
                                          textStyle: const TextStyle(
                                            fontFamily: "Manrope",
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            color: Color(0xff1b237e),
                                            height: 15 / 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xff1b237e),
                                              width: 1,
                                            ),
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0x66D9FFCB),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              "+${widget.tags.length - 2}",
                                              style: const TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 12,
                                                fontWeight: FontWeight.w400,
                                                color: Color(0xff1b237e),
                                                height: 15 / 12,
                                              ),
                                              textAlign: TextAlign.left,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Schedule row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  "Schedule",
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff573353),
                                    height: 16 / 12,
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                                Expanded(
                                  child: Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    alignment: WrapAlignment.end,
                                    children: [
                                      ...[
                                        "Mon",
                                        "Tue",
                                        "Wed",
                                        "Thu",
                                        "Fri",
                                      ].map((day) {
                                        final isActive = widget.schedule
                                            .contains(day);
                                        return Container(
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
                                      }),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Birthdate row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  "Birthdate",
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff573353),
                                    height: 16 / 12,
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                                Text(
                                  widget.birthdate,
                                  style: const TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xff573353),
                                    height: 19 / 14,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Movement Date row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  "Movement Date",
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xff573353),
                                    height: 16 / 12,
                                  ),
                                  textAlign: TextAlign.left,
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
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ),
                            // const SizedBox(height: 18),
                            // // Buttons row (unchanged)
                            // Row(
                            //   children: [
                            //     Expanded(
                            //       child: SizedBox(
                            //         height: 40,
                            //         child: OutlinedButton(
                            //           onPressed: widget.onDeactivate,
                            //           style: OutlinedButton.styleFrom(
                            //             side: const BorderSide(color: Color(0xFF6C7FD8)),
                            //             shape: RoundedRectangleBorder(
                            //               borderRadius: BorderRadius.circular(8),
                            //             ),
                            //             padding: EdgeInsets.zero,
                            //           ),
                            //           child: const Text(
                            //             "Deactivate",
                            //             style: TextStyle(
                            //               fontFamily: 'Manrope',
                            //               fontSize: 16,
                            //               fontWeight: FontWeight.w700,
                            //               color: Color(0xFF6C7FD8),
                            //               height: 16 / 16,
                            //             ),
                            //           ),
                            //         ),
                            //       ),
                            //     ),
                            //     const SizedBox(width: 16),
                            //     Expanded(
                            //       child: Container(
                            //         height: 40,
                            //         decoration: BoxDecoration(
                            //           borderRadius: BorderRadius.circular(8),
                            //           gradient: AppColors.buildPrimaryGradient(),
                            //         ),
                            //         child: TextButton(
                            //           onPressed: widget.onEdit,
                            //           style: TextButton.styleFrom(
                            //             padding: EdgeInsets.zero,
                            //           ),
                            //           child: const Text(
                            //             "Edit",
                            //             style: TextStyle(
                            //               fontFamily: 'Manrope',
                            //               fontSize: 16,
                            //               fontWeight: FontWeight.w700,
                            //               color: Colors.white,
                            //               height: 16 / 16,
                            //             ),
                            //           ),
                            //         ),
                            //       ),
                            //     ),
                            //   ],
                            // ),
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
