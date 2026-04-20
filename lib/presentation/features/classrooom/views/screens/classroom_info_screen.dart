import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/domain/features/classroom/entities/classroom.dart';
import 'package:wowcare/domain/features/classroom/entities/classroom_details.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_classroom_by_code_usecase.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/presentation/features/classrooom/views/widgets/classroom_dropdown.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/events_card.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/domain/features/attendance/entities/student_attendance_expected_summary.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_attendance_expected_summary_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_attendance_expected_summary_usecase.dart';

class ClassroomInfoScreen extends StatefulWidget {
  const ClassroomInfoScreen({super.key});

  static const String routeName = '/classroom-info-screen';

  @override
  State<ClassroomInfoScreen> createState() => _ClassroomInfoScreenState();
}

class _ClassroomInfoScreenState extends State<ClassroomInfoScreen> {
  Classroom? _selectedRoom;
  ClassroomDetails? _details;
  bool _isDetailsLoading = false;
  String? _detailsError;
  final GetClassroomByCodeUseCase _getClassroomByCodeUseCase =
      serviceLocator<GetClassroomByCodeUseCase>();
  final GetStudentAttendanceExpectedSummaryUseCase
      _getStudentAttendanceExpectedSummaryUseCase =
      serviceLocator<GetStudentAttendanceExpectedSummaryUseCase>();
  final GetStaffAttendanceExpectedSummaryUseCase
      _getStaffAttendanceExpectedSummaryUseCase =
      serviceLocator<GetStaffAttendanceExpectedSummaryUseCase>();
  StudentAttendanceExpectedSummary? _studentSummary;
  StudentAttendanceExpectedSummary? _staffSummary;
  bool _isSummaryLoading = false;
  String? _summaryError;

  @override
  void initState() {
    super.initState();
    // Selected room may be passed as a route argument
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Classroom) {
        setState(() {
          _selectedRoom = args;
        });
        _loadDetails(args.code);
      }
    });
  }

  Future<void> _loadSummaries() async {
    setState(() {
      _isSummaryLoading = true;
      _summaryError = null;
    });
    try {
      final student = await _getStudentAttendanceExpectedSummaryUseCase();
      final staff = await _getStaffAttendanceExpectedSummaryUseCase();
      if (!mounted) return;
      setState(() {
        _studentSummary = student;
        _staffSummary = staff;
        _isSummaryLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSummaryLoading = false;
        _summaryError = e.toString();
      });
    }
  }

  Future<void> _loadDetails(String code) async {
    setState(() {
      _isDetailsLoading = true;
      _detailsError = null;
    });
    try {
      final details = await _getClassroomByCodeUseCase(code: code);
      if (!mounted) return;
      setState(() {
        _details = details;
        _isDetailsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDetailsLoading = false;
        _detailsError = e.toString();
      });
    }
  }

  Widget _buildRoomDetailsCard(ClassroomDetails details) {
    final isRatioGood = (details.status.toUpperCase() == 'ACTIVE');

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
          fileUuid: '',
          name: details.name,
          size: 60,
          fontSize: 24,
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              details.name,
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
                details.minAgeYear + details.minAgeMonths + details.maxAgeYear + details.maxAgeMonths > 0
                    ? '${details.minAgeYear}-${details.maxAgeYear} Years'
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
                          text: '${details.capacity}',
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
                          text: '${details.studentsPerTeacher}:1',
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
    return BlocProvider<ClassroomCubit>(
      create: (_) => serviceLocator<ClassroomCubit>()..loadActiveClassrooms(),
      child: BlocBuilder<ClassroomCubit, ClassroomState>(
        builder: (context, state) {
          final classrooms = state.classrooms;
          if (classrooms.isNotEmpty && _selectedRoom == null) {
            _selectedRoom = classrooms.first;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadDetails(_selectedRoom!.code);
            });
          }

          final dropdownItems = classrooms.map((e) => e.name).toList();
          final isInitialLoading = state.isLoading && classrooms.isEmpty;

          return GlobalScaffold(
            body: CustomRefreshIndicator(
              onRefresh: () async {
                await context.read<ClassroomCubit>().loadActiveClassrooms(force: true);
                if (_selectedRoom != null) {
                  await _loadDetails(_selectedRoom!.code);
                }
                await _loadSummaries();
              },
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: ClassroomDropdown(
                            items: dropdownItems.isEmpty ? const ['Loading...'] : dropdownItems,
                            value: dropdownItems.isEmpty
                                ? 'Loading...'
                                : (_selectedRoom?.name ?? dropdownItems.first),
                            onChanged: (value) {
                              if (dropdownItems.isEmpty) return;
                              final selected = classrooms.firstWhere((c) => c.name == value);
                              setState(() {
                                _selectedRoom = selected;
                              });
                              _loadDetails(selected.code);
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
                    if (isInitialLoading || _isDetailsLoading || _isSummaryLoading)
                      const Center(child: PrimaryCircularLoader())
                    else if (_detailsError != null)
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          'Failed to load classroom details',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
                        ),
                      )
                    else if (_summaryError != null)
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Text(
                          'Failed to load summary cards',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red),
                        ),
                      )
                    else if (_details != null)
                      _buildRoomDetailsCard(_details!),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      title: 'Enrolled\nStudents',
                      number: '0',
                      items: [
                        _ProgressItem(
                          label: 'Active (0)',
                          value: 0,
                          color: Colors.lightBlue,
                        ),
                        _ProgressItem(
                          label: 'Upcoming (0)',
                          value: 0,
                          color: Colors.amber,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      title: 'Expected\nStudents',
                      number: (_studentSummary?.expected ?? 0).toString(),
                      items: [
                        _ProgressItem(
                          label: 'Present (${_studentSummary?.present ?? 0})',
                          value: (_studentSummary?.present ?? 0).toDouble(),
                          color: Colors.green,
                        ),
                        _ProgressItem(
                          label: 'Absent (${_studentSummary?.absent ?? 0})',
                          value: (_studentSummary?.absent ?? 0).toDouble(),
                          color: Colors.red,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(
                      title: 'Expected\nStaff',
                      number: (_staffSummary?.expected ?? 0).toString(),
                      items: [
                        _ProgressItem(
                          label: 'Present (${_staffSummary?.present ?? 0})',
                          value: (_staffSummary?.present ?? 0).toDouble(),
                          color: Colors.green,
                        ),
                        _ProgressItem(
                          label: 'Absent (${_staffSummary?.absent ?? 0})',
                          value: (_staffSummary?.absent ?? 0).toDouble(),
                          color: Colors.red,
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Icon(Icons.chevron_left, color: Colors.grey),
                                Text(
                                  'Nov 2025',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    color: Color(0xff573353),
                                  ),
                                ),
                                Icon(Icons.chevron_right, color: Colors.grey),
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
                ),
              ),
            ),
            hasBackButton: true,
          );
        },
      ),
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
