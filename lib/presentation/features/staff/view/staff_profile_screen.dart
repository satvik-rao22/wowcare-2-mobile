import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/presentation/features/scheduling/view/staff_scheduling_screen.dart';
import 'package:wowcare/presentation/features/students/module_access.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/core/utils/staff_code_resolver.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
// import 'package:wowcare/presentation/features/attendance/widgets/attendance_popup.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_profile_tab.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_dates_tab.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_documents_tab.dart';
import 'package:wowcare/shared/common/widgets/profile_photo_action_sheet.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/core/utils/file_utils/file_picker_utils.dart';
import 'package:wowcare/presentation/features/staff/view_model/staff_profile_cubit.dart';
import 'package:wowcare/presentation/features/staff/view_model/staff_profile_photo_upload_cubit.dart';
import 'package:wowcare/presentation/features/communication/bulk_messaging/utils/messaging_shortcut.dart';
import 'package:wowcare/presentation/features/staff/view_model/staff_classroom_name_cubit.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/shared/common/widgets/app_tooltip.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/theme/app_icon.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/skeu_press.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/student/entities/student_settings.dart';

class StaffProfileScreen extends StatelessWidget {
  static const String routeName = '/dashboard/staff-profile';

  const StaffProfileScreen({
    super.key,
    required this.staffCode,
    required this.name,
    required this.classroom,
    required this.designation,
    required this.phoneNumber,
    this.userCode = '',
    this.employmentStatus,
    this.classroomNames,
    this.classroomNameByCode,
    this.initialTabIndex = 0,
    this.highlightCode,
  });

  /// Tab to open on entry (0 Profile, 1 Dates, 2 Documents) — set by
  /// notification deep-links.
  final int initialTabIndex;

  /// Row code to highlight inside the opened tab (e.g. documentCode on the
  /// Documents tab). Null for normal navigation.
  final String? highlightCode;

  final String staffCode;
  final String name;

  /// USR_* user code pre-supplied by the caller. Avoids sending STF_* as a
  /// participant code when the Message button is tapped before the async
  /// profile fetch completes.
  final String userCode;

  /// API employment status (e.g. ACTIVE, UPCOMING) for avatar status dot.
  final String? employmentStatus;
  final String classroom;
  final String designation;
  final String phoneNumber;

  /// Optional cached classroom names from StaffScreen (to avoid re-calling classrooms API).
  final List<String>? classroomNames;

  /// Optional mapping from classroom code -> display name.
  final Map<String, String>? classroomNameByCode;

  @override
  Widget build(BuildContext context) {
    // Cubits are created by the route builder (§1.6), not here.
    return _StaffProfileScreenView(
      staffCode: staffCode,
      name: name,
      classroom: classroom,
      designation: designation,
      phoneNumber: phoneNumber,
      userCode: userCode,
      employmentStatus: employmentStatus,
      classroomNames: classroomNames,
      classroomNameByCode: classroomNameByCode,
      initialTabIndex: initialTabIndex,
      highlightCode: highlightCode,
    );
  }
}

class _StaffProfileScreenView extends StatefulWidget {
  const _StaffProfileScreenView({
    required this.staffCode,
    required this.name,
    required this.classroom,
    required this.designation,
    required this.phoneNumber,
    this.userCode = '',
    this.employmentStatus,
    this.classroomNames,
    this.classroomNameByCode,
    this.initialTabIndex = 0,
    this.highlightCode,
  });

  final int initialTabIndex;
  final String? highlightCode;
  final String staffCode;
  final String name;
  final String userCode;
  final String? employmentStatus;
  final String classroom;
  final String designation;
  final String phoneNumber;
  final List<String>? classroomNames;
  final Map<String, String>? classroomNameByCode;

  @override
  State<_StaffProfileScreenView> createState() =>
      _StaffProfileScreenViewState();
}

class _StaffProfileScreenViewState extends State<_StaffProfileScreenView>
    with TickerProviderStateMixin {
  late TabController _tabController;

  late final StaffProfileCubit _staffProfileCubit;
  late final StaffClassroomNameCubit _classroomNameCubit;

  late String _displayName;
  late String _displayDesignation;
  late String _displayClassroom;
  String? _profilePhotoUrl;
  String _profileUserCode = '';
  String? _schoolCode;
  String? _organizationCode;

  bool _isResolvingClassroom = false;

  /// Logged-in user's own staffCode (resolved lazily, staff persona only) —
  /// used to scope document edit/upload to a staff member's own profile.
  String? _ownStaffCode;

  /// School-level settings gating whether staff may add/edit documents on
  /// their own profile independent of the generic STAFF module permission —
  /// see [_canEditStaffDocuments].
  StudentSettings? _staffSettings;

  /// Formats enum-style strings from the API into human readable labels.
  /// Examples:
  /// - "ASSOCIATE_TEACHER" -> "Associate Teacher"
  /// - "FULL_TIME" -> "Full-Time"
  /// - "PART_TIME" -> "Part-Time"
  String _formatEnumLabel(String value) {
    if (value.trim().isEmpty) return '-';
    final upper = value.trim().toUpperCase();

    // Special cases for job type
    if (upper == 'FULL_TIME') return 'Full-Time';
    if (upper == 'PART_TIME') return 'Part-Time';

    final parts = upper.split(RegExp(r'[_\s]+'));
    final words = parts
        .map((part) {
          if (part.isEmpty) return '';
          final lower = part.toLowerCase();
          return lower[0].toUpperCase() + lower.substring(1);
        })
        .where((w) => w.isNotEmpty);
    return words.join(' ');
  }

  @override
  void initState() {
    super.initState();
    _staffProfileCubit = context.read<StaffProfileCubit>();
    _classroomNameCubit = context.read<StaffClassroomNameCubit>();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
    _displayName = widget.name;
    _displayDesignation = _formatEnumLabel(widget.designation);
    _displayClassroom = widget.classroom;
    _profileUserCode = widget.userCode.trim();
    _loadUploadContext();
    _loadOwnStaffCodeIfStaff();
    _loadStaffSettings();
    // Deep-link case: opened by code straight to a non-Profile tab. The summary
    // (name/designation/classroom) is normally pushed up by the Profile tab,
    // which TabBarView builds lazily — so it never runs when we land on Dates or
    // Documents. Fetch here too so the header loads regardless of the tab.
    _ensureHeaderProfileLoaded();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // If classroom is a code (or not present in passed cache), resolve using
      // classrooms API WITHOUT type=CLASSROOM filter.
      _ensureClassroomResolved();
    });
  }

  /// Loads the staff profile at the screen level so the header (name,
  /// designation, classroom, photo) populates even when the user deep-links
  /// straight to a tab other than Profile. Always runs: the caller (staff
  /// list card, deep-link) never has the profile photo to pre-supply, so
  /// this fetch is the ONLY source for [_profilePhotoUrl] — gating it on
  /// "name not already supplied" (the old behaviour) meant the header photo
  /// never loaded on the normal list -> profile navigation, since the list
  /// always passes a name.
  Future<void> _ensureHeaderProfileLoaded() async {
    final code = widget.staffCode.trim();
    if (code.isEmpty) return;
    try {
      // forEditStaff:true hits `/staff/{code}/profile` (this staff member's
      // actual record). The cubit's own default (false) hits
      // `/staff/my-profile/{code}`, which the backend resolves to the
      // LOGGED-IN user's own profile regardless of the code in the path —
      // that mismatch is what showed the viewer's own name/photo instead
      // of the staff member being viewed.
      final profile = await _staffProfileCubit.fetchProfile(
        staffCode: code,
        forEditStaff: true,
      );
      if (!mounted) return;
      setState(() {
        // Name/designation: only backfill when the caller didn't already
        // supply them, so a pre-supplied value never flickers/changes once
        // this slower fetch resolves.
        if (_displayName.trim().isEmpty) {
          final name = profile.fullName.trim();
          if (name.isNotEmpty) _displayName = name;
        }
        if (widget.designation.trim().isEmpty) {
          final designation = profile.designation.trim();
          if (designation.isNotEmpty) {
            _displayDesignation = _formatEnumLabel(designation);
          }
        }
        final photo = profile.profilePhotoUrl.trim();
        if (photo.isNotEmpty) _profilePhotoUrl = photo;
        final uc = profile.userCode.trim();
        if (uc.isNotEmpty) _profileUserCode = uc;
        // Prefer the staff member's own school/organization over the
        // device's active-school context: an admin/staff may be viewing a
        // staff member whose home school differs from the active one, and
        // uploads scoped to the wrong school 500 on the backend.
        final ownerSchoolCode = profile.schoolCode.trim();
        if (ownerSchoolCode.isNotEmpty) _schoolCode = ownerSchoolCode;
        final ownerOrganizationCode = profile.organizationCode.trim();
        if (ownerOrganizationCode.isNotEmpty) {
          _organizationCode = ownerOrganizationCode;
        }
      });
      // Prefer the human-readable name the API already returns; fall back to the
      // code (which _applyHeaderClassroomFromProfile then resolves to a name).
      final classroomName = profile.primaryClassroomName.trim();
      _applyHeaderClassroomFromProfile(
        classroomName.isNotEmpty ? classroomName : profile.primaryClassroomCode,
      );
    } catch (_) {
      // Profile tab's own load still surfaces errors when visited.
    }
  }

  Future<void> _loadUploadContext() async {
    final uploadContext = await context
        .read<StaffProfilePhotoUploadCubit>()
        .loadUploadContext();
    if (!mounted) return;
    setState(() {
      _schoolCode = uploadContext.schoolCode;
      _organizationCode = uploadContext.organizationCode;
    });
  }

  /// Resolves the logged-in user's own staffCode so [_canEditDocuments] can
  /// scope staff document edit/upload to their own profile only. Best-effort:
  /// on failure editing stays disabled for staff.
  Future<void> _loadOwnStaffCodeIfStaff() async {
    try {
      final code = await resolveStaffCodeForLoggedInUser();
      if (!mounted) return;
      setState(() => _ownStaffCode = code);
    } catch (_) {
      // Keep editing disabled for staff on failure.
    }
  }

  /// Loads the school's `canStaffEditTheirOwnHealthRecords` toggle (the
  /// "Allow Staff Upload Document" school setting — see [_canEditStaffDocuments]
  /// and [StudentSettings]'s doc for why the name doesn't match the effect).
  /// Best-effort: on failure, document edit for a staff member without the
  /// generic STAFF module permission simply stays disabled, same as before
  /// this toggle existed.
  Future<void> _loadStaffSettings() async {
    try {
      final storage = serviceLocator<StorageService>();
      final school = (await storage.getString(StorageKeys.schoolCode) ?? '')
          .trim();
      if (school.isEmpty) return;
      final settings = await _staffProfileCubit.fetchSettings(school);
      if (!mounted) return;
      setState(() => _staffSettings = settings);
    } catch (_) {
      // Keep the module-permission-only gate on failure.
    }
  }

  /// Write access on the STAFF module as returned by `/users/details`.
  ///
  /// Every edit affordance on this screen hangs off it. Owning the profile is
  /// NOT permission to edit it: a staff member with read-only STAFF access
  /// must not see the photo, important-dates or document edit actions even on
  /// their own profile.
  bool _hasStaffWriteAccess(RoleCubit role) {
    if (role.isParent || role.isKiosk) return false;
    return ModuleAccess.mayWrite(role, AppAccessModules.staff);
  }

  /// Whether the current persona may add/edit/delete this staff member's own
  /// records (profile photo, Important Dates, Documents): requires STAFF write
  /// access, and the staff persona is additionally scoped to their own
  /// profile. Parents/kiosk never.
  bool _canEditStaffRecords(RoleCubit role) {
    if (!_hasStaffWriteAccess(role)) return false;
    if (role.isStaff) {
      final own = (_ownStaffCode ?? '').trim();
      return own.isNotEmpty && own == widget.staffCode.trim();
    }
    return true;
  }

  /// Whether the current persona may add/edit/delete THIS staff member's
  /// Documents specifically — a staff member viewing their own profile gets
  /// an additional path beyond [_canEditStaffRecords]'s generic STAFF module
  /// permission: the school's "Allow Staff Upload Document" setting
  /// ([StudentSettings.canStaffEditTheirOwnHealthRecords], despite its name —
  /// see that field's doc) grants document edit on its own, independent of
  /// module write access. Photo and Important Dates are unaffected and stay
  /// on [_canEditStaffRecords] alone.
  bool _canEditStaffDocuments(RoleCubit role) {
    if (_canEditStaffRecords(role)) return true;
    if (!role.isStaff) return false;
    final own = (_ownStaffCode ?? '').trim();
    final isOwnProfile = own.isNotEmpty && own == widget.staffCode.trim();
    return isOwnProfile && (_staffSettings?.canStaffEditTheirOwnHealthRecords ?? false);
  }

  bool _canMessageStaff() {
    final own = (_ownStaffCode ?? '').trim();
    // Keep the action hidden until the identity lookup finishes. This avoids
    // briefly offering a self-message action while the profile initializes.
    return own.isNotEmpty && own != widget.staffCode.trim();
  }

  bool _looksLikeClassroomCode(String value) {
    final v = value.trim();
    if (v.isEmpty) return false;
    // Current backend uses "CLS_*" for classrooms; treat that as code.
    return v.startsWith('CLS_') || v.startsWith('LOC_');
  }

  Future<void> _ensureClassroomResolved() async {
    final raw = _displayClassroom.trim();
    if (raw.isEmpty) return;

    final cache = widget.classroomNameByCode ?? const <String, String>{};
    if (cache.isNotEmpty) {
      final cachedName = cache[raw]?.trim();
      if (cachedName != null && cachedName.isNotEmpty) {
        if (!mounted) return;
        setState(() => _displayClassroom = cachedName);
        return;
      }
    }

    // If it's already a readable name, don't hit the API.
    if (!_looksLikeClassroomCode(raw)) return;
    if (_isResolvingClassroom) return;

    setState(() => _isResolvingClassroom = true);
    try {
      final name = await _classroomNameCubit.resolveNameForActiveSchool(raw);
      if (!mounted) return;
      if (name != null) {
        setState(() => _displayClassroom = name);
      }
    } catch (_) {
      // Keep showing raw code when lookup fails.
    } finally {
      if (mounted) setState(() => _isResolvingClassroom = false);
    }
  }

  void _applyHeaderClassroomFromProfile(String incoming) {
    final value = incoming.trim();
    if (value.isEmpty) return;

    // Prefer readable names immediately.
    if (!_looksLikeClassroomCode(value)) {
      if (_displayClassroom != value) {
        setState(() => _displayClassroom = value);
      }
      return;
    }

    // If we already show a resolved human-readable name, don't replace it
    // with raw code on every profile-tab rebuild.
    if (!_looksLikeClassroomCode(_displayClassroom.trim()) &&
        _displayClassroom.trim().isNotEmpty) {
      return;
    }

    if (_displayClassroom != value) {
      setState(() => _displayClassroom = value);
    }
    // Resolve code -> name in background for this screen.
    _ensureClassroomResolved();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Camera capture for the profile photo; hands the shot to the same upload
  /// path as [_pickProfileImage].
  Future<void> _takeProfilePhoto() async {
    if (!_canEditStaffRecords(context.read<RoleCubit>())) {
      ModuleAccess.showWriteRestricted(context);
      return;
    }
    try {
      final shot = await FilePickerUtils.pickOne(
        type: PickType.image,
        source: PickSource.camera,
      );
      if (shot == null || !mounted) return;
      await _pickProfileImage(capturedPath: shot.path);
    } catch (e) {
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Unable to open the camera: $e',
        isError: true,
      );
    }
  }

  Future<void> _pickProfileImage({String? capturedPath}) async {
    // Defense in depth: the camera badge is hidden and the avatar is not
    // tappable without write access, but never let the picker open regardless
    // of how this is reached.
    if (!_canEditStaffRecords(context.read<RoleCubit>())) {
      ModuleAccess.showWriteRestricted(context);
      return;
    }
    try {
      // Shared file picker → every allowed image format is selectable. Skipped
      // when the camera already supplied a path.
      final picked = capturedPath != null
          ? null
          : await FilePickerUtils.pickFile(
              allowedExtensions: FilePickerUtils.allowedImageExtensions,
            );
      final imagePath = capturedPath ?? picked?.path;
      if (imagePath == null || imagePath.isEmpty) return;
      if (!mounted) return;
      final staffCode = widget.staffCode.trim();
      if (staffCode.isEmpty) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Staff code is required to upload profile photo.',
          isError: true,
        );
        return;
      }
      if ((_schoolCode ?? '').trim().isEmpty ||
          (_organizationCode ?? '').trim().isEmpty) {
        await _loadUploadContext();
      }
      if (!mounted) return;
      final schoolCode = (_schoolCode ?? '').trim();
      final organizationCode = (_organizationCode ?? '').trim();
      if (schoolCode.isEmpty || organizationCode.isEmpty) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Missing school or organization context.',
          isError: true,
        );
        return;
      }

      final finalizedUrl = await context
          .read<StaffProfilePhotoUploadCubit>()
          .uploadPhoto(
            staffCode: staffCode,
            schoolCode: schoolCode,
            organizationCode: organizationCode,
            imagePath: imagePath,
          );

      DocumentImageWidget.clearProfilePhotoCache(staffCode: staffCode);
      DocumentImageWidget.markStaffPhotoUploaded(staffCode);
      // forEditStaff:true — an admin/director can change another staff
      // member's photo here (see `_canEditStaffRecords`), so this must read
      // that staff member's own record, not fall back to my-profile.
      final refreshed = await _staffProfileCubit.fetchProfile(
        staffCode: staffCode,
        forEditStaff: true,
      );
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Profile photo updated successfully',
        isSuccess: true,
      );
      setState(() {
        _profilePhotoUrl = (refreshed.profilePhotoUrl).trim().isNotEmpty
            ? refreshed.profilePhotoUrl.trim()
            : finalizedUrl;
        final uc = refreshed.userCode.trim();
        if (uc.isNotEmpty) _profileUserCode = uc;
      });
    } catch (e) {
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Failed to update profile photo: $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        context.read<StaffProfilePhotoUploadCubit>().reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<RoleCubit>();
    // Photo / Important Dates / Documents are this staff member's own records.
    final canEditStaffRecords = _canEditStaffRecords(role);
    // Documents specifically also honor the school's "Allow Staff Upload
    // Document" setting — see [_canEditStaffDocuments].
    final canEditStaffDocuments = _canEditStaffDocuments(role);
    // Profile Information and Schedule are manager-owned: the tab additionally
    // keeps them hidden on the logged-in user's own profile — except for a
    // true admin, who has no other self-service screen for their own
    // schedule (see `allowOwnProfileEdit` below).
    final canEditManagedProfile = _hasStaffWriteAccess(role);
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
              dividerColor: AppColors.transparentColor,
              indicator: const UnderlineTabIndicator(
                borderSide: BorderSide(color: AppColors.themeColor),
              ),
              indicatorPadding: const EdgeInsets.only(bottom: 8),
              labelStyle: const TextStyle(
                color: AppColors.attendanceIconColor,
                fontFamily: AppFonts.body,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              unselectedLabelStyle: TextStyle(
                color: AppColors.primaryColor.withValues(alpha: 0.5),
                fontFamily: AppFonts.body,
                fontSize: 16,
              ),
              labelColor: AppColors.attendanceIconColor,
              unselectedLabelColor: AppColors.primaryColor.withValues(
                alpha: 0.5,
              ),
              tabAlignment: TabAlignment.center,
              tabs: const [
                Tab(text: 'Profile'),
                Tab(text: 'Important Dates'),
                Tab(text: 'Documents'),
                // Billing settings can be added based on role
              ],
            ),
          ),
          _buildStaffProfileCard(context, canChangePhoto: canEditStaffRecords),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                StaffProfileTab(
                  staffCode: widget.staffCode,
                  canEdit: canEditManagedProfile,
                  allowOwnProfileEdit: role.isTrueAdmin,
                  classroomNames: widget.classroomNames,
                  classroomNameByCode: widget.classroomNameByCode,
                  onProfileSummaryChanged:
                      (String name, String classroom, String designation) {
                        setState(() {
                          _displayName = name;
                          _displayDesignation = _formatEnumLabel(designation);
                        });
                        _applyHeaderClassroomFromProfile(classroom);
                      },
                ),
                StaffDatesTab(
                  staffCode: widget.staffCode,
                  canEdit: canEditStaffRecords,
                ),
                StaffDocumentsTab(
                  staffCode: widget.staffCode,
                  canEdit: canEditStaffDocuments,
                  highlightCode: widget.highlightCode,
                  onRefreshSettings: _loadStaffSettings,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Whether a photo exists to delete: the profile carries a URL, or the
  /// avatar has resolved one by staff code. False only while an upload is
  /// still in flight.
  bool _hasStaffPhotoToDelete() {
    if (!mounted) return false;
    if (context.read<StaffProfilePhotoUploadCubit>().state.isUploading) {
      return false;
    }
    return (_profilePhotoUrl ?? '').trim().isNotEmpty ||
        DocumentImageWidget.hasResolvedStaffPhoto(widget.staffCode);
  }

  Future<void> _deleteProfilePhoto() async {
    final staffCode = widget.staffCode.trim();
    if (staffCode.isEmpty) return;
    try {
      await context.read<StaffProfilePhotoUploadCubit>().deletePhoto(
        staffCode: staffCode,
      );

      // Post-success reset, in the order the plan fixes: clear the field the
      // avatar reads FIRST (that is what visually removes the image), then
      // forget the cached URL so every other mounted avatar re-resolves.
      if (!mounted) return;
      setState(() => _profilePhotoUrl = null);
      DocumentImageWidget.forgetProfilePhoto(staffCode: staffCode);
      await _staffProfileCubit.fetchProfile(staffCode: staffCode);
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Profile photo deleted successfully',
        isSuccess: true,
      );
    } catch (e) {
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Failed to delete profile photo: $e',
        isError: true,
      );
    }
  }

  Widget _buildStaffProfileCard(
    BuildContext context, {
    required bool canChangePhoto,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.cardColor,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 30),
            child: Row(
              children: [
                GestureDetector(
                  onTap: canChangePhoto
                      ? () => ProfilePhotoActionSheet.show(
                          context,
                          // Delete is offered whenever a photo exists (only
                          // held back while an upload is still in flight).
                          hasPhoto: _hasStaffPhotoToDelete(),
                          hasPhotoNow: _hasStaffPhotoToDelete,
                          refreshOn: DocumentImageWidget.profilePhotoResolved,
                          subjectName: _displayName.trim().isNotEmpty
                              ? _displayName
                              : widget.name,
                          onChangePhoto: _pickProfileImage,
                          onTakePhoto: _takeProfilePhoto,
                          onDelete: _deleteProfilePhoto,
                        )
                      : null,
                  child: BlocBuilder<StaffProfilePhotoUploadCubit, StaffProfilePhotoUploadState>(
                    builder: (context, uploadState) {
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          DocumentImageWidget(
                            fileUuid: widget.staffCode,
                            // `_profilePhotoUrl` isn't always a resolved
                            // http(s) URL — some responses hand back a raw
                            // media-asset code instead. Feeding that
                            // straight into `imageUrl` both fails to decode
                            // (Image.network on a non-URL renders as
                            // corrupted noise) and blocks the widget's own
                            // staffCode-based photo resolution below, which
                            // only runs when imageUrl/mediaAssetCode are
                            // both empty.
                            imageUrl:
                                (_profilePhotoUrl ?? '').startsWith('http')
                                ? _profilePhotoUrl
                                : null,
                            mediaAssetCode:
                                (_profilePhotoUrl ?? '').isNotEmpty &&
                                    !(_profilePhotoUrl ?? '').startsWith(
                                      'http',
                                    )
                                ? _profilePhotoUrl
                                : null,
                            // Use the resolved display name so the no-photo branch
                            // renders the coloured initials avatar. On a deep-link
                            // widget.name starts empty, which fell back to the grey
                            // placeholder instead of initials.
                            name: _displayName.trim().isNotEmpty
                                ? _displayName
                                : widget.name,
                            staffCode: widget.staffCode,
                            staffEmploymentStatus: widget.employmentStatus,
                            size: 90,
                            fontSize: 24,
                          ),
                          if (uploadState.isUploading)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.staffPhotoUploadOverlayColor,
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
                                        color: AppColors.cardColor.withValues(
                                          alpha: 0.22,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${uploadState.progressPercent.clamp(0, 100)}%',
                                          style: const TextStyle(
                                            color: AppColors.cardColor,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          child: LinearProgressIndicator(
                                            value:
                                                (uploadState.progressPercent /
                                                        100)
                                                    .clamp(0.0, 1.0),
                                            minHeight: 4,
                                            backgroundColor: AppColors.cardColor
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
                                            AppIcon(
                                              MediaRes.uploadIcon,
                                              height: 10,
                                              width: 10,
                                              color: AppColors.cardColor
                                                  .withValues(alpha: 0.92),
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              uploadState.progressPercent >= 100
                                                  ? 'Finalizing'
                                                  : 'Uploading',
                                              style: TextStyle(
                                                color: AppColors.cardColor
                                                    .withValues(alpha: 0.92),
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
                                decoration: AppSurfaces.card(radius: 16),
                                child: SkeuKeyBox(
                                  variant: KeyVariant.primary,
                                  radius: 14,
                                  margin: const EdgeInsets.all(2),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: AppColors.cardColor,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
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
                          color: AppColors.primaryColor.withValues(alpha: 0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.staffInfoBannerBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _displayClassroom,
                          style: const TextStyle(
                            color: AppColors.staffInfoText,
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
    final canMessageStaff = _canMessageStaff();
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: AppSurfaces.key(
        KeyVariant.primary,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionIcon(
            MediaRes.calenderClockIcon,
            // widget.employmentStatus is the same value this screen already
            // renders as the "Status: Upcoming" badge, so it's used directly
            // both to disable the icon and as profileStatus below — no need
            // to re-fetch it (unlike the attendance-list screens, which
            // don't have it locally; see resolveStaffProfileStatus).
            isEnabled: !_isUpcomingProfile,
            disabledTooltip: 'Attendance unavailable for upcoming staff',
            onTap: () {
              final code = widget.staffCode.trim();
              if (code.isEmpty) {
                CoreUtils.showTopSnackBar(
                  context: context,
                  message: 'Staff code is required for attendance.',
                  isError: true,
                );
                return;
              }
              context.push(
                '/dashboard/staff-attendance-profile',
                extra: <String, dynamic>{
                  'staffCode': code,
                  'staffId': 0,
                  'staffName': _displayName,
                  'staffPhotoUuid': null,
                  'designationName': widget.designation,
                  'roomName': _displayClassroom,
                  'isSignedIn': false,
                  'isAbsent': false,
                  'isExpectedToday': true,
                  'isPresentToday': false,
                  'profileStatus': widget.employmentStatus ?? 'ACTIVE',
                },
              );
            },
          ),
          // Staff Scheduling — opens scheduling pre-selected on this staff.
          _buildActionIcon(
            MediaRes.staff_Schedule_drawer_icon,
            onTap: () {
              final code = widget.staffCode.trim();
              if (code.isEmpty) return;
              context.go(
                Uri(
                  path: StaffSchedulingScreen.routeName,
                  queryParameters: <String, String>{'staffCode': code},
                ).toString(),
              );
            },
          ),
          if (canMessageStaff)
            _buildActionIcon(
              MediaRes.communicationIcon,
              onTap: () {
                final code = widget.staffCode.trim();
                if (code.isEmpty) return;
                openMessagingShortcut(
                  context,
                  recipients: [
                    SelectedRecipient(
                      code: code,
                      name: widget.name,
                      isStaff: true,
                      userCode: _profileUserCode,
                      avatar: _profilePhotoUrl ?? '',
                      designation: widget.designation,
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  bool get _isUpcomingProfile =>
      (widget.employmentStatus ?? '').trim().toUpperCase() == 'UPCOMING';

  Widget _buildActionIcon(
    String asset, {
    required VoidCallback onTap,
    bool isEnabled = true,
    String disabledTooltip = '',
  }) {
    final bool isSvg = asset.toLowerCase().endsWith('.svg');
    return AppTooltip(
      message: !isEnabled ? disabledTooltip : '',
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        child: Opacity(
          opacity: isEnabled ? 1.0 : 0.5,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: isSvg
                  ? AppIcon(asset, height: 28, color: AppColors.cardColor)
                  : Image.asset(asset, height: 28, color: AppColors.cardColor),
            ),
          ),
        ),
      ),
    );
  }
}
