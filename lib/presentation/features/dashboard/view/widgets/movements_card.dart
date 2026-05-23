import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_card_header.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

// ---------------------------------------------------------------------------
// Local model classes (UI-only, no entity imports)
// ---------------------------------------------------------------------------

class Student {
  const Student({required this.id, required this.name});

  final int id;
  final String name;
}

class GroupedMovement {
  GroupedMovement({
    required this.currentRoomId,
    required this.nextRoomId,
    required this.movementDate,
    required this.movementDay,
    required this.movementMonth,
    required this.enrollmentStatus,
    required this.isLeaving,
    required this.currentRoom,
    required this.nextRoom,
    required this.students,
  });

  final int? currentRoomId;
  final int? nextRoomId;
  final String movementDate;
  final String movementDay;
  final String movementMonth;
  final String enrollmentStatus;
  final bool isLeaving;
  final String? currentRoom;
  final String? nextRoom;
  final List<Student> students;
}

// ---------------------------------------------------------------------------
// Hardcoded mock data — 3 representative grouped movements
// ---------------------------------------------------------------------------
final List<GroupedMovement> _mockMovements = [
  GroupedMovement(
    currentRoomId: 1,
    nextRoomId: 2,
    movementDate: '2026-05-10',
    movementDay: '10',
    movementMonth: 'May',
    enrollmentStatus: 'Overdue',
    isLeaving: false,
    currentRoom: 'Infant Room',
    nextRoom: 'Toddler Room',
    students: [
      Student(id: 1, name: 'Ava Martinez'),
      Student(id: 2, name: 'Liam Johnson'),
      Student(id: 3, name: 'Sophia Lee'),
    ],
  ),
  GroupedMovement(
    currentRoomId: 2,
    nextRoomId: 3,
    movementDate: '2026-05-22',
    movementDay: '22',
    movementMonth: 'May',
    enrollmentStatus: 'Upcoming',
    isLeaving: false,
    currentRoom: 'Toddler Room',
    nextRoom: 'Pre-K Room',
    students: [
      Student(id: 4, name: 'Noah Williams'),
      Student(id: 5, name: 'Emma Davis'),
    ],
  ),
  GroupedMovement(
    currentRoomId: 3,
    nextRoomId: null,
    movementDate: '2026-06-01',
    movementDay: '01',
    movementMonth: 'Jun',
    enrollmentStatus: 'Confirmed',
    isLeaving: true,
    currentRoom: 'Pre-K Room',
    nextRoom: null,
    students: [
      Student(id: 6, name: 'Oliver Brown'),
      Student(id: 7, name: 'Isabella Jones'),
      Student(id: 8, name: 'Mia Garcia'),
      Student(id: 9, name: 'Ethan Wilson'),
      Student(id: 10, name: 'Charlotte Moore'),
      Student(id: 11, name: 'James Taylor'),
    ],
  ),
];

// ---------------------------------------------------------------------------
// MovementsCard — StatefulWidget (collapse toggle is genuine local UI state)
// ---------------------------------------------------------------------------

class MovementsCard extends StatefulWidget {
  const MovementsCard({super.key});

  @override
  State<MovementsCard> createState() => _MovementsCardState();
}

class _MovementsCardState extends State<MovementsCard> {
  bool _minimized = false;

  // -------------------------------------------------------------------------
  // Status colour helpers (inline — no ColorUtils import)
  // -------------------------------------------------------------------------

  Color _statusColor(String status) {
    if (status == 'Overdue') return Colors.red;
    if (status == 'Upcoming') return Colors.yellow.shade700;
    if (status == 'Confirmed') return Colors.green;
    return Colors.grey;
  }

  Color _statusBackground(String status) {
    if (status == 'Overdue') return Colors.red.withValues(alpha: 0.25);
    if (status == 'Upcoming') return Colors.yellow.withValues(alpha: 0.25);
    if (status == 'Confirmed') return Colors.green.withValues(alpha: 0.25);
    return Colors.grey.withValues(alpha: 0.25);
  }

  // -------------------------------------------------------------------------
  // Students dialog
  // -------------------------------------------------------------------------

  void _showStudentsDialog(BuildContext context, List<Student> students) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Students'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: students.length,
              itemBuilder: (_, index) {
                return ListTile(
                  leading: DocumentImageWidget(
                    fileUuid: '',
                    name: students[index].name,
                    size: 40,
                    fontSize: 16,
                    disableProfileLookupFallback: true,
                    disableAttendanceStatusLookup: true,
                  ),
                  title: Text(students[index].name),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // Student avatar stack (max 5, overflow indicator)
  // -------------------------------------------------------------------------

  Widget _buildStudentAvatars(List<Student> students) {
    final displayCount = students.length > 5 ? 5 : students.length;
    final overflowCount = students.length - 4;

    return InkWell(
      onTap: () => _showStudentsDialog(context, students),
      child: Row(
        children: [
          SizedBox(
            height: 45,
            width: 45,
            child: Stack(
              clipBehavior: Clip.none,
              children: List.generate(displayCount, (index) {
                final isOverflowSlot = index == 4 && students.length > 5;

                return Positioned(
                  right: index * 5.0,
                  child: isOverflowSlot
                      ? Container(
                          height: 45,
                          width: 45,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade400,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '+$overflowCount',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : Container(
                          height: 45,
                          width: 45,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: DocumentImageWidget(
                            fileUuid: '',
                            name: students[index].name,
                            size: 41,
                            fontSize: 16,
                            disableProfileLookupFallback: true,
                            disableAttendanceStatusLookup: true,
                          ),
                        ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Status pill badge
  // -------------------------------------------------------------------------

  Widget _buildStatusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: _statusBackground(status),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 16,
          color: _statusColor(status),
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Individual movement row
  // -------------------------------------------------------------------------

  Widget _buildMoveItem({
    required String month,
    required String day,
    required String studentCount,
    required String from,
    required String to,
    required List<Student> students,
    required String status,
  }) {
    return Column(
      children: [
        Row(
          children: [
            // Date column
            SizedBox(
              width: 48,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    month,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    day,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Coloured vertical divider line
            Container(
              width: 3,
              height: 64,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: _statusColor(status),
            ),
            // Movement details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            studentCount,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Students',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 4),
                      _buildStatusBadge(status),
                      const SizedBox(width: 8),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Room transition label — wrapped to avoid overflow
                  Text(
                    '$from → $to',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            _buildStudentAvatars(students),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorderColor),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Card header row
          DashboardCardHeader(
            title: 'Movements',
            showRedirect: true,
            onRedirect: () {},
            minimized: _minimized,
            onToggle: () {
              setState(() {
                _minimized = !_minimized;
              });
            },
          ),
          const SizedBox(height: 24),

          /// Collapsible body
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _minimized
                ? const SizedBox.shrink()
                : Column(
                    children: _mockMovements
                        .map(
                          (move) => _buildMoveItem(
                            month: move.movementMonth,
                            day: move.movementDay,
                            studentCount: move.students.length.toString(),
                            from: move.currentRoom ?? '',
                            to: move.isLeaving
                                ? 'Leaving the School'
                                : move.nextRoom ?? '',
                            students: move.students,
                            status: move.enrollmentStatus,
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
