import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/school_timezone_resolver.dart';

import '../core/utils/reg_time_zone.dart';

/// The one ambient value the repository needs: the school's IANA zone, for
/// rendering UTC as school-local and converting a picked time back.
///
/// It is never sent — the school's attendance config defines its working day.
abstract class RegContext {
  Future<String> timeZone();
}

class RegHostContext implements RegContext {
  RegHostContext({
    required StorageService storage,
    required ApiClient apiClient,
  })  : _storage = storage,
        _apiClient = apiClient;

  final StorageService _storage;
  final ApiClient _apiClient;

  @override
  Future<String> timeZone() async {
    try {
      return RegTimeZone.resolveZone(
        await SchoolTimezoneResolver.resolveForCurrentSchool(
          storage: _storage,
          apiClient: _apiClient,
        ),
      );
    } catch (_) {
      return RegTimeZone.resolveZone(SchoolTimezoneResolver.lastKnownTimeZone);
    }
  }
}

class RegStaticContext implements RegContext {
  const RegStaticContext({this.zone = 'America/New_York'});

  final String zone;

  @override
  Future<String> timeZone() async => zone;
}
