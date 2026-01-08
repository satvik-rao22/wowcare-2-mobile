import 'dart:io';
import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/activities/widgets/date_widget.dart';
import 'package:wowcare/presentation/features/activities/widgets/input_widget.dart';
import 'package:wowcare/presentation/features/activities/widgets/selected_student_tile.dart';
import 'package:wowcare/presentation/features/activities/widgets/staff_present_widget.dart';
import 'package:wowcare/presentation/features/activities/widgets/time_widget.dart';
import 'package:wowcare/presentation/features/activities/widgets/upload_photo_video.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

import '../../../../../app/theme/colors.dart';
import '../../../../../app/theme/media_res.dart';
import '../../../../../core/util/core_utils.dart';
import '../../../../../shared/common/widgets/custom_app_bar.dart';
import '../activity_daily_tab.dart';
import '../activity_feed_screen.dart';

class PhotoVideoActivityScreen extends StatefulWidget {
  const PhotoVideoActivityScreen({
    super.key,
    this.selectedStudents,
    this.isEdit = false,
    required this.isPhoto,
    this.activityData
  });
  final List<Map<String, dynamic>>? selectedStudents;
  final bool isEdit;
  final bool isPhoto;
  final ActivityItem? activityData;

  @override
  State<PhotoVideoActivityScreen> createState() => _PhotoVideoActivityScreenState();
}

class _PhotoVideoActivityScreenState extends State<PhotoVideoActivityScreen> {
  late final List<Map<String, dynamic>> _selectedStudentsData;
  late final List<String> _selectedStudents;
  final TextEditingController _descriptionController = TextEditingController();

  List<File> _uploadedPhotos = [];
  File? _uploadedVideo;
  List<String> _existingPhotoUrls =[];
  String? _existingVideoUrl;
  bool get _hasMedia => _uploadedPhotos.isNotEmpty || _uploadedVideo != null || _existingPhotoUrls.isNotEmpty || _existingVideoUrl != null;

  @override
  void initState() {
    super.initState();
    // Create a mutable copy of the incoming list
    //_selectedStudents = List.from(widget.selectedStudents);
    //_selectedStudents = widget.selectedStudents.map((studentMap) => studentMap['name'] as String).toList();
    if(widget.selectedStudents != null){
      _selectedStudentsData = List.from(widget.selectedStudents!);
      _selectedStudents = _selectedStudentsData.map((student) => student['name'] as String).toList();
    } else if(widget.isEdit ) {
      final activity = widget.activityData!;
      _selectedStudents = List<String>.from(activity.studentList);
      _descriptionController.text = activity.description ?? '';
      if (widget.isPhoto) {
        if (activity.photoUrl != null ) {
          _existingPhotoUrls = [activity.photoUrl!];
        }
      } else {
        _existingVideoUrl = activity.videoUrl;
      }
    }
  }

  void _onMediaChanged(List<File> photos, File? video, List<String> remainingExistingPhotoUrls, String? remainingExistingVideoUrl){
    setState(() {
      _uploadedPhotos = photos;
      _uploadedVideo = video;
      _existingPhotoUrls = remainingExistingPhotoUrls;
      _existingVideoUrl = remainingExistingVideoUrl;
    });
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
              const SizedBox(height: 10),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.horizontalSpacing,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.isPhoto ?'Photo' : 'Video',
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
              Expanded(
                  child: Container(
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
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10,),
                          GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            padding: const EdgeInsets.all(10),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: responsive.isTablet ? 3 : 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: responsive.isTablet ? 3.8 : 3.0,
                            ),
                            itemCount: _selectedStudents.length,
                            itemBuilder: (context, index) {
                              final String name = _selectedStudents[index];

                              return SelectedStudentTile(
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
                          // Row(
                          //   children: [
                          //     Flexible(child: DateWidget(isEditable: false, isRequired: true,)),
                          //     const SizedBox(width: 10,),
                          //     Flexible(child: TimeWidget(isEditable: true, isRequired: true,)),
                          //   ],
                          // ),
                          SizedBox(height: responsive.verticalSpacing,),
                          MediaUploader(isRequired: true,allowVideo: !widget.isPhoto, allowPhoto: widget.isPhoto, onMediaChanged: _onMediaChanged, initialPhotoUrls: widget.isEdit ? _existingPhotoUrls :[], initialVideoUrl: widget.isEdit ? _existingVideoUrl: null,),
                          SizedBox(height: responsive.verticalSpacing,),
                          StaffPresentWidget(staffName: widget.isEdit ? widget.activityData?.createdBy ?? '':'Staff A', isEditable: false,),
                          SizedBox(height: responsive.verticalSpacing,),
                          InputWidget(controller: _descriptionController, height: 100, hint: 'Enter Description'),
                          SizedBox(height: responsive.verticalSpacing,),


                        ],
                      ),
                    ),
                  )
              ),
              const SizedBox(height: 12),
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
          onPressed: _hasMedia ? (){
           // Navigator.of(context).popUntil((route) => route.isFirst);
            //Navigator.of(context).pop();
            Navigator.of(context).popUntil((route) {
              return route.settings.name == ActivityFeedScreen.routeName;
            });
          } : (){
            CoreUtils.showTopSnackBar(
              context: context,
              message: widget.isPhoto ? 'Please upload a photo before adding activity.' : 'Please upload a video before adding activity.',
              isWarning: true
            );
          },
          style: TextButton.styleFrom(overlayColor: Colors.transparent),
          child: Text(
            widget.isEdit ?'Save':'Add',
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
