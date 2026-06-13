import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_navigation_bar.dart';
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
import 'package:wowcare/shared/common/widgets/highlightable_card.dart';
import 'package:wowcare/presentation/features/classrooom/forms/assign_student_to_classroom_form.dart';
import 'package:wowcare/presentation/features/classrooom/forms/assign_staff_to_classroom_form.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';

class ClassroomScreen extends StatefulWidget {
  const ClassroomScreen({
    super.key,
    this.initialTabIndex = 0,
    this.initialClassroomCode,
    this.initialHighlightCode,
  });

  final int initialTabIndex;

  /// When provided (e.g. from a notification deep-link), the dropdown opens
  /// pre-selected on the classroom with this code instead of the first one.
  final String? initialClassroomCode;

  /// Row code to highlight inside the opened tab — studentCode on the Students
  /// tab, staffCode on the Staff tab (from an assign-to-classroom notification).
  final String? initialHighlightCode;

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
  // Whether [widget.initialClassroomCode] has already been honored, so a manual
  // dropdown change afterwards isn't overridden on the next rebuild.
  bool _appliedInitialClassroom = false;
  bool _defaultClassroomPrefsResolved = false;
  String? _staffPrimaryClassroomCode;
  bool _defaultClassroomApplied = false;

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
    _resolveDefaultClassroomPrefs();
  }

  Future<void> _resolveDefaultClassroomPrefs() async {
    try {
      final storage = serviceLocator<StorageService>();
      final primary = await resolveStaffPrimaryClassroomCode(storage: storage);
      if (!mounted) return;
      setState(() {
        _staffPrimaryClassroomCode = primary;
        _defaultClassroomPrefsResolved = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _defaultClassroomPrefsResolved = true);
    }
  }

  Classroom? _pickDefaultClassroom(List<Classroom> classrooms) {
    if (classrooms.isEmpty) return null;

    final targetCode = widget.initialClassroomCode?.trim();
    if (!_appliedInitialClassroom &&
        targetCode != null &&
        targetCode.isNotEmpty) {
      for (final c in classrooms) {
        if (c.code.trim() == targetCode) {
          _appliedInitialClassroom = true;
          return c;
        }
      }
      return classrooms.first;
    }

    final primaryCode = (_staffPrimaryClassroomCode ?? '').trim();
    if (primaryCode.isNotEmpty) {
      for (final c in classrooms) {
        if (c.code.trim() == primaryCode) return c;
      }
    }

    // Admin (and staff fallback): first classroom sorted alphabetically by name.
    return classrooms.first;
  }

  void _applyDefaultClassroomSelection(List<Classroom> classrooms) {
    if (_defaultClassroomApplied || !_defaultClassroomPrefsResolved) return;
    if (classrooms.isEmpty) return;

    final picked = _pickDefaultClassroom(classrooms);
    if (picked == null) return;

    _defaultClassroomApplied = true;
    if (selectedRoom?.code == picked.code) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => selectedRoom = picked);
    });
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
  void didUpdateWidget(covariant ClassroomScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A new notification target arrived while the screen is already alive
    // (go_router rebuilds the branch with a new code) — re-apply on next build.
    if (oldWidget.initialClassroomCode != widget.initialClassroomCode &&
        widget.initialClassroomCode != null) {
      setState(() {
        _appliedInitialClassroom = false;
        _defaultClassroomApplied = false;
      });
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
          if (classrooms.isNotEmpty) {
            _applyDefaultClassroomSelection(classrooms);
          }

          final isInitialLoading = state.isLoading && classrooms.isEmpty;
          final dropdownItems = classrooms.map((c) => c.name).toList();

          return GlobalScaffold(
            bodyPadding: EdgeInsets.zero,
            floatingActionButton: _buildTabFab(context),
            body: Container(
              color: Colors.white,
              // Extra bottom padding clears the (extend-body) bottom nav so the
              // tab box's bottom border is visible instead of sitting behind it.
              padding: EdgeInsets.fromLTRB(8, 8, 8, 8 + CustomNavigationBar.navBarHeight),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: isInitialLoading
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: ShimmerLoader(
                                  height: 24,
                                  width: 160,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(6),
                                  ),
                                ),
                              )
                            : HighlightableCard(
                                // Flashes the dropdown when the screen was
                                // opened from a classroom notification whose
                                // code matches the (pre-selected) room.
                                code: selectedRoom?.code,
                                highlightCode: widget.initialClassroomCode,
                                borderRadius: 8,
                                child: ClassroomDropdown(
                                  items: dropdownItems.isEmpty
                                      ? const ['Loading...']
                                      : dropdownItems,
                                  value: dropdownItems.isEmpty
                                      ? 'Loading...'
                                      : (selectedRoom?.name ??
                                          dropdownItems.first),
                                  onChanged: (value) {
                                    if (dropdownItems.isEmpty) return;
                                    setState(() {
                                      selectedRoom = classrooms
                                          .firstWhere((c) => c.name == value);
                                    });
                                  },
                                ),
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
                        ? const Padding(
                            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                            child: ClassroomStudentsTabShimmer(),
                          )
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              ClassroomStudentsTabCard(
                                scrollController: _studentsScrollController,
                                selectedRoom: selectedRoom,
                                highlightCode: widget.initialHighlightCode,
                              ),
                              ClassroomStaffTabCard(
                                scrollController: _staffScrollController,
                                selectedRoom: selectedRoom,
                                highlightCode: widget.initialHighlightCode,
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
                  // Roster mutated — tell the Students tab card to drop its
                  // attendance cache and refetch so the newly assigned
                  // student appears immediately, no tab switch required.
                  notifyClassroomStudentsChanged();
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
                  // Staff roster mutated — tell the Staff tab card to drop its
                  // attendance cache and refetch so the newly assigned staff
                  // appears immediately, no tab switch required.
                  notifyClassroomStaffChanged();
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
