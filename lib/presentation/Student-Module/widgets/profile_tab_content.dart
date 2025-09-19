import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

// Placeholder definitions for missing classes
class StudentEntity {
  final int id;
  final String fullName;
  final String profileStatus;
  final String roomName;
  final List<TagModel> tags;
  final String dateOfBirth;
  final String note;
  final String? childCustody;
  final bool isStateSubsidyAllowed;
  final List<ScheduleEntity> schedule;
  final String? expectedMoveDate;
  final String? leavingDate;
  final String? startDate;

  StudentEntity({
    required this.id,
    required this.fullName,
    required this.profileStatus,
    required this.roomName,
    required this.tags,
    required this.dateOfBirth,
    required this.note,
    this.childCustody,
    required this.isStateSubsidyAllowed,
    required this.schedule,
    this.expectedMoveDate,
    this.leavingDate,
    this.startDate,
  });
}

class GuardianEntity {
  final int id;
  final String fullName;
  final String relation;
  final String email;
  final String phoneNumber;
  final int signInPin;
  final String photoUuid;

  GuardianEntity({
    required this.id,
    required this.fullName,
    required this.relation,
    required this.email,
    required this.phoneNumber,
    required this.signInPin,
    required this.photoUuid,
  });
}

class AddressEntity {
  final String line;
  final String city;
  final String state;
  final String country;
  final String zipcode;

  AddressEntity({
    required this.line,
    required this.city,
    required this.state,
    required this.country,
    required this.zipcode,
  });
}

class ScheduleEntity {
  final String day;
  final String startTime;
  final String endTime;
  final String status;

  ScheduleEntity({
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.status,
  });
}

class TagModel {
  final String name;

  TagModel({required this.name});
}

class AuthorizedPickupsEntity {
  final String firstName;
  final String lastName;
  final String relation;
  final String status;
  final String phoneNumber;
  final int signInPin;

  AuthorizedPickupsEntity({
    required this.firstName,
    required this.lastName,
    required this.relation,
    required this.status,
    required this.phoneNumber,
    required this.signInPin,
  });
}

class Sibling {
  final String? photoUuid;
  final String fullName;
  final String gender;
  final bool? isSignedIn;
  final bool? isAbsent;
  final String? profileStatus;

  Sibling({
    this.photoUuid,
    required this.fullName,
    required this.gender,
    this.isSignedIn,
    this.isAbsent,
    this.profileStatus,
  });
}

// Placeholder service locator
final sl = GetIt.instance;

// Placeholder service
class StudentService {
  static void getAllStudents(BuildContext context, {required int id}) {
    // Simulate fetching student data
    context.read<StudentDataCubit>().loadStudents([
      StudentEntity(
        id: id,
        fullName: "John Doe",
        profileStatus: "A",
        roomName: "Room 101",
        tags: [
          TagModel(name: "Tag1"),
          TagModel(name: "Tag2"),
        ],
        dateOfBirth: "2020-01-01",
        note: "Sample note",
        childCustody: "1",
        isStateSubsidyAllowed: true,
        schedule: [
          ScheduleEntity(
            day: "Monday",
            startTime: "09:00",
            endTime: "15:00",
            status: "A",
          ),
        ],
        expectedMoveDate: "2025-12-01",
      ),
    ]);
  }
}

// Placeholder utility
class CoreUtils {
  static String formatPhoneNumber(String phoneNumber) {
    if (phoneNumber.length != 10) return phoneNumber;
    return '(${phoneNumber.substring(0, 3)}) ${phoneNumber.substring(3, 6)}-${phoneNumber.substring(6, 10)}';
  }

  static void showTopSnackBar({
    required BuildContext context,
    required bool isError,
    required bool isWarning,
    required bool isSuccess,
    required bool isAdjust,
    required String message,
  }) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

// Placeholder Cubits and States
class StudentDataCubit extends Cubit<StudentDataState> {
  StudentDataCubit() : super(GettingAllStudentsData());
  void loadStudents(List<StudentEntity> students) {
    emit(AllStudentsDataLoaded(students));
  }
}

abstract class StudentDataState {}

class GettingAllStudentsData extends StudentDataState {}

class AllStudentsDataLoaded extends StudentDataState {
  final List<StudentEntity> students;
  AllStudentsDataLoaded(this.students);
}

class GuardianCubit extends Cubit<GuardianState> {
  GuardianCubit() : super(GettingAllGuardian());
  Future<List<GuardianEntity>> getAllGuardian({
    required Map<String, dynamic> parameters,
  }) async {
    // Simulate fetching guardians
    emit(
      AllGuardianLoaded([
        GuardianEntity(
          id: 1,
          fullName: "Mary Doe",
          relation: "Mother",
          email: "mary.doe@example.com",
          phoneNumber: "1234567890",
          signInPin: 1234,
          photoUuid: "guardian_photo1",
        ),
      ]),
    );
    return [
      GuardianEntity(
        id: 1,
        fullName: "Mary Doe",
        relation: "Mother",
        email: "mary.doe@example.com",
        phoneNumber: "1234567890",
        signInPin: 1234,
        photoUuid: "guardian_photo1",
      ),
    ];
  }
}

abstract class GuardianState {}

class GettingAllGuardian extends GuardianState {}

class AllGuardianLoaded extends GuardianState {
  final List<GuardianEntity> guardians;
  AllGuardianLoaded(this.guardians);
}

class GuardianError extends GuardianState {
  final String message;
  GuardianError(this.message);
}

class AuthorizedPickupCubit extends Cubit<AuthorizedPickupState> {
  AuthorizedPickupCubit() : super(GettingAllAuthorizedPickup());
  void getAllAuthorizedPickup({required Map<String, dynamic> parameters}) {
    // Simulate fetching authorized pickups
    emit(
      AllAuthorizedPickupLoaded([
        AuthorizedPickupsEntity(
          firstName: "John",
          lastName: "Smith",
          relation: "Father",
          status: "A",
          phoneNumber: "9876543210",
          signInPin: 5678,
        ),
      ]),
    );
  }
}

abstract class AuthorizedPickupState {}

class GettingAllAuthorizedPickup extends AuthorizedPickupState {}

class AllAuthorizedPickupLoaded extends AuthorizedPickupState {
  final List<AuthorizedPickupsEntity> authorizedPickups;
  AllAuthorizedPickupLoaded(this.authorizedPickups);
}

class AuthorizedPickupError extends AuthorizedPickupState {
  final String message;
  AuthorizedPickupError(this.message);
}

class AddressCubit extends Cubit<AddressCubitState> {
  AddressCubit() : super(GettingAllAddress());
  void getAllAddress({required Map<String, dynamic> parameters}) {
    // Simulate fetching addresses
    emit(
      AllAddressDataLoaded([
        AddressEntity(
          line: "123 Main St",
          city: "Springfield",
          state: "IL",
          country: "USA",
          zipcode: "62701",
        ),
      ]),
    );
  }
}

abstract class AddressCubitState {}

class GettingAllAddress extends AddressCubitState {}

class AllAddressDataLoaded extends AddressCubitState {
  final List<AddressEntity> addresses;
  AllAddressDataLoaded(this.addresses);
}

class SiblingBloc extends Bloc<SiblingEvent, SiblingState> {
  SiblingBloc() : super(SiblingState()) {
    on<FetchSiblings>((event, emit) async {
      emit(state.copyWith(loading: true));
      // Simulate fetching siblings
      await Future.delayed(Duration(seconds: 1));
      emit(
        state.copyWith(
          loading: false,
          siblings: [
            Sibling(
              photoUuid: "photo456",
              fullName: "Jane Doe",
              gender: "Female",
              isSignedIn: false,
              isAbsent: false,
              profileStatus: "A",
            ),
          ],
        ),
      );
    });
  }
}

abstract class SiblingEvent {}

class FetchSiblings extends SiblingEvent {
  final int studentId;
  FetchSiblings(this.studentId);
}

class SiblingState {
  final bool loading;
  final List<Sibling> siblings;
  final String? error;

  SiblingState({this.loading = false, this.siblings = const [], this.error});

  SiblingState copyWith({
    bool? loading,
    List<Sibling>? siblings,
    String? error,
  }) {
    return SiblingState(
      loading: loading ?? this.loading,
      siblings: siblings ?? this.siblings,
      error: error ?? this.error,
    );
  }
}

class DocumentBloc extends Bloc<dynamic, dynamic> {
  DocumentBloc() : super(null);
}

// Placeholder widgets
class CustomRefreshIndicator extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;

  const CustomRefreshIndicator({
    Key? key,
    required this.onRefresh,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(onRefresh: onRefresh, child: child);
  }
}

class DocumentImageWidget extends StatelessWidget {
  final String fileUuid;
  final String? name;
  final double size;

  const DocumentImageWidget({
    Key? key,
    required this.fileUuid,
    this.name,
    required this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Colors.grey.shade300,
      child: Text(
        name?.isNotEmpty == true ? name![0] : 'S',
        style: TextStyle(fontSize: size / 2.5, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class ShimmerLoader extends StatelessWidget {
  final double height;

  const ShimmerLoader({Key? key, required this.height}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: Colors.grey[200],
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

// Placeholder for AppColors
class AppColors {
  static const Color themeColor = Colors.blue;
  static const Color primaryColor = Colors.blue;
  static const Color dividerColor = Colors.grey;
  static const Color classroomStudentTabColor = Color.fromRGBO(
    200,
    220,
    255,
    0.2,
  );
  static const Color classroomStaffTabColor = Color.fromRGBO(
    200,
    255,
    200,
    0.2,
  );
  static const Color classroomNotesTabColor = Color.fromRGBO(
    255,
    220,
    200,
    0.2,
  );
}

// Placeholder for MediaRes
class MediaRes {
  static const String userImageMale = 'assets/images/user_male.png';
}

// Main widget
class ProfileTabContent extends StatefulWidget {
  const ProfileTabContent({super.key, required this.student});

  final StudentEntity student;

  @override
  State<ProfileTabContent> createState() => _ProfileTabContentState();
}

class _ProfileTabContentState extends State<ProfileTabContent>
    with TickerProviderStateMixin {
  late TabController _tabControllerSecondary;
  List<GuardianEntity> guardianData = [];

  @override
  void initState() {
    super.initState();
    _tabControllerSecondary = TabController(length: 3, vsync: this);
    _fetchData();
    _tabControllerSecondary.addListener(() {
      setState(() {});
    });
  }

  void _fetchData() {
    StudentService.getAllStudents(context, id: widget.student.id);
    getAddressInfo();
    getFamilyInfo();
    getPickupInfo();
    _getGuardian();
  }

  void _onRefresh() {
    _fetchData();
    setState(() {});
  }

  @override
  void dispose() {
    _tabControllerSecondary.removeListener(() {
      setState(() {});
    });
    _tabControllerSecondary.dispose();
    super.dispose();
  }

  void getFamilyInfo() {
    Map<String, dynamic> parameters = {
      'studentId.equals': '${widget.student.id}',
      'size': '100',
      'page': '0',
      'sort': 'fullName,asc',
      'status.in': 'A',
      'schoolId.equals':
          '${context.read<CurrentStaffCubit?>()?.state?.schoolId ?? 0}',
    };
    context.read<GuardianCubit>().getAllGuardian(parameters: parameters);
  }

  void getPickupInfo() {
    Map<String, dynamic> parameters = {
      'studentId.equals': '${widget.student.id}',
      'size': '100',
      'page': '0',
      'sort': 'firstName,asc',
      'status.in': 'A',
      'schoolId.equals':
          '${context.read<CurrentStaffCubit?>()?.state?.schoolId ?? 0}',
    };
    context.read<AuthorizedPickupCubit>().getAllAuthorizedPickup(
      parameters: parameters,
    );
  }

  void getAddressInfo() {
    Map<String, dynamic> parameters = {
      'refTableId.equals': '${widget.student.id}',
      'refTable.equals': 'STUDENT',
      'size': '10',
      'page': '0',
      'sort': 'id,desc',
      'status.in': 'A',
      'schoolId.equals':
          '${context.read<CurrentStaffCubit?>()?.state?.schoolId ?? 0}',
    };
    context.read<AddressCubit>().getAllAddress(parameters: parameters);
  }

  void _getGuardian() async {
    Map<String, dynamic> guardianParameters = {
      "page": "0",
      'schoolId.equals':
          '${context.read<CurrentStaffCubit?>()?.state?.schoolId ?? 0}',
      "sort": "fullName,asc",
      "status.equals": "A",
      "studentId.equals": '${widget.student.id}',
      "size": "100",
    };

    List<GuardianEntity> allGuardian = await context
        .read<GuardianCubit>()
        .getAllGuardian(parameters: guardianParameters);
    setState(() {
      guardianData = allGuardian;
    });
  }

  String _formatAddress(AddressEntity address) {
    List<String> parts = [];
    if (address.line.trim().isNotEmpty) parts.add(address.line);
    if (address.city.trim().isNotEmpty) parts.add(address.city);
    if (address.state.trim().isNotEmpty) parts.add(address.state);
    if (address.country.trim().isNotEmpty) parts.add(address.country);
    if (address.zipcode.trim().isNotEmpty) parts.add(address.zipcode);
    return parts.join(", ");
  }

  String getGuardianNameById(String? ids) {
    if (ids == null || ids.trim().isEmpty) {
      return 'Child custody not selected';
    }

    try {
      final List<String> idList = ids
          .split(',')
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toList();
      if (idList.isEmpty) {
        return 'Child custody not selected';
      }

      final guardians = guardianData
          .where((guardian) => idList.contains(guardian.id.toString()))
          .toList();

      if (guardians.isNotEmpty) {
        return guardians.map((guardian) => guardian.fullName).join(', ');
      } else {
        return 'Child custody not selected';
      }
    } catch (e, stackTrace) {
      debugPrint('Error in getGuardianNameById: $e\n$stackTrace');
      return 'Failed to load guardians';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabControllerSecondary,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildProfileInfo(),
              _buildFamilyContent(),
              _buildPickupContent(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Transform.translate(
      offset: const Offset(0, 6),
      child: TabBar(
        controller: _tabControllerSecondary,
        labelStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: AppColors.primaryColor,
          fontSize: 14,
        ),
        unselectedLabelStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: AppColors.primaryColor.withOpacity(0.5),
          fontSize: 14,
        ),
        indicatorPadding: _tabControllerSecondary.index == 0
            ? const EdgeInsets.only(right: 8)
            : _tabControllerSecondary.index == 1
            ? const EdgeInsets.symmetric(horizontal: 4)
            : const EdgeInsets.only(left: 8),
        labelPadding: EdgeInsets.zero,
        dividerHeight: 0,
        indicator: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          border: Border.all(
            color: AppColors.classroomStudentTabColor.withOpacity(1),
          ),
        ),
        tabs: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildTab(
              label: 'About',
              color: AppColors.classroomStudentTabColor,
              index: 0,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildTab(
              label: 'Family',
              color: AppColors.classroomStaffTabColor,
              index: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: _buildTab(
              label: 'Pickup',
              color: AppColors.classroomNotesTabColor,
              index: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab({
    required String label,
    required Color color,
    required int index,
  }) {
    return Tab(
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        ),
        child: Center(child: Text(label, maxLines: 1)),
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Stack(
      children: [
        Card(
          elevation: 0,
          margin: const EdgeInsets.all(0),
          shape: const RoundedRectangleBorder(
            side: BorderSide(color: AppColors.themeColor),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(12),
            child: CustomRefreshIndicator(
              onRefresh: () async => _onRefresh(),
              child: SingleChildScrollView(
                child: BlocBuilder<StudentDataCubit, StudentDataState>(
                  builder: (context, state) {
                    if (state is AllStudentsDataLoaded) {
                      final currentStudent = state.students.firstWhere(
                        (student) => student.id == widget.student.id,
                        orElse: () => widget.student,
                      );
                      currentStudent.tags.sort(
                        (a, b) => a.name.compareTo(b.name),
                      );
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoItem('Name', currentStudent.fullName, true),
                          _buildDivider(),
                          _buildStatusItem(
                            'Status',
                            currentStudent.profileStatus,
                          ),
                          _buildDivider(),
                          _buildInfoItem(
                            'Classroom',
                            currentStudent.roomName,
                            false,
                          ),
                          _buildDivider(),
                          _buildTagsItem('Tags', currentStudent.tags),
                          _buildDivider(),
                          _buildInfoItem(
                            'Birthdate',
                            currentStudent.dateOfBirth,
                            false,
                            isDateOfBirth: true,
                          ),
                          _buildDivider(),
                          _buildInfoItem('Notes', currentStudent.note, false),
                          _buildDivider(),
                          _buildInfoItem(
                            'Child Custody',
                            getGuardianNameById(currentStudent.childCustody),
                            false,
                          ),
                          _buildDivider(),
                          _buildInfoItem(
                            'State Subsidy',
                            currentStudent.isStateSubsidyAllowed
                                ? 'Yes'
                                : 'No State Subsidy',
                            false,
                          ),
                          _buildDivider(),
                          _buildAddressInfo('Address'),
                          _buildDivider(),
                          _buildSiblingItem(
                            context,
                            "Siblings",
                            widget.student.id,
                          ),
                          _buildDivider(),
                          _buildScheduleItem(currentStudent.schedule),
                          if (currentStudent.profileStatus.isNotEmpty &&
                              currentStudent.profileStatus == 'A') ...[
                            _buildDivider(),
                            currentStudent.expectedMoveDate != null
                                ? _buildUpcomingMoveItem(
                                        currentStudent.expectedMoveDate!,
                                      ) ??
                                      const SizedBox(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Upcoming Move',
                                              style: TextStyle(
                                                color: Color.fromARGB(
                                                  255,
                                                  158,
                                                  158,
                                                  158,
                                                ),
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              'No Movement Date',
                                              style: TextStyle(fontSize: 16),
                                            ),
                                          ],
                                        ),
                                      )
                                : const SizedBox(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Upcoming Move',
                                          style: TextStyle(
                                            color: Color.fromARGB(
                                              255,
                                              158,
                                              158,
                                              158,
                                            ),
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          'No Movement Date',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                          ],
                          if (currentStudent.profileStatus.isNotEmpty &&
                              currentStudent.profileStatus == 'I') ...[
                            _buildDivider(),
                            _buildSchoolLeavingDate(
                              currentStudent.leavingDate ??
                                  DateTime.now().toIso8601String(),
                            ),
                          ],
                          if (currentStudent.profileStatus.isNotEmpty &&
                              currentStudent.profileStatus == 'Upcoming') ...[
                            _buildDivider(),
                            _buildSchoolStartDate(
                              currentStudent.startDate ??
                                  DateTime.now().toIso8601String(),
                            ),
                          ],
                        ],
                      );
                    } else if (state is GettingAllStudentsData) {
                      return const ShimmerLoader(height: 400);
                    }
                    return const Text('Error fetching student data');
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(
    String label,
    String value,
    bool editable, {
    bool isDateOfBirth = false,
  }) {
    String displayValue = value;

    if (isDateOfBirth) {
      try {
        final DateTime dob = DateTime.parse(value);
        final String month = _getMonthAbbreviation(dob.month);
        final String formattedDate = "$month ${dob.day}, ${dob.year}";

        final DateTime now = DateTime.now();
        int years = now.year - dob.year;
        int months = now.month - dob.month;

        if (months < 0 || (months == 0 && now.day < dob.day)) {
          years--;
          months += 12;
        }

        if (months == 0 && now.day < dob.day) {
          months = 11;
        }

        String ageString = "";
        if (years > 0) {
          ageString += "$years ${years == 1 ? 'year' : 'years'}";
          if (months > 0) {
            ageString += " $months ${months == 1 ? 'month' : 'months'}";
          }
        } else {
          ageString = "$months ${months == 1 ? 'month' : 'months'}";
        }

        displayValue = "$formattedDate ($ageString)";
      } catch (e) {
        displayValue = value;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                displayValue.trim().isNotEmpty ? displayValue : '- -',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getMonthAbbreviation(int month) {
    const List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  Widget _buildStatusItem(String label, String status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        const SizedBox(height: 4),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: status == 'A'
                    ? Colors.green[50]
                    : status == 'Upcoming'
                    ? const Color.fromRGBO(255, 245, 230, 1)
                    : status == 'I'
                    ? const Color.fromRGBO(255, 236, 236, 1)
                    : Colors.grey,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Text(
                    status == 'A'
                        ? 'Active'
                        : status == 'Upcoming'
                        ? 'Upcoming'
                        : status == 'I'
                        ? 'Inactive'
                        : '',
                    style: TextStyle(
                      color: status == 'A'
                          ? const Color.fromRGBO(55, 200, 32, 1)
                          : status == 'Upcoming'
                          ? const Color.fromARGB(255, 246, 184, 91)
                          : status == 'I'
                          ? const Color.fromARGB(255, 239, 5, 5)
                          : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (status == 'A')
                    const Icon(
                      Icons.check_circle,
                      color: Color.fromRGBO(55, 200, 32, 1),
                      size: 16,
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTagsItem(String label, List<TagModel> tags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
        tags.isEmpty
            ? const Text(
                '- -',
                style: TextStyle(fontSize: 16, color: Colors.black54),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tags.map((tag) {
                      final index = tags.indexOf(tag);
                      final colorIndex = index % 3;

                      Color backgroundColor;
                      Color textColor;

                      switch (colorIndex) {
                        case 0:
                          backgroundColor = Colors.purple[50]!;
                          textColor = Colors.purple;
                          break;
                        case 1:
                          backgroundColor = Colors.blue[50]!;
                          textColor = Colors.blue;
                          break;
                        case 2:
                          backgroundColor = Colors.green[50]!;
                          textColor = Colors.green;
                          break;
                        default:
                          backgroundColor = Colors.grey[50]!;
                          textColor = Colors.grey;
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          tag.name,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
      ],
    );
  }

  Widget _buildSiblingItem(BuildContext context, String label, int studentId) {
    return BlocProvider(
      create: (context) => SiblingBloc()..add(FetchSiblings(studentId)),
      child: BlocBuilder<SiblingBloc, SiblingState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error != null) {
            return Text(
              'Error: ${state.error}',
              style: const TextStyle(color: Colors.red, fontSize: 14),
            );
          }

          final siblings = state.siblings;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              siblings.isEmpty
                  ? const Text(
                      '- -',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    )
                  : BlocProvider(
                      create: (context) => DocumentBloc(),
                      child: Wrap(
                        spacing: 16.0,
                        runSpacing: 12.0,
                        children: siblings.map<Widget>((sibling) {
                          final String fileUuid =
                              sibling.photoUuid ??
                              'https://placehold.co/100x100';
                          final String fullName = sibling.fullName;
                          final String relation = sibling.gender == 'Male'
                              ? ' (Brother)'
                              : sibling.gender == 'Female'
                              ? ' (Sister)'
                              : '';
                          final bool isSignedIn = sibling.isSignedIn ?? false;
                          final bool isAbsent = sibling.isAbsent ?? false;
                          final String profileStatus =
                              sibling.profileStatus ?? 'Unknown';

                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                children: [
                                  DocumentImageWidget(
                                    fileUuid: fileUuid,
                                    name: fullName,
                                    size: 32,
                                  ),
                                  if (isSignedIn ||
                                      isAbsent ||
                                      profileStatus == 'A')
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: profileStatus == 'A'
                                              ? const Color(0xFF00B115)
                                              : isSignedIn
                                              ? const Color(0xFF00B115)
                                              : isAbsent
                                              ? const Color(0xFFC82020)
                                              : Colors.transparent,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fullName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (relation.isNotEmpty)
                                      Text(
                                        relation,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildScheduleItem(List<ScheduleEntity> schedule) {
    Map<String, Map<String, String>> scheduleByDay = {
      'Monday': {'isActive': 'false', 'hours': ''},
      'Tuesday': {'isActive': 'false', 'hours': ''},
      'Wednesday': {'isActive': 'false', 'hours': ''},
      'Thursday': {'isActive': 'false', 'hours': ''},
      'Friday': {'isActive': 'false', 'hours': ''},
    };

    for (ScheduleEntity scheduleItem in schedule) {
      String day = scheduleItem.day;
      if (scheduleByDay.containsKey(day) && scheduleItem.status == 'A') {
        String startTime = scheduleItem.startTime;
        String endTime = scheduleItem.endTime;

        scheduleByDay[day] = {
          'isActive': 'true',
          'hours': '${_formatTime(startTime)} -\n${_formatTime(endTime)}',
        };
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Schedule',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
          child: Row(
            children: [
              _buildScheduleDay(
                'Monday',
                scheduleByDay['Monday']!['isActive'] == 'true',
                scheduleByDay['Monday']!['isActive'] == 'true'
                    ? scheduleByDay['Monday']!['hours']
                    : null,
              ),
              _buildScheduleDay(
                'Tuesday',
                scheduleByDay['Tuesday']!['isActive'] == 'true',
                scheduleByDay['Tuesday']!['isActive'] == 'true'
                    ? scheduleByDay['Tuesday']!['hours']
                    : null,
              ),
              _buildScheduleDay(
                'Wednesday',
                scheduleByDay['Wednesday']!['isActive'] == 'true',
                scheduleByDay['Wednesday']!['isActive'] == 'true'
                    ? scheduleByDay['Wednesday']!['hours']
                    : null,
              ),
              _buildScheduleDay(
                'Thursday',
                scheduleByDay['Thursday']!['isActive'] == 'true',
                scheduleByDay['Thursday']!['isActive'] == 'true'
                    ? scheduleByDay['Thursday']!['hours']
                    : null,
              ),
              _buildScheduleDay(
                'Friday',
                scheduleByDay['Friday']!['isActive'] == 'true',
                scheduleByDay['Friday']!['isActive'] == 'true'
                    ? scheduleByDay['Friday']!['hours']
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleDay(String day, bool isActive, String? hours) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              decoration: BoxDecoration(
                color: isActive ? Colors.blue[100] : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                day,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isActive ? Colors.indigo[800] : Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              decoration: BoxDecoration(
                color: isActive ? Colors.blue[50] : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                hours ?? '',
                style: TextStyle(
                  fontSize: 10,
                  color: isActive ? Colors.indigo[700] : Colors.transparent,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String timeString) {
    try {
      if (timeString.contains('AM') || timeString.contains('PM')) {
        if (timeString.contains(':00 ')) {
          return timeString.replaceAll(':00 ', ' ');
        }
        return timeString;
      }

      final parts = timeString.split(':');
      int hour = int.parse(parts[0]);
      final minutes = parts[1];
      final period = hour >= 12 ? 'PM' : 'AM';

      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;

      return '$hour:$minutes$period';
    } catch (e) {
      return timeString;
    }
  }

  bool _isUpcomingDate(String movementDate) {
    try {
      DateTime moveDate = DateTime.parse(movementDate);
      DateTime today = DateTime.now();
      DateTime todayDateOnly = DateTime(today.year, today.month, today.day);
      DateTime moveDateOnly = DateTime(
        moveDate.year,
        moveDate.month,
        moveDate.day,
      );
      return moveDateOnly.isAfter(todayDateOnly) ||
          moveDateOnly.isAtSameMomentAs(todayDateOnly);
    } catch (e) {
      return false;
    }
  }

  Widget? _buildUpcomingMoveItem(
    String movementDate, {
    String fromClass = '1-Blue-D',
    String toClass = '2-Green-D',
  }) {
    if (!_isUpcomingDate(movementDate)) {
      return null;
    }

    DateTime moveDate;
    try {
      moveDate = DateTime.parse(movementDate);
    } catch (e) {
      moveDate = DateTime.now();
    }

    final String year = moveDate.year.toString();
    final String month = _getMonthAbbreviation(moveDate.month);
    final String day = moveDate.day.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Move',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Text(
                month,
                style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              ),
              const SizedBox(width: 3),
              Text(
                "$day,",
                style: const TextStyle(
                  fontSize: 15,
                  color: Color.fromRGBO(117, 117, 117, 1),
                ),
              ),
              const SizedBox(width: 3),
              Text(
                year,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color.fromRGBO(117, 117, 117, 1),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSchoolLeavingDate(String leavingDate) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(leavingDate);
    } catch (e) {
      parsedDate = DateTime.now();
    }

    final String formattedDate = _formatDateToLongForm(parsedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'School Leaving Date',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          formattedDate,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSchoolStartDate(String startDate) {
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(startDate);
    } catch (e) {
      parsedDate = DateTime.now();
    }

    final String formattedDate = _formatDateToLongForm(parsedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'School Start Date',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          formattedDate,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatDateToLongForm(DateTime date) {
    final List<String> months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final String month = months[date.month - 1];
    final String day = date.day.toString();
    final String year = date.year.toString();
    return '$month $day, $year';
  }

  Widget _buildFamilyContent() {
    return BlocConsumer<GuardianCubit, GuardianState>(
      listener: (context, state) {
        if (state is GuardianError) {
          CoreUtils.showTopSnackBar(
            context: context,
            isError: true,
            isWarning: false,
            isSuccess: false,
            isAdjust: false,
            message: 'Guardian Error: ${state.message}',
          );
        }
      },
      builder: (context, state) {
        if (state is AllGuardianLoaded) {
          final List<GuardianEntity> guardians = state.guardians;

          if (guardians.isEmpty) {
            return Card(
              elevation: 0,
              margin: const EdgeInsets.all(0),
              shape: const RoundedRectangleBorder(
                side: BorderSide(color: AppColors.themeColor),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: CustomRefreshIndicator(
                onRefresh: () async => _onRefresh(),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return ListView(
                      children: [
                        SizedBox(
                          height: constraints.maxHeight,
                          child: Center(
                            child: Text(
                              'No Guardians Added',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.primaryColor.withOpacity(0.6),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          }
          return CustomRefreshIndicator(
            onRefresh: () async => _onRefresh(),
            child: SingleChildScrollView(
              child: Column(
                children: guardians.map((guardian) {
                  return Column(
                    children: [
                      _buildFamilyMemberCard(
                        name: guardian.fullName,
                        relation: guardian.relation,
                        email: guardian.email,
                        phoneNumber: guardian.phoneNumber,
                        pin: guardian.signInPin.toString(),
                        avatarUrl: guardian.photoUuid,
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        } else if (state is GettingAllGuardian) {
          return const ShimmerLoader(height: 400);
        }
        return CustomRefreshIndicator(
          onRefresh: () async => _onRefresh(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ListView(
                children: [
                  SizedBox(
                    height: constraints.maxHeight,
                    child: Center(
                      child: Text(
                        'No Guardians Added',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.primaryColor.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFamilyMemberCard({
    required String name,
    required String relation,
    required String email,
    required String phoneNumber,
    required String pin,
    required String avatarUrl,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(0),
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: AppColors.themeColor),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          children: [
            Row(
              children: [
                BlocProvider(
                  create: (context) => DocumentBloc(),
                  child: DocumentImageWidget(
                    fileUuid: avatarUrl,
                    name: name,
                    size: 40,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(height: 32, color: AppColors.dividerColor),
            _buildInfoRow("Relation", relation),
            const SizedBox(height: 16),
            _buildInfoRow("Email ID", email),
            const SizedBox(height: 16),
            _buildInfoRow(
              "Phone Number",
              CoreUtils.formatPhoneNumber(phoneNumber),
            ),
            const SizedBox(height: 16),
            _buildInfoRow("Sign-in Pin", pin),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressInfo(String label) {
    return BlocConsumer<AddressCubit, AddressCubitState>(
      listener: (context, state) {},
      builder: (context, state) {
        if (state is AllAddressDataLoaded) {
          final List<AddressEntity> addresses = state.addresses.isEmpty
              ? []
              : state.addresses;
          if (addresses.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
                const SizedBox(height: 4),
                const Row(
                  children: [
                    Expanded(
                      child: Text('- -', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey[500], fontSize: 14),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatAddress(addresses.first),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
            const SizedBox(height: 4),
            const Row(
              children: [
                Expanded(child: Text('- -', style: TextStyle(fontSize: 16))),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildPickupContent() {
    return BlocConsumer<AuthorizedPickupCubit, AuthorizedPickupState>(
      listener: (context, state) {
        if (state is AuthorizedPickupError) {
          CoreUtils.showTopSnackBar(
            context: context,
            isError: true,
            isWarning: false,
            isSuccess: false,
            isAdjust: false,
            message: 'Authorized Pickup Error: ${state.message}',
          );
        }
      },
      builder: (context, state) {
        if (state is AllAuthorizedPickupLoaded) {
          final List<AuthorizedPickupsEntity> authorizedPickups =
              state.authorizedPickups;
          if (authorizedPickups.isEmpty) {
            return Card(
              elevation: 0,
              margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              shape: const RoundedRectangleBorder(
                side: BorderSide(color: AppColors.themeColor),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: CustomRefreshIndicator(
                onRefresh: () async => _onRefresh(),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return ListView(
                      children: [
                        SizedBox(
                          height: constraints.maxHeight,
                          child: Center(
                            child: Text(
                              'No Authorized Pickup Available',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.primaryColor.withOpacity(0.6),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          }
          return CustomRefreshIndicator(
            onRefresh: () async => _onRefresh(),
            child: SingleChildScrollView(
              child: Column(
                children: authorizedPickups.map((authorizedPickup) {
                  return Column(
                    children: [
                      _buildPickupCard(
                        name: authorizedPickup.firstName,
                        lastName: authorizedPickup.lastName,
                        relation: authorizedPickup.relation,
                        email: authorizedPickup.status,
                        phoneNumber: authorizedPickup.phoneNumber,
                        pin: authorizedPickup.signInPin.toString(),
                        avatarUrl: authorizedPickup.status,
                        signInPin: authorizedPickup.signInPin,
                      ),
                      const SizedBox(height: 12),
                    ],
                  );
                }).toList(),
              ),
            ),
          );
        } else if (state is GettingAllAuthorizedPickup) {
          return const ShimmerLoader(height: 400);
        }
        return CustomRefreshIndicator(
          onRefresh: () async => _onRefresh(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ListView(
                children: [
                  SizedBox(
                    height: constraints.maxHeight,
                    child: Center(
                      child: Text(
                        'No Authorized Pickup Available',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.primaryColor.withOpacity(0.6),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPickupCard({
    required String name,
    required String relation,
    required String email,
    required String phoneNumber,
    required String pin,
    required String avatarUrl,
    required String lastName,
    required int signInPin,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.all(0),
      shape: const RoundedRectangleBorder(
        side: BorderSide(color: AppColors.themeColor),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundImage: AssetImage(MediaRes.userImageMale),
                ),
                const SizedBox(width: 12),
                Text(
                  '$name $lastName',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const Divider(height: 32, color: AppColors.dividerColor),
            _buildInfoRow("Relation", relation),
            const SizedBox(height: 16),
            _buildInfoRow(
              "Phone Number",
              CoreUtils.formatPhoneNumber(phoneNumber),
            ),
            const SizedBox(height: 16),
            _buildInfoRow("Sign-in Pin", pin),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const SizedBox(height: 24);
  }
}

// Placeholder for CurrentStaffCubit
class CurrentStaff {
  final int schoolId;

  CurrentStaff({required this.schoolId});
}

class CurrentStaffCubit extends Cubit<CurrentStaff?> {
  CurrentStaffCubit() : super(null);
  void setStaff(CurrentStaff staff) => emit(staff);
}
