import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/data/features/Student-Module/Student-Module-Models/student_view_model.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';

import '../../../data/features/Student-Module/Student-Module-DataSource/student_data_cubit.dart';
import '../../../data/features/Student-Module/Students-Modeule-Repository/student_repository.dart';
import '../../../domain/features/Student-Module/entities/Student-Entity.dart';
import '../widgets/dates_tab_content.dart';
import '../widgets/documents_tab_content.dart';
import '../widgets/health_tab_content.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key, required this.students});

  final List<StudentEntity> students;

  static const String routeName = '/student-profile-screen';

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabControllerPrimary;
  int _selectedPrimaryTabIndex = 0;
  bool isGettingChatData = false;
  String chatId = '0';
  List<Staff> staffList = [];
  List<GuardianEntity> studentGuardians = [];
  late StudentViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = StudentViewModel(StudentRepository());
    _tabControllerPrimary = TabController(length: 4, vsync: this);
    _tabControllerPrimary.addListener(_handlePrimaryTabChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  void _handlePrimaryTabChange() {
    if (_tabControllerPrimary.indexIsChanging ||
        _selectedPrimaryTabIndex != _tabControllerPrimary.index) {
      setState(() {
        _selectedPrimaryTabIndex = _tabControllerPrimary.index;
      });
    }
  }

  Future<void> _initializeData() async {
    if (widget.students.isEmpty) return;
    final student = widget.students.first;
    setState(() => isGettingChatData = true);
    await _fetchChatData(student);
    if (mounted) setState(() => isGettingChatData = false);
  }

  Future<void> _fetchChatData(StudentEntity student) async {
    try {
      chatId = 'chat123';
      staffList = await _viewModel.getStaff(student.roomId, student.schoolId);
      studentGuardians = await _viewModel.getGuardians(
        student.id,
        student.schoolId,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to fetch chat data: $e')));
    }
  }

  @override
  void dispose() {
    _tabControllerPrimary.removeListener(_handlePrimaryTabChange);
    _tabControllerPrimary.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final student = widget.students.isNotEmpty
        ? widget.students.first
        : StudentEntity.demo;

    return Scaffold(
      appBar: CustomAppBar(hasBackButton: true),
      body: Column(
        children: [
          _buildStudentCard(student),
          Expanded(
            child: TabBarView(
              controller: _tabControllerPrimary,
              children: [
                _buildProfileTab(student),
                _buildHealthTab(student),
                _buildDatesTab(student),
                _buildDocumentsTab(student),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard(StudentEntity student) {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: AssetImage('assets/profile_placeholder.png'),
                ),
                if (student.isSignedIn || student.isAbsent)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: student.isSignedIn ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.fullName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    student.roomName,
                    style: const TextStyle(color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (!student.isPhotoPermission)
                        _buildIconLabel('assets/camera.svg', 'No Photo'),
                      if (student.medications.isNotEmpty)
                        _buildIconLabel('assets/health.svg', 'Medications'),
                      if (student.allergies.isNotEmpty)
                        _buildIconLabel('assets/alert.svg', 'Allergies'),
                      if (student.note.isNotEmpty)
                        _buildIconLabel('assets/docs.svg', 'Notes'),
                      if (student.dietRestriction.isNotEmpty)
                        _buildIconLabel('assets/food.svg', 'Diet'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconLabel(String iconPath, String label) {
    return Chip(
      avatar: SvgPicture.asset(iconPath, height: 20),
      label: Text(label),
      backgroundColor: Colors.blue[50],
      labelStyle: const TextStyle(color: Colors.blue),
    );
  }

  Widget _buildProfileTab(StudentEntity student) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoRow('Date of Birth', student.dateOfBirth),
          _buildInfoRow('Gender', student.gender ?? '-'),
          _buildInfoRow('Blood Group', student.bloodGroup ?? '-'),
          _buildInfoRow('Food Program', student.foodProgram ?? '-'),
          _buildInfoRow('Profile Status', student.profileStatus),
          _buildInfoRow('Open Balance', '\$${student.openBalance}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text('$title:', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildHealthTab(StudentEntity student) {
    return BlocProvider(
      create: (_) => StudentDataCubit(_viewModel),
      child: HealthTabContent(student: student),
    );
  }

  Widget _buildDatesTab(StudentEntity student) {
    return BlocProvider(
      create: (_) => StudentDataCubit(_viewModel),
      child: DatesTabContent(student: student),
    );
  }

  Widget _buildDocumentsTab(StudentEntity student) {
    return BlocProvider(
      create: (_) => StudentDataCubit(_viewModel),
      child: DocumentsTabContent(student: student),
    );
  }
}
