part of 'asset_service.dart';

/// What [AssetService.profilePhotoUrl] found: the photo's [url], or none.
///
/// [deleted] is true when there is no photo because it was deleted moments
/// ago. The caller then clears the photo it shows. Any other empty result
/// (lookup failed, raced, offline) keeps what is already on screen.
typedef ProfilePhotoLookup = ({String? url, bool deleted});

/// Profile photos and classroom logos: whose photo is it → its display URL.
///
/// [AssetService.getMediaAssetUrlByCode] turns an asset code into a URL. This
/// adds the step before it: finding the photo's asset code from a student,
/// staff, user or classroom code. Results are cached for 10 minutes and
/// requests in flight are shared, so a list of 50 avatars of the same people
/// asks the server once per person.
///
/// Uploads go through [ProfilePhotoUploader]; after one, call
/// [primeProfilePhotoUrl] or [clearProfilePhotoCache], and after a delete
/// [forgetProfilePhoto], so every avatar on screen updates at once.
mixin _ProfilePhotos {
  ApiClient get _apiClient;

  Future<String> getMediaAssetUrlByCode({required String assetCode});

  static const Duration _photoCacheTtl = Duration(minutes: 10);

  /// Long enough to outlast the backend's eventual consistency right after a
  /// delete, short enough that it cannot suppress a later re-upload.
  static const Duration _deletedTombstoneTtl = Duration(minutes: 2);

  final Map<String, String> _photoUrlCache = <String, String>{};
  final Map<String, DateTime> _photoFetchedAt = <String, DateTime>{};
  final Map<String, Future<String?>> _photoInFlight =
      <String, Future<String?>>{};

  /// Owners whose photo was just deleted, and when. See [forgetProfilePhoto].
  final Map<String, DateTime> _photoDeletedAt = <String, DateTime>{};

  /// Staff photo keys (`staff:<code>`) that have a photo. Unlike the URL cache
  /// this has no TTL: an avatar keeps showing its photo long after the cache
  /// entry expires, so "is there a photo" can't be answered from the cache.
  final Set<String> _staffKeysWithPhoto = <String>{};

  /// `USR_*` → `STF_*` for avatars that only know the account code. The
  /// mapping doesn't change within a session, so it's never invalidated.
  /// Empty values are cached too, so a non-staff account isn't re-queried.
  final Map<String, String> _staffCodeByUserCode = <String, String>{};
  final Map<String, Future<String>> _staffCodeByUserCodeInFlight =
      <String, Future<String>>{};

  final ValueNotifier<int> _photoChanges = ValueNotifier<int>(0);
  final ValueNotifier<int> _photoResolved = ValueNotifier<int>(0);

  /// Fires when a photo was uploaded, replaced or deleted. Mounted avatars
  /// listen and look their photo up again.
  Listenable get profilePhotoChanges => _photoChanges;

  /// Fires when a lookup found a photo. Lets a screen (the profile photo
  /// action sheet) re-check "is there a photo" when a lookup that was in
  /// flight when it opened finishes.
  Listenable get profilePhotoResolved => _photoResolved;

  // ── Reading ───────────────────────────────────────────────────────────────

  /// The photo URL already in the cache, without asking the server. Lets an
  /// avatar paint its photo on the first frame instead of flashing initials.
  String? cachedProfilePhotoUrl({
    String? assetCode,
    String? classroomCode,
    String? studentCode,
    String? staffCode,
    String? userCode,
  }) {
    for (final key in <String>[
      if (_has(assetCode)) 'asset:${assetCode!.trim()}',
      if (_has(classroomCode)) 'classroom:${classroomCode!.trim()}',
      if (_has(studentCode)) 'student:${studentCode!.trim()}',
      if (_has(staffCode)) 'staff:${staffCode!.trim()}',
      if (_has(userCode) && _has(_staffCodeByUserCode[userCode!.trim()]))
        'staff:${_staffCodeByUserCode[userCode.trim()]}',
    ]) {
      final cached = _cachedUrlIfFresh(key);
      if (cached != null && cached.isNotEmpty) return cached;
    }
    return null;
  }

  /// Finds the photo for the first code given, in this order: [assetCode],
  /// [classroomCode] (a classroom logo), [studentCode], [staffCode],
  /// [userCode] (mapped to the staff code first).
  ///
  /// [lookUpProfile] false skips the student/staff profile lookups, for
  /// callers whose data already says there's no photo; asset codes and
  /// classroom logos are still looked up.
  Future<ProfilePhotoLookup> profilePhotoUrl({
    String? assetCode,
    String? classroomCode,
    String? studentCode,
    String? staffCode,
    String? userCode,
    bool lookUpProfile = true,
  }) async {
    const none = (url: null, deleted: false);
    final asset = assetCode?.trim() ?? '';
    final classroom = classroomCode?.trim() ?? '';
    final student = studentCode?.trim() ?? '';
    var staff = staffCode?.trim() ?? '';
    final user = userCode?.trim() ?? '';
    if (asset.isEmpty && classroom.isEmpty) {
      if (!lookUpProfile) return none;
      if (student.isEmpty && staff.isEmpty && user.isEmpty) return none;
      // Map the account code BEFORE picking the cache key, so the photo is
      // stored under the same `staff:<code>` entry every other avatar of this
      // person uses, and clear/prime keep working for it.
      if (student.isEmpty && staff.isEmpty) {
        staff = await _staffCodeForUserCode(user);
        if (staff.isEmpty) return none;
      }
    }

    final key = asset.isNotEmpty
        ? 'asset:$asset'
        : classroom.isNotEmpty
        ? 'classroom:$classroom'
        : student.isNotEmpty
        ? 'student:$student'
        : 'staff:$staff';
    final cached = _cachedUrlIfFresh(key);
    if (cached != null && cached.isNotEmpty) {
      return (url: cached, deleted: false);
    }

    final future =
        _photoInFlight[key] ??
        (_photoInFlight[key] = _fetchPhotoUrl(
          assetCode: asset,
          classroomCode: classroom,
          studentCode: student,
          staffCode: staff,
          lookUpProfile: lookUpProfile,
        ));
    try {
      final resolved = (await future)?.trim() ?? '';
      if (resolved.isNotEmpty) {
        if (_photoInFlight[key] == future) {
          _photoUrlCache[key] = resolved;
          _photoFetchedAt[key] = AppTime.nowUtc();
          if (key.startsWith('staff:')) _staffKeysWithPhoto.add(key);
          _photoResolved.value++;
        }
        return (url: resolved, deleted: false);
      }
      return (url: null, deleted: _wasRecentlyDeleted(key));
    } catch (_) {
      // Network / 404: the avatar keeps its initials.
      return none;
    } finally {
      if (_photoInFlight[key] == future) _photoInFlight.remove(key);
    }
  }

  /// Whether [staffCode] currently has a photo. Read-only: never fetches.
  ///
  /// Lets a screen agree with what its avatar shows — the avatar resolves a
  /// staff photo by code when the profile response carries no URL, so
  /// `profilePhotoUrl` alone can say "no photo" while one is on screen.
  bool hasResolvedStaffPhoto(String? staffCode) {
    final code = (staffCode ?? '').trim();
    if (code.isEmpty) return false;
    final key = 'staff:$code';
    if (_wasRecentlyDeleted(key)) return false;
    if (_staffKeysWithPhoto.contains(key)) return true;
    final cached = _cachedUrlIfFresh(key);
    return cached != null && cached.isNotEmpty;
  }

  // ── After an upload or delete ─────────────────────────────────────────────

  /// Drops the cached photo for the given owner (or everyone when no code is
  /// passed) and makes every mounted avatar look its photo up again.
  void clearProfilePhotoCache({
    String? studentCode,
    String? staffCode,
    String? classroomCode,
  }) {
    if (!_has(studentCode) && !_has(staffCode) && !_has(classroomCode)) {
      _photoUrlCache.clear();
      _photoFetchedAt.clear();
      _photoInFlight.clear();
    } else {
      // A targeted clear runs after a (re-)upload. Lift any delete tombstone,
      // or a photo uploaded within minutes of a delete counts as deleted.
      for (final key in _keys(studentCode, staffCode, classroomCode)) {
        _removeKey(key);
        _photoDeletedAt.remove(key);
      }
    }
    _photoChanges.value++;
  }

  /// Marks the owner's photo as deleted and drops every trace of it.
  ///
  /// [clearProfilePhotoCache] alone isn't enough after a delete: the lookup
  /// that follows comes back empty, and an empty result normally keeps what
  /// the avatar shows (the lookup may just have failed). The short-lived
  /// tombstone recorded here tells the two apart, so the avatar clears.
  void forgetProfilePhoto({String? studentCode, String? staffCode}) {
    for (final key in _keys(studentCode, staffCode, null)) {
      final cached = _photoUrlCache[key];
      // Evict the bitmap too, or it keeps painting once the URL 404s.
      if (cached != null && cached.isNotEmpty) unawaited(_evict(cached));
      _removeKey(key);
      _staffKeysWithPhoto.remove(key);
      _photoDeletedAt[key] = AppTime.nowUtc();
    }
    _photoChanges.value++;
  }

  /// Records that a staff photo was just uploaded, so screens offer Delete
  /// straight away instead of waiting for the (eventually-consistent) URL.
  void markStaffPhotoUploaded(String? staffCode) {
    if (!_has(staffCode)) return;
    final key = 'staff:${staffCode!.trim()}';
    _photoDeletedAt.remove(key);
    _staffKeysWithPhoto.add(key);
    _photoResolved.value++;
  }

  /// Seeds a just-uploaded photo/logo [url] for the owner, so avatars show it
  /// at once without re-asking the (eventually-consistent) server, which
  /// could hand back the old image. An empty [url] just clears the cache.
  void primeProfilePhotoUrl({
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
    for (final key in _keys(studentCode, staffCode, classroomCode)) {
      _photoUrlCache[key] = u;
      _photoFetchedAt[key] = AppTime.nowUtc();
      _photoInFlight.remove(key);
      _photoDeletedAt.remove(key);
      if (key.startsWith('staff:')) _staffKeysWithPhoto.add(key);
    }
    // Right after an upload the CDN can briefly 4xx the object, and a failed
    // load is cached. Evict and refresh now, and once more after the CDN has
    // had a moment, so the photo appears on its own.
    unawaited(_evict(u));
    _photoChanges.value++;
    Future<void>.delayed(const Duration(milliseconds: 1500), () async {
      await _evict(u);
      _photoChanges.value++;
    });
  }

  // ── Internals ─────────────────────────────────────────────────────────────

  static bool _has(String? value) => (value ?? '').trim().isNotEmpty;

  static List<String> _keys(String? student, String? staff, String? room) => [
    if (_has(student)) 'student:${student!.trim()}',
    if (_has(staff)) 'staff:${staff!.trim()}',
    if (_has(room)) 'classroom:${room!.trim()}',
  ];

  void _removeKey(String key) {
    _photoUrlCache.remove(key);
    _photoFetchedAt.remove(key);
    _photoInFlight.remove(key);
  }

  static Future<void> _evict(String url) async {
    try {
      await AppImage.evict(url);
    } catch (_) {}
  }

  bool _wasRecentlyDeleted(String key) {
    final deletedAt = _photoDeletedAt[key];
    if (deletedAt == null) return false;
    if (AppTime.nowUtc().difference(deletedAt) > _deletedTombstoneTtl) {
      _photoDeletedAt.remove(key);
      return false;
    }
    return true;
  }

  String? _cachedUrlIfFresh(String key) {
    final cached = _photoUrlCache[key];
    final fetchedAt = _photoFetchedAt[key];
    if (cached == null || fetchedAt == null) return null;
    if (AppTime.nowUtc().difference(fetchedAt) > _photoCacheTtl) {
      _photoUrlCache.remove(key);
      _photoFetchedAt.remove(key);
      return null;
    }
    return cached;
  }

  Future<String?> _fetchPhotoUrl({
    required String assetCode,
    required String classroomCode,
    required String studentCode,
    required String staffCode,
    required bool lookUpProfile,
  }) async {
    if (assetCode.isNotEmpty) {
      final url = await _assetUrl(assetCode);
      if (url != null || !lookUpProfile) return url;
      // The asset lookup failed: fall back to the owner's profile below.
    }
    if (classroomCode.isNotEmpty) {
      final logoCode = await _assetCodeFromList(
        path: ApiPaths.url(ApiPaths.classroomLogoAssetCodes),
        query: {'classroomCode': classroomCode},
        matchField: 'classroomCode',
        match: classroomCode,
        codeFields: const ['logoAssetCode', 'assetCode'],
      );
      return logoCode.isEmpty ? null : _assetUrl(logoCode);
    }
    if (studentCode.isNotEmpty) {
      return _ownerPhotoUrl(
        profilePath: ApiPaths.urlWithBase(
          ApiPaths.studentProfile(studentCode),
          ApiConstants.studentBaseUrl,
        ),
        listPath: ApiPaths.urlWithBase(
          ApiPaths.studentProfilePhotoAssetCodes,
          ApiConstants.studentBaseUrl,
        ),
        matchField: 'studentCode',
        code: studentCode,
        codeFields: const ['assetCode'],
      );
    }
    if (staffCode.isNotEmpty) {
      return _ownerPhotoUrl(
        profilePath: ApiPaths.urlWithBase(
          ApiPaths.staffProfileByCodePath(staffCode),
          ApiConstants.staffBaseUrl,
        ),
        listPath: ApiPaths.urlWithBase(
          ApiPaths.staffProfilePhotoAssetCodes,
          ApiConstants.staffBaseUrl,
        ),
        matchField: 'staffCode',
        code: staffCode,
        codeFields: const ['profilePhotoAssetCode', 'assetCode'],
      );
    }
    return null;
  }

  Future<String?> _assetUrl(String assetCode) async {
    final url = (await getMediaAssetUrlByCode(assetCode: assetCode)).trim();
    return url.isEmpty ? null : url;
  }

  /// A student's or staff member's photo: the profile's own photo URL, else
  /// its photo asset code, else the school's photo asset-code list. The
  /// profile endpoint can 404 (e.g. local backends); that falls through to
  /// the list rather than throwing.
  Future<String?> _ownerPhotoUrl({
    required String profilePath,
    required String listPath,
    required String matchField,
    required String code,
    required List<String> codeFields,
  }) async {
    var assetCode = '';
    var schoolCode = '';
    try {
      final response = await _apiClient.client.get<dynamic>(profilePath);
      final body = response.data;
      final data = body is Map && body['data'] is Map
          ? Map<String, dynamic>.from(body['data'] as Map)
          : null;
      if (data != null) {
        final directUrl = _firstNonEmpty(data, const [
          'profilePhotoUrl',
          'photoUrl',
          'profileImageUrl',
          'imageUrl',
          'url',
        ]);
        if (directUrl.isNotEmpty) return directUrl;
        assetCode = _firstNonEmpty(data, const [
          'profilePhotoAssetCode',
          'photoAssetCode',
          'assetCode',
        ]);
        schoolCode = (data['schoolCode'] ?? '').toString().trim();
      }
    } catch (_) {
      // Fall through to the asset-code list.
    }
    if (assetCode.isEmpty) {
      assetCode = await _assetCodeFromList(
        path: listPath,
        query: {matchField: code},
        matchField: matchField,
        match: code,
        codeFields: codeFields,
        schoolCode: schoolCode,
      );
    }
    return assetCode.isEmpty ? null : _assetUrl(assetCode);
  }

  /// Reads a `{data: [{<matchField>, <codeField>}]}` asset-code list for the
  /// school and returns the code of the row matching [match].
  Future<String> _assetCodeFromList({
    required String path,
    required Map<String, String> query,
    required String matchField,
    required String match,
    required List<String> codeFields,
    String schoolCode = '',
  }) async {
    final school = schoolCode.isNotEmpty
        ? schoolCode
        : await _stored(StorageKeys.schoolCode);
    if (school.isEmpty) return '';
    try {
      final response = await _apiClient.client.get<dynamic>(
        path,
        queryParameters: <String, dynamic>{...query, 'schoolCode': school},
      );
      final body = response.data;
      final rows = body is Map ? body['data'] : null;
      if (rows is! List) return '';
      final row = rows.whereType<Map>().firstWhere(
        (r) =>
            (r[matchField] ?? '').toString().trim().toUpperCase() ==
            match.toUpperCase(),
        orElse: () => const {},
      );
      return _firstNonEmpty(row, codeFields);
    } catch (_) {
      return '';
    }
  }

  static String _firstNonEmpty(Map<dynamic, dynamic> data, List<String> keys) {
    for (final key in keys) {
      final value = (data[key] ?? '').toString().trim();
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  static Future<String> _stored(String key) async {
    try {
      return (await serviceLocator<StorageService>().getString(key) ?? '')
          .trim();
    } catch (_) {
      return '';
    }
  }

  /// `USR_*` → `STF_*`, memoised and de-duped across the many avatars that
  /// ask for the same person at once. '' when the account isn't staff.
  Future<String> _staffCodeForUserCode(String userCode) async {
    final cached = _staffCodeByUserCode[userCode];
    if (cached != null) return cached;
    final future =
        _staffCodeByUserCodeInFlight[userCode] ??
        (_staffCodeByUserCodeInFlight[userCode] = _fetchStaffCode(userCode));
    try {
      return _staffCodeByUserCode[userCode] = await future;
    } catch (_) {
      return '';
    } finally {
      _staffCodeByUserCodeInFlight.remove(userCode);
    }
  }

  /// The same `/api/v1/staff/code` mapping the signed-in user's own staff
  /// code comes from. Org admins are mapped org-level, where the backend
  /// expects `'-'` and 404s on a real school code, so both are tried.
  static Future<String> _fetchStaffCode(String userCode) async {
    final organizationCode = await _stored(StorageKeys.organizationCode);
    if (organizationCode.isEmpty) return '';
    final schoolCode = await _stored(StorageKeys.schoolCode);
    final StaffRepository repository;
    try {
      repository = serviceLocator<StaffRepository>();
    } catch (_) {
      return '';
    }
    for (final school in <String>{if (schoolCode.isNotEmpty) schoolCode, '-'}) {
      try {
        final resolved = (await repository.getStaffCodeForUser(
          userCode: userCode,
          organizationCode: organizationCode,
          schoolCode: school,
        ))?.trim();
        if (resolved != null && resolved.isNotEmpty) return resolved;
      } catch (_) {
        // 404 for this scope (or offline): try the next.
      }
    }
    return '';
  }
}
