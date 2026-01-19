import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/activities/widgets/checkbox_widget.dart';
import 'package:wowcare/presentation/features/activities/widgets/date_widget.dart';
import 'package:wowcare/presentation/features/activities/widgets/input_widget.dart';
import 'package:wowcare/presentation/features/activities/widgets/selected_student_tile.dart';
import 'package:wowcare/presentation/features/activities/widgets/staff_present_widget.dart';
import 'package:wowcare/presentation/features/activities/widgets/time_widget.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

import '../../../../../app/theme/colors.dart';
import '../../../../../app/theme/media_res.dart';
import '../../../../../core/util/core_utils.dart';
import '../../../../../shared/common/widgets/custom_app_bar.dart';
import '../../../../../shared/common/widgets/custom_checkbox.dart';
import '../../widgets/student_tile.dart';
import '../activity_daily_tab.dart';
import '../activity_feed_screen.dart';

class NapActivityScreen extends StatefulWidget {
  const NapActivityScreen({
    super.key,
    this.selectedStudents,
    this.activityData,
    this.isEdit = false
  });
  final List<Map<String, dynamic>>? selectedStudents;
  final bool isEdit;
  final ActivityItem? activityData;

  @override
  State<NapActivityScreen> createState() => _NapActivityScreenState();
}

class _NapActivityScreenState extends State<NapActivityScreen> {
  late final List<Map<String,dynamic>> _selectedStudentsData;
  late final List<String> _selectedStudents;
  List<String> _studentsToEdit = [];
  bool _selectAll = false;
  final TextEditingController _descriptionController = TextEditingController();

  bool get allNapping {
    return _selectedStudentsData.every((student) => student['nappingStatus'] == true);
  }
  bool get noOneNapping {
    return _selectedStudentsData.every((student) => student['nappingStatus'] == false);
  }

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.activityData != null) {
      final activity = widget.activityData!;
      _selectedStudents = List<String>.from(activity.studentList);
      bool isOngoingNap = activity.napStartTime != null && activity.napEndTime == null;
      bool isCompletedNap = activity.napStartTime != null && activity.napEndTime != null;

      bool uniformNappingStatus = isCompletedNap || isOngoingNap;

      _selectedStudentsData = _selectedStudents.map((name) => {
        'name': name,
        'nappingStatus': uniformNappingStatus,
      }).toList();

      _descriptionController.text = activity.description ?? '';

    } else if (widget.selectedStudents != null) {
      _selectedStudentsData = List.from(widget.selectedStudents!);
      _selectedStudents = _selectedStudentsData.map((student) => student['name'] as String).toList();

    } else {
      _selectedStudentsData = [];
      _selectedStudents = [];
      _descriptionController.text = '';
    }
  }

  // @override
  // void initState() {
  //   super.initState();
  //   // Create a mutable copy of the incoming list
  //   if(widget.selectedStudents != null){
  //     _selectedStudentsData = List.from(widget.selectedStudents!);
  //     _selectedStudents = _selectedStudentsData.map((student) => student['name'] as String).toList();
  //   }
  //
  // }

  void _updateSelectAllState() {
    _selectAll = _selectedStudents.every((student) => _studentsToEdit.contains(student));

  }

  void _removeStudent(String name) {
    setState(() {
      _selectedStudents.remove(name);
      _selectedStudentsData.removeWhere((s) => s['name'] == name);

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
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: const CustomAppBar(hasBackButton: true),
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.buildScaffoldGradient(),
                ),
                child: Image.asset(
                  MediaRes.wowcareMobileBg,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),
            Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: responsive.horizontalSpacing,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Nap',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: responsive.titleFontSize,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xff573353),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: responsive.isTablet ? 32.0 : 10.0),
                        Container(
                          width: responsive.containerWidth,
                          margin: EdgeInsets.symmetric(
                              horizontal: responsive.horizontalSpacing
                          ),
                          padding: EdgeInsets.all(responsive.isTablet ? 32.0 : 16.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.all(
                              Radius.circular(responsive.isTablet ? 30.0 : 20.0),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 10,),
                              // Select All
                              if(widget.isEdit) ...[
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
                                const SizedBox(height: 12,),
                              ],
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
                                  final bool isSelected =  _studentsToEdit.contains(name);

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
                              // GridView.builder(
                              //   physics: const NeverScrollableScrollPhysics(),
                              //   shrinkWrap: true,
                              //   padding: const EdgeInsets.all(10),
                              //   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              //     crossAxisCount: responsive.isTablet ? 3 : 2,
                              //     crossAxisSpacing: 12,
                              //     mainAxisSpacing: 12,
                              //     childAspectRatio: responsive.isTablet ? 3.8 : 3.0,
                              //   ),
                              //   itemCount: _selectedStudents.length,
                              //   itemBuilder: (context, index) {
                              //     final String name = _selectedStudents[index];
                              //
                              //     return SelectedStudentTile(
                              //       name: name,
                              //       onTap: () => _removeStudent(name),
                              //     );
                              //   },
                              // ),
                              SizedBox(height: responsive.verticalSpacing,),
                              if(widget.isEdit)
                                DateWidget(isEditable: true, isRequired: true, initialDate: widget.activityData?.date,)
                              else
                                DateWidget(isEditable: true, isRequired: true,),
                              SizedBox(height: responsive.verticalSpacing,),
                              if(!widget.isEdit)
                                Row(
                                  children: [
                                    Flexible(child: TimeWidget(label: 'Start Time',isEditable: noOneNapping || (!allNapping && !noOneNapping), isRequired: noOneNapping || (!allNapping && !noOneNapping), doNotShowTime: allNapping,)),
                                    const SizedBox(width: 10,),
                                    Flexible(child: TimeWidget(label : 'End Time', isEditable: allNapping || (!allNapping && !noOneNapping), isRequired: allNapping || (!allNapping && !noOneNapping), doNotShowTime: noOneNapping,))
                                  ],
                                )
                              else
                                Row(
                                  children: [
                                    Flexible(child: TimeWidget(label: 'Start Time',isEditable: true, isRequired: true, prefilledTime: widget.activityData?.napStartTime,)),
                                    const SizedBox(width: 10,),
                                    Flexible(child: TimeWidget(label : 'End Time', isEditable: widget.activityData?.name == 'Nap End', isRequired: widget.activityData?.name == 'Nap End', doNotShowTime: widget.activityData?.name != 'Nap End', prefilledTime: widget.activityData?.napEndTime,))
                                  ],
                                ),
                              SizedBox(height: responsive.verticalSpacing,),
                              if(!widget.isEdit)
                                CheckboxWidget(label: 'Remind to check nap every 15 mins', isEditable: noOneNapping || (!allNapping && !noOneNapping),)
                              else
                                CheckboxWidget(label: 'Remind to check nap every 15 mins', isEditable: widget.activityData?.name == 'Nap Start',),
                              SizedBox(height: responsive.verticalSpacing,),
                              StaffPresentWidget(staffName: widget.isEdit ? widget.activityData?.staffPresent ?? '' :'Staff A', isEditable: false,),
                              SizedBox(height: responsive.verticalSpacing,),
                              InputWidget(controller: _descriptionController, height: 100, hint: 'Enter Description'),
                              SizedBox(height: responsive.verticalSpacing,),


                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomBar(context, responsive),
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
            Navigator.of(context).popUntil((route) {
              return route.settings.name == ActivityFeedScreen.routeName;
            });
          },
          style: TextButton.styleFrom(overlayColor: Colors.transparent),
          child: Text(
            widget.isEdit ? 'Save':'Add',
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
