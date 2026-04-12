import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/student/module_access.dart';
import 'package:wowcare/shared/common/app/providers/role_provider.dart';
import 'package:wowcare/presentation/features/activities/view/activity_feed_screen.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_profile.dart';
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
  late String _displayName;
  late String _displayClassroom;
  /// Upper-case API status; set when profile loads (e.g. UPCOMING for yellow dot).
  String? _profileStatusUpper;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _healthFuture = _buildHealthFuture();
    _displayName = widget.name;
    _displayClassroom = widget.classroom;

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

  void _onProfileChanged(StudentProfileModel profile) {
    if (!mounted) return;
    setState(() {
      final nextName = profile.fullName.trim();
      _displayName = nextName.isEmpty ? _displayName : nextName;
      final nextClassroom = (profile.classroom ?? '').trim();
      _displayClassroom =
          nextClassroom.isEmpty ? _displayClassroom : nextClassroom;
      _profileStatusUpper = profile.status.trim().toUpperCase();
    });
  }

  void _showHealthDetailsDialog(StudentHealthModel health) {
    final items = <Widget>[];
    void addLine(String text, Widget leading) {
      final t = text.trim();
      if (t.isEmpty) return;
      items.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              leading,
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Color(0xff573353),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final med = (health.medications ?? '').trim();
    if (med.isNotEmpty) {
      addLine(
        med,
        SvgPicture.asset(
          MediaRes.healthIcon,
          height: 22,
          width: 22,
        ),
      );
    }
    final allergy = (health.allergy ?? '').trim();
    if (allergy.isNotEmpty) {
      addLine(
        allergy,
        SvgPicture.asset(
          MediaRes.alertIcon,
          height: 22,
          width: 22,
        ),
      );
    }
    final diet = (health.dietRestrictions ?? '').trim();
    if (diet.isNotEmpty) {
      addLine(
        diet,
        Image.asset(
          MediaRes.foodIcon2,
          height: 22,
          width: 22,
        ),
      );
    }
    if (health.photoPermission == false) {
      addLine(
        'Photo permission not granted',
        SvgPicture.asset(
          MediaRes.cameraIcon,
          height: 22,
          width: 22,
        ),
      );
    }

    if (items.isEmpty) return;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Details',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xff573353),
                  ),
                ),
                const SizedBox(height: 12),
                ...items,
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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

  void _refreshHeaderHealth() {
    if (!mounted) return;
    setState(() {
      _healthFuture = _buildHealthFuture();
    });
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
    final role = context.read<RoleProvider>();
    if (!ModuleAccess.mayWrite(role, AppAccessModules.student)) {
      ModuleAccess.showWriteRestricted(context);
      return;
    }
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
    final role = context.watch<RoleProvider>();
    final canChangePhoto =
        ModuleAccess.mayWrite(role, AppAccessModules.student);

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
          _buildStudentProfileCard(context, role, canChangePhoto),

          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                StudentProfileTab(
                  scrollController: _profileScrollController,
                  name: _displayName,
                  classroom: _displayClassroom,
                  tags: widget.tags,
                  schedule: widget.schedule,
                  sibling: widget.sibling,
                  studentCode: widget.studentCode,
                  onProfileChanged: _onProfileChanged,
                ),
                StudentHealthTab(
                  scrollController: _healthScrollController,
                  name: _displayName,
                  classroom: _displayClassroom,
                  studentCode: widget.studentCode,
                  onHealthChanged: _refreshHeaderHealth,
                ),
                StudentImportantDatesTab(
                  scrollController: _importantDatesScrollController,
                  name: _displayName,
                  classroom: _displayClassroom,
                  studentCode: widget.studentCode,
                ),
                StudentDocumentsTab(
                  scrollController: _documentsScrollController,
                  name: _displayName,
                  classroom: _displayClassroom,
                  studentCode: widget.studentCode,
                )

              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentProfileCard(
    BuildContext context,
    RoleProvider role,
    bool canChangePhoto,
  ) {
    final isUpcoming = (_profileStatusUpper ?? '') == 'UPCOMING';
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
                  child: Opacity(
                    opacity: canChangePhoto ? 1 : 0.55,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        DocumentImageWidget(
                          fileUuid: _displayName, // seed for stable color when no image
                          name: _displayName,
                          size: 90,
                          fontSize: 24,
                          statusColor: isUpcoming
                              ? const Color(0xFFFFC107)
                              : const Color(0xFF00B115),
                          statusTooltip:
                              isUpcoming ? 'Upcoming student' : 'Active',
                        ),
                        if (canChangePhoto)
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
                          _displayClassroom,
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
                          final isPhotoPermissionOff =
                              (health?.photoPermission ?? true) == false;

                          final hasAnyHealthIcon =
                              hasAllergy ||
                              hasMedication ||
                              hasDietRestrictions ||
                              isPhotoPermissionOff;

                          if (!hasAnyHealthIcon) {
                            return const SizedBox.shrink();
                          }

                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              final h = health;
                              if (h == null) return;
                              _showHealthDetailsDialog(h);
                            },
                            child: Row(
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
                                if (isPhotoPermissionOff)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4),
                                    child: SvgPicture.asset(
                                      MediaRes.cameraIcon,
                                      height: 20,
                                      width: 20,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildStudentActionButtons(context, role),
        ],
      ),
    );
  }

  Widget _buildStudentActionButtons(
    BuildContext context,
    RoleProvider role,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
        gradient: AppColors.buildPrimaryGradient(),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionIcon(
            context,
            role,
            MediaRes.attendanceIcon,
            enabled: role.canOpenModule(AppAccessModules.studentAttendance),
            onTap: () {
              ModuleAccess.runIfFeatureAllowed(
                context,
                role,
                AppAccessModules.studentAttendance,
                () {
                  final code = widget.studentCode?.trim() ?? '';
                  if (code.isEmpty) {
                    CoreUtils.showTopSnackBar(
                      context: context,
                      message: 'Student code is required for attendance.',
                      isError: true,
                    );
                    return;
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      settings: const RouteSettings(
                        name: StudentAttendanceProfile.routeName,
                      ),
                      builder: (_) => StudentAttendanceProfile(
                        studentCode: code,
                        studentId: 0,
                        studentName: _displayName,
                        studentPhotoUuid: null,
                        roomName: _displayClassroom,
                        isSignedIn: false,
                      ),
                    ),
                  );
                },
              );
            },
          ),
          _buildActionIcon(
            context,
            role,
            MediaRes.activitesIcon,
            enabled: role.canOpenModule(AppAccessModules.dailyActivity),
            onTap: () {
              ModuleAccess.runIfFeatureAllowed(
                context,
                role,
                AppAccessModules.dailyActivity,
                () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ActivityFeedScreen(
                        fromStudentProfile: true,
                        allowActivityWrite: ModuleAccess.mayWrite(
                          role,
                          AppAccessModules.dailyActivity,
                        ),
                        studentName: {
                          'name': _displayName,
                          if (widget.studentCode != null &&
                              widget.studentCode!.trim().isNotEmpty)
                            'studentCode': widget.studentCode!.trim(),
                          'classroom': _displayClassroom,
                          'tags': widget.tags,
                          'nappingStatus': false,
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
          _buildActionIcon(
            context,
            role,
            MediaRes.message_panel_icon,
            enabled: role.canAccessAny([
              AppAccessModules.parentMessaging,
              AppAccessModules.staffMessaging,
            ]),
            onTap: () {
              final messagingOk = role.canAccessAny([
                AppAccessModules.parentMessaging,
                AppAccessModules.staffMessaging,
              ]);
              if (messagingOk) {
                CoreUtils.showTopSnackBar(
                  context: context,
                  message: 'Messaging is available from the Messages section.',
                  isError: false,
                );
              } else {
                ModuleAccess.showFeatureRestricted(context);
              }
            },
          ),
          _buildActionIcon(
            context,
            role,
            MediaRes.billing_drawer_icon,
            enabled: role.canAccessAny([
              AppAccessModules.transaction,
              AppAccessModules.invoices,
              AppAccessModules.recurringPlans,
              AppAccessModules.billingSettings,
            ]),
            onTap: () {
              final billingOk = role.canAccessAny([
                AppAccessModules.transaction,
                AppAccessModules.invoices,
                AppAccessModules.recurringPlans,
                AppAccessModules.billingSettings,
              ]);
              if (billingOk) {
                CoreUtils.showTopSnackBar(
                  context: context,
                  message: 'Billing is available from the Transactions section.',
                  isError: false,
                );
              } else {
                ModuleAccess.showFeatureRestricted(context);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(
    BuildContext context,
    RoleProvider role,
    String asset, {
    required VoidCallback onTap,
    required bool enabled,
  }) {
    final bool isSvg = asset.toLowerCase().endsWith('.svg');
    final void Function() tap = enabled
        ? onTap
        : () => ModuleAccess.showFeatureRestricted(context);
    return InkWell(
      onTap: tap,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
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
      ),
    );
  }
}
