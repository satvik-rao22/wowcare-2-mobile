// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:schoolerp/core/util/api_paths.dart';
// import 'package:schoolerp/core/util/constants.dart';
// import 'package:schoolerp/core/util/core_utils.dart';
// import 'package:schoolerp/core/util/typedefs.dart';
// import 'package:schoolerp/features/student/domain/entities/studentData.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';

// import '../../../../../../features/student/data/model/studentDataModel.dart';

// part 'napping_students_state.dart';

// class NappingStudentsCubit extends Cubit<NappingStudentsState> {
//   NappingStudentsCubit() : super(NappingStudentsInitial());

//   Future<void> fetchNappingStudents(int roomId, int schoolId) async {
//     emit(NappingStudentsLoading());

//     try {
//       final prefs = await SharedPreferences.getInstance();
//       // NOTE: Auth token is intentionally NOT used here. We only send basic JSON
//       // headers so this API is called without Authorization.
//       final headers = {
//         'Content-Type': 'application/json',
//       };
//       String path = APIPathHelper.getValue(APIPath.studentsByRoom);
//       final url = Uri.parse('$baseUrl$path/$roomId');
//       var request = http.Request('GET', url);
//       // var request = http.Request(
//       //     'GET',
//       //     Uri.parse(
//       //         'https://qa.childcarewow.app/wowcare-qa/api/students-by-room/$roomId'));

//       request.headers.addAll(headers);

//       http.StreamedResponse response = await request.send();

//       if (response.statusCode == 200) {
//         final responseBody = await response.stream.bytesToString();
//         final List<dynamic> data = jsonDecode(responseBody);
//         List<StudentEntity> nappingStudents = data
//             .where((student) {
//               final activities =
//                   (student['activities'] as List<dynamic>?) ?? [];
//               if (activities.isEmpty) return false;

//               activities.sort((a, b) => DateTime.parse(b['date'])
//                   .compareTo(DateTime.parse(a['date'])));
//               final latestActivity = activities.first['name'];
//               return latestActivity == 'NAP START' &&
//                   !activities.any((act) =>
//                       act['name'] == 'NAP END' &&
//                       DateTime.parse(act['date'])
//                           .isAfter(DateTime.parse(activities.first['date'])));
//             })
//             .map((student) => StudentEntity(
//                   id: student['id'],
//                   fullName: student['fullName'],
//                   photoUuid: '',
//                   gender: null,
//                   bloodGroup: null,
//                   studentUniqueId: '',
//                   dateOfBirth: '',
//                   isSignedIn: student['isPresentToday'],
//                   isAbsent: !student['isPresentToday'],
//                   isExpectedToday: student['isPresentToday'],
//                   isPresentToday: student['isPresentToday'],
//                   napStartOrEnd: '',
//                   movementDate: '',
//                   studentFte: null,
//                   foodProgram: null,
//                   isPhotoPermission: false,
//                   registrationDate: '',
//                   leavingDate: null,
//                   roomStartDate: null,
//                   profileStatus: student['isPresentToday'] ? 'A' : 'Upcoming',
//                   allergies: '',
//                   medications: '',
//                   dietRestriction: '',
//                   note: '',
//                   roomId: roomId,
//                   status: 'A',
//                   schoolId: schoolId,
//                   lastModified: '',
//                   lastModifiedBy: '',
//                   hasPrivateChat: false,
//                   isTagRemoved: null,
//                   privatedByGuardian: null,
//                   subsidyInvoiced: 0.0,
//                   subsidyBalance: 0.0,
//                   subsidyReceived: 0.0,
//                   childCustody: null,
//                   startDate: null,
//                   expectedMoveDate: null,
//                   isStateSubsidyAllowed: null,
//                   tags: [],
//                   siblings: [],
//                   activities: (student['activities'] as List<dynamic>?)
//                           ?.map((act) => ActivityModel(
//                                 lastModified: '',
//                                 lastModifiedBy: '',
//                                 schoolId: schoolId,
//                                 id: 0,
//                                 date: act['date'],
//                                 description: '',
//                                 activityNote: act['activityNote'] ?? '',
//                                 hasStaffOnly: false,
//                                 isDiaperCreamApplied: false,
//                                 time: act['time'],
//                                 hasParentNotify: false,
//                                 activityRefValue1: '',
//                                 activityRefValue2: '',
//                                 activityRefValue3: '',
//                                 activityTypeId: 0,
//                                 staffId: 0,
//                                 status: 'A',
//                                 activityStatus: act['activityStatus'],
//                                 photoUuid: null,
//                                 roomId: roomId,
//                                 students: null,
//                                 absent: null,
//                                 attendance: 0,
//                               ))
//                           .toList() ??
//                       [],
//                   schedule: [],
//                   transactions: [],
//                   programRoom: null,
//                   openBalance: 0.0,
//                   roomName: '',
//                   invoice: [],
//                   students: [],
//                   recurringPlan: [],
//                 ))
//             .toList();

//         emit(NappingStudentsLoaded(nappingStudents));
//       } else {
//         emit(NappingStudentsError(
//             'Failed to fetch napping students: ${response.reasonPhrase}'));
//       }
//     } catch (e) {
//       emit(NappingStudentsError('Error fetching napping students: $e'));
//     }
//   }
// }
