import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';

import '../../../../shared/common/widgets/profile_show_widget.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({
    super.key,
    required this.name,
    required this.classroom,

  });

  final String name;
  final String classroom;


  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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

        ],
      ),
    );
  }

  Widget _buildStudentProfileCard(BuildContext context) {
    //final String initials = _getInitials(widget.name);
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
          //_buildStudentActionButtons(context),
        ],
      ),
    );
  }

}
