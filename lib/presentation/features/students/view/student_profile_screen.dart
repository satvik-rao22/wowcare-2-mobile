import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/activities/view/activity_feed_screen.dart';
import 'package:wowcare/presentation/features/students/view/student_profile_screen_tabs/student_documents_tab.dart';
import 'package:wowcare/presentation/features/students/view/student_profile_screen_tabs/student_health_tab.dart';
import 'package:wowcare/presentation/features/students/view/student_profile_screen_tabs/student_important_dates_tab.dart';
import 'package:wowcare/presentation/features/students/view/student_profile_screen_tabs/student_profile_tab.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/data/features/student/repositories/student_repository_impl.dart';
import 'package:wowcare/data/features/student/models/student_models.dart';

import '../../../../app/theme/media_res.dart';
import '../../../../core/util/core_utils.dart';
import '../../../../shared/common/widgets/profile_show_widget.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({
    super.key,
    required this.name,
    required this.classroom,
    required this.tags,
    required this.schedule,
    required this.sibling,
    this.studentCode,
  });

  final String name;
  final String classroom;
  final List<String> tags;
  final List<String> schedule;
  final Map<String, dynamic> sibling;
  final String? studentCode;

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _profileScrollController = ScrollController();
  final ScrollController _healthScrollController = ScrollController();
  final ScrollController _importantDatesScrollController = ScrollController();
  final ScrollController _documentsScrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  late Future<StudentHealthModel?> _healthFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _healthFuture = _buildHealthFuture();

    // Cache-first classroom load (won't refetch if already loaded).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        context.read<ClassroomCubit>().loadActiveClassrooms();
      } catch (_) {
        // If no ClassroomCubit is provided above, build() will wrap with one.
      }
    });
  }

  Future<StudentHealthModel?> _buildHealthFuture() async {
    final code = widget.studentCode;
    if (code == null || code.isEmpty) {
      return null;
    }
    final repo = serviceLocator<StudentRepository>() as StudentRepositoryImpl;
    try {
      return await repo.getStudentHealth(studentCode: code);
    } catch (e) {
      CoreUtils.logApiError(e.toString());
      return null;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _profileScrollController.dispose();
    _healthScrollController.dispose();
    _importantDatesScrollController.dispose();
    _documentsScrollController.dispose();
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
    // Ensure classroom list is available for any downstream screens (edit dropdown etc.)
    // - If a ClassroomCubit is already provided (e.g. from StudentScreen), reuse it.
    // - Otherwise, create it here and load once.
    final hasClassroomCubit = (() {
      try {
        context.read<ClassroomCubit>();
        return true;
      } catch (_) {
        return false;
      }
    })();

    if (!hasClassroomCubit) {
      return BlocProvider<ClassroomCubit>(
        create: (_) => serviceLocator<ClassroomCubit>()..loadActiveClassrooms(),
        child: Builder(
          builder: (context) => _buildScreen(context),
        ),
      );
    }

    return _buildScreen(context);
  }

  Widget _buildScreen(BuildContext context) {
    return GlobalScaffold(
      hasBackButton: true,
      showCustomNavigationBar: true,
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
                //color: Colors.black,
                color: const Color(0xFF241631),
                fontFamily: 'Manrope',
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              unselectedLabelStyle: TextStyle(
                color: AppColors.primaryColor.withOpacity(0.5),
                fontFamily: 'Manrope',
                fontSize: 16,
              ),
              //labelColor: Colors.black,
              labelColor: const Color(0xFF241631),
              unselectedLabelColor: AppColors.primaryColor.withOpacity(0.5),
              tabAlignment: TabAlignment.center,
              tabs: const [
                Tab(text: 'Profile'),
                Tab(text: 'Health'),
                Tab(text: 'Dates'),
                Tab(text: 'Documents'),
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
                  schedule: widget.schedule,
                  sibling: widget.sibling,
                  studentCode: widget.studentCode,
                ),
                StudentHealthTab(
                  scrollController: _healthScrollController,
                  name: widget.name,
                  classroom: widget.classroom,
                  studentCode: widget.studentCode,
                ),
                StudentImportantDatesTab(
                  scrollController: _importantDatesScrollController,
                  name: widget.name,
                  classroom: widget.classroom,
                  studentCode: widget.studentCode,
                ),
                StudentDocumentsTab(
                  scrollController: _documentsScrollController,
                  name: widget.name,
                  classroom: widget.classroom,
                  studentCode: widget.studentCode,
                )

              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentProfileCard(BuildContext context) {
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
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
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
                      const SizedBox(height: 8),
                      FutureBuilder<StudentHealthModel?>(
                        future: _healthFuture,
                        builder: (context, snapshot) {
                          final health = snapshot.data;
                          final hasAllergy =
                              (health?.allergy ?? '').trim().isNotEmpty;
                          final hasMedication =
                              (health?.medications ?? '').trim().isNotEmpty;
                          final hasDietRestrictions =
                              (health?.dietRestrictions ?? '').trim().isNotEmpty;

                          final hasAnyHealthIcon =
                              hasAllergy || hasMedication || hasDietRestrictions;

                          if (!hasAnyHealthIcon) {
                            return const SizedBox.shrink();
                          }

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              if (hasDietRestrictions)
                                Image.asset(
                                  MediaRes.foodIcon2,
                                  height: 20,
                                  width: 20,
                                ),
                              if (hasMedication)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: SvgPicture.asset(
                                    MediaRes.healthIcon,
                                    height: 20,
                                    width: 20,
                                  ),
                                ),
                              if (hasAllergy)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: SvgPicture.asset(
                                    MediaRes.alertIcon,
                                    height: 20,
                                    width: 20,
                                  ),
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
          ),
          _buildStudentActionButtons(context, widget.name),
        ],
      ),
    );
  }

  Widget _buildStudentActionButtons(BuildContext context, studentName) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        gradient: AppColors.buildPrimaryGradient(),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionIcon(MediaRes.attendanceIcon, onTap: () {}),
          _buildActionIcon(
              MediaRes.activitesIcon, onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => ActivityFeedScreen(fromStudentProfile: true, studentName: {'name' : widget.name, 'classroom': widget.classroom, 'tags': widget.tags, 'nappingStatus': false},))); //get this data from database for now hardcoding napping status

          }
          ),
          _buildActionIcon(MediaRes.message_panel_icon, onTap: () {}),
          _buildActionIcon(MediaRes.billing_drawer_icon, onTap: () {}),
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
              : Image.asset(asset, height: 28, color: Colors.white),
        ),
      ),
    );
  }
}
