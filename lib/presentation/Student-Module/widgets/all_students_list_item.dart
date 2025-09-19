import 'package:flutter/material.dart';
import '../../../domain/features/Student-Module/entities/Student-Entity.dart';

class AllStudentsListItem extends StatefulWidget {
  const AllStudentsListItem(
    this.student, {
    required this.isSelected,
    required this.onSelectionChanged,
    super.key,
  });

  final StudentEntity student;
  final bool isSelected;
  final ValueChanged<bool?> onSelectionChanged;

  @override
  State<AllStudentsListItem> createState() => _AllStudentsListItemState();
}

class _AllStudentsListItemState extends State<AllStudentsListItem> {
  // Static classroom data
  final Map<int, Map<String, dynamic>> _classrooms = {
    1: {'id': 1, 'photoUuid': 'classroom_photo1', 'name': 'Classroom A'},
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Checkbox(
            value: widget.isSelected,
            onChanged: widget.onSelectionChanged,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Row(
              children: [
                Flexible(
                  flex: 3,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => widget.onSelectionChanged(!widget.isSelected),
                    child: Tooltip(
                      message: widget.student.fullName,
                      preferBelow: false,
                      child: Row(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.grey.shade300,
                                child: Text(
                                  widget.student.fullName.isNotEmpty
                                      ? widget.student.fullName[0]
                                      : 'S',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (widget.student.isSignedIn ||
                                  widget.student.isAbsent ||
                                  widget.student.profileStatus == 'Upcoming')
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color:
                                          widget.student.profileStatus ==
                                              'Upcoming'
                                          ? const Color.fromARGB(
                                              255,
                                              253,
                                              205,
                                              22,
                                            )
                                          : widget.student.isSignedIn
                                          ? const Color.fromRGBO(0, 177, 21, 1)
                                          : widget.student.isAbsent
                                          ? const Color.fromRGBO(200, 32, 32, 1)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(100),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final name = widget.student.fullName.trim();
                                final splitName = name.split(' ');

                                final textStyle = const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                );

                                final textPainter1 = TextPainter(
                                  text: TextSpan(
                                    text: splitName.first,
                                    style: textStyle,
                                  ),
                                  maxLines: 1,
                                  textDirection: TextDirection.ltr,
                                )..layout(maxWidth: constraints.maxWidth);

                                final textPainter2 = TextPainter(
                                  text: TextSpan(
                                    text: splitName.length > 1
                                        ? splitName[1]
                                        : '',
                                    style: textStyle,
                                  ),
                                  maxLines: 1,
                                  textDirection: TextDirection.ltr,
                                )..layout(maxWidth: constraints.maxWidth);

                                return Text(
                                  textPainter2.didExceedMaxLines ||
                                          textPainter2.width >=
                                              constraints.maxWidth
                                      ? '${splitName.first}\n${splitName.length > 1 ? splitName[1] : ''}'
                                      : name,
                                  style: textStyle,
                                  maxLines:
                                      textPainter1.didExceedMaxLines ||
                                          textPainter1.width >=
                                              constraints.maxWidth ||
                                          splitName.length <= 1
                                      ? 1
                                      : 2,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (widget.student.roomName.isNotEmpty)
                  Container(
                    height: 20,
                    child: VerticalDivider(
                      color: Colors.blue.withOpacity(0.3),
                      thickness: 0.5,
                      width: 0,
                    ),
                  ),
                const SizedBox(width: 4),
                Flexible(
                  flex: 2,
                  child: Tooltip(
                    message: widget.student.roomName.trim(),
                    preferBelow: false,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: Text(
                            widget.student.roomName,
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.end,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildClassroomAvatar(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassroomAvatar() {
    final classroom = _classrooms[widget.student.roomId];
    if (classroom == null || classroom['photoUuid'].isEmpty) {
      return CircleAvatar(
        backgroundColor: Colors.blueGrey,
        radius: 16,
        child: Text(
          widget.student.roomName.isNotEmpty ? widget.student.roomName[0] : 'R',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      );
    }
    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.grey.shade300,
      child: Text(
        classroom['name'][0],
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}
