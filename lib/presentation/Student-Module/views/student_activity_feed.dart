// import 'dart:io';
// import 'dart:typed_data';
// import 'package:chewie/chewie.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:intl/intl.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:shimmer/shimmer.dart';
// import 'package:video_player/video_player.dart';

// import '../../../../domain/features/Student-Module/entities/Student-Entity.dart';

// class StudentActivityScreen extends StatefulWidget {
//   const StudentActivityScreen({
//     super.key,
//     required this.refreshCallback,
//     required this.students,
//     required this.studentId,
//   });
//   final VoidCallback refreshCallback;
//   final List<StudentEntity> students;
//   final int studentId;

//   @override
//   State<StudentActivityScreen> createState() => _StudentActivityScreenState();
// }

// class _StudentActivityScreenState extends State<StudentActivityScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   bool isSelectAllChecked = false;
//   List<StudentEntity> allStudents = [];
//   List<ActivityNewModel> activities = [];
//   ChewieController? _chewieController;
//   VideoPlayerController? _videoPlayerController;
//   List<String> _tempFilePaths = [];
//   int studentId = 0;
//   DateTime selectedStartDate = DateTime.now();
//   DateTime selectedEndDate = DateTime.now();
//   bool isActivityLoading = false;
//   int? addedActivityRoomId;
//   String? selectedStudentName;

//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 1, vsync: this);
//     _tabController.addListener(() {
//       setState(() {});
//     });
//     selectedStudentName = '';
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       addedActivityRoomId = ModalRoute.of(context)?.settings.arguments as int?;
//       getAllDailyActivities(
//         studentId: widget.studentId,
//         startDate: selectedStartDate,
//         endDate: selectedEndDate,
//       );
//       getAllStudents();
//     });
//   }

//   void refreshPage() {
//     getAllDailyActivities(
//       studentId: widget.studentId,
//       startDate: selectedStartDate,
//       endDate: selectedEndDate,
//     );
//     setState(() {});
//   }

//   void getAllDailyActivities({
//     required int? studentId,
//     required DateTime startDate,
//     required DateTime endDate,
//   }) async {
//     setState(() {
//       isActivityLoading = true;
//     });

//     DateTime startOfDay = DateTime(
//       startDate.year,
//       startDate.month,
//       startDate.day,
//       0,
//       0,
//       0,
//       0,
//     );
//     String startDateFormated = await convertLocalToUtc(startOfDay);

//     DateTime endOfDay = DateTime(
//       endDate.year,
//       endDate.month,
//       endDate.day,
//       23,
//       59,
//       59,
//       9,
//     );
//     String endDateFormated = await convertLocalToUtc(endOfDay);

//     DataMap parameters = {
//       'size': '100',
//       'page': '0',
//       'sort': 'time,desc',
//       'status.equals': 'A',
//       'schoolId.equals':
//           '${context.currentStaff == null ? 0 : context.currentStaff!.schoolId}',
//       'date.greaterThanOrEqual': startDateFormated,
//       'date.lessThanOrEqual': endDateFormated,
//       'studentId.equals': '$studentId',
//     };

//     try {
//       activities = await context
//           .read<DailyActivityCubit>()
//           .getAllActivityDataAdminDashboard(parameters: parameters);

//       setState(() {
//         isActivityLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         isActivityLoading = false;
//       });
//     }
//   }

//   void getAllStudents() async {
//     DataMap parameters = {
//       'size': '100',
//       'page': '0',
//       'sort': 'id,asc',
//       'status.in': 'A',
//       'profileStatus.equals': 'A',
//       'schoolId.equals':
//           '${context.currentStaff == null ? 0 : context.currentStaff!.schoolId}',
//     };

//     allStudents = await context.read<StudentDataCubit>().getAllStudentsData(
//       parameters: parameters,
//     );

//     if (allStudents.isNotEmpty) {
//       final foundStudent = allStudents.firstWhere(
//         (student) => student.id == widget.studentId,
//       );

//       selectedStudentName = foundStudent.fullName;
//       studentId = foundStudent.id;
//     }

//     allStudents = allStudents
//         .where((student) => student.id == widget.studentId)
//         .toList();

//     setState(() {});
//   }

//   bool isVideo(Uint8List bytes) {
//     if (bytes.length < 16) return false;

//     if (bytes[4] == 0x66 &&
//         bytes[5] == 0x74 &&
//         bytes[6] == 0x79 &&
//         bytes[7] == 0x70) {
//       return true;
//     }

//     if (bytes[0] == 0x52 &&
//         bytes[1] == 0x49 &&
//         bytes[2] == 0x46 &&
//         bytes[3] == 0x46 &&
//         bytes[8] == 0x41 &&
//         bytes[9] == 0x56 &&
//         bytes[10] == 0x49 &&
//         bytes[11] == 0x20) {
//       return true;
//     }

//     return false;
//   }

//   Future<VideoPlayerController> _getControllerForVideoBytes(
//     Uint8List bytes,
//   ) async {
//     try {
//       final tempDir = await getTemporaryDirectory();
//       final tempPath = tempDir.path;
//       final tempFile = File(
//         '$tempPath/temp_video_${DateTime.now().millisecondsSinceEpoch}.mp4',
//       );

//       await tempFile.writeAsBytes(bytes);
//       _tempFilePaths.add(tempFile.path);
//       final controller = VideoPlayerController.file(tempFile);
//       await controller.initialize();
//       return controller;
//     } catch (e) {
//       debugPrint('Error initializing video controller: $e');
//       throw Exception('Failed to load video');
//     }
//   }

//   void _clearTempFiles() async {
//     for (String path in _tempFilePaths) {
//       try {
//         final file = File(path);
//         if (await file.exists()) {
//           await file.delete();
//         }
//       } catch (e) {
//         debugPrint('Error deleting temp file: $e');
//       }
//     }
//     _tempFilePaths.clear();
//   }

//   Widget _buildFullVideoPlayer(Uint8List videoData) {
//     return FutureBuilder<VideoPlayerController>(
//       future: _getControllerForVideoBytes(videoData),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.done &&
//             snapshot.hasData) {
//           _videoPlayerController = snapshot.data;
//           _chewieController = ChewieController(
//             videoPlayerController: _videoPlayerController!,
//             autoPlay: true,
//             looping: false,
//             aspectRatio: _videoPlayerController!.value.aspectRatio,
//             allowFullScreen: true,
//             errorBuilder: (context, errorMessage) {
//               return Center(
//                 child: Text(
//                   errorMessage,
//                   style: const TextStyle(color: Colors.white),
//                 ),
//               );
//             },
//           );
//           return Chewie(controller: _chewieController!);
//         } else {
//           return const Center(child: CircularProgressIndicator());
//         }
//       },
//     );
//   }

//   void _navigateToEditActivityForm(
//     BuildContext context,
//     String activityName,
//     int activityId,
//     List<StudentDataModel> selectedStudents,
//     int roomId,
//   ) {
//     final Map<String, String> activityEditRoutes = {
//       'BOTTLE': EditBottleActivityForm.routeName,
//       'BATHROOM': EditBathroomActivityForm.routeName,
//       'NAP': EditNapActivityForm.routeName,
//       'NAP START': EditNapStartActivityForm.routeName,
//       'NAP END': EditNapEndActivityForm.routeName,
//       'NOTES': EditNotesActivityForm.routeName,
//       'MEAL': EditMealActivityForm.routeName,
//       'INCIDENT': EditIncidentActivityForm.routeName,
//       'PHOTO': EditPhotoVideoActivityForm.routeName,
//       'MEDICATION': EditMedicationActivityForm.routeName,
//       'OUTDOOR': EditOutdoorActivityForm.routeName,
//       'LEARNING': EditLearningActivityForm.routeName,
//     };

//     String? routeName = activityEditRoutes[activityName];

//     final arguments = {
//       'students': selectedStudents.toList(),
//       'activityId': activityId,
//       'roomId': roomId == 0 ? context.currentStaff!.primaryRoomId : roomId,
//     };

//     if (routeName != null) {
//       Navigator.pushNamed(context, routeName, arguments: arguments);
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('No edit form available for $activityName activities'),
//         ),
//       );
//     }
//   }

//   @override
//   void dispose() {
//     _tabController.dispose();
//     _chewieController?.dispose();
//     _videoPlayerController?.dispose();
//     _clearTempFiles();
//     super.dispose();
//   }

//   Widget _buildFullImageViewer(Uint8List imageData) {
//     return InteractiveViewer(
//       panEnabled: true,
//       boundaryMargin: EdgeInsets.zero,
//       minScale: 0.5,
//       maxScale: 4,
//       child: Container(
//         color: Colors.black,
//         child: Center(child: Image.memory(imageData, fit: BoxFit.contain)),
//       ),
//     );
//   }

//   Widget _buildTabToggleButton({
//     required bool isSelected,
//     required VoidCallback onPressed,
//     required String text,
//   }) {
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: onPressed,
//         borderRadius: BorderRadius.circular(8),
//         child: Container(
//           padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.02),
//           decoration: BoxDecoration(
//             border: isSelected
//                 ? const Border(
//                     bottom: BorderSide(color: AppColors.themeColor, width: 2),
//                   )
//                 : null,
//           ),
//           child: Row(
//             children: [
//               Text(
//                 text,
//                 style: TextStyle(
//                   color: isSelected ? AppColors.themeColor : Colors.grey,
//                   fontWeight: FontWeight.bold,
//                   fontSize: MediaQuery.of(context).size.width * 0.04,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTimelineSection() {
//     List<Color> colors = [
//       const Color.fromRGBO(255, 235, 59, 1),
//       Colors.blue,
//       Colors.green,
//       Colors.red,
//     ];

//     if (isActivityLoading) {
//       return ListView.builder(
//         itemCount: 3,
//         shrinkWrap: true,
//         itemBuilder: (context, index) {
//           return const ActivityShimmerCard();
//         },
//       );
//     }

//     if (activities.isEmpty) {
//       return CustomRefreshIndicator(
//         onRefresh: () async => refreshPage(),
//         child: LayoutBuilder(
//           builder: (context, constraints) {
//             return Card(
//               elevation: 0,
//               margin: EdgeInsets.zero,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(16),
//                 side: BorderSide(
//                   color: AppColors.primaryColor.withValues(alpha: 0.15),
//                 ),
//               ),
//               child: ListView(
//                 children: [
//                   SizedBox(
//                     height: constraints.maxHeight,
//                     child: Center(
//                       child: Text(
//                         'No Activities Found',
//                         style: TextStyle(
//                           color: AppColors.primaryColor,
//                           fontSize: MediaQuery.of(context).size.width * 0.045,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           },
//         ),
//       );
//     }

//     DateTime? parseTimeString(String timeString) {
//       if (timeString.isEmpty) return null;

//       try {
//         final dateTime = DateFormat('hh:mm:ss a').parse(timeString);
//         return dateTime;
//       } catch (e) {
//         try {
//           final dateTime = DateFormat('HH:mm:ss').parse(timeString);
//           return dateTime;
//         } catch (e2) {
//           try {
//             final dateTime = DateFormat('hh:mm:ss').parse(timeString);
//             return dateTime;
//           } catch (e3) {
//             return null;
//           }
//         }
//       }
//     }

//     List<ActivityNewModel> sortedActivities = List.from(activities);
//     sortedActivities.sort((a, b) {
//       DateTime? timeA = parseTimeString(a.time);
//       DateTime? timeB = parseTimeString(b.time);

//       if (timeA == null && timeB == null) return 0;
//       if (timeA == null) return 1;
//       if (timeB == null) return -1;

//       return timeB.compareTo(timeA);
//     });

//     return CustomRefreshIndicator(
//       onRefresh: () async {
//         refreshPage();
//       },
//       child: SingleChildScrollView(
//         child: Column(
//           children: sortedActivities.asMap().entries.map((entry) {
//             int index = entry.key;
//             ActivityNewModel activity = entry.value;

//             Color color = colors[index % colors.length];
//             return _buildTimelineItem(
//               time: activity.lastModified,
//               color: color,
//               name: activity.activityType.name,
//               description: activity.description,
//               students: activity.students,
//               fileuuid: activity.activityType.logoFileUuid,
//               activityId: activity.id,
//               approverId: activity.approverId,
//               acknowledgeBy: activity.acknowledgeBy,
//               isApprover: activity.isApprover,
//               approvalDate: activity.approvalDate,
//               activityStatus: activity.activityStatus,
//               roomId: activity.roomId,
//               activityNote: activity.activityNote,
//               formatTime: activity.time,
//             );
//           }).toList(),
//         ),
//       ),
//     );
//   }

//   Widget _buildTimelineItem({
//     required String time,
//     required Color color,
//     required String name,
//     required String description,
//     required List<StudentDataModel> students,
//     required String fileuuid,
//     required int activityId,
//     required int approverId,
//     required int acknowledgeBy,
//     required bool isApprover,
//     required String approvalDate,
//     required String activityStatus,
//     required int roomId,
//     required String activityNote,
//     required String formatTime,
//   }) {
//     return Container(
//       margin: EdgeInsets.only(
//         bottom: MediaQuery.of(context).size.height * 0.01,
//       ),
//       child: IntrinsicHeight(
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Column(
//               children: [
//                 Container(
//                   width: MediaQuery.of(context).size.width * 0.05,
//                   height: MediaQuery.of(context).size.width * 0.05,
//                   decoration: BoxDecoration(
//                     color: color,
//                     shape: BoxShape.circle,
//                   ),
//                 ),
//                 Expanded(
//                   child: Container(
//                     color: color.withValues(alpha: 0.3),
//                     width: 3,
//                   ),
//                 ),
//               ],
//             ),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Container(
//                         width: context.width * 0.25,
//                         height: 3,
//                         color: color.withValues(alpha: 0.5),
//                       ),
//                       Container(
//                         width: MediaQuery.of(context).size.width * 0.05,
//                         height: MediaQuery.of(context).size.width * 0.05,
//                         decoration: BoxDecoration(
//                           color: color,
//                           shape: BoxShape.circle,
//                         ),
//                       ),
//                       SizedBox(width: MediaQuery.of(context).size.width * 0.04),
//                       Text(
//                         formatTime.isEmpty
//                             ? ''
//                             : formatTimeWithoutSeconds(formatTime),
//                         style: TextStyle(
//                           color: Colors.grey,
//                           fontSize: MediaQuery.of(context).size.width * 0.035,
//                         ),
//                       ),
//                     ],
//                   ),
//                   SizedBox(height: MediaQuery.of(context).size.height * 0.015),
//                   _buildActivityCard(
//                     fileuuid: fileuuid,
//                     color: color,
//                     name: name,
//                     description: description,
//                     students: students,
//                     activityId: activityId,
//                     approverId: approverId,
//                     acknowledgeBy: acknowledgeBy,
//                     isApprover: isApprover,
//                     approvalDate: approvalDate,
//                     activityStatus: activityStatus,
//                     roomId: roomId,
//                     activityNote: activityNote,
//                   ),
//                   SizedBox(height: MediaQuery.of(context).size.height * 0.015),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildActivityCard({
//     required Color color,
//     required String name,
//     required String description,
//     required List<StudentDataModel> students,
//     required String fileuuid,
//     required int activityId,
//     required int approverId,
//     required int acknowledgeBy,
//     required bool isApprover,
//     required String approvalDate,
//     required String activityStatus,
//     required int roomId,
//     required String activityNote,
//   }) {
//     final Map<String, String> activityIcons = {
//       'SIGN-IN': MediaRes.dailyActivitySignInIcon,
//       'SIGN-OUT': MediaRes.dailyActivitySignOutIcon,
//       'ABSENT': MediaRes.dailyActivityAbsentIcon,
//       'NAP': MediaRes.napActivityIcon,
//       'NAP START': MediaRes.napActivityIcon,
//       'NAP END': MediaRes.napActivityIcon,
//       'BATHROOM': MediaRes.bathroomActivityIcon,
//       'BOTTLE': MediaRes.bottleActivityIcon,
//       'MEAL': MediaRes.mealActivityIcon,
//       'INCIDENT': MediaRes.incidentActivityIcon,
//       'PHOTO': MediaRes.photoVideoActivityIcon,
//       'MEDICATION': MediaRes.medicationActivityIcon,
//       'NOTES': MediaRes.notesActivityIcon,
//       'OUTDOOR': MediaRes.outdoorActivityIcon,
//       'LEARNING': MediaRes.learningActivityIcon,
//     };

//     String? iconPath = activityIcons[name];

//     return Container(
//       padding: EdgeInsets.all(
//         MediaQuery.of(context).size.width * 0.01,
//       ), // Reduced padding
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(8),
//         color: color.withValues(alpha: 0.2),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             height: MediaQuery.of(context).size.height * 0.15,
//             width: MediaQuery.of(context).size.width * 0.4,
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: BlocProvider(
//               create: (context) {
//                 final bloc = sl<DocumentBloc>();
//                 bloc.add(
//                   DownloadDocument({
//                     'size': '100',
//                     'page': '0',
//                     'sort': 'id,asc',
//                     'status.equals': 'A',
//                     'schoolId.equals':
//                         '${context.currentStaff == null ? 0 : context.currentStaff!.schoolId}',
//                     'docStatus.equals': 'Activity',
//                     'docType.equals': 'ACTIVITY',
//                     'refTable.equals': 'Activity',
//                     'refTableId.equals': '$activityId',
//                   }),
//                 );
//                 return bloc;
//               },
//               child: BlocBuilder<DocumentBloc, DocumentState>(
//                 builder: (context, state) {
//                   if (state is DownloadingDocument) {
//                     return Center(
//                       child: ShimmerLoaderCard(
//                         child: Container(
//                           height: MediaQuery.of(context).size.height * 0.15,
//                           width: MediaQuery.of(context).size.width * 0.4,
//                         ),
//                         cardColor: Colors.grey.shade300,
//                       ),
//                     );
//                   } else if (state is DocumentDownloaded &&
//                       state.fileData.isNotEmpty) {
//                     final bool isVideoFile = isVideo(state.fileData);

//                     return GestureDetector(
//                       onTap: () {
//                         showDialog(
//                           context: context,
//                           barrierDismissible: true,
//                           barrierColor: Colors.black,
//                           builder: (BuildContext context) {
//                             return Dialog.fullscreen(
//                               child: Stack(
//                                 fit: StackFit.expand,
//                                 children: [
//                                   isVideoFile
//                                       ? _buildFullVideoPlayer(state.fileData)
//                                       : _buildFullImageViewer(state.fileData),
//                                   Positioned(
//                                     top: 20,
//                                     right: 20,
//                                     child: IconButton(
//                                       icon: const Icon(
//                                         Icons.close,
//                                         color: Colors.white,
//                                         size: 28,
//                                       ),
//                                       onPressed: () =>
//                                           Navigator.of(context).pop(),
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             );
//                           },
//                         );
//                       },
//                       child: Container(
//                         height: MediaQuery.of(context).size.height * 0.15,
//                         width: MediaQuery.of(context).size.width * 0.4,
//                         decoration: BoxDecoration(
//                           color: Colors.black12,
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: isVideoFile
//                             ? Stack(
//                                 alignment: Alignment.center,
//                                 children: [
//                                   FutureBuilder<VideoPlayerController>(
//                                     future: _getControllerForVideoBytes(
//                                       state.fileData,
//                                     ),
//                                     builder: (context, snapshot) {
//                                       if (snapshot.connectionState ==
//                                               ConnectionState.done &&
//                                           snapshot.hasData) {
//                                         return AspectRatio(
//                                           aspectRatio:
//                                               snapshot.data!.value.aspectRatio,
//                                           child: VideoPlayer(snapshot.data!),
//                                         );
//                                       } else {
//                                         return Center(
//                                           child: ShimmerLoaderCard(
//                                             child: Container(
//                                               height:
//                                                   MediaQuery.of(
//                                                     context,
//                                                   ).size.height *
//                                                   0.15,
//                                               width:
//                                                   MediaQuery.of(
//                                                     context,
//                                                   ).size.width *
//                                                   0.4,
//                                             ),
//                                             cardColor: Colors.grey.shade300,
//                                           ),
//                                         );
//                                       }
//                                     },
//                                   ),
//                                   Container(
//                                     padding: const EdgeInsets.all(8),
//                                     decoration: const BoxDecoration(
//                                       color: Colors.black54,
//                                       shape: BoxShape.circle,
//                                     ),
//                                     child: const Icon(
//                                       Icons.play_arrow,
//                                       color: Colors.white,
//                                       size: 30,
//                                     ),
//                                   ),
//                                 ],
//                               )
//                             : Image.memory(state.fileData, fit: BoxFit.contain),
//                       ),
//                     );
//                   } else {
//                     return Padding(
//                       padding: const EdgeInsets.all(10.0),
//                       child: iconPath != null
//                           ? iconPath.endsWith('.svg')
//                                 ? SvgPicture.asset(
//                                     iconPath,
//                                     fit: BoxFit.contain,
//                                   )
//                                 : Image.asset(iconPath, fit: BoxFit.contain)
//                           : RectangularDocumentWidget(
//                               fileUuid: fileuuid,
//                               width: double.infinity,
//                               height: double.infinity,
//                             ),
//                     );
//                   }
//                 },
//               ),
//             ),
//           ),
//           SizedBox(
//             width: MediaQuery.of(context).size.width * 0.015,
//           ), // Reduced spacer
//           Expanded(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Flexible(
//                           child: Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 6, // Reduced padding
//                               vertical: 4,
//                             ),
//                             decoration: BoxDecoration(
//                               color: color.withValues(alpha: 0.5),
//                               borderRadius: BorderRadius.circular(4),
//                             ),
//                             child: Text(
//                               name,
//                               maxLines: 1,
//                               overflow: TextOverflow.ellipsis,
//                               style: TextStyle(
//                                 color: AppColors.primaryColor,
//                                 fontSize:
//                                     MediaQuery.of(context).size.width * 0.03,
//                               ),
//                             ),
//                           ),
//                         ),
//                         name != 'SIGN-IN' &&
//                                 name != 'SIGN-OUT' &&
//                                 name != 'ABSENT'
//                             ? Flexible(
//                                 child: Container(
//                                   height: 24,
//                                   child: Align(
//                                     alignment: Alignment.center,
//                                     child: PopupMenuButton<String>(
//                                       icon: const Icon(
//                                         Icons.more_horiz,
//                                         size: 18, // Reduced icon size
//                                       ),
//                                       padding: EdgeInsets.zero,
//                                       constraints: const BoxConstraints(),
//                                       onSelected: (value) {
//                                         if (value == 'edit') {
//                                           _navigateToEditActivityForm(
//                                             context,
//                                             name,
//                                             activityId,
//                                             students,
//                                             roomId,
//                                           );
//                                         } else if (value == 'delete') {
//                                           showModalBottomSheet(
//                                             context: context,
//                                             isScrollControlled: true,
//                                             backgroundColor: Colors.transparent,
//                                             builder: (context) =>
//                                                 DraggableScrollableSheet(
//                                                   initialChildSize: 0.27,
//                                                   minChildSize: 0.2,
//                                                   maxChildSize: 0.4,
//                                                   builder: (context, scrollController) =>
//                                                       BlocProvider<
//                                                         DailyActivityCubit
//                                                       >.value(
//                                                         value:
//                                                             BlocProvider.of<
//                                                               DailyActivityCubit
//                                                             >(this.context),
//                                                         child:
//                                                             DeleteActivityForm(
//                                                               activityId:
//                                                                   activityId,
//                                                               activityName:
//                                                                   name,
//                                                               onDeleteSuccess:
//                                                                   refreshPage,
//                                                             ),
//                                                       ),
//                                                 ),
//                                           );
//                                         }
//                                       },
//                                       itemBuilder: (context) => [
//                                         const PopupMenuItem<String>(
//                                           value: 'edit',
//                                           child: PopupItem(
//                                             title: 'Edit',
//                                             icon: Icon(
//                                               Icons.edit_outlined,
//                                               color: AppColors.themeColor,
//                                             ),
//                                           ),
//                                         ),
//                                         const PopupMenuItem<String>(
//                                           value: 'delete',
//                                           child: PopupItem(
//                                             title: 'Delete',
//                                             icon: Icon(
//                                               Icons.delete_outline,
//                                               color: AppColors.themeColor,
//                                             ),
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ),
//                               )
//                             : const SizedBox(),
//                       ],
//                     ),
//                     SizedBox(
//                       height: MediaQuery.of(context).size.height * 0.005,
//                     ),
//                     _buildStudentAvatars(students),
//                   ],
//                 ),
//                 SizedBox(height: MediaQuery.of(context).size.height * 0.015),
//                 Container(
//                   width: double.infinity,
//                   child: Text(
//                     ([
//                               'NAP',
//                               'NAP START',
//                               'NAP END',
//                               'BATHROOM',
//                               'MEAL',
//                               'BOTTLE',
//                             ].contains(name.toUpperCase()) &&
//                             activityNote.isNotEmpty)
//                         ? activityNote
//                         : description,
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                     style: TextStyle(
//                       color: AppColors.primaryColor,
//                       fontSize: MediaQuery.of(context).size.width * 0.035,
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: MediaQuery.of(context).size.height * 0.015),
//                 name == 'SIGN-IN' ||
//                         name == 'SIGN-OUT' ||
//                         name == 'ABSENT' ||
//                         name == 'TRANSFER' ||
//                         activityStatus == "Sent"
//                     ? const SizedBox()
//                     : Container(
//                         decoration: BoxDecoration(
//                           color: (activityStatus == "Sent" && approverId == 0)
//                               ? Colors.transparent
//                               : activityStatus == "Pending"
//                               ? Colors.amber
//                               : (activityStatus == "Approved" &&
//                                     approverId != 0 &&
//                                     approvalDate != '')
//                               ? Colors.green
//                               : activityStatus == "Acknowledged"
//                               ? Colors.green
//                               : Colors.orange,
//                           borderRadius: BorderRadius.circular(4),
//                         ),
//                         padding: const EdgeInsets.symmetric(
//                           horizontal: 8,
//                         ), // Reduced padding
//                         width: double.infinity,
//                         child: Text(
//                           (activityStatus == "Sent" && approverId == 0)
//                               ? ''
//                               : (activityStatus == "Approved" &&
//                                     approverId != 0 &&
//                                     approvalDate != '')
//                               ? 'Approved'
//                               : activityStatus,
//                           textAlign: TextAlign.center,
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(
//                             color: AppColors.primaryColor,
//                             fontSize: MediaQuery.of(context).size.width * 0.035,
//                           ),
//                         ),
//                       ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   String formatTimeWithoutSeconds(String timeWithSeconds) {
//     if (timeWithSeconds.isEmpty) return '';

//     try {
//       final dateTime = DateFormat('hh:mm:ss a').parse(timeWithSeconds);
//       return DateFormat('hh:mm a').format(dateTime);
//     } catch (e) {
//       try {
//         final dateTime = DateFormat('HH:mm:ss').parse(timeWithSeconds);
//         return DateFormat('hh:mm a').format(dateTime);
//       } catch (e2) {
//         try {
//           final dateTime = DateFormat('hh:mm:ss').parse(timeWithSeconds);
//           return DateFormat('hh:mm a').format(dateTime);
//         } catch (e3) {
//           return timeWithSeconds;
//         }
//       }
//     }
//   }

//   Widget _buildStudentAvatars(List<StudentDataModel> students) {
//     return InkWell(
//       onTap: students.length > 1
//           ? () => _showStudentsDialog(context, students)
//           : () => _showSingleStudentDialog(context, students[0].fullName),
//       child: Row(
//         children: [
//           SizedBox(
//             height: MediaQuery.of(context).size.width * 0.08,
//             width: students.length > 1
//                 ? MediaQuery.of(context).size.width * 0.3
//                 : MediaQuery.of(context).size.width * 0.08,
//             child: Stack(
//               clipBehavior: Clip.none,
//               children: List.generate(
//                 students.length > 5 ? 5 : students.length,
//                 (index) {
//                   String photoUuid = students[index].photoUuid;

//                   return Positioned(
//                     left: index * MediaQuery.of(context).size.width * 0.06,
//                     child: Container(
//                       height: MediaQuery.of(context).size.width * 0.08,
//                       width: MediaQuery.of(context).size.width * 0.08,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         border: Border.all(color: Colors.white, width: 2),
//                       ),
//                       child: ClipOval(
//                         child: index == 4 && students.length > 5
//                             ? Center(
//                                 child: Text(
//                                   '+${students.length - 4}',
//                                   style: TextStyle(
//                                     fontSize:
//                                         MediaQuery.of(context).size.width *
//                                         0.025,
//                                   ),
//                                 ),
//                               )
//                             : BlocProvider(
//                                 create: (context) => sl<DocumentBloc>(),
//                                 child: DocumentImageWidget(
//                                   fileUuid: photoUuid,
//                                   name: students[index].fullName,
//                                   size:
//                                       MediaQuery.of(context).size.width * 0.08,
//                                 ),
//                               ),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//           if (students.length == 1)
//             Padding(
//               padding: EdgeInsets.only(
//                 left: MediaQuery.of(context).size.width * 0.02,
//               ),
//               child: Container(
//                 width: MediaQuery.of(context).size.width * 0.35,
//                 child: Text(
//                   students[0].fullName,
//                   maxLines: 1,
//                   overflow: TextOverflow.ellipsis,
//                   style: TextStyle(
//                     color: Colors.grey,
//                     fontSize: MediaQuery.of(context).size.width * 0.035,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   void _showSingleStudentDialog(BuildContext context, String studentName) {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return Dialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           insetPadding: const EdgeInsets.symmetric(
//             horizontal: 16,
//             vertical: 24,
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 16,
//                   vertical: 16,
//                 ),
//                 decoration: const BoxDecoration(
//                   color: Color(0xFFF2F2FF),
//                   borderRadius: BorderRadius.only(
//                     topLeft: Radius.circular(16),
//                     topRight: Radius.circular(16),
//                   ),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Text(
//                       'Student',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFF573353),
//                       ),
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.close, color: Color(0xFF573353)),
//                       onPressed: () => Navigator.pop(context),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 24),
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Text(
//                       studentName,
//                       style: TextStyle(
//                         fontSize: 16,
//                         color: AppColors.primaryColor,
//                       ),
//                     ),
//                     const SizedBox(height: 24),
//                     GestureDetector(
//                       onTap: () => Navigator.pop(context),
//                       child: Container(
//                         width: double.infinity,
//                         padding: const EdgeInsets.symmetric(vertical: 16),
//                         decoration: BoxDecoration(
//                           gradient: const LinearGradient(
//                             colors: [Color(0xFF7175F4), Color(0xFF9287F4)],
//                             begin: Alignment.centerLeft,
//                             end: Alignment.centerRight,
//                           ),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         alignment: Alignment.center,
//                         child: const Text(
//                           'Close',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   void _showStudentsDialog(
//     BuildContext context,
//     List<StudentDataModel> students,
//   ) {
//     showDialog(
//       context: context,
//       builder: (context) {
//         return Dialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(16),
//           ),
//           insetPadding: const EdgeInsets.symmetric(
//             horizontal: 16,
//             vertical: 24,
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               Container(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 16,
//                   vertical: 16,
//                 ),
//                 decoration: const BoxDecoration(
//                   color: Color(0xFFF2F2FF),
//                   borderRadius: BorderRadius.only(
//                     topLeft: Radius.circular(16),
//                     topRight: Radius.circular(16),
//                   ),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Text(
//                       'Students',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFF573353),
//                       ),
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.close, color: Color(0xFF573353)),
//                       onPressed: () => Navigator.pop(context),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 24),
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     SizedBox(
//                       width: double.maxFinite,
//                       child: ListView.builder(
//                         shrinkWrap: true,
//                         itemCount: students.length,
//                         itemBuilder: (context, index) {
//                           return ListTile(
//                             leading: Container(
//                               height: MediaQuery.of(context).size.width * 0.1,
//                               width: MediaQuery.of(context).size.width * 0.1,
//                               decoration: BoxDecoration(
//                                 shape: BoxShape.circle,
//                                 border: Border.all(
//                                   color: Colors.white,
//                                   width: 2,
//                                 ),
//                               ),
//                               child: ClipOval(
//                                 child: BlocProvider(
//                                   create: (context) => sl<DocumentBloc>(),
//                                   child: DocumentImageWidget(
//                                     fileUuid: students[index].photoUuid,
//                                     name: students[index].fullName,
//                                     size:
//                                         MediaQuery.of(context).size.width * 0.1,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                             title: Text(
//                               students[index].fullName,
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 color: AppColors.primaryColor,
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                     const SizedBox(height: 24),
//                     GestureDetector(
//                       onTap: () => Navigator.pop(context),
//                       child: Container(
//                         width: double.infinity,
//                         padding: const EdgeInsets.symmetric(vertical: 16),
//                         decoration: BoxDecoration(
//                           gradient: const LinearGradient(
//                             colors: [Color(0xFF7175F4), Color(0xFF9287F4)],
//                             begin: Alignment.centerLeft,
//                             end: Alignment.centerRight,
//                           ),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         alignment: Alignment.center,
//                         child: const Text(
//                           'Close',
//                           style: TextStyle(
//                             color: Colors.white,
//                             fontSize: 16,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GlobalScaffold(
//       isGloballyScrollable: false,
//       body: BlocListener<DailyActivityCubit, DailyActivityState>(
//         listener: (context, state) {
//           if (state is ActivityCreated) {
//             setState(() {
//               refreshPage();
//             });
//           }
//         },
//         child: SafeArea(
//           child: Column(
//             children: [
//               SizedBox(
//                 width: double.infinity,
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Container(
//                       constraints: BoxConstraints(
//                         maxWidth: context.width * 0.5,
//                       ),
//                       height: MediaQuery.of(context).size.height * 0.06,
//                       child: Row(
//                         children: [
//                           _buildTabToggleButton(
//                             isSelected: _tabController.index == 0,
//                             onPressed: () => _tabController.animateTo(0),
//                             text: "Daily",
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               SizedBox(height: MediaQuery.of(context).size.height * 0.025),
//               _buildFilterSection(_tabController.index),
//               SizedBox(height: MediaQuery.of(context).size.height * 0.025),
//               Expanded(
//                 child: TabBarView(
//                   controller: _tabController,
//                   children: [_buildTimelineSection()],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildFilterSection(int currentTabIndex) {
//     return Container(
//       padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.025),
//       decoration: BoxDecoration(
//         border: Border.all(color: AppColors.dividerColor),
//         borderRadius: BorderRadius.circular(12),
//         color: Colors.white,
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Row(
//             children: [
//               Expanded(
//                 child: CustomDropdown(
//                   hintText: selectedStudentName?.isNotEmpty ?? false
//                       ? selectedStudentName!
//                       : 'Select Student',
//                   items: allStudents
//                       .map((student) => student.fullName)
//                       .toList(),
//                   initialValue: selectedStudentName?.isNotEmpty ?? false
//                       ? selectedStudentName
//                       : null,
//                   onSelect: (value) {
//                     final selectedStudent = allStudents.firstWhere(
//                       (student) => student.fullName == value,
//                     );

//                     setState(() {
//                       studentId = selectedStudent.id;
//                       selectedStudentName = selectedStudent.fullName;
//                     });

//                     getAllDailyActivities(
//                       studentId: studentId,
//                       startDate: selectedStartDate,
//                       endDate: selectedEndDate,
//                     );
//                   },
//                 ),
//               ),
//             ],
//           ),
//           SizedBox(height: MediaQuery.of(context).size.height * 0.01),
//           currentTabIndex == 0
//               ? CustomDateTimeField(
//                   hasLabel: false,
//                   isRangePicker: false,
//                   initialDate: selectedStartDate,
//                   label: 'Date Range',
//                   onDateSelected: (value) {
//                     selectedStartDate = value;
//                     selectedEndDate = value;

//                     getAllDailyActivities(
//                       studentId: widget.studentId,
//                       startDate: selectedStartDate,
//                       endDate: selectedEndDate,
//                     );
//                   },
//                 )
//               : const CustomDateTimeField(hasLabel: false, isRangePicker: true),
//         ],
//       ),
//     );
//   }
// }

// class ActivityShimmerCard extends StatelessWidget {
//   const ActivityShimmerCard({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       margin: EdgeInsets.only(
//         bottom: MediaQuery.of(context).size.height * 0.01,
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Column(
//             children: [
//               Shimmer.fromColors(
//                 baseColor: Colors.grey[300]!,
//                 highlightColor: Colors.grey[100]!,
//                 child: Container(
//                   width: MediaQuery.of(context).size.width * 0.05,
//                   height: MediaQuery.of(context).size.width * 0.05,
//                   decoration: const BoxDecoration(
//                     color: Colors.white,
//                     shape: BoxShape.circle,
//                   ),
//                 ),
//               ),
//               Shimmer.fromColors(
//                 baseColor: Colors.grey[300]!,
//                 highlightColor: Colors.grey[300]!,
//                 child: Container(
//                   width: 3,
//                   height: MediaQuery.of(context).size.height * 0.2,
//                   color: Colors.white,
//                 ),
//               ),
//             ],
//           ),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Shimmer.fromColors(
//                       baseColor: Colors.grey[300]!,
//                       highlightColor: Colors.grey[300]!,
//                       child: Container(
//                         color: Colors.white,
//                         width: context.width * 0.25,
//                         height: 3,
//                       ),
//                     ),
//                     Shimmer.fromColors(
//                       baseColor: Colors.grey[300]!,
//                       highlightColor: Colors.grey[300]!,
//                       child: Container(
//                         height: MediaQuery.of(context).size.width * 0.05,
//                         width: MediaQuery.of(context).size.width * 0.05,
//                         decoration: const BoxDecoration(
//                           color: Colors.white,
//                           shape: BoxShape.circle,
//                         ),
//                       ),
//                     ),
//                     SizedBox(width: MediaQuery.of(context).size.width * 0.04),
//                     Shimmer.fromColors(
//                       baseColor: Colors.grey[300]!,
//                       highlightColor: Colors.grey[300]!,
//                       child: Container(
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(6),
//                         ),
//                         width: MediaQuery.of(context).size.width * 0.15,
//                         height: MediaQuery.of(context).size.width * 0.05,
//                       ),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: MediaQuery.of(context).size.height * 0.015),
//                 Shimmer.fromColors(
//                   baseColor: Colors.grey[300]!,
//                   highlightColor: Colors.grey[300]!,
//                   child: Container(
//                     padding: EdgeInsets.all(
//                       MediaQuery.of(context).size.width * 0.03,
//                     ),
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(8),
//                       color: Colors.white,
//                     ),
//                     height: MediaQuery.of(context).size.height * 0.15,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
