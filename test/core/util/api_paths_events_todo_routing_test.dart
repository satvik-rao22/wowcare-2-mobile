import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/utils/api_constants.dart';
import 'package:wowcare/core/utils/api_constants_dev.dart';
import 'package:wowcare/core/utils/api_constants_prod.dart';
import 'package:wowcare/core/utils/api_constants_uat.dart';
import 'package:wowcare/core/utils/api_paths.dart';
import 'package:wowcare/core/utils/api_paths_uat.dart';

/// Events, Tasks and Holidays are served by the events-todo microservice, but
/// the gateway exposes them as top-level routes: the request path is exactly
/// `/api/v1/events/...`, `/api/v1/tasks/...`, `/api/v1/holidays/...`,
/// `/api/v1/occurrences` and `/api/v1/calendar/feed`, with no `events-todo`
/// or `scheduler` segment after the version. This pins that on every gateway
/// environment so it cannot come undone through the path rewriter or the
/// per-service base URLs.
void main() {
  const List<String> paths = <String>[
    '/api/v1/events',
    '/api/v1/events/EVT_99E594B6AC',
    '/api/v1/events/EVT_99E594B6AC/occurrences',
    '/api/v1/events/EVT_99E594B6AC/occurrences/OCC_DB3558B6C4/rsvp',
    '/api/v1/events/EVT_99E594B6AC/occurrences/OCC_DB3558B6C4/rsvps',
    '/api/v1/events/EVT_99E594B6AC/attachments',
    '/api/v1/occurrences',
    '/api/v1/calendar/feed',
    '/api/v1/holidays',
    '/api/v1/holidays/HOL_1/status',
    '/api/v1/tasks',
    '/api/v1/tasks/TSK_B63D01D6EB',
    '/api/v1/tasks/TSK_B63D01D6EB/occurrences/TOC_7',
    '/api/v1/tasks/assignments/TSA_1/status',
    '/api/v1/tasks/board',
    '/api/v1/tasks/upload-session',
  ];

  bool hasServiceSegment(String url) =>
      url.contains('/events-todo/') || url.contains('/scheduler/');

  group('gateway path rewrite leaves events-todo routes untouched', () {
    test('every path classifies as the events-todo service', () {
      for (final String p in paths) {
        expect(
          ApiPathsUat.microserviceKeyFromPath(p),
          ApiMicroservices.eventsTodo,
          reason: p,
        );
        expect(
          ApiPaths.microserviceKeyFromPath(p),
          ApiMicroservices.eventsTodo,
          reason: p,
        );
      }
    });

    test('the rewritten URL ends with the original path', () {
      for (final String p in paths) {
        final String url = ApiPathsUat.url(p);
        expect(url, endsWith(p), reason: p);
        expect(hasServiceSegment(url), isFalse, reason: url);
      }
    });

    test('the ApiPaths builders produce the same unprefixed paths', () {
      expect(
        ApiPaths.occurrenceRsvps('EVT_99E594B6AC', 'OCC_DB3558B6C4'),
        '/api/v1/events/EVT_99E594B6AC/occurrences/OCC_DB3558B6C4/rsvps',
      );
      expect(
        ApiPaths.taskByCode('TSK_B63D01D6EB'),
        '/api/v1/tasks/TSK_B63D01D6EB',
      );
      expect(ApiPaths.holidayStatus('HOL_1'), '/api/v1/holidays/HOL_1/status');
      expect(ApiPaths.calendarFeed, '/api/v1/calendar/feed');
      expect(ApiPaths.occurrencesView, '/api/v1/occurrences');
    });
  });

  group('the events-todo base URL is the bare gateway host', () {
    test('on DEV, UAT and PROD', () {
      final Map<String, String> bases = <String, String>{
        'DEV': ApiConstantsDev.baseUrlForMicroservice(
          ApiMicroservicesDev.eventsTodo,
        ),
        'DEV scheduler key': ApiConstantsDev.baseUrlForMicroservice(
          ApiMicroservicesDev.scheduler,
        ),
        'UAT': ApiConstantsUat.baseUrlForMicroservice(
          ApiMicroservicesUat.eventsTodo,
        ),
        'PROD': ApiConstantsProd.baseUrlForMicroservice(
          ApiMicroservicesProd.eventsTodo,
        ),
      };
      bases.forEach((String env, String base) {
        final Uri uri = Uri.parse(base);
        expect(uri.hasScheme, isTrue, reason: '$env: $base');
        expect(uri.path, anyOf(isEmpty, '/'), reason: '$env: $base');
      });
      expect(bases['DEV'], ApiConstantsDev.baseUrl);
      expect(bases['UAT'], ApiConstantsUat.baseUrl);
      expect(bases['PROD'], ApiConstantsProd.baseUrl);
    });
  });

  group('the URLs the app sends on the default (DEV) build', () {
    // The test binary has no --dart-define, so ApiConstants is on its default
    // environment, which is the DEV gateway.
    test('match the gateway routes exactly', () {
      expect(ApiConstants.isGatewayEnv, isTrue);
      expect(
        ApiPaths.urlWithBase(
          ApiPaths.occurrenceRsvps('EVT_99E594B6AC', 'OCC_DB3558B6C4'),
          ApiConstants.schedulerBaseUrl,
        ),
        '${ApiConstantsDev.baseUrl}'
        '/api/v1/events/EVT_99E594B6AC/occurrences/OCC_DB3558B6C4/rsvps',
      );
      expect(
        ApiPaths.urlWithBase(
          ApiPaths.taskByCode('TSK_B63D01D6EB'),
          ApiConstants.eventsTodoBaseUrl,
        ),
        '${ApiConstantsDev.baseUrl}/api/v1/tasks/TSK_B63D01D6EB',
      );
      expect(
        ApiPaths.urlWithBase(ApiPaths.holidays, ApiConstants.schedulerBaseUrl),
        '${ApiConstantsDev.baseUrl}/api/v1/holidays',
      );
      for (final String p in paths) {
        expect(
          hasServiceSegment(
            ApiPaths.urlWithBase(p, ApiConstants.schedulerBaseUrl),
          ),
          isFalse,
          reason: p,
        );
      }
    });
  });
}
