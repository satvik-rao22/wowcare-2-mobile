import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/fonts.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/presentation/features/availability/view/add_edit_individual_movement_screen.dart';
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
  int _currentSectionIndex = 0;
  late final List<MovementItem> _allMovements;

  final List<String> _students = const <String>[
    'Arvind Joshi',
    'Chaitanya Bhave',
    'Kimberly Dixon',
    'Aria KC',
    'Devi Vampati',
  ];

  final List<String> _classrooms = const <String>[
    '1-Blue D',
    '2-Green D',
    '3-Purple D',
    '4-Yellow D',
  ];

  @override
  void initState() {
    super.initState();
    _sectionPageController = PageController(viewportFraction: 0.98);

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime yesterday = today.subtract(const Duration(days: 1));
    final DateTime tomorrow = today.add(const Duration(days: 1));

    _allMovements = <MovementItem>[
      MovementItem(
        id: 1,
        name: 'Arvind Joshi',
        fromClassroom: '1-Blue D',
        toClassroom: '2-Green D',
        movementDate: yesterday,
        workflowStatus: MovementWorkflowStatus.pending,
      ),
      MovementItem(
        id: 2,
        name: 'Chaitanya Bhave',
        fromClassroom: '1-Blue D',
        toClassroom: '2-Green D',
        movementDate: yesterday,
        workflowStatus: MovementWorkflowStatus.pending,
      ),
      MovementItem(
        id: 3,
        name: 'Kimberly Dixon',
        fromClassroom: '1-Blue D',
        toClassroom: '2-Green D',
        movementDate: tomorrow,
        workflowStatus: MovementWorkflowStatus.pending,
      ),
      MovementItem(
        id: 4,
        name: 'Aria KC',
        fromClassroom: '1-Blue D',
        toClassroom: '2-Green D',
        movementDate: tomorrow,
        workflowStatus: MovementWorkflowStatus.pending,
      ),
      MovementItem(
        id: 5,
        name: 'Devi Vampati',
        fromClassroom: '1-Blue D',
        toClassroom: '2-Green D',
        movementDate: tomorrow,
        workflowStatus: MovementWorkflowStatus.pending,
      ),
      MovementItem(
        id: 6,
        name: 'Nichole Adams',
        fromClassroom: '1-Blue D',
        toClassroom: '2-Green D',
        movementDate: yesterday,
        workflowStatus: MovementWorkflowStatus.confirmed,
      ),
      MovementItem(
        id: 7,
        name: 'Brindar Goraya',
        fromClassroom: '1-Blue D',
        toClassroom: '2-Green D',
        movementDate: tomorrow,
        workflowStatus: MovementWorkflowStatus.confirmed,
      ),
      MovementItem(
        id: 8,
        name: 'Jessica Lima',
        fromClassroom: '1-Blue D',
        toClassroom: '2-Green D',
        movementDate: tomorrow,
        workflowStatus: MovementWorkflowStatus.confirmed,
      ),
      MovementItem(
        id: 9,
        name: 'Atraye Rawal',
        fromClassroom: '1-Blue D',
        toClassroom: '2-Green D',
        movementDate: yesterday,
        workflowStatus: MovementWorkflowStatus.rejected,
      ),
      MovementItem(
        id: 10,
        name: 'Aparna Bhiwakar',
        fromClassroom: '1-Blue D',
        toClassroom: '2-Green D',
        movementDate: tomorrow,
        workflowStatus: MovementWorkflowStatus.rejected,
      ),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPersistedFilters());
  }

  @override
  void dispose() {
    _sectionPageController.dispose();
    super.dispose();
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

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

  List<MovementItem> _filteredMovements() {
    final DateTime? rs = _filterRangeStart != null ? _dateOnly(_filterRangeStart!) : null;
    final DateTime? re = _filterRangeEnd != null ? _dateOnly(_filterRangeEnd!) : null;

    return _allMovements.where((MovementItem m) {
      if (_selectedStudent != null && _selectedStudent!.trim().isNotEmpty) {
        if (m.name != _selectedStudent) return false;
      }
      if (_fromClassroom != null && _fromClassroom!.trim().isNotEmpty) {
        if (m.fromClassroom != _fromClassroom) return false;
      }
      if (_toClassroom != null && _toClassroom!.trim().isNotEmpty) {
        if (m.toClassroom != _toClassroom) return false;
      }
      if (rs != null && re != null) {
        final DateTime d = _dateOnly(m.movementDate);
        if (d.isBefore(rs) || d.isAfter(re)) return false;
      }
      return true;
    }).toList();
  }

  List<MovementSection> _buildSections() {
    final DateTime now = DateTime.now();
    final List<MovementItem> base = _filteredMovements();

    List<MovementItem> inBucket(MovementBucket bucket) {
      return base.where((MovementItem e) => e.bucketFor(now) == bucket).toList();
    }

    return <MovementSection>[
      MovementSection(
        title: 'Overdue',
        backgroundColor: const Color(0xFFF8F6FF),
        bucket: MovementBucket.overdue,
        items: inBucket(MovementBucket.overdue),
      ),
      MovementSection(
        title: 'Upcoming',
        backgroundColor: const Color(0xFFFFFBEE),
        bucket: MovementBucket.upcoming,
        items: inBucket(MovementBucket.upcoming),
      ),
      MovementSection(
        title: 'Confirmed',
        backgroundColor: const Color(0xFFEFFFF4),
        bucket: MovementBucket.confirmed,
        items: inBucket(MovementBucket.confirmed),
      ),
      MovementSection(
        title: 'Rejected',
        backgroundColor: const Color(0xFFFFF0F0),
        bucket: MovementBucket.rejected,
        items: inBucket(MovementBucket.rejected),
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
  }

  Future<void> _openAddMovementScreen() async {
    final RoleProvider roles = context.read<RoleProvider>();
    if (!_canMutateMovements(roles)) {
      _toastViewOnly(context);
      return;
    }

    final MovementFormResult? result = await Navigator.of(context).push<MovementFormResult>(
      MaterialPageRoute(
        builder: (_) => AddEditIndividualMovementScreen(
          students: _students,
          classrooms: _classrooms,
          existingMovements: List<MovementItem>.from(_allMovements),
        ),
      ),
    );
    if (result == null || !mounted) return;

    final String? formError = IndividualMovementValidators.validateMoveToNextClassroomForm(
      student: result.student,
      fromClassroom: result.currentClassroom,
      toClassroom: result.nextClassroom,
      movementDate: result.movementDate,
      existing: _allMovements,
    );
    if (formError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(formError)));
      return;
    }

    setState(() {
      final int maxId = _allMovements.isEmpty
          ? 0
          : _allMovements.map((MovementItem e) => e.id).reduce((int a, int b) => a > b ? a : b);
      _allMovements.insert(
        0,
        MovementItem(
          id: maxId + 1,
          name: result.student,
          fromClassroom: result.currentClassroom,
          toClassroom: result.nextClassroom,
          movementDate: result.movementDate,
          comment: result.comment,
          workflowStatus: MovementWorkflowStatus.pending,
        ),
      );
    });
  }

  Future<String?> _showRejectCommentDialog() async {
    final TextEditingController controller = TextEditingController();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Reject movement'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Comment (optional)',
            ),
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
    final String note = controller.text.trim();
    controller.dispose();
    if (confirmed != true) return null;
    return note;
  }

  String _mergeRejectComment(String existing, String rejectNote) {
    if (rejectNote.isEmpty) return existing;
    if (existing.trim().isEmpty) return 'Reject: $rejectNote';
    return '$existing\nReject: $rejectNote';
  }

  Future<void> _showMovementOptions(MovementItem item) async {
    final RoleProvider roles = context.read<RoleProvider>();
    if (!_canMutateMovements(roles)) {
      _toastViewOnly(context);
      return;
    }

    final IndividualMovementAction? action =
        await showIndividualMovementOptionsBottomSheet(context, item: item);
    if (action == null || !mounted) return;

    switch (action) {
      case IndividualMovementAction.edit:
        final MovementFormResult? result = await Navigator.of(context).push<MovementFormResult>(
          MaterialPageRoute(
            builder: (_) => AddEditIndividualMovementScreen(
              students: _students,
              classrooms: _classrooms,
              existingMovements: List<MovementItem>.from(_allMovements),
              initialData: MovementFormResult(
                student: item.name,
                currentClassroom: item.fromClassroom,
                nextClassroom: item.toClassroom,
                movementDate: item.movementDate,
                comment: item.comment,
              ),
              isEditing: true,
              editingMovementId: item.id,
            ),
          ),
        );
        if (result == null || !mounted) return;
        setState(() {
          final int idx = _allMovements.indexWhere((MovementItem e) => e.id == item.id);
          if (idx >= 0) {
            final MovementWorkflowStatus nextStatus =
                item.workflowStatus == MovementWorkflowStatus.rejected
                    ? MovementWorkflowStatus.pending
                    : item.workflowStatus;
            _allMovements[idx] = _allMovements[idx].copyWith(
              name: result.student,
              fromClassroom: result.currentClassroom,
              toClassroom: result.nextClassroom,
              movementDate: result.movementDate,
              comment: result.comment,
              workflowStatus: nextStatus,
            );
          }
        });
        break;
      case IndividualMovementAction.confirm:
        if (item.workflowStatus != MovementWorkflowStatus.pending) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Only pending movements can be confirmed. Edit the movement first.'),
            ),
          );
          return;
        }
        if (IndividualMovementValidators.hasIdenticalFromAndTo(
          item.fromClassroom,
          item.toClassroom,
        )) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('From and to classroom cannot be the same.')),
          );
          return;
        }
        final bool? confirmed = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => ConfirmIndividualMovementScreen(item: item),
          ),
        );
        if (confirmed != true || !mounted) return;
        setState(() {
          final int idx = _allMovements.indexWhere((MovementItem e) => e.id == item.id);
          if (idx >= 0) {
            _allMovements[idx] =
                _allMovements[idx].copyWith(workflowStatus: MovementWorkflowStatus.confirmed);
          }
        });
        break;
      case IndividualMovementAction.reject:
        final String? rejectNote = await _showRejectCommentDialog();
        if (rejectNote == null || !mounted) return;
        setState(() {
          final int idx = _allMovements.indexWhere((MovementItem e) => e.id == item.id);
          if (idx >= 0) {
            _allMovements[idx] = _allMovements[idx].copyWith(
              workflowStatus: MovementWorkflowStatus.rejected,
              comment: _mergeRejectComment(_allMovements[idx].comment, rejectNote),
            );
          }
        });
        break;
      case IndividualMovementAction.delete:
        setState(() {
          _allMovements.removeWhere((MovementItem e) => e.id == item.id);
        });
        break;
    }
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
    final List<MovementSection> sections = _buildSections();
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
            IndividualMovementFilterCard(
              students: _students,
              classrooms: _classrooms,
              selectedStudent: _selectedStudent,
              toClassroom: _toClassroom,
              fromClassroom: _fromClassroom,
              filterRangeStart: _filterRangeStart,
              filterRangeEnd: _filterRangeEnd,
              onStudentChanged: (String? value) {
                setState(() => _selectedStudent = value);
                _persistFilters();
              },
              onToClassroomChanged: (String? value) {
                setState(() => _toClassroom = value);
                _persistFilters();
              },
              onFromClassroomChanged: (String? value) {
                setState(() => _fromClassroom = value);
                _persistFilters();
              },
              onDateRangeChanged: (DateTime? start, DateTime? end) {
                setState(() {
                  _filterRangeStart = start;
                  _filterRangeEnd = end;
                });
                _persistFilters();
              },
              onClearAll: _clearFilters,
            ),
            const SizedBox(height: 12),
            IndividualMovementPager(
              sections: sections,
              currentSectionIndex: _currentSectionIndex,
              sectionPageController: _sectionPageController,
              onPageChanged: (int index) => setState(() => _currentSectionIndex = index),
              onPrevious: _goToPreviousSection,
              onNext: _goToNextSection,
              onMoreTap: _showMovementOptions,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
