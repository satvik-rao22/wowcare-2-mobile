import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/app_update/datasources/app_update_local_data_source.dart';
import 'package:wowcare/data/features/app_update/datasources/app_update_mock_data_sources.dart';
import 'package:wowcare/data/features/app_update/datasources/app_update_platform_data_source.dart';
import 'package:wowcare/data/features/app_update/datasources/app_update_remote_data_source.dart';
import 'package:wowcare/data/features/app_update/mappers/app_update_config_mapper.dart';
import 'package:wowcare/data/features/app_update/models/app_update_config_model.dart';
import 'package:wowcare/data/features/app_update/repositories/app_update_repository_impl.dart';
import 'package:wowcare/domain/features/app_update/entities/app_update_policy.dart';
import 'package:wowcare/domain/features/app_update/entities/app_update_status.dart';

class _FakePlatform implements AppUpdatePlatformDataSource {
  _FakePlatform({this.isIos = false, this.build = 25, this.opens = true});

  @override
  final bool isIos;
  final int build;
  final bool opens;
  final List<Uri> opened = <Uri>[];

  @override
  Future<InstalledApp> readInstalledApp() async => (
    versionName: '2.2.21',
    buildNumber: build,
    packageName: 'com.wiseowl.wowcareapp',
  );

  @override
  Future<bool> openExternal(Uri uri) async {
    opened.add(uri);
    return opens;
  }
}

class _FixedRemote implements AppUpdateRemoteDataSource {
  _FixedRemote(this.config);

  final AppUpdateConfigModel config;

  @override
  Future<AppUpdateConfigModel> getConfig({required bool refresh}) async =>
      config;
}

void main() {
  group('AppUpdateRemoteDataSourceImpl.parse', () {
    test('reads the feature/app-update schema', () {
      final AppUpdateConfigModel model = AppUpdateRemoteDataSourceImpl.parse('''
        {
          "android_minimum_build_version": 20,
          "android_latest_build_version": 26,
          "android_update_title": "  New version  ",
          "android_update_description": "Please update",
          "android_update_features": ["ignored"],
          "android_update_url": "https://play.google.com/store/apps/details?id=x",
          "ios_minimum_build_version": 21,
          "ios_latest_build_version": 27,
          "ios_latest_version_name": "2.3.0",
          "ios_update_url": "https://apps.apple.com/app/id1"
        }
      ''');
      expect(model.androidMinimumBuildVersion, 20);
      expect(model.androidLatestBuildVersion, 26);
      expect(model.androidUpdateTitle, 'New version');
      expect(model.androidUpdateDescription, 'Please update');
      expect(model.iosMinimumBuildVersion, 21);
      expect(model.iosLatestBuildVersion, 27);
      expect(model.iosLatestVersionName, '2.3.0');
      expect(model.iosUpdateUrl, 'https://apps.apple.com/app/id1');
    });

    test('accepts build numbers typed as strings', () {
      final AppUpdateConfigModel model = AppUpdateRemoteDataSourceImpl.parse(
        '{"android_minimum_build_version": " 26 ", "ios_latest_build_version": 27.0}',
      );
      expect(model.androidMinimumBuildVersion, 26);
      expect(model.iosLatestBuildVersion, 27);
    });

    test('missing and junk values fall back to asking nothing', () {
      final AppUpdateConfigModel model = AppUpdateRemoteDataSourceImpl.parse(
        '{"android_minimum_build_version": "soon", "ios_update_url": 42}',
      );
      expect(model, AppUpdateConfigModel.empty);
    });

    for (final String raw in <String>['', '   ', '{}', '[1, 2]', 'not json']) {
      test('"$raw" reads as the empty config', () {
        expect(
          AppUpdateRemoteDataSourceImpl.parse(raw),
          AppUpdateConfigModel.empty,
        );
      });
    }

    test('the empty config makes no demand of any real build', () {
      for (final StorePlatform store in StorePlatform.values) {
        expect(
          AppUpdateConfigModel.empty.toPolicy(store).requirementFor(1),
          AppUpdateRequirement.none,
        );
      }
    });
  });

  group('AppUpdateConfigMapper', () {
    const AppUpdateConfigModel model = AppUpdateConfigModel(
      androidMinimumBuildVersion: 20,
      androidLatestBuildVersion: 26,
      androidLatestVersionName: '2.3.0',
      iosMinimumBuildVersion: 21,
      iosLatestBuildVersion: 27,
      iosUpdateTitle: 'Custom title',
    );

    test('picks the half for each store', () {
      final AppUpdatePolicy android = model.toPolicy(StorePlatform.playStore);
      final AppUpdatePolicy ios = model.toPolicy(StorePlatform.appStore);
      expect((android.minimumBuild, android.latestBuild), (20, 26));
      expect((ios.minimumBuild, ios.latestBuild), (21, 27));
      expect(android.latestVersionName, '2.3.0');
      expect(ios.title, 'Custom title');
    });

    test('blank strings become null so the designed copy shows', () {
      final AppUpdatePolicy ios = model.toPolicy(StorePlatform.appStore);
      expect(ios.latestVersionName, isNull);
      expect(ios.storeUrl, isNull);
      expect(ios.message, isNull);
    });
  });

  group('AppUpdateRepositoryImpl.openStore', () {
    AppUpdateRepositoryImpl repository(_FakePlatform platform) =>
        AppUpdateRepositoryImpl(
          remote: _FixedRemote(AppUpdateConfigModel.empty),
          platform: platform,
          local: InMemoryAppUpdateLocalDataSource(),
        );

    test('opens the configured URL', () async {
      final _FakePlatform platform = _FakePlatform();
      expect(
        await repository(platform).openStore('https://example.com/x'),
        isTrue,
      );
      expect(platform.opened.single, Uri.parse('https://example.com/x'));
    });

    test('falls back to the Play listing for this package', () async {
      final _FakePlatform platform = _FakePlatform();
      await repository(platform).openStore(null);
      expect(
        platform.opened.single.toString(),
        'https://play.google.com/store/apps/details?id=com.wiseowl.wowcareapp',
      );
    });

    test('falls back to the App Store listing on iOS', () async {
      final _FakePlatform platform = _FakePlatform(isIos: true);
      await repository(platform).openStore(null);
      expect(platform.opened.single.host, 'apps.apple.com');
    });

    test('reports false when nothing opens', () async {
      final _FakePlatform platform = _FakePlatform(opens: false);
      expect(await repository(platform).openStore(null), isFalse);
    });
  });

  group('MockAppUpdateRemoteDataSource', () {
    Future<AppUpdateRequirement> requirementUnder(AppUpdateMock mode) async {
      final _FakePlatform platform = _FakePlatform(build: 25);
      final AppUpdateConfigModel config = await MockAppUpdateRemoteDataSource(
        mode,
        platform,
      ).getConfig(refresh: true);
      return config.toPolicy(StorePlatform.playStore).requirementFor(25);
    }

    test('optional mode offers the build after the installed one', () async {
      expect(
        await requirementUnder(AppUpdateMock.optional),
        AppUpdateRequirement.optional,
      );
    });

    test('required mode demands it', () async {
      expect(
        await requirementUnder(AppUpdateMock.required),
        AppUpdateRequirement.required,
      );
    });

    test('names the version it pretends to be', () async {
      final _FakePlatform platform = _FakePlatform();
      final AppUpdateConfigModel optional = await MockAppUpdateRemoteDataSource(
        AppUpdateMock.optional,
        platform,
      ).getConfig(refresh: false);
      final AppUpdateConfigModel required = await MockAppUpdateRemoteDataSource(
        AppUpdateMock.required,
        platform,
      ).getConfig(refresh: false);
      expect(optional.androidLatestVersionName, '2.3.0');
      expect(required.iosLatestVersionName, '3.0.0');
    });

    test('the switch is off unless a mode is chosen', () {
      expect(AppUpdateMock.inCode, AppUpdateMock.off);
      expect(AppUpdateMock.active, AppUpdateMock.off);
    });

    test('mock dismissals live for the session only', () async {
      final AppUpdateLocalDataSource local = InMemoryAppUpdateLocalDataSource();
      expect(await local.readDismissal(), isNull);
      await local.saveDismissal(latestBuild: 26, at: DateTime(2026));
      expect((await local.readDismissal())?.latestBuild, 26);
      expect(await InMemoryAppUpdateLocalDataSource().readDismissal(), isNull);
    });
  });
}
