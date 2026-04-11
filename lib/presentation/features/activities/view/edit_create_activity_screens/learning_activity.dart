import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/activities/widgets/date_widget.dart';
import 'package:wowcare/presentation/features/activities/widgets/input_widget.dart';
import 'package:wowcare/shared/common/widgets/selected_student_tile.dart';
import 'package:wowcare/presentation/features/activities/widgets/staff_present_widget.dart';
import 'package:wowcare/shared/common/widgets/student_tile.dart';
import 'package:wowcare/presentation/features/activities/widgets/time_widget.dart';
import 'package:wowcare/presentation/features/activities/widgets/upload_photo_video.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';

import '../../../../../app/theme/colors.dart';
import '../../../../../core/util/core_utils.dart';
import '../../../../../shared/common/widgets/custom_checkbox.dart';
import '../../widgets/activity_dropdown_widget.dart';
import '../activity_daily_tab.dart';
import '../activity_feed_screen.dart';

class LearningActivityScreen extends StatefulWidget {
  const LearningActivityScreen({
    super.key,
    this.selectedStudents,
    this.isEdit = false,
    this.activityData
  });
  final List<Map<String,dynamic>>? selectedStudents;
  final bool isEdit;
  final ActivityItem? activityData;

  @override
  State<LearningActivityScreen> createState() => _LearningActivityScreenState();
}

class _LearningActivityScreenState extends State<LearningActivityScreen> {
  late final List<Map<String, dynamic>> _selectedStudentsData;
  late final List<String> _selectedStudents;
  List<String> _studentsToEdit = [];
  bool _selectAll = false;
  final TextEditingController _descriptionController = TextEditingController();

  final List<String> _activityType = ['Art and Craft', 'Circle Time', 'Morning Time', 'Music and Movement', 'Puzzle Time', 'Other'];
  final List<String> _category = ['Creativity', 'Empathy', 'Self care', 'Math/Science', 'Communication', 'Language', 'Teamwork', 'Decision making', 'Other'];
  List<String> _selectedCategories = [];
  String? _selectedActivityType;

  @override
  void initState() {
    super.initState();
    // Create a mutable copy of the incoming list
    //_selectedStudents = widget.selectedStudents.map((studentMap) => studentMap['name'] as String).toList();
    if(widget.selectedStudents != null){
      _selectedStudentsData = List.from(widget.selectedStudents!);
      _selectedStudents = _selectedStudentsData.map((student) => student['name'] as String).toList();
    } else if(widget.isEdit ){
      final activity = widget.activityData!;
      _selectedStudents = List<String>.from(activity.studentList);
      _descriptionController.text = activity.whatHappened ?? '';
      _selectedActivityType = activity.activityType ?? '';
      _selectedCategories = activity.categoryType ?? [];
    }
  }

  void _updateSelectAllState() {
    _selectAll = _selectedStudents.every((student) => _studentsToEdit.contains(student));

  }

  void _removeStudent(String name) {
    setState(() {
      _selectedStudents.remove(name);

      // If no students left, go back to previous screen
      if (_selectedStudents.isEmpty) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return StaffFormLayout(
      title: 'Learning',
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10,),
            // Select All
            if(widget.isEdit)
              Align(
                alignment: Alignment.centerLeft,
                child: CustomCheckbox(
                  label: 'Select All',
                  value: _selectAll,
                  borderColor: AppColors.themeColor,
                  onChanged: (v) {
                    final newVal = v ?? false;
                    setState(() {
                      _selectAll = newVal;
                      if (newVal) {
                        _studentsToEdit = List.from(_selectedStudents);
                      } else {
                        _studentsToEdit.clear();
                      }
                    });
                  },
                ),
              ),
            if(widget.isEdit) const SizedBox(height: 12,),
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              padding: const EdgeInsets.all(10),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: responsive.isTablet ? 3 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: responsive.isTablet ? 3.8 : widget.isEdit ? 4.2 : 3.0,
              ),
              itemCount: _selectedStudents.length,
              itemBuilder: (context, index) {
                final String name = _selectedStudents[index];
                final bool isSelected = _studentsToEdit.contains(name);

                return widget.isEdit ?
                StudentTile(
                  name: name,
                  isSelected: isSelected,
                  onSelected: (bool? selected){
                    ScaffoldMessenger.of(context).removeCurrentSnackBar();
                    setState(() {
                      if(selected == true){
                        _studentsToEdit.add(name);
                      } else {
                        _studentsToEdit.remove(name);
                      }
                      _updateSelectAllState();
                    });
                  },
                )
                    :SelectedStudentTile(
                  name: name,
                  onTap: () => _removeStudent(name),
                );
              },
            ),
            SizedBox(height: responsive.verticalSpacing,),
            Row(
              children: [
                Flexible(
                  child:
                  widget.isEdit ?
                  DateWidget(isEditable: true, isRequired: true, initialDate: widget.activityData?.date,)
                      :
                  DateWidget(isEditable: true, isRequired: true,),
                ),
                const SizedBox(width: 10,),
                Flexible(
                    child: widget.isEdit ?
                    TimeWidget(isEditable: true, isRequired: true, prefilledTime: widget.activityData?.time,)
                        : TimeWidget(isRequired: true, isEditable: true,)
                ),
              ],
            ),
            SizedBox(height: responsive.verticalSpacing,),
            Row(
              children: [
                Flexible(
                    child: ActivityDropdownWidget(
                      options: _activityType,
                      dropDownName: 'Activity Name',
                      selectedValue: _selectedActivityType,
                      isRequired: true,
                      onSelect: (value){
                        setState(() {
                          _selectedActivityType = value;
                        });
                      },

                    )
                ),
                const SizedBox(width: 10,),
                Flexible(
                    child: ActivityDropdownWidget(
                      options: _category,
                      dropDownName: 'Category',
                      isMultiSelect: true,
                      selectedOptions: _selectedCategories,
                      isRequired: true,
                      onMultiSelect: (selectList){
                        setState(() {
                          _selectedCategories = selectList;
                        });
                      },
                    )
                )
              ],
            ),
            SizedBox(height: responsive.verticalSpacing,),
            StaffPresentWidget(staffName: widget.isEdit ? widget.activityData?.createdBy ?? '':'Staff A', isEditable: false,),
            SizedBox(height: responsive.verticalSpacing,),
            InputWidget(controller: _descriptionController, height: 100, hint: 'Enter Description'),
            SizedBox(height: responsive.verticalSpacing,),
            if(widget.isEdit)
              MediaUploader(
                isRequired: false,
                allowVideo: false,
                allowPhoto: true,
                isPictureBox: false,
                limit: 10,
                initialPhotoUrls:
                    widget.activityData?.photoUrl != null &&
                            widget.activityData!.photoUrl!.trim().isNotEmpty
                        ? [widget.activityData!.photoUrl!.trim()]
                        : const [],
                label: 'Upload Photos',
              )
            else
              MediaUploader(isRequired: false,allowVideo: false, allowPhoto: true, isPictureBox: false, limit: 10, label: 'Upload Photos', ),
            SizedBox(height: responsive.verticalSpacing,),
          ],
        ),
      ),
      bottomBar: _buildBottomBar(context, responsive),
    );
  }

  Widget _buildBottomBar(BuildContext context, ResponsiveHelper responsive) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;
    return Container(
      padding: EdgeInsets.only(
        bottom: safeAreaBottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(responsive.isTablet ? 40.0 : 24.0),
          topRight: Radius.circular(responsive.isTablet ? 40.0 : 24.0),
        ),
      ),
      child: Container(
        height: responsive.buttonHeight,
        decoration: BoxDecoration(
          gradient: AppColors.buildPrimaryGradient(),
          borderRadius: BorderRadius.circular(
            responsive.isTablet ? 16.0 : 8.0,
          ),
        ),
        child: TextButton(
          onPressed: (){
            if (widget.isEdit && _studentsToEdit.isEmpty ){
              CoreUtils.showTopSnackBar(
                  context: context,
                  message: 'Please select at least one student',
                  isWarning: true
              );
              return;
            }
            if (_selectedActivityType == null ){
              CoreUtils.showTopSnackBar(
                  context: context,
                  message: 'Please select a Activity Name',
                  isWarning: true
              );
              return;
            }
            if (_selectedCategories.isEmpty ){
              CoreUtils.showTopSnackBar(
                  context: context,
                  message: 'Please select at least one category',
                  isWarning: true
              );
              return;
            }
            Navigator.of(context).popUntil((route) {
              return route.settings.name == ActivityFeedScreen.routeName;
            });
          },
          style: TextButton.styleFrom(overlayColor: Colors.transparent),
          child: Text(
            widget.isEdit ? 'Save' :'Add',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: responsive.buttonFontSize,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
