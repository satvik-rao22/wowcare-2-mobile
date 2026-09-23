import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/sign_in_pin_resolver.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';

class _FakeStorageService implements StorageService {
  final Map<String, String> _strings = {};

  @override
  Future<void> saveString(String key, String value) async {
    _strings[key] = value;
  }

  @override
  Future<String?> getString(String key) async => _strings[key];

  @override
  Future<void> remove(String key) async => _strings.remove(key);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Scripts `getStaffSignInPin` and records every staff code it was asked for.
class _FakeStaffRepository implements StaffRepository {
  _FakeStaffRepository(this.pin);

  /// Returns the PIN, or throws when the fixture is an [Exception].
  final Object pin;
  final List<String> askedFor = <String>[];

  @override
  Future<String> getStaffSignInPin({required String staffCode}) async {
    askedFor.add(staffCode);
    final value = pin;
    if (value is Exception) throw value;
    return value as String;
  }

  /// The resolver falls back to the stored staff code when this returns null,
  /// which is what every test here relies on.
  @override
  Future<String?> getStaffCodeForUser({
    required String userCode,
    required String organizationCode,
    required String schoolCode,
  }) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeStorageService storage;

  setUp(() async {
    await serviceLocator.reset();
    storage = _FakeStorageService();
    serviceLocator.registerSingleton<StorageService>(storage);
  });

  tearDown(() async => serviceLocator.reset());

  test('asks the API for the PIN and never reads a stored copy', () async {
    await storage.saveString(StorageKeys.staffCode, 'STF_1');
    // A stale value left by an older build that used to cache the PIN. The
    // resolver must ignore it entirely — that cache is the bug it replaces.
    await storage.saveString(StorageKeys.staffPin, '0000');
    final repository = _FakeStaffRepository('4321');

    final pin = await fetchSignInPinForLoggedInUser(
      staffRepository: repository,
      storageService: storage,
    );

    expect(pin, '4321');
    expect(repository.askedFor, <String>['STF_1']);
  });

  test('trims whatever the API returns', () async {
    await storage.saveString(StorageKeys.staffCode, 'STF_1');

    final pin = await fetchSignInPinForLoggedInUser(
      staffRepository: _FakeStaffRepository('  9876 '),
      storageService: storage,
    );

    expect(pin, '9876');
  });

  test('returns null when the fetch fails, so callers keep what is shown', () async {
    await storage.saveString(StorageKeys.staffCode, 'STF_1');

    final pin = await fetchSignInPinForLoggedInUser(
      staffRepository: _FakeStaffRepository(Exception('offline')),
      storageService: storage,
    );

    // Distinct from '': null means "unknown, leave the card alone", whereas
    // '' means "this account genuinely has no PIN".
    expect(pin, isNull);
  });

  test('returns empty without calling the API when there is no staff code', () async {
    // A guardian-only account: nothing to ask the staff service about.
    final repository = _FakeStaffRepository('4321');

    final pin = await fetchSignInPinForLoggedInUser(
      staffRepository: repository,
      storageService: storage,
    );

    expect(pin, '');
    expect(repository.askedFor, isEmpty);
  });
}
