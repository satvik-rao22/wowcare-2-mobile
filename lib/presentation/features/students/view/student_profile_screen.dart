import 'dart:async';
import 'dart:io';
import 'package:wowcare/core/util/app_time.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/core/util/file_picker_utils.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/students/module_access.dart';
import 'package:wowcare/shared/common/app/cubit/parent_child_cubit.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'package:wowcare/presentation/features/activities/view/activity_feed_screen.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_profile.dart';
import 'package:wowcare/presentation/features/billing/view/parent_billing_screen.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/transaction_details_screen.dart';
import 'package:wowcare/domain/features/billing/entities/family_summary_entity.dart';
import 'package:wowcare/domain/features/billing/usecases/get_family_summary_usecase.dart';
import 'package:wowcare/presentation/features/students/view/student_profile_screen_tabs/student_documents_tab.dart';
import 'package:wowcare/presentation/features/students/view/student_profile_screen_tabs/student_health_tab.dart';
import 'package:wowcare/presentation/features/students/view/student_profile_screen_tabs/student_important_dates_tab.dart';
import 'package:wowcare/presentation/features/students/view/student_profile_screen_tabs/student_profile_tab.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/cache_manager.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/data/features/student/datasources/student_remote_datasource.dart';
import 'package:wowcare/domain/features/student/entities/student_settings.dart';
import 'package:wowcare/data/features/student/models/student_models.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_service.dart';
import 'package:wowcare/presentation/features/communication/bulk_messaging/util/messaging_shortcut.dart';

import '../../../../app/theme/media_res.dart';
import '../../../../core/util/core_utils.dart';
import '../../../../shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';

class StudentProfileScreen extends StatefulWidget {
  static const String routeName = '/dashboard/student-profile';

  const StudentProfileScreen({
    super.key,
    required this.name,
    required this.classroom,
    required this.tags,
    required this.schedule,
    required this.sibling,
    this.studentCode,

    /// Raw API status (e.g. ACTIVE, UPCOMING) so the header dot is correct before the profile tab loads.
    this.initialEnrollmentStatus,
    this.syncWithParentChildSelection = false,
    this.initialTabIndex = 0,
    this.initialProfileSubTabIndex = 0,
    this.initialHealthSubTabIndex = 0,
    this.highlightCode,
  });

  final String name;
  final String classroom;
  final List<String> tags;
  final List<String> schedule;
  final Map<String, dynamic> sibling;
  final String? studentCode;

  final String? initialEnrollmentStatus;

  /// Tab to open on entry (0 Profile, 1 Health, 2 Dates, 3 Documents) — set by
  /// notification deep-links so e.g. an immunization alert lands on Health.
  final int initialTabIndex;

  /// Sub-tab to open inside the Profile tab (0 About, 1 Family, 2 Pickup) — set
  /// by notification deep-links so e.g. a "parent not added" alert lands on
  /// Family. Only applies when [initialTabIndex] is 0 (Profile).
  final int initialProfileSubTabIndex;

  /// Sub-tab to open inside the Health tab (0 Health, 1 Physician,
  /// 2 Physical Examination Dates, 3 Immunization) — set by notification
  /// deep-links so e.g. a "physical overdue" alert lands on Physical Exam Dates
  /// and an immunization alert lands on Immunization. Only applies when
  /// [initialTabIndex] is 1 (Health).
  final int initialHealthSubTabIndex;

  /// Row code to highlight inside the opened tab (e.g. documentCode on the
  /// Documents tab). Null for normal navigation.
  final String? highlightCode;

  /// When true (e.g. parent opens My Child from drawer), child dropdown updates this screen.
  final bool syncWithParentChildSelection;

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
  late final CacheManager _cacheManager;
  late Future<StudentHealthModel?> _healthFuture;
  late String _displayName;
  late String _displayClassroom;

  /// The classroom's actual CODE — populated once the Profile tab's own
  /// fetch (or the deep-link header fetch below) returns real API data.
  /// See [Student.classroomCode] for why this can't be derived from
  /// [_displayClassroom] (a display name) via a separate name→code lookup.
  String _displayClassroomCode = '';

  /// Upper-case API status; set when profile loads (e.g. UPCOMING for yellow dot).
  String? _profileStatusUpper;

  /// Raw FTE from the API (e.g. "1.0", "0.5"); set when the profile loads.
  /// Displayed ×100 on the front end only (1.0 → 100, 0.5 → 50).
  String? _profileFte;
  String? _activeStudentCode;
  late List<String> _profileTags;
  late List<String> _profileSchedule;
  late Map<String, dynamic> _profileSibling;
  ParentChildCubit? _parentChildProvider;
  StreamSubscription<ParentChildState>? _parentChildSub;
  String? _profilePhotoUrl;
  String? _schoolCode;
  String? _organizationCode;
  bool _isUploadingProfilePhoto = false;
  double _profilePhotoUploadPercent = 0;

  /// School-level student settings; gates Health/Documents editing for the
  /// guardian and staff personas. Null until loaded (edit stays off meanwhile).
  StudentSettings? _studentSettings;

  @override
  void initState() {
    super.initState();
    _cacheManager = CacheManager(serviceLocator<StorageService>());
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 3),
    );
    _activeStudentCode = widget.studentCode;
    _profileTags = List<String>.from(widget.tags);
    _profileSchedule = List<String>.from(widget.schedule);
    _profileSibling = Map<String, dynamic>.from(widget.sibling);
    _healthFuture = _buildHealthFuture();
    _displayName = widget.name;
    _displayClassroom = widget.classroom;
    _profileStatusUpper = widget.initialEnrollmentStatus?.trim().toUpperCase();
    _loadUploadContext();
    _loadStudentSettings();
    // Deep-link case: opened by code straight to a non-Profile tab. The profile
    // fetch that fills the header (name/classroom) lives inside the Profile tab,
    // which TabBarView builds lazily — so it never runs when we land on another
    // tab. Fetch here too so the header loads regardless of the initial tab.
    _ensureHeaderProfileLoaded();

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

  /// Resolves the active student's classroom NAME ([_displayClassroom]) to its
  /// classroom CODE via the loaded [ClassroomCubit] list. The activity flow needs
  /// the code — the feed to pre-filter to this student's room, and the add-flow
  /// to load per-classroom activity settings — but the profile only carries the
  /// name. Returns '' when it can't be resolved (list not loaded / no match).
  String _resolveClassroomCode(BuildContext context) {
    final name = _displayClassroom.trim();
    if (name.isEmpty) return '';
    try {
      final classrooms = context.read<ClassroomCubit>().state.classrooms;
      final needle = name.toLowerCase();
      for (final c in classrooms) {
        if (c.name.trim().toLowerCase() == needle) return c.code.trim();
      }
    } catch (_) {
      // ClassroomCubit not available / not loaded yet — fall through.
    }
    return '';
  }

  /// Loads school-level student settings so the Health/Documents tabs know
  /// whether the current persona may edit. Best-effort: on failure editing
  /// stays disabled for guardian/staff (admins keep their module-access default).
  Future<void> _loadStudentSettings() async {
    try {
      final storage = serviceLocator<StorageService>();
      final school = (await storage.getString(StorageKeys.schoolCode) ?? '')
          .trim();
      if (school.isEmpty) return;
      final settings = await serviceLocator<StudentRemoteDataSource>()
          .getStudentSettings(schoolCode: school);
      if (!mounted) return;
      setState(() => _studentSettings = settings);
    } catch (e) {
      AppLogger.d('[StudentProfile] student settings load failed: $e');
    }
  }

  /// Whether the current persona may edit a student's Health tab: guardian →
  /// [StudentSettings.canParentEditChildHealthRecords], staff → also
  /// [StudentSettings.canParentEditChildHealthRecords] (per backend contract,
  /// this single toggle governs Health-tab edit access for both guardian and
  /// staff personas — [StudentSettings.canStaffEditTheirOwnHealthRecords] is
  /// reserved for Documents, see [_canEditDocuments]), admin → module access.
  bool _canEditHealth(RoleCubit role) {
    if (role.isParent || role.isStaff) {
      return _studentSettings?.canParentEditChildHealthRecords ?? false;
    }
    return ModuleAccess.mayWrite(role, AppAccessModules.student);
  }

  /// Whether the current persona may add/edit/delete a student's Documents:
  /// guardian → [StudentSettings.canParentEditChildHealthRecords], staff →
  /// [StudentSettings.canStaffEditTheirOwnHealthRecords] (despite its
  /// health-records name, this field is the backend's toggle for whether
  /// staff may add/edit student documents), admin → module access.
  bool _canEditDocuments(RoleCubit role) {
    if (role.isParent) {
      return _studentSettings?.canParentEditChildHealthRecords ?? false;
    }
    if (role.isStaff) {
      return _studentSettings?.canStaffEditTheirOwnHealthRecords ?? false;
    }
    return ModuleAccess.mayWrite(role, AppAccessModules.student);
  }

  /// Loads the student's profile at the screen level so the header (name,
  /// classroom, status, photo) populates even when the user deep-links straight
  /// to a tab other than Profile. Only runs when we were opened by code without
  /// a pre-supplied name (i.e. the notification-redirect path).
  Future<void> _ensureHeaderProfileLoaded() async {
    final code = (_activeStudentCode ?? '').trim();
    if (code.isEmpty || _displayName.trim().isNotEmpty) return;
    try {
      final profile = await serviceLocator<StudentRemoteDataSource>()
          .getStudentProfile(code);
      _onProfileChanged(profile);
    } catch (_) {
      // Profile tab's FutureBuilder still surfaces load errors when visited.
    }
  }

  void _onProfileChanged(StudentProfileModel profile) {
    if (!mounted) return;
    AppLogger.d(
      '[ProfileHeader] student=${profile.code} name="${profile.fullName}" '
      'classroom="${profile.classroom}"',
    );
    setState(() {
      final nextName = profile.fullName.trim();
      _displayName = nextName.isEmpty ? _displayName : nextName;
      final nextClassroom = (profile.classroom ?? '').trim();
      _displayClassroom = nextClassroom.isEmpty
          ? _displayClassroom
          : nextClassroom;
      final nextClassroomCode = (profile.classroomCode ?? '').trim();
      if (nextClassroomCode.isNotEmpty) {
        _displayClassroomCode = nextClassroomCode;
      }
      final nextStatus = profile.status.trim().toUpperCase();
      if (nextStatus.isNotEmpty) {
        _profileStatusUpper = nextStatus;
      }
      _profileFte = profile.fte;
      _profilePhotoUrl = (profile.profilePhotoUrl ?? '').trim().isEmpty
          ? null
          : profile.profilePhotoUrl!.trim();
    });
  }

  /// FTE for display: the API value multiplied by 100 (front end only) and shown
  /// as a percentage, with a trailing `.0` dropped for whole numbers.
  /// Null/blank/non-numeric → null so the field is hidden.
  String? get _fteDisplay {
    final raw = (_profileFte ?? '').trim();
    if (raw.isEmpty) return null;
    final value = double.tryParse(raw);
    if (value == null) return null;
    final scaled = value * 100;
    final number = scaled == scaled.roundToDouble()
        ? scaled.toStringAsFixed(0)
        : scaled.toString();
    return '$number%';
  }

  Future<void> _loadUploadContext() async {
    final storage = serviceLocator<StorageService>();
    final schoolCode = (await storage.getString(StorageKeys.schoolCode) ?? '')
        .trim();
    final organizationCode =
        (await storage.getString(StorageKeys.organizationCode) ?? '').trim();
    if (!mounted) return;
    setState(() {
      _schoolCode = schoolCode.isEmpty ? null : schoolCode;
      _organizationCode = organizationCode.isEmpty ? null : organizationCode;
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
                  style: AppTextStyles.body.copyWith(color: Color(0xff573353)),
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
        SvgPicture.asset(MediaRes.healthIcon, height: 22, width: 22),
      );
    }
    final allergy = (health.allergy ?? '').trim();
    if (allergy.isNotEmpty) {
      addLine(
        allergy,
        SvgPicture.asset(MediaRes.alertIcon, height: 22, width: 22),
      );
    }
    final diet = (health.dietRestrictions ?? '').trim();
    if (diet.isNotEmpty) {
      addLine(diet, Image.asset(MediaRes.foodIcon2, height: 22, width: 22));
    }
    if (health.photoPermission == false) {
      addLine(
        'Photo permission not granted',
        SvgPicture.asset(MediaRes.cameraIcon, height: 22, width: 22),
      );
    }

    if (items.isEmpty) return;

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Details',
                  style: AppTextStyles.heading.copyWith(
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
    final code = _activeStudentCode;
    if (code == null || code.isEmpty) {
      return null;
    }
    final dataSource = serviceLocator<StudentRemoteDataSource>();
    try {
      return await dataSource.getStudentHealth(code: code);
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.syncWithParentChildSelection || _parentChildProvider != null) {
      return;
    }
    final p = context.read<ParentChildCubit>();
    _parentChildProvider = p;
    _parentChildSub = p.stream.listen((_) => _onParentChildSelectionChanged());
  }

  void _onParentChildSelectionChanged() {
    if (!widget.syncWithParentChildSelection) return;
    final child = _parentChildProvider?.selectedChild;
    final code = child?.code.trim() ?? '';
    if (code.isEmpty || code == (_activeStudentCode ?? '').trim()) return;
    setState(() {
      _activeStudentCode = code;
      _displayName = child!.name;
      _displayClassroom = child.classroom;
      _profileTags = List<String>.from(child.tags);
      _profileSchedule = List<String>.from(child.schedule);
      _profileSibling = <String, dynamic>{
        'name': <dynamic>[],
        'relation': <dynamic>[],
        'status': <dynamic>[],
      };
      _profileStatusUpper = null;
      _healthFuture = _buildHealthFuture();
    });
  }

  @override
  void dispose() {
    _parentChildSub?.cancel();
    _tabController.dispose();
    _profileScrollController.dispose();
    _healthScrollController.dispose();
    _importantDatesScrollController.dispose();
    _documentsScrollController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    final role = context.read<RoleCubit>();
    if (!ModuleAccess.mayWrite(role, AppAccessModules.student)) {
      ModuleAccess.showWriteRestricted(context);
      return;
    }
    try {
      // Shared file picker → every allowed image format is selectable.
      final picked = await FilePickerUtils.pickFile(
        allowedExtensions: FilePickerUtils.allowedImageExtensions,
        context: context,
      );
      final imagePath = picked?.path;
      if (imagePath == null || imagePath.isEmpty) return;
      final studentCode = (_activeStudentCode ?? '').trim();
      final schoolCode = (_schoolCode ?? '').trim();
      final organizationCode = (_organizationCode ?? '').trim();
      if (studentCode.isEmpty) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Student code is required to upload profile photo.',
          isError: true,
        );
        return;
      }
      if (schoolCode.isEmpty || organizationCode.isEmpty) {
        await _loadUploadContext();
      }
      final resolvedSchoolCode = (_schoolCode ?? '').trim();
      final resolvedOrganizationCode = (_organizationCode ?? '').trim();
      if (resolvedSchoolCode.isEmpty || resolvedOrganizationCode.isEmpty) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Missing school context for photo upload.',
          isError: true,
        );
        return;
      }

      setState(() {
        _isUploadingProfilePhoto = true;
        _profilePhotoUploadPercent = 5;
      });
      final uploadService = serviceLocator<ImageUploadService>();
      final file = File(imagePath);
      final sessionCode = await uploadService
          .createStudentProfilePhotoUploadSession(
            studentCode: studentCode,
            schoolCode: resolvedSchoolCode,
            organizationCode: resolvedOrganizationCode,
          );
      if (mounted) setState(() => _profilePhotoUploadPercent = 15);
      final lowerPath = imagePath.toLowerCase();
      final fileName = lowerPath.split(Platform.pathSeparator).last;
      final mime = FilePickerUtils.getMimeType(
        fileName.contains('.') ? fileName.split('.').last : '',
      );
      final contentType = mime.startsWith('image/') ? mime : 'image/jpeg';
      final presign = await uploadService.createAssetPresign(
        sessionCode: sessionCode,
        documentApiBasePath: '/api/v1',
        fileName: fileName.isNotEmpty
            ? fileName
            : 'student-profile-photo-${AppTime.nowUtc().millisecondsSinceEpoch}.jpg',
        contentType: contentType,
        contentLengthBytes: await file.length(),
        mediaType: 'IMAGE',
        ownerType: 'STUDENT',
        ownerCode: studentCode,
      );
      if (mounted) setState(() => _profilePhotoUploadPercent = 25);
      await uploadService.uploadFileToPresignedUrl(
        file: file,
        presignedPutUrl: presign.presignedPutUrl,
        requiredHeaders: presign.requiredHeaders,
        fallbackContentType: contentType,
        onSendProgress: (int sent, int total) {
          if (!mounted || total <= 0) return;
          final uploadPhasePercent = (sent / total).clamp(0.0, 1.0);
          setState(() {
            _profilePhotoUploadPercent = 25 + (uploadPhasePercent * 55);
          });
        },
      );
      if (mounted) setState(() => _profilePhotoUploadPercent = 84);
      await uploadService.completeAssetUpload(
        sessionCode: sessionCode,
        assetCode: presign.assetCode,
        documentApiBasePath: '/api/v1',
      );
      if (mounted) setState(() => _profilePhotoUploadPercent = 90);
      await uploadService.waitUntilAssetsReady(
        sessionCode: sessionCode,
        expectedAssetCodes: <String>[presign.assetCode],
      );
      if (mounted) setState(() => _profilePhotoUploadPercent = 100);
      final finalizedUrl = await uploadService.finalizeStudentProfilePhoto(
        studentCode: studentCode,
        sessionCode: sessionCode,
        assetCode: presign.assetCode,
        schoolCode: resolvedSchoolCode,
      );
      if (mounted) {
        setState(() => _profilePhotoUploadPercent = 100);
      }

      DocumentImageWidget.clearProfilePhotoCache(studentCode: studentCode);

      final dataSource = serviceLocator<StudentRemoteDataSource>();
      final refreshed = await dataSource.getStudentProfile(studentCode);
      await _cacheManager.saveCache(
        CacheManager.buildCacheKey(
          feature: 'student',
          resource: 'profile',
          identifier: studentCode.trim(),
        ),
        refreshed.toJson(),
      );
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Profile photo updated successfully',
        isSuccess: true,
      );
      if (!mounted) return;
      setState(() {
        _profilePhotoUrl = (refreshed.profilePhotoUrl ?? '').trim().isNotEmpty
            ? refreshed.profilePhotoUrl!.trim()
            : finalizedUrl;
      });
    } catch (e) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Failed to update profile photo: $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingProfilePhoto = false;
          _profilePhotoUploadPercent = 0;
        });
      }
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
        child: Builder(builder: (context) => _buildScreen(context)),
      );
    }

    return _buildScreen(context);
  }

  Widget _buildScreen(BuildContext context) {
    final role = context.watch<RoleCubit>();
    final canChangePhoto = ModuleAccess.mayWrite(
      role,
      AppAccessModules.student,
    );
    final canEditHealth = _canEditHealth(role);
    final canEditDocuments = _canEditDocuments(role);

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
              labelStyle: AppTextStyles.bodyLarge.copyWith(
                color: const Color(0xFF241631),
              ),
              unselectedLabelStyle: AppTextStyles.emptyState.copyWith(
                color: AppColors.primaryColor.withValues(alpha: 0.5),
              ),
              //labelColor: Colors.black,
              labelColor: const Color(0xFF241631),
              unselectedLabelColor: AppColors.primaryColor.withValues(
                alpha: 0.5,
              ),
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
                  key: ValueKey<String>(
                    'profile_tab_${_activeStudentCode ?? 'none'}',
                  ),
                  scrollController: _profileScrollController,
                  name: _displayName,
                  classroom: _displayClassroom,
                  tags: _profileTags,
                  schedule: _profileSchedule,
                  sibling: _profileSibling,
                  studentCode: _activeStudentCode,
                  initialTabIndex: widget.initialProfileSubTabIndex.clamp(0, 2),
                  onProfileChanged: _onProfileChanged,
                ),
                StudentHealthTab(
                  key: ValueKey<String>(
                    'health_tab_${_activeStudentCode ?? 'none'}',
                  ),
                  initialTabIndex: widget.initialHealthSubTabIndex.clamp(0, 3),
                  scrollController: _healthScrollController,
                  name: _displayName,
                  classroom: _displayClassroom,
                  studentCode: _activeStudentCode,
                  canEdit: canEditHealth,
                  onHealthChanged: _refreshHeaderHealth,
                ),
                StudentImportantDatesTab(
                  key: ValueKey<String>(
                    'dates_tab_${_activeStudentCode ?? 'none'}',
                  ),
                  scrollController: _importantDatesScrollController,
                  name: _displayName,
                  classroom: _displayClassroom,
                  studentCode: _activeStudentCode,
                ),
                StudentDocumentsTab(
                  key: ValueKey<String>(
                    'docs_tab_${_activeStudentCode ?? 'none'}',
                  ),
                  scrollController: _documentsScrollController,
                  name: _displayName,
                  classroom: _displayClassroom,
                  studentCode: _activeStudentCode,
                  canEdit: canEditDocuments,
                  highlightCode: widget.highlightCode,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentProfileCard(
    BuildContext context,
    RoleCubit role,
    bool canChangePhoto,
  ) {
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
                          fileUuid: _activeStudentCode ?? _displayName,
                          imageUrl: _profilePhotoUrl,
                          name: _displayName,
                          studentCode: _activeStudentCode,
                          studentEnrollmentStatus: _profileStatusUpper,
                          size: 90,
                          fontSize: 24,
                        ),
                        if (_isUploadingProfilePhoto)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xB3241631),
                                borderRadius: BorderRadius.circular(45),
                              ),
                              child: Center(
                                child: Container(
                                  width: 72,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryColor.withValues(
                                      alpha: 0.25,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.22,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${_profilePhotoUploadPercent.clamp(0, 100)}%',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        child: LinearProgressIndicator(
                                          value:
                                              (_profilePhotoUploadPercent / 100)
                                                  .clamp(0.0, 1.0),
                                          minHeight: 4,
                                          backgroundColor: Colors.white
                                              .withValues(alpha: 0.22),
                                          valueColor:
                                              const AlwaysStoppedAnimation<
                                                Color
                                              >(AppColors.themeColor),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SvgPicture.asset(
                                            MediaRes.uploadIcon,
                                            height: 10,
                                            width: 10,
                                            colorFilter: ColorFilter.mode(
                                              Colors.white.withValues(
                                                alpha: 0.92,
                                              ),
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            _profilePhotoUploadPercent >= 100
                                                ? 'Finalizing'
                                                : 'Uploading',
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: 0.92,
                                              ),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
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
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Container(
                                margin: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  gradient: AppColors.buildPrimaryGradient(),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 16,
                                ),
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
                          style: AppTextStyles.body.copyWith(
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<StudentHealthModel?>(
                        future: _healthFuture,
                        builder: (context, snapshot) {
                          final health = snapshot.data;
                          final hasAllergy = (health?.allergy ?? '')
                              .trim()
                              .isNotEmpty;
                          final hasMedication = (health?.medications ?? '')
                              .trim()
                              .isNotEmpty;
                          final hasDietRestrictions =
                              (health?.dietRestrictions ?? '')
                                  .trim()
                                  .isNotEmpty;
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

  Widget _buildStudentActionButtons(BuildContext context, RoleCubit role) {
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
                  final code = (_activeStudentCode ?? '').trim();
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
                        syncWithParentChildSelection:
                            widget.syncWithParentChildSelection,
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
                  // Resolve the classroom NAME → CODE so the activity feed can
                  // filter to this student's room and the add-activity flow can
                  // load per-classroom activity settings (the profile only holds
                  // the name; without the code the add screen shows "No
                  // activities available from API").
                  final classroomCode = _resolveClassroomCode(context);
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
                          if (_activeStudentCode != null &&
                              _activeStudentCode!.trim().isNotEmpty)
                            'studentCode': _activeStudentCode!.trim(),
                          'classroom': _displayClassroom,
                          if (classroomCode.isNotEmpty)
                            'classroomCode': classroomCode,
                          'tags': _profileTags,
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
              if (!messagingOk) {
                ModuleAccess.showFeatureRestricted(context);
                return;
              }
              final code = (_activeStudentCode ?? '').trim();
              if (code.isEmpty) {
                CoreUtils.showTopSnackBar(
                  context: context,
                  message: 'Student details not loaded yet. Please try again.',
                  isError: true,
                );
                return;
              }
              openMessagingShortcut(
                context,
                recipients: [
                  SelectedRecipient(
                    code: code,
                    name: _displayName,
                    isStaff: false,
                    classroomCode: _displayClassroomCode,
                  ),
                ],
              );
            },
          ),
          // Billing is hidden for the staff persona; admins open the
          // student's family billing profile, parents/guardians land on
          // their family billing tab.
          if (!role.isStaff)
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
                if (!billingOk) {
                  ModuleAccess.showFeatureRestricted(context);
                  return;
                }
                // Admin persona (role == 'admin', i.e. isAdmin but not staff):
                // open this student's family billing profile.
                if (role.isAdmin && !role.isStaff) {
                  final code = (_activeStudentCode ?? '').trim();
                  if (code.isEmpty) {
                    CoreUtils.showTopSnackBar(
                      context: context,
                      message:
                          'Student details not loaded yet. Please try again.',
                      isError: true,
                    );
                    return;
                  }
                  _openStudentFamilyBilling(context, code);
                  return;
                }
                // Parent/guardian persona: land on the bottom-nav Billing
                // branch, same as the dashboard billing card.
                if (role.isParent) {
                  context.go(ParentBillingScreen.routeName);
                  return;
                }
                // Any other persona reaching here (e.g. kiosk with module
                // access somehow granted) has no billing destination.
                ModuleAccess.showFeatureRestricted(context);
              },
            ),
        ],
      ),
    );
  }

  /// Resolves the student's family (`FAM_…`) from the billing family-summary —
  /// the family-ledger API is keyed by the FAMILY owner code, not the student
  /// code — then opens that family's billing profile. Mirrors how the admin
  /// billing screen navigates.
  Future<void> _openStudentFamilyBilling(
    BuildContext context,
    String studentCode,
  ) async {
    final storage = serviceLocator<StorageService>();
    final org = (await storage.getString(StorageKeys.organizationCode) ?? '')
        .trim();
    final school = (await storage.getString(StorageKeys.schoolCode) ?? '')
        .trim();
    if (!context.mounted) return;
    if (org.isEmpty || school.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Missing school context. Please try again.',
        isError: true,
      );
      return;
    }

    CoreUtils.showLoadingDialog(context);
    try {
      final families = await serviceLocator<GetFamilySummaryUseCase>()(
        organizationCode: org,
        school: school,
      );
      FamilySummaryEntity? family;
      for (final f in families) {
        if (f.studentCodes.contains(studentCode)) {
          family = f;
          break;
        }
      }
      if (!context.mounted) return;
      // showLoadingDialog uses the root navigator, so dismiss it there.
      Navigator.of(context, rootNavigator: true).pop();
      if (family == null) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'No billing profile found for this student.',
          isError: true,
        );
        return;
      }
      final resolved = family;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => TransactionDetailsScreen(
            ownerType: resolved.ownerType.isNotEmpty
                ? resolved.ownerType
                : 'FAMILY',
            ownerCode: resolved.ownerCode,
            familyName: resolved.familyName.isNotEmpty
                ? resolved.familyName
                : _displayName,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      // showLoadingDialog uses the root navigator, so dismiss it there.
      Navigator.of(context, rootNavigator: true).pop();
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Unable to open billing. Please try again.',
        isError: true,
      );
    }
  }

  Widget _buildActionIcon(
    BuildContext context,
    RoleCubit role,
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
