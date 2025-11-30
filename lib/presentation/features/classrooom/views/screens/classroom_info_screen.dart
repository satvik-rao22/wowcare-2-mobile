import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/classrooom/views/widgets/classroom_dropdown.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/events_card.dart';
import 'package:shimmer/shimmer.dart';

class ClassroomInfoScreen extends StatefulWidget {
  const ClassroomInfoScreen({super.key});

  static const String routeName = '/classroom-info-screen';

  @override
  State<ClassroomInfoScreen> createState() => _ClassroomInfoScreenState();
}

class _ClassroomInfoScreenState extends State<ClassroomInfoScreen> {
  RoomInfo? selectedRoom;
  int? selectedRoomId = null;
  bool isFirstTimeLoaded = false;
  List<RoomInfo> allRooms = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Backend disabled: initialize UI with dummy rooms
      getClassroomsData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // No-op in UI-only mode
  }

  void getClassroomsData() async {
    allRooms = [
      RoomInfo(
        room: RoomDTOInfo(
          id: 1,
          name: 'Sunshine Room',
          ageRange: '2-3 Years',
          maxCapacity: 20,
          staffRatio: '10',
          photoUuid: '',
        ),
        isRatioCheck: true,
        assignedStudent: 12,
        enrolledButNotStarted: 3,
        expectedStudent: 15,
        checkedInStudent: 10,
        absentStudent: 5,
        expectedStaff: 4,
        checkedInStaff: 3,
        onLeaveStaff: 1,
      ),
      RoomInfo(
        room: RoomDTOInfo(
          id: 2,
          name: 'Rainbow Room',
          ageRange: '3-4 Years',
          maxCapacity: 18,
          staffRatio: '9',
          photoUuid: '',
        ),
        isRatioCheck: false,
        assignedStudent: 9,
        enrolledButNotStarted: 2,
        expectedStudent: 11,
        checkedInStudent: 7,
        absentStudent: 4,
        expectedStaff: 3,
        checkedInStaff: 2,
        onLeaveStaff: 1,
      ),
    ];
    selectedRoomId ??= allRooms.first.room.id;
    setState(() {
      selectedRoom = allRooms.firstWhere((r) => r.room.id == selectedRoomId);
    });
  }

  void getClassroomsDataForPhoto() async {}

  Widget _buildRoomDetailsCard(RoomInfo room) {
    bool isRatioGood = room.isRatioCheck;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(
          width: 1.5,
          color: Color.fromARGB(255, 232, 234, 234),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        leading: DocumentImageWidget(
          fileUuid: room.room.photoUuid ?? '',
          name: room.room.name,
          size: 60,
          fontSize: 24,
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              room.room.name,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Icon(
                  isRatioGood ? Icons.thumb_up : Icons.thumb_down,
                  color: isRatioGood ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                // Uncomment the next line if you want to show the edit icon for admins or directors or when the functionality is implemented
                // if (context.isAdminOrDirector) const Icon(Icons.edit_outlined),
              ],
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                room.room.ageRange.isNotEmpty
                    ? room.room.ageRange.trim()
                    : 'No Age Limit',
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  color: Color(0xff573353),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                      child: Text.rich(
                    TextSpan(
                      text: 'Capacity: ',
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        color: Color(0xff573353),
                      ),
                      children: [
                        TextSpan(
                          text: '${room.room.maxCapacity}',
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontWeight: FontWeight.bold,
                            color: Color(0xff573353),
                          ),
                        ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  )),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text.rich(
                    TextSpan(
                      text: 'Ratio: ',
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        color: Color(0xff573353),
                      ),
                      children: [
                        TextSpan(
                          text: room.room.staffRatio.isEmpty
                              ? '0'
                              : '${room.room.staffRatio}:1',
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontWeight: FontWeight.bold,
                            color: Color(0xff573353),
                          ),
                        ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  )),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlobalScaffold(
      body: CustomRefreshIndicator(
        onRefresh: () async {
          getClassroomsData();
        },
        child: SingleChildScrollView(
          child: Builder(builder: (context) {
            final List<String> roomNames =
                allRooms.map((room) => room.room.name).toList();
            selectedRoom ??= allRooms.first;
            return Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: ClassroomDropdown(
                            items: roomNames,
                            value: selectedRoom!.room.name,
                            onChanged: (value) {
                              setState(() {
                                selectedRoom = allRooms.firstWhere(
                                  (room) => room.room.name == value,
                                );
                              });
                            },
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: SvgPicture.asset(
                            MediaRes.classroomInfoIcon,
                            height: 28,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildRoomDetailsCard(selectedRoom!),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      title: 'Enrolled\nStudents',
                      number:
                          '${selectedRoom!.assignedStudent + selectedRoom!.enrolledButNotStarted}',
                      items: [
                        _ProgressItem(
                          label:
                              'Active (${selectedRoom!.assignedStudent.toString()})',
                          value: selectedRoom!.assignedStudent.toDouble(),
                          color: Colors.lightBlue[200]!,
                        ),
                        _ProgressItem(
                          label:
                              'Upcoming (${selectedRoom!.enrolledButNotStarted.toString()})',
                          value: selectedRoom!.enrolledButNotStarted.toDouble(),
                          color: Colors.amber,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      title: 'Expected\nStudents',
                      number: selectedRoom!.expectedStudent.toString(),
                      items: [
                        _ProgressItem(
                          label:
                              'Present  (${selectedRoom!.checkedInStudent.toString()})',
                          value: selectedRoom!.checkedInStudent.toDouble(),
                          color: Colors.green[200]!,
                        ),
                        _ProgressItem(
                          label:
                              'Absent (${selectedRoom!.absentStudent.toString()})',
                          value: selectedRoom!.absentStudent.toDouble(),
                          color: Colors.red[200]!,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      title: 'Expected\nStaff',
                      number: selectedRoom!.expectedStaff.toString(),
                      items: [
                        _ProgressItem(
                          label:
                              'Present (${selectedRoom!.checkedInStaff.toString()})',
                          value: selectedRoom!.checkedInStaff.toDouble(),
                          color: Colors.green[200]!,
                        ),
                        _ProgressItem(
                          label:
                              'Absent (${selectedRoom!.onLeaveStaff.toString()})',
                          value: selectedRoom!.onLeaveStaff.toDouble(),
                          color: Colors.red[200]!,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(
                          width: 1.5,
                          color: Color.fromARGB(255, 232, 234, 234),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Events',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xff573353),
                              ),
                            ),
                            const SizedBox(height: 16),
                             // Calendar header simplified for UI-only mode
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Icon(Icons.chevron_left, color: Colors.grey),
                                  const Text(
                                    'Nov 2025',
                                    style: TextStyle(
                                      fontFamily: 'Manrope',
                                      color: Color(0xff573353),
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: Colors.grey),
                                ],
                              ),
                            const SizedBox(height: 16),
                            const EventsCard(),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
          }),
        ),
      ),
      hasBackButton: true,
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String number,
    required List<_ProgressItem> items,
  }) {
    int total = int.tryParse(number) ?? 0;
    double sumValues = items.fold(0, (sum, item) => sum + item.value);
    bool hasValidTotal = total > 0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(
          width: 1.5,
          color: Color.fromARGB(255, 232, 234, 234),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        child: Row(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  number,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 32,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    color: const Color(0xff573353),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 28),
            Expanded(
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: SizedBox(
                      height: 24,
                      child: Row(
                        children: !hasValidTotal
                            ? [
                                Expanded(
                                    child: Container(color: Colors.grey[300]))
                              ]
                            : [
                                ...items.map((item) => Expanded(
                                      flex: hasValidTotal
                                          ? (item.value * 100 ~/ total)
                                          : 1,
                                      child: Container(color: item.color),
                                    )),
                                if (sumValues < total)
                                  Expanded(
                                    flex: hasValidTotal
                                        ? ((total - sumValues) * 100 ~/ total)
                                        : 1,
                                    child: Container(color: Colors.grey[300]),
                                  ),
                              ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: items
                        .map(
                          (item) => Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: item.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.label,
                                style: const TextStyle(fontFamily: 'Manrope', fontSize: 12),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// UI-only lightweight models
class RoomDTOInfo {
  final int id;
  final String name;
  final String ageRange;
  final int maxCapacity;
  final String staffRatio;
  final String? photoUuid;
  const RoomDTOInfo({
    required this.id,
    required this.name,
    required this.ageRange,
    required this.maxCapacity,
    required this.staffRatio,
    this.photoUuid,
  });
}

class RoomInfo {
  final RoomDTOInfo room;
  final bool isRatioCheck;
  final int assignedStudent;
  final int enrolledButNotStarted;
  final int expectedStudent;
  final int checkedInStudent;
  final int absentStudent;
  final int expectedStaff;
  final int checkedInStaff;
  final int onLeaveStaff;

  RoomInfo({
    required this.room,
    required this.isRatioCheck,
    required this.assignedStudent,
    required this.enrolledButNotStarted,
    required this.expectedStudent,
    required this.checkedInStudent,
    required this.absentStudent,
    required this.expectedStaff,
    required this.checkedInStaff,
    required this.onLeaveStaff,
  });
}

class _EventRow extends StatelessWidget {
  final String date;
  final String month;
  final String title;
  final Color borderColor;
  const _EventRow({
    required this.date,
    required this.month,
    required this.title,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(date,
                    style: const TextStyle(
                        fontFamily: 'Manrope', fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xff573353))),
                Text(month, style: const TextStyle(fontFamily: 'Manrope', fontSize: 12, color: Color(0xff573353))),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color.fromRGBO(87, 51, 83, 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressItem {
  final String label;
  final double value;
  final Color color;

  _ProgressItem({
    required this.label,
    required this.value,
    required this.color,
  });
}

class ClassroomInfoShimmer extends StatelessWidget {
  const ClassroomInfoShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 200,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Room Details Card
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 16),

              // Enrolled Students Card
              _buildMetricsShimmerCard(),
              const SizedBox(height: 16),

              // Expected Students Card
              _buildMetricsShimmerCard(),
              const SizedBox(height: 16),

              // Expected Staff Card
              _buildMetricsShimmerCard(),
              const SizedBox(height: 16),

              // Events Card
              Container(
                height: 400,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Events Title
                      Container(
                        width: 80,
                        height: 24,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),

                      // Calendar Week Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(
                            7,
                            (index) => Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                )),
                      ),
                      const SizedBox(height: 24),

                      // Event Items
                      ...List.generate(
                          3,
                          (index) => Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Row(
                                  children: [
                                    // Date Container
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Event Details
                                    Expanded(
                                      child: Container(
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsShimmerCard() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Title and Number
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 80,
                  height: 32,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Container(
                  width: 60,
                  height: 40,
                  color: Colors.white,
                ),
              ],
            ),
            const SizedBox(width: 24),
            // Progress Bar and Labels
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 80,
                        height: 12,
                        color: Colors.white,
                      ),
                      Container(
                        width: 80,
                        height: 12,
                        color: Colors.white,
                      ),
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
}
