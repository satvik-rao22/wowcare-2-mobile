import 'package:flutter/material.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/api_constants.dart';
import 'package:wowcare/core/utils/api_paths.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/core/utils/string_utils.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_today_sign_in_status_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_today_sign_in_status_usecase.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';

class DocumentImageWidget extends StatefulWidget {
  static const Duration _profilePhotoCacheTtl = Duration(minutes: 10);
  final String fileUuid;
  final String? imageUrl;
  final String? mediaAssetCode;
  final String? name;

  /// Optional staff code for attendance status dot.
  final String? staffCode;

  /// Account code (`USR_*`) of the person this avatar belongs to.
  ///
  /// Messaging surfaces only ever know their counterpart by this code — the
  /// conversation participant payload carries no `staffCode` and, for most
  /// staff, no photo field either — so without this the whole staff-messaging
  /// inbox fell back to initials. Mapped to a `staffCode` once per account
  /// (cached for the session) and then resolved exactly like [staffCode].
  /// Only consulted when no [imageUrl]/[mediaAssetCode]/[studentCode]/
  /// [classroomCode]/[staffCode] is given.
  final String? userCode;

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
    this.userCode,
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

  /// Bumped whenever an attendance mutation (sign-in/out, edit, delete,
  /// transfer, mark absent) succeeds, so every currently-mounted status dot
  /// re-fetches instead of showing what it fetched before the mutation.
  static final ValueNotifier<int> _attendanceStatusRefreshTick =
      ValueNotifier<int>(0);

  /// Call after any attendance-mutating action succeeds to refresh every
  /// visible status dot (avoids each list screen needing its own plumbing).
  static void refreshAttendanceStatusDots() {
    _attendanceStatusRefreshTick.value++;
  }

  /// Bumped whenever a profile photo is updated so every currently-mounted
  /// avatar re-resolves its image. Clearing the URL cache alone is not enough:
  /// avatars already on screen keep the URL they resolved earlier and only
  /// re-fetch on rebuild — which is why a new photo used to appear only after
  /// re-navigating or restarting the app.
  static final ValueNotifier<int> _profilePhotoRefreshTick = ValueNotifier<int>(
    0,
  );

  static void _removeProfilePhotoKey(String key) {
    _DocumentImageWidgetState._profilePhotoUrlCache.remove(key);
    _DocumentImageWidgetState._profilePhotoFetchedAt.remove(key);
    _DocumentImageWidgetState._profilePhotoInFlight.remove(key);
  }

  /// Drops the cached photo URL for the given owner (or everyone when no code
  /// is passed) AND notifies every mounted avatar to re-resolve, so a
  /// just-updated photo shows immediately across the whole app.
  static void clearProfilePhotoCache({
    String? studentCode,
    String? staffCode,
    String? classroomCode,
  }) {
    final student = (studentCode ?? '').trim();
    final staff = (staffCode ?? '').trim();
    final classroom = (classroomCode ?? '').trim();
    if (student.isEmpty && staff.isEmpty && classroom.isEmpty) {
      _DocumentImageWidgetState._profilePhotoUrlCache.clear();
      _DocumentImageWidgetState._profilePhotoFetchedAt.clear();
      _DocumentImageWidgetState._profilePhotoInFlight.clear();
    } else {
      if (student.isNotEmpty) _removeProfilePhotoKey('student:$student');
      if (staff.isNotEmpty) _removeProfilePhotoKey('staff:$staff');
      if (classroom.isNotEmpty) _removeProfilePhotoKey('classroom:$classroom');
    }
    // Wake every mounted avatar so the change is visible immediately.
    _profilePhotoRefreshTick.value++;
  }

  /// Marks the given owner's photo as DELETED and drops every trace of it.
  ///
  /// [clearProfilePhotoCache] alone is not enough after a delete. It evicts the
  /// cache and wakes every mounted avatar, but the re-resolution that follows
  /// comes back EMPTY — and [_resolveProfilePhotoIfNeeded] only ever assigns
  /// `_resolvedImageUrl` on a non-empty result, so each avatar quietly keeps
  /// the URL it resolved before the delete. The photo would stay on screen
  /// until the app restarted.
  ///
  /// The tombstone recorded here is what lets that resolution distinguish
  /// "came back empty because it was deleted" (clear the avatar) from "came
  /// back empty because the lookup failed or raced" (keep what we have, which
  /// is the behaviour every other caller depends on). It is deliberately
  /// short-lived: once the backend is consistently reporting no photo, an
  /// empty result is no longer surprising, and a stale tombstone would
  /// suppress a photo the user re-uploads later.
  static void forgetProfilePhoto({String? studentCode, String? staffCode}) {
    final student = (studentCode ?? '').trim();
    final staff = (staffCode ?? '').trim();

    void forget(String key) {
      // Evict the dead URL from Flutter's decoded-image cache before dropping
      // it, or the bitmap keeps painting even once the URL 404s. Mirrors the
      // eviction [primeProfilePhotoUrl] does for the opposite reason.
      final cached = _DocumentImageWidgetState._profilePhotoUrlCache[key];
      if (cached != null && cached.trim().isNotEmpty) {
        try {
          PaintingBinding.instance.imageCache.evict(NetworkImage(cached.trim()));
        } catch (_) {}
      }
      _removeProfilePhotoKey(key);
      _DocumentImageWidgetState._profilePhotoDeletedAt[key] = AppTime.nowUtc();
    }

    if (student.isNotEmpty) forget('student:$student');
    if (staff.isNotEmpty) forget('staff:$staff');

    // Wake every mounted avatar so the deletion is visible immediately.
    _profilePhotoRefreshTick.value++;
  }

  /// Seeds the freshly-resolved [url] into the cache for the given owner and
  /// wakes every mounted avatar, so a just-uploaded photo/logo shows
  /// immediately WITHOUT each avatar re-hitting the (eventually-consistent)
  /// resolve endpoint — which could otherwise re-cache the old image. Falls
  /// back to a plain cache-clear when [url] is empty.
  static void primeProfilePhotoUrl({
    String? studentCode,
    String? staffCode,
    String? classroomCode,
    required String url,
  }) {
    final u = url.trim();
    if (u.isEmpty) {
      clearProfilePhotoCache(
        studentCode: studentCode,
        staffCode: staffCode,
        classroomCode: classroomCode,
      );
      return;
    }
    void prime(String key) {
      _DocumentImageWidgetState._profilePhotoUrlCache[key] = u;
      _DocumentImageWidgetState._profilePhotoFetchedAt[key] = AppTime.nowUtc();
      _DocumentImageWidgetState._profilePhotoInFlight.remove(key);
    }

    final student = (studentCode ?? '').trim();
    final staff = (staffCode ?? '').trim();
    final classroom = (classroomCode ?? '').trim();
    if (student.isNotEmpty) prime('student:$student');
    if (staff.isNotEmpty) prime('staff:$staff');
    if (classroom.isNotEmpty) prime('classroom:$classroom');

    // Evict any previously-cached load of this URL from Flutter's image cache.
    // Right after an upload the CDN can briefly 4xx the object; Flutter caches
    // that failed load and never retries, so the avatar would keep showing the
    // fallback even once the image is live. Evicting forces Image.network to
    // re-fetch it fresh on the next paint (triggered by the tick below).
    try {
      PaintingBinding.instance.imageCache.evict(NetworkImage(u));
    } catch (_) {}

    _profilePhotoRefreshTick.value++;

    // The CDN can still be propagating the freshly-processed image for a second
    // or two after finalize. Retry the evict + refresh once shortly after so the
    // avatar appears on its own if the first paint raced ahead of availability.
    Future.delayed(const Duration(milliseconds: 1500), () {
      try {
        PaintingBinding.instance.imageCache.evict(NetworkImage(u));
      } catch (_) {}
      _profilePhotoRefreshTick.value++;
    });
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

  /// Owners whose photo was just deleted, and when. See
  /// [DocumentImageWidget.forgetProfilePhoto] for why an empty resolve needs
  /// this to be actionable. Entries expire after [_deletedTombstoneTtl].
  static final Map<String, DateTime> _profilePhotoDeletedAt =
      <String, DateTime>{};

  /// Long enough to outlast the backend's eventual consistency right after a
  /// delete, short enough that it cannot suppress a later re-upload.
  static const Duration _deletedTombstoneTtl = Duration(minutes: 2);

  /// True while [key]'s photo is known to have been deleted recently, so an
  /// empty resolve should CLEAR the avatar rather than leave the old image up.
  static bool _wasRecentlyDeleted(String key) {
    final deletedAt = _profilePhotoDeletedAt[key];
    if (deletedAt == null) return false;
    if (AppTime.nowUtc().difference(deletedAt) > _deletedTombstoneTtl) {
      _profilePhotoDeletedAt.remove(key);
      return false;
    }
    return true;
  }

  /// `USR_*` → `STF_*` for avatars that only know the account code (see
  /// [DocumentImageWidget.userCode]). Session-scoped and never invalidated:
  /// the mapping itself doesn't change while the user stays signed into the
  /// same org/school, unlike the photo URL it leads to (which keeps its own
  /// TTL'd entry under the resolved `staff:` key). Empty values are cached
  /// too, so a non-staff account isn't re-queried on every list rebuild.
  static final Map<String, String> _staffCodeByUserCode = <String, String>{};
  static final Map<String, Future<String>> _staffCodeByUserCodeInFlight =
      <String, Future<String>>{};

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
    DocumentImageWidget._attendanceStatusRefreshTick.addListener(
      _onAttendanceStatusRefreshTick,
    );
    DocumentImageWidget._profilePhotoRefreshTick.addListener(
      _onProfilePhotoRefreshTick,
    );
  }

  @override
  void dispose() {
    DocumentImageWidget._attendanceStatusRefreshTick.removeListener(
      _onAttendanceStatusRefreshTick,
    );
    DocumentImageWidget._profilePhotoRefreshTick.removeListener(
      _onProfilePhotoRefreshTick,
    );
    super.dispose();
  }

  void _onAttendanceStatusRefreshTick() {
    if (!mounted) return;
    _loadAttendanceStatusIfNeeded();
  }

  void _onProfilePhotoRefreshTick() {
    if (!mounted) return;
    // The URL cache for this avatar's owner may have just been cleared. Re-run
    // resolution: cleared keys re-fetch the new photo (and setState to it),
    // while still-cached ones return unchanged — so the new image appears
    // immediately without a flash of the initials fallback.
    _resolveProfilePhotoIfNeeded();
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
        oldWidget.userCode != widget.userCode ||
        oldWidget.classroomCode != widget.classroomCode) {
      // A parent rebuild (e.g. a BlocConsumer firing on pull-to-refresh, or
      // this element getting reused at the same list position for a
      // different item — e.g. a ListView.builder row after a pagination
      // merge) can recompute these props. `_seedImageUrl()` returns null
      // unless a fresh cache entry already exists for whatever owner is
      // now being asked for, so unconditionally overwriting
      // `_resolvedImageUrl` with it flashed the avatar back to its
      // unresolved placeholder on every such rebuild, self-correcting only
      // once the (often redundant) async re-resolution completed a moment
      // later. Only skip that reset when the owner identity is actually
      // unchanged — if this element got reused for a genuinely different
      // person/asset, we must still clear immediately, or it would show
      // the PREVIOUS owner's photo/initials on the new one instead of
      // just a brief placeholder.
      final sameOwner =
          _ownerIdentityKey(oldWidget) == _ownerIdentityKey(widget);
      final newSeed = _seedImageUrl();
      if (newSeed != null && newSeed.isNotEmpty) {
        _resolvedImageUrl = newSeed;
      } else if (!sameOwner) {
        _resolvedImageUrl = null;
      }
      _resolveProfilePhotoIfNeeded();
    }

    if (oldWidget.staffCode != widget.staffCode ||
        oldWidget.staffEmploymentStatus != widget.staffEmploymentStatus ||
        oldWidget.studentEnrollmentStatus != widget.studentEnrollmentStatus ||
        oldWidget.studentCode != widget.studentCode) {
      _loadAttendanceStatusIfNeeded();
    }
  }

  /// Identifies WHO this widget is currently showing a photo for — same
  /// precedence as [_seedImageUrl]'s lookup order. Used by
  /// [didUpdateWidget] to tell "still the same person, just a redundant
  /// prop recompute" apart from "this element got reused for someone
  /// else", since only the latter must clear a stale resolved photo
  /// immediately rather than preserve it.
  String _ownerIdentityKey(DocumentImageWidget w) {
    final explicit = w.imageUrl?.trim() ?? '';
    if (explicit.isNotEmpty) return 'url:$explicit';
    final mediaAssetCode = w.mediaAssetCode?.trim() ?? '';
    if (mediaAssetCode.isNotEmpty) return 'asset:$mediaAssetCode';
    final classroomCode = w.classroomCode?.trim() ?? '';
    if (classroomCode.isNotEmpty) return 'classroom:$classroomCode';
    final studentCode = w.studentCode?.trim() ?? '';
    if (studentCode.isNotEmpty) return 'student:$studentCode';
    final staffCode = w.staffCode?.trim() ?? '';
    if (staffCode.isNotEmpty) return 'staff:$staffCode';
    final userCode = w.userCode?.trim() ?? '';
    if (userCode.isNotEmpty) return 'user:$userCode';
    return '';
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
    // An account code whose staff mapping was already resolved earlier this
    // session seeds from that staff member's own cache entry — so scrolling
    // the messaging inbox back over a row repaints its photo immediately
    // instead of flashing the initials while the async lookup re-runs.
    final userCode = widget.userCode?.trim() ?? '';
    if (userCode.isNotEmpty) {
      final mappedStaffCode = _staffCodeByUserCode[userCode] ?? '';
      if (mappedStaffCode.isNotEmpty) {
        final cached = _cachedUrlIfFresh('staff:$mappedStaffCode');
        if (cached != null && cached.isNotEmpty) return cached;
      }
    }
    return null;
  }

  String? _cachedUrlIfFresh(String key) {
    final cached = _profilePhotoUrlCache[key];
    final fetchedAt = _profilePhotoFetchedAt[key];
    if (cached == null || fetchedAt == null) return null;
    if (AppTime.nowUtc().difference(fetchedAt) >
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
    var staffCode = widget.staffCode?.trim() ?? '';
    final userCode = widget.userCode?.trim() ?? '';
    final mediaAssetCode = widget.mediaAssetCode?.trim() ?? '';
    final classroomCode = widget.classroomCode?.trim() ?? '';
    if (studentCode.isEmpty &&
        staffCode.isEmpty &&
        userCode.isEmpty &&
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

    // Account code only (a messaging participant): map it to the staff code
    // BEFORE picking a cache key, so the resolved photo is stored under the
    // same `staff:<code>` entry every other avatar of this person uses —
    // which also keeps [clearProfilePhotoCache]/[primeProfilePhotoUrl]
    // working after that staff member updates their photo.
    if (staffCode.isEmpty &&
        userCode.isNotEmpty &&
        studentCode.isEmpty &&
        mediaAssetCode.isEmpty &&
        classroomCode.isEmpty) {
      staffCode = await _resolveStaffCodeForUserCode(userCode);
      if (!mounted || staffCode.isEmpty) return;
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
      } else if (_wasRecentlyDeleted(cacheKey)) {
        setState(() => _resolvedImageUrl = null);
      }
      return;
    }

    final future = _fetchProfilePhotoUrl(
      studentCode: studentCode,
      staffCode: staffCode,
      userCode: userCode,
      mediaAssetCode: mediaAssetCode,
      classroomCode: classroomCode,
    );
    _profilePhotoInFlight[cacheKey] = future;
    try {
      final resolved = await future;
      if ((resolved ?? '').trim().isNotEmpty) {
        _profilePhotoUrlCache[cacheKey] = resolved!.trim();
        _profilePhotoFetchedAt[cacheKey] = AppTime.nowUtc();
      }
      if (!mounted) return;
      if ((resolved ?? '').trim().isNotEmpty) {
        setState(() => _resolvedImageUrl = resolved!.trim());
      } else if (_wasRecentlyDeleted(cacheKey)) {
        // Deleted, and the backend agrees. Drop the image we were showing —
        // without this the avatar keeps the pre-delete photo until restart.
        setState(() => _resolvedImageUrl = null);
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
    required String userCode,
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
    // An avatar given only an account code (or one whose media-asset lookup
    // above came up empty) resolves the staff code first, then follows the
    // ordinary staff-photo path below.
    var resolvedStaffCode = staffCode;
    if (resolvedStaffCode.isEmpty && userCode.isNotEmpty) {
      resolvedStaffCode = await _resolveStaffCodeForUserCode(userCode);
    }
    if (resolvedStaffCode.isNotEmpty) {
      String? directUrl;
      String assetCode = '';
      String schoolCode = '';
      // The staff profile-by-code endpoint may 404 (e.g. local backends). Don't
      // let that throw uncaught — fall back to the asset-code lookup below, the
      // same way daily/custom views resolve the photo.
      try {
        final endpoint = ApiPaths.urlWithBase(
          ApiPaths.staffProfileByCodePath(resolvedStaffCode),
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
          staffCode: resolvedStaffCode,
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

  Future<String> _currentOrganizationCode() async {
    try {
      final storage = serviceLocator<StorageService>();
      return (await storage.getString(StorageKeys.organizationCode) ?? '')
          .trim();
    } catch (_) {
      return '';
    }
  }

  /// `USR_*` → `STF_*`, memoised per account for the session and de-duped
  /// across the many avatars that ask for the same person at once (a
  /// conversation list renders one row per counterpart). Returns '' when the
  /// account has no staff mapping (e.g. a guardian) — cached too, so such an
  /// account isn't re-queried on every rebuild.
  Future<String> _resolveStaffCodeForUserCode(String userCode) async {
    final cached = _staffCodeByUserCode[userCode];
    if (cached != null) return cached;

    final inFlight = _staffCodeByUserCodeInFlight[userCode];
    if (inFlight != null) return inFlight;

    final future = _fetchStaffCodeForUserCode(userCode);
    _staffCodeByUserCodeInFlight[userCode] = future;
    try {
      final resolved = await future;
      _staffCodeByUserCode[userCode] = resolved;
      return resolved;
    } catch (_) {
      return '';
    } finally {
      _staffCodeByUserCodeInFlight.remove(userCode);
    }
  }

  /// Hits the same `/api/v1/staff/code` mapping the logged-in user's own
  /// staff code is resolved with ([resolveStaffCodeForLoggedInUser]), for an
  /// arbitrary account. Org admins are mapped org-level, where the backend
  /// expects `'-'` and 404s on a real school code, so both scopes are tried.
  Future<String> _fetchStaffCodeForUserCode(String userCode) async {
    final organizationCode = await _currentOrganizationCode();
    if (organizationCode.isEmpty) return '';
    final schoolCode = await _currentSchoolCode();

    final StaffRepository repository;
    try {
      repository = serviceLocator<StaffRepository>();
    } catch (_) {
      return '';
    }

    for (final candidateSchoolCode in <String>{
      if (schoolCode.isNotEmpty) schoolCode,
      '-',
    }) {
      try {
        final resolved =
            (await repository.getStaffCodeForUser(
                      userCode: userCode,
                      organizationCode: organizationCode,
                      schoolCode: candidateSchoolCode,
                    ) ??
                    '')
                .trim();
        if (resolved.isNotEmpty) return resolved;
      } catch (_) {
        // 404 for this scope (or offline) — try the next candidate.
      }
    }
    return '';
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
    try {
      final apiClient = serviceLocator<ApiClient>();
      final endpoint =
          '${ApiConstants.documentMsBaseUrl.replaceAll(RegExp(r'/+$'), '')}'
          '${ApiPaths.documentMediaAssetByCodePath(normalizedAssetCode)}';
      final response = await apiClient.client.get<dynamic>(endpoint);
      final body = response.data;
      return _extractDocumentAssetUrl(body);
    } catch (_) {
      return '';
    }
  }

  String _extractDocumentAssetUrl(dynamic body) {
    if (body is! Map) return '';
    final data = body['data'];
    if (data is! Map) return '';

    String pickUrl(Map map) {
      final candidates = <dynamic>[
        map['deliveryUrl'],
        map['artifactUrl'],
        map['url'],
        map['thumbnailUrl'],
        map['originalDownloadUrl'],
      ];
      for (final raw in candidates) {
        final value = (raw ?? '').toString().trim();
        if (value.isNotEmpty) return value;
      }
      return '';
    }

    final direct = pickUrl(data);
    if (direct.isNotEmpty) return direct;

    final variants = data['variants'];
    if (variants is List) {
      for (final row in variants.whereType<Map>()) {
        final defaultVariant =
            (row['defaultVariant'] ?? false).toString().toLowerCase() == 'true';
        if (!defaultVariant) continue;
        final url = pickUrl(row);
        if (url.isNotEmpty) return url;
      }
      for (final row in variants.whereType<Map>()) {
        final url = pickUrl(row);
        if (url.isNotEmpty) return url;
      }
    }
    return '';
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
        final useCase = serviceLocator<GetStaffTodaySignInStatusUseCase>();
        status = await useCase(staffCode: staffCode);
      } else if (studentCode != null && studentCode.isNotEmpty) {
        final useCase = serviceLocator<GetStudentTodaySignInStatusUseCase>();
        status = await useCase(studentCode: studentCode);
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
            // `MediaRes.userImageMale` was, despite its name, the retired
            // owl/graduation-cap WowCare logo — so any avatar without a
            // resolved photo or name (the async gap while a signed image URL
            // is being fetched) briefly flashed old branding instead of a
            // neutral no-photo placeholder. A plain person icon reads as
            // "no photo yet" instead of as content.
            : CircleAvatar(
                radius: widget.size / 2,
                backgroundColor: AppColors.shimmerBase,
                child: Icon(
                  Icons.person,
                  size: widget.size * 0.6,
                  color: AppColors.userProfileMutedIconColor,
                ),
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
