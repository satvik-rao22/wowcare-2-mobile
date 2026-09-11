import 'dart:async';
import 'package:wowcare/core/router/app_routes.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/domain/features/availability/entities/individual_movement.dart';
import 'package:wowcare/domain/features/availability/entities/individual_movement_board.dart';
import 'package:wowcare/presentation/features/availability/view_model/individual_movements_cubit.dart';
import 'package:wowcare/presentation/features/availability/widgets/individual_movement_bottom_sheet.dart';
import 'package:wowcare/presentation/features/availability/widgets/individual_movement_drag_drop_dialogs.dart';
import 'package:wowcare/presentation/features/availability/model/individual_movement_models.dart';
import 'package:wowcare/presentation/features/availability/widgets/individual_movement_overview.dart';
import 'package:wowcare/presentation/features/availability/widgets/individual_movement_validators.dart';
import 'package:wowcare/presentation/features/students/model/student_sibling_info.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';
import 'package:wowcare/shared/common/widgets/delete_confirmation_bottom_sheet.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';

class IndividualMovementScreen extends StatefulWidget {
  const IndividualMovementScreen({
    super.key,
    this.highlightCode,
    this.studentCode,
  });

  /// Movement id (as string) from a notification deep-link; the matching
  /// movement card scrolls into view and flashes.
  final String? highlightCode;

  /// When set, pre-filters the board to this student code.
  final String? studentCode;

  static const String routeName = DashboardRoutes.individualMovement;

  @override
  State<IndividualMovementScreen> createState() =>
      _IndividualMovementScreenState();
}

class _IndividualMovementScreenState extends State<IndividualMovementScreen> {
  List<String> _selectedStudents = const <String>[];
  List<String> _toClassrooms = const <String>[];
  List<String> _fromClassrooms = const <String>[];
  List<String> _filterStudentCodes = const <String>[];
  List<String> _filterClassroomCodes = const <String>[];
  Map<String, String> _studentNamesByCode = const <String, String>{};
  Map<String, String> _classroomNamesByCode = const <String, String>{};
  DateTime? _filterRangeStart;
  DateTime? _filterRangeEnd;

  late final PageController _sectionPageController;
  late final IndividualMovementsCubit _individualMovementsCubit;
  int _currentSectionIndex = 0;
  // Once we've auto-jumped to the bucket holding the deep-link highlighted
  // movement, don't fight the user's subsequent swipes.
  bool _highlightBucketApplied = false;
  bool _isDraggingCard = false;
  Timer? _edgeAutoPageTimer;
  int _edgeDirection = 0; // -1 left, 1 right, 0 none
  DateTime? _edgeHoldStartedAt;

  @override
  void initState() {
    super.initState();
    _sectionPageController = PageController(viewportFraction: 0.98);
    // Provided by the `individual-movement` GoRoute's BlocProvider — the
    // route owns creation/disposal, this screen only consumes it.
    _individualMovementsCubit = context.read<IndividualMovementsCubit>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadPersistedFilters();
      if (!mounted) return;
      if (widget.studentCode != null && widget.studentCode!.isNotEmpty) {
        setState(() {
          _selectedStudents = [widget.studentCode!];
        });
      }
      // Load movements before heavy student/classroom metadata so the list
      // (and loader) appear immediately instead of an empty board for ~1s+.
      await _fetchMovements(initialLoad: true);
      if (!mounted) return;
      await _loadFilterOptions();
    });
  }

  @override
  void dispose() {
    _stopEdgeAutoPaging();
    _sectionPageController.dispose();
    super.dispose();
  }

  bool _canMutateMovements(RoleCubit roles) {
    if (roles.isParent) return false;
    if (roles.role == 'staff') {
      return roles.canWriteModule('availability') ||
          roles.canWriteModule('individual_movements') ||
          // Backend sometimes sends `INDIVISUAL_MOVEMENTS` (typo) in user-details.
          roles.canWriteModule('indivisual_movements');
    }
    return true;
  }

  void _toastViewOnly(BuildContext context) {
    CoreUtils.showTopSnackBar(
      context: context,
      message: 'You do not have permission to change movements.',
      isWarning: true,
    );
  }

  Future<void> _persistFilters() async {
    await _individualMovementsCubit.persistFilters(
      MovementFilterSnapshot(
        studentCodes: _selectedStudents,
        fromClassroomCodes: _fromClassrooms,
        toClassroomCodes: _toClassrooms,
        rangeStart: _filterRangeStart,
        rangeEnd: _filterRangeEnd,
      ),
    );
  }

  Future<void> _loadPersistedFilters() async {
    final snapshot = await _individualMovementsCubit.loadPersistedFilters();
    if (snapshot == null || !mounted) return;
    setState(() {
      _selectedStudents = snapshot.studentCodes;
      _fromClassrooms = snapshot.fromClassroomCodes;
      _toClassrooms = snapshot.toClassroomCodes;
      _filterRangeStart = snapshot.rangeStart;
      _filterRangeEnd = snapshot.rangeEnd;
    });
  }

  Future<void> _onPullRefreshBuckets() async {
    await _fetchMovements();
    if (!mounted) return;
    // Do not block pull-to-refresh on heavy student/classroom paging; list is the priority.
    unawaited(_loadFilterOptions());
  }

  Future<void> _loadFilterOptions() async {
    final roles = context.read<RoleCubit>();
    try {
      final options = await _individualMovementsCubit.loadFilterOptions(
        isStaffRole: roles.role == 'staff',
      );
      if (!mounted) return;
      setState(() {
        _studentNamesByCode = options.studentNamesByCode;
        _classroomNamesByCode = options.classroomNamesByCode;
        _filterStudentCodes = options.studentCodes;
        _filterClassroomCodes = options.classroomCodes;
        _selectedStudents = _selectedStudents
            .where(options.studentNamesByCode.containsKey)
            .toList();
        _fromClassrooms = _fromClassrooms
            .where(options.classroomNamesByCode.containsKey)
            .toList();
        _toClassrooms = _toClassrooms
            .where(options.classroomNamesByCode.containsKey)
            .toList();
      });
      await _persistFilters();
    } catch (_) {
      // Keep existing board-derived fallback options if API metadata fails.
    }
  }

  List<MovementSection> _buildSections(IndividualMovementBoard? board) {
    MovementSection sectionFor(
      MovementBucket bucket,
      List<IndividualMovement> items,
    ) {
      return MovementSection(
        title: bucket.label,
        backgroundColor: bucket.sectionBackgroundColor,
        bucket: bucket,
        items: items.map(MovementItem.fromEntity).toList(),
      );
    }

    return <MovementSection>[
      sectionFor(MovementBucket.overdue, board?.overdue ?? const []),
      sectionFor(MovementBucket.upcoming, board?.upcoming ?? const []),
      sectionFor(MovementBucket.confirmed, board?.confirmed ?? const []),
      sectionFor(MovementBucket.rejected, board?.rejected ?? const []),
    ];
  }

  /// A movement deep-link highlights a card by its numeric id, but that card may
  /// live in any bucket (Overdue/Upcoming/Confirmed/Rejected) — and the board
  /// opens on Overdue. Find which bucket holds it and swipe there once, so the
  /// highlight flashes without the user having to switch buckets manually.
  void _maybeJumpToHighlightBucket(List<MovementSection> sections) {
    if (_highlightBucketApplied) return;
    final target = (widget.highlightCode ?? '').trim();
    if (target.isEmpty) return;
    final bucketIndex = sections.indexWhere(
      (s) => s.items.any((i) => i.id.toString() == target),
    );
    // Sections still empty (board not loaded yet) — wait for the next build.
    if (bucketIndex < 0) {
      if (sections.every((s) => s.items.isEmpty)) return;
      _highlightBucketApplied = true; // loaded but not found; stop trying.
      return;
    }
    _highlightBucketApplied = true;
    if (bucketIndex == _currentSectionIndex) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_sectionPageController.hasClients) return;
      _sectionPageController.animateToPage(
        bucketIndex,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      setState(() => _currentSectionIndex = bucketIndex);
    });
  }

  Future<void> _clearFilters() async {
    setState(() {
      _selectedStudents = const <String>[];
      _toClassrooms = const <String>[];
      _fromClassrooms = const <String>[];
      _filterRangeStart = null;
      _filterRangeEnd = null;
    });
    await _individualMovementsCubit.clearPersistedFilters();
    await _fetchMovements();
  }

  Future<void> _onMovementAction(
    MovementItem item,
    IndividualMovementAction action,
  ) async {
    final RoleCubit roles = context.read<RoleCubit>();
    if (!_canMutateMovements(roles)) {
      _toastViewOnly(context);
      return;
    }
    switch (action) {
      case IndividualMovementAction.edit:
        await _openEditMovementScreen(item);
        break;
      case IndividualMovementAction.confirm:
        MovementItem? fresh;
        try {
          final movement = await _individualMovementsCubit.getMovementById(
            item.id,
          );
          fresh = MovementItem.fromEntity(movement);
        } catch (_) {
          fresh = null;
        }
        final bool? confirmed = await context.push<bool>(
          '/dashboard/individual-movement/confirm',
          extra: fresh ?? item,
        );
        if (confirmed != true || !mounted) return;
        await _transitionMovementStatus(
          id: item.id,
          status: IndividualMovementWorkflowStatus.confirmed,
          comment: item.comment.isEmpty ? null : item.comment,
        );
        break;
      case IndividualMovementAction.reject:
        final String? rejectNote = await _showRejectCommentDialog(item.name);
        if (rejectNote == null || !mounted) return;
        await _transitionMovementStatus(
          id: item.id,
          status: IndividualMovementWorkflowStatus.rejected,
          comment: rejectNote,
        );
        break;
      case IndividualMovementAction.moveToPending:
        await _transitionMovementStatus(
          id: item.id,
          status: IndividualMovementWorkflowStatus.pending,
          comment: item.comment.isEmpty ? null : item.comment,
          newMovementDate: item.movementDate,
        );
        break;
      case IndividualMovementAction.delete:
        await _deleteMovement(item);
        break;
    }
  }

  Future<void> _deleteMovement(MovementItem item) async {
    final RoleCubit roles = context.read<RoleCubit>();
    if (!_canMutateMovements(roles)) {
      _toastViewOnly(context);
      return;
    }
    if (item.workflowStatus == MovementWorkflowStatus.confirmed) {
      final decision = await showMovementDeleteNotAllowedDialog(
        context,
        movementTitle: item.name,
      );
      if (decision?.confirmed == true) {
        await _transitionMovementStatus(
          id: item.id,
          status: IndividualMovementWorkflowStatus.rejected,
          comment: item.comment.isEmpty
              ? 'Moved to rejected from confirmed via delete flow'
              : item.comment,
        );
      }
      return;
    }
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DeleteConfirmationBottomSheet(
          name: item.name,
          type: 'Activity',
          onDelete: () async {
            Navigator.of(ctx).pop();
            try {
              final message = await _individualMovementsCubit.deleteMovement(
                id: item.id,
              );
              if (!mounted) return;
              CoreUtils.showTopSnackBar(
                context: context,
                message: message,
                isSuccess: true,
              );
            } catch (e) {
              if (!mounted) return;
              final msg = e.toString().replaceFirst('Exception: ', '').trim();
              CoreUtils.logApiError(
                msg.isEmpty ? 'Failed to delete movement.' : msg,
                showOnScreen: true,
                context: context,
              );
            }
          },
          onCancel: () => Navigator.of(ctx).pop(),
        );
      },
    );
  }

  Future<void> _openEditMovementScreen(MovementItem item) async {
    final RoleCubit roles = context.read<RoleCubit>();
    if (!_canMutateMovements(roles)) {
      _toastViewOnly(context);
      return;
    }

    final board = _individualMovementsCubit.state.board;
    if (board == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Movements are not loaded yet.',
        isWarning: true,
      );
      return;
    }

    IndividualMovement resolvedMovement;
    try {
      resolvedMovement = await _individualMovementsCubit.getMovementById(
        item.id,
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      CoreUtils.logApiError(
        msg.isEmpty ? 'Failed to load movement details.' : msg,
        showOnScreen: true,
        context: context,
      );
      return;
    }

    final students = _filterStudentCodes.isNotEmpty
        ? _filterStudentCodes
        : _uniqueStudents(board);
    final classrooms = _filterClassroomCodes.isNotEmpty
        ? _filterClassroomCodes
        : _uniqueClassrooms(board);
    final existing = board.all.map(MovementItem.fromEntity).toList();
    final studentNamesByCode = <String, String>{..._studentNamesByCode};
    final classroomNamesByCode = <String, String>{..._classroomNamesByCode};
    for (final m in board.all) {
      final sCode = m.studentCode.trim();
      final sName = m.studentName.trim();
      if (sCode.isNotEmpty && sName.isNotEmpty) {
        studentNamesByCode[sCode] = sName;
      }
      final fromCode = m.fromClassroomCode.trim();
      final fromName = m.fromClassroomName.trim();
      if (fromCode.isNotEmpty && fromName.isNotEmpty) {
        classroomNamesByCode[fromCode] = fromName;
      }
      final toCode = m.toClassroomCode.trim();
      final toName = m.toClassroomName.trim();
      if (toCode.isNotEmpty && toName.isNotEmpty) {
        classroomNamesByCode[toCode] = toName;
      }
    }

    final editMovementType = movementTypeFromEntity(
      resolvedMovement.movementType,
    );
    final MovementFormResult? result = await context.push<MovementFormResult>(
      '/dashboard/individual-movement/add-edit',
      extra: AddEditMovementArgs(
        students: students,
        classrooms: classrooms,
        existingMovements: existing,
        isEditing: true,
        editingMovementId: resolvedMovement.id,
        disablePastDates: true,
        lockClassroomSelection:
            resolvedMovement.status ==
                IndividualMovementWorkflowStatus.confirmed &&
            resolvedMovement.movementType !=
                IndividualMovementType.moveToNextClassroom,
        movementType: editMovementType,
        studentNamesByCode: studentNamesByCode,
        classroomNamesByCode: classroomNamesByCode,
        initialData: MovementFormResult(
          student: resolvedMovement.studentCode,
          currentClassroom: resolvedMovement.fromClassroomCode,
          nextClassroom: resolvedMovement.toClassroomCode,
          movementDate: resolvedMovement.movementDate,
          comment: resolvedMovement.comment,
        ),
      ),
    );

    if (result == null || !mounted) return;

    final String? error =
        IndividualMovementValidators.validateMoveToNextClassroomForm(
          student: result.student,
          fromClassroom: result.currentClassroom,
          toClassroom: result.nextClassroom,
          movementType: editMovementType,
          movementDate: result.movementDate,
          existing: existing,
          excludeId: resolvedMovement.id,
        );
    if (error != null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: error,
        isWarning: true,
      );
      return;
    }

    try {
      final message = await _individualMovementsCubit.updateMovement(
        id: resolvedMovement.id,
        movementType: resolvedMovement.movementType,
        fromClassroomCode: result.currentClassroom.trim(),
        toClassroomCode: result.nextClassroom.trim(),
        movementDate: result.movementDate,
        comment: result.comment.isEmpty ? null : result.comment,
      );
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: message,
        isSuccess: true,
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      CoreUtils.logApiError(
        msg.isEmpty ? 'Failed to update movement.' : msg,
        showOnScreen: true,
        context: context,
      );
    }
  }

  Future<void> _transitionMovementStatus({
    required int id,
    required IndividualMovementWorkflowStatus status,
    String? comment,
    DateTime? newMovementDate,
  }) async {
    try {
      final message = await _individualMovementsCubit.transitionStatus(
        id: id,
        status: status,
        comment: comment,
        newMovementDate: newMovementDate,
      );
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: message,
        isSuccess: true,
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      CoreUtils.logApiError(
        msg.isEmpty ? 'Failed to update movement status.' : msg,
        showOnScreen: true,
        context: context,
      );
    }
  }

  Future<String?> _showRejectCommentDialog(String movementTitle) async {
    final decision = await showMovementRejectDropDialog(
      context,
      movementTitle: movementTitle,
    );
    if (decision == null || decision.confirmed != true || !mounted) return null;
    return decision.comment.trim();
  }

  void _goToPreviousSection() {
    if (_currentSectionIndex == 0) return;
    _sectionPageController.animateToPage(
      _currentSectionIndex - 1,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
    );
  }

  void _goToNextSection() {
    if (_currentSectionIndex >= MovementBucket.values.length - 1) return;
    _sectionPageController.animateToPage(
      _currentSectionIndex + 1,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
    );
  }

  void _onCardDragStarted() {
    _isDraggingCard = true;
    _edgeDirection = 0;
    _edgeHoldStartedAt = null;
  }

  void _onCardDragEnded() {
    _isDraggingCard = false;
    _edgeDirection = 0;
    _edgeHoldStartedAt = null;
    _stopEdgeAutoPaging();
  }

  void _stopEdgeAutoPaging() {
    _edgeAutoPageTimer?.cancel();
    _edgeAutoPageTimer = null;
  }

  void _startEdgeAutoPaging() {
    if (_edgeAutoPageTimer != null) return;
    _edgeAutoPageTimer = Timer.periodic(const Duration(milliseconds: 460), (_) {
      if (!_isDraggingCard || _edgeDirection == 0) {
        _stopEdgeAutoPaging();
        return;
      }
      if (!_sectionPageController.hasClients) {
        _stopEdgeAutoPaging();
        return;
      }

      final targetIndex = _currentSectionIndex + _edgeDirection;
      if (targetIndex < 0 || targetIndex >= MovementBucket.values.length) {
        // Hit a boundary; stop until user moves to other edge.
        _stopEdgeAutoPaging();
        return;
      }

      _sectionPageController.animateToPage(
        targetIndex,
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _onCardDragGlobalUpdate(Offset globalPosition) {
    if (!_isDraggingCard) return;

    final screenWidth = MediaQuery.of(context).size.width;
    const edgeThreshold = 44.0;
    const edgeDwellMs = 220;

    int nextDirection = 0;
    if (globalPosition.dx <= edgeThreshold) {
      nextDirection = -1;
    } else if (globalPosition.dx >= (screenWidth - edgeThreshold)) {
      nextDirection = 1;
    }

    if (nextDirection != _edgeDirection) {
      _edgeDirection = nextDirection;
      _edgeHoldStartedAt = nextDirection == 0 ? null : AppTime.now();
      _stopEdgeAutoPaging();
      return;
    }

    // Start soft auto paging only after a brief dwell at the same edge.
    if (_edgeDirection != 0 && _edgeAutoPageTimer == null) {
      final holdStart = _edgeHoldStartedAt;
      if (holdStart != null &&
          AppTime.now().difference(holdStart).inMilliseconds >= edgeDwellMs) {
        _startEdgeAutoPaging();
      }
    }
  }

  bool _canDragItem(MovementItem item) {
    final roles = context.read<RoleCubit>();
    return _canMutateMovements(roles);
  }

  Future<void> _onStudentNameTap(MovementItem item) async {
    final studentCode = item.studentCode.trim();
    if (studentCode.isEmpty) return;
    final classroom = item.toClassroom.trim().isNotEmpty
        ? item.toClassroom.trim()
        : item.fromClassroom.trim();
    await context.push(
      '/dashboard/student-profile',
      extra: <String, dynamic>{
        'name': item.name,
        'classroom': classroom,
        'tags': const <String>[],
        'schedule': const <String>[],
        'sibling': const StudentSiblingInfo(),
        'studentCode': studentCode,
      },
    );
  }

  Future<void> _handleDropToBucket(
    MovementItem item,
    MovementBucket targetBucket,
  ) async {
    final RoleCubit roles = context.read<RoleCubit>();
    if (!_canMutateMovements(roles)) {
      _toastViewOnly(context);
      return;
    }
    final sourceBucket = item.bucketFor(AppTime.now());
    if (sourceBucket == targetBucket) return;
    if (sourceBucket == MovementBucket.overdue &&
        targetBucket == MovementBucket.confirmed) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Cannot transition from Overdue to Confirmed.',
        isWarning: true,
      );
      return;
    }

    if (sourceBucket == MovementBucket.overdue &&
        targetBucket == MovementBucket.upcoming) {
      // Backend disallows this transition outright, so skip the date
      // prompt entirely and let the backend's validation error surface.
      await _transitionMovementStatus(
        id: item.id,
        status: IndividualMovementWorkflowStatus.pending,
        comment: item.comment.isEmpty
            ? 'Moved to pending via drag'
            : item.comment,
      );
      return;
    }

    // Confirmed -> Upcoming, Confirmed -> Overdue, Rejected -> Overdue,
    // Rejected -> Confirmed and Upcoming -> Overdue are all invalid
    // transitions on the backend, so skip the confirmation prompt entirely
    // and let the backend's validation error surface instead.
    if ((sourceBucket == MovementBucket.confirmed &&
            (targetBucket == MovementBucket.upcoming ||
                targetBucket == MovementBucket.overdue)) ||
        (sourceBucket == MovementBucket.rejected &&
            (targetBucket == MovementBucket.overdue ||
                targetBucket == MovementBucket.confirmed)) ||
        (sourceBucket == MovementBucket.upcoming &&
            targetBucket == MovementBucket.overdue)) {
      await _transitionMovementStatus(
        id: item.id,
        status: targetBucket == MovementBucket.confirmed
            ? IndividualMovementWorkflowStatus.confirmed
            : IndividualMovementWorkflowStatus.pending,
        comment: item.comment.isEmpty ? 'Moved via drag' : item.comment,
      );
      return;
    }

    if (targetBucket == MovementBucket.confirmed) {
      final confirmDecision = await showMovementConfirmDropDialog(
        context,
        movementTitle: item.name,
      );
      if (confirmDecision == null ||
          confirmDecision.confirmed != true ||
          !mounted) {
        return;
      }

      await _transitionMovementStatus(
        id: item.id,
        status: IndividualMovementWorkflowStatus.confirmed,
        comment: confirmDecision.comment.trim().isNotEmpty
            ? confirmDecision.comment.trim()
            : (item.comment.isEmpty
                  ? 'Moved to confirmed via drag'
                  : item.comment),
      );
      return;
    }

    if (targetBucket == MovementBucket.rejected) {
      final decision = await showMovementRejectDropDialog(
        context,
        movementTitle: item.name,
      );
      if (decision == null || decision.confirmed != true || !mounted) return;

      await _transitionMovementStatus(
        id: item.id,
        status: IndividualMovementWorkflowStatus.rejected,
        comment: decision.comment.trim().isNotEmpty
            ? decision.comment.trim()
            : (item.comment.isEmpty
                  ? 'Moved to rejected via drag'
                  : item.comment),
      );
      return;
    }

    // Only Rejected -> Upcoming reaches here; it requires date confirmation.
    final dateDecision = await showMovementDateDropDialog(
      context,
      title: 'Confirm Date',
      message: 'Select a future date to move this movement to Upcoming.',
      mustBeFuture: true,
    );
    if (dateDecision == null || dateDecision.confirmed != true || !mounted)
      return;
    final newDate = dateDecision.selectedDate;
    if (newDate == null) return;

    await _transitionMovementStatus(
      id: item.id,
      status: IndividualMovementWorkflowStatus.pending,
      comment: item.comment.isEmpty
          ? 'Moved to pending via drag'
          : item.comment,
      newMovementDate: newDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    // The cubit is owned and disposed by the `individual-movement` route's
    // BlocProvider (see app_router.dart) — this widget only listens.
    return BlocBuilder<IndividualMovementsCubit, IndividualMovementsState>(
      bloc: _individualMovementsCubit,
      builder: (BuildContext context, IndividualMovementsState state) {
        final sections = _buildSections(state.board);
        _maybeJumpToHighlightBucket(sections);
        final students = _filterStudentCodes.isNotEmpty
            ? _filterStudentCodes
            : _uniqueStudents(state.board);
        final classrooms = _filterClassroomCodes.isNotEmpty
            ? _filterClassroomCodes
            : _uniqueClassrooms(state.board);
        final roles = context.watch<RoleCubit>();
        final bool isViewOnly = !_canMutateMovements(roles);
        final studentNamesByCode = <String, String>{..._studentNamesByCode};
        final classroomNamesByCode = <String, String>{..._classroomNamesByCode};
        if (state.board != null) {
          for (final m in state.board!.all) {
            final sCode = m.studentCode.trim();
            final sName = m.studentName.trim();
            if (sCode.isNotEmpty && sName.isNotEmpty) {
              studentNamesByCode[sCode] = sName;
            }
            final fromCode = m.fromClassroomCode.trim();
            final fromName = m.fromClassroomName.trim();
            if (fromCode.isNotEmpty && fromName.isNotEmpty) {
              classroomNamesByCode[fromCode] = fromName;
            }
            final toCode = m.toClassroomCode.trim();
            final toName = m.toClassroomName.trim();
            if (toCode.isNotEmpty && toName.isNotEmpty) {
              classroomNamesByCode[toCode] = toName;
            }
          }
        }

        String studentNameForCode(String code) =>
            (studentNamesByCode[code.trim()] ?? '').trim();
        String classroomNameForCode(String code) =>
            (classroomNamesByCode[code.trim()] ?? '').trim();

        final studentOptions = buildDisplayOnlyOptions(
          codes: students,
          nameForCode: studentNameForCode,
        );
        final classroomOptions = buildDisplayOnlyOptions(
          codes: classrooms,
          nameForCode: classroomNameForCode,
        );

        final selectedStudentDisplays = _selectedStudents
            .map((c) => studentOptions.codeToDisplay[c.trim()])
            .whereType<String>()
            .toList();
        final selectedFromDisplays = _fromClassrooms
            .map((c) => classroomOptions.codeToDisplay[c.trim()])
            .whereType<String>()
            .toList();
        final selectedToDisplays = _toClassrooms
            .map((c) => classroomOptions.codeToDisplay[c.trim()])
            .whereType<String>()
            .toList();

        return GlobalScaffold(
          hasBackButton: false,
          showCustomNavigationBar: true,
          body: CustomRefreshIndicator(
            displacement: 28,
            onRefresh: _onPullRefreshBuckets,
            // The heading and filters stay pinned and the visible bucket's own
            // list is the only vertical scrollable on the screen. This used to
            // be a page-wide SingleChildScrollView wrapping a pager of fixed
            // estimated height, each of whose cards had a ListView of its own —
            // two nested scrollables competing for every drag, so a bucket
            // taller than the estimate could neither be scrolled to its last
            // card nor scrolled back up.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: <Widget>[
                      const Expanded(
                        child: Text(
                          'Overview',
                          style: AppTextStyles.movementSectionHeading,
                        ),
                      ),
                    ],
                  ),
                ),
                IndividualMovementFilterCard(
                  students: studentOptions.items,
                  classrooms: classroomOptions.items,
                  selectedStudents: selectedStudentDisplays,
                  fromClassrooms: selectedFromDisplays,
                  toClassrooms: selectedToDisplays,
                  filterRangeStart: _filterRangeStart,
                  filterRangeEnd: _filterRangeEnd,
                  onStudentsChanged: (List<String> displays) {
                    final codes = displays
                        .map((d) => studentOptions.displayToCode[d.trim()])
                        .whereType<String>()
                        .toList();
                    setState(() => _selectedStudents = codes);
                    _persistFilters();
                    _fetchMovements();
                  },
                  onFromClassroomsChanged: (List<String> displays) {
                    final codes = displays
                        .map((d) => classroomOptions.displayToCode[d.trim()])
                        .whereType<String>()
                        .toList();
                    setState(() => _fromClassrooms = codes);
                    _persistFilters();
                    _fetchMovements();
                  },
                  onToClassroomsChanged: (List<String> displays) {
                    final codes = displays
                        .map((d) => classroomOptions.displayToCode[d.trim()])
                        .whereType<String>()
                        .toList();
                    setState(() => _toClassrooms = codes);
                    _persistFilters();
                    _fetchMovements();
                  },
                  onDateRangeChanged: (DateTime? start, DateTime? end) {
                    setState(() {
                      _filterRangeStart = start;
                      _filterRangeEnd = end;
                    });
                    _persistFilters();
                    _fetchMovements();
                  },
                  onClearAll: _clearFilters,
                ),
                const SizedBox(height: 12),
                // The board takes every pixel left below the filters, so the
                // bucket the user is looking at scrolls against a viewport that
                // is actually on screen instead of one sized from a row-count
                // guess.
                Expanded(
                  child: state.isLoading
                      ? const _BoardPlaceholder(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: PrimaryCircularLoader(),
                          ),
                        )
                      : (state.errorMessage != null && state.board == null)
                      ? _BoardPlaceholder(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 18,
                            ),
                            child: Text(
                              state.errorMessage!,
                              style: AppTextStyles.movementErrorText,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : IndividualMovementPager(
                          sections: sections,
                          currentSectionIndex: _currentSectionIndex,
                          sectionPageController: _sectionPageController,
                          onPageChanged: (int index) =>
                              setState(() => _currentSectionIndex = index),
                          onPrevious: _goToPreviousSection,
                          onNext: _goToNextSection,
                          onActionSelected: _onMovementAction,
                          onDropToBucket: _handleDropToBucket,
                          isViewOnly: isViewOnly,
                          canDragItem: _canDragItem,
                          onDragStarted: _onCardDragStarted,
                          onDragEnded: _onCardDragEnded,
                          onDragGlobalUpdate: _onCardDragGlobalUpdate,
                          highlightCode: widget.highlightCode,
                          onStudentNameTap: _onStudentNameTap,
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _fetchMovements({bool initialLoad = false}) async {
    final studentCodes = _selectedStudents.isEmpty ? null : _selectedStudents;
    final fromClassroomCodes = _fromClassrooms.isEmpty ? null : _fromClassrooms;
    final toClassroomCodes = _toClassrooms.isEmpty ? null : _toClassrooms;

    if (initialLoad) {
      await _individualMovementsCubit.loadInitial(
        studentCodes: studentCodes,
        fromClassroomCodes: fromClassroomCodes,
        toClassroomCodes: toClassroomCodes,
        dateFrom: _filterRangeStart,
        dateTo: _filterRangeEnd,
      );
      return;
    }
    await _individualMovementsCubit.refresh(
      studentCodes: studentCodes,
      fromClassroomCodes: fromClassroomCodes,
      toClassroomCodes: toClassroomCodes,
      dateFrom: _filterRangeStart,
      dateTo: _filterRangeEnd,
    );
  }

  List<String> _uniqueStudents(IndividualMovementBoard? board) {
    if (board == null) return const <String>[];
    final values =
        board.all
            .map((e) => e.studentCode.trim())
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return values;
  }

  List<String> _uniqueClassrooms(IndividualMovementBoard? board) {
    if (board == null) return const <String>[];
    final values = <String>{};
    for (final movement in board.all) {
      final from = movement.fromClassroomCode.trim();
      final to = movement.toClassroomCode.trim();
      if (from.isNotEmpty) values.add(from);
      if (to.isNotEmpty) values.add(to);
    }
    final list = values.toList()..sort();
    return list;
  }
}

/// Centers the loader / error message in the board's slot while staying a
/// scrollable, so pull-to-refresh still works when there is no bucket list to
/// overscroll.
class _BoardPlaceholder extends StatelessWidget {
  const _BoardPlaceholder({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: child),
          ),
        );
      },
    );
  }
}
