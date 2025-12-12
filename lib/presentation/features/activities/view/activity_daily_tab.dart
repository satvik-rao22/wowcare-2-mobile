import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';

import '../../../../shared/common/views/filter_screen.dart';
import '../../../../shared/common/widgets/custom_dropdown.dart';
import '../../../../shared/utils/responsive_helper.dart';

class ActivityDailyTab extends StatefulWidget {
  const ActivityDailyTab({
    super.key,
    this.fromStudentProfile = false,
    this.studentName = '',
  });

  final bool fromStudentProfile;
  final String studentName;

  static const String routeName = '/activityDailyTab';

  @override
  State<ActivityDailyTab> createState() => _ActivityDailyTabState();
}

class _ActivityDailyTabState extends State<ActivityDailyTab> {
  final TextEditingController _searchController = TextEditingController();
  final isNotParent = true;

  DateTime? _selectedDate = DateTime.now();
  String? _selectdClassroom;
  String? _selectedStudent;
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
  final List<String> _allStudents = [
    'Raghave Gupta',
    'Rohan Gupta',
    'Ruhi Gupta',
    'Anya Mehta',
    'Kabir Mehta',
    'Sara Khan',
  ];
  final List<String> _classroomOptions = ['1-Blue D', '3-Orange-D', '2-Red A'];
  final List<ActivityItem> activities = [
    ActivityItem(
      time: "05.00 PM",
      name: "Outdoor",
      description: "Outdoor Activity",
      color: Color(0xFFFFE0B2), // orange
      photoUrl:
          "https://images.unsplash.com/photo-1570545906912-5b2a3f3c2bab?w=400",
      studentList: ['Kabir Mehta', 'Sara Khan'],
      createdBy: 'Staff A'
    ),
    ActivityItem(
      time: "04.30 PM",
      name: "Learning",
      description: "Drawing Activity",
      color: Color(0xFFB3E5FC), // blue
      photoUrl:
          "https://images.unsplash.com/photo-1587653915930-8d17f0e7ff5d?w=400",
      studentList: ['Raghav Gupta'],
      createdBy: 'Staff B'
    ),
    ActivityItem(
      time: "04.00 PM",
      name: "Nap",
      description: "Nap Time",
      color: Color(0xFFFFCCBC), // pink
      photoUrl:
          "https://images.unsplash.com/photo-1603394152748-9625e4419c7a?w=400",
      studentList: ['Sara Khan', 'Raghav Gupta', 'Kabir Mehta'],
      createdBy: 'Staff C'
    ),
    ActivityItem(
      time: "02.22 PM",
      name: "Meal",
      description: "Lunch (Finished)",
      color: Color(0xFFC8E6C9), // green
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
      createdBy: 'Staff A'
    ),
    ActivityItem(
      time: "01.00 PM",
      name: "Meal",
      description: "Drawing Activity",
      color: Color(0xFFD1C4E9), // purple
      photoUrl:
          "https://images.unsplash.com/photo-1596461404969-9ae8f10bdd83?w=400",
      studentList: ['Sara Khan', 'Raghav Gupta', 'Kabir Mehta'],
      createdBy: 'Staff B'
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectdClassroom = _classroomOptions[0];
    _selectedStudent = _allStudents[0];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: ResponsiveSizing.contentPadding(context),
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
                        child: _buildCustomDropdown(
                          'Select Student',
                          [widget.studentName],
                          widget.studentName,
                          (v) => setState(() {
                            _selectedStudent = v;
                          }),
                          height: 65
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 65,
                        child: _datePickerFilter(
                          selectedDate: _selectedDate,
                          onDateSelected: (date) {
                            setState(() {
                              _selectedDate = date;
                            });
                          },
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
                              }),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildCustomDropdown(
                              'Select Student',
                              _allStudents,
                              _selectedStudent,
                              (v) => setState(() {
                                _selectedStudent = v;
                              }),
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
                                          isMultiSelectDropDown: false,
                                        ),
                                      ],
                                      onApply: (filters) {},
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
                              selectedDate: _selectedDate,
                              onDateSelected: (date) {
                                setState(() {
                                  _selectedDate = date;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          CustomClearAllChip(onTap: () {}, label: 'Clear All'),
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
                            selectedDate: _selectedDate,
                            onDateSelected: (date) {
                              setState(() {
                                _selectedDate = date;
                              });
                            },
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
                            height: 65
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
                        final students = activity.studentList ?? [];

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
                                        color: activity.color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    Container(
                                      width: 4,
                                      height: 2,
                                      color: activity.color,
                                    ),
                                  ],
                                ),
                                Container(
                                  width: 100,
                                  height: 4,
                                  color: activity.color,
                                ),
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: activity.color,
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
                                  color: activity.color,
                                ),

                                const SizedBox(width: 16),

                                // Activity Card
                                Expanded(
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
                                          color: activity.color.withOpacity(
                                            0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: activity.color.withOpacity(
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
                                                child: Image.network(
                                                  activity.photoUrl,
                                                  fit: BoxFit.cover,
                                                  loadingBuilder:
                                                      (
                                                        context,
                                                        child,
                                                        loadingProgress,
                                                      ) {
                                                        if (loadingProgress ==
                                                            null)
                                                          return child;
                                                        return Container(
                                                          color: Colors
                                                              .transparent,
                                                          child: const Center(
                                                            child:
                                                                CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2,
                                                                ),
                                                          ),
                                                        );
                                                      },
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return Container(
                                                          width: 122,
                                                          height: 76,
                                                          color: activity.color
                                                              .withOpacity(
                                                                0.25,
                                                              ),
                                                          child: Center(
                                                            child: Image.asset(
                                                              MediaRes
                                                                  .napActivityIcon,
                                                              //'assets/icons/activity-nap-icon.png',
                                                              fit: BoxFit.fill,
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment : MainAxisAlignment.spaceEvenly,
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
                                                          color:
                                                              activity.color,
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
                                                          PopupMenuItem<
                                                              String
                                                          >(
                                                            value: 'view',
                                                            child: PopupItem(
                                                              title: 'View',
                                                              icon: Icon( Icons.visibility_outlined, color: AppColors.themeColor,),
                                                            ),
                                                          ),
                                                          PopupMenuItem<
                                                            String
                                                          >(
                                                            value: 'edit',
                                                            child: PopupItem(
                                                              title: 'Edit',
                                                              icon: Icon(Icons.edit, color: AppColors.themeColor),
                                                            ),
                                                          ),
                                                          PopupMenuItem<
                                                            String
                                                          >(
                                                            value: 'delete',
                                                            child: PopupItem(
                                                              title: 'Delete',
                                                              icon: Icon(Icons.delete, color : AppColors.themeColor),
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
                                                  const SizedBox(height: 10,),

                                                  Text(
                                                    activity.description,

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
                                                  const SizedBox(height: 10,),
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
                                                  )
                                                ],
                                              ),
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

  Widget _datePickerFilter({
    required DateTime? selectedDate,
    required Function(DateTime?) onDateSelected,
  }) {
    return GestureDetector(
      onTap: () async {
        final result = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) => CalendarDialog(
            isTimePicker: false,
            initialDate: selectedDate,
            whiteBgColor: true,
          ),
        );

        if (result != null && result['date'] != null) {
          onDateSelected(result['date'] as DateTime);
        }
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F7FA),
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
                  selectedDate != null
                      ? DateFormat('MMM dd, yyyy').format(selectedDate)
                      : 'Select Date',
                  style: TextStyle(
                    color: selectedDate == null
                        ? AppColors.primaryColor.withOpacity(0.6)
                        : AppColors.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
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
        double? height = null
  }) {
    final responsive = ResponsiveHelper(context);
    return CustomDropdown(
      label: null,
      hintText: hintText,
      height: height,
      items: items,
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
        const SizedBox(width: 5,),
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

class ActivityItem {
  final String time;
  final String name;
  final String description;
  final Color color;
  final String photoUrl;
  final List<String> studentList;
  final String createdBy;

  const ActivityItem({
    required this.time,
    required this.name,
    required this.description,
    required this.color,
    required this.photoUrl,
    required this.studentList,
    required this.createdBy
  });
}
