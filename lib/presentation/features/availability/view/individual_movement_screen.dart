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
import 'package:wowcare/shared/common/widgets/gradient_add_button.dart';

class IndividualMovementScreen extends StatefulWidget {
  const IndividualMovementScreen({super.key});

  static const String routeName = '/individual-movement';

  @override
  State<IndividualMovementScreen> createState() => _IndividualMovementScreenState();
}

class _IndividualMovementScreenState extends State<IndividualMovementScreen> {
  String? _selectedStudent;
  String? _toClassroom;
  String? _fromClassroom;
  DateTime? _filterRangeStart;
  DateTime? _filterRangeEnd;

  late final PageController _sectionPageController;
  late final IndividualMovementsCubit _individualMovementsCubit;
  int _currentSectionIndex = 0;

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
        'student': _selectedStudent,
        'fromClassroom': _fromClassroom,
        'toClassroom': _toClassroom,
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
        _selectedStudent = json['student'] as String?;
        _fromClassroom = json['fromClassroom'] as String?;
        _toClassroom = json['toClassroom'] as String?;
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
      _selectedStudent = null;
      _toClassroom = null;
      _fromClassroom = null;
      _filterRangeStart = null;
      _filterRangeEnd = null;
    });
    try {
      await serviceLocator<StorageService>().remove(StorageKeys.individualMovementFilters);
    } catch (_) {}
    await _fetchMovements();
  }

  Future<void> _openAddMovementScreen() async {
    final RoleProvider roles = context.read<RoleProvider>();
    if (!_canMutateMovements(roles)) {
      _toastViewOnly(context);
      return;
    }
    final board = _individualMovementsCubit.state.board;
    final students = _uniqueStudents(board);
    final classrooms = _uniqueClassrooms(board);
    final existing = board == null
        ? const <MovementItem>[]
        : board.all.map(MovementItem.fromEntity).toList();

    final MovementFormResult? result = await Navigator.of(context).push<MovementFormResult>(
      MaterialPageRoute(
        builder: (_) => _buildAddEditMovementScreen(
          students: students,
          classrooms: classrooms,
          existingMovements: existing,
        ),
      ),
    );
    if (result == null || !mounted) return;

    final String? error = IndividualMovementValidators.validateMoveToNextClassroomForm(
      student: result.student,
      fromClassroom: result.currentClassroom,
      toClassroom: result.nextClassroom,
      movementDate: result.movementDate,
      existing: existing,
    );
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    try {
      final message = await _individualMovementsCubit.createMovement(
        studentCode: result.student,
        fromClassroomCode: result.currentClassroom,
        toClassroomCode: result.nextClassroom,
        movementDate: result.movementDate,
        comment: result.comment.isEmpty ? null : result.comment,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg.isEmpty ? 'Failed to create movement.' : msg)),
      );
    }
  }

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
        final bool? confirmed = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => ConfirmIndividualMovementScreen(item: item)),
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

    IndividualMovement? movement;
    for (final m in board.all) {
      if (m.id == item.id) {
        movement = m;
        break;
      }
    }

    if (movement == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to find this movement for editing.')),
      );
      return;
    }
    final resolvedMovement = movement;

    final students = _uniqueStudents(board);
    final classrooms = _uniqueClassrooms(board);
    final existing = board.all.map(MovementItem.fromEntity).toList();

    final MovementFormResult? result = await Navigator.of(context).push<MovementFormResult>(
      MaterialPageRoute(
        builder: (_) => AddEditIndividualMovementScreen(
          students: students,
          classrooms: classrooms,
          existingMovements: existing,
          isEditing: true,
          editingMovementId: resolvedMovement.id,
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
        fromClassroomCode: result.currentClassroom,
        toClassroomCode: result.nextClassroom,
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider<IndividualMovementsCubit>.value(
      value: _individualMovementsCubit,
      child: BlocBuilder<IndividualMovementsCubit, IndividualMovementsState>(
        builder: (BuildContext context, IndividualMovementsState state) {
          final sections = _buildSections(state.board);
          final students = _uniqueStudents(state.board);
          final classrooms = _uniqueClassrooms(state.board);

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
                        GradientAddButton(
                          wantedButtonSize: 30,
                          iconSize: 18,
                          borderRadius: 8,
                          onTap: _openAddMovementScreen,
                        ),
                      ],
                    ),
                  ),
                  _buildFilterCard(students: students, classrooms: classrooms),
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
    final studentCodes =
        (_selectedStudent == null || _selectedStudent!.trim().isEmpty) ? null : <String>[_selectedStudent!.trim()];
    final fromClassroomCodes = (_fromClassroom == null || _fromClassroom!.trim().isEmpty)
        ? null
        : <String>[_fromClassroom!.trim()];
    final toClassroomCodes =
        (_toClassroom == null || _toClassroom!.trim().isEmpty) ? null : <String>[_toClassroom!.trim()];

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
  }) {
    final dynamic constructor = IndividualMovementFilterCard.new;
    return Function.apply(constructor, const [], <Symbol, dynamic>{
      #students: students,
      #classrooms: classrooms,
      #selectedStudent: _selectedStudent,
      #toClassroom: _toClassroom,
      #fromClassroom: _fromClassroom,
      #onStudentChanged: (String? value) {
        setState(() => _selectedStudent = value);
        _persistFilters();
        _fetchMovements();
      },
      #onToClassroomChanged: (String? value) {
        setState(() => _toClassroom = value);
        _persistFilters();
        _fetchMovements();
      },
      #onFromClassroomChanged: (String? value) {
        setState(() => _fromClassroom = value);
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

  Widget _buildAddEditMovementScreen({
    required List<String> students,
    required List<String> classrooms,
    required List<MovementItem> existingMovements,
  }) {
    final dynamic constructor = AddEditIndividualMovementScreen.new;
    return Function.apply(constructor, const [], <Symbol, dynamic>{
      #students: students,
      #classrooms: classrooms,
      #existingMovements: existingMovements,
    }) as Widget;
  }
}
