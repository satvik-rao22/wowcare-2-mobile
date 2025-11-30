import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/classrooom/views/classroom_tab_cards/classroom_students_tab_card.dart';
import 'package:wowcare/presentation/features/classrooom/views/classroom_tab_cards/classroom_staff_tab_card.dart';
import 'package:wowcare/presentation/features/classrooom/views/classroom_tab_cards/classroom_notes_tab_card.dart';
import 'package:wowcare/presentation/features/classrooom/views/screens/classroom_info_screen.dart';
import 'package:wowcare/presentation/features/classrooom/views/widgets/classroom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/gradient_add_button.dart';
import 'package:wowcare/presentation/features/classrooom/forms/assign_student_to_classroom_form.dart';
import 'package:wowcare/presentation/features/classrooom/forms/assign_staff_to_classroom_form.dart';
// Backend/bloc imports disabled for UI-only mode
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:wowcare/core/extentions/context_extentions.dart';
// import 'package:wowcare/core/services/injection_container.dart';
// import 'package:wowcare/core/util/core_utils.dart';
// import 'package:wowcare/core/util/typedefs.dart';
// import 'package:wowcare/features/...';
// import 'package:wowcare/presentation/features/classrooom/views/classroom_tab_cards/classroom_notes_tab_card.dart';
// import 'package:wowcare/presentation/features/classrooom/views/classroom_tab_cards/classroom_staff_tab_card.dart';
// import 'package:wowcare/src/communication/domain/entities/classroom_chat_models.dart';

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
  RoomDTO? selectedRoom;
  bool isRoomDataLoaded = false;
  bool hasRoomBeenSet = false;
  String? roomName;
  String? displayRoomName;
  final List<RoomDTO> _dummyRooms = const [
    RoomDTO(id: 1, name: 'Room A'),
    RoomDTO(id: 2, name: 'Room B'),
    RoomDTO(id: 3, name: 'Room C'),
  ];

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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!hasRoomBeenSet) {
      selectedRoom = _dummyRooms.first;
      displayRoomName = selectedRoom?.name;
      hasRoomBeenSet = true;
      getClassroomsData();
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

  // Backend disabled: classrooms data provided via dummy list
  void getClassroomsData() {}

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
    return GlobalScaffold(
      floatingActionButton: _buildTabFab(context),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ClassroomDropdown(
                  items: _dummyRooms.map((room) => room.name).toList(),
                  value: selectedRoom?.name ?? _dummyRooms.first.name,
                  onChanged: (value) {
                    setState(() {
                      selectedRoom =
                          _dummyRooms.firstWhere((room) => room.name == value);
                      displayRoomName = selectedRoom!.name;
                    });
                  },
                ),
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ClassroomInfoScreen(),
                      settings: RouteSettings(arguments: selectedRoom),
                    ),
                  );
                },
                icon: SvgPicture.asset(
                  MediaRes.infoButtonSelectedIcon,
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
            child: TabBarView(
              controller: _tabController,
              children: [
                ClassroomStudentsTabCard(
                  scrollController: _studentsScrollController,
                  // Pass null to avoid cross-file RoomDTO type mismatch
                  selectedRoom: null,
                ),
                ClassroomStaffTabCard(
                  scrollController: _staffScrollController,
                  // Pass null to avoid cross-file RoomDTO type mismatch
                  selectedRoom: null,
                ),
                ClassroomNotesTabCard(
                  scrollController: _notesScrollController,
                  // Pass null to avoid cross-file RoomDTO type mismatch
                  selectedRoom: null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildTabFab(BuildContext context) {
    // Show respective FAB only on Students (0) and Staff (1) tabs
    if (selectedRoom == null) return null;
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

// Lightweight RoomDTO for UI-only
class RoomDTO {
  final int id;
  final String name;
  const RoomDTO({required this.id, required this.name});
}
