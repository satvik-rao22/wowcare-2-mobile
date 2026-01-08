import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/activities/view/view_activity_screens/view_bathroom_activity.dart';
import 'package:wowcare/presentation/features/activities/view/view_activity_screens/view_bottle_activity.dart';
import 'package:wowcare/presentation/features/activities/view/view_activity_screens/view_incident_activity.dart';
import 'package:wowcare/presentation/features/activities/view/view_activity_screens/view_learning_activity.dart';
import 'package:wowcare/presentation/features/activities/view/view_activity_screens/view_meal_activity.dart';
import 'package:wowcare/presentation/features/activities/view/view_activity_screens/view_medication_activity.dart';
import 'package:wowcare/presentation/features/activities/view/view_activity_screens/view_nap_activity.dart';
import 'package:wowcare/presentation/features/activities/view/view_activity_screens/view_notes_activity.dart';
import 'package:wowcare/presentation/features/activities/view/view_activity_screens/view_outdoor_activity.dart';
import 'package:wowcare/presentation/features/activities/view/view_activity_screens/view_photo_activity.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';

import '../../../../shared/common/views/filter_screen.dart';
import '../../../../shared/common/widgets/custom_dropdown.dart';
import '../../../../shared/utils/responsive_helper.dart';
import '../widgets/avtivity_media_preview.dart';
import 'activity_daily_tab.dart';
import 'edit_create_activity_screens/bathroom_activity.dart';
import 'edit_create_activity_screens/bottle_activity.dart';
import 'edit_create_activity_screens/incident_activity.dart';
import 'edit_create_activity_screens/meal_activity.dart';
import 'edit_create_activity_screens/medication_activity.dart';
import 'edit_create_activity_screens/nap_activity.dart';
import 'edit_create_activity_screens/photo_activity.dart';

class ActivityCustomTab extends StatefulWidget {
  const ActivityCustomTab({
    super.key,
    this.fromStudentProfile = false,
    this.studentName,
    this.isNotParent = true,
  });

  final bool fromStudentProfile;
  final String? studentName;
  final bool isNotParent;

  static const String routeName = '/activityCustomTab';

  @override
  State<ActivityCustomTab> createState() => _ActivityCustomTabState();
}

class _ActivityCustomTabState extends State<ActivityCustomTab> {
  late bool isNotParent;

  DateTime? _selectedStartDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  );
  DateTime? _selectedEndDate = DateTime(
    DateTime.now().year,
    DateTime.now().month + 1,
    0,
  );
  String? _selectdClassroom;
  String? _selectedStudent;
  List<String> _availableStudents = [];
  List<String> _filterTags = [];
  List<String> _filterActivityTypes = [];
  String? _selectedActivityType;
  final List<String> activityType = [
    'Nap Start',
    'Nap End',
    'Bathroom',
    'Bottle',
    'Meal',
    'Incident',
    'Photo',
    'Outdoor',
    'Medication',
    'Notes',
    'Learning',
    'Sign-in',
    'Sign-out',
    'Absent',
  ];
  final Map<String, List<String>> classroomStudents = {
    '1-Blue D': ['Raghave Gupta', 'Rohan Gupta', 'Ruhi Gupta'],
    '3-Orange-D': ['Anya Mehta', 'Kabir Mehta'],
    '2-Red A': ['Sara Khan'],
  };
  final List<Color> _colorPalette = [
    const Color(0xFFB3E5FC),
    const Color(0xFFFFCCBC),
    const Color(0xFFC8E6C9),
    const Color(0xFFFFE0B2),
    //const Color(0xFFFFF9C4),
    const Color(0xFFE1BEE7),
    //const Color(0xFFCCFF90),
    const Color(0xFF80DEEA),
    const Color(0xFFD1C4E9),
    const Color(0xFFFFAB91),
  ];
  // final List<String> _allStudents = [
  //   'Raghave Gupta',
  //   'Rohan Gupta',
  //   'Ruhi Gupta',
  //   'Anya Mehta',
  //   'Kabir Mehta',
  //   'Sara Khan',
  // ];
  final List<String> _classroomOptions = ['1-Blue D', '3-Orange-D', '2-Red A'];
  final List<ActivityItem> activities = [
    ActivityItem(
        time: "07:10 PM",
        date: 'December 31, 2025',
        name: "Incident",
        description: "incident happened",
        //color: Color(0xFFFFE0B2), // orange
        studentList: ['Kabir Mehta'],
        createdBy: 'Staff A',
        whatHappened: 'incident happened',
        firstAidAdministered: true,
        staffPresent: 'Staff A',
        additionalNotes: 'some notes'

    ),
    ActivityItem(
      time: "07:00 PM",
      date: 'December 31, 2025',
      name: "Nap End",
      description: "Nap Ended at 6:30 PM",
      //color: Color(0xFFFFE0B2), // orange
      studentList: ['Kabir Mehta', 'Sara Khan'],
      createdBy: 'Staff A',
      napStartTime: '6:00 PM',
      napEndTime: '6:30 PM',
    ),
    ActivityItem(
        time: "05:30 PM",
        date: 'December 31, 2025',
        name: "Nap Start",
        description: "Nap Started at 6:00 PM",
        //color: Color(0xFFFFE0B2), // orange
        studentList: ['Kabir Mehta', 'Sara Khan'],
        createdBy: 'Staff A',
        napStartTime: '6:00 PM',
        remainderOn: true
    ),
    ActivityItem(
      time: "05:10 PM",
      date: 'December 30, 2025',
      name: "Medication",
      description: "Medication given",
      //color: Color(0xFFFFE0B2), // orange
      studentList: ['Sara Khan', 'Raghav Gupta'],
      createdBy: 'Staff A',
    ),
    ActivityItem(
      time: "05:00 PM",
      date: 'December 30, 2025',
      name: "Outdoor",
      description: "Outdoor Activity",
      photoUrl:
      'https://images.unsplash.com/photo-1503454537195-1dcabb73ffb9?w=800&referrer=grok.com',
      //color: Color(0xFFFFE0B2), // orange
      // photoUrl:
      //     "https://images.unsplash.com/photo-1570545906912-5b2a3f3c2bab?w=400",
      studentList: ['Kabir Mehta', 'Sara Khan'],
      createdBy: 'Staff A',
    ),
    ActivityItem(
      time: "04:30 PM",
      date: 'December 29, 2025',
      name: "Learning",
      description: "Drawing Activity",
      //color: Color(0xFFB3E5FC), // blue
      photoUrl:
          "https://images.unsplash.com/photo-1503454537195-1dcabb73ffb9?w=800&referrer=grok.com",
      studentList: ['Raghav Gupta'],
      createdBy: 'Staff B',
      categoryType: 'Self Care',
      activityType: 'Morning Time',
    ),
    ActivityItem(
        time: "04:00 PM",
        date: 'December 20, 2025',
        name: "Bathroom",
        description: "Bathroom Activity",
        //color: Color(0xFFB3E5FC), // blue
        studentList: [
          'Sara Khan',
          'Raghav Gupta',
          'Kabir Mehta',
        ],
        createdBy: 'Staff B',
        bathroomType: 'Pee',
        bathroomSubType: 'Accident'
    ),
    ActivityItem(
      time: "02:22 PM",
      date: 'December 19, 2025',
      name: "Meal",
      description: "Lunch (Finished)",
      //color: Color(0xFFC8E6C9), // green
      photoUrl:
          "https://images.unsplash.com/photo-1547573854-74d2a71d0826?w=400",
      studentList: [
        'Sara Khan',
        'Raghav Gupta',
        'Kabir Mehta',
        'Sara Khan',
        'Raghav Gupta',
        'Kabir Mehta',
      ],
      createdBy: 'Staff A',
      mealType: 'Lunch',
      mealQuantity: '8 Oz'
    ),
    ActivityItem(
      time: "02:22 PM",
      date: 'December 12, 2025',
      name: "Photo",
      description: "Lunch (Finished)",
      //color: Color(0xFFC8E6C9), // green
      photoUrl:
          "https://images.unsplash.com/photo-1547573854-74d2a71d0826?w=400",
      studentList: [
        'Sara Khan',
        'Raghav Gupta',
        'Kabir Mehta',
        'Sara Khan',
        'Raghav Gupta',
        'Kabir Mehta',
      ],
      createdBy: 'Staff A',
    ),
    ActivityItem(
      time: "01:00 PM",
      date: 'December 10, 2025',
      name: "Meal",
      description: "Drawing Activity",
      //color: Color(0xFFD1C4E9), // purple
      photoUrl:
          "https://images.unsplash.com/photo-1596461404969-9ae8f10bdd83?w=400",
      studentList: ['Sara Khan', 'Raghav Gupta', 'Kabir Mehta'],
      createdBy: 'Staff B',
      mealType: 'Breakfast',
      mealQuantity: '3 Oz',
    ),
    ActivityItem(
      time: "01:00 PM",
      date: 'December 9, 2025',
      name: "Video",
      description: "Drawing Activity",
      //color: Color(0xFFD1C4E9), // purple
      // photoUrl:
      //     "https://images.unsplash.com/photo-1596461404969-9ae8f10bdd83?w=400",
      //videoUrl: 'https://test-videos.co.uk/vids/bigbuckbunny/mp4/av1/360/Big_Buck_Bunny_360_10s_1MB.mp4',
      videoUrl:
          "https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4",
      studentList: ['Sara Khan', 'Raghav Gupta', 'Kabir Mehta'],
      createdBy: 'Staff B',
    ),
    ActivityItem(
        time: "05:00 PM",
        date: 'December 8, 2025',
        name: "Bottle",
        description: "Bottle Activity",
        //color: Color(0xFFFFE0B2), // orange
        studentList: ['Kabir Mehta', 'Sara Khan'],
        createdBy: 'Staff A',
        amountConsumed: '5 Oz'
    ),
  ];

  static final Map<String, Widget Function(ActivityItem)> editActivityRoutes = {
    'Nap Start': (activity) =>
        NapActivityScreen(activityData: activity, isEdit: true),
    'Nap End': (activity) =>
        NapActivityScreen(activityData: activity, isEdit: true),
    'Bathroom': (activity) =>
        BathroomActivityScreen(activityData: activity, isEdit: true),
    'Bottle': (activity) =>
        BottleActivityScreen(activityData: activity, isEdit: true),
    'Meal': (activity) =>
        MealActivityScreen(activityData: activity, isEdit: true),
    'Incident': (activity) =>
        IncidentActivityScreen(activityData: activity, isEdit: true),
    'Photo': (activity) =>
        PhotoVideoActivityScreen(activityData: activity, isEdit: true, isPhoto: true,),
    'Video': (activity) =>
        PhotoVideoActivityScreen(activityData: activity, isEdit: true, isPhoto: false,),
    'Medication': (activity) =>
        MedicationActivityScreen(activityData: activity, isEdit: true),
    'Notes': (activity) =>
        NapActivityScreen(activityData: activity, isEdit: true),
    'Outdoor': (activity) =>
        NapActivityScreen(activityData: activity, isEdit: true),
    'Learning': (activity) =>
        NapActivityScreen(activityData: activity, isEdit: true),
  };

  // Map activity label to the destination view activity screen
  static final Map<String, Widget Function(ActivityItem)> activityRoutes = {
    'Nap Start': (activity) => ViewNapActivity(activityData: activity),
    'Nap End': (activity) => ViewNapActivity(activityData: activity, isNapStart: false,),
    'Bathroom': (activity) => ViewBathroomActivity(activityData: activity),
    'Bottle': (activity) => ViewBottleActivity(activityData: activity),
    'Meal': (activity) => ViewMealActivity(activityData: activity),
    'Incident': (activity) => ViewIncidentActivity(activityData: activity),
    'Photo': (activity) => ViewPhotoVideoActivity(activityData: activity),
    'Video': (activity) =>
        ViewPhotoVideoActivity(activityData: activity, isVideo: true),
    'Medication': (activity) => ViewMedicationActivity(activityData: activity),
    'Notes': (activity) => ViewNotesActivity(activityData: activity),
    'Outdoor': (activity) => ViewOutdoorActivity(activityData: activity),
    'Learning': (activity) => ViewLearningActivity(activityData: activity),
  };

  static final Map<String, dynamic> activityIcons = {
    'Nap Start': MediaRes.napActivityIcon,
    'Nap End': MediaRes.napActivityIcon,
    'Bathroom': MediaRes.bathroomActivityIcon,
    'Bottle': MediaRes.bottleActivityIcon,
    'Meal': MediaRes.mealActivityIcon,
    'Incident': MediaRes.incidentActivityIcon,
    'Photo': MediaRes.photoVideoActivityIcon,
    'Video': MediaRes.photoVideoActivityIcon,
    'Medication': MediaRes.medicationActivityIcon,
    'Notes': MediaRes.notesActivityIcon,
    'Outdoor': MediaRes.outdoorActivityIcon,
    'Learning': MediaRes.learningActivityIcon,
  };

  @override
  void initState() {
    super.initState();
    _selectdClassroom = _classroomOptions[0];
    _updateAvailableStudents();
    isNotParent = widget.isNotParent;
    //_selectedStudent = _allStudents[0];
  }

  void _updateAvailableStudents() {
    if (_selectdClassroom != null) {
      _availableStudents = classroomStudents[_selectdClassroom] ?? [];
      // If current selected student is not in the new list, clear it
      if (_selectedStudent != null &&
          !_availableStudents.contains(_selectedStudent)) {
        _selectedStudent = null;
      }
    } else {
      _availableStudents = [];
      _selectedStudent = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
        builder: (context, orientation){
          if(orientation == Orientation.landscape){
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child:  Padding(
                  padding: ResponsiveSizing.contentPadding(context),
                  // filter card
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.cardBorderColor),
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.cardColor,
                    ),
                    child: widget.fromStudentProfile
                        ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 65,
                          child: AbsorbPointer(
                            child: _buildCustomDropdown(
                              'Select Student',
                              [?widget.studentName],
                              widget.studentName,
                                  (v) => setState(() {
                                _selectedStudent = v;
                              }),
                              height: 65,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 65,
                          child: _datePickerFilter(
                            selectedStartDate: _selectedStartDate,
                            selectedEndDate: _selectedEndDate,
                            // onDateRangeSelected: (date) {
                            //   List<String>? dates = date?.split('-\n');
                            //   setState(() {
                            //     _selectedStartDate = dates?[0].trim() as DateTime?;
                            //     _selectedEndDate = dates?[1].trim() as DateTime;
                            //
                            //   });
                            // },
                          ),
                        ),
                      ],
                    )
                        : isNotParent
                        ? Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildCustomDropdown(
                                'Select Classroom',
                                _classroomOptions,
                                _selectdClassroom,
                                    (v) => setState(() {
                                  _selectdClassroom = v;
                                  _updateAvailableStudents();
                                }),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              // child: _buildCustomDropdown(
                              //   'Select Student',
                              //   _allStudents,
                              //   _selectedStudent,
                              //       (v) => setState(() {
                              //     _selectedStudent = v;
                              //   }),
                              // ),
                              child: _buildCustomDropdown(
                                _selectdClassroom == null
                                    ? 'Select Classroom First'
                                    : 'Select Student',
                                _availableStudents,
                                _selectedStudent,
                                    (value) {
                                  if (_selectdClassroom != null) {
                                    setState(() {
                                      _selectedStudent = value;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(100),
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FilterScreen(
                                        sections: [
                                          FilerSection(
                                            label: 'Tags',
                                            hintText: 'Select tags',
                                            items: [
                                              '5 Days',
                                              'Full Day',
                                              'Photo Permission',
                                              'Vegetarian',
                                              'First Aid',
                                              'Allergy',
                                              'Pickup Authorized',
                                              'Medication',
                                              'Half Day',
                                              'Boy',
                                              'Girl',
                                            ],
                                            initialSelected: _filterTags,
                                            isMultiSelectDropDown: false,
                                          ),
                                          FilerSection(
                                            label: 'Activity Type',
                                            hintText: 'Select Activity',
                                            items: [
                                              'Nap Start',
                                              'Nap End',
                                              'Bathroom',
                                              'Bottle',
                                              'Meal',
                                              'Incident',
                                              'Photo',
                                              'Outdoor',
                                              'Medication',
                                              'Notes',
                                              'Learning',
                                              'Sign-in',
                                              'Sign-out',
                                              'Absent',
                                            ],
                                            initialSelected: _filterActivityTypes,
                                            isMultiSelectDropDown: false,
                                          ),
                                        ],
                                        onApply: (filters) {
                                          setState(() {
                                            _filterTags = filters['Tags']!;
                                            _filterActivityTypes =
                                            filters['Activity Type']!;
                                          });
                                        },
                                      ),
                                    ),
                                  );
                                  if (!mounted) return;
                                  if (result is Map) {
                                    // TODO: apply filters to list
                                    setState(() {});
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: SvgPicture.asset(
                                    MediaRes.filterIcon,
                                    height: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: _datePickerFilter(
                                selectedStartDate: _selectedStartDate,
                                selectedEndDate: _selectedEndDate,
                              ),
                            ),
                            const SizedBox(width: 8),
                            CustomClearAllChip(
                              onTap: () {
                                setState(() {
                                  _selectdClassroom = _classroomOptions[0];
                                  _selectedStudent = null;
                                  _filterActivityTypes.clear();
                                  _filterTags.clear();
                                });
                              },
                              label: 'Clear All',
                            ),
                          ],
                        ),
                      ],
                    )
                        : Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 65,
                            child: _datePickerFilter(
                              selectedStartDate: _selectedStartDate,
                              selectedEndDate: _selectedEndDate,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 65,
                            child: _buildCustomDropdown(
                              'Activity Type',
                              activityType,
                              _selectedActivityType,
                                  (v) => setState(() {
                                _selectedActivityType = v;
                              }),
                              height: 65,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),),
                SliverToBoxAdapter(child: SizedBox(height: 12,),),
                if(activities.isEmpty)
                  SliverToBoxAdapter(child: Padding(
                    padding: ResponsiveSizing.contentPadding(context),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.cardBorderColor),
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.cardColor,
                      ),
                      child: Center(
                        child: Text(
                          'No Activities found',
                          style: TextStyle(
                            color: Colors.black,
                            fontFamily: 'Manrope',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),),
                if(activities.isNotEmpty)
                  SliverPadding(
                    padding: ResponsiveSizing.contentPadding(context),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                              (context, index){
                            final activity = activities[index];
                            final students = activity.studentList;
                            final Color activityColor =
                            _colorPalette[index % _colorPalette.length];

                            return Column(
                              children: [
                                Row(
                                  children: [
                                    Column(
                                      children: [
                                        Container(
                                          width: 18,
                                          height: 18,
                                          decoration: BoxDecoration(
                                            //color: activity.color,
                                            color: activityColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        Container(
                                          width: 4,
                                          height: 2,
                                          //color: activity.color,
                                          color: activityColor,
                                        ),
                                      ],
                                    ),
                                    Container(
                                      width: 100,
                                      height: 4,
                                      //color: activity.color,
                                      color: activityColor,
                                    ),
                                    Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        //color: activity.color,
                                        color: activityColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    SizedBox(
                                      height: 20,
                                      child: Text(
                                        activity.time,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.primaryColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(width: 7),
                                    Container(
                                      width: 4,
                                      height: 220,
                                      //color: activity.color,
                                      color: activityColor,
                                    ),

                                    const SizedBox(width: 16),

                                    // Activity Card
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Column(
                                          children: [
                                            const SizedBox(height: 15),
                                            InkWell(
                                              onTap: () {
                                                final destinationBuilder =
                                                activityRoutes[activity
                                                    .name];
                                                if (destinationBuilder !=
                                                    null) {
                                                  final nextScreen =
                                                  destinationBuilder(
                                                    activity,
                                                  );
                                                  Navigator.of(
                                                    context,
                                                  ).push(
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                      nextScreen,
                                                    ),
                                                  );
                                                }
                                              },
                                              child: Container(
                                                height: 180,
                                                margin: const EdgeInsets.only(
                                                  bottom: 24,
                                                ),
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: activityColor.withOpacity(
                                                    0.15,
                                                  ),
                                                  borderRadius: BorderRadius.circular(
                                                    16,
                                                  ),
                                                  border: Border.all(
                                                    color: activityColor.withOpacity(
                                                      0.4,
                                                    ),
                                                  ),
                                                ),
                                                child: Row(
                                                  // crossAxisAlignment:
                                                  //     CrossAxisAlignment.center,
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius:
                                                      BorderRadius.circular(12),
                                                      child: SizedBox(
                                                        width: 140,
                                                        height: 120,
                                                        child:
                                                        activity.photoUrl != null ||
                                                            activity.videoUrl !=
                                                                null
                                                            ? ActivityMediaPreview(
                                                          activity: activity,
                                                          activityColor:
                                                          activityColor,
                                                        )
                                                        // ? Image.network(
                                                        //     activity.photoUrl!,
                                                        //     fit: BoxFit.cover,
                                                        //     loadingBuilder:
                                                        //         (
                                                        //           context,
                                                        //           child,
                                                        //           loadingProgress,
                                                        //         ) {
                                                        //           if (loadingProgress ==
                                                        //               null)
                                                        //             return child;
                                                        //           return Container(
                                                        //             color: Colors
                                                        //                 .transparent,
                                                        //             child: const Center(
                                                        //               child: CircularProgressIndicator(
                                                        //                 strokeWidth:
                                                        //                     2,
                                                        //               ),
                                                        //             ),
                                                        //           );
                                                        //         },
                                                        //     errorBuilder:
                                                        //         (
                                                        //           context,
                                                        //           error,
                                                        //           stackTrace,
                                                        //         ) {
                                                        //           return Container(
                                                        //             width: 122,
                                                        //             height: 76,
                                                        //             color: activity
                                                        //                 .color
                                                        //                 .withOpacity(
                                                        //                   0.25,
                                                        //                 ),
                                                        //             child: Center(
                                                        //               child: Image.asset(
                                                        //                 activityIcons[activity
                                                        //                     .name],
                                                        //                 //'assets/icons/activity-nap-icon.png',
                                                        //                 fit: BoxFit
                                                        //                     .fill,
                                                        //               ),
                                                        //             ),
                                                        //           );
                                                        //         },
                                                        //   )
                                                            : Container(
                                                          width: 122,
                                                          height: 76,
                                                          color: Colors.white,
                                                          // color: activityColor
                                                          //     .withOpacity(0.25),
                                                          child: Center(
                                                            child: Image.asset(
                                                              activityIcons[activity
                                                                  .name],
                                                              //'assets/icons/activity-nap-icon.png',
                                                              fit: BoxFit.fill,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                        mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceEvenly,
                                                        children: [
                                                          Row(
                                                            mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                            children: [
                                                              Container(
                                                                padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 12,
                                                                  vertical: 6,
                                                                ),
                                                                decoration: BoxDecoration(
                                                                  color: activityColor,
                                                                  borderRadius:
                                                                  BorderRadius.circular(
                                                                    20,
                                                                  ),
                                                                ),
                                                                child: Text(
                                                                  activity.name,
                                                                  style:
                                                                  const TextStyle(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize: 11,
                                                                    fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                  ),
                                                                ),
                                                              ),
                                                              PopupMenuButton<String>(
                                                                icon: const Icon(
                                                                  Icons.more_horiz,
                                                                  size: 20,
                                                                ),
                                                                onSelected: null,
                                                                itemBuilder: (context) => [
                                                                  PopupMenuItem<String>(
                                                                    value: 'view',
                                                                    child: PopupItem(
                                                                      title: 'View',
                                                                      icon: Icon(
                                                                        Icons
                                                                            .visibility_outlined,
                                                                        color: AppColors
                                                                            .themeColor,
                                                                      ),
                                                                    ),
                                                                    onTap: () {
                                                                      final destinationBuilder =
                                                                      activityRoutes[activity
                                                                          .name];
                                                                      if (destinationBuilder !=
                                                                          null) {
                                                                        final nextScreen =
                                                                        destinationBuilder(
                                                                          activity,
                                                                        );
                                                                        Navigator.of(
                                                                          context,
                                                                        ).push(
                                                                          MaterialPageRoute(
                                                                            builder: (_) =>
                                                                            nextScreen,
                                                                          ),
                                                                        );
                                                                      }
                                                                    },
                                                                  ),
                                                                  PopupMenuItem<String>(
                                                                    value: 'edit',
                                                                    child: PopupItem(
                                                                      title: 'Edit',
                                                                      icon: Icon(
                                                                        Icons.edit,
                                                                        color: AppColors
                                                                            .themeColor,
                                                                      ),
                                                                    ),
                                                                    onTap: () {
                                                                      final destinationBuilder =
                                                                      editActivityRoutes[activity
                                                                          .name];
                                                                      if (destinationBuilder !=
                                                                          null) {
                                                                        final nextScreen =
                                                                        destinationBuilder(
                                                                          activity,
                                                                        );
                                                                        Navigator.of(
                                                                          context,
                                                                        ).push(
                                                                          MaterialPageRoute(
                                                                            builder: (_) =>
                                                                            nextScreen,
                                                                          ),
                                                                        );
                                                                      }
                                                                    },
                                                                  ),
                                                                  PopupMenuItem<String>(
                                                                    value: 'delete',
                                                                    child: PopupItem(
                                                                      title: 'Delete',
                                                                      icon: Icon(
                                                                        Icons.delete,
                                                                        color: AppColors
                                                                            .themeColor,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(height: 10),

                                                          SizedBox(
                                                            height: 32,
                                                            child: Stack(
                                                              children: [
                                                                for (
                                                                int i = 0;
                                                                i < students.length &&
                                                                    i < 4;
                                                                i++
                                                                )
                                                                  Positioned(
                                                                    left: i * 20,
                                                                    child:
                                                                    DocumentImageWidget(
                                                                      fileUuid: '',
                                                                      name:
                                                                      students[i],
                                                                      size: 28,
                                                                      fontSize: 10,
                                                                    ),
                                                                  ),

                                                                // Extra count tooltip
                                                                if (students.length > 4)
                                                                  Positioned(
                                                                    left:
                                                                    4 *
                                                                        20, // after 4 avatars
                                                                    child: Tooltip(
                                                                      message: students
                                                                          .skip(4)
                                                                          .join(', '),
                                                                      child: DocumentImageWidget(
                                                                        fileUuid: '',
                                                                        name:
                                                                        '+${students.length - 4}',
                                                                        size: 28,
                                                                        fontSize: 10,
                                                                      ),
                                                                    ),
                                                                  ),
                                                              ],
                                                            ),
                                                          ),
                                                          const SizedBox(height: 10),

                                                          Text(
                                                            activity.description ?? 'No description',

                                                            style: TextStyle(
                                                              color: AppColors
                                                                  .primaryColor,
                                                              fontSize: 14,
                                                              fontWeight:
                                                              FontWeight.w600,
                                                            ),
                                                            maxLines: 1,
                                                            overflow:
                                                            TextOverflow.ellipsis,
                                                          ),
                                                          const SizedBox(height: 10),
                                                          Text(
                                                            'Created By - ${activity.createdBy}',

                                                            style: TextStyle(
                                                              color: AppColors
                                                                  .primaryColor,
                                                              fontSize: 12,
                                                              fontWeight:
                                                              FontWeight.w500,
                                                            ),
                                                            maxLines: 1,
                                                            overflow:
                                                            TextOverflow.ellipsis,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                          childCount: activities.length
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 20,),)
              ],
            );
            return SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: ResponsiveSizing.contentPadding(context),
                    // filter card
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.cardBorderColor),
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.cardColor,
                      ),
                      child: widget.fromStudentProfile
                          ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: 65,
                            child: AbsorbPointer(
                              child: _buildCustomDropdown(
                                'Select Student',
                                [?widget.studentName],
                                widget.studentName,
                                    (v) => setState(() {
                                  _selectedStudent = v;
                                }),
                                height: 65,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 65,
                            child: _datePickerFilter(
                              selectedStartDate: _selectedStartDate,
                              selectedEndDate: _selectedEndDate,
                              // onDateRangeSelected: (date) {
                              //   List<String>? dates = date?.split('-\n');
                              //   setState(() {
                              //     _selectedStartDate = dates?[0].trim() as DateTime?;
                              //     _selectedEndDate = dates?[1].trim() as DateTime;
                              //
                              //   });
                              // },
                            ),
                          ),
                        ],
                      )
                          : isNotParent
                          ? Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildCustomDropdown(
                                  'Select Classroom',
                                  _classroomOptions,
                                  _selectdClassroom,
                                      (v) => setState(() {
                                    _selectdClassroom = v;
                                    _updateAvailableStudents();
                                  }),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                // child: _buildCustomDropdown(
                                //   'Select Student',
                                //   _allStudents,
                                //   _selectedStudent,
                                //       (v) => setState(() {
                                //     _selectedStudent = v;
                                //   }),
                                // ),
                                child: _buildCustomDropdown(
                                  _selectdClassroom == null
                                      ? 'Select Classroom First'
                                      : 'Select Student',
                                  _availableStudents,
                                  _selectedStudent,
                                      (value) {
                                    if (_selectdClassroom != null) {
                                      setState(() {
                                        _selectedStudent = value;
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(100),
                                  onTap: () async {
                                    final result = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => FilterScreen(
                                          sections: [
                                            FilerSection(
                                              label: 'Tags',
                                              hintText: 'Select tags',
                                              items: [
                                                '5 Days',
                                                'Full Day',
                                                'Photo Permission',
                                                'Vegetarian',
                                                'First Aid',
                                                'Allergy',
                                                'Pickup Authorized',
                                                'Medication',
                                                'Half Day',
                                                'Boy',
                                                'Girl',
                                              ],
                                              initialSelected: _filterTags,
                                              isMultiSelectDropDown: false,
                                            ),
                                            FilerSection(
                                              label: 'Activity Type',
                                              hintText: 'Select Activity',
                                              items: [
                                                'Nap Start',
                                                'Nap End',
                                                'Bathroom',
                                                'Bottle',
                                                'Meal',
                                                'Incident',
                                                'Photo',
                                                'Outdoor',
                                                'Medication',
                                                'Notes',
                                                'Learning',
                                                'Sign-in',
                                                'Sign-out',
                                                'Absent',
                                              ],
                                              initialSelected: _filterActivityTypes,
                                              isMultiSelectDropDown: false,
                                            ),
                                          ],
                                          onApply: (filters) {
                                            setState(() {
                                              _filterTags = filters['Tags']!;
                                              _filterActivityTypes =
                                              filters['Activity Type']!;
                                            });
                                          },
                                        ),
                                      ),
                                    );
                                    if (!mounted) return;
                                    if (result is Map) {
                                      // TODO: apply filters to list
                                      setState(() {});
                                    }
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: SvgPicture.asset(
                                      MediaRes.filterIcon,
                                      height: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: _datePickerFilter(
                                  selectedStartDate: _selectedStartDate,
                                  selectedEndDate: _selectedEndDate,
                                ),
                              ),
                              const SizedBox(width: 8),
                              CustomClearAllChip(
                                onTap: () {
                                  setState(() {
                                    _selectdClassroom = _classroomOptions[0];
                                    _selectedStudent = null;
                                    _filterActivityTypes.clear();
                                    _filterTags.clear();
                                  });
                                },
                                label: 'Clear All',
                              ),
                            ],
                          ),
                        ],
                      )
                          : Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 65,
                              child: _datePickerFilter(
                                selectedStartDate: _selectedStartDate,
                                selectedEndDate: _selectedEndDate,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SizedBox(
                              height: 65,
                              child: _buildCustomDropdown(
                                'Activity Type',
                                activityType,
                                _selectedActivityType,
                                    (v) => setState(() {
                                  _selectedActivityType = v;
                                }),
                                height: 65,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (activities.length == 0)
                    Padding(
                      padding: ResponsiveSizing.contentPadding(context),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.cardBorderColor),
                          borderRadius: BorderRadius.circular(12),
                          color: AppColors.cardColor,
                        ),
                        child: Center(
                          child: Text(
                            'No Activities found',
                            style: TextStyle(
                              color: Colors.black,
                              fontFamily: 'Manrope',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),

                  if (activities.length != 0)
                    Padding(
                      padding: ResponsiveSizing.contentPadding(context),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(right: 16),
                            itemCount: activities.length,
                            itemBuilder: (context, index) {
                              final activity = activities[index];
                              final students = activity.studentList;
                              final Color activityColor = _colorPalette[index % _colorPalette.length];

                              return Column(
                                children: [
                                  Row(
                                    children: [
                                      Column(
                                        children: [
                                          Container(
                                            width: 18,
                                            height: 18,
                                            decoration: BoxDecoration(
                                              color: activityColor,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          Container(
                                            width: 4,
                                            height: 2,
                                            color: activityColor,
                                          ),
                                        ],
                                      ),
                                      Container(
                                        width: 100,
                                        height: 4,
                                        color: activityColor,
                                      ),
                                      Container(
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          color: activityColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      SizedBox(
                                        height: 20,
                                        child: Text(
                                          activity.time,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppColors.primaryColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(width: 7),
                                      Container(
                                        width: 4,
                                        height: 220,
                                        color: activityColor,
                                      ),

                                      const SizedBox(width: 16),

                                      // Activity Card
                                      Column(
                                        children: [
                                          const SizedBox(height: 15),
                                          Container(
                                            height: 180,
                                            margin: const EdgeInsets.only(
                                              bottom: 24,
                                            ),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: activityColor.withOpacity(
                                                0.15,
                                              ),
                                              borderRadius: BorderRadius.circular(
                                                16,
                                              ),
                                              border: Border.all(
                                                color: activityColor.withOpacity(
                                                  0.4,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              // crossAxisAlignment:
                                              //     CrossAxisAlignment.center,
                                              children: [
                                                ClipRRect(
                                                  borderRadius:
                                                  BorderRadius.circular(12),
                                                  child: SizedBox(
                                                    width: 140,
                                                    height: 120,
                                                    child:
                                                    activity.photoUrl != null || activity.videoUrl != null
                                                        ? ActivityMediaPreview(activity: activity, activityColor: activityColor,)
                                                    // ? Image.network(
                                                    //     activity.photoUrl!,
                                                    //     fit: BoxFit.cover,
                                                    //     loadingBuilder:
                                                    //         (
                                                    //           context,
                                                    //           child,
                                                    //           loadingProgress,
                                                    //         ) {
                                                    //           if (loadingProgress ==
                                                    //               null)
                                                    //             return child;
                                                    //           return Container(
                                                    //             color: Colors
                                                    //                 .transparent,
                                                    //             child: const Center(
                                                    //               child: CircularProgressIndicator(
                                                    //                 strokeWidth:
                                                    //                     2,
                                                    //               ),
                                                    //             ),
                                                    //           );
                                                    //         },
                                                    //     errorBuilder:
                                                    //         (
                                                    //           context,
                                                    //           error,
                                                    //           stackTrace,
                                                    //         ) {
                                                    //           return Container(
                                                    //             width: 122,
                                                    //             height: 76,
                                                    //             color: activityColor
                                                    //                 .withOpacity(
                                                    //                   0.25,
                                                    //                 ),
                                                    //             child: Center(
                                                    //               child: Image.asset(
                                                    //                 activityIcons[activity
                                                    //                     .name],
                                                    //                 //'assets/icons/activity-nap-icon.png',
                                                    //                 fit: BoxFit
                                                    //                     .fill,
                                                    //               ),
                                                    //             ),
                                                    //           );
                                                    //         },
                                                    //   )
                                                        : Container(
                                                      width: 122,
                                                      height: 76,
                                                      color: Colors.white,
                                                      // color: activityColor
                                                      //     .withOpacity(0.25),
                                                      child: Center(
                                                        child: Image.asset(
                                                          activityIcons[activity
                                                              .name],
                                                          //'assets/icons/activity-nap-icon.png',
                                                          fit: BoxFit.fill,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                    mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                        children: [
                                                          Container(
                                                            padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 12,
                                                              vertical: 6,
                                                            ),
                                                            decoration: BoxDecoration(
                                                              color: activityColor,
                                                              borderRadius:
                                                              BorderRadius.circular(
                                                                20,
                                                              ),
                                                            ),
                                                            child: Text(
                                                              activity.name,
                                                              style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: 11,
                                                                fontWeight:
                                                                FontWeight
                                                                    .bold,
                                                              ),
                                                            ),
                                                          ),
                                                          PopupMenuButton<String>(
                                                            icon: const Icon(
                                                              Icons.more_horiz,
                                                              size: 20,
                                                            ),
                                                            onSelected: null,
                                                            itemBuilder: (context) => [
                                                              PopupMenuItem<String>(
                                                                value: 'view',
                                                                child: PopupItem(
                                                                  title: 'View',
                                                                  icon: Icon(
                                                                    Icons
                                                                        .visibility_outlined,
                                                                    color: AppColors
                                                                        .themeColor,
                                                                  ),
                                                                ),
                                                                onTap: () {
                                                                  final destinationBuilder =
                                                                  activityRoutes[activity
                                                                      .name];
                                                                  if (destinationBuilder !=
                                                                      null) {
                                                                    final nextScreen =
                                                                    destinationBuilder(
                                                                      activity,
                                                                    );
                                                                    Navigator.of(
                                                                      context,
                                                                    ).push(
                                                                      MaterialPageRoute(
                                                                        builder: (_) =>
                                                                        nextScreen,
                                                                      ),
                                                                    );
                                                                  }
                                                                },
                                                              ),
                                                              PopupMenuItem<String>(
                                                                value: 'edit',
                                                                child: PopupItem(
                                                                  title: 'Edit',
                                                                  icon: Icon(
                                                                    Icons.edit,
                                                                    color: AppColors
                                                                        .themeColor,
                                                                  ),
                                                                ),
                                                              ),
                                                              PopupMenuItem<String>(
                                                                value: 'delete',
                                                                child: PopupItem(
                                                                  title: 'Delete',
                                                                  icon: Icon(
                                                                    Icons.delete,
                                                                    color: AppColors
                                                                        .themeColor,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 10),

                                                      SizedBox(
                                                        height: 32,
                                                        child: Stack(
                                                          children: [
                                                            for (
                                                            int i = 0;
                                                            i < students.length &&
                                                                i < 4;
                                                            i++
                                                            )
                                                              Positioned(
                                                                left: i * 20,
                                                                child:
                                                                DocumentImageWidget(
                                                                  fileUuid: '',
                                                                  name:
                                                                  students[i],
                                                                  size: 28,
                                                                  fontSize: 10,
                                                                ),
                                                              ),

                                                            // Extra count tooltip
                                                            if (students.length > 4)
                                                              Positioned(
                                                                left:
                                                                4 *
                                                                    20, // after 4 avatars
                                                                child: Tooltip(
                                                                  message: students
                                                                      .skip(4)
                                                                      .join(', '),
                                                                  child: DocumentImageWidget(
                                                                    fileUuid: '',
                                                                    name:
                                                                    '+${students.length - 4}',
                                                                    size: 28,
                                                                    fontSize: 10,
                                                                  ),
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(height: 10),

                                                      Text(
                                                        activity.description!,

                                                        style: TextStyle(
                                                          color: AppColors
                                                              .primaryColor,
                                                          fontSize: 14,
                                                          fontWeight:
                                                          FontWeight.w600,
                                                        ),
                                                        maxLines: 1,
                                                        overflow:
                                                        TextOverflow.ellipsis,
                                                      ),
                                                      const SizedBox(height: 10),
                                                      Text(
                                                        'Created By - ${activity.createdBy}',

                                                        style: TextStyle(
                                                          color: AppColors
                                                              .primaryColor,
                                                          fontSize: 12,
                                                          fontWeight:
                                                          FontWeight.w500,
                                                        ),
                                                        maxLines: 1,
                                                        overflow:
                                                        TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          } else {
            return Column(
              children: [
                Padding(
                  padding: ResponsiveSizing.contentPadding(context),
                  // filter card
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.cardBorderColor),
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.cardColor,
                    ),
                    child: widget.fromStudentProfile
                        ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 65,
                          child: AbsorbPointer(
                            child: _buildCustomDropdown(
                              'Select Student',
                              [?widget.studentName],
                              widget.studentName,
                                  (v) => setState(() {
                                _selectedStudent = v;
                              }),
                              height: 65,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 65,
                          child: _datePickerFilter(
                            selectedStartDate: _selectedStartDate,
                            selectedEndDate: _selectedEndDate,
                            // onDateRangeSelected: (date) {
                            //   List<String>? dates = date?.split('-\n');
                            //   setState(() {
                            //     _selectedStartDate = dates?[0].trim() as DateTime?;
                            //     _selectedEndDate = dates?[1].trim() as DateTime;
                            //
                            //   });
                            // },
                          ),
                        ),
                      ],
                    )
                        : isNotParent
                        ? Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildCustomDropdown(
                                'Select Classroom',
                                _classroomOptions,
                                _selectdClassroom,
                                    (v) => setState(() {
                                  _selectdClassroom = v;
                                  _updateAvailableStudents();
                                }),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              // child: _buildCustomDropdown(
                              //   'Select Student',
                              //   _allStudents,
                              //   _selectedStudent,
                              //       (v) => setState(() {
                              //     _selectedStudent = v;
                              //   }),
                              // ),
                              child: _buildCustomDropdown(
                                _selectdClassroom == null
                                    ? 'Select Classroom First'
                                    : 'Select Student',
                                _availableStudents,
                                _selectedStudent,
                                    (value) {
                                  if (_selectdClassroom != null) {
                                    setState(() {
                                      _selectedStudent = value;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(100),
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FilterScreen(
                                        sections: [
                                          FilerSection(
                                            label: 'Tags',
                                            hintText: 'Select tags',
                                            items: [
                                              '5 Days',
                                              'Full Day',
                                              'Photo Permission',
                                              'Vegetarian',
                                              'First Aid',
                                              'Allergy',
                                              'Pickup Authorized',
                                              'Medication',
                                              'Half Day',
                                              'Boy',
                                              'Girl',
                                            ],
                                            initialSelected: _filterTags,
                                            isMultiSelectDropDown: false,
                                          ),
                                          FilerSection(
                                            label: 'Activity Type',
                                            hintText: 'Select Activity',
                                            items: [
                                              'Nap Start',
                                              'Nap End',
                                              'Bathroom',
                                              'Bottle',
                                              'Meal',
                                              'Incident',
                                              'Photo',
                                              'Outdoor',
                                              'Medication',
                                              'Notes',
                                              'Learning',
                                              'Sign-in',
                                              'Sign-out',
                                              'Absent',
                                            ],
                                            initialSelected: _filterActivityTypes,
                                            isMultiSelectDropDown: false,
                                          ),
                                        ],
                                        onApply: (filters) {
                                          setState(() {
                                            _filterTags = filters['Tags']!;
                                            _filterActivityTypes =
                                            filters['Activity Type']!;
                                          });
                                        },
                                      ),
                                    ),
                                  );
                                  if (!mounted) return;
                                  if (result is Map) {
                                    // TODO: apply filters to list
                                    setState(() {});
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: SvgPicture.asset(
                                    MediaRes.filterIcon,
                                    height: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: _datePickerFilter(
                                selectedStartDate: _selectedStartDate,
                                selectedEndDate: _selectedEndDate,
                              ),
                            ),
                            const SizedBox(width: 8),
                            CustomClearAllChip(
                              onTap: () {
                                setState(() {
                                  _selectdClassroom = _classroomOptions[0];
                                  _selectedStudent = null;
                                  _filterActivityTypes.clear();
                                  _filterTags.clear();
                                });
                              },
                              label: 'Clear All',
                            ),
                          ],
                        ),
                      ],
                    )
                        : Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 65,
                            child: _datePickerFilter(
                              selectedStartDate: _selectedStartDate,
                              selectedEndDate: _selectedEndDate,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 65,
                            child: _buildCustomDropdown(
                              'Activity Type',
                              activityType,
                              _selectedActivityType,
                                  (v) => setState(() {
                                _selectedActivityType = v;
                              }),
                              height: 65,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                if (activities.length == 0)
                  Expanded(
                    child: Padding(
                      padding: ResponsiveSizing.contentPadding(context),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.cardBorderColor),
                          borderRadius: BorderRadius.circular(12),
                          color: AppColors.cardColor,
                        ),
                        child: Center(
                          child: Text(
                            'No Activities found',
                            style: TextStyle(
                              color: Colors.black,
                              fontFamily: 'Manrope',
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                if (activities.length != 0)
                  Expanded(
                    child: Padding(
                      padding: ResponsiveSizing.contentPadding(context),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.only(right: 16),
                              itemCount: activities.length,
                              itemBuilder: (context, index) {
                                final activity = activities[index];
                                final students = activity.studentList;
                                final Color activityColor = _colorPalette[index % _colorPalette.length];

                                return Column(
                                  children: [
                                    Row(
                                      children: [
                                        Column(
                                          children: [
                                            Container(
                                              width: 18,
                                              height: 18,
                                              decoration: BoxDecoration(
                                                color: activityColor,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            Container(
                                              width: 4,
                                              height: 2,
                                              color: activityColor,
                                            ),
                                          ],
                                        ),
                                        Container(
                                          width: 100,
                                          height: 4,
                                          color: activityColor,
                                        ),
                                        Container(
                                          width: 18,
                                          height: 18,
                                          decoration: BoxDecoration(
                                            color: activityColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 20),
                                        SizedBox(
                                          height: 20,
                                          child: Text(
                                            activity.time,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: AppColors.primaryColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(width: 7),
                                        Container(
                                          width: 4,
                                          height: 220,
                                          color: activityColor,
                                        ),

                                        const SizedBox(width: 16),

                                        // Activity Card
                                        Expanded(
                                          child: InkWell(
                                            onTap: () {
                                              final destinationBuilder =
                                              activityRoutes[activity
                                                  .name];
                                              if (destinationBuilder !=
                                                  null) {
                                                final nextScreen =
                                                destinationBuilder(
                                                  activity,
                                                );
                                                Navigator.of(
                                                  context,
                                                ).push(
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                    nextScreen,
                                                  ),
                                                );
                                              }
                                            },
                                            child: Column(
                                              children: [
                                                const SizedBox(height: 15),
                                                Container(
                                                  height: 180,
                                                  margin: const EdgeInsets.only(
                                                    bottom: 24,
                                                  ),
                                                  padding: const EdgeInsets.all(12),
                                                  decoration: BoxDecoration(
                                                    color: activityColor.withOpacity(
                                                      0.15,
                                                    ),
                                                    borderRadius: BorderRadius.circular(
                                                      16,
                                                    ),
                                                    border: Border.all(
                                                      color: activityColor.withOpacity(
                                                        0.4,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    // crossAxisAlignment:
                                                    //     CrossAxisAlignment.center,
                                                    children: [
                                                      ClipRRect(
                                                        borderRadius:
                                                        BorderRadius.circular(12),
                                                        child: SizedBox(
                                                          width: 140,
                                                          height: 120,
                                                          child:
                                                          activity.photoUrl != null || activity.videoUrl != null
                                                              ? ActivityMediaPreview(activity: activity, activityColor: activityColor,)
                                                          // ? Image.network(
                                                          //     activity.photoUrl!,
                                                          //     fit: BoxFit.cover,
                                                          //     loadingBuilder:
                                                          //         (
                                                          //           context,
                                                          //           child,
                                                          //           loadingProgress,
                                                          //         ) {
                                                          //           if (loadingProgress ==
                                                          //               null)
                                                          //             return child;
                                                          //           return Container(
                                                          //             color: Colors
                                                          //                 .transparent,
                                                          //             child: const Center(
                                                          //               child: CircularProgressIndicator(
                                                          //                 strokeWidth:
                                                          //                     2,
                                                          //               ),
                                                          //             ),
                                                          //           );
                                                          //         },
                                                          //     errorBuilder:
                                                          //         (
                                                          //           context,
                                                          //           error,
                                                          //           stackTrace,
                                                          //         ) {
                                                          //           return Container(
                                                          //             width: 122,
                                                          //             height: 76,
                                                          //             color: activityColor
                                                          //                 .withOpacity(
                                                          //                   0.25,
                                                          //                 ),
                                                          //             child: Center(
                                                          //               child: Image.asset(
                                                          //                 activityIcons[activity
                                                          //                     .name],
                                                          //                 //'assets/icons/activity-nap-icon.png',
                                                          //                 fit: BoxFit
                                                          //                     .fill,
                                                          //               ),
                                                          //             ),
                                                          //           );
                                                          //         },
                                                          //   )
                                                              : Container(
                                                            width: 122,
                                                            height: 76,
                                                            color: Colors.white,
                                                            // color: activityColor
                                                            //     .withOpacity(0.25),
                                                            child: Center(
                                                              child: Image.asset(
                                                                activityIcons[activity
                                                                    .name],
                                                                //'assets/icons/activity-nap-icon.png',
                                                                fit: BoxFit.fill,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                          CrossAxisAlignment.start,
                                                          mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceEvenly,
                                                          children: [
                                                            Row(
                                                              mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                              children: [
                                                                Container(
                                                                  padding:
                                                                  const EdgeInsets.symmetric(
                                                                    horizontal: 12,
                                                                    vertical: 6,
                                                                  ),
                                                                  decoration: BoxDecoration(
                                                                    color: activityColor,
                                                                    borderRadius:
                                                                    BorderRadius.circular(
                                                                      20,
                                                                    ),
                                                                  ),
                                                                  child: Text(
                                                                    activity.name,
                                                                    style:
                                                                    const TextStyle(
                                                                      color: Colors
                                                                          .white,
                                                                      fontSize: 11,
                                                                      fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                    ),
                                                                  ),
                                                                ),
                                                                PopupMenuButton<String>(
                                                                  icon: const Icon(
                                                                    Icons.more_horiz,
                                                                    size: 20,
                                                                  ),
                                                                  onSelected: null,
                                                                  itemBuilder: (context) => [
                                                                    PopupMenuItem<String>(
                                                                      value: 'view',
                                                                      child: PopupItem(
                                                                        title: 'View',
                                                                        icon: Icon(
                                                                          Icons
                                                                              .visibility_outlined,
                                                                          color: AppColors
                                                                              .themeColor,
                                                                        ),
                                                                      ),
                                                                      onTap: () {
                                                                        final destinationBuilder =
                                                                        activityRoutes[activity
                                                                            .name];
                                                                        if (destinationBuilder !=
                                                                            null) {
                                                                          final nextScreen =
                                                                          destinationBuilder(
                                                                            activity,
                                                                          );
                                                                          Navigator.of(
                                                                            context,
                                                                          ).push(
                                                                            MaterialPageRoute(
                                                                              builder: (_) =>
                                                                              nextScreen,
                                                                            ),
                                                                          );
                                                                        }
                                                                      },
                                                                    ),
                                                                    PopupMenuItem<String>(
                                                                      value: 'edit',
                                                                      child: PopupItem(
                                                                        title: 'Edit',
                                                                        icon: Icon(
                                                                          Icons.edit,
                                                                          color: AppColors
                                                                              .themeColor,
                                                                        ),
                                                                      ),
                                                                      onTap: () {
                                                                        final destinationBuilder =
                                                                        editActivityRoutes[activity
                                                                            .name];
                                                                        if (destinationBuilder !=
                                                                            null) {
                                                                          final nextScreen =
                                                                          destinationBuilder(
                                                                            activity,
                                                                          );
                                                                          Navigator.of(
                                                                            context,
                                                                          ).push(
                                                                            MaterialPageRoute(
                                                                              builder: (_) =>
                                                                              nextScreen,
                                                                            ),
                                                                          );
                                                                        }
                                                                      },
                                                                    ),
                                                                    PopupMenuItem<String>(
                                                                      value: 'delete',
                                                                      child: PopupItem(
                                                                        title: 'Delete',
                                                                        icon: Icon(
                                                                          Icons.delete,
                                                                          color: AppColors
                                                                              .themeColor,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                            const SizedBox(height: 10),

                                                            SizedBox(
                                                              height: 32,
                                                              child: Stack(
                                                                children: [
                                                                  for (
                                                                  int i = 0;
                                                                  i < students.length &&
                                                                      i < 4;
                                                                  i++
                                                                  )
                                                                    Positioned(
                                                                      left: i * 20,
                                                                      child:
                                                                      DocumentImageWidget(
                                                                        fileUuid: '',
                                                                        name:
                                                                        students[i],
                                                                        size: 28,
                                                                        fontSize: 10,
                                                                      ),
                                                                    ),

                                                                  // Extra count tooltip
                                                                  if (students.length > 4)
                                                                    Positioned(
                                                                      left:
                                                                      4 *
                                                                          20, // after 4 avatars
                                                                      child: Tooltip(
                                                                        message: students
                                                                            .skip(4)
                                                                            .join(', '),
                                                                        child: DocumentImageWidget(
                                                                          fileUuid: '',
                                                                          name:
                                                                          '+${students.length - 4}',
                                                                          size: 28,
                                                                          fontSize: 10,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                ],
                                                              ),
                                                            ),
                                                            const SizedBox(height: 10),

                                                            Text(
                                                              activity.description!,

                                                              style: TextStyle(
                                                                color: AppColors
                                                                    .primaryColor,
                                                                fontSize: 14,
                                                                fontWeight:
                                                                FontWeight.w600,
                                                              ),
                                                              maxLines: 1,
                                                              overflow:
                                                              TextOverflow.ellipsis,
                                                            ),
                                                            const SizedBox(height: 10),
                                                            Text(
                                                              'Created By - ${activity.createdBy}',

                                                              style: TextStyle(
                                                                color: AppColors
                                                                    .primaryColor,
                                                                fontSize: 12,
                                                                fontWeight:
                                                                FontWeight.w500,
                                                              ),
                                                              maxLines: 1,
                                                              overflow:
                                                              TextOverflow.ellipsis,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          }
        }
    );
  }


  // @override
  // Widget build(BuildContext context) {
  //   return Column(
  //     children: [
  //       Padding(
  //         padding: ResponsiveSizing.contentPadding(context),
  //         // filter card
  //         child: Container(
  //           padding: const EdgeInsets.all(12),
  //           decoration: BoxDecoration(
  //             border: Border.all(color: AppColors.cardBorderColor),
  //             borderRadius: BorderRadius.circular(12),
  //             color: AppColors.cardColor,
  //           ),
  //           child: widget.fromStudentProfile
  //               ? Column(
  //                   crossAxisAlignment: CrossAxisAlignment.stretch,
  //                   children: [
  //                     SizedBox(
  //                       height: 65,
  //                       child: AbsorbPointer(
  //                         child: _buildCustomDropdown(
  //                           'Select Student',
  //                           [?widget.studentName],
  //                           widget.studentName,
  //                           (v) => setState(() {
  //                             _selectedStudent = v;
  //                           }),
  //                           height: 65,
  //                         ),
  //                       ),
  //                     ),
  //                     const SizedBox(height: 8),
  //                     SizedBox(
  //                       height: 65,
  //                       child: _datePickerFilter(
  //                         selectedStartDate: _selectedStartDate,
  //                         selectedEndDate: _selectedEndDate,
  //                         // onDateRangeSelected: (date) {
  //                         //   List<String>? dates = date?.split('-\n');
  //                         //   setState(() {
  //                         //     _selectedStartDate = dates?[0].trim() as DateTime?;
  //                         //     _selectedEndDate = dates?[1].trim() as DateTime;
  //                         //
  //                         //   });
  //                         // },
  //                       ),
  //                     ),
  //                   ],
  //                 )
  //               : isNotParent
  //               ? Column(
  //                   children: [
  //                     Row(
  //                       children: [
  //                         Expanded(
  //                           child: _buildCustomDropdown(
  //                             'Select Classroom',
  //                             _classroomOptions,
  //                             _selectdClassroom,
  //                             (v) => setState(() {
  //                               _selectdClassroom = v;
  //                               _updateAvailableStudents();
  //                             }),
  //                           ),
  //                         ),
  //                         const SizedBox(width: 8),
  //                         Expanded(
  //                           // child: _buildCustomDropdown(
  //                           //   'Select Student',
  //                           //   _allStudents,
  //                           //   _selectedStudent,
  //                           //       (v) => setState(() {
  //                           //     _selectedStudent = v;
  //                           //   }),
  //                           // ),
  //                           child: _buildCustomDropdown(
  //                             _selectdClassroom == null
  //                                 ? 'Select Classroom First'
  //                                 : 'Select Student',
  //                             _availableStudents,
  //                             _selectedStudent,
  //                             (value) {
  //                               if (_selectdClassroom != null) {
  //                                 setState(() {
  //                                   _selectedStudent = value;
  //                                 });
  //                               }
  //                             },
  //                           ),
  //                         ),
  //                         const SizedBox(width: 8),
  //                         Material(
  //                           color: Colors.transparent,
  //                           child: InkWell(
  //                             borderRadius: BorderRadius.circular(100),
  //                             onTap: () async {
  //                               final result = await Navigator.push(
  //                                 context,
  //                                 MaterialPageRoute(
  //                                   builder: (_) => FilterScreen(
  //                                     sections: [
  //                                       FilerSection(
  //                                         label: 'Tags',
  //                                         hintText: 'Select tags',
  //                                         items: [
  //                                           '5 Days',
  //                                           'Full Day',
  //                                           'Photo Permission',
  //                                           'Vegetarian',
  //                                           'First Aid',
  //                                           'Allergy',
  //                                           'Pickup Authorized',
  //                                           'Medication',
  //                                           'Half Day',
  //                                           'Boy',
  //                                           'Girl',
  //                                         ],
  //                                         initialSelected: _filterTags,
  //                                         isMultiSelectDropDown: false,
  //                                       ),
  //                                       FilerSection(
  //                                         label: 'Activity Type',
  //                                         hintText: 'Select Activity',
  //                                         items: [
  //                                           'Nap Start',
  //                                           'Nap End',
  //                                           'Bathroom',
  //                                           'Bottle',
  //                                           'Meal',
  //                                           'Incident',
  //                                           'Photo',
  //                                           'Outdoor',
  //                                           'Medication',
  //                                           'Notes',
  //                                           'Learning',
  //                                           'Sign-in',
  //                                           'Sign-out',
  //                                           'Absent',
  //                                         ],
  //                                         initialSelected: _filterActivityTypes,
  //                                         isMultiSelectDropDown: false,
  //                                       ),
  //                                     ],
  //                                     onApply: (filters) {
  //                                       setState(() {
  //                                         _filterTags = filters['Tags']!;
  //                                         _filterActivityTypes =
  //                                             filters['Activity Type']!;
  //                                       });
  //                                     },
  //                                   ),
  //                                 ),
  //                               );
  //                               if (!mounted) return;
  //                               if (result is Map) {
  //                                 // TODO: apply filters to list
  //                                 setState(() {});
  //                               }
  //                             },
  //                             child: Padding(
  //                               padding: const EdgeInsets.all(8),
  //                               child: SvgPicture.asset(
  //                                 MediaRes.filterIcon,
  //                                 height: 20,
  //                               ),
  //                             ),
  //                           ),
  //                         ),
  //                       ],
  //                     ),
  //                     const SizedBox(height: 16),
  //                     Row(
  //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                       children: [
  //                         Expanded(
  //                           child: _datePickerFilter(
  //                             selectedStartDate: _selectedStartDate,
  //                             selectedEndDate: _selectedEndDate,
  //                           ),
  //                         ),
  //                         const SizedBox(width: 8),
  //                         CustomClearAllChip(
  //                           onTap: () {
  //                             setState(() {
  //                               _selectdClassroom = _classroomOptions[0];
  //                               _selectedStudent = null;
  //                               _filterActivityTypes.clear();
  //                               _filterTags.clear();
  //                             });
  //                           },
  //                           label: 'Clear All',
  //                         ),
  //                       ],
  //                     ),
  //                   ],
  //                 )
  //               : Row(
  //                   children: [
  //                     Expanded(
  //                       child: SizedBox(
  //                         height: 65,
  //                         child: _datePickerFilter(
  //                           selectedStartDate: _selectedStartDate,
  //                           selectedEndDate: _selectedEndDate,
  //                         ),
  //                       ),
  //                     ),
  //                     const SizedBox(width: 8),
  //                     Expanded(
  //                       child: SizedBox(
  //                         height: 65,
  //                         child: _buildCustomDropdown(
  //                           'Activity Type',
  //                           activityType,
  //                           _selectedActivityType,
  //                           (v) => setState(() {
  //                             _selectedActivityType = v;
  //                           }),
  //                           height: 65,
  //                         ),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //         ),
  //       ),
  //
  //       const SizedBox(height: 12),
  //
  //       if (activities.length == 0)
  //         Expanded(
  //           child: Padding(
  //             padding: ResponsiveSizing.contentPadding(context),
  //             child: Container(
  //               padding: const EdgeInsets.all(12),
  //               decoration: BoxDecoration(
  //                 border: Border.all(color: AppColors.cardBorderColor),
  //                 borderRadius: BorderRadius.circular(12),
  //                 color: AppColors.cardColor,
  //               ),
  //               child: Center(
  //                 child: Text(
  //                   'No Activities found',
  //                   style: TextStyle(
  //                     color: Colors.black,
  //                     fontFamily: 'Manrope',
  //                     fontSize: 16,
  //                     fontWeight: FontWeight.w500,
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ),
  //
  //       if (activities.length != 0)
  //         Expanded(
  //           child: Padding(
  //             padding: ResponsiveSizing.contentPadding(context),
  //             child: Column(
  //               children: [
  //                 const SizedBox(height: 10),
  //                 Expanded(
  //                   child: ListView.builder(
  //                     padding: const EdgeInsets.only(right: 16),
  //                     itemCount: activities.length,
  //                     itemBuilder: (context, index) {
  //                       final activity = activities[index];
  //                       final students = activity.studentList;
  //                       final Color activityColor = _colorPalette[index % _colorPalette.length];
  //
  //                       return Column(
  //                         children: [
  //                           Row(
  //                             children: [
  //                               Column(
  //                                 children: [
  //                                   Container(
  //                                     width: 18,
  //                                     height: 18,
  //                                     decoration: BoxDecoration(
  //                                       color: activityColor,
  //                                       shape: BoxShape.circle,
  //                                     ),
  //                                   ),
  //                                   Container(
  //                                     width: 4,
  //                                     height: 2,
  //                                     color: activityColor,
  //                                   ),
  //                                 ],
  //                               ),
  //                               Container(
  //                                 width: 100,
  //                                 height: 4,
  //                                 color: activityColor,
  //                               ),
  //                               Container(
  //                                 width: 18,
  //                                 height: 18,
  //                                 decoration: BoxDecoration(
  //                                   color: activityColor,
  //                                   shape: BoxShape.circle,
  //                                 ),
  //                               ),
  //                               const SizedBox(width: 20),
  //                               SizedBox(
  //                                 height: 20,
  //                                 child: Text(
  //                                   activity.time,
  //                                   style: TextStyle(
  //                                     fontSize: 14,
  //                                     color: AppColors.primaryColor,
  //                                     fontWeight: FontWeight.w500,
  //                                   ),
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //                           Row(
  //                             crossAxisAlignment: CrossAxisAlignment.start,
  //                             children: [
  //                               const SizedBox(width: 7),
  //                               Container(
  //                                 width: 4,
  //                                 height: 220,
  //                                 color: activityColor,
  //                               ),
  //
  //                               const SizedBox(width: 16),
  //
  //                               // Activity Card
  //                               Expanded(
  //                                 child: Column(
  //                                   children: [
  //                                     const SizedBox(height: 15),
  //                                     Container(
  //                                       height: 180,
  //                                       margin: const EdgeInsets.only(
  //                                         bottom: 24,
  //                                       ),
  //                                       padding: const EdgeInsets.all(12),
  //                                       decoration: BoxDecoration(
  //                                         color: activityColor.withOpacity(
  //                                           0.15,
  //                                         ),
  //                                         borderRadius: BorderRadius.circular(
  //                                           16,
  //                                         ),
  //                                         border: Border.all(
  //                                           color: activityColor.withOpacity(
  //                                             0.4,
  //                                           ),
  //                                         ),
  //                                       ),
  //                                       child: Row(
  //                                         // crossAxisAlignment:
  //                                         //     CrossAxisAlignment.center,
  //                                         children: [
  //                                           ClipRRect(
  //                                             borderRadius:
  //                                                 BorderRadius.circular(12),
  //                                             child: SizedBox(
  //                                               width: 140,
  //                                               height: 120,
  //                                               child:
  //                                               activity.photoUrl != null || activity.videoUrl != null
  //                                                   ? ActivityMediaPreview(activity: activity, activityColor: activityColor,)
  //                                                   // ? Image.network(
  //                                                   //     activity.photoUrl!,
  //                                                   //     fit: BoxFit.cover,
  //                                                   //     loadingBuilder:
  //                                                   //         (
  //                                                   //           context,
  //                                                   //           child,
  //                                                   //           loadingProgress,
  //                                                   //         ) {
  //                                                   //           if (loadingProgress ==
  //                                                   //               null)
  //                                                   //             return child;
  //                                                   //           return Container(
  //                                                   //             color: Colors
  //                                                   //                 .transparent,
  //                                                   //             child: const Center(
  //                                                   //               child: CircularProgressIndicator(
  //                                                   //                 strokeWidth:
  //                                                   //                     2,
  //                                                   //               ),
  //                                                   //             ),
  //                                                   //           );
  //                                                   //         },
  //                                                   //     errorBuilder:
  //                                                   //         (
  //                                                   //           context,
  //                                                   //           error,
  //                                                   //           stackTrace,
  //                                                   //         ) {
  //                                                   //           return Container(
  //                                                   //             width: 122,
  //                                                   //             height: 76,
  //                                                   //             color: activityColor
  //                                                   //                 .withOpacity(
  //                                                   //                   0.25,
  //                                                   //                 ),
  //                                                   //             child: Center(
  //                                                   //               child: Image.asset(
  //                                                   //                 activityIcons[activity
  //                                                   //                     .name],
  //                                                   //                 //'assets/icons/activity-nap-icon.png',
  //                                                   //                 fit: BoxFit
  //                                                   //                     .fill,
  //                                                   //               ),
  //                                                   //             ),
  //                                                   //           );
  //                                                   //         },
  //                                                   //   )
  //                                                   : Container(
  //                                                       width: 122,
  //                                                       height: 76,
  //                                                       color: Colors.white,
  //                                                       // color: activityColor
  //                                                       //     .withOpacity(0.25),
  //                                                       child: Center(
  //                                                         child: Image.asset(
  //                                                           activityIcons[activity
  //                                                               .name],
  //                                                           //'assets/icons/activity-nap-icon.png',
  //                                                           fit: BoxFit.fill,
  //                                                         ),
  //                                                       ),
  //                                                     ),
  //                                             ),
  //                                           ),
  //                                           const SizedBox(width: 12),
  //                                           Expanded(
  //                                             child: Column(
  //                                               crossAxisAlignment:
  //                                                   CrossAxisAlignment.start,
  //                                               mainAxisAlignment:
  //                                                   MainAxisAlignment
  //                                                       .spaceEvenly,
  //                                               children: [
  //                                                 Row(
  //                                                   mainAxisAlignment:
  //                                                       MainAxisAlignment
  //                                                           .spaceBetween,
  //                                                   children: [
  //                                                     Container(
  //                                                       padding:
  //                                                           const EdgeInsets.symmetric(
  //                                                             horizontal: 12,
  //                                                             vertical: 6,
  //                                                           ),
  //                                                       decoration: BoxDecoration(
  //                                                         color: activityColor,
  //                                                         borderRadius:
  //                                                             BorderRadius.circular(
  //                                                               20,
  //                                                             ),
  //                                                       ),
  //                                                       child: Text(
  //                                                         activity.name,
  //                                                         style:
  //                                                             const TextStyle(
  //                                                               color: Colors
  //                                                                   .white,
  //                                                               fontSize: 11,
  //                                                               fontWeight:
  //                                                                   FontWeight
  //                                                                       .bold,
  //                                                             ),
  //                                                       ),
  //                                                     ),
  //                                                     PopupMenuButton<String>(
  //                                                       icon: const Icon(
  //                                                         Icons.more_horiz,
  //                                                         size: 20,
  //                                                       ),
  //                                                       onSelected: null,
  //                                                       itemBuilder: (context) => [
  //                                                         PopupMenuItem<String>(
  //                                                           value: 'view',
  //                                                           child: PopupItem(
  //                                                             title: 'View',
  //                                                             icon: Icon(
  //                                                               Icons
  //                                                                   .visibility_outlined,
  //                                                               color: AppColors
  //                                                                   .themeColor,
  //                                                             ),
  //                                                           ),
  //                                                           onTap: () {
  //                                                             final destinationBuilder =
  //                                                                 activityRoutes[activity
  //                                                                     .name];
  //                                                             if (destinationBuilder !=
  //                                                                 null) {
  //                                                               final nextScreen =
  //                                                                   destinationBuilder(
  //                                                                     activity,
  //                                                                   );
  //                                                               Navigator.of(
  //                                                                 context,
  //                                                               ).push(
  //                                                                 MaterialPageRoute(
  //                                                                   builder: (_) =>
  //                                                                       nextScreen,
  //                                                                 ),
  //                                                               );
  //                                                             }
  //                                                           },
  //                                                         ),
  //                                                         PopupMenuItem<String>(
  //                                                           value: 'edit',
  //                                                           child: PopupItem(
  //                                                             title: 'Edit',
  //                                                             icon: Icon(
  //                                                               Icons.edit,
  //                                                               color: AppColors
  //                                                                   .themeColor,
  //                                                             ),
  //                                                           ),
  //                                                         ),
  //                                                         PopupMenuItem<String>(
  //                                                           value: 'delete',
  //                                                           child: PopupItem(
  //                                                             title: 'Delete',
  //                                                             icon: Icon(
  //                                                               Icons.delete,
  //                                                               color: AppColors
  //                                                                   .themeColor,
  //                                                             ),
  //                                                           ),
  //                                                         ),
  //                                                       ],
  //                                                     ),
  //                                                   ],
  //                                                 ),
  //                                                 const SizedBox(height: 10),
  //
  //                                                 SizedBox(
  //                                                   height: 32,
  //                                                   child: Stack(
  //                                                     children: [
  //                                                       for (
  //                                                         int i = 0;
  //                                                         i < students.length &&
  //                                                             i < 4;
  //                                                         i++
  //                                                       )
  //                                                         Positioned(
  //                                                           left: i * 20,
  //                                                           child:
  //                                                               DocumentImageWidget(
  //                                                                 fileUuid: '',
  //                                                                 name:
  //                                                                     students[i],
  //                                                                 size: 28,
  //                                                                 fontSize: 10,
  //                                                               ),
  //                                                         ),
  //
  //                                                       // Extra count tooltip
  //                                                       if (students.length > 4)
  //                                                         Positioned(
  //                                                           left:
  //                                                               4 *
  //                                                               20, // after 4 avatars
  //                                                           child: Tooltip(
  //                                                             message: students
  //                                                                 .skip(4)
  //                                                                 .join(', '),
  //                                                             child: DocumentImageWidget(
  //                                                               fileUuid: '',
  //                                                               name:
  //                                                                   '+${students.length - 4}',
  //                                                               size: 28,
  //                                                               fontSize: 10,
  //                                                             ),
  //                                                           ),
  //                                                         ),
  //                                                     ],
  //                                                   ),
  //                                                 ),
  //                                                 const SizedBox(height: 10),
  //
  //                                                 Text(
  //                                                   activity.description!,
  //
  //                                                   style: TextStyle(
  //                                                     color: AppColors
  //                                                         .primaryColor,
  //                                                     fontSize: 14,
  //                                                     fontWeight:
  //                                                         FontWeight.w600,
  //                                                   ),
  //                                                   maxLines: 1,
  //                                                   overflow:
  //                                                       TextOverflow.ellipsis,
  //                                                 ),
  //                                                 const SizedBox(height: 10),
  //                                                 Text(
  //                                                   'Created By - ${activity.createdBy}',
  //
  //                                                   style: TextStyle(
  //                                                     color: AppColors
  //                                                         .primaryColor,
  //                                                     fontSize: 12,
  //                                                     fontWeight:
  //                                                         FontWeight.w500,
  //                                                   ),
  //                                                   maxLines: 1,
  //                                                   overflow:
  //                                                       TextOverflow.ellipsis,
  //                                                 ),
  //                                               ],
  //                                             ),
  //                                           ),
  //                                         ],
  //                                       ),
  //                                     ),
  //                                   ],
  //                                 ),
  //                               ),
  //                             ],
  //                           ),
  //                         ],
  //                       );
  //                     },
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //     ],
  //   );
  // }

  Widget _datePickerFilter({
    required DateTime? selectedStartDate,
    required DateTime? selectedEndDate,
    //required Function(String?) onDateRangeSelected,
  }) {
    return GestureDetector(
      onTap: () async {
        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (_) => CalendarDialog(
            isRangePicker: true,
            isTimePicker: false,
            initialDate: selectedStartDate,
            initialEndDate: selectedEndDate,
            whiteBgColor: true,
          ),
        );

        if (result != null) {
          setState(() {
            _selectedStartDate = result['startDate'] as DateTime?;
            if (result['endDate'] != null)
              _selectedEndDate = result['endDate'] as DateTime?;
          });
        }
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        decoration: BoxDecoration(
          color: const Color(0xFFB1AFE9).withOpacity(0.102),
          //color: const Color(0xFFF8F7FA),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  selectedStartDate != null
                      ? '${DateFormat('MMM dd, yyyy').format(selectedStartDate)} - ${DateFormat('MMM dd, yyyy').format(selectedEndDate!)}'
                      : 'Select Date',
                  style: TextStyle(
                    color: selectedStartDate == null
                        ? AppColors.primaryColor.withOpacity(0.6)
                        : AppColors.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              // Flexible(
              //   child: Text(
              //     selectedEndDate != null
              //         ? DateFormat('MMM dd, yyyy').format(selectedEndDate)
              //         : 'Select Date',
              //     style: TextStyle(
              //       color: selectedEndDate == null
              //           ? AppColors.primaryColor.withOpacity(0.6)
              //           : AppColors.primaryColor,
              //       fontSize: 14,
              //       fontWeight: FontWeight.w500,
              //     ),
              //     overflow: TextOverflow.ellipsis,
              //   ),
              // ),
              // const SizedBox(width: 4),
              SvgPicture.asset(
                MediaRes.calender_icon,
                height: 20.0,
                colorFilter: const ColorFilter.mode(
                  AppColors.primaryColor,
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomDropdown(
    String hintText,
    List<String> items,
    String? selectedItem,
    ValueChanged<String?> onSelect, {
    bool isRequired = false,
    double? height = null,
  }) {
    final responsive = ResponsiveHelper(context);
    return CustomDropdown(
      label: null,
      hintText: hintText,
      items: items,
      height: height,
      selectedItem: selectedItem,
      onSelect: onSelect,
      showAsterisk: isRequired,
      labelStyle: TextStyle(
        fontSize: responsive.labelFontSize,
        fontFamily: "Manrope",
        fontWeight: FontWeight.w400,
        color: const Color(0xff573353),
      ),
      labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
      fieldHeight: responsive.isTablet ? 64.0 : 56.0,
      selectedTextStyle: TextStyle(
        fontFamily: 'Manrope',
        fontSize: responsive.inputFontSize,
        fontWeight: FontWeight.w600,
        color: const Color(0xff573353),
        height: 19 / 14,
      ),
      popupItemTextStyle: TextStyle(
        fontFamily: 'Manrope',
        fontSize: responsive.inputFontSize,
        fontWeight: FontWeight.w400,
        color: const Color(0xff573353),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: responsive.isTablet ? 16.0 : 12.0,
        vertical: responsive.isTablet ? 16.0 : 12.0,
      ),
    );
  }
}

class PopupItem extends StatelessWidget {
  final String title;
  final Icon icon;

  const PopupItem({super.key, required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        icon,
        const SizedBox(width: 5),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

//
// class ActivityItem {
//   final String time;
//   final String name;
//   final String description;
//   final Color color;
//   final String photoUrl;
//   final List<String> studentList;
//   final String createdBy;
//
//   const ActivityItem({
//     required this.time,
//     required this.name,
//     required this.description,
//     required this.color,
//     required this.photoUrl,
//     required this.studentList,
//     required this.createdBy
//   });
// }
