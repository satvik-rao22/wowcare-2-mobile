import 'api_constants.dart';

/// UAT routing rules for API URLs.
///
/// This matches the repo-root `api_paths.dart` behavior (host is derived from the
/// resource segment after `/api/v1/`), but is kept under `lib/` so Flutter can
/// compile it.
class ApiPathsUat {
  ApiPathsUat._();

  static const Set<String> _microservicePathSegments = {
    ApiMicroservices.user,
    ApiMicroservices.organization,
    ApiMicroservices.staff,
    ApiMicroservices.student,
    ApiMicroservices.classroom,
    ApiMicroservices.attendance,
    ApiMicroservices.activity,
    ApiMicroservices.document,
  };

  static const Map<String, Set<String>> _resourceRootsByMicroservice = {
    ApiMicroservices.user: {
      'auth',
      'users',
      'school-users',
      'organization-admins',
      'guardian-user',
      'guardian',
    },
    ApiMicroservices.organization: {
      'schools',
      'organizations',
      'school',
    },
    ApiMicroservices.staff: {
      'staff',
      'staff-classrooms',
      'staff-documents',
      'staff-dates',
      'staff-address',
      'staff-schedules',
    },
    ApiMicroservices.student: {
      'student',
      'student-classroom',
      'student-documents',
      'student-tags',
      'regular-schedules',
      'physicians',
      'tags',
      'guardian',
      'pickup',
    },
    ApiMicroservices.attendance: {
      'student-attendance',
      'student-absence-records',
      'student-attendance-records',
      'staff-attendance',
      'staff-absence-records',
      'staff-attendance-records',
    },
    ApiMicroservices.classroom: {
      'classroom',
    },
    ApiMicroservices.activity: {
      'classrooms',
      'activities',
      'activity-types',
    },
    // Document endpoints in this app are handled separately via `/document-ms/...`.
    ApiMicroservices.document: {},
  };

  static String microserviceKeyFromPath(String path) {
    final p = path.startsWith('/') ? path : '/$path';
    final parts = p.split('/').where((s) => s.isNotEmpty).toList();
    if (parts.length < 3 || parts[0] != 'api' || parts[1] != 'v1') {
      return ApiMicroservices.user;
    }
    final seg = parts[2];

    // If the UAT path already includes the microservice segment
    // (/api/v1/<ms>/...), use it as-is.
    if (_microservicePathSegments.contains(seg)) return seg;

    switch (seg) {
      case 'auth':
      case 'users':
      case 'school-users':
      case 'organization-admins':
      case 'guardian-user':
        return ApiMicroservices.user;
      case 'schools':
      case 'organizations':
      case 'school':
        return ApiMicroservices.organization;
      case 'staff':
      case 'staff-classrooms':
      case 'staff-documents':
      case 'staff-dates':
      case 'staff-address':
      case 'staff-schedules':
        return ApiMicroservices.staff;
      case 'student':
      case 'student-classroom':
      case 'student-documents':
      case 'student-tags':
      case 'regular-schedules':
      case 'physicians':
      case 'tags':
      case 'guardian':
      case 'pickup':
        return ApiMicroservices.student;
      case 'student-attendance':
      case 'student-absence-records':
      case 'student-attendance-records':
      case 'staff-attendance':
      case 'staff-absence-records':
      case 'staff-attendance-records':
        return ApiMicroservices.attendance;
      case 'classroom':
        return ApiMicroservices.classroom;
      case 'classrooms':
      case 'activities':
      case 'activity-types':
        return ApiMicroservices.activity;
      default:
        return ApiMicroservices.user;
    }
  }

  /// Whether [path] should include org+school headers:
  /// `X-Organization-Code` and `X-School-Code`.
  ///
  /// In UAT we still want this for most authenticated API calls (including
  /// `GET /api/v1/student/student-classroom`).
  static bool requiresOrganizationAndSchoolHeaders(String path) {
    final p = path.startsWith('/') ? path : '/$path';
    if (!p.startsWith('/api/v1/')) return false;
    if (p.startsWith('/document-ms/')) return false;
    // Public endpoints: no org/school context.
    if (p.contains('/auth/login') || p.contains('/auth/forgot-password')) {
      return false;
    }
    return true;
  }

  /// UAT expects `/api/v1/<ms>/...` (e.g. `/api/v1/user/auth/login`).
  /// If [path] is already in that format, it's returned unchanged.
  static String _ensureUatMicroserviceSegment(String path) {
    var p = path.startsWith('/') ? path : '/$path';

    // Special-case: document-ms endpoints are already namespaced differently.
    if (p.startsWith('/document-ms/')) return p;

    final parts = p.split('/').where((s) => s.isNotEmpty).toList();
    if (parts.length < 3 || parts[0] != 'api' || parts[1] != 'v1') return p;

    final seg = parts[2];
    if (_microservicePathSegments.contains(seg)) {
      // Ambiguous case: some endpoints use the same word for both MS and resource
      // (e.g. local `/api/v1/staff/code` should become `/api/v1/staff/staff/code` in UAT).
      final ms = seg;
      final roots = _resourceRootsByMicroservice[ms];
      if (parts.length >= 4 && roots != null && roots.contains(parts[3])) {
        return p; // already `/api/v1/<ms>/<resource>/...`
      }
      final rest = parts.sublist(2).join('/');
      return '/api/v1/$ms/$rest';
    }

    final ms = microserviceKeyFromPath(p);
    final rest = parts.sublist(2).join('/');
    return '/api/v1/$ms/$rest';
  }

  static String url(String path) {
    final p = _ensureUatMicroserviceSegment(path);
    final ms = microserviceKeyFromPath(p);
    return '${ApiConstants.baseUrlForMicroservice(ms)}$p';
  }

  static String urlWithBase(String path, String baseUrl) => url(path);

  /// Document endpoints are special-cased under `/document-ms/...` in this app.
  /// This helper is added for parity with local [ApiPaths].
  static String documentAssetCompletePath({
    required String documentApiBasePath,
    required String sessionCode,
    required String assetCode,
  }) {
    var base = documentApiBasePath.trim();
    if (base.isEmpty) base = '/document-ms/api/v1';
    if (!base.startsWith('/')) base = '/$base';
    base = base.replaceAll(RegExp(r'/+$'), '');
    final s = sessionCode.trim();
    final a = assetCode.trim();
    return '$base/upload-sessions/$s/assets/$a/complete';
  }
}

