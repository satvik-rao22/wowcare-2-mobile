import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/students/view/student_profile_screen_tabs/student_profile_tab.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';

import '../../../../app/theme/media_res.dart';
import '../../../../shared/common/widgets/profile_show_widget.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({
    super.key,
    required this.name,
    required this.classroom,
    required this.tags

  });

  final String name;
  final String classroom;
  final List<String> tags;


  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _profileScrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

  }

  @override
  void dispose() {
    _tabController.dispose();
    _profileScrollController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      // TODO: wire this to upload/update avatar in your backend/state
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected profile image')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
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
                Tab(text: 'Health'),
                Tab(text: 'Dates'),
                Tab(text: 'Documents',)
                // Billing settings can be added based on role
              ],
            ),
          ),
          _buildStudentProfileCard(context),

          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                StudentProfileTab(
                  scrollController: _profileScrollController,
                  name: widget.name,
                  classroom: widget.classroom,
                  tags: widget.tags,

                ),
                StudentProfileTab(
                  scrollController: _profileScrollController,
                  name: widget.name,
                  classroom: widget.classroom,
                  tags: widget.tags,

                ),
                StudentProfileTab(
                  scrollController: _profileScrollController,
                  name: widget.name,
                  classroom: widget.classroom,
                  tags: widget.tags,

                ),
                StudentProfileTab(
                  scrollController: _profileScrollController,
                  name: widget.name,
                  classroom: widget.classroom,
                  tags: widget.tags,

                ),

              ],
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildStudentProfileCard(BuildContext context) {
    //final String initials = _getInitials(widget.name)
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 8,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 30),
            child: Column(
              children: [
                Container(
                  height: 120,
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 24 : 16,
                    vertical: 10
                  ),
                  alignment: Alignment.center,
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
                          ],
                        ),
                      ),
                      const SizedBox(width: 28),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.name,
                              style: const TextStyle(
                                color: AppColors.primaryColor,
                                fontSize: 23,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.6,
                              ),
                              maxLines: 2,
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
                                widget.classroom,
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
                const Divider(
                  height: 1,
                  thickness: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Color(0xFFE9ECEF),
                ),
                SizedBox(height: 10,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Tooltip(
                        message: 'Photo Permission not given by parent',
                        child: SvgPicture.asset(MediaRes.cameraIcon, height: 28)
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Tooltip(
                          message: 'Observe first aid',
                          child: SvgPicture.asset(MediaRes.alertIcon, height: 28)
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Tooltip(
                          message: 'Bring homework',
                          child: SvgPicture.asset(MediaRes.docsIcon, height: 28)
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Tooltip(
                          message: 'Student has health concerns',
                          child: SvgPicture.asset(MediaRes.healthIcon, height: 28)
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Tooltip(
                          message: 'Student is vegetarian',
                          child: Image.asset(MediaRes.foodIcon2, height: 28)
                      ),
                    ),
                  ],
                )
              ],
            ),

          ),

          _buildStudentActionButtons(context),

        ],
      ),
    );
  }

  Widget _buildStudentActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        gradient: AppColors.buildPrimaryGradient(),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionIcon(MediaRes.attendanceIcon, onTap: () {

          }),
          _buildActionIcon(MediaRes.activitesIcon, onTap: () {

          }),
          _buildActionIcon(MediaRes.message_panel_icon, onTap: () {}),
          _buildActionIcon(MediaRes.billing_drawer_icon, onTap: () {

          }),
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
