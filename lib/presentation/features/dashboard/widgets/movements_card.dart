import 'dart:async';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/domain/features/availability/entities/individual_movement.dart';
import 'package:wowcare/domain/features/availability/entities/individual_movement_board.dart';
import 'package:wowcare/presentation/features/availability/view_model/individual_movements_cubit.dart';
import 'package:wowcare/presentation/features/availability/view/individual_movement_screen.dart';
import 'package:wowcare/presentation/features/availability/model/individual_movement_models.dart';
import 'package:wowcare/presentation/features/dashboard/widgets/dashboard_card_header.dart';
import 'package:wowcare/presentation/features/dashboard/widgets/dashboard_collapsible.dart';
import 'package:wowcare/presentation/features/dashboard/widgets/dashboard_error_chip.dart';
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
    this.studentCode,
  });

  final int id;
  final String name;
  final String avatarInitials;
  final String? profilePhotoAssetCode;
  final String? studentCode;
}

// ---------------------------------------------------------------------------
// UI-layer grouped movement row
// ---------------------------------------------------------------------------

class _GroupedMovement {
  _GroupedMovement({
    required this.movementDate,
    required this.movementDay,
    required this.movementMonth,
    required this.bucket,
    required this.isLeaving,
    this.currentRoom,
    this.nextRoom,
    required this.students,
  });

  final DateTime movementDate;
  final String movementDay;
  final String movementMonth;
  final MovementBucket bucket;
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
  final now = AppTime.now();
  final thirtyDaysAgo = now.subtract(const Duration(days: 30));
  return movementDate.isAfter(thirtyDaysAgo);
}

/// Keeps movements that involve [classroomCode] as source or destination.
IndividualMovementBoard _filterBoardForClassroom(
  IndividualMovementBoard board,
  String classroomCode,
) {
  final code = classroomCode.trim();
  if (code.isEmpty) return board;

  bool involves(IndividualMovement m) {
    return m.fromClassroomCode.trim() == code ||
        m.toClassroomCode.trim() == code;
  }

  return IndividualMovementBoard(
    overdue: board.overdue.where(involves).toList(growable: false),
    upcoming: board.upcoming.where(involves).toList(growable: false),
    confirmed: board.confirmed.where(involves).toList(growable: false),
    rejected: board.rejected.where(involves).toList(growable: false),
  );
}

/// Filter priority movements: overdue → confirmed → upcoming, max 3 items.
List<_GroupedMovement> _filterPriorityMovements(
  IndividualMovementBoard board, {
  int maxRows = 3,
}) {
  final map = <String, _GroupedMovement>{};

  void addBucket(List<IndividualMovement> movements, MovementBucket bucket) {
    for (final m in movements) {
      final dateKey = _dateKey(m.movementDate);
      final key =
          '$dateKey|${m.fromClassroomCode}|${m.toClassroomCode}|${bucket.name}';
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
          bucket: bucket,
          isLeaving: m.movementType == IndividualMovementType.leaveSchool,
          currentRoom: from,
          nextRoom: to,
          students: [_studentFrom(m)],
        );
      }
    }
  }

  // Priority: Overdue > Confirmed > Upcoming
  // Step 1: Add overdue within last 1 month
  final recentOverdue = board.overdue
      .where((m) => _isWithinLastMonth(m.movementDate))
      .toList();
  if (recentOverdue.isNotEmpty) {
    addBucket(recentOverdue, MovementBucket.overdue);
  }

  // Step 2: Add confirmed
  if (board.confirmed.isNotEmpty) {
    addBucket(board.confirmed, MovementBucket.confirmed);
  }

  // Step 3: Add upcoming
  if (board.upcoming.isNotEmpty) {
    addBucket(board.upcoming, MovementBucket.upcoming);
  }

  final rows = map.values.toList(growable: false);

  int statusPriority(MovementBucket bucket) {
    switch (bucket) {
      case MovementBucket.overdue:
        return 0;
      case MovementBucket.confirmed:
        return 1;
      case MovementBucket.upcoming:
        return 2;
      case MovementBucket.rejected:
        return 3;
    }
  }

  rows.sort((a, b) {
    final priorityA = statusPriority(a.bucket);
    final priorityB = statusPriority(b.bucket);

    if (priorityA != priorityB) {
      return priorityA.compareTo(priorityB);
    }

    // Within same status, sort by date
    if (a.bucket == MovementBucket.overdue ||
        a.bucket == MovementBucket.confirmed) {
      // most recent/latest first (descending)
      return b.movementDate.compareTo(a.movementDate);
    } else {
      // Upcoming: nearest first (ascending)
      return a.movementDate.compareTo(b.movementDate);
    }
  });

  return rows.length <= maxRows ? rows : rows.sublist(0, maxRows);
}

_MovementStudent _studentFrom(IndividualMovement m) => _MovementStudent(
  id: m.id,
  name: m.studentName,
  avatarInitials: m.studentAvatarInitials,
  profilePhotoAssetCode: (m.profilePhotoAssetCode?.trim().isEmpty ?? true)
      ? null
      : m.profilePhotoAssetCode,
  studentCode: m.studentCode,
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
                  onTap: () {
                    Navigator.of(ctx).pop();
                    if (s.studentCode != null && s.studentCode!.isNotEmpty) {
                      context.go(
                        '/dashboard/individual-movement?studentCode=${s.studentCode}',
                      );
                    }
                  },
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

/// Student avatar stack (max 5, overflow indicator).
class _MovementAvatarStack extends StatelessWidget {
  const _MovementAvatarStack({required this.students});

  final List<_MovementStudent> students;

  @override
  Widget build(BuildContext context) {
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
                  key: ValueKey('student_${s.id}'),
                  right: index * 5.0,
                  child: isOverflowSlot
                      ? Container(
                          height: 45,
                          width: 45,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.attendanceEmptyStateIconColor,
                            border: Border.all(
                              color: AppColors.cardColor,
                              width: 2,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '+$overflowCount',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.cardColor,
                            ),
                          ),
                        )
                      : Container(
                          height: 45,
                          width: 45,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.cardColor,
                              width: 2,
                            ),
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
}

/// Small pill badge showing a bucket's label, coloured via
/// [MovementBucketPresentation] — the same mapping the board screen uses.
class _MovementStatusBadge extends StatelessWidget {
  const _MovementStatusBadge({required this.bucket});

  final MovementBucket bucket;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: bucket.badgeBackgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        bucket.label,
        style: TextStyle(
          fontSize: 16,
          color: bucket.badgeColor,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// One summary row: date, status divider, student count/names, avatars.
class _MovementSummaryRow extends StatelessWidget {
  const _MovementSummaryRow({
    required this.month,
    required this.day,
    required this.studentCount,
    required this.from,
    required this.to,
    required this.students,
    required this.bucket,
  });

  final String month;
  final String day;
  final String studentCount;
  final String from;
  final String to;
  final List<_MovementStudent> students;
  final MovementBucket bucket;

  @override
  Widget build(BuildContext context) {
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
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.attendanceDialogHintTextColor,
                    ),
                  ),
                  Text(
                    day,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
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
              color: bucket.badgeColor,
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
                          child: InkWell(
                            onTap: () {
                              final code = students.first.studentCode;
                              if (code != null && code.isNotEmpty) {
                                context.go(
                                  '/dashboard/individual-movement?studentCode=$code',
                                );
                              }
                            },
                            child: Text(
                              'Student 1',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
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
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Students',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(width: 4),
                      _MovementStatusBadge(bucket: bucket),
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
            _MovementAvatarStack(students: students),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _MovementEmptyState extends StatelessWidget {
  const _MovementEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.swap_horiz_rounded,
              size: 36,
              color: AppColors.attendanceEmptyStateIconColor,
            ),
            const SizedBox(height: 8),
            const Text(
              'No movements scheduled',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.attendanceMutedTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MovementsCard extends StatefulWidget {
  const MovementsCard({super.key, this.classroomCode, this.onRedirect});

  /// When set, only movements involving this classroom (from or to) are shown.
  final String? classroomCode;

  /// Override header redirect; defaults to [IndividualMovementScreen].
  final VoidCallback? onRedirect;

  @override
  State<MovementsCard> createState() => _MovementsCardState();
}

class _MovementsCardState extends State<MovementsCard> {
  final ValueNotifier<bool> _minimized = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _minimized.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<IndividualMovementsCubit, IndividualMovementsState>(
      buildWhen: (prev, curr) =>
          prev.board != curr.board || prev.errorMessage != curr.errorMessage,
      builder: (context, state) {
        final isError = state.board == null && state.errorMessage != null;
        return DashboardCardErrorOverlay(
          show: isError,
          onRetry: () => context.read<IndividualMovementsCubit>().refresh(),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.cardBorderColor),
              borderRadius: BorderRadius.circular(12),
              color: AppColors.cardColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: _minimized,
                  builder: (context, minimized, _) => DashboardCardHeader(
                    title: 'Movements',
                    showRedirect: true,
                    onRedirect:
                        widget.onRedirect ??
                        () => context.go(IndividualMovementScreen.routeName),
                    minimized: minimized,
                    onToggle: () => _minimized.value = !_minimized.value,
                  ),
                ),
                const SizedBox(height: 24),
                ValueListenableBuilder<bool>(
                  valueListenable: _minimized,
                  builder: (context, minimized, body) =>
                      DashboardCollapsible(collapsed: minimized, child: body!),
                  child: _MovementCardBody(classroomCode: widget.classroomCode),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MovementCardBody extends StatelessWidget {
  const _MovementCardBody({this.classroomCode});

  final String? classroomCode;

  @override
  Widget build(BuildContext context) {
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
          return const _MovementEmptyState();
        }

        if (state.board != null) {
          final scopedBoard = _filterBoardForClassroom(
            state.board!,
            classroomCode ?? '',
          );
          // Priority filtering and sorting (max 3 items) happen in _filterPriorityMovements.
          final rows = _filterPriorityMovements(scopedBoard);
          if (rows.isEmpty) return const _MovementEmptyState();

          return Column(
            children: rows
                .map(
                  (move) => _MovementSummaryRow(
                    month: move.movementMonth,
                    day: move.movementDay,
                    studentCount: move.students.length.toString(),
                    from: move.currentRoom ?? '',
                    to: move.isLeaving
                        ? 'Leaving the School'
                        : move.nextRoom ?? '',
                    students: move.students,
                    bucket: move.bucket,
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
