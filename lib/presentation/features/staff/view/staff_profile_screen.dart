import 'dart:io';

import 'package:flutter/material.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/presentation/features/scheduling/view/staff_scheduling_screen.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_classroom_by_code_usecase.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_profile.dart';
// import 'package:wowcare/presentation/features/attendance/widgets/attendance_popup.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_profile_tab.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_dates_tab.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_documents_tab.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/core/util/file_picker_utils.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_service.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/presentation/features/communication/bulk_messaging/util/messaging_shortcut.dart';

class StaffProfileScreen extends StatefulWidget {
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
  State<StaffProfileScreen> createState() => _StaffProfileScreenState();
}

class _StaffProfileScreenState extends State<StaffProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  late String _displayName;
  late String _displayDesignation;
  late String _displayClassroom;
  String? _profilePhotoUrl;
  String _profileUserCode = '';
  String? _schoolCode;
  String? _organizationCode;
  bool _isUploadingProfilePhoto = false;
  double _profilePhotoUploadPercent = 0;

  bool _isResolvingClassroom = false;

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
  /// straight to a tab other than Profile. Only runs when we were opened by code
  /// without a pre-supplied name (the notification-redirect path).
  Future<void> _ensureHeaderProfileLoaded() async {
    final code = widget.staffCode.trim();
    if (code.isEmpty || _displayName.trim().isNotEmpty) return;
    try {
      final profile = await serviceLocator<StaffRepository>().getStaffProfile(
        staffCode: code,
      );
      if (!mounted) return;
      setState(() {
        final name = profile.fullName.trim();
        if (name.isNotEmpty) _displayName = name;
        final designation = profile.designation.trim();
        if (designation.isNotEmpty) {
          _displayDesignation = _formatEnumLabel(designation);
        }
        final photo = profile.profilePhotoUrl.trim();
        if (photo.isNotEmpty) _profilePhotoUrl = photo;
        final uc = profile.userCode.trim();
        if (uc.isNotEmpty) _profileUserCode = uc;
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
      final storage = serviceLocator<StorageService>();
      final schoolCode = (await storage.getString(StorageKeys.schoolCode) ?? '')
          .trim();
      // Try active-classrooms list first (fast, cached on backend).
      if (schoolCode.isNotEmpty) {
        final useCase = serviceLocator<GetActiveClassroomsUseCase>();
        final classrooms = await useCase(
          schoolCode: schoolCode,
          onlyTypeClassroom: false,
        );

        for (final c in classrooms) {
          if (c.code.trim() == raw) {
            final name = c.name.trim();
            if (name.isNotEmpty) {
              if (!mounted) return;
              setState(() => _displayClassroom = name);
              return;
            }
            break;
          }
        }
      }

      // Fallback: fetch by code (works even when not in active list).
      final details = await serviceLocator<GetClassroomByCodeUseCase>()(
        code: raw,
      );
      final name = details.name.trim();
      if (!mounted) return;
      if (name.isNotEmpty) {
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

  Future<void> _pickProfileImage() async {
    try {
      // Shared file picker → every allowed image format is selectable.
      final picked = await FilePickerUtils.pickFile(
        allowedExtensions: FilePickerUtils.allowedImageExtensions,
        context: context,
      );
      final imagePath = picked?.path;
      if (imagePath == null || imagePath.isEmpty) return;
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

      setState(() => _isUploadingProfilePhoto = true);
      setState(() => _profilePhotoUploadPercent = 0);
      final uploadService = serviceLocator<ImageUploadService>();
      final file = File(imagePath);
      final sessionCode = await uploadService
          .createStaffProfilePhotoUploadSession(
            staffCode: staffCode,
            schoolCode: schoolCode,
            organizationCode: organizationCode,
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
      final finalizedUrl = await uploadService.finalizeStaffProfilePhoto(
        staffCode: staffCode,
        assetCode: presign.assetCode,
      );
      if (mounted) {
        setState(() => _profilePhotoUploadPercent = 100);
      }

      DocumentImageWidget.clearProfilePhotoCache(staffCode: staffCode);
      final repo = serviceLocator<StaffRepository>();
      final refreshed = await repo.getStaffProfile(staffCode: staffCode);
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Profile photo updated successfully',
        isSuccess: true,
      );
      if (!mounted) return;
      setState(() {
        _profilePhotoUrl = (refreshed.profilePhotoUrl).trim().isNotEmpty
            ? refreshed.profilePhotoUrl.trim()
            : finalizedUrl;
        final uc = refreshed.userCode.trim();
        if (uc.isNotEmpty) _profileUserCode = uc;
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
                color: Colors.black,
                fontFamily: 'Manrope',
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              unselectedLabelStyle: TextStyle(
                color: AppColors.primaryColor.withValues(alpha: 0.5),
                fontFamily: 'Manrope',
                fontSize: 16,
              ),
              labelColor: Colors.black,
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
                          _displayDesignation = _formatEnumLabel(designation);
                        });
                        _applyHeaderClassroomFromProfile(classroom);
                      },
                ),
                StaffDatesTab(staffCode: widget.staffCode),
                StaffDocumentsTab(
                  staffCode: widget.staffCode,
                  highlightCode: widget.highlightCode,
                ),
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
                        fileUuid: widget.staffCode,
                        imageUrl: _profilePhotoUrl,
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
                                    color: Colors.white.withValues(alpha: 0.22),
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
                                      borderRadius: BorderRadius.circular(999),
                                      child: LinearProgressIndicator(
                                        value:
                                            (_profilePhotoUploadPercent / 100)
                                                .clamp(0.0, 1.0),
                                        minHeight: 4,
                                        backgroundColor: Colors.white
                                            .withValues(alpha: 0.22),
                                        valueColor:
                                            const AlwaysStoppedAnimation<Color>(
                                              AppColors.themeColor,
                                            ),
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
          _buildActionIcon(
            MediaRes.calenderClockIcon,
            onTap: () {
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
