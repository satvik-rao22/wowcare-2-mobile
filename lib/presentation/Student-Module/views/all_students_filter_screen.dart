// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:schoolerp/core/common/widgets/custom_button_layout.dart';
// import 'package:schoolerp/core/common/widgets/custom_multi_select_dropdown.dart';
// import 'package:schoolerp/core/common/widgets/custom_scaffold.dart';
// import 'package:schoolerp/core/common/widgets/custom_shimmer_loader.dart';
// import 'package:schoolerp/core/helpers/filter_data_helper.dart';
// import 'package:schoolerp/core/res/colors.dart';
// import 'package:schoolerp/core/services/api_services/classroom_service.dart';
// import 'package:schoolerp/core/services/api_services/master_lookup_service.dart';
// import 'package:schoolerp/core/services/api_services/tag_service.dart';
// import 'package:schoolerp/core/util/core_utils.dart';
// import 'package:schoolerp/features/Tags/presentation/cubit/tag_data_cubit.dart';
// import 'package:schoolerp/features/classroom/presentation/cubit/classroom_cubit.dart';
// import 'package:schoolerp/features/masterLookup/presentation/cubit/masterlookup_cubit.dart';

// class AllStudentsFilterScreen extends StatefulWidget {
//   final FilterData? initialFilters;

//   const AllStudentsFilterScreen({
//     super.key,
//     this.initialFilters,
//   });

//   @override
//   State<AllStudentsFilterScreen> createState() =>
//       _AllStudentsFilterScreenState();
// }

// class _AllStudentsFilterScreenState extends State<AllStudentsFilterScreen> {
//   final List<String> _labelList = ['Classroom', 'Status', 'Tag'];
//   List<int> _classroomIdList = [];
//   List<String> _classroomList = [];
//   List<String> _statusList = [];
//   List<String> _tagList = [];
//   List<int> _selectedClassroomIdList = [];
//   List<String> _selectedClassroomList = [];
//   List<String> _selectedStatusList = [];
//   List<String> _selectedTagList = [];

//   void _syncClassroomIds() {
//     _selectedClassroomIdList.clear();
//     for (final classroomName in _selectedClassroomList) {
//       final index = _classroomList.indexOf(classroomName);
//       if (index != -1 && index < _classroomIdList.length) {
//         _selectedClassroomIdList.add(_classroomIdList[index]);
//       }
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     if (widget.initialFilters != null) {
//       _selectedClassroomIdList = List.from(widget.initialFilters!.classroomIds);
//       _selectedClassroomList = List.from(widget.initialFilters!.classrooms);
//       _selectedStatusList = List.from(widget.initialFilters!.statuses);
//       _selectedTagList = List.from(widget.initialFilters!.tags);
//     }
//     _fetchFilterData();
//   }

//   void _fetchFilterData() async {
//     ClassroomService.getAllClassrooms(context);
//     MasterLookupService.getAllMasterLookups(
//       context,
//       type: 'Profile Status',
//       valueNotEquals: 'I',
//     );
//     TagService.getAllTags(context);
//   }

//   void _applyFilters() {
//     _syncClassroomIds();

//     final filterData = FilterData.createWithTagMapping(
//       classroomIds: _selectedClassroomIdList,
//       classrooms: _selectedClassroomList,
//       statuses: _selectedStatusList,
//       tags: _selectedTagList,
//     );
//     Navigator.pop(context, filterData);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GlobalScaffold(
//       hasBackButton: true,
//       showCustomNavigationBar: false,
//       customButtonLayout: CustomButtonLayout(
//         showCancelButton: false,
//         confirmButtonLabel: 'Apply Filters',
//         onPressedConfirm: _applyFilters,
//       ),
//       body: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Padding(
//             padding: EdgeInsets.only(left: 4, top: 8),
//             child: Text(
//               'Filter Students',
//               style: TextStyle(
//                 color: AppColors.primaryColor,
//                 fontSize: 17,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//           const SizedBox(height: 12),
//           Expanded(
//             child: Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 border: Border.all(color: AppColors.cardBorderColor),
//                 borderRadius: BorderRadius.circular(12),
//                 color: AppColors.cardColor,
//               ),
//               child: BlocConsumer<ClassroomCubit, ClassroomState>(
//                 listener: (context, state) {
//                   if (state is ClassroomError) {
//                     CoreUtils.showTopSnackBar(
//                       context: context,
//                       isError: true,
//                       message: 'Error Loading Filters',
//                     );
//                   } else if (state is ClassroomLoaded) {
//                     setState(() {
//                       _classroomIdList =
//                           state.classrooms.map((e) => e.id).toList();
//                       _classroomList =
//                           state.classrooms.map((e) => e.name).toList();

//                       _selectedClassroomIdList.removeWhere(
//                         (item) => !_classroomIdList.contains(item),
//                       );
//                       _selectedClassroomList.removeWhere(
//                         (item) => !_classroomList.contains(item),
//                       );

//                       _syncClassroomIds();
//                     });
//                   }
//                 },
//                 builder: (context, classroomState) {
//                   return BlocConsumer<MasterlookupCubit, MasterlookupState>(
//                     listener: (context, state) {
//                       if (state is AuthErrorMasterLookup) {
//                         CoreUtils.showTopSnackBar(
//                           context: context,
//                           isError: true,
//                           message: 'Error Loading Filters',
//                         );
//                       } else if (state is MasterLookupLoaded) {
//                         setState(() {
//                           _statusList =
//                               state.masterLookups.map((e) => e.name).toList();

//                           // Now that _statusList contains 'Inactive', this line
//                           // will no longer remove it when it's pre-selected.
//                           _selectedStatusList.removeWhere(
//                             (item) => !_statusList.contains(item),
//                           );

//                           // This default logic still works perfectly for the initial case.
//                           if (_selectedStatusList.isEmpty &&
//                               _statusList.contains('Active')) {
//                             _selectedStatusList.add('Active');
//                           }
//                         });
//                       }
//                     },
//                     builder: (context, masterLookupState) {
//                       return BlocConsumer<TagDataCubit, TagDataState>(
//                         listener: (context, state) {
//                           if (state is TagError) {
//                             CoreUtils.showTopSnackBar(
//                               context: context,
//                               isError: true,
//                               message: 'Error Loading Filters',
//                             );
//                           } else if (state is AllTagDataLoaded) {
//                             setState(() {
//                               _tagList = state.tags.map((e) => e.name).toList();

//                               _selectedTagList.removeWhere(
//                                 (item) => !_tagList.contains(item),
//                               );
//                             });
//                           }
//                         },
//                         builder: (context, tagState) {
//                           if (classroomState is ClassroomLoaded &&
//                               masterLookupState is MasterLookupLoaded &&
//                               tagState is AllTagDataLoaded) {
//                             final _dropdownLists = [
//                               _classroomList,
//                               _statusList,
//                               _tagList,
//                             ];

//                             final _selectedDropdownLists = [
//                               _selectedClassroomList,
//                               _selectedStatusList,
//                               _selectedTagList,
//                             ];

//                             return GridView.builder(
//                               itemCount: _dropdownLists.length,
//                               gridDelegate:
//                                   const SliverGridDelegateWithFixedCrossAxisCount(
//                                 crossAxisCount: 2,
//                                 crossAxisSpacing: 16,
//                                 mainAxisSpacing: 16,
//                                 childAspectRatio: 2,
//                               ),
//                               itemBuilder: (context, index) =>
//                                   CustomMultiSelectDropdown(
//                                 label: _labelList[index],
//                                 hintText: 'Select',
//                                 items: _dropdownLists[index],
//                                 selectedItems: _selectedDropdownLists[index],
//                                 onChanged: (selectedItems) {
//                                   setState(() {
//                                     _selectedDropdownLists[index].clear();
//                                     _selectedDropdownLists[index]
//                                         .addAll(selectedItems);

//                                     if (index == 0) {
//                                       _syncClassroomIds();
//                                     }
//                                   });
//                                 },
//                               ),
//                             );
//                           }
//                           return GridView.builder(
//                             itemCount: 3,
//                             gridDelegate:
//                                 const SliverGridDelegateWithFixedCrossAxisCount(
//                               crossAxisCount: 2,
//                               crossAxisSpacing: 16,
//                               mainAxisSpacing: 16,
//                               childAspectRatio: 2,
//                             ),
//                             itemBuilder: (context, index) => Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   _labelList[index],
//                                   style: TextStyle(
//                                     color: AppColors.primaryColor
//                                         .withValues(alpha: 0.5),
//                                     fontSize: 13,
//                                     fontWeight: FontWeight.w400,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 8),
//                                 const ShimmerLoader(height: 40),
//                               ],
//                             ),
//                           );
//                         },
//                       );
//                     },
//                   );
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
