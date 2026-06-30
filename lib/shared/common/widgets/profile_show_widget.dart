import 'dart:async';
import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/core/util/string_utils.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_today_sign_in_status_map_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_today_sign_in_status_map_usecase.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_service.dart';

class DocumentImageWidget extends StatefulWidget {
  static const Duration _profilePhotoCacheTtl = Duration(minutes: 10);
  final String fileUuid;
  final String? imageUrl;
  final String? mediaAssetCode;
  final String? name;

  /// Optional staff code for attendance status dot.
  final String? staffCode;

  /// Employment/list status (e.g. `UPCOMING`) — shows amber dot, takes precedence over attendance API.
  final String? staffEmploymentStatus;

  /// Enrollment/list status (e.g. `UPCOMING`) — amber dot, takes precedence over attendance API.
  final String? studentEnrollmentStatus;

  /// Optional student code for attendance status dot.
  final String? studentCode;

  /// Optional classroom code — when set (and no [imageUrl]/[mediaAssetCode] is
  /// given), the widget resolves and renders the classroom logo via the
  /// classroom-logo asset-codes endpoint → document service, mirroring how
  /// staff/student profile photos are resolved.
  final String? classroomCode;
  final double size;
  final String? placeholderAsset;
  final BoxShape shape;
  final BoxFit fit;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final Widget? errorWidget;
  final double? fontSize;
  final Color? statusColor; // optional small status dot color
  /// Tooltip when showing [statusColor] without API-driven attendance label.
  final String? statusTooltip;

  /// If true, the API-driven attendance dot is shown only when status == ABSENT.
  /// (E.g. sign-in selection screens want to highlight absences only.)
  final bool showOnlyAbsentAttendanceDot;

  /// If true, widget does not call profile/asset-code endpoints as a fallback
  /// when both [imageUrl] and [mediaAssetCode] are empty.
  final bool disableProfileLookupFallback;

  /// If true, widget will NOT call attendance APIs for status dot.
  /// You can provide [statusColor] + [statusTooltip] instead (e.g. from a cached map).
  final bool disableAttendanceStatusLookup;

  const DocumentImageWidget({
    Key? key,
    required this.fileUuid,
    this.imageUrl,
    this.mediaAssetCode,
    this.name,
    this.staffCode,
    this.staffEmploymentStatus,
    this.studentEnrollmentStatus,
    this.studentCode,
    this.classroomCode,
    this.size = 50.0,
    this.placeholderAsset,
    this.shape = BoxShape.circle,
    this.fit = BoxFit.cover,
    this.onTap,
    this.borderRadius,
    this.errorWidget,
    this.fontSize,
    this.statusColor,
    this.statusTooltip,
    this.showOnlyAbsentAttendanceDot = false,
    this.disableProfileLookupFallback = false,
    this.disableAttendanceStatusLookup = false,
  }) : super(key: key);

  static void clearProfilePhotoCache({String? studentCode, String? staffCode}) {
    final student = (studentCode ?? '').trim();
    final staff = (staffCode ?? '').trim();
    if (student.isEmpty && staff.isEmpty) {
      _DocumentImageWidgetState._profilePhotoUrlCache.clear();
      _DocumentImageWidgetState._profilePhotoFetchedAt.clear();
      _DocumentImageWidgetState._profilePhotoInFlight.clear();
      return;
    }
    if (student.isNotEmpty) {
      final key = 'student:$student';
      _DocumentImageWidgetState._profilePhotoUrlCache.remove(key);
      _DocumentImageWidgetState._profilePhotoFetchedAt.remove(key);
      _DocumentImageWidgetState._profilePhotoInFlight.remove(key);
    }
    if (staff.isNotEmpty) {
      final key = 'staff:$staff';
      _DocumentImageWidgetState._profilePhotoUrlCache.remove(key);
      _DocumentImageWidgetState._profilePhotoFetchedAt.remove(key);
      _DocumentImageWidgetState._profilePhotoInFlight.remove(key);
    }
  }

  @override
  State<DocumentImageWidget> createState() => _DocumentImageWidgetState();
}

class _DocumentImageWidgetState extends State<DocumentImageWidget> {
  static final Map<String, String> _profilePhotoUrlCache = <String, String>{};
  static final Map<String, DateTime> _profilePhotoFetchedAt =
      <String, DateTime>{};
  static final Map<String, Future<String?>> _profilePhotoInFlight =
      <String, Future<String?>>{};

  // ── Batch sign-in status fetching ──────────────────────────────────────────
  // All widget instances share these static queues. A 50 ms debounce timer
  // coalesces rapid concurrent requests into a single POST that sends all
  // pending codes at once, matching the batch API contract:
  //   POST /api/v1/attendance/student-attendance/sign-in/status
  //   body: { "studentCodes": ["STD_…", …] }  →  { "data": { "STD_…": "SIGNED_IN", … } }
  static final Map<String, Completer<String?>> _pendingStudentCodes =
      <String, Completer<String?>>{};
  static final Map<String, Completer<String?>> _pendingStaffCodes =
      <String, Completer<String?>>{};
  static Timer? _studentBatchTimer;
  static Timer? _staffBatchTimer;
  static const Duration _kBatchDebounce = Duration(milliseconds: 50);

  static Future<String?> _batchStudentStatus(String studentCode) {
    final existing = _pendingStudentCodes[studentCode];
    if (existing != null) return existing.future;
    final c = Completer<String?>();
    _pendingStudentCodes[studentCode] = c;
    _studentBatchTimer?.cancel();
    _studentBatchTimer = Timer(_kBatchDebounce, _flushStudentBatch);
    return c.future;
  }

  static Future<String?> _batchStaffStatus(String staffCode) {
    final existing = _pendingStaffCodes[staffCode];
    if (existing != null) return existing.future;
    final c = Completer<String?>();
    _pendingStaffCodes[staffCode] = c;
    _staffBatchTimer?.cancel();
    _staffBatchTimer = Timer(_kBatchDebounce, _flushStaffBatch);
    return c.future;
  }

  static Future<void> _flushStudentBatch() async {
    if (_pendingStudentCodes.isEmpty) return;
    final batch = Map<String, Completer<String?>>.from(_pendingStudentCodes);
    _pendingStudentCodes.clear();
    _studentBatchTimer = null;
    try {
      final useCase = serviceLocator<GetStudentTodaySignInStatusMapUseCase>();
      final map = await useCase(studentCodes: batch.keys.toList());
      batch.forEach((code, completer) {
        if (!completer.isCompleted) completer.complete(map[code]);
      });
    } catch (_) {
      batch.forEach((_, completer) {
        if (!completer.isCompleted) completer.complete(null);
      });
    }
  }

  static Future<void> _flushStaffBatch() async {
    if (_pendingStaffCodes.isEmpty) return;
    final batch = Map<String, Completer<String?>>.from(_pendingStaffCodes);
    _pendingStaffCodes.clear();
    _staffBatchTimer = null;
    try {
      final useCase = serviceLocator<GetStaffTodaySignInStatusMapUseCase>();
      final map = await useCase(staffCodes: batch.keys.toList());
      batch.forEach((code, completer) {
        if (!completer.isCompleted) completer.complete(map[code]);
      });
    } catch (_) {
      batch.forEach((_, completer) {
        if (!completer.isCompleted) completer.complete(null);
      });
    }
  }
  // ───────────────────────────────────────────────────────────────────────────

  Color? _avatarColor;
  Color? _statusDotColor;
  String? _statusLabel; // SIGNED_IN / ABSENT / null
  String? _resolvedImageUrl;
  bool _isLoadingStatus = false;

  @override
  void initState() {
    super.initState();
    _avatarColor = _pickStableProfileAvatarColor(
      widget.name?.trim().isNotEmpty == true
          ? widget.name!.trim()
          : widget.fileUuid,
    );
    _resolvedImageUrl = _seedImageUrl();
    _resolveProfilePhotoIfNeeded();
    _loadAttendanceStatusIfNeeded();
  }

  @override
  void didUpdateWidget(DocumentImageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.name != widget.name ||
        oldWidget.fileUuid != widget.fileUuid) {
      _avatarColor = _pickStableProfileAvatarColor(
        widget.name?.trim().isNotEmpty == true
            ? widget.name!.trim()
            : widget.fileUuid,
      );
    }

    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.mediaAssetCode != widget.mediaAssetCode ||
        oldWidget.studentCode != widget.studentCode ||
        oldWidget.staffCode != widget.staffCode ||
        oldWidget.classroomCode != widget.classroomCode) {
      _resolvedImageUrl = _seedImageUrl();
      _resolveProfilePhotoIfNeeded();
    }

    if (oldWidget.staffCode != widget.staffCode ||
        oldWidget.staffEmploymentStatus != widget.staffEmploymentStatus ||
        oldWidget.studentEnrollmentStatus != widget.studentEnrollmentStatus ||
        oldWidget.studentCode != widget.studentCode) {
      _loadAttendanceStatusIfNeeded();
    }
  }

  String? _seedImageUrl() {
    final explicit = widget.imageUrl?.trim() ?? '';
    if (explicit.isNotEmpty) return explicit;
    final mediaAssetCode = widget.mediaAssetCode?.trim() ?? '';
    if (mediaAssetCode.isNotEmpty) {
      final key = 'asset:$mediaAssetCode';
      final cached = _cachedUrlIfFresh(key);
      if (cached != null && cached.isNotEmpty) return cached;
    }
    final classroomCode = widget.classroomCode?.trim() ?? '';
    if (classroomCode.isNotEmpty) {
      final key = 'classroom:$classroomCode';
      final cached = _cachedUrlIfFresh(key);
      if (cached != null && cached.isNotEmpty) return cached;
    }
    final studentCode = widget.studentCode?.trim() ?? '';
    if (studentCode.isNotEmpty) {
      final key = 'student:$studentCode';
      final cached = _cachedUrlIfFresh(key);
      if (cached != null && cached.isNotEmpty) return cached;
    }
    final staffCode = widget.staffCode?.trim() ?? '';
    if (staffCode.isNotEmpty) {
      final key = 'staff:$staffCode';
      final cached = _cachedUrlIfFresh(key);
      if (cached != null && cached.isNotEmpty) return cached;
    }
    return null;
  }

  String? _cachedUrlIfFresh(String key) {
    final cached = _profilePhotoUrlCache[key];
    final fetchedAt = _profilePhotoFetchedAt[key];
    if (cached == null || fetchedAt == null) return null;
    if (DateTime.now().difference(fetchedAt) >
        DocumentImageWidget._profilePhotoCacheTtl) {
      _profilePhotoUrlCache.remove(key);
      _profilePhotoFetchedAt.remove(key);
      return null;
    }
    return cached;
  }

  Future<void> _resolveProfilePhotoIfNeeded() async {
    if ((widget.imageUrl ?? '').trim().isNotEmpty) return;

    final studentCode = widget.studentCode?.trim() ?? '';
    final staffCode = widget.staffCode?.trim() ?? '';
    final mediaAssetCode = widget.mediaAssetCode?.trim() ?? '';
    final classroomCode = widget.classroomCode?.trim() ?? '';
    if (studentCode.isEmpty &&
        staffCode.isEmpty &&
        mediaAssetCode.isEmpty &&
        classroomCode.isEmpty) {
      return;
    }

    // [disableProfileLookupFallback] only gates the student/staff profile
    // fallback. A classroom logo is a deliberate lookup, so it must proceed.
    if (widget.disableProfileLookupFallback &&
        mediaAssetCode.isEmpty &&
        classroomCode.isEmpty) {
      return;
    }

    final cacheKey = mediaAssetCode.isNotEmpty
        ? 'asset:$mediaAssetCode'
        : classroomCode.isNotEmpty
        ? 'classroom:$classroomCode'
        : (studentCode.isNotEmpty
              ? 'student:$studentCode'
              : 'staff:$staffCode');
    final cached = _cachedUrlIfFresh(cacheKey);
    if (cached != null && cached.isNotEmpty) {
      if (!mounted) return;
      setState(() => _resolvedImageUrl = cached);
      return;
    }

    final inFlight = _profilePhotoInFlight[cacheKey];
    if (inFlight != null) {
      final resolved = await inFlight;
      if (!mounted) return;
      if ((resolved ?? '').trim().isNotEmpty) {
        setState(() => _resolvedImageUrl = resolved!.trim());
      }
      return;
    }

    final future = _fetchProfilePhotoUrl(
      studentCode: studentCode,
      staffCode: staffCode,
      mediaAssetCode: mediaAssetCode,
      classroomCode: classroomCode,
    );
    _profilePhotoInFlight[cacheKey] = future;
    try {
      final resolved = await future;
      if ((resolved ?? '').trim().isNotEmpty) {
        _profilePhotoUrlCache[cacheKey] = resolved!.trim();
        _profilePhotoFetchedAt[cacheKey] = DateTime.now();
      }
      if (!mounted) return;
      if ((resolved ?? '').trim().isNotEmpty) {
        setState(() => _resolvedImageUrl = resolved!.trim());
      }
    } catch (_) {
      // Photo resolution failed (e.g. network / 404). Keep the initials
      // fallback instead of letting the error propagate unhandled.
    } finally {
      _profilePhotoInFlight.remove(cacheKey);
    }
  }

  Future<String?> _fetchProfilePhotoUrl({
    required String studentCode,
    required String staffCode,
    required String mediaAssetCode,
    required String classroomCode,
  }) async {
    final apiClient = serviceLocator<ApiClient>();
    if (mediaAssetCode.isNotEmpty) {
      // Try document service first (when caller provides an asset code),
      // but fall back to profile endpoints if the document lookup fails.
      final documentUrl = await _fetchDocumentAssetUrl(mediaAssetCode);
      if (documentUrl.isNotEmpty) return documentUrl;
    }
    if (classroomCode.isNotEmpty) {
      final schoolCode = await _currentSchoolCode();
      final assetCode = await _fetchClassroomLogoAssetCode(
        classroomCode: classroomCode,
        schoolCode: schoolCode,
      );
      if (assetCode.isEmpty) return null;
      final documentUrl = await _fetchDocumentAssetUrl(assetCode);
      return documentUrl.isEmpty ? null : documentUrl;
    }
    if (studentCode.isNotEmpty) {
      String? directUrl;
      String assetCode = '';
      String schoolCode = '';
      // The student profile endpoint may 404; don't throw uncaught — fall back
      // to the asset-code lookup below.
      try {
        final endpoint = ApiPaths.urlWithBase(
          ApiPaths.studentProfile(studentCode),
          ApiConstants.studentBaseUrl,
        );
        final response = await apiClient.client.get<dynamic>(endpoint);
        final data = _extractDataMap(response.data);
        directUrl = _extractPhotoUrl(data);
        assetCode = _extractAssetCode(data);
        schoolCode = (data?['schoolCode'] ?? '').toString().trim();
      } catch (_) {
        // Ignore and try the asset-code lookup.
      }
      if ((directUrl ?? '').trim().isNotEmpty) return directUrl;
      if (assetCode.isEmpty) {
        if (schoolCode.isEmpty) schoolCode = await _currentSchoolCode();
        assetCode = await _fetchStudentProfilePhotoAssetCode(
          studentCode: studentCode,
          schoolCode: schoolCode,
        );
      }
      if (assetCode.isEmpty) return null;
      final documentUrl = await _fetchDocumentAssetUrl(assetCode);
      return documentUrl.isEmpty ? null : documentUrl;
    }
    if (staffCode.isNotEmpty) {
      String? directUrl;
      String assetCode = '';
      String schoolCode = '';
      // The staff profile-by-code endpoint may 404 (e.g. local backends). Don't
      // let that throw uncaught — fall back to the asset-code lookup below, the
      // same way daily/custom views resolve the photo.
      try {
        final endpoint = ApiPaths.urlWithBase(
          ApiPaths.staffProfileByCodePath(staffCode),
          ApiConstants.staffBaseUrl,
        );
        final response = await apiClient.client.get<dynamic>(endpoint);
        final data = _extractDataMap(response.data);
        directUrl = _extractPhotoUrl(data);
        assetCode = _extractAssetCode(data);
        schoolCode = (data?['schoolCode'] ?? '').toString().trim();
      } catch (_) {
        // Ignore and try the asset-code lookup.
      }
      if ((directUrl ?? '').trim().isNotEmpty) return directUrl;
      if (assetCode.isEmpty) {
        if (schoolCode.isEmpty) schoolCode = await _currentSchoolCode();
        assetCode = await _fetchStaffProfilePhotoAssetCode(
          staffCode: staffCode,
          schoolCode: schoolCode,
        );
      }
      if (assetCode.isEmpty) return null;
      final documentUrl = await _fetchDocumentAssetUrl(assetCode);
      return documentUrl.isEmpty ? null : documentUrl;
    }
    return null;
  }

  Map<String, dynamic>? _extractDataMap(dynamic body) {
    if (body is! Map) return null;
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  String? _extractPhotoUrl(Map<String, dynamic>? data) {
    if (data == null) return null;
    final candidates = <dynamic>[
      data['profilePhotoUrl'],
      data['photoUrl'],
      data['profileImageUrl'],
      data['imageUrl'],
      data['url'],
    ];
    for (final raw in candidates) {
      final value = (raw ?? '').toString().trim();
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  String _extractAssetCode(Map<String, dynamic>? data) {
    if (data == null) return '';
    final candidates = <dynamic>[
      data['profilePhotoAssetCode'],
      data['photoAssetCode'],
      data['assetCode'],
    ];
    for (final raw in candidates) {
      final value = (raw ?? '').toString().trim();
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  Future<String> _fetchStaffProfilePhotoAssetCode({
    required String staffCode,
    required String schoolCode,
  }) async {
    final normalizedStaff = staffCode.trim();
    final normalizedSchool = schoolCode.trim();
    if (normalizedStaff.isEmpty || normalizedSchool.isEmpty) return '';
    try {
      final apiClient = serviceLocator<ApiClient>();
      final endpoint = ApiPaths.urlWithBase(
        ApiPaths.staffProfilePhotoAssetCodes,
        ApiConstants.staffBaseUrl,
      );
      final response = await apiClient.client.get<dynamic>(
        endpoint,
        queryParameters: <String, dynamic>{
          'schoolCode': normalizedSchool,
          'staffCode': normalizedStaff,
        },
      );
      final body = response.data;
      if (body is! Map) return '';
      final data = body['data'];
      if (data is! List) return '';
      final match = data.whereType<Map>().firstWhere(
        (row) =>
            (row['staffCode'] ?? '').toString().trim().toUpperCase() ==
            normalizedStaff.toUpperCase(),
        orElse: () => <String, dynamic>{},
      );
      return (match['profilePhotoAssetCode'] ?? match['assetCode'] ?? '')
          .toString()
          .trim();
    } catch (_) {
      return '';
    }
  }

  Future<String> _fetchStudentProfilePhotoAssetCode({
    required String studentCode,
    required String schoolCode,
  }) async {
    final normalizedStudent = studentCode.trim();
    final normalizedSchool = schoolCode.trim();
    if (normalizedStudent.isEmpty || normalizedSchool.isEmpty) return '';
    try {
      final apiClient = serviceLocator<ApiClient>();
      final endpoint = ApiPaths.urlWithBase(
        ApiPaths.studentProfilePhotoAssetCodes,
        ApiConstants.studentBaseUrl,
      );
      final response = await apiClient.client.get<dynamic>(
        endpoint,
        queryParameters: <String, dynamic>{
          'schoolCode': normalizedSchool,
          'studentCode': normalizedStudent,
        },
      );
      final body = response.data;
      if (body is! Map) return '';
      final data = body['data'];
      if (data is! List) return '';
      final match = data.whereType<Map>().firstWhere(
        (row) =>
            (row['studentCode'] ?? '').toString().trim().toUpperCase() ==
            normalizedStudent.toUpperCase(),
        orElse: () => <String, dynamic>{},
      );
      return (match['assetCode'] ?? '').toString().trim();
    } catch (_) {
      return '';
    }
  }

  Future<String> _currentSchoolCode() async {
    try {
      final storage = serviceLocator<StorageService>();
      return (await storage.getString(StorageKeys.schoolCode) ?? '').trim();
    } catch (_) {
      return '';
    }
  }

  /// Resolves the classroom's logo asset code from
  /// `GET /classroom/classroom-logo/asset-codes?classroomCode=&schoolCode=`,
  /// matching the row whose `classroomCode` equals the requested one.
  Future<String> _fetchClassroomLogoAssetCode({
    required String classroomCode,
    required String schoolCode,
  }) async {
    final normalizedClassroom = classroomCode.trim();
    final normalizedSchool = schoolCode.trim();
    if (normalizedClassroom.isEmpty || normalizedSchool.isEmpty) return '';
    try {
      final apiClient = serviceLocator<ApiClient>();
      final endpoint = ApiPaths.url(ApiPaths.classroomLogoAssetCodes);
      final response = await apiClient.client.get<dynamic>(
        endpoint,
        queryParameters: <String, dynamic>{
          'classroomCode': normalizedClassroom,
          'schoolCode': normalizedSchool,
        },
      );
      final body = response.data;
      if (body is! Map) return '';
      final data = body['data'];
      if (data is! List) return '';
      final match = data.whereType<Map>().firstWhere(
        (row) =>
            (row['classroomCode'] ?? '').toString().trim().toUpperCase() ==
            normalizedClassroom.toUpperCase(),
        orElse: () => <String, dynamic>{},
      );
      return (match['logoAssetCode'] ?? match['assetCode'] ?? '')
          .toString()
          .trim();
    } catch (_) {
      return '';
    }
  }

  Future<String> _fetchDocumentAssetUrl(String assetCode) async {
    final normalizedAssetCode = assetCode.trim();
    if (normalizedAssetCode.isEmpty) return '';
    // Delegates to ImageUploadService's cached/deduped/cooldown-protected
    // resolver instead of calling the endpoint directly, so a 500/expired
    // asset doesn't trigger a fresh network call on every rebuild of this
    // widget and is logged exactly once per failure window.
    return serviceLocator<ImageUploadService>().getMediaAssetUrlByCode(
      assetCode: normalizedAssetCode,
    );
  }

  Future<void> _loadAttendanceStatusIfNeeded() async {
    // Employment / enrollment "upcoming" must apply even when attendance API
    // lookups are disabled (e.g. classroom roster rows pass today's status via
    // [statusColor] and set [disableAttendanceStatusLookup] to avoid N+1 calls).
    final employment = widget.staffEmploymentStatus?.trim().toUpperCase() ?? '';
    if (employment == 'UPCOMING') {
      if (!mounted) return;
      setState(() {
        _statusDotColor = AppColors.mustardProgressBar;
        _statusLabel = 'Upcoming';
      });
      return;
    }

    final enrollment =
        widget.studentEnrollmentStatus?.trim().toUpperCase() ?? '';
    if (enrollment == 'UPCOMING') {
      if (!mounted) return;
      setState(() {
        _statusDotColor = AppColors.mustardProgressBar;
        _statusLabel = 'Upcoming';
      });
      return;
    }

    if (widget.disableAttendanceStatusLookup) {
      if (!mounted) return;
      setState(() {
        _statusDotColor = null;
        _statusLabel = null;
      });
      return;
    }

    // Only one of staffCode / studentCode is expected; if both null, do nothing.
    final staffCode = widget.staffCode;
    final studentCode = widget.studentCode;
    if ((staffCode == null || staffCode.isEmpty) &&
        (studentCode == null || studentCode.isEmpty)) {
      setState(() {
        _statusDotColor = null;
        _statusLabel = null;
      });
      return;
    }

    if (_isLoadingStatus) return;
    _isLoadingStatus = true;

    try {
      String? status;
      if (staffCode != null && staffCode.isNotEmpty) {
        status = await _batchStaffStatus(staffCode);
      } else if (studentCode != null && studentCode.isNotEmpty) {
        status = await _batchStudentStatus(studentCode);
      }

      if (!mounted) return;

      // Normalize status to upper-case for comparison.
      final normalized = status?.toUpperCase();
      Color? color;
      String? label;
      if (normalized == 'SIGNED_IN') {
        if (widget.showOnlyAbsentAttendanceDot) {
          color = null;
          label = null;
        } else {
          color = Colors.green;
          label = 'Signed in';
        }
      } else if (normalized == 'ABSENT') {
        color = Colors.red;
        label = 'Absent';
      } else {
        color = null;
        label = null;
      }

      setState(() {
        // For staff/student codes we rely only on API status.
        // If API doesn't return a recognized status, hide the dot.
        _statusDotColor = color;
        _statusLabel = label;
      });
    } catch (_) {
      if (!mounted) return;
      // On error, hide the API-driven status dot so we don't show stale data.
      setState(() {
        _statusDotColor = null;
        _statusLabel = null;
      });
    } finally {
      _isLoadingStatus = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrlToShow = (_resolvedImageUrl ?? widget.imageUrl ?? '').trim();
    final hasImageUrl = imageUrlToShow.isNotEmpty;
    return GestureDetector(
      onTap: widget.onTap,
      child: hasImageUrl
          ? _buildAvatarWithStatus(_buildNetworkAvatar(imageUrlToShow))
          : (widget.name != null && widget.name!.isNotEmpty)
          ? _buildAvatarWithStatus(_buildInitialsAvatar())
          : _buildAvatarWithStatus(_buildPlaceholder()),
    );
  }

  Widget _buildImageContainer({required Widget child}) {
    if (widget.shape == BoxShape.circle) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.size / 2),
          child: child,
        ),
      );
    } else {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: ClipRRect(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
          child: child,
        ),
      );
    }
  }

  Widget _buildAvatarWithStatus(Widget avatar) {
    final dotColor = _statusDotColor ?? widget.statusColor;
    if (dotColor == null) return avatar;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: 2,
          top: 2,
          child: Tooltip(
            message: _statusTooltipMessage(),
            waitDuration: const Duration(milliseconds: 100),
            showDuration: const Duration(seconds: 2),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w600,
            ),
            child: Container(
              width: widget.size * 0.27,
              height: widget.size * 0.27,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _statusTooltipMessage() {
    if (_statusLabel != null) {
      if (_statusLabel == 'Upcoming' &&
          widget.staffCode != null &&
          widget.staffCode!.isNotEmpty) {
        return 'Upcoming staff';
      }
      if (_statusLabel == 'Upcoming' &&
          widget.studentCode != null &&
          widget.studentCode!.isNotEmpty) {
        return 'Upcoming student';
      }
      // Prefix with "Staff"/"Student" when we know which one it is.
      if (widget.staffCode != null && widget.staffCode!.isNotEmpty) {
        return 'Staff is ${_statusLabel!.toLowerCase()}';
      }
      if (widget.studentCode != null && widget.studentCode!.isNotEmpty) {
        return 'Student is ${_statusLabel!.toLowerCase()}';
      }
      return _statusLabel!;
    }
    final manual = widget.statusTooltip?.trim();
    if (manual != null && manual.isNotEmpty) {
      return manual;
    }
    return 'Status';
  }

  Widget _buildInitialsAvatar() {
    return CircleAvatar(
      backgroundColor:
          _avatarColor ??
          _pickStableProfileAvatarColor(
            widget.name?.trim().isNotEmpty == true
                ? widget.name!.trim()
                : widget.fileUuid,
          ),
      radius: widget.size / 2,
      child: Text(
        StringUtils.getInitials(widget.name!),
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: widget.fontSize,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    final placeholder =
        widget.errorWidget ??
        (widget.placeholderAsset != null
            ? Image.asset(
                widget.placeholderAsset!,
                width: widget.size,
                height: widget.size,
                fit: widget.fit,
              )
            : CircleAvatar(
                radius: widget.size / 2,
                backgroundImage: const AssetImage(MediaRes.userImageMale),
              ));

    // Fixed: Improved null safety checks
    if (widget.name == null ||
        widget.name!.isEmpty ||
        widget.fileUuid.isNotEmpty) {
      return _buildImageContainer(child: placeholder);
    } else {
      return CircleAvatar(
        backgroundColor:
            _avatarColor ??
            _pickStableProfileAvatarColor(
              widget.name?.trim().isNotEmpty == true
                  ? widget.name!.trim()
                  : widget.fileUuid,
            ),
        radius: widget.size / 2,
        child: Text(
          StringUtils.getInitials(widget.name!),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: widget.fontSize,
            color: Colors.white,
          ),
        ),
      );
    }
  }

  Widget _buildNetworkAvatar(String imageUrl) {
    final image = Image.network(
      imageUrl,
      width: widget.size,
      height: widget.size,
      fit: widget.fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildShimmer();
      },
      errorBuilder: (context, error, stackTrace) {
        if (widget.name != null && widget.name!.trim().isNotEmpty) {
          return _buildInitialsAvatar();
        }
        return _buildPlaceholder();
      },
    );
    return _buildImageContainer(child: image);
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          shape: widget.shape,
          borderRadius: widget.shape == BoxShape.rectangle
              ? (widget.borderRadius ?? BorderRadius.circular(8))
              : null,
        ),
      ),
    );
  }
}

Color _pickStableProfileAvatarColor(String seed) {
  if (AppColors.profileAvatarColors.isEmpty) return AppColors.primaryColor;
  if (seed.isEmpty) seed = 'default';
  final int index = seed.hashCode.abs() % AppColors.profileAvatarColors.length;
  return AppColors.profileAvatarColors[index];
}
