import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/attendance_classroom_scope.dart';
import 'package:wowcare/domain/features/classroom/entities/classroom.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/presentation/features/classrooom/views/classroom_tab_cards/classroom_students_tab_card.dart';
import 'package:wowcare/presentation/features/classrooom/views/classroom_tab_cards/classroom_staff_tab_card.dart';
import 'package:wowcare/presentation/features/classrooom/views/classroom_tab_cards/classroom_notes_tab_card.dart';
import 'package:wowcare/presentation/features/classrooom/views/screens/classroom_info_screen.dart';
import 'package:wowcare/presentation/features/classrooom/views/widgets/classroom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/gradient_add_button.dart';
import 'package:wowcare/presentation/features/classrooom/forms/assign_student_to_classroom_form.dart';
import 'package:wowcare/presentation/features/classrooom/forms/assign_staff_to_classroom_form.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';

class ClassroomScreen extends StatefulWidget {
  const ClassroomScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  final int initialTabIndex;

  static const routeName = '/classroom-screen';

  @override
  State<ClassroomScreen> createState() => _ClassroomScreenState();
}

class _ClassroomScreenState extends State<ClassroomScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _studentsScrollController = ScrollController();
  final ScrollController _staffScrollController = ScrollController();
  final ScrollController _notesScrollController = ScrollController();
  Classroom? selectedRoom;
  bool _hideAssignFabForStaffPersona = false;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _tabController.addListener(() {
      setState(() {});
    });

    _resolveStaffPersonaRestrictions();
  }

  Future<void> _resolveStaffPersonaRestrictions() async {
    try {
      final storage = serviceLocator<StorageService>();
      final shouldScope =
          await isAttendanceScopedStaffPersona(storage: storage);
      if (!mounted) return;
      setState(() => _hideAssignFabForStaffPersona = shouldScope);
    } catch (_) {
      // Fail open: keep FAB visible.
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _studentsScrollController.dispose();
    _staffScrollController.dispose();
    _notesScrollController.dispose();
    super.dispose();
  }

  // Backend disabled: always 0 unread
  Stream<int> getClassroomNotesUnreadCountStream() => Stream.value(0);

  Tab _buildTab({
    required String label,
    required Color color,
  }) {
    return Tab(
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(12),
          ),
        ),
        child: Center(
          child: Text(
            label,
          ),
        ),
      ),
    );
  }

  Tab _builtNotesTab({
    required String label,
    required Color color,
  }) {
    return Tab(
      child: StreamBuilder<int>(
        stream: getClassroomNotesUnreadCountStream(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final unreadCount = snapshot.data ?? 0;
            return Container(
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                    ),
                    const SizedBox(width: 4),
                    if (unreadCount > 0)
                      CircleAvatar(
                        radius: 9,
                        backgroundColor: AppColors.successColor,
                        child: Text(
                          unreadCount.toString(),
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }
          return Container(
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Center(
              child: Text(
                label,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ClassroomCubit>(
      create: (_) => serviceLocator<ClassroomCubit>()
        ..loadActiveClassrooms(applyAttendanceStaffScope: true),
      child: BlocBuilder<ClassroomCubit, ClassroomState>(
        builder: (context, state) {
          final classrooms = state.classrooms;
          if (classrooms.isNotEmpty && selectedRoom == null) {
            selectedRoom = classrooms.first;
          }

          final isInitialLoading = state.isLoading && classrooms.isEmpty;
          final dropdownItems = classrooms.map((c) => c.name).toList();

          return GlobalScaffold(
            bodyPadding: EdgeInsets.zero,
            floatingActionButton: _buildTabFab(context),
            body: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: ClassroomDropdown(
                          items: dropdownItems.isEmpty
                              ? const ['Loading...']
                              : dropdownItems,
                          value: dropdownItems.isEmpty
                              ? 'Loading...'
                              : (selectedRoom?.name ?? dropdownItems.first),
                          onChanged: (value) {
                            if (dropdownItems.isEmpty) return;
                            setState(() {
                              selectedRoom =
                                  classrooms.firstWhere((c) => c.name == value);
                            });
                          },
                        ),
                      ),
                      IconButton(
                        tooltip: 'Class profile',
                        onPressed: classrooms.isEmpty
                            ? null
                            : () {
                                final room = selectedRoom ?? classrooms.first;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ClassroomInfoScreen(),
                                    settings: RouteSettings(arguments: room),
                                  ),
                                );
                              },
                        icon: SvgPicture.asset(
                          MediaRes.infoButtonIcon,
                          height: 32,
                        ),
                      ),
                    ],
                  ),
                  Transform.translate(
                    offset: const Offset(0, 4),
                    child: TabBar(
                      controller: _tabController,
                      dividerHeight: 0,
                      indicator: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        border: Border.all(
                          color: AppColors.classroomStudentTabColor
                              .withValues(alpha: 1),
                        ),
                      ),
                      labelStyle: TextTheme.of(context).titleSmall!.copyWith(
                            color: AppColors.primaryColor,
                            fontSize: 15,
                          ),
                      unselectedLabelStyle: TextTheme.of(context)
                          .titleSmall!
                          .copyWith(
                            color: AppColors.primaryColor.withValues(alpha: 0.5),
                            fontSize: 15,
                          ),
                      labelPadding: const EdgeInsets.all(0),
                      indicatorPadding: _tabController.index == 0
                          ? const EdgeInsets.only(right: 4)
                          : _tabController.index == 1
                              ? const EdgeInsets.symmetric(horizontal: 2)
                              : const EdgeInsets.only(left: 4),
                      splashFactory: NoSplash.splashFactory,
                      tabs: [
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: _buildTab(
                            label: 'Students',
                            color: AppColors.classroomStudentTabColor,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: _buildTab(
                            label: 'Staff',
                            color: AppColors.classroomStaffTabColor,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: _builtNotesTab(
                            label: 'Notes',
                            color: AppColors.classroomNotesTabColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: isInitialLoading
                        ? const Center(child: PrimaryCircularLoader())
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              ClassroomStudentsTabCard(
                                scrollController: _studentsScrollController,
                                selectedRoom: selectedRoom,
                              ),
                              ClassroomStaffTabCard(
                                scrollController: _staffScrollController,
                                selectedRoom: selectedRoom,
                              ),
                              ClassroomNotesTabCard(
                                scrollController: _notesScrollController,
                                selectedRoom: selectedRoom,
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget? _buildTabFab(BuildContext context) {
    // Show respective FAB only on Students (0) and Staff (1) tabs
    if (selectedRoom == null) return null;
    if (_hideAssignFabForStaffPersona) return null;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isLargeTablet = screenWidth >= 900;
    
    if (_tabController.index == 0) {
      return GradientAddButton(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => DraggableScrollableSheet(
              maxChildSize: 0.95,
              initialChildSize: 0.9,
              minChildSize: 0.6,
              builder: (_, controller) => AssignStudentToClassroomForm(
                selectedRoomName: selectedRoom!.name,
                classroomCode: selectedRoom!.code,
                onStudentsAssigned: () {
                  // no-op for UI-only; could trigger a UI refresh callback if needed
                },
              ),
            ),
          );
        },
        isTablet: isTablet,
        isLargeTablet: isLargeTablet,
      );
    }
    if (_tabController.index == 1) {
      return GradientAddButton(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => DraggableScrollableSheet(
              maxChildSize: 0.95,
              initialChildSize: 0.9,
              minChildSize: 0.6,
              builder: (_, controller) => AssignStaffToClassroomForm(
                selectedRoomName: selectedRoom!.name,
                classroomCode: selectedRoom!.code,
                onStaffsAssigned: () {
                  // no-op for UI-only; could trigger a UI refresh callback if needed
                },
              ),
            ),
          );
        },
        isTablet: isTablet,
        isLargeTablet: isLargeTablet,
      );
    }
    return null;
  }
}
