import 'dart:async';
import 'package:wowcare/core/util/app_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/fonts.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/availability/entities/individual_movement.dart';
import 'package:wowcare/domain/features/availability/entities/individual_movement_board.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import 'package:wowcare/domain/features/student/entities/student.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_page_usecase.dart';
import 'package:wowcare/presentation/features/availability/view/add_edit_individual_movement_screen.dart';
import 'package:wowcare/presentation/features/availability/cubit/individual_movements_cubit.dart';
import 'package:wowcare/presentation/features/availability/view/confirm_individual_movement_screen.dart';
import 'package:wowcare/presentation/features/availability/widgets/individual_movement_bottom_sheet.dart';
import 'package:wowcare/presentation/features/availability/widgets/individual_movement_drag_drop_dialogs.dart';
import 'package:wowcare/presentation/features/availability/widgets/individual_movement_models.dart';
import 'package:wowcare/presentation/features/availability/widgets/individual_movement_overview.dart';
import 'package:wowcare/presentation/features/availability/widgets/individual_movement_validators.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'package:wowcare/shared/common/widgets/delete_confirmation_bottom_sheet.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
// import 'package:wowcare/shared/common/widgets/gradient_add_button.dart';
import 'dart:convert';

MovementType _movementTypeFromEntity(IndividualMovementType type) {
  switch (type) {
    case IndividualMovementType.startSchool:
      return MovementType.startSchool;
    case IndividualMovementType.leaveSchool:
      return MovementType.leaveSchool;
    case IndividualMovementType.moveToNextClassroom:
      return MovementType.moveToNextClassroom;
  }
}

class IndividualMovementScreen extends StatefulWidget {
  const IndividualMovementScreen({super.key, this.highlightCode});

  /// Movement id (as string) from a notification deep-link; the matching
  /// movement card scrolls into view and flashes.
  final String? highlightCode;

  static const String routeName = '/dashboard/individual-movement';

  @override
  State<IndividualMovementScreen> createState() => _IndividualMovementScreenState();
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

  ({
    List<String> items,
    Map<String, String> displayToCode,
    Map<String, String> codeToDisplay,
  }) _buildDisplayOnlyOptions({
    required List<String> codes,
    required String Function(String code) nameForCode,
  }) {
    final counts = <String, int>{};
    final items = <String>[];
    final displayToCode = <String, String>{};
    final codeToDisplay = <String, String>{};

    for (final codeRaw in codes) {
      final code = codeRaw.trim();
      if (code.isEmpty) continue;
      final baseName = nameForCode(code).trim();
      final name = baseName.isNotEmpty ? baseName : code;

      final next = (counts[name] ?? 0) + 1;
      counts[name] = next;

      final display = next == 1 ? name : '$name ($next)';
      items.add(display);
      displayToCode[display] = code;
      codeToDisplay[code] = display;
    }

    return (
      items: items,
      displayToCode: displayToCode,
      codeToDisplay: codeToDisplay,
    );
  }

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
    _individualMovementsCubit = serviceLocator<IndividualMovementsCubit>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadPersistedFilters();
      if (!mounted) return;
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
    _individualMovementsCubit.close();
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
    try {
      final StorageService storage = serviceLocator<StorageService>();
      final Map<String, dynamic> map = <String, dynamic>{
        'students': _selectedStudents,
        'fromClassrooms': _fromClassrooms,
        'toClassrooms': _toClassrooms,
      };
      if (_filterRangeStart != null) {
        map['rangeStartMs'] = _filterRangeStart!.millisecondsSinceEpoch;
      }
      if (_filterRangeEnd != null) {
        map['rangeEndMs'] = _filterRangeEnd!.millisecondsSinceEpoch;
      }
      await storage.saveJson(StorageKeys.individualMovementFilters, map);
    } catch (_) {}
  }

  Future<void> _loadPersistedFilters() async {
    try {
      final StorageService storage = serviceLocator<StorageService>();
      final Map<String, dynamic>? json =
          await storage.getJson(StorageKeys.individualMovementFilters);
      if (json == null || !mounted) return;
      setState(() {
        final students = json['students'];
        final froms = json['fromClassrooms'];
        final tos = json['toClassrooms'];
        _selectedStudents =
            (students is List ? students.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList() : const <String>[]);
        _fromClassrooms =
            (froms is List ? froms.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList() : const <String>[]);
        _toClassrooms =
            (tos is List ? tos.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList() : const <String>[]);
        final int? s = (json['rangeStartMs'] as num?)?.toInt();
        final int? e = (json['rangeEndMs'] as num?)?.toInt();
        _filterRangeStart = s != null ? DateTime.fromMillisecondsSinceEpoch(s) : null;
        _filterRangeEnd = e != null ? DateTime.fromMillisecondsSinceEpoch(e) : null;
      });
    } catch (_) {}
  }

  Future<String> _resolveSchoolCode() async {
    final storage = serviceLocator<StorageService>();
    final stored = (await storage.getString(StorageKeys.schoolCode) ?? '').trim();
    if (stored.isNotEmpty && stored != '-') return stored;
    return '';
  }

  Future<void> _onPullRefreshBuckets() async {
    await _fetchMovements();
    if (!mounted) return;
    // Do not block pull-to-refresh on heavy student/classroom paging; list is the priority.
    unawaited(_loadFilterOptions());
  }

  Future<void> _loadFilterOptions() async {
    final schoolCode = await _resolveSchoolCode();
    if (schoolCode.isEmpty || !mounted) return;
    final roles = context.read<RoleCubit>();
    final allowedClassrooms = await _resolveAllowedClassroomsForStaff(roles);

    final getStudents = serviceLocator<GetStudentPageUseCase>();
    final getClassrooms = serviceLocator<GetActiveClassroomsUseCase>();

    Future<List<Student>> fetchStudentsByStatus(String status) async {
      final out = <Student>[];
      var page = 0;
      const size = 200;
      while (true) {
        final res = await getStudents(
          schoolCode: schoolCode,
          status: status,
          classroomCodes: allowedClassrooms.isNotEmpty ? allowedClassrooms.toList() : null,
          page: page,
          size: size,
        );
        out.addAll(res.items);
        if (!res.hasMore || page >= (res.totalPages - 1)) break;
        page += 1;
      }
      return out;
    }

    try {
      final activeStudents = await fetchStudentsByStatus('ACTIVE');
      final upcomingStudents = await fetchStudentsByStatus('UPCOMING');
      final allStudents = [...activeStudents, ...upcomingStudents];
      final studentNamesByCode = <String, String>{};
      for (final s in allStudents) {
        final code = s.code.trim();
        if (code.isEmpty) continue;
        final full = '${s.firstName.trim()} ${s.lastName.trim()}'.trim();
        studentNamesByCode[code] = full.isNotEmpty ? full : code;
      }

      final classroomsRaw = await getClassrooms(
        schoolCode: schoolCode,
        onlyTypeClassroom: true,
      );
      final classroomNamesByCode = <String, String>{};
      for (final c in classroomsRaw) {
        final code = c.code.trim();
        if (code.isEmpty) continue;
        if (allowedClassrooms.isNotEmpty && !allowedClassrooms.contains(code)) continue;
        final name = c.name.trim();
        classroomNamesByCode[code] = name.isNotEmpty ? name : code;
      }

      if (!mounted) return;
      setState(() {
        _studentNamesByCode = studentNamesByCode;
        _classroomNamesByCode = classroomNamesByCode;
        _filterStudentCodes = studentNamesByCode.keys.toList()
          ..sort((a, b) => (studentNamesByCode[a] ?? a)
              .toLowerCase()
              .compareTo((studentNamesByCode[b] ?? b).toLowerCase()));
        _filterClassroomCodes = classroomNamesByCode.keys.toList()
          ..sort((a, b) => (classroomNamesByCode[a] ?? a)
              .toLowerCase()
              .compareTo((classroomNamesByCode[b] ?? b).toLowerCase()));

        _selectedStudents = _selectedStudents.where(studentNamesByCode.containsKey).toList();
        _fromClassrooms = _fromClassrooms.where(classroomNamesByCode.containsKey).toList();
        _toClassrooms = _toClassrooms.where(classroomNamesByCode.containsKey).toList();
      });
      await _persistFilters();
    } catch (_) {
      // Keep existing board-derived fallback options if API metadata fails.
    }
  }

  List<MovementSection> _buildSections(IndividualMovementBoard? board) {
    return <MovementSection>[
      MovementSection(
        title: 'Overdue',
        backgroundColor: const Color(0xFFF8F6FF),
        bucket: MovementBucket.overdue,
        items: (board?.overdue ?? const []).map(MovementItem.fromEntity).toList(),
      ),
      MovementSection(
        title: 'Upcoming',
        backgroundColor: const Color(0xFFFFFBEE),
        bucket: MovementBucket.upcoming,
        items: (board?.upcoming ?? const []).map(MovementItem.fromEntity).toList(),
      ),
      MovementSection(
        title: 'Confirmed',
        backgroundColor: const Color(0xFFEFFFF4),
        bucket: MovementBucket.confirmed,
        items: (board?.confirmed ?? const []).map(MovementItem.fromEntity).toList(),
      ),
      MovementSection(
        title: 'Rejected',
        backgroundColor: const Color(0xFFFFF0F0),
        bucket: MovementBucket.rejected,
        items: (board?.rejected ?? const []).map(MovementItem.fromEntity).toList(),
      ),
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
    try {
      await serviceLocator<StorageService>().remove(StorageKeys.individualMovementFilters);
    } catch (_) {}
    await _fetchMovements();
  }

  // Temporarily disabled: add movement flow is not needed right now.
  // Future<void> _openAddMovementScreen() async {
  //   final RoleCubit roles = context.read<RoleCubit>();
  //   if (!_canMutateMovements(roles)) {
  //     _toastViewOnly(context);
  //     return;
  //   }
  //   final board = _individualMovementsCubit.state.board;
  //   final students = _uniqueStudents(board);
  //   final classrooms = _uniqueClassrooms(board);
  //   final existing = board == null
  //       ? const <MovementItem>[]
  //       : board.all.map(MovementItem.fromEntity).toList();
  //
  //   final MovementFormResult? result = await Navigator.of(context).push<MovementFormResult>(
  //     MaterialPageRoute(
  //       builder: (_) => _buildAddEditMovementScreen(
  //         students: students,
  //         classrooms: classrooms,
  //         existingMovements: existing,
  //       ),
  //     ),
  //   );
  //   if (result == null || !mounted) return;
  //
  //   final String? error = IndividualMovementValidators.validateMoveToNextClassroomForm(
  //     student: result.student,
  //     fromClassroom: result.currentClassroom,
  //     toClassroom: result.nextClassroom,
  //     movementDate: result.movementDate,
  //     existing: existing,
  //   );
  //   if (error != null) {
  //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  //     return;
  //   }
  //
  //   try {
  //     final message = await _individualMovementsCubit.createMovement(
  //       studentCode: result.student,
  //       fromClassroomCode: result.currentClassroom,
  //       toClassroomCode: result.nextClassroom,
  //       movementDate: result.movementDate,
  //       comment: result.comment.isEmpty ? null : result.comment,
  //     );
  //     if (!mounted) return;
  //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  //   } catch (e) {
  //     if (!mounted) return;
  //     final msg = e.toString().replaceFirst('Exception: ', '').trim();
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text(msg.isEmpty ? 'Failed to create movement.' : msg)),
  //     );
  //   }
  // }

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
          final movement = await _individualMovementsCubit.getMovementById(item.id);
          fresh = MovementItem.fromEntity(movement);
        } catch (_) {
          fresh = null;
        }
        final bool? confirmed = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => ConfirmIndividualMovementScreen(item: fresh ?? item),
          ),
        );
        if (confirmed != true || !mounted) return;
        await _transitionMovementStatus(
          id: item.id,
          status: IndividualMovementWorkflowStatus.confirmed,
          comment: item.comment.isEmpty ? null : item.comment,
        );
        break;
      case IndividualMovementAction.reject:
        final String? rejectNote = await _showRejectCommentDialog();
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
              final message = await _individualMovementsCubit.deleteMovement(id: item.id);
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
      resolvedMovement = await _individualMovementsCubit.getMovementById(item.id);
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

    final students = _filterStudentCodes.isNotEmpty ? _filterStudentCodes : _uniqueStudents(board);
    final classrooms =
        _filterClassroomCodes.isNotEmpty ? _filterClassroomCodes : _uniqueClassrooms(board);
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

    final MovementFormResult? result = await Navigator.of(context).push<MovementFormResult>(
      MaterialPageRoute(
        builder: (_) => AddEditIndividualMovementScreen(
          students: students,
          classrooms: classrooms,
          existingMovements: existing,
          isEditing: true,
          editingMovementId: resolvedMovement.id,
          disablePastDates: true,
          lockClassroomSelection:
              resolvedMovement.status == IndividualMovementWorkflowStatus.confirmed &&
                  resolvedMovement.movementType !=
                      IndividualMovementType.moveToNextClassroom,
          movementType: _movementTypeFromEntity(resolvedMovement.movementType),
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
      ),
    );

    if (result == null || !mounted) return;

    final String? error = IndividualMovementValidators.validateMoveToNextClassroomForm(
      student: result.student,
      fromClassroom: result.currentClassroom,
      toClassroom: result.nextClassroom,
      movementType: _movementTypeFromEntity(resolvedMovement.movementType),
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

  Future<String?> _showRejectCommentDialog() async {
    final decision = await showMovementRejectDropDialog(
      context,
      movementTitle: '',
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
    _edgeAutoPageTimer = Timer.periodic(
      const Duration(milliseconds: 460),
      (_) {
        if (!_isDraggingCard || _edgeDirection == 0) {
          _stopEdgeAutoPaging();
          return;
        }
        if (!_sectionPageController.hasClients) {
          _stopEdgeAutoPaging();
          return;
        }

        final targetIndex = _currentSectionIndex + _edgeDirection;
        if (targetIndex < 0 ||
            targetIndex >= MovementBucket.values.length) {
          // Hit a boundary; stop until user moves to other edge.
          _stopEdgeAutoPaging();
          return;
        }

        _sectionPageController.animateToPage(
          targetIndex,
          duration: const Duration(milliseconds: 340),
          curve: Curves.easeInOutCubic,
        );
      },
    );
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
          DateTime.now().difference(holdStart).inMilliseconds >= edgeDwellMs) {
        _startEdgeAutoPaging();
      }
    }
  }

  Future<Set<String>> _resolveAllowedClassroomsForStaff(RoleCubit roles) async {
    if (roles.role != 'staff') return const <String>{};
    try {
      final storage = serviceLocator<StorageService>();
      final raw =
          (await storage.getString(StorageKeys.staffAllowedClassroomCodes) ?? '')
              .trim();
      if (raw.isEmpty) return const <String>{};
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toSet();
      }
    } catch (_) {}
    return const <String>{};
  }

  bool _canDragItem(MovementItem item) {
    final roles = context.read<RoleCubit>();
    return _canMutateMovements(roles);
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

    if (targetBucket == MovementBucket.confirmed) {
      DateTime? newDate;
      if (sourceBucket == MovementBucket.rejected) {
        final dateDecision = await showMovementDateDropDialog(
          context,
          title: 'Revalidate Date',
          message:
              'Please select a future date before moving this rejected movement to Confirmed.',
          mustBeFuture: true,
        );
        if (dateDecision == null ||
            dateDecision.confirmed != true ||
            !mounted) {
          return;
        }
        newDate = dateDecision.selectedDate;
        if (newDate == null) return;
      }

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
            : (item.comment.isEmpty ? 'Moved to confirmed via drag' : item.comment),
        newMovementDate: newDate,
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
            : (item.comment.isEmpty ? 'Moved to rejected via drag' : item.comment),
      );
      return;
    }

    // Dragging to Upcoming or Overdue requires date confirmation.
    final dateDecision = await showMovementDateDropDialog(
      context,
      title: 'Confirm Date',
      message: targetBucket == MovementBucket.upcoming
          ? 'Select a future date to move this movement to Upcoming.'
          : 'Select a past date to move this movement to Overdue.',
      mustBeFuture: targetBucket == MovementBucket.upcoming,
    );
    if (dateDecision == null || dateDecision.confirmed != true || !mounted) return;
    final newDate = dateDecision.selectedDate;
    if (newDate == null) return;

    await _transitionMovementStatus(
      id: item.id,
      status: IndividualMovementWorkflowStatus.pending,
      comment: item.comment.isEmpty ? 'Moved to pending via drag' : item.comment,
      newMovementDate: newDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<IndividualMovementsCubit>.value(
      value: _individualMovementsCubit,
      child: BlocBuilder<IndividualMovementsCubit, IndividualMovementsState>(
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

          final studentOptions = _buildDisplayOnlyOptions(
            codes: students,
            nameForCode: studentNameForCode,
          );
          final classroomOptions = _buildDisplayOnlyOptions(
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
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                              style: TextStyle(
                                fontFamily: Fonts.manrope,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                          // Temporarily disabled: add movement flow is not needed.
                          // GradientAddButton(
                          //   wantedButtonSize: 30,
                          //   iconSize: 18,
                          //   borderRadius: 8,
                          //   onTap: _openAddMovementScreen,
                          // ),
                        ],
                      ),
                    ),
                    _buildFilterCard(
                      students: studentOptions.items,
                      classrooms: classroomOptions.items,
                      selectedStudents: selectedStudentDisplays,
                      fromClassrooms: selectedFromDisplays,
                      toClassrooms: selectedToDisplays,
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
                    ),
                    const SizedBox(height: 12),
                    if (state.isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: PrimaryCircularLoader(),
                        ),
                      )
                    else if (state.errorMessage != null && state.board == null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        child: Center(
                          child: Text(
                            state.errorMessage!,
                            style: const TextStyle(
                              fontFamily: Fonts.manrope,
                              fontSize: 14,
                              color: AppColors.primaryColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      IndividualMovementPager(
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
                      ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        },
      ),
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
    final values = board.all.map((e) => e.studentCode.trim()).where((e) => e.isNotEmpty).toSet().toList()..sort();
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

  Widget _buildFilterCard({
    required List<String> students,
    required List<String> classrooms,
    required List<String> selectedStudents,
    required List<String> fromClassrooms,
    required List<String> toClassrooms,
    ValueChanged<List<String>>? onStudentsChanged,
    ValueChanged<List<String>>? onFromClassroomsChanged,
    ValueChanged<List<String>>? onToClassroomsChanged,
  }) {
    final dynamic constructor = IndividualMovementFilterCard.new;
    return Function.apply(constructor, const [], <Symbol, dynamic>{
      #students: students,
      #classrooms: classrooms,
      #selectedStudents: selectedStudents,
      #toClassrooms: toClassrooms,
      #fromClassrooms: fromClassrooms,
      #onStudentsChanged: onStudentsChanged ??
          (List<String> values) {
            setState(() => _selectedStudents = values);
            _persistFilters();
            _fetchMovements();
          },
      #onToClassroomsChanged: onToClassroomsChanged ??
          (List<String> values) {
            setState(() => _toClassrooms = values);
            _persistFilters();
            _fetchMovements();
          },
      #onFromClassroomsChanged: onFromClassroomsChanged ??
          (List<String> values) {
            setState(() => _fromClassrooms = values);
            _persistFilters();
            _fetchMovements();
          },
      #onDateRangeChanged: (DateTime? start, DateTime? end) {
        setState(() {
          _filterRangeStart = start;
          _filterRangeEnd = end;
        });
        _persistFilters();
        _fetchMovements();
      },
      #onClearAll: _clearFilters,
      #filterRangeStart: _filterRangeStart,
      #filterRangeEnd: _filterRangeEnd,
    }) as Widget;
  }

  // Temporarily disabled with add movement flow.
  // Widget _buildAddEditMovementScreen({
  //   required List<String> students,
  //   required List<String> classrooms,
  //   required List<MovementItem> existingMovements,
  // }) {
  //   final dynamic constructor = AddEditIndividualMovementScreen.new;
  //   return Function.apply(constructor, const [], <Symbol, dynamic>{
  //     #students: students,
  //     #classrooms: classrooms,
  //     #existingMovements: existingMovements,
  //   }) as Widget;
  // }
}
