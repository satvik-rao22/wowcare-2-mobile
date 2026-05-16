import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_service.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/di/di.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/core_utils.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../core/util/string_utils.dart';
import '../../../../domain/features/staff/entities/staff_profile.dart';
import '../../../../domain/features/staff/repositories/staff_repository.dart';
import '../../../../shared/common/widgets/profile_show_widget.dart';
import '../../../../shared/utils/responsive_helper.dart';
import 'edit_user_profile_screen.dart';
import 'package:wowcare/presentation/features/staff/view/staff_profile_screen.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import 'package:wowcare/data/features/auth/datasources/auth_local_datasource.dart';
import 'package:wowcare/data/features/auth/datasources/auth_remote_datasource.dart';
import 'package:wowcare/data/features/student/datasources/student_remote_datasource.dart';
import 'package:wowcare/presentation/features/auth/cubit/auth_cubit.dart';
import 'package:wowcare/shared/common/app/providers/parent_child_provider.dart';
import 'package:wowcare/shared/common/app/providers/role_provider.dart';
import 'package:wowcare/presentation/features/students/view/student_profile_screen.dart';
import 'package:wowcare/core/util/login_persona_util.dart';
import 'package:wowcare/core/util/user_details_school_roles.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';

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
  final ImagePicker _picker = ImagePicker();
  StaffProfile? _profile;
  String _loginDisplayName = '';
  String _loginEmail = '';
  String _loginPersona = '';
  bool _hasShownProfileLoadError = false;
  String? _schoolCode;
  String? _organizationCode;
  bool _isUploadingProfilePhoto = false;
  double _profilePhotoUploadPercent = 0;
  List<String> _distinctRolesForCurrentSchool = const [];
  bool _switchPersonasLoading = false;
  String? _cachedActiveSchoolRole;
  String _guardianPhone = '';
  String _guardianAddress = '';

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
    // Seed from navigation arguments so we don't render '-' while storage loads.
    _loginDisplayName = widget.userName.trim();
    _loginEmail = widget.userEmail.trim();
    _loginPersona = widget.userPersona.trim();
    // Load profile for logged-in user.
    // If staffCode is provided, use it; otherwise resolve staffCode from cached login info.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initProfileLoad();
    });
  }

  Future<void> _initProfileLoad() async {
    // Preload login-based user summary (name, email, persona) from storage
    try {
      final storage = serviceLocator<StorageService>();
      _loginDisplayName =
          (await storage.getString(StorageKeys.displayName) ?? '').trim();
      _loginEmail = (await storage.getString(StorageKeys.email) ?? '').trim();
      final cachedDesignation =
          (await storage.getString(StorageKeys.staffDesignation) ?? '').trim();

      final activeSchoolRole =
          (await storage.getString(StorageKeys.activeSchoolRole) ?? '').trim();
      final rolesJson = await storage.getString(
        StorageKeys.roles,
      ); // JSON array from login
      String persona = '';
      if (activeSchoolRole.isNotEmpty) {
        persona = StringUtils.staffTypeToDisplayRole(activeSchoolRole);
      }
      // For staff personas, show designation instead of staffType/role when available.
      if (persona.isEmpty && cachedDesignation.isNotEmpty) {
        persona = StringUtils.staffTypeToDisplayRole(cachedDesignation);
      }
      final school = (await storage.getString(StorageKeys.schoolCode) ?? '')
          .trim();
      final org = (await storage.getString(StorageKeys.organizationCode) ?? '')
          .trim();
      if (persona.isEmpty && rolesJson != null && rolesJson.isNotEmpty) {
        try {
          final List<dynamic> roles = (jsonDecode(rolesJson) as List<dynamic>);
          final matches = matchingRolesForOrgSchool(
            roles,
            org,
            school,
          ).toList();
          if (matches.isNotEmpty) {
            persona = StringUtils.staffTypeToDisplayRole(
              matches.first['role'] ?? '',
            );
          } else if (roles.isNotEmpty) {
            final first = roles.first as Map<String, dynamic>;
            final roleCode = (first['role'] ?? '').toString();
            persona = StringUtils.staffTypeToDisplayRole(roleCode);
          }
        } catch (_) {}
      }
      _loginPersona = persona;
      if (mounted) {
        setState(() {
          _schoolCode = school.isEmpty ? null : school;
          _organizationCode = org.isEmpty ? null : org;
          _cachedActiveSchoolRole = activeSchoolRole.isEmpty
              ? null
              : activeSchoolRole;
        });
      }
      await _refreshSwitchProfileAvailability();
    } catch (_) {}

    // For guardian/parent persona, load guardian profile fields for phone/address
    // and skip staff profile fetches.
    try {
      if (mounted && context.read<RoleProvider>().isParent) {
        await _loadGuardianProfileForParent();
        if (!mounted) return;
        setState(() => _profile = null);
        return;
      }
    } catch (_) {}

    final direct = (widget.staffCode ?? '').trim();
    if (direct.isNotEmpty) {
      await _loadStaffProfile(direct);
      return;
    }

    final resolved = await _resolveLoggedInStaffCode();
    if (!mounted) return;
    if (resolved.isEmpty) {
      setState(() => _profile = null);
    } else {
      await _loadStaffProfile(resolved);
    }
  }

  /// Attempts to resolve staffCode for the logged-in user from local cache.
  /// Falls back to any cached staffCode to keep my-profile fetch non-blocking.
  Future<String> _resolveLoggedInStaffCode() async {
    try {
      final storage = serviceLocator<StorageService>();

      // Ensure cached staffCode, if any, belongs to the currently logged-in user.
      final currentUserCode =
          (await storage.getString(StorageKeys.userCode) ?? '').trim();
      final cachedStaffCode =
          (await storage.getString(StorageKeys.staffCode) ?? '').trim();
      final cachedStaffUser =
          (await storage.getString(StorageKeys.staffCodeUser) ?? '').trim();

      if (cachedStaffCode.isNotEmpty &&
          cachedStaffUser.isNotEmpty &&
          currentUserCode.isNotEmpty &&
          cachedStaffUser == currentUserCode) {
        // Cache is valid for this user.
        return cachedStaffCode;
      }
      if (cachedStaffCode.isNotEmpty) {
        // Fallback: still use cached staffCode so my-profile API can run.
        return cachedStaffCode;
      }
      return '';
    } catch (_) {
      return '';
    }
  }

  Future<void> _refreshSwitchProfileAvailability() async {
    final org = (_organizationCode ?? '').trim();
    final school = (_schoolCode ?? '').trim();
    if (org.isEmpty || school.isEmpty) {
      if (mounted) {
        setState(() {
          _distinctRolesForCurrentSchool = const [];
          _switchPersonasLoading = false;
        });
      }
      return;
    }
    if (mounted) setState(() => _switchPersonasLoading = true);
    try {
      final storage = serviceLocator<StorageService>();
      var users = await readCachedUserAccessDetailsUsers(storage);
      if (users.isEmpty) {
        final token = (await storage.getString(StorageKeys.accessToken) ?? '')
            .trim();
        if (token.isNotEmpty) {
          users = await serviceLocator<AuthRemoteDataSource>().getUserDetails(
            accessToken: token,
          );
          await storage.saveString(
            StorageKeys.userAccessDetails,
            jsonEncode(users),
          );
        }
      }
      final distinct = distinctActiveRolesForCurrentSchoolFromUserDetails(
        users,
        org,
        school,
      );
      final active =
          (await storage.getString(StorageKeys.activeSchoolRole) ?? '').trim();
      if (!mounted) return;
      setState(() {
        _distinctRolesForCurrentSchool = distinct;
        _cachedActiveSchoolRole = active.isEmpty ? null : active;
        _switchPersonasLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _distinctRolesForCurrentSchool = const [];
        _switchPersonasLoading = false;
      });
    }
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
    if (mounted) setState(() => _switchPersonasLoading = true);
    try {
      // IMPORTANT: do not change visible persona/profile until required
      // APIs are done. Only show the button loader.
      final authLocal = serviceLocator<AuthLocalDataSource>();
      await authLocal.clearPersonaVolatileCaches();
      await authLocal.persistActiveSchoolPersonaRole(backendRole);
      if (!mounted) return;
      context.read<ParentChildProvider>().invalidate();
      // Preload guardian data BEFORE RoleProvider flips to parent so the global
      // dropdown doesn't show a loading state.
      final targetIsGuardian = roleStringIsGuardianPersona(backendRole);
      if (targetIsGuardian) {
        // Also fetch guardian profile so phone/address appear immediately.
        await _loadGuardianProfileForParent();
        if (!mounted) return;
        await context.read<ParentChildProvider>().ensureLoaded(force: true);
      }
      if (!mounted) return;
      await context.read<RoleProvider>().refreshAccessFromServer(force: true);
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
      setState(() {
        _profile = null;
        _cachedActiveSchoolRole = backendRole;
        _loginPersona = StringUtils.staffTypeToDisplayRole(backendRole);
      });
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message:
            'Switched to ${StringUtils.staffTypeToDisplayRole(backendRole)}',
        isSuccess: true,
      );
      await _refreshSwitchProfileAvailability();
      await _initProfileLoad();
    } catch (e) {
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Could not switch profile: $e',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _switchPersonasLoading = false);
    }
  }

  Future<void> _loadStaffProfile(String staffCode) async {
    try {
      final repo = serviceLocator<StaffRepository>();
      // 1) Try cached profile first (fast, no loader).
      if (repo is StaffRepositoryWithCache) {
        final cached = await (repo as StaffRepositoryWithCache)
            .loadCachedStaffProfile(staffCode);
        if (!mounted) return;
        if (cached != null) {
          _profile = cached;
          // Persist staffType for ProfileMenuHeader.
          if (cached.staffType.isNotEmpty) {
            final storage = serviceLocator<StorageService>();
            await storage.saveString(StorageKeys.staffType, cached.staffType);
          }
          if (cached.designation.trim().isNotEmpty) {
            final storage = serviceLocator<StorageService>();
            await storage.saveString(
              StorageKeys.staffDesignation,
              cached.designation.trim(),
            );
          }
          setState(() {});
        }
      }

      // 2) Prefetch latest profile in the background (no loader shown).
      try {
        final fresh = await repo.getStaffProfile(staffCode: staffCode);
        if (!mounted) return;
        // Persist staffType for ProfileMenuHeader (overwrite with latest).
        if (fresh.staffType.isNotEmpty) {
          final storage = serviceLocator<StorageService>();
          await storage.saveString(StorageKeys.staffType, fresh.staffType);
        }
        if (fresh.designation.trim().isNotEmpty) {
          final storage = serviceLocator<StorageService>();
          await storage.saveString(
            StorageKeys.staffDesignation,
            fresh.designation.trim(),
          );
        }
        setState(() {
          _profile = fresh;
        });
      } catch (e) {
        CoreUtils.logApiError(e.toString());
        if (_profile == null && !_hasShownProfileLoadError) {
          _hasShownProfileLoadError = true;
          CoreUtils.showTopSnackBar(
            context: context,
            message: 'Failed to load profile. Please try again.',
            isError: true,
          );
        }
      }
    } catch (e) {
      CoreUtils.logApiError(e.toString());
      if (_profile == null && !_hasShownProfileLoadError) {
        _hasShownProfileLoadError = true;
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Failed to load profile. Please try again.',
          isError: true,
        );
      }
    }
  }

  Future<void> _loadGuardianProfileForParent() async {
    try {
      final storage = serviceLocator<StorageService>();
      final schoolCode = (await storage.getString(StorageKeys.schoolCode) ?? '')
          .trim();
      final userCode = (await storage.getString(StorageKeys.userCode) ?? '')
          .trim();
      if (schoolCode.isEmpty || userCode.isEmpty) return;

      final remote = serviceLocator<StudentRemoteDataSource>();
      final profile = await remote.getGuardianProfile(
        schoolCode: schoolCode,
        userCode: userCode,
      );

      final firstName = (profile['firstName'] ?? '').toString().trim();
      final lastName = (profile['lastName'] ?? '').toString().trim();
      final fullName = (profile['fullName'] ?? '').toString().trim();
      final resolvedName = fullName.isNotEmpty
          ? fullName
          : ('$firstName $lastName').trim();
      final resolvedEmail = (profile['email'] ?? '').toString().trim();
      final resolvedPhone = ((profile['mobile'] ?? profile['phone'] ?? '')
          .toString()
          .trim());

      String resolvedAddress = '';
      final rawAddress = profile['address'];
      if (rawAddress is Map) {
        final m = Map<String, dynamic>.from(rawAddress);
        final parts = <String>[
          (m['street'] ?? m['addressStreet'] ?? '').toString().trim(),
          (m['line2'] ?? m['addressLine2'] ?? '').toString().trim(),
          (m['city'] ?? m['addressCity'] ?? '').toString().trim(),
          (m['state'] ?? m['addressState'] ?? '').toString().trim(),
          (m['zipCode'] ?? m['addressZipCode'] ?? '').toString().trim(),
          (m['country'] ?? m['addressCountry'] ?? '').toString().trim(),
        ].where((e) => e.isNotEmpty).toList(growable: false);
        resolvedAddress = parts.join(', ');
      } else if (rawAddress is String) {
        resolvedAddress = rawAddress.trim();
      }

      if (!mounted) return;
      setState(() {
        if (resolvedName.isNotEmpty) _loginDisplayName = resolvedName;
        if (resolvedEmail.isNotEmpty) _loginEmail = resolvedEmail;
        _guardianPhone = resolvedPhone;
        _guardianAddress = resolvedAddress;
      });
    } catch (_) {
      // Non-blocking: profile still renders with cached/login values.
    }
  }

  String _effectiveStaffCode() {
    final fromProfile = (_profile?.staffCode ?? '').trim();
    if (fromProfile.isNotEmpty) return fromProfile;
    return (widget.staffCode ?? '').trim();
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      var staffCode = _effectiveStaffCode();
      if (staffCode.isEmpty) {
        final resolved = await _resolveLoggedInStaffCode();
        if (!mounted) return;
        staffCode = resolved.trim();
      }
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
        final storage = serviceLocator<StorageService>();
        final school = (await storage.getString(StorageKeys.schoolCode) ?? '')
            .trim();
        final org =
            (await storage.getString(StorageKeys.organizationCode) ?? '')
                .trim();
        if (!mounted) return;
        setState(() {
          _schoolCode = school.isEmpty ? null : school;
          _organizationCode = org.isEmpty ? null : org;
        });
      }
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

      setState(() {
        _isUploadingProfilePhoto = true;
        _profilePhotoUploadPercent = 5;
      });
      final uploadService = serviceLocator<ImageUploadService>();
      final file = File(image.path);
      final sessionCode = await uploadService
          .createStaffProfilePhotoUploadSession(
            staffCode: staffCode,
            schoolCode: schoolCode,
            organizationCode: organizationCode,
          );
      if (mounted) setState(() => _profilePhotoUploadPercent = 15);
      final lowerPath = image.path.toLowerCase();
      final fileName = lowerPath.split(Platform.pathSeparator).last;
      final contentType = lowerPath.endsWith('.png')
          ? 'image/png'
          : 'image/jpeg';
      final presign = await uploadService.createAssetPresign(
        sessionCode: sessionCode,
        documentApiBasePath: '/api/v1',
        fileName: fileName.isNotEmpty
            ? fileName
            : 'staff-profile-photo-${DateTime.now().millisecondsSinceEpoch}.jpg',
        contentType: contentType,
        contentLengthBytes: await file.length(),
        mediaType: 'IMAGE',
        ownerType: 'STAFF',
        ownerCode: staffCode,
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
      await uploadService.finalizeStaffProfilePhoto(
        staffCode: staffCode,
        assetCode: presign.assetCode,
      );
      if (mounted) setState(() => _profilePhotoUploadPercent = 100);

      DocumentImageWidget.clearProfilePhotoCache(staffCode: staffCode);
      await _loadStaffProfile(staffCode);
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Profile photo updated successfully',
        isSuccess: true,
      );
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

  Future<String> _resolveClassroomNameForStaff(StaffProfile profile) async {
    final code = profile.primaryClassroomCode.trim().isNotEmpty
        ? profile.primaryClassroomCode.trim()
        : (profile.allowedClassroomCodes.isNotEmpty
              ? profile.allowedClassroomCodes.first.trim()
              : '');
    if (code.isEmpty) return '-';

    try {
      final storage = serviceLocator<StorageService>();
      final schoolCode = (await storage.getString(StorageKeys.schoolCode) ?? '')
          .trim();
      if (schoolCode.isEmpty) return code;

      final getActiveClassrooms = serviceLocator<GetActiveClassroomsUseCase>();
      final classrooms = await getActiveClassrooms(
        schoolCode: schoolCode,
        onlyTypeClassroom: false,
      );
      for (final c in classrooms) {
        if (c.code.trim() == code) {
          final name = c.name.trim();
          return name.isNotEmpty ? name : code;
        }
      }
      return code;
    } catch (_) {
      return code;
    }
  }

  Future<void> _openStaffProfile() async {
    // Ensure we have a profile to open.
    final staffCode = (_profile?.staffCode ?? widget.staffCode ?? '').trim();
    if (staffCode.isEmpty) {
      final resolved = await _resolveLoggedInStaffCode();
      if (!mounted) return;
      if (resolved.isEmpty) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Unable to resolve staff profile. Please re-login.',
          isError: true,
        );
        return;
      }
      await _loadStaffProfile(resolved);
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

    final classroom = await _resolveClassroomNameForStaff(profile);
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StaffProfileScreen(
          staffCode: profile.staffCode,
          name: profile.fullName.trim().isNotEmpty
              ? profile.fullName.trim()
              : '-',
          classroom: classroom,
          designation: profile.designation,
          phoneNumber: profile.phoneNumber,
          employmentStatus: profile.status,
        ),
      ),
    );
  }

  Future<void> _viewStudentProfileForParent() async {
    final parentChild = context.read<ParentChildProvider>();
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

    await context.read<RoleProvider>().refreshAccessFromServer(force: true);
    if (!mounted) return;

    final resolvedClassroom = await _resolveClassroomNameForStudent(
      selected.classroom,
    );
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => StudentProfileScreen(
          name: selected.name,
          classroom: resolvedClassroom,
          tags: selected.tags,
          schedule: selected.schedule,
          sibling: const <String, dynamic>{
            'name': [],
            'relation': [],
            'status': [],
          },
          studentCode: selected.code,
          syncWithParentChildSelection: true,
        ),
      ),
    );
  }

  Future<String> _resolveClassroomNameForStudent(String classroomRaw) async {
    final raw = classroomRaw.trim();
    if (raw.isEmpty) return '-';
    try {
      final storage = serviceLocator<StorageService>();
      final schoolCode = (await storage.getString(StorageKeys.schoolCode) ?? '')
          .trim();
      if (schoolCode.isEmpty) return raw;

      final getActiveClassrooms = serviceLocator<GetActiveClassroomsUseCase>();
      final classrooms = await getActiveClassrooms(
        schoolCode: schoolCode,
        onlyTypeClassroom: false,
      );
      for (final c in classrooms) {
        if (c.code.trim() == raw) {
          final name = c.name.trim();
          return name.isNotEmpty ? name : raw;
        }
      }
      return raw;
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final responsive = ResponsiveHelper(context);
    final isParentPersona = context.watch<RoleProvider>().isParent;
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
    final String roleDisplay = isParentPersona
        ? StringUtils.staffTypeToDisplayRole(
            activeRoleForDisplay.isNotEmpty ? activeRoleForDisplay : 'GUARDIAN',
          )
        : _profile != null
        ? StringUtils.staffTypeToDisplayRole(
            _profile!.designation.trim().isNotEmpty
                ? _profile!.designation
                : _profile!.staffType,
          )
        : (activeRoleForDisplay.isNotEmpty
              ? StringUtils.staffTypeToDisplayRole(activeRoleForDisplay)
              : _loginPersona);
    final String displayPersona = roleDisplay.isNotEmpty ? roleDisplay : '-';

    return GlobalScaffold(
      hasBackButton: true,
      body: CustomRefreshIndicator(
        onRefresh: _initProfileLoad,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Top profile header (name + role) with 4px horizontal gap
              Card(
                margin: const EdgeInsets.symmetric(vertical: 15, horizontal: 4),
                color: Colors.white,
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
                                  onTap: _pickProfileImage,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      DocumentImageWidget(
                                        fileUuid:
                                            _effectiveStaffCode().isNotEmpty
                                            ? _effectiveStaffCode()
                                            : (displayName.isNotEmpty
                                                  ? displayName
                                                  : 'User'),
                                        name: displayName.isNotEmpty
                                            ? displayName
                                            : 'User',
                                        imageUrl:
                                            (_profile?.profilePhotoUrl ?? '')
                                                .trim()
                                                .isNotEmpty
                                            ? _profile!.profilePhotoUrl.trim()
                                            : null,
                                        staffCode:
                                            _effectiveStaffCode().isNotEmpty
                                            ? _effectiveStaffCode()
                                            : null,
                                        staffEmploymentStatus: _profile?.status,
                                        size: 90,
                                        fontSize: 24,
                                      ),
                                      if (_isUploadingProfilePhoto)
                                        Positioned.fill(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: const Color(0xB3241631),
                                              borderRadius:
                                                  BorderRadius.circular(45),
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
                                                  color: AppColors.primaryColor
                                                      .withOpacity(0.25),
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                  border: Border.all(
                                                    color: Colors.white
                                                        .withOpacity(0.22),
                                                  ),
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      '${_profilePhotoUploadPercent.clamp(0, 100)}%',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
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
                                                        backgroundColor: Colors
                                                            .white
                                                            .withOpacity(0.22),
                                                        valueColor:
                                                            const AlwaysStoppedAnimation<
                                                              Color
                                                            >(
                                                              AppColors
                                                                  .themeColor,
                                                            ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        SvgPicture.asset(
                                                          MediaRes.uploadIcon,
                                                          height: 10,
                                                          width: 10,
                                                          colorFilter:
                                                              ColorFilter.mode(
                                                                Colors.white
                                                                    .withOpacity(
                                                                      0.92,
                                                                    ),
                                                                BlendMode.srcIn,
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
                                                            color: Colors.white
                                                                .withOpacity(
                                                                  0.92,
                                                                ),
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.w600,
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
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.08,
                                                ),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Container(
                                            margin: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              gradient:
                                                  AppColors.buildPrimaryGradient(),
                                              borderRadius:
                                                  BorderRadius.circular(14),
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
                                      // Text(
                                      //   widget.userName, // hardcoded for now
                                      //   style: const TextStyle(
                                      //     color: const Color(0xFF573353),
                                      //     fontFamily: 'Manrope',
                                      //     fontSize: 23,
                                      //     fontWeight: FontWeight.w600,
                                      //     letterSpacing: -0.03 * 23,
                                      //   ),
                                      //   maxLines: 2,
                                      //   overflow: TextOverflow.ellipsis,
                                      // ),
                                      const SizedBox(height: 5),
                                      CustomTextWidget(
                                        text: displayPersona,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      // Text(
                                      //   widget.userPersona,
                                      //   style: const TextStyle(
                                      //     color: const Color(0xFF573353),
                                      //     fontFamily: 'Manrope',
                                      //     fontSize: 15,
                                      //     fontWeight: FontWeight.w400,
                                      //     letterSpacing: -0.03 * 23,
                                      //   ),
                                      //   maxLines: 2,
                                      //   overflow: TextOverflow.ellipsis,
                                      // ),
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
                                      confirmButtonLabel: 'Switch Profile',
                                      onPressedConfirm: _switchPersonasLoading
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
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    gradient: AppColors.buildPrimaryGradient(),
                                  ),
                                  child: TextButton(
                                    onPressed: () async {
                                      if (isParentPersona) {
                                        await _viewStudentProfileForParent();
                                        return;
                                      }
                                      // For staff persona, open StaffProfileScreen.
                                      if (displayPersona != 'Admin') {
                                        await _openStaffProfile();
                                      }
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      alignment: Alignment.center,
                                    ),
                                    child: CustomTextWidget(
                                      text: isParentPersona
                                          ? 'View Student Profile'
                                          : displayPersona == 'Admin'
                                          ? 'View Admin Profile'
                                          : 'View Staff Profile',
                                      textStyle: TextStyle(
                                        fontFamily: 'Manrope',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        height: 16 / 16,
                                      ),
                                      maxLines: 1,
                                    ),
                                    // child: Text(
                                    //   widget.userPersona == 'Admin' ?'View Admin Profile' :  widget.userPersona == 'Parent' ? "View Child's Profile" : 'View Staff Profile', // or view staff profile depending on persona
                                    //   style: const TextStyle(
                                    //     fontFamily: 'Manrope',
                                    //     fontSize: 16,
                                    //     fontWeight: FontWeight.w700,
                                    //     color: Colors.white,
                                    //     height: 16 / 16,
                                    //   ),
                                    //   maxLines: 1,
                                    //   overflow: TextOverflow.ellipsis,
                                    // ),
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
              //const SizedBox(height: 15,),
              // "My Profile" card with 4px gap from screen edge and gradient border
              Container(
                margin: const EdgeInsets.fromLTRB(4, 6, 4, 12),
                decoration: BoxDecoration(
                  gradient: AppColors.buildPrimaryGradient(),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Container(
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                CustomTextWidget(
                                  text: 'My Profile',
                                  fontSize: 18,
                                ),
                                // Text(
                                //   'My Profile',
                                //   style: const TextStyle(
                                //     fontFamily: 'Manrope',
                                //     fontSize: 16,
                                //     color: Color(0xff573353),
                                //     fontWeight: FontWeight.w600,
                                //     letterSpacing: -0.03 * 16,
                                //   ),
                                // ),
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
                                    final initialFirstName = parts.isNotEmpty
                                        ? parts.first
                                        : '';
                                    final initialLastName = parts.length > 1
                                        ? parts.sublist(1).join(' ')
                                        : '';
                                    final initialEmail =
                                        (_profile?.email ?? '')
                                            .trim()
                                            .isNotEmpty
                                        ? _profile!.email.trim()
                                        : _loginEmail;
                                    final initialPhoneNo =
                                        (_profile?.phoneNumber ?? '').trim();
                                    final address = _profile?.address;
                                    final initialStreet =
                                        (address?.street ?? '').trim();
                                    final initialLine2 = (address?.line2 ?? '')
                                        .trim();
                                    final initialCity = (address?.city ?? '')
                                        .trim();
                                    final initialState = (address?.state ?? '')
                                        .trim();
                                    final initialCountry =
                                        (address?.country ?? '').trim();
                                    final initialZip = (address?.zipCode ?? '')
                                        .trim();
                                    final role = displayPersona;

                                    final updated = await Navigator.push<bool>(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            EditUserProfileScreen(
                                              initialFirstName:
                                                  initialFirstName,
                                              initialLastName: initialLastName,
                                              initialEmail: initialEmail,
                                              initialPhoneNo: initialPhoneNo,
                                              initialAddressLine2: initialLine2,
                                              role: role,
                                              initialStreet: initialStreet,
                                              initialCity: initialCity,
                                              initialState: initialState,
                                              initialCountry: initialCountry,
                                              initialZipCode: initialZip,
                                            ),
                                      ),
                                    );
                                    // If profile was updated, reload latest data so
                                    // the multiline address and other fields reflect changes.
                                    if (updated == true && mounted) {
                                      await _initProfileLoad();
                                    }
                                  },
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      gradient:
                                          AppColors.buildPrimaryGradient(),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.edit,
                                      size: 22,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CustomTextWidget(
                                  text: 'Name',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  height: 16 / 13,
                                ),
                                // const Text(
                                //   'Name',
                                //   style: TextStyle(
                                //     fontFamily: 'Manrope',
                                //     fontSize: 13,
                                //     fontWeight: FontWeight.w400,
                                //     color: Color(0xff573353),
                                //     height: 16 / 13,
                                //   ),
                                // ),
                                CustomTextWidget(
                                  text: displayName,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  height: 19 / 14,
                                ),
                                // Text(
                                //   widget.userName,
                                //   style: const TextStyle(
                                //     fontFamily: 'Manrope',
                                //     fontSize: 14,
                                //     fontWeight: FontWeight.w500,
                                //     color: Color(0xff573353),
                                //     height: 19 / 14,
                                //   ),
                                // ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CustomTextWidget(
                                  text: 'Email',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  height: 16 / 13,
                                ),
                                // const Text(
                                //   'Email',
                                //   style: TextStyle(
                                //     fontFamily: 'Manrope',
                                //     fontSize: 13,
                                //     fontWeight: FontWeight.w400,
                                //     color: Color(0xff573353),
                                //     height: 16 / 13,
                                //   ),
                                // ),
                                CustomTextWidget(
                                  text: displayEmail,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  height: 19 / 14,
                                ),
                                // Text(
                                //   widget.userEmail,
                                //   style: const TextStyle(
                                //     fontFamily: 'Manrope',
                                //     fontSize: 14,
                                //     fontWeight: FontWeight.w500,
                                //     color: Color(0xff573353),
                                //     height: 19 / 14,
                                //   ),
                                // ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CustomTextWidget(
                                  text: 'Phone Number',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  height: 16 / 13,
                                ),
                                // const Text(
                                //   'Phone Number',
                                //   style: TextStyle(
                                //     fontFamily: 'Manrope',
                                //     fontSize: 13,
                                //     fontWeight: FontWeight.w400,
                                //     color: Color(0xff573353),
                                //     height: 16 / 13,
                                //   ),
                                // ),
                                CustomTextWidget(
                                  text: displayPhone,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  height: 19 / 14,
                                ),
                                // Text(
                                //   widget.userPhoneNo,
                                //   style: const TextStyle(
                                //     fontFamily: 'Manrope',
                                //     fontSize: 14,
                                //     fontWeight: FontWeight.w500,
                                //     color: Color(0xff573353),
                                //     height: 19 / 14,
                                //   ),
                                // ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
  }
}
