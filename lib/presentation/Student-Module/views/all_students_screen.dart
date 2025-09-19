// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:schoolerp/core/common/widgets/custom_checkbox.dart';
// import 'package:schoolerp/core/common/widgets/custom_chip.dart';
// import 'package:schoolerp/core/common/widgets/custom_clear_all_chip.dart';
// import 'package:schoolerp/core/common/widgets/custom_scaffold.dart';
// import 'package:schoolerp/src/attendance/presentation/views/screens/attendance_tabbed_view.dart';
// import 'package:schoolerp/core/common/widgets/custom_search_bar.dart';
// import 'package:schoolerp/core/common/widgets/custom_shimmer_loader.dart';
// import 'package:schoolerp/core/common/widgets/custom_stat_bar_card.dart';
// import 'package:schoolerp/core/common/widgets/custom_toggle.dart';
// import 'package:schoolerp/core/extentions/context_extentions.dart';
// import 'package:schoolerp/core/helpers/filter_data_helper.dart';
// import 'package:schoolerp/core/helpers/progress_item_helper.dart';
// import 'package:schoolerp/core/res/colors.dart';
// import 'package:schoolerp/core/res/media_res.dart';
// import 'package:schoolerp/core/services/api_services/room_data_service.dart';
// import 'package:schoolerp/core/services/api_services/student_service.dart';
// import 'package:schoolerp/core/services/injection_container.dart';
// import 'package:schoolerp/core/util/core_utils.dart';
// import 'package:schoolerp/features/Tags/presentation/cubit/tag_data_cubit.dart';
// import 'package:schoolerp/features/classroom/presentation/cubit/classroom_cubit.dart';
// import 'package:schoolerp/features/dailyActivity/presentation/cubit/daily_activity_cubit.dart';
// import 'package:schoolerp/features/guardian/domain/entities/guardianData.dart';
// import 'package:schoolerp/features/guardian/presentaion/cubit/guardian_cubit.dart';
// import 'package:schoolerp/features/masterLookup/presentation/cubit/masterlookup_cubit.dart';
// import 'package:schoolerp/features/roomsdata/presentation/cubit/cubit/roomdata_cubit.dart';
// import 'package:schoolerp/features/student/domain/entities/studentData.dart';
// import 'package:schoolerp/features/student/presentation/cubit/student_data_cubit.dart';
// import 'package:schoolerp/features/user/domain/entities/staff.dart';
// import 'package:schoolerp/features/user/presentation/cubit/staff_cubit.dart';
// import 'package:schoolerp/src/classroom/presentation/widgets/attendance_activity_panel.dart';
// import 'package:schoolerp/src/communication/presentation/messaging/views/create_message_screen.dart';
// import 'package:schoolerp/src/communication/presentation/messaging/views/send_parent_message_screen.dart';
// import 'package:schoolerp/src/student/presentation/views/add_student_screen.dart';
// import 'package:schoolerp/src/student/presentation/views/all_students_filter_screen.dart';
// import 'package:schoolerp/src/student/presentation/widgets/all_students_list_item.dart';
// import 'package:schoolerp/core/common/widgets/custom_floating_action_button.dart';
// import 'package:schoolerp/src/student/presentation/widgets/student_card.dart';
// import 'package:schoolerp/src/attendance/presentation/views/screens/attendance_daily_view.dart';
// import 'package:intl/intl.dart';
// import 'package:schoolerp/core/common/app/providers/auth_providers.dart';
// import 'package:schoolerp/features/schoolData/data/datasource/schooldata_remote_datasource.dart';

// class AllStudentsScreen extends StatefulWidget {
//   final String? incomingFilter;

//   const AllStudentsScreen({
//     super.key,
//     this.incomingFilter,
//   });

//   static const String routeName = '/all-students-screen';

//   @override
//   State<AllStudentsScreen> createState() => _AllStudentsScreenState();
// }

// class _AllStudentsScreenState extends State<AllStudentsScreen> {
//   final TextEditingController _studentSearchController =
//       TextEditingController();
//   bool isShowInactiveToggled = false;
//   bool isSelectAllChecked = false;
//   List<StudentEntity> allStudents = [];
//   List<StudentEntity> visibleStudents = [];
//   Map<int, bool> studentSelections = {};
//   String searchQuery = '';
//   bool _isFiltering = false;
//   bool _isLoadingSchoolData = false;
//   String? _schoolDataError;

//   // School data totals
//   int _enrolledStudents = 0;
//   int _activeStudents = 0;
//   int _upcomingStudents = 0;
//   int _expectedStudents = 0;
//   int _presentStudents = 0;
//   int _absentStudents = 0;

//   FilterData appliedFilters = FilterData(
//     classroomIds: [],
//     classrooms: [],
//     statuses: [],
//     tags: [],
//     tagIds: [],
//   );

//   Map<String, String> statusDisplayToCode = {
//     'Active': 'A',
//     'Inactive': 'I',
//     'Upcoming': 'Upcoming',
//   };

//   @override
//   void initState() {
//     super.initState();
//     StudentService.getAllStudents(context);
//     _fetchSchoolData();
//     _studentSearchController.addListener(_onSearchChanged);
//     if (widget.incomingFilter != null) {
//       appliedFilters = appliedFilters.copyWith(
//         statuses: [widget.incomingFilter!],
//       );
//       if (widget.incomingFilter == 'Inactive') {
//         isShowInactiveToggled = true;
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _studentSearchController.removeListener(_onSearchChanged);
//     _studentSearchController.dispose();
//     super.dispose();
//   }

//   Future<void> _fetchSchoolData() async {
//     try {
//       setState(() {
//         _isLoadingSchoolData = true;
//         _schoolDataError = null;
//       });
//       final schoolId = AuthProvider.userSchool.id;
//       final schoolData =
//           await SchoolDataRemoteDataSourceImpl().getSchoolData(schoolId);
//       setState(() {
//         _enrolledStudents = schoolData.totalStudents; // 119
//         _activeStudents =
//             schoolData.activeStudents.clamp(0, schoolData.totalStudents); // 110
//         _upcomingStudents =
//             schoolData.upcomingStudents.clamp(0, schoolData.totalStudents); // 9
//         _expectedStudents = schoolData.expectedStudent;
//         _presentStudents = schoolData.presentStudent;
//         _absentStudents = schoolData.absentStudent;
//         _isLoadingSchoolData = false;
//       });
//       print(
//           'School Data: enrolledStudents=$_enrolledStudents, activeStudents=$_activeStudents, upcomingStudents=$_upcomingStudents');
//     } catch (e) {
//       setState(() {
//         _isLoadingSchoolData = false;
//         _schoolDataError = 'Error fetching school statistics';
//       });
//     }
//   }

//   String _formatMovementDate(dynamic movementDate) {
//     if (movementDate == null || movementDate.toString().isEmpty) {
//       return '-';
//     }
//     try {
//       final date = DateTime.parse(movementDate.toString());
//       return DateFormat('MMM dd, yyyy').format(date);
//     } catch (_) {
//       return movementDate.toString();
//     }
//   }

//   int _getCommonRoomId() {
//     final selected = _getSelectedStudents();
//     if (selected.isEmpty) {
//       return 0;
//     }
//     final firstRoomId = selected.first.roomId;
//     final allShareSameRoom = selected.every((s) => s.roomId == firstRoomId);
//     return allShareSameRoom ? firstRoomId : 0;
//   }

//   bool get hasSelectedStudents =>
//       studentSelections.values.any((selected) => selected);

//   List<StudentEntity> _getSelectedStudents() {
//     return allStudents
//         .where((student) => studentSelections[student.id] == true)
//         .toList();
//   }

//   void _onSearchChanged() {
//     setState(() {
//       searchQuery = _studentSearchController.text.toLowerCase();
//       isSelectAllChecked = false;
//     });
//     Future.delayed(const Duration(milliseconds: 50), () {
//       if (mounted) {
//         _filterStudents();
//       }
//     });
//   }

//   void _toggleShowInactive(bool value) {
//     setState(() {
//       isSelectAllChecked = false;
//       isShowInactiveToggled = value;
//       if (value) {
//         appliedFilters = appliedFilters.copyWith(statuses: ['Inactive']);
//       } else {
//         appliedFilters = appliedFilters.copyWith(statuses: []);
//       }
//     });
//     Future.delayed(const Duration(milliseconds: 50), () {
//       if (mounted) {
//         _filterStudents();
//       }
//     });
//   }

//   void _filterStudents() {
//     if (_isFiltering) {
//       debugPrint('_filterStudents already running, skipping...');
//       return;
//     }
//     _isFiltering = true;
//     List<StudentEntity> filteredStudents = allStudents;
//     debugPrint(
//         '_filterStudents called with ${appliedFilters.statuses.length} status filters');
//     debugPrint('Status filters: ${appliedFilters.statuses}');
//     debugPrint('isShowInactiveToggled: $isShowInactiveToggled');
//     debugPrint('Total students available: ${allStudents.length}');

//     if (allStudents.isNotEmpty) {
//       final sampleStatuses =
//           allStudents.take(5).map((s) => s.profileStatus).toSet();
//       debugPrint('Sample student profile statuses: $sampleStatuses');
//     }

//     if (appliedFilters.statuses.isNotEmpty) {
//       debugPrint('Applying status filters: ${appliedFilters.statuses}');
//       debugPrint('statusDisplayToCode mapping: $statusDisplayToCode');
//       filteredStudents = filteredStudents.where((student) {
//         final mappedStatuses = appliedFilters.statuses
//             .map((status) => statusDisplayToCode[status] ?? status)
//             .toList();
//         debugPrint(
//             'Mapped statuses: $mappedStatuses, student profileStatus: ${student.profileStatus}');
//         final isMatch = mappedStatuses.contains(student.profileStatus);
//         debugPrint(
//             'Student ${student.fullName} (${student.profileStatus}) matches filter: $isMatch');
//         return isMatch;
//       }).toList();
//       debugPrint('After status filtering: ${filteredStudents.length} students');
//     } else if (isShowInactiveToggled) {
//       debugPrint('Showing inactive students (isShowInactiveToggled: true)');
//       filteredStudents = filteredStudents
//           .where((student) => student.profileStatus == 'I')
//           .toList();
//       debugPrint(
//           'After inactive filtering: ${filteredStudents.length} students');
//     } else {
//       debugPrint(
//           'Showing active students by default (no status filters, isShowInactiveToggled: false)');
//       filteredStudents = filteredStudents
//           .where((student) => student.profileStatus == 'A')
//           .toList();
//       debugPrint('After active filtering: ${filteredStudents.length} students');
//     }

//     if (appliedFilters.classroomIds.isNotEmpty) {
//       filteredStudents = filteredStudents.where((student) {
//         return appliedFilters.classroomIds.contains(student.roomId);
//       }).toList();
//     }

//     if (appliedFilters.tags.isNotEmpty) {
//       filteredStudents = filteredStudents.where((student) {
//         return student.tags
//             .any((tag) => appliedFilters.tags.contains(tag.name));
//       }).toList();
//     }

//     if (searchQuery.isNotEmpty) {
//       filteredStudents = filteredStudents.where((student) {
//         final fullName = student.fullName.toLowerCase();
//         return fullName.contains(searchQuery);
//       }).toList();
//     }

//     visibleStudents = filteredStudents;
//     debugPrint('Final visible students count: ${visibleStudents.length}');

//     if (visibleStudents.isNotEmpty) {
//       final finalStatusCounts = <String, int>{};
//       for (var student in visibleStudents) {
//         finalStatusCounts[student.profileStatus] =
//             (finalStatusCounts[student.profileStatus] ?? 0) + 1;
//       }
//       debugPrint(
//           'Final filtered students status distribution: $finalStatusCounts');
//     }

//     if (mounted) {
//       setState(() {});
//     }
//     _isFiltering = false;
//   }

//   Future<void> _onRefresh() async {
//     StudentService.getAllStudents(context);
//     await _fetchSchoolData();
//     await Future.delayed(const Duration(milliseconds: 100));
//   }

//   void _clearAllFilters() {
//     _studentSearchController.clear();
//     setState(() {
//       searchQuery = '';
//       appliedFilters = FilterData(
//           classroomIds: [], classrooms: [], statuses: [], tags: [], tagIds: []);
//       isShowInactiveToggled = false;
//     });
//     Future.delayed(const Duration(milliseconds: 50), () {
//       if (mounted) {
//         _filterStudents();
//       }
//     });
//   }

//   void _onFiltersApplied(FilterData filters) {
//     setState(() {
//       appliedFilters = filters;
//       isSelectAllChecked = false;
//       isShowInactiveToggled = filters.statuses.contains('Inactive');
//     });
//     Future.delayed(const Duration(milliseconds: 50), () {
//       if (mounted) {
//         _filterStudents();
//       }
//     });
//   }

//   void _toggleStudentSelection(int studentId, bool? value) {
//     if (value == null) return;
//     setState(() {
//       studentSelections[studentId] = value;
//       isSelectAllChecked = visibleStudents.isNotEmpty &&
//           visibleStudents.every((s) => studentSelections[s.id] == true);
//     });
//   }

//   void _toggleSelectAll(bool? value) {
//     if (value == null) return;
//     setState(() {
//       isSelectAllChecked = value;
//       for (var student in visibleStudents) {
//         studentSelections[student.id] = value;
//       }
//     });
//   }

//   void _clearSelections() {
//     setState(() {
//       isSelectAllChecked = false;
//       studentSelections.updateAll((key, val) => false);
//     });
//   }

//   Future<List<GuardianEntity>> getGuardianInfoForStudent(
//       String studentId) async {
//     Map<String, dynamic> parameters = {
//       'studentId.equals': studentId,
//       'size': '100',
//       'page': '0',
//       'sort': 'fullName,asc',
//       'status.in': 'A',
//       'schoolId.equals':
//           '${context.currentStaff == null ? 0 : context.currentStaff!.schoolId}',
//     };
//     try {
//       List<GuardianEntity> guardians = await context
//           .read<GuardianCubit>()
//           .getAllGuardian(parameters: parameters);
//       return guardians;
//     } catch (e) {
//       print('Error fetching guardians for student $studentId: $e');
//       return [];
//     }
//   }

//   Future<List<Staff>> fetchAllStaffs() async {
//     try {
//       Map<String, dynamic> parameters = {
//         'sort': 'id,asc',
//         'status.in': 'A',
//         'size': '100',
//         'schoolId.equals':
//             '${context.currentStaff == null ? 0 : context.currentStaff!.schoolId}',
//       };
//       final data =
//           await context.read<StaffCubit>().getAllStaffs(parameters: parameters);
//       return data;
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(content: Text('Failed to fetch staff information')));
//       }
//       return [];
//     }
//   }

//   Widget _buildFilterCard() {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         border: Border.all(color: AppColors.cardBorderColor),
//         borderRadius: BorderRadius.circular(12),
//         color: AppColors.cardColor,
//       ),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               Expanded(
//                 child: CustomSearchBar(
//                   controller: _studentSearchController,
//                   hintText: 'Search Student',
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Material(
//                 child: InkWell(
//                   onTap: () async {
//                     final result = await Navigator.push<FilterData>(
//                       context,
//                       MaterialPageRoute(
//                         builder: (_) => MultiBlocProvider(
//                           providers: [
//                             BlocProvider(create: (_) => sl<ClassroomCubit>()),
//                             BlocProvider(
//                                 create: (_) => sl<MasterlookupCubit>()),
//                             BlocProvider(create: (_) => sl<TagDataCubit>()),
//                           ],
//                           child: AllStudentsFilterScreen(
//                               initialFilters: appliedFilters),
//                         ),
//                       ),
//                     );
//                     if (result != null) {
//                       _onFiltersApplied(result);
//                     }
//                   },
//                   borderRadius: BorderRadius.circular(100),
//                   splashColor: AppColors.primaryColor.withValues(alpha: 0.15),
//                   child: Padding(
//                     padding: const EdgeInsets.all(8),
//                     child: SvgPicture.asset(
//                       MediaRes.filterIcon,
//                       height: 20,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12), // Reduced from 16
//           IntrinsicHeight(
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 Expanded(
//                   flex: 8,
//                   child: Wrap(
//                     spacing: 8,
//                     runSpacing: 8,
//                     children: [
//                       CustomChip(
//                         label: appliedFilters.statuses.isEmpty
//                             ? (isShowInactiveToggled ? 'Inactive' : 'Active')
//                             : appliedFilters.statuses.join(', '),
//                         labelStyle: const TextStyle(
//                           color: AppColors.secondaryColor,
//                           fontSize: 12, // Reduced from 13
//                           fontWeight: FontWeight.w500,
//                         ),
//                         color: const Color.fromRGBO(177, 175, 233, 0.3),
//                       ),
//                       if (appliedFilters.classrooms.isNotEmpty)
//                         CustomChip(
//                           label:
//                               '${appliedFilters.classrooms.length} Classroom${appliedFilters.classrooms.length > 1 ? 's' : ''}',
//                           labelStyle: const TextStyle(
//                             color: AppColors.secondaryColor,
//                             fontSize: 12, // Reduced from 13
//                             fontWeight: FontWeight.w500,
//                           ),
//                           color: const Color.fromRGBO(177, 175, 233, 0.3),
//                         ),
//                       if (appliedFilters.tags.isNotEmpty)
//                         CustomChip(
//                           label:
//                               '${appliedFilters.tags.length} Tag${appliedFilters.tags.length > 1 ? 's' : ''}',
//                           labelStyle: const TextStyle(
//                             color: AppColors.secondaryColor,
//                             fontSize: 12, // Reduced from 13
//                             fontWeight: FontWeight.w500,
//                           ),
//                           color: const Color.fromRGBO(177, 175, 233, 0.3),
//                         ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 Expanded(
//                   flex: 2,
//                   child: CustomClearAllChip(onTap: _clearAllFilters),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Column _buildShimmerLoaderView() {
//     return Column(
//       children: [
//         ListView.builder(
//           shrinkWrap: true,
//           itemCount: 5,
//           itemBuilder: (context, index) => const ShimmerLoader(
//             height: 72,
//             margin: EdgeInsets.only(bottom: 12),
//           ),
//         ),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final bool hasAccess =
//         context.currentUser?.authorities.contains('Student (Full Access)') ??
//             false;
//     debugPrint("USER HAS FULL STUDENT ACCESS: $hasAccess");

//     return GlobalScaffold(
//       isRefreshable: true,
//       onRefresh: _onRefresh,
//       body: Stack(
//         children: [
//           SingleChildScrollView(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 const Padding(
//                   padding: EdgeInsets.only(left: 4, top: 8),
//                   child: Text(
//                     'Students',
//                     style: TextStyle(
//                       color: AppColors.primaryColor,
//                       fontSize: 17,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 if (_isLoadingSchoolData)
//                   ListView.builder(
//                     shrinkWrap: true,
//                     itemCount: 2,
//                     itemBuilder: (context, index) => ShimmerLoader(
//                       height: 100,
//                       margin:
//                           index == 0 ? const EdgeInsets.only(bottom: 12) : null,
//                     ),
//                   )
//                 else if (_schoolDataError != null)
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 16, vertical: 48),
//                     decoration: BoxDecoration(
//                       border: Border.all(color: AppColors.cardBorderColor),
//                       borderRadius: BorderRadius.circular(12),
//                       color: AppColors.cardColor,
//                     ),
//                     child: Center(child: Text(_schoolDataError!)),
//                   )
//                 else
//                   Column(
//                     children: [
//                       CustomStatBarCard(
//                         title: 'Enrolled\nStudents',
//                         number: '$_enrolledStudents',
//                         items: [
//                           ProgressItemHelper(
//                             label: 'Active ($_activeStudents)',
//                             value: _activeStudents.toDouble(),
//                             color: AppColors.lightBlueProgressBar,
//                           ),
//                           ProgressItemHelper(
//                             label: 'Upcoming ($_upcomingStudents)',
//                             value: _upcomingStudents.toDouble(),
//                             color: AppColors.mustardProgressBar,
//                           ),
//                         ],
//                         onLegendTap: (label) {
//                           String status = label.split(' ').first;
//                           if (status == 'Active' || status == 'Upcoming') {
//                             setState(() {
//                               isShowInactiveToggled = false;
//                               appliedFilters = appliedFilters.copyWith(
//                                 statuses: status == 'Active' ? [] : [status],
//                               );
//                             });
//                             Future.delayed(const Duration(milliseconds: 50),
//                                 () {
//                               if (mounted) {
//                                 _filterStudents();
//                               }
//                             });
//                           }
//                         },
//                       ),
//                       const SizedBox(height: 12), // Reduced from 16
//                       CustomStatBarCard(
//                         title: 'Expected\nStudents',
//                         number: '$_expectedStudents',
//                         items: [
//                           ProgressItemHelper(
//                             label: 'Present ($_presentStudents)',
//                             value: _presentStudents.toDouble(),
//                             color: AppColors.lightGreenProgressBar,
//                           ),
//                           ProgressItemHelper(
//                             label: 'Absent ($_absentStudents)',
//                             value: _absentStudents.toDouble(),
//                             color: AppColors.redProgressBar,
//                           ),
//                         ],
//                         onLegendTap: (label) {
//                           String status = label.split(' ').first;
//                           if (status == 'Present' || status == 'Absent') {
//                             Navigator.of(context).push(
//                               MaterialPageRoute(
//                                 builder: (context) => AttendanceTabbedView(
//                                   dailyIncomingFilter: status,
//                                 ),
//                               ),
//                             );
//                           }
//                         },
//                       ),
//                     ],
//                   ),
//                 const SizedBox(height: 12), // Reduced from 16
//                 _buildFilterCard(),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(
//                       horizontal: 12, vertical: 12), // Reduced vertical from 16
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Expanded(
//                         child: CustomCheckbox(
//                           label: 'Select All',
//                           labelStyle: const TextStyle(
//                             color: AppColors.primaryColor,
//                             fontSize: 14, // Reduced from default
//                             fontWeight: FontWeight.w500,
//                           ),
//                           value: isSelectAllChecked,
//                           onChanged: _toggleSelectAll,
//                         ),
//                       ),
//                       Expanded(
//                         child: CustomToggle(
//                           label: 'Show Inactive',
//                           isToggled: isShowInactiveToggled,
//                           onToggle: _toggleShowInactive,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 BlocConsumer<StudentDataCubit, StudentDataState>(
//                   listener: (context, state) {
//                     if (state is StudentError) {
//                       return CoreUtils.showTopSnackBar(
//                         context: context,
//                         message: 'Error Loading Students',
//                         isError: true,
//                       );
//                     }
//                     if (state is AllStudentsDataLoaded) {
//                       debugPrint('Students loaded: ${state.students.length}');
//                       allStudents = state.students;
//                       final statusCounts = <String, int>{};
//                       for (var student in allStudents) {
//                         statusCounts[student.profileStatus] =
//                             (statusCounts[student.profileStatus] ?? 0) + 1;
//                       }
//                       debugPrint('Student status distribution: $statusCounts');
//                       for (var student in allStudents) {
//                         studentSelections.putIfAbsent(student.id, () => false);
//                       }
//                       debugPrint(
//                           'Calling _filterStudents after students loaded');
//                       _filterStudents();
//                     }
//                   },
//                   builder: (context, state) {
//                     if (state is AllStudentsDataLoaded) {
//                       if (state.students.isEmpty) {
//                         return const Center(child: Text('No Students Found'));
//                       }
//                       return ListView.builder(
//                         shrinkWrap: true,
//                         physics: const NeverScrollableScrollPhysics(),
//                         itemCount: visibleStudents.length,
//                         padding: const EdgeInsets.only(bottom: 16),
//                         itemBuilder: (context, index) {
//                           final student = visibleStudents[index];
//                           String formattedBirthdate = '-';
//                           if (student.dateOfBirth != null &&
//                               student.dateOfBirth.toString().isNotEmpty) {
//                             try {
//                               final date = DateTime.parse(
//                                   student.dateOfBirth.toString());
//                               formattedBirthdate =
//                                   DateFormat('MMM dd, yyyy').format(date);
//                             } catch (_) {
//                               formattedBirthdate =
//                                   student.dateOfBirth.toString();
//                             }
//                           }
//                           return Padding(
//                             padding: const EdgeInsets.only(
//                                 bottom: 12), // Reduced from 16
//                             child: StudentCard(
//                               name: student.fullName,
//                               classroom: student.roomName,
//                               avatarUrl: student.photoUuid,
//                               tags:
//                                   student.tags.map((tag) => tag.name).toList(),
//                               schedule: ["Mon", "Tue", "Wed", "Thu", "Fri"],
//                               birthdate: formattedBirthdate,
//                               movementDate:
//                                   _formatMovementDate(student.movementDate),
//                               onDeactivate: () {},
//                               onEdit: () {},
//                               isSelected:
//                                   studentSelections[student.id] ?? false,
//                               onSelected: (value) {
//                                 _toggleStudentSelection(student.id, value);
//                               },
//                             ),
//                           );
//                         },
//                       );
//                     }
//                     if (state is GettingAllStudentsData) {
//                       return _buildShimmerLoaderView();
//                     }
//                     return const Center(child: Text('Error Loading Students'));
//                   },
//                 ),
//               ],
//             ),
//           ),
//           if (hasSelectedStudents)
//             Positioned(
//               right: 5,
//               top: context.height / 4,
//               child: BlocProvider(
//                 create: (context) => sl<DailyActivityCubit>(),
//                 child: AttendanceActivitiesPanel(
//                   key: ValueKey(_getCommonRoomId()),
//                   students: _getSelectedStudents(),
//                   roomId: _getCommonRoomId(),
//                   onClearSelections: _clearSelections,
//                   onStudentStatusChanged: () {
//                     _onRefresh();
//                     _clearSelections();
//                   },
//                   onMessageTap: () async {
//                     Map<String, List<GuardianEntity>> studentGuardians = {};
//                     try {
//                       for (final student in _getSelectedStudents()) {
//                         final data = await getGuardianInfoForStudent(
//                             student.id.toString());
//                         studentGuardians[student.id.toString()] = data;
//                       }
//                     } catch (e) {
//                       if (!mounted) return;
//                       CoreUtils.showTopSnackBar(
//                         context: context,
//                         message:
//                             'Failed to fetch guardians. Please try again later.',
//                         isError: true,
//                       );
//                       return;
//                     }
//                     final staffList = await fetchAllStaffs();
//                     if (!mounted) return;
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => MultiBlocProvider(
//                           providers: [
//                             BlocProvider(create: (_) => sl<GuardianCubit>()),
//                             BlocProvider(create: (_) => sl<StaffCubit>()),
//                           ],
//                           child: SendParentMessageScreen(
//                             staffList: staffList,
//                             studentGuardians: studentGuardians,
//                             selectedItems: _getSelectedStudents()
//                                 .map((student) => SelectedMessageItem(
//                                       id: student.id,
//                                       photoUrl: student.photoUuid,
//                                       name: student.fullName,
//                                       email: '${student.id}@example.com',
//                                       roomId: student.roomId,
//                                       roomIds: [student.roomId],
//                                       schoolId: student.schoolId ?? 0,
//                                     ))
//                                 .toList(),
//                           ),
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
