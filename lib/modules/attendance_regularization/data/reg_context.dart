import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/storage_keys.dart';

import '../core/utils/reg_time_zone.dart';

/// The ambient values the repository needs from the host app.
///
/// Two things are unavoidably ambient: the school's IANA timezone (every
/// payload carries `timeZone`, §10.1) and the active `schoolCode` (§9.7's
/// bulk-approve body requires it). Naming them in a two-method interface,
/// rather than reaching into `serviceLocator` from inside the repository,
/// keeps the repository unit-testable and makes the module's dependency on
/// host state explicit instead of hidden.
abstract class RegContext {
  /// Active school, for the §9.7 body.
  Future<String> schoolCode();

  /// School IANA zone, for wall-clock ⇄ UTC conversion.
  Future<String> timeZone();

  /// The logged-in user's staff code, used when a §9.1 gate item carries none.
  Future<String> staffCode();
}

/// Real implementation, backed by the host's storage and timezone resolver.
class RegHostContext implements RegContext {
  RegHostContext({
    required StorageService storage,
    required ApiClient apiClient,
  })  : _storage = storage,
        _apiClient = apiClient;

  final StorageService _storage;
  final ApiClient _apiClient;

  @override
  Future<String> schoolCode() async =>
      (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();

  @override
  Future<String> staffCode() async =>
      (await _storage.getString(StorageKeys.staffCode) ?? '').trim();

  @override
  Future<String> timeZone() async {
    try {
      final zone = await SchoolTimezoneResolver.resolveForCurrentSchool(
        storage: _storage,
        apiClient: _apiClient,
      );
      // The resolver can legitimately answer "UTC" when no school is selected;
      // `resolveZone` turns that into a usable IANA zone so a wall-clock time
      // is never converted against a placeholder.
      return RegTimeZone.resolveZone(zone);
    } catch (_) {
      return RegTimeZone.resolveZone(
        SchoolTimezoneResolver.lastKnownTimeZone,
      );
    }
  }
}

/// Fixed values, for tests and for the mock-backed dev flow.
class RegStaticContext implements RegContext {
  const RegStaticContext({
    this.zone = 'America/New_York',
    this.school = 'SCH_MOCK',
    this.staff = 'STF_ME',
  });

  final String zone;
  final String school;
  final String staff;

  @override
  Future<String> schoolCode() async => school;

  @override
  Future<String> timeZone() async => zone;

  @override
  Future<String> staffCode() async => staff;
}
