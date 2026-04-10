import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/fonts.dart';
import 'package:wowcare/presentation/features/availability/view/add_edit_individual_movement_screen.dart';
import 'package:wowcare/presentation/features/availability/view/confirm_individual_movement_screen.dart';
import 'package:wowcare/presentation/features/availability/widgets/individual_movement_bottom_sheet.dart';
import 'package:wowcare/presentation/features/availability/widgets/individual_movement_models.dart';
import 'package:wowcare/presentation/features/availability/widgets/individual_movement_overview.dart';
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
    _allMovements = <MovementItem>[
      MovementItem(
        id: 1,
        name: 'Arvind Joshi',
        fromClassroom: '1-Blue D',
        toClassroom: '2-Green D',
        movementDate: DateTime(2024, 7, 31),
        status: MovementStatus.overdue,
      ),
      MovementItem(
        id: 2,
        name: 'Chaitanya Bhave',
        fromClassroom: '1-Blue D',
        toClassroom: '2-Green D',
        movementDate: DateTime(2024, 9, 30),
        status: MovementStatus.overdue,
      ),
      MovementItem(
        id: 3,
        name: 'Kimberly Dixon',
        fromClassroom: '1-Blue D',
        toClassroom: '2-Green D',
        movementDate: DateTime(2024, 7, 31),
        status: MovementStatus.upcoming,
      ),
      MovementItem(
        id: 4,
        name: 'Aria KC',
        fromClassroom: '1-Blue D',
        toClassroom: '2-Green D',
        movementDate: DateTime(2024, 9, 30),
        status: MovementStatus.upcoming,
      ),
      MovementItem(
        id: 5,
        name: 'Devi Vampati',
        fromClassroom: '1-Blue D',
        toClassroom: '2-Green D',
        movementDate: DateTime(2024, 9, 30),
        status: MovementStatus.upcoming,
      ),
      MovementItem(
        id: 6,
        name: 'Nichole Adams',
        fromClassroom: '1-Blue D',
        toClassroom: '2-Green D',
        movementDate: DateTime(2024, 7, 31),
        status: MovementStatus.confirmed,
      ),
      MovementItem(
        id: 7,
        name: 'Brindar Goraya',
        fromClassroom: '1-Blue D',
        toClassroom: '2-Green D',
        movementDate: DateTime(2024, 9, 30),
        status: MovementStatus.confirmed,
      ),
      MovementItem(
        id: 8,
        name: 'Jessica Lima',
        fromClassroom: '1-Blue D',
        toClassroom: '2-Green D',
        movementDate: DateTime(2024, 9, 30),
        status: MovementStatus.confirmed,
      ),
      MovementItem(
        id: 9,
        name: 'Atraye Rawal',
        fromClassroom: '1-Blue D',
        toClassroom: '2-Green D',
        movementDate: DateTime(2024, 7, 31),
        status: MovementStatus.rejected,
      ),
      MovementItem(
        id: 10,
        name: 'Aparna Bhiwakar',
        fromClassroom: '1-Blue D',
        toClassroom: '2-Green D',
        movementDate: DateTime(2024, 9, 30),
        status: MovementStatus.rejected,
      ),
    ];
  }

  @override
  void dispose() {
    _sectionPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sections = _buildSections();
    if (_currentSectionIndex >= sections.length) {
      _currentSectionIndex = sections.length - 1;
    }
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
              onStudentChanged: (value) => setState(() => _selectedStudent = value),
              onToClassroomChanged: (value) => setState(() => _toClassroom = value),
              onFromClassroomChanged: (value) => setState(() => _fromClassroom = value),
              onClearAll: _clearFilters,
            ),
            const SizedBox(height: 12),
            IndividualMovementPager(
              sections: sections,
              currentSectionIndex: _currentSectionIndex,
              sectionPageController: _sectionPageController,
              onPageChanged: (index) => setState(() => _currentSectionIndex = index),
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

  List<MovementSection> _buildSections() {
    return <MovementSection>[
      MovementSection(
        title: 'Overdue',
        backgroundColor: const Color(0xFFF8F6FF),
        status: MovementStatus.overdue,
        items: _allMovements.where((e) => e.status == MovementStatus.overdue).toList(),
      ),
      MovementSection(
        title: 'Upcoming',
        backgroundColor: const Color(0xFFFFFBEE),
        status: MovementStatus.upcoming,
        items: _allMovements.where((e) => e.status == MovementStatus.upcoming).toList(),
      ),
      MovementSection(
        title: 'Confirmed',
        backgroundColor: const Color(0xFFEFFFF4),
        status: MovementStatus.confirmed,
        items: _allMovements.where((e) => e.status == MovementStatus.confirmed).toList(),
      ),
      MovementSection(
        title: 'Rejected',
        backgroundColor: const Color(0xFFFFF0F0),
        status: MovementStatus.rejected,
        items: _allMovements.where((e) => e.status == MovementStatus.rejected).toList(),
      ),
    ];
  }

  void _clearFilters() {
    setState(() {
      _selectedStudent = null;
      _toClassroom = null;
      _fromClassroom = null;
    });
  }

  Future<void> _openAddMovementScreen() async {
    final result = await Navigator.of(context).push<MovementFormResult>(
      MaterialPageRoute(
        builder: (_) => AddEditIndividualMovementScreen(
          students: _students,
          classrooms: _classrooms,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      final int maxId = _allMovements.isEmpty
          ? 0
          : _allMovements.map((e) => e.id).reduce((a, b) => a > b ? a : b);
      _allMovements.insert(
        0,
        MovementItem(
          id: maxId + 1,
          name: result.student,
          fromClassroom: result.currentClassroom,
          toClassroom: result.nextClassroom,
          movementDate: result.movementDate,
          comment: result.comment,
          status: MovementStatus.upcoming,
        ),
      );
    });
  }

  Future<void> _showMovementOptions(MovementItem item) async {
    final action = await showIndividualMovementOptionsBottomSheet(context);
    if (action == null || !mounted) return;

    switch (action) {
      case IndividualMovementAction.edit:
        final result = await Navigator.of(context).push<MovementFormResult>(
          MaterialPageRoute(
            builder: (_) => AddEditIndividualMovementScreen(
              students: _students,
              classrooms: _classrooms,
              initialData: MovementFormResult(
                student: item.name,
                currentClassroom: item.fromClassroom,
                nextClassroom: item.toClassroom,
                movementDate: item.movementDate,
                comment: item.comment,
              ),
              isEditing: true,
            ),
          ),
        );
        if (result == null || !mounted) return;
        setState(() {
          final idx = _allMovements.indexWhere((e) => e.id == item.id);
          if (idx >= 0) {
            _allMovements[idx] = _allMovements[idx].copyWith(
              name: result.student,
              fromClassroom: result.currentClassroom,
              toClassroom: result.nextClassroom,
              movementDate: result.movementDate,
              comment: result.comment,
            );
          }
        });
        break;
      case IndividualMovementAction.confirm:
        final bool? confirmed = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => ConfirmIndividualMovementScreen(item: item),
          ),
        );
        if (confirmed != true || !mounted) return;
        setState(() {
          final idx = _allMovements.indexWhere((e) => e.id == item.id);
          if (idx >= 0) {
            _allMovements[idx] =
                _allMovements[idx].copyWith(status: MovementStatus.confirmed);
          }
        });
        break;
      case IndividualMovementAction.reject:
        setState(() {
          final idx = _allMovements.indexWhere((e) => e.id == item.id);
          if (idx >= 0) {
            _allMovements[idx] = _allMovements[idx].copyWith(status: MovementStatus.rejected);
          }
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
    if (_currentSectionIndex == MovementStatus.values.length - 1) return;
    _sectionPageController.animateToPage(
      _currentSectionIndex + 1,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
    );
  }
}
