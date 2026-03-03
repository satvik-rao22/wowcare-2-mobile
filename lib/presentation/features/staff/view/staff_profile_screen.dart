import 'package:flutter/material.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_profile.dart';
// import 'package:wowcare/presentation/features/attendance/widgets/attendance_popup.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_profile_tab.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_dates_tab.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_documents_tab.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:image_picker/image_picker.dart';

class StaffProfileScreen extends StatefulWidget {
  const StaffProfileScreen({
    super.key,
    required this.staffCode,
    required this.name,
    required this.classroom,
    required this.designation,
    required this.phoneNumber,
    this.classroomNames,
    this.classroomNameByCode,
  });

  final String staffCode;
  final String name;
  final String classroom;
  final String designation;
  final String phoneNumber;
  /// Optional cached classroom names from StaffScreen (to avoid re-calling classrooms API).
  final List<String>? classroomNames;
  /// Optional mapping from classroom code -> display name.
  final Map<String, String>? classroomNameByCode;

  @override
  State<StaffProfileScreen> createState() => _StaffProfileScreenState();
}

class _StaffProfileScreenState extends State<StaffProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();

  late String _displayName;
  late String _displayDesignation;
  late String _displayClassroom;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _displayName = widget.name;
    _displayDesignation = widget.designation;
    _displayClassroom = widget.classroom;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      // TODO: wire this to upload/update avatar in your backend/state
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Selected profile image',
        isSuccess: true,
      );
    } catch (e) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Failed to pick image: $e',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlobalScaffold(
      hasBackButton: true,
      showCustomNavigationBar: false,
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: TabBar(
              isScrollable: true,
              controller: _tabController,
              dividerColor: Colors.transparent,
              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(color: AppColors.themeColor),
              ),
              indicatorPadding: const EdgeInsets.only(bottom: 8),
              labelStyle: const TextStyle(
                color: Colors.black,
                fontFamily: 'Manrope',
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              unselectedLabelStyle: TextStyle(
                color: AppColors.primaryColor.withOpacity(0.5),
                fontFamily: 'Manrope',
                fontSize: 16,
              ),
              labelColor: Colors.black,
              unselectedLabelColor: AppColors.primaryColor.withOpacity(0.5),
              tabAlignment: TabAlignment.center,
              tabs: const [
                Tab(text: 'Profile'),
                Tab(text: 'Important Dates'),
                Tab(text: 'Documents'),
                // Billing settings can be added based on role
              ],
            ),
          ),
          _buildStaffProfileCard(context),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                StaffProfileTab(
                  staffCode: widget.staffCode,
                  classroomNames: widget.classroomNames,
                  classroomNameByCode: widget.classroomNameByCode,
                  onProfileSummaryChanged:
                      (String name, String classroom, String designation) {
                    setState(() {
                      _displayName = name;
                      _displayDesignation = designation;
                      _displayClassroom = classroom;
                    });
                  },
                ),
                StaffDatesTab(staffCode: widget.staffCode),
                StaffDocumentsTab(staffCode: widget.staffCode),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffProfileCard(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 30),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _pickProfileImage,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      DocumentImageWidget(
                        fileUuid: widget.name, // seed for stable color when no image
                        name: widget.name,
                        size: 90,
                        fontSize: 24,
                        statusColor: const Color(0xFF00B115),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              gradient: AppColors.buildPrimaryGradient(),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 28),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayName,
                        style: const TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 23,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.6,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _displayDesignation,
                        style: TextStyle(
                          color: AppColors.primaryColor.withOpacity(0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _displayClassroom,
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildStaffActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildStaffActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        gradient: AppColors.buildPrimaryGradient(),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionIcon(MediaRes.calenderClockIcon, onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StudentAttendanceProfile(
                  studentCode: '',
                  studentId: 0, // Staff profile - using placeholder ID
                  studentName: widget.name,
                  studentPhotoUuid: null,
                  roomName: widget.classroom,
                  isSignedIn: false,
                  isAbsent: false,
                  isExpectedToday: true,
                  isPresentToday: false,
                  profileStatus: 'A',
                ),
              ),
            );
          }),
          _buildActionIcon(MediaRes.timerIcon, onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StudentAttendanceProfile(
                  studentCode: '',
                  studentId: 0, // Staff profile - using placeholder ID
                  studentName: widget.name,
                  studentPhotoUuid: null,
                  roomName: widget.classroom,
                  isSignedIn: false,
                  isAbsent: false,
                  isExpectedToday: true,
                  isPresentToday: false,
                  profileStatus: 'A',
                ),
              ),
            );
          }),
          _buildActionIcon(MediaRes.communicationIcon, onTap: () {}),
        ],
      ),
    );
  }

  Widget _buildActionIcon(String asset, {required VoidCallback onTap}) {
    final bool isSvg = asset.toLowerCase().endsWith('.svg');
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          child: isSvg
              ? SvgPicture.asset(
                  asset,
                  height: 28,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                )
              : Image.asset(
                  asset,
                  height: 28,
                  color: Colors.white,
                ),
        ),
      ),
    );
  }

}
