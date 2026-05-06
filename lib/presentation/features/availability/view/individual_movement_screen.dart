import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/fonts.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/availability/entities/individual_movement.dart';
import 'package:wowcare/domain/features/availability/entities/individual_movement_board.dart';
import 'package:wowcare/presentation/features/availability/view/add_edit_individual_movement_screen.dart';
import 'package:wowcare/presentation/features/availability/cubit/individual_movements_cubit.dart';
import 'package:wowcare/presentation/features/availability/view/confirm_individual_movement_screen.dart';
import 'package:wowcare/presentation/features/availability/widgets/individual_movement_bottom_sheet.dart';
import 'package:wowcare/presentation/features/availability/widgets/individual_movement_models.dart';
import 'package:wowcare/presentation/features/availability/widgets/individual_movement_overview.dart';
import 'package:wowcare/presentation/features/availability/widgets/individual_movement_validators.dart';
import 'package:wowcare/shared/common/app/providers/role_provider.dart';
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
  const IndividualMovementScreen({super.key});

  static const String routeName = '/individual-movement';

  @override
  State<IndividualMovementScreen> createState() => _IndividualMovementScreenState();
}

class _IndividualMovementScreenState extends State<IndividualMovementScreen> {
  List<String> _selectedStudents = const <String>[];
  List<String> _toClassrooms = const <String>[];
  List<String> _fromClassrooms = const <String>[];
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
      await _fetchMovements(initialLoad: true);
    });
  }

  @override
  void dispose() {
    _stopEdgeAutoPaging();
    _sectionPageController.dispose();
    _individualMovementsCubit.close();
    super.dispose();
  }

  bool _canMutateMovements(RoleProvider roles) {
    if (roles.isParent) return false;
    if (roles.role == 'staff') {
      return roles.canWriteModule('availability') ||
          roles.canWriteModule('individual_movements');
    }
    return true;
  }

  void _toastViewOnly(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You do not have permission to change movements.')),
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
  //   final RoleProvider roles = context.read<RoleProvider>();
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

  Future<void> _showMovementOptions(MovementItem item) async {
    final RoleProvider roles = context.read<RoleProvider>();
    if (!_canMutateMovements(roles)) {
      _toastViewOnly(context);
      return;
    }
    if (item.workflowStatus == MovementWorkflowStatus.confirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No status transition actions available for confirmed items.')),
      );
      return;
    }
    final action = await showIndividualMovementOptionsBottomSheet(context, item: item);
    if (action == null || !mounted) return;

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
        await _deleteRejectedMovement(item);
        break;
    }
  }

  Future<void> _deleteRejectedMovement(MovementItem item) async {
    final RoleProvider roles = context.read<RoleProvider>();
    if (!_canMutateMovements(roles)) {
      _toastViewOnly(context);
      return;
    }
    if (item.workflowStatus != MovementWorkflowStatus.rejected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only rejected movements can be deleted.')),
      );
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Delete movement'),
          content: const Text('This will delete the rejected movement. Continue?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      final message = await _individualMovementsCubit.deleteMovement(id: item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg.isEmpty ? 'Failed to delete movement.' : msg)),
      );
    }
  }

  Future<void> _openEditMovementScreen(MovementItem item) async {
    final RoleProvider roles = context.read<RoleProvider>();
    if (!_canMutateMovements(roles)) {
      _toastViewOnly(context);
      return;
    }

    final board = _individualMovementsCubit.state.board;
    if (board == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Movements are not loaded yet.')),
      );
      return;
    }

    IndividualMovement resolvedMovement;
    try {
      resolvedMovement = await _individualMovementsCubit.getMovementById(item.id);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg.isEmpty ? 'Failed to load movement details.' : msg),
        ),
      );
      return;
    }

    final students = _uniqueStudents(board);
    final classrooms = _uniqueClassrooms(board);
    final existing = board.all.map(MovementItem.fromEntity).toList();
    final studentNamesByCode = <String, String>{};
    final classroomNamesByCode = <String, String>{};
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg.isEmpty ? 'Failed to update movement.' : msg)),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg.isEmpty ? 'Failed to update movement status.' : msg)),
      );
    }
  }

  Future<String?> _showRejectCommentDialog() async {
    final controller = TextEditingController();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Reject movement'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Comment (optional)'),
            maxLines: 3,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      controller.dispose();
      return null;
    }
    final note = controller.text.trim();
    controller.dispose();
    return note;
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
      _edgeHoldStartedAt = nextDirection == 0 ? null : DateTime.now();
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

  Future<Set<String>> _resolveAllowedClassroomsForStaff(RoleProvider roles) async {
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

  DateTime _dateOnlyNow() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _canDragItem(MovementItem item) {
    // Keep drag actions aligned with allowed status transitions.
    if (item.workflowStatus == MovementWorkflowStatus.confirmed) return false;
    return true;
  }

  Future<void> _handleDropToBucket(
    MovementItem item,
    MovementBucket targetBucket,
  ) async {
    final sourceBucket = item.bucketFor(DateTime.now());
    if (sourceBucket == targetBucket) return;

    if (item.workflowStatus == MovementWorkflowStatus.confirmed) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Confirmed movements cannot be moved.')),
      );
      return;
    }

    if (targetBucket == MovementBucket.confirmed) {
      await _transitionMovementStatus(
        id: item.id,
        status: IndividualMovementWorkflowStatus.confirmed,
        comment: item.comment.isEmpty ? 'Moved to confirmed via drag' : item.comment,
      );
      return;
    }

    if (targetBucket == MovementBucket.rejected) {
      await _transitionMovementStatus(
        id: item.id,
        status: IndividualMovementWorkflowStatus.rejected,
        comment: item.comment.isEmpty ? 'Moved to rejected via drag' : item.comment,
      );
      return;
    }

    // Overdue / Upcoming buckets are pending; choose date by target lane.
    final today = _dateOnlyNow();
    final newDate = targetBucket == MovementBucket.upcoming
        ? today.add(const Duration(days: 1))
        : today.subtract(const Duration(days: 1));

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
          final students = _uniqueStudents(state.board);
          final classrooms = _uniqueClassrooms(state.board);
          final roles = context.watch<RoleProvider>();

          return GlobalScaffold(
            hasBackButton: true,
            showCustomNavigationBar: true,
            body: SingleChildScrollView(
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
                  FutureBuilder<Set<String>>(
                    future: _resolveAllowedClassroomsForStaff(roles),
                    builder: (ctx, snap) {
                      final allowed = snap.data ?? const <String>{};
                      final bool isStaff = roles.role == 'staff';

                      // If staff has allowed classrooms, restrict the available classroom filters.
                      final filteredClassrooms = (!isStaff || allowed.isEmpty)
                          ? classrooms
                          : classrooms.where((c) => allowed.contains(c.trim())).toList();

                      // Student options: for staff, restrict to movements that touch allowed classrooms.
                      // (best-effort based on loaded board)
                      List<String> filteredStudents = students;
                      if (isStaff && allowed.isNotEmpty && state.board != null) {
                        final set = <String>{};
                        for (final m in state.board!.all) {
                          final from = m.fromClassroomCode.trim();
                          final to = m.toClassroomCode.trim();
                          final touches = (from.isNotEmpty && allowed.contains(from)) ||
                              (to.isNotEmpty && allowed.contains(to));
                          if (touches) {
                            final s = m.studentCode.trim();
                            if (s.isNotEmpty) set.add(s);
                          }
                        }
                        filteredStudents = set.toList()..sort();
                      }

                      // Clamp selected filters to allowed sets (prevents persisted stale values).
                      final selectedStudents = isStaff && allowed.isNotEmpty
                          ? _selectedStudents.where((s) => filteredStudents.contains(s)).toList()
                          : _selectedStudents;
                      final froms = isStaff && allowed.isNotEmpty
                          ? _fromClassrooms.where((c) => filteredClassrooms.contains(c)).toList()
                          : _fromClassrooms;
                      final tos = isStaff && allowed.isNotEmpty
                          ? _toClassrooms.where((c) => filteredClassrooms.contains(c)).toList()
                          : _toClassrooms;

                      // Build code->name maps from loaded board to display friendly names in filters.
                      final studentNamesByCode = <String, String>{};
                      final classroomNamesByCode = <String, String>{};
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
                        codes: filteredStudents,
                        nameForCode: studentNameForCode,
                      );
                      final classroomOptions = _buildDisplayOnlyOptions(
                        codes: filteredClassrooms,
                        nameForCode: classroomNameForCode,
                      );

                      final selectedStudentDisplays = selectedStudents
                          .map((c) => studentOptions.codeToDisplay[c.trim()])
                          .whereType<String>()
                          .toList();
                      final selectedFromDisplays = froms
                          .map((c) => classroomOptions.codeToDisplay[c.trim()])
                          .whereType<String>()
                          .toList();
                      final selectedToDisplays = tos
                          .map((c) => classroomOptions.codeToDisplay[c.trim()])
                          .whereType<String>()
                          .toList();

                      if (selectedStudents.length != _selectedStudents.length ||
                          froms.length != _fromClassrooms.length ||
                          tos.length != _toClassrooms.length) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          setState(() {
                            _selectedStudents = selectedStudents;
                            _fromClassrooms = froms;
                            _toClassrooms = tos;
                          });
                          _persistFilters();
                          _fetchMovements();
                        });
                      }

                      return _buildFilterCard(
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
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  if (state.isLoading)
                    const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
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
                      onMoreTap: _showMovementOptions,
                      onDropToBucket: _handleDropToBucket,
                      canDragItem: _canDragItem,
                      onDragStarted: _onCardDragStarted,
                      onDragEnded: _onCardDragEnded,
                      onDragGlobalUpdate: _onCardDragGlobalUpdate,
                    ),
                  const SizedBox(height: 20),
                ],
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
