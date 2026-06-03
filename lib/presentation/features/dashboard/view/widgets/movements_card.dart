import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/domain/features/availability/entities/individual_movement.dart';
import 'package:wowcare/domain/features/availability/entities/individual_movement_board.dart';
import 'package:wowcare/presentation/features/availability/cubit/individual_movements_cubit.dart';
import 'package:wowcare/presentation/features/availability/view/individual_movement_screen.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_card_header.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

// ---------------------------------------------------------------------------
// UI-layer student model
// ---------------------------------------------------------------------------

class _MovementStudent {
  const _MovementStudent({
    required this.id,
    required this.name,
    required this.avatarInitials,
    this.profilePhotoAssetCode,
  });

  final int id;
  final String name;
  final String avatarInitials;
  final String? profilePhotoAssetCode;
}

// ---------------------------------------------------------------------------
// UI-layer grouped movement row
// ---------------------------------------------------------------------------

class _GroupedMovement {
  _GroupedMovement({
    required this.movementDate,
    required this.movementDay,
    required this.movementMonth,
    required this.enrollmentStatus,
    required this.isLeaving,
    this.currentRoom,
    this.nextRoom,
    required this.students,
  });

  final DateTime movementDate;
  final String movementDay;
  final String movementMonth;
  final String enrollmentStatus;
  final bool isLeaving;
  final String? currentRoom;
  final String? nextRoom;
  final List<_MovementStudent> students;
}

// ---------------------------------------------------------------------------
// Priority & filtering helpers
// ---------------------------------------------------------------------------

/// Check if a movement is within the last 30 days from today.
bool _isWithinLastMonth(DateTime movementDate) {
  final now = DateTime.now();
  final thirtyDaysAgo = now.subtract(const Duration(days: 30));
  return movementDate.isAfter(thirtyDaysAgo);
}

/// Filter priority movements: overdue → upcoming → confirmed, max 3 items.
List<_GroupedMovement> _filterPriorityMovements(
  IndividualMovementBoard board, {
  int maxRows = 3,
}) {
  final map = <String, _GroupedMovement>{};

  void addBucket(List<IndividualMovement> movements, String label) {
    for (final m in movements) {
      final dateKey = _dateKey(m.movementDate);
      final key = '$dateKey|${m.fromClassroomCode}|${m.toClassroomCode}|$label';
      final existing = map[key];
      if (existing != null) {
        existing.students.add(_studentFrom(m));
      } else {
        final from = m.fromClassroomName.trim().isEmpty
            ? null
            : m.fromClassroomName.trim();
        final to = m.toClassroomName.trim().isEmpty
            ? null
            : m.toClassroomName.trim();
        map[key] = _GroupedMovement(
          movementDate: m.movementDate,
          movementDay: m.movementDate.day.toString().padLeft(2, '0'),
          movementMonth: _monthAbbr(m.movementDate.month),
          enrollmentStatus: label,
          isLeaving: m.movementType == IndividualMovementType.leaveSchool,
          currentRoom: from,
          nextRoom: to,
          students: [_studentFrom(m)],
        );
      }
    }
  }

  // Priority: Overdue > Upcoming > Confirmed
  // Step 1: Check for overdue within last 1 month
  final recentOverdue = board.overdue.where((m) => _isWithinLastMonth(m.movementDate)).toList();
  if (recentOverdue.isNotEmpty) {
    addBucket(recentOverdue, 'Overdue');
    final rows = map.values.toList(growable: false);
    // Sort overdue: most recent first
    rows.sort((a, b) => b.movementDate.compareTo(a.movementDate));
    return rows.length <= maxRows ? rows : rows.sublist(0, maxRows);
  }

  // Step 2: No overdue, check upcoming
  if (board.upcoming.isNotEmpty) {
    addBucket(board.upcoming, 'Upcoming');
    final rows = map.values.toList(growable: false);
    // Sort upcoming: nearest first
    rows.sort((a, b) => a.movementDate.compareTo(b.movementDate));
    return rows.length <= maxRows ? rows : rows.sublist(0, maxRows);
  }

  // Step 3: No overdue/upcoming, show confirmed
  if (board.confirmed.isNotEmpty) {
    addBucket(board.confirmed, 'Confirmed');
    final rows = map.values.toList(growable: false);
    // Sort confirmed: latest first
    rows.sort((a, b) => b.movementDate.compareTo(a.movementDate));
    return rows.length <= maxRows ? rows : rows.sublist(0, maxRows);
  }

  return [];
}

_MovementStudent _studentFrom(IndividualMovement m) => _MovementStudent(
  id: m.id,
  name: m.studentName,
  avatarInitials: m.studentAvatarInitials,
  profilePhotoAssetCode: (m.profilePhotoAssetCode?.trim().isEmpty ?? true)
      ? null
      : m.profilePhotoAssetCode,
);

String _dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}'
    '${d.month.toString().padLeft(2, '0')}'
    '${d.day.toString().padLeft(2, '0')}';

String _monthAbbr(int month) {
  const abbrs = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return abbrs[(month - 1).clamp(0, 11)];
}

// ---------------------------------------------------------------------------
// MovementsCard
// ---------------------------------------------------------------------------

class MovementsCard extends StatefulWidget {
  const MovementsCard({super.key});

  @override
  State<MovementsCard> createState() => _MovementsCardState();
}

class _MovementsCardState extends State<MovementsCard> {
  bool _minimized = false;

  // ── Status colour helpers ──────────────────────────────────────────────────

  Color _statusColor(String status) {
    switch (status) {
      case 'Overdue':
        return Colors.red;
      case 'Upcoming':
        return Colors.yellow.shade700;
      case 'Confirmed':
        return Colors.green;
      case 'Rejected':
        return Colors.red.shade300;
      default:
        return Colors.grey;
    }
  }

  Color _statusBackground(String status) {
    switch (status) {
      case 'Overdue':
        return Colors.red.withValues(alpha: 0.25);
      case 'Upcoming':
        return Colors.yellow.withValues(alpha: 0.25);
      case 'Confirmed':
        return Colors.green.withValues(alpha: 0.25);
      case 'Rejected':
        return Colors.red.shade300.withValues(alpha: 0.20);
      default:
        return Colors.grey.withValues(alpha: 0.25);
    }
  }

  // ── Students dialog ────────────────────────────────────────────────────────

  void _showStudentsDialog(
    BuildContext context,
    List<_MovementStudent> students,
  ) {
    unawaited(
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
                  final s = students[index];
                  return ListTile(
                    leading: DocumentImageWidget(
                      fileUuid: '',
                      mediaAssetCode: s.profilePhotoAssetCode,
                      name: s.name.isEmpty ? s.avatarInitials : s.name,
                      size: 40,
                      fontSize: 16,
                      disableProfileLookupFallback: true,
                      disableAttendanceStatusLookup: true,
                    ),
                    title: Text(s.name),
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
      ),
    );
  }

  // ── Student avatar stack (max 5, overflow indicator) ──────────────────────

  Widget _buildStudentAvatars(List<_MovementStudent> students) {
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
                final s = students[index];
                return Positioned(
                  right: index * 5.0,
                  child: isOverflowSlot
                      ? Container(
                          height: 45,
                          width: 45,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade400,
                            border: Border.all(color: Colors.white, width: 2),
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
                            mediaAssetCode: s.profilePhotoAssetCode,
                            name: s.name.isEmpty ? s.avatarInitials : s.name,
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

  // ── Status pill badge ──────────────────────────────────────────────────────

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

  // ── Individual movement row ────────────────────────────────────────────────

  Widget _buildMoveItem({
    required String month,
    required String day,
    required String studentCount,
    required String from,
    required String to,
    required List<_MovementStudent> students,
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
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
            // Coloured vertical divider
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
                      if (students.length == 1)
                        Flexible(
                          child: Text(
                            students.first.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      else
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
                  Text(
                    from.isEmpty ? to : '$from → $to',
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

  // ── Empty state ────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.swap_horiz_rounded, size: 36, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'No movements scheduled',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

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
          DashboardCardHeader(
            title: 'Movements',
            showRedirect: true,
            onRedirect: () => context.go(IndividualMovementScreen.routeName),
            minimized: _minimized,
            onToggle: () => setState(() => _minimized = !_minimized),
          ),
          const SizedBox(height: 24),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _minimized ? const SizedBox.shrink() : _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<IndividualMovementsCubit, IndividualMovementsState>(
      // Only rebuild when board content or loading state changes.
      buildWhen: (prev, curr) =>
          prev.board != curr.board ||
          prev.isLoading != curr.isLoading ||
          prev.isRefreshing != curr.isRefreshing,
      builder: (context, state) {
        // First load — no data yet → shimmer.
        if (state.isLoading && state.board == null) {
          return const MovementsCardShimmer();
        }

        // Error with no data.
        if (state.board == null && state.errorMessage != null) {
          return _buildEmptyState();
        }

        if (state.board != null) {
          // Priority filtering and sorting (max 3 items) happen in _filterPriorityMovements.
          final rows = _filterPriorityMovements(state.board!);
          if (rows.isEmpty) return _buildEmptyState();

          return Column(
            children: rows
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
          );
        }

        return const MovementsCardShimmer();
      },
    );
  }
}
