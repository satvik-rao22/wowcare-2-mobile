import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/main.dart';

/// Scope: only `TokenLifecycleObserver` (the `main.dart` piece added on top
/// of the already-refactored `AppBootstrap`/`MyApp` split). Does not
/// re-verify `TokenRefreshService`'s own single-flight/rotation logic —
/// that's a separate file's responsibility.
class _FakeStorageService implements StorageService {
  final Map<String, Object> _values = {};

  @override
  Future<void> saveString(String key, String value) async =>
      _values[key] = value;

  @override
  Future<String?> getString(String key) async => _values[key] as String?;

  @override
  Future<void> saveInt(String key, int value) async => _values[key] = value;

  @override
  Future<int?> getInt(String key) async => _values[key] as int?;

  @override
  Future<void> saveBool(String key, bool value) async => _values[key] = value;

  @override
  Future<bool?> getBool(String key) async => _values[key] as bool?;

  @override
  Future<void> saveJson(String key, Map<String, dynamic> value) async =>
      _values[key] = value;

  @override
  Future<Map<String, dynamic>?> getJson(String key) async =>
      _values[key] as Map<String, dynamic>?;

  @override
  Future<void> remove(String key) async => _values.remove(key);

  @override
  Future<void> clear() async => _values.clear();

  @override
  Future<Set<String>> getKeys() async => _values.keys.toSet();
}

/// Records whether a network call was attempted at all — enough to detect
/// whether the observer triggered `ensureFreshToken()`, without asserting on
/// `TokenRefreshService`'s internal response-parsing behavior.
class _CountingHttpClientAdapter implements HttpClientAdapter {
  int fetchCount = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    fetchCount++;
    return ResponseBody.fromString(
      '{"data":{"accessToken":"unused"}}',
      200,
      headers: {
        'content-type': const ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _CountingHttpClientAdapter adapter;

  setUp(() async {
    adapter = _CountingHttpClientAdapter();

    if (serviceLocator.isRegistered<StorageService>()) {
      serviceLocator.unregister<StorageService>();
    }
    if (serviceLocator.isRegistered<ApiClient>()) {
      serviceLocator.unregister<ApiClient>();
    }

    final storage = _FakeStorageService();
    // A refresh token must be present for ensureFreshToken() to attempt a
    // network call at all — otherwise it short-circuits before ever
    // touching the adapter, which would make this test pass for the wrong
    // reason (no call because no observer, vs. no call because no token).
    await storage.saveString(StorageKeys.accessToken, 'stale-access-token');
    await storage.saveString(StorageKeys.refreshToken, 'some-refresh-token');
    serviceLocator.registerSingleton<StorageService>(storage);

    final apiClient = ApiClient(baseUrl: 'https://test.invalid');
    apiClient.client.httpClientAdapter = adapter;
    serviceLocator.registerSingleton<ApiClient>(apiClient);
  });

  tearDown(() {
    serviceLocator.unregister<StorageService>();
    serviceLocator.unregister<ApiClient>();
  });

  test(
    'triggers a token refresh attempt on AppLifecycleState.resumed',
    () async {
      final observer = TokenLifecycleObserver();

      observer.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(adapter.fetchCount, greaterThan(0));
    },
  );

  for (final state in [
    AppLifecycleState.inactive,
    AppLifecycleState.paused,
    AppLifecycleState.hidden,
    AppLifecycleState.detached,
  ]) {
    test('does not trigger a refresh attempt on $state', () async {
      final observer = TokenLifecycleObserver();

      observer.didChangeAppLifecycleState(state);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(adapter.fetchCount, 0);
    });
  }

  test(
    'a failed refresh is swallowed and never throws through the observer',
    () async {
      // Adapter that always fails the request.
      final failingAdapter = _ThrowingHttpClientAdapter();
      serviceLocator<ApiClient>().client.httpClientAdapter = failingAdapter;
      final observer = TokenLifecycleObserver();

      expect(
        () => observer.didChangeAppLifecycleState(AppLifecycleState.resumed),
        returnsNormally,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
    },
  );
}

class _ThrowingHttpClientAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    throw DioException(
      requestOptions: options,
      error: 'simulated network failure',
    );
  }

  @override
  void close({bool force = false}) {}
}
