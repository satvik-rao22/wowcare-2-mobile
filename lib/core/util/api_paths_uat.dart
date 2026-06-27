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
    'activities',
    ApiMicroservices.document,
    // UAT gateway uses singular `newsletter` (constant value is `newslatter`).
    'newsletter',
    // Communication
    // Billing MS — UAT segment is `accounts`.
    'accounts',
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
    ApiMicroservices.organization: {'schools', 'organizations', 'school'},
    ApiMicroservices.staff: {
      'staff',
      'staff-classrooms',
      'staff-documents',
      'staff-dates',
      'staff-address',
      'staff-schedules',
      'staff-shifts',
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
      'schools', // GPS sign-in settings: /api/v1/attendance/schools/{code}/attendance-settings
      'kiosk', // Kiosk PIN verification: /api/v1/kiosk/verify-pin
    },
    ApiMicroservices.classroom: {
      'classroom',
      'individual-movements',
      'future-availability',
    },
    ApiMicroservices.activity: {'classrooms', 'activities', 'activity-types', 'admin'},
    // Document endpoints in this app are handled separately via `/document-ms/...`.
    ApiMicroservices.document: {},

    //. Communication
    ApiMicroservices.communication: {},

    // Newsletter MS — resource root is plural `newsletters`.
    ApiMicroservices.newsLatter: {'newsletters'},
    // Billing MS — UAT segment `accounts`, resource roots.
    ApiMicroservices.billing: {
      'ledgers',
      'ledger-transactions',
      'discount',
      'subsidy',
      'fee-structure',
      'other-fees',
      'invoices',
      'school-forte-configs',
      'payment-gateway',
    },
  };

  static String _uatSegmentForMicroservice(String microserviceKey) {
    // UAT gateway expects plural `activities` as the microservice segment.
    if (microserviceKey == ApiMicroservices.activity) return 'activities';
    // UAT gateway uses singular `newsletter` (constant value is `newslatter`).
    if (microserviceKey == ApiMicroservices.newsLatter) return 'newsletter';
    // UAT gateway uses `accounts` for the billing microservice.
    if (microserviceKey == ApiMicroservices.billing) return 'accounts';
    return microserviceKey;
  }

  static String microserviceKeyFromPath(String path) {
    final p = path.startsWith('/') ? path : '/$path';
    final parts = p.split('/').where((s) => s.isNotEmpty).toList();
    if (parts.length < 3 || parts[0] != 'api') {
      return ApiMicroservices.user;
    }
    final version = parts[1];
    if (version != 'v1' && version != 'v2') {
      return ApiMicroservices.user;
    }
    final seg = parts[2];
    final nextSeg = parts.length > 3 ? parts[3] : '';

    // If the UAT path already includes the microservice segment
    // (/api/v1/<ms>/...), use it as-is.
    if (_microservicePathSegments.contains(seg)) {
      if (seg == 'activities') return ApiMicroservices.activity;
      if (seg == 'newsletter') return ApiMicroservices.newsLatter;
      return seg;
    }

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
      case 'staff-shifts':
        return ApiMicroservices.staff;
      case 'student':
      case 'student-classroom':
      case 'student-documents':
      case 'student-tags':
      case 'regular-schedules':
      case 'physicians':
      case 'tags':
      case 'guardian':
        if (nextSeg == 'activities') {
          return ApiMicroservices.activity;
        }
        return ApiMicroservices.student;
      case 'pickup':
        return ApiMicroservices.student;
      case 'student-attendance':
      case 'student-absence-records':
      case 'student-attendance-records':
      case 'staff-attendance':
      case 'staff-absence-records':
      case 'staff-attendance-records':
      case 'kiosk':
        return ApiMicroservices.attendance;
      case 'classroom':
      case 'individual-movements':
      case 'future-availability':
        return ApiMicroservices.classroom;
      case 'classrooms':
      case 'activities':
      case 'activity-types':
        return ApiMicroservices.activity;
      // /api/v1/messaging/conversations
      case 'messaging':
      case 'conversations':
      case 'messages':
        return ApiMicroservices.communication;
      case 'notification':
        return ApiMicroservices.notification;
      case 'newsletters':
        return ApiMicroservices.newsLatter;
      case 'billing':
      case 'ledgers':
      case 'accounts':
      case 'ledger-transactions':
      case 'discount':
      case 'subsidy':
      case 'fee-structure':
      case 'other-fees':
      case 'invoices':
      case 'school-forte-configs':
      case 'payment-gateway':
      case 'payment':
        return ApiMicroservices.billing;
      case 'reports':
        // Billing reports live on the accounts (billing) MS: /api/v1/reports/billing/...
        if (nextSeg == 'billing') return ApiMicroservices.billing;
        return ApiMicroservices.user;
      case 'admin':
        // v2 activity moderation endpoints:
        // /api/v2/admin/activities/{cardGroupCode}/approve|reject
        if (nextSeg == 'activities') {
          return ApiMicroservices.activity;
        }
        return ApiMicroservices.user;

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

    // Communication/messaging endpoints in UAT are routed under /messaging/ prefix.
    if (microserviceKeyFromPath(p) == ApiMicroservices.communication) {
      if (p.startsWith('/api/v1/messaging/')) return p; // already prefixed
      if (p.startsWith('/api/v1/conversations')) {
        return p.replaceFirst('/api/v1/conversations', '/api/v1/messaging/conversations');
      }
      if (p.startsWith('/api/v1/messages')) {
        return p.replaceFirst('/api/v1/messages', '/api/v1/messaging/messages');
      }
      return p;
    }

    // Notification endpoints are served under the newsletter gateway segment in
    // UAT (same MS as newsletter), so prepend that segment (keeping the
    // `notification/...` resource):
    //   /api/v1/notification/...  →  /api/v1/newsletter/notification/...
    final notificationSegment =
        _uatSegmentForMicroservice(ApiMicroservices.newsLatter);
    if (p.startsWith('/api/v1/$notificationSegment/notification/')) {
      return p; // already done
    }
    if (p.startsWith('/api/v1/notification/')) {
      return p.replaceFirst(
        '/api/v1/notification/',
        '/api/v1/$notificationSegment/notification/',
      );
    }
    if (p == '/api/v1/notification') {
      return '/api/v1/$notificationSegment/notification';
    }

    final parts = p.split('/').where((s) => s.isNotEmpty).toList();
    if (parts.length < 3 || parts[0] != 'api') return p;
    final version = parts[1];
    if (version != 'v1' && version != 'v2') return p;

    final seg = parts[2];

    if (_microservicePathSegments.contains(seg)) {
      // Ambiguous case: some endpoints use the same word for both MS and resource
      // (e.g. local `/api/v1/staff/code` should become `/api/v1/staff/staff/code` in UAT).
      final ms = seg == 'activities'
          ? ApiMicroservices.activity
          : seg == 'newsletter'
          ? ApiMicroservices.newsLatter
          : seg;
      final roots = _resourceRootsByMicroservice[ms];
      if (parts.length >= 4 && roots != null && roots.contains(parts[3])) {
        return p; // already `/api/<version>/<ms>/<resource>/...`
      }
      final rest = parts.sublist(2).join('/');
      final uatSegment = _uatSegmentForMicroservice(ms);
      return '/api/$version/$uatSegment/$rest';
    }

    final ms = microserviceKeyFromPath(p);
    final rest = parts.sublist(2).join('/');
    final uatSegment = _uatSegmentForMicroservice(ms);
    return '/api/$version/$uatSegment/$rest';
  }

  static String url(String path) {
    final p = _ensureUatMicroserviceSegment(path);
    final ms = microserviceKeyFromPath(p);
    final base = ApiConstants.baseUrlForMicroservice(ms);

    // Attendance in UAT is hosted under `/api/v1/attendance` already.
    // When [p] is `/api/v1/attendance/...`, append only the remainder.
    if (ms == ApiMicroservices.attendance &&
        base.endsWith('/api/v1/attendance') &&
        p.startsWith('/api/v1/attendance/')) {
      final rest = p.substring('/api/v1/attendance'.length);
      return '$base$rest';
    }

    return '$base$p';
  }

  static String urlWithBase(String path, String baseUrl) => url(path);

  /// Document endpoints in UAT are rooted under `/api/v1/document`.
  /// This helper is added for parity with local [ApiPaths].
  static String documentAssetCompletePath({
    required String documentApiBasePath,
    required String sessionCode,
    required String assetCode,
  }) {
    var base = documentApiBasePath.trim();
    if (base.isEmpty) base = '/api/v1/document';
    if (!base.startsWith('/')) base = '/$base';
    base = base.replaceAll(RegExp(r'/+$'), '');
    final s = sessionCode.trim();
    final a = assetCode.trim();
    return '$base/upload-sessions/$s/assets/$a/complete';
  }
}