import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/students/model/student_sibling_info.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wowcare/src/app_router.dart'
    show AppRoutes, goToDashboardRoot, popAllShellBranchNavigators;
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';

import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_fonts.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/school_switch_events.dart';
import 'package:wowcare/core/utils/string_utils.dart';
import 'package:wowcare/domain/features/staff/entities/staff_profile.dart';
import 'package:wowcare/shared/common/widgets/profile_photo_action_sheet.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/presentation/features/user_profile/view_model/user_profile_cubit.dart';
import 'package:wowcare/presentation/features/staff/model/staff_route_args.dart';
import 'package:wowcare/presentation/features/staff/view/staff_profile_screen.dart';
import 'package:wowcare/presentation/features/auth/view_model/auth_cubit.dart';
import 'package:wowcare/shared/common/app/cubits/parent_child_cubit.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';
import 'package:wowcare/presentation/features/students/view/student_profile_screen.dart';
import 'package:wowcare/core/utils/login_persona_util.dart';
import 'package:wowcare/presentation/features/geofencing/view_model/geofence_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/core/theme/app_icon.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/skeu_press.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({
    super.key,
    this.userName = '',
    this.userPersona = '',
    this.userEmail = '',
    this.userPhoneNo = '',
    this.userAddress = '',
    this.staffCode,
  });
  final String userName;
  final String userPersona;
  final String userEmail;
  final String userPhoneNo;
  final String userAddress;

  /// Optional staffCode for the logged-in staff user. When provided,
  /// this screen will load profile details via GET `/api/v1/staff/{staffCode}/profile`.
  final String? staffCode;

  static const String routeName = '/dashboard/userProfile';

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  /// Formats a [StaffProfileTime] as `h:mm AM/PM` (space before period).
  static String _fmtTime(StaffProfileTime t) {
    final period = t.hour >= 12 ? 'PM' : 'AM';
    final h = t.hour > 12 ? t.hour - 12 : (t.hour == 0 ? 12 : t.hour);
    return '$h:${t.minute.toString().padLeft(2, '0')} $period';
  }

  /// Returns the 3-letter uppercase day abbreviation from a full day name.
  static String _dayAbbr(String day) =>
      day.length >= 3 ? day.substring(0, 3).toUpperCase() : day.toUpperCase();

  final ImagePicker _picker = ImagePicker();
  late final UserProfileCubit _cubit;
  // Dedupes the one-time "failed to load profile" snackbar.
  bool _shownLoadError = false;

  /// Guards the "View Profile" button against multiple taps: it stays true from
  /// the first tap until the pushed profile screen is popped, so rapid taps
  /// can't open several instances. UI-local and never read outside this
  /// screen, so it's a [ValueNotifier] rather than setState (Mandate 2) —
  /// only the button rebuilds while it's in flight, not the whole screen.
  final _openingProfile = ValueNotifier<bool>(false);

  // Read-only proxies onto the cubit's state so the (large) build + helper
  // methods below keep reading the same names while the cubit owns the data.
  StaffProfile? get _profile => _cubit.state.profile;
  String get _loginDisplayName => _cubit.state.loginDisplayName;
  String get _loginEmail => _cubit.state.loginEmail;
  String get _loginPersona => _cubit.state.loginPersona;
  String? get _schoolCode => _cubit.state.schoolCode;
  String? get _organizationCode => _cubit.state.organizationCode;
  bool get _isUploadingProfilePhoto => _cubit.state.isUploadingProfilePhoto;
  double get _profilePhotoUploadPercent =>
      _cubit.state.profilePhotoUploadPercent;
  List<String> get _distinctRolesForCurrentSchool =>
      _cubit.state.distinctRolesForCurrentSchool;
  bool get _switchPersonasLoading => _cubit.state.switchPersonasLoading;
  String? get _cachedActiveSchoolRole => _cubit.state.cachedActiveSchoolRole;
  String get _guardianPhone => _cubit.state.guardianPhone;
  String get _guardianAddress => _cubit.state.guardianAddress;
  String get _guardianCode => _cubit.state.guardianCode;
  String get _guardianPhotoAssetCode => _cubit.state.guardianPhotoAssetCode;
  String get _guardianPhotoUrl => _cubit.state.guardianPhotoUrl;

  String _formatPhoneForDisplay(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      return CoreUtils.formatPhoneNumber(digits);
    }
    return raw;
  }

  @override
  void initState() {
    super.initState();
    // Owned by the ancestor BlocProvider set up in the router's GoRoute
    // builder — resolved here via context.read, never serviceLocator, so
    // BlocProvider (not this widget) is what closes it on dispose.
    _cubit = context.read<UserProfileCubit>();
    // Seed from navigation arguments so we don't render '-' while storage loads.
    _cubit.seed(
      name: widget.userName,
      email: widget.userEmail,
      persona: widget.userPersona,
      directStaffCode: widget.staffCode,
    );
    // Load profile for logged-in user. If staffCode is provided it's used;
    // otherwise the cubit resolves staffCode from cached login info.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _cubit.load(isParent: context.read<RoleCubit>().isParent);
    });
  }

  // The cubit itself needs no disposal here — it's owned by the ancestor
  // BlocProvider set up in the router, which closes it automatically.
  @override
  void dispose() {
    _openingProfile.dispose();
    super.dispose();
  }

  String _effectiveActiveBackendRoleForSwitch() {
    final cached = (_cachedActiveSchoolRole ?? '').trim();
    if (cached.isNotEmpty) return cached;
    if (_distinctRolesForCurrentSchool.length == 1) {
      return _distinctRolesForCurrentSchool.first;
    }
    return '';
  }

  Future<void> _onSwitchProfilePressed() async {
    final org = (_organizationCode ?? '').trim();
    final school = (_schoolCode ?? '').trim();
    if (org.isEmpty || school.isEmpty) return;

    if (_distinctRolesForCurrentSchool.length <= 1) return;

    final roles = _distinctRolesForCurrentSchool
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    if (roles.length <= 1) return;

    final current = _effectiveActiveBackendRoleForSwitch().trim().toUpperCase();
    var currentIndex = -1;
    if (current.isNotEmpty) {
      for (var i = 0; i < roles.length; i++) {
        if (roles[i].toUpperCase() == current) {
          currentIndex = i;
          break;
        }
      }
    }
    final nextIndex = (currentIndex < 0)
        ? 0
        : ((currentIndex + 1) % roles.length);
    final nextRole = roles[nextIndex];
    await _applyPersonaSwitch(nextRole);
  }

  Future<void> _applyPersonaSwitch(String backendRole) async {
    if (backendRole.isEmpty) return;
    _cubit.setSwitching(true);
    try {
      // IMPORTANT: do not change visible persona/profile until required
      // APIs are done. Only show the button loader.
      await _cubit.persistPersonaSwitch(backendRole);
      if (!mounted) return;
      // Wipe every cache layer (repository caches, Isar messaging data,
      // in-memory invalidation gates) BEFORE the refetches below, same as a
      // school switch — otherwise Messaging/Activity/etc, kept alive in the
      // shell's IndexedStack, kept showing the previous persona's cached
      // data (e.g. a guardian's own messages after switching to Staff)
      // until a manual pull-to-refresh.
      try {
        await _cubit.clearCachesForContextSwitch();
      } catch (_) {}
      try {
        context.read<GeofenceCubit>().handleProfileSwitch();
      } catch (_) {}
      context.read<ParentChildCubit>().invalidate();
      // Preload guardian data BEFORE RoleCubit flips to parent so the global
      // dropdown doesn't show a loading state.
      final targetIsGuardian = roleStringIsGuardianPersona(backendRole);
      if (targetIsGuardian) {
        // Also fetch guardian profile so phone/address appear immediately.
        await _cubit.loadGuardianProfileForParent();
        if (!mounted) return;
        await context.read<ParentChildCubit>().ensureLoaded(force: true);
      }
      if (!mounted) return;
      await context.read<RoleCubit>().refreshAccessFromServer(force: true);
      final org = (_organizationCode ?? '').trim();
      final school = (_schoolCode ?? '').trim();
      if (org.isNotEmpty && school.isNotEmpty) {
        try {
          await context.read<AuthCubit>().prefetchStaffProfileForOrgAndSchool(
            organizationCode: org,
            schoolCode: school,
          );
        } catch (_) {}
      }
      if (!mounted) return;
      // Now that prefetch is complete, apply the persona to UI.
      _cubit.applySwitchedPersona(backendRole);
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message:
            'Switched to ${StringUtils.staffTypeToDisplayRole(backendRole)}',
        isSuccess: true,
      );
      await _cubit.refreshSwitchProfileAvailability();
      if (!mounted) return;
      await _cubit.load(isParent: context.read<RoleCubit>().isParent);
      if (!mounted) return;

      // "Switch Profile" can be reached with a route imperatively pushed on
      // top of the root navigator OR a shell branch's own nested navigator
      // (the parent Attendance profile onto dashboardBranchKey, a
      // Communication-module sub-screen onto messagingBranchKey, etc.) —
      // `context.go` alone doesn't know how to pop those, so the pushed
      // screen just keeps covering Dashboard. Unwind every branch's
      // navigator first — see popAllShellBranchNavigators's own doc.
      popAllShellBranchNavigators(context);
      if (!mounted) return;

      // Land on the new persona's dashboard. DashboardScreen branches on
      // RoleCubit, so this shows the correct (admin/staff/parent) dashboard and
      // rebuilds it fresh — otherwise a stale screen lingers after the switch.
      // goToDashboardRoot (not a bare context.go) is what actually switches
      // the shell's active branch — see its own doc for why a plain `go`
      // wasn't landing on Dashboard from another branch (e.g. Messaging).
      goToDashboardRoot(context);

      // Tell every kept-alive branch screen (Dashboard, Classroom, Activity,
      // Messaging, Billing) to reload fresh for the new persona —
      // deliberately AFTER navigating away, not before. A branch screen's
      // own SchoolSwitchReloadMixin (e.g. MessagingScreen) reacts to this by
      // re-keying the BlocProvider wrapping its GlobalScaffold, which would
      // dispose this screen's own context mid-flight if fired while still
      // on it and reached via that branch — see custom_app_bar.dart's
      // identical fix for the concrete symptom this caused ("persona
      // switches, but the screen never moves").
      SchoolSwitchEvents.notifySwitched();
    } catch (e) {
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Could not switch profile: $e',
        isError: true,
      );
    } finally {
      _cubit.setSwitching(false);
    }
  }

  String _effectiveStaffCode() => _cubit.effectiveStaffCode();

  Future<void> _pickProfileImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    if (!mounted) return;
    // The cubit branches staff vs guardian based on persona and streams upload
    // progress into state; we just surface the resulting snackbar.
    final isParent = context.read<RoleCubit>().isParent;
    final result = await _cubit.uploadProfilePhoto(
      imagePath: image.path,
      isParent: isParent,
    );
    if (!mounted) return;
    CoreUtils.showTopSnackBar(
      context: context,
      message: result.message,
      isSuccess: result.isSuccess,
      isError: !result.isSuccess,
    );
  }

  Future<void> _deleteProfileImage() async {
    final isParent = context.read<RoleCubit>().isParent;
    final result = await _cubit.deleteProfilePhoto(isParent: isParent);
    if (!mounted) return;
    CoreUtils.showTopSnackBar(
      context: context,
      message: result.message,
      isSuccess: result.isSuccess,
      isError: !result.isSuccess,
    );
  }

  /// Whether a photo exists to delete, for either persona.
  ///
  /// The guardian branch checks the asset code too: the guardian-profile API
  /// sometimes returns an asset code with no URL (see
  /// `loadGuardianProfileForParent`), so a photo can exist with an empty URL.
  bool _hasDeletableProfilePhoto({required bool isParent}) {
    if (_isUploadingProfilePhoto) return false;
    if (isParent) {
      return _guardianPhotoUrl.trim().isNotEmpty ||
          _guardianPhotoAssetCode.trim().isNotEmpty;
    }
    return (_profile?.profilePhotoUrl ?? '').trim().isNotEmpty;
  }

  Future<void> _openStaffProfile() async {
    // Ensure we have a profile to open.
    final staffCode = (_profile?.staffCode ?? widget.staffCode ?? '').trim();
    if (staffCode.isEmpty) {
      final resolved = await _cubit.resolveLoggedInStaffCode();
      if (!mounted) return;
      if (resolved.isEmpty) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Unable to resolve staff profile. Please re-login.',
          isError: true,
        );
        return;
      }
      await _cubit.loadStaffProfile(resolved);
    }

    final profile = _profile;
    if (profile == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Profile is still loading. Please try again.',
        isWarning: true,
      );
      return;
    }

    final classroom = await _cubit.resolveClassroomNameForStaff(profile);
    if (!mounted) return;

    await context.push(
      StaffProfileScreen.routeName,
      extra: StaffProfileArgs(
        staffCode: profile.staffCode,
        userCode: profile.userCode,
        name: profile.fullName.trim().isNotEmpty
            ? profile.fullName.trim()
            : '-',
        classroom: classroom,
        designation: profile.designation,
        phoneNumber: profile.phoneNumber,
        employmentStatus: profile.status,
      ),
    );
  }

  Future<void> _viewStudentProfileForParent() async {
    final parentChild = context.read<ParentChildCubit>();
    if (!parentChild.isLoaded && !parentChild.isLoading) {
      await parentChild.ensureLoaded();
    }
    final selected = parentChild.selectedChild;
    if (selected == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'No child selected. Choose a child from the menu first.',
        isError: true,
      );
      return;
    }

    await context.read<RoleCubit>().refreshAccessFromServer(force: true);
    if (!mounted) return;

    final resolvedClassroom = await _cubit.resolveClassroomNameForStudent(
      selected.classroom,
    );
    if (!mounted) return;

    await context.push(
      StudentProfileScreen.routeName,
      extra: <String, dynamic>{
        'name': selected.name,
        'classroom': resolvedClassroom,
        'tags': selected.tags,
        'schedule': selected.schedule,
        'sibling': const StudentSiblingInfo(),
        'studentCode': selected.code,
        'syncWithParentChildSelection': true,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<UserProfileCubit>.value(
      value: _cubit,
      child: BlocConsumer<UserProfileCubit, UserProfileState>(
        listener: (context, state) {
          if (state.profileLoadFailed && !_shownLoadError) {
            _shownLoadError = true;
            CoreUtils.showTopSnackBar(
              context: context,
              message: 'Failed to load profile. Please try again.',
              isError: true,
            );
          }
        },
        builder: (context, state) {
          final responsive = ResponsiveHelper(context);
          // Was its own inline `screenWidth > 600` check — a second,
          // disagreeing tablet breakpoint alongside ResponsiveHelper's own
          // >=768 isTablet, exactly the kind of drift Mandate 7 flags.
          // isTabletCompact is the helper's >=600 breakpoint, preserved
          // verbatim for call sites like this one.
          final isTablet = responsive.isTabletCompact;
          final isParentPersona = context.watch<RoleCubit>().isParent;
          final isStaffPersona = context.watch<RoleCubit>().isStaff;
          final String displayName = _profile?.fullName.isNotEmpty == true
              ? _profile!.fullName
              : (_loginDisplayName.isNotEmpty ? _loginDisplayName : '-');
          final String displayEmail = _profile?.email.isNotEmpty == true
              ? _profile!.email
              : (_loginEmail.isNotEmpty ? _loginEmail : '-');
          final String displayPhone = _profile?.phoneNumber.isNotEmpty == true
              ? _formatPhoneForDisplay(_profile!.phoneNumber)
              : (isParentPersona && _guardianPhone.trim().isNotEmpty
                    ? _formatPhoneForDisplay(_guardianPhone.trim())
                    : '-');
          final String displayAddressRaw =
              _profile?.address.formattedAddress.isNotEmpty == true
              ? _profile!.address.formattedAddress
              : (isParentPersona && _guardianAddress.trim().isNotEmpty
                    ? _guardianAddress.trim()
                    : '-');
          // Show address in a more readable multi-line format by breaking on commas.
          final String displayAddress = displayAddressRaw == '-'
              ? '-'
              : displayAddressRaw.replaceAll(', ', '\n');
          final activeRoleForDisplay =
              _effectiveActiveBackendRoleForSwitch().trim().isNotEmpty
              ? _effectiveActiveBackendRoleForSwitch().trim()
              : (_cachedActiveSchoolRole ?? '').trim();
          // Non-parent: show the job designation (e.g. Director / Lead Teacher),
          // preferring the live profile, then the cached designation-first persona,
          // and only falling back to the role/staffType when no designation exists.
          final String _profileDesignation = (_profile?.designation ?? '')
              .trim();
          final String _profileStaffType = (_profile?.staffType ?? '').trim();
          final String roleDisplay = isParentPersona
              ? StringUtils.staffTypeToDisplayRole(
                  activeRoleForDisplay.isNotEmpty
                      ? activeRoleForDisplay
                      : 'GUARDIAN',
                )
              : _profileDesignation.isNotEmpty
              ? StringUtils.staffTypeToDisplayRole(_profileDesignation)
              : (_loginPersona.trim().isNotEmpty
                    ? _loginPersona.trim()
                    : (_profileStaffType.isNotEmpty
                          ? StringUtils.staffTypeToDisplayRole(
                              _profileStaffType,
                            )
                          : (activeRoleForDisplay.isNotEmpty
                                ? StringUtils.staffTypeToDisplayRole(
                                    activeRoleForDisplay,
                                  )
                                : '')));
          final String displayPersona = roleDisplay.isNotEmpty
              ? roleDisplay
              : '-';

          return GlobalScaffold(
            hasBackButton: true,
            body: CustomRefreshIndicator(
              onRefresh: () => _cubit.load(isParent: isParentPersona),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Top profile header (name + role) with 4px horizontal gap
                    Card(
                      margin: const EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 4,
                      ),
                      color: AppColors.cardColor,
                      elevation: 2,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 10,
                            ),
                            child: Column(
                              children: [
                                Container(
                                  height: 120,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isTablet ? 24 : 16,
                                    vertical: 10,
                                  ),
                                  alignment: Alignment.center,
                                  child: Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () =>
                                            ProfilePhotoActionSheet.show(
                                              context,
                                              hasPhoto:
                                                  _hasDeletableProfilePhoto(
                                                    isParent: isParentPersona,
                                                  ),
                                              subjectName: displayName,
                                              onChangePhoto: _pickProfileImage,
                                              onDelete: _deleteProfileImage,
                                            ),
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            DocumentImageWidget(
                                              fileUuid: isParentPersona
                                                  ? (_guardianCode.isNotEmpty
                                                        ? _guardianCode
                                                        : (displayName
                                                                  .isNotEmpty
                                                              ? displayName
                                                              : 'User'))
                                                  : (_effectiveStaffCode()
                                                            .isNotEmpty
                                                        ? _effectiveStaffCode()
                                                        : (displayName
                                                                  .isNotEmpty
                                                              ? displayName
                                                              : 'User')),
                                              name: displayName.isNotEmpty
                                                  ? displayName
                                                  : 'User',
                                              imageUrl: isParentPersona
                                                  ? (_guardianPhotoUrl
                                                            .trim()
                                                            .isNotEmpty
                                                        ? _guardianPhotoUrl
                                                              .trim()
                                                        : null)
                                                  : ((_profile?.profilePhotoUrl ??
                                                                '')
                                                            .trim()
                                                            .isNotEmpty
                                                        ? _profile!
                                                              .profilePhotoUrl
                                                              .trim()
                                                        : null),
                                              mediaAssetCode: isParentPersona
                                                  ? (_guardianPhotoAssetCode
                                                            .trim()
                                                            .isNotEmpty
                                                        ? _guardianPhotoAssetCode
                                                              .trim()
                                                        : null)
                                                  : null,
                                              staffCode:
                                                  (!isParentPersona &&
                                                      _effectiveStaffCode()
                                                          .isNotEmpty)
                                                  ? _effectiveStaffCode()
                                                  : null,
                                              staffEmploymentStatus:
                                                  isParentPersona
                                                  ? null
                                                  : _profile?.status,
                                              disableAttendanceStatusLookup:
                                                  isParentPersona,
                                              size: 90,
                                              fontSize: 24,
                                            ),
                                            if (_isUploadingProfilePhoto)
                                              Positioned.fill(
                                                child: Container(
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xB3241631,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          45,
                                                        ),
                                                  ),
                                                  child: Center(
                                                    child: Container(
                                                      width: 72,
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 7,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: AppColors
                                                            .primaryColor
                                                            .withValues(
                                                              alpha: 0.25,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              14,
                                                            ),
                                                        border: Border.all(
                                                          color: AppColors
                                                              .cardColor
                                                              .withValues(
                                                                alpha: 0.22,
                                                              ),
                                                        ),
                                                      ),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            '${_profilePhotoUploadPercent.clamp(0, 100)}%',
                                                            style:
                                                                const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            height: 4,
                                                          ),
                                                          ClipRRect(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  999,
                                                                ),
                                                            child: LinearProgressIndicator(
                                                              value:
                                                                  (_profilePhotoUploadPercent /
                                                                          100)
                                                                      .clamp(
                                                                        0.0,
                                                                        1.0,
                                                                      ),
                                                              minHeight: 4,
                                                              backgroundColor:
                                                                  AppColors
                                                                      .cardColor
                                                                      .withValues(
                                                                        alpha:
                                                                            0.22,
                                                                      ),
                                                              valueColor:
                                                                  const AlwaysStoppedAnimation<
                                                                    Color
                                                                  >(
                                                                    AppColors
                                                                        .themeColor,
                                                                  ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 4,
                                                          ),
                                                          Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              AppIcon(
                                                                MediaRes
                                                                    .uploadIcon,
                                                                size: 10,
                                                                color: AppColors
                                                                    .cardColor
                                                                    .withValues(
                                                                      alpha:
                                                                          0.92,
                                                                    ),
                                                              ),
                                                              const SizedBox(
                                                                width: 3,
                                                              ),
                                                              Text(
                                                                _profilePhotoUploadPercent >=
                                                                        100
                                                                    ? 'Finalizing'
                                                                    : 'Uploading',
                                                                style: TextStyle(
                                                                  color: Colors
                                                                      .white
                                                                      .withValues(
                                                                        alpha:
                                                                            0.92,
                                                                      ),
                                                                  fontSize: 10,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
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
                                            Positioned(
                                              right: -2,
                                              bottom: -2,
                                              child: Container(
                                                width: 32,
                                                height: 32,
                                                decoration: AppSurfaces.card(
                                                  radius: 16,
                                                ),
                                                child: SkeuKeyBox(
                                                  variant: KeyVariant.primary,
                                                  radius: 14,
                                                  margin: const EdgeInsets.all(
                                                    2,
                                                  ),
                                                  child: const Icon(
                                                    Icons.camera_alt,
                                                    color: AppColors.cardColor,
                                                    size: 16,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 28),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(height: 10),
                                            CustomTextWidget(
                                              text: displayName,
                                              fontSize: 26,
                                            ),
                                            const SizedBox(height: 5),
                                            CustomTextWidget(
                                              text: displayPersona,
                                              fontSize: 17,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    if (_distinctRolesForCurrentSchool.length >
                                        1) ...[
                                      Expanded(
                                        child: SizedBox(
                                          height: 48,
                                          child: CustomButtonLayout(
                                            confirmButtonLabel:
                                                'Switch Profile',
                                            onPressedConfirm:
                                                _switchPersonasLoading
                                                ? null
                                                : _onSwitchProfilePressed,
                                            showCancelButton: false,
                                            isForm: false,
                                            isLoading: _switchPersonasLoading,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                    ],
                                    Expanded(
                                      child: Container(
                                        height: 48,
                                        decoration: AppSurfaces.key(
                                          KeyVariant.primary,
                                          radius: 8,
                                        ),
                                        child: ValueListenableBuilder<bool>(
                                          valueListenable: _openingProfile,
                                          builder: (context, openingProfile, _) => TextButton(
                                            onPressed: openingProfile
                                                ? null
                                                : () async {
                                                    // Block re-entry until the pushed
                                                    // profile screen is popped, so
                                                    // rapid taps open only one instance.
                                                    _openingProfile.value =
                                                        true;
                                                    try {
                                                      if (isParentPersona) {
                                                        await _viewStudentProfileForParent();
                                                      } else {
                                                        // Staff and Admin both open the
                                                        // Staff Profile screen.
                                                        await _openStaffProfile();
                                                      }
                                                    } finally {
                                                      if (mounted) {
                                                        _openingProfile.value =
                                                            false;
                                                      }
                                                    }
                                                  },
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 8,
                                              ),
                                              alignment: Alignment.center,
                                            ),
                                            child: openingProfile
                                                // Loading feedback while the profile
                                                // resolves/opens (mirrors
                                                // CustomButtonLayout's white loader).
                                                ? const SizedBox(
                                                    height: 20,
                                                    width: 20,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor:
                                                          AlwaysStoppedAnimation<
                                                            Color
                                                          >(
                                                            AppColors.cardColor,
                                                          ),
                                                    ),
                                                  )
                                                : CustomTextWidget(
                                                    text: isParentPersona
                                                        ? 'View Student Profile'
                                                        : 'View Staff Profile',
                                                    textStyle: TextStyle(
                                                      fontFamily: AppFonts.body,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color:
                                                          AppColors.cardColor,
                                                      height: 16 / 16,
                                                    ),
                                                    maxLines: 1,
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // "My Profile" card with 4px gap from screen edge and gradient border
                    Container(
                      margin: const EdgeInsets.fromLTRB(4, 6, 4, 12),
                      decoration: AppSurfaces.key(
                        KeyVariant.primary,
                        radius: 10,
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(1),
                        decoration: AppSurfaces.card(radius: 9),
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      CustomTextWidget(
                                        text: 'My Profile',
                                        fontSize: 18,
                                      ),
                                      // Staff persona edits their own profile through HR/admin,
                                      // not this screen — hide the edit action entirely rather
                                      // than show a control that would just fail/be reverted.
                                      if (!isStaffPersona)
                                        GestureDetector(
                                          onTap: () async {
                                            // Prefer loaded profile data; fall back to login name/email.
                                            final fullName =
                                                (_profile?.fullName ?? '')
                                                    .trim()
                                                    .isNotEmpty
                                                ? _profile!.fullName.trim()
                                                : _loginDisplayName.trim();
                                            final parts = fullName
                                                .split(' ')
                                                .where((p) => p.isNotEmpty)
                                                .toList();
                                            final initialFirstName =
                                                parts.isNotEmpty
                                                ? parts.first
                                                : '';
                                            final initialLastName =
                                                parts.length > 1
                                                ? parts.sublist(1).join(' ')
                                                : '';
                                            final initialEmail =
                                                (_profile?.email ?? '')
                                                    .trim()
                                                    .isNotEmpty
                                                ? _profile!.email.trim()
                                                : _loginEmail;
                                            final initialPhoneNo =
                                                (_profile?.phoneNumber ?? '')
                                                    .trim();
                                            final address = _profile?.address;
                                            final initialStreet =
                                                (address?.street ?? '').trim();
                                            final initialLine2 =
                                                (address?.line2 ?? '').trim();
                                            final initialCity =
                                                (address?.city ?? '').trim();
                                            final initialState =
                                                (address?.state ?? '').trim();
                                            final initialCountry =
                                                (address?.country ?? '').trim();
                                            final initialZip =
                                                (address?.zipCode ?? '').trim();
                                            final role = displayPersona;
                                            final isParent = context
                                                .read<RoleCubit>()
                                                .isParent;

                                            final updated = await context
                                                .push<bool>(
                                                  AppRoutes.editUserProfile,
                                                  extra: <String, dynamic>{
                                                    'initialFirstName':
                                                        initialFirstName,
                                                    'initialLastName':
                                                        initialLastName,
                                                    'initialEmail':
                                                        initialEmail,
                                                    'initialPhoneNo':
                                                        initialPhoneNo,
                                                    'initialAddressLine2':
                                                        initialLine2,
                                                    'role': role,
                                                    'initialStreet':
                                                        initialStreet,
                                                    'initialCity': initialCity,
                                                    'initialState':
                                                        initialState,
                                                    'initialCountry':
                                                        initialCountry,
                                                    'initialZipCode':
                                                        initialZip,
                                                    'isParent': isParent,
                                                  },
                                                );
                                            // If profile was updated, reload latest data so
                                            // the multiline address and other fields reflect changes.
                                            if (updated == true && mounted) {
                                              await _cubit.load(
                                                isParent: context
                                                    .read<RoleCubit>()
                                                    .isParent,
                                              );
                                            }
                                          },
                                          child: SkeuKeyBox(
                                            variant: KeyVariant.primary,
                                            radius: 8,
                                            width: 38,
                                            height: 38,
                                            alignment: Alignment.center,
                                            child: const Icon(
                                              Icons.edit,
                                              size: 22,
                                              color: AppColors.cardColor,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      CustomTextWidget(
                                        text: 'Name',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        height: 16 / 13,
                                      ),
                                      CustomTextWidget(
                                        text: displayName,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        height: 19 / 14,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      CustomTextWidget(
                                        text: 'Email',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        height: 16 / 13,
                                      ),
                                      CustomTextWidget(
                                        text: displayEmail,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        height: 19 / 14,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      CustomTextWidget(
                                        text: 'Phone Number',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        height: 16 / 13,
                                      ),
                                      CustomTextWidget(
                                        text: displayPhone,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                        height: 19 / 14,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CustomTextWidget(
                                        text: 'Address',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        height: 16 / 13,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: CustomTextWidget(
                                          text: displayAddress,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          height: 19 / 14,
                                          unlimitedLines: true,
                                          overflow: TextOverflow.visible,
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // ── Schedule section (staff only) ──────────────────
                                  if (!isParentPersona &&
                                      _profile != null &&
                                      (_profile!.workSchedules.isNotEmpty ||
                                          _profile!
                                              .breakSchedules
                                              .isNotEmpty)) ...[
                                    const SizedBox(height: 16),
                                    const Divider(
                                      height: 1,
                                      thickness: 1,
                                      color: AppColors
                                          .userProfileSectionDividerColor,
                                    ),
                                    const SizedBox(height: 16),

                                    // Work Schedule
                                    if (_profile!.workSchedules.isNotEmpty) ...[
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          CustomTextWidget(
                                            text: 'Work Schedule',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      ..._profile!.workSchedules.map((ws) {
                                        final dayAbbr = _dayAbbr(ws.dayOfWeek);
                                        final value =
                                            '${_fmtTime(ws.workStartTime)} - ${_fmtTime(ws.workEndTime)} ($dayAbbr)';
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              CustomTextWidget(
                                                text: dayAbbr,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400,
                                                height: 16 / 13,
                                              ),
                                              CustomTextWidget(
                                                text: value,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                height: 19 / 14,
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ],

                                    // Break Schedule
                                    if (_profile!
                                        .breakSchedules
                                        .isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          CustomTextWidget(
                                            text: 'Break Schedule',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      ..._profile!.breakSchedules.map((bs) {
                                        final dayAbbr = _dayAbbr(bs.dayOfWeek);
                                        final value =
                                            '${_fmtTime(bs.breakStartTime)} - ${_fmtTime(bs.breakEndTime)} ($dayAbbr)';
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              CustomTextWidget(
                                                text: dayAbbr,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400,
                                                height: 16 / 13,
                                              ),
                                              CustomTextWidget(
                                                text: value,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                height: 19 / 14,
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ],
                                  ],

                                  SizedBox(height: responsive.verticalSpacing),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
