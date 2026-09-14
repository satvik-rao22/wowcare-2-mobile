import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/reports/models/media_asset_resolve_response.dart';
import 'package:wowcare/data/features/reports/models/recent_reports_response.dart';
import 'package:wowcare/data/features/reports/models/student_tags_response.dart';

/// Covers the response shapes that used to be picked apart with map lookups
/// inside `ReportsRemoteDataSourceImpl` (§8). The behaviour is deliberately
/// tolerant, so the malformed cases matter as much as the happy ones.
void main() {
  group('RecentReportsResponse', () {
    Map<String, dynamic> report(String id) => {
      'reportId': id,
      'reportType': 'STUDENT_ABSENT',
      'generatedAt': '2026-01-02T00:00:00Z',
    };

    test('reads the `{reports: [...]}` shape', () {
      final models = RecentReportsResponse.fromJson({
        'reports': [report('a'), report('b')],
      }).toModels();

      expect(models.map((m) => m.reportId), ['a', 'b']);
    });

    test('reads the `{data: [...]}` shape', () {
      final models = RecentReportsResponse.fromJson({
        'data': [report('a')],
      }).toModels();

      expect(models.single.reportId, 'a');
    });

    test('reads the `{data: {reports: [...]}}` shape', () {
      final models = RecentReportsResponse.fromJson({
        'data': {
          'reports': [report('a')],
        },
      }).toModels();

      expect(models.single.reportId, 'a');
    });

    test('`reports` wins when both shapes are present', () {
      final models = RecentReportsResponse.fromJson({
        'reports': [report('top')],
        'data': [report('nested')],
      }).toModels();

      expect(models.single.reportId, 'top');
    });

    test('no recognised shape yields an empty list, not an error', () {
      expect(RecentReportsResponse.fromJson(const {}).toModels(), isEmpty);
      expect(
        RecentReportsResponse.fromJson(const {'data': 'nonsense'}).toModels(),
        isEmpty,
      );
      expect(
        RecentReportsResponse.fromJson(const {'data': {}}).toModels(),
        isEmpty,
      );
    });

    test('an empty list stays empty', () {
      expect(
        RecentReportsResponse.fromJson(const {'reports': []}).toModels(),
        isEmpty,
      );
    });
  });

  group('StudentTagsResponse', () {
    test('reads the tag list', () {
      expect(
        StudentTagsResponse.fromJson(const {
          'tags': ['Allergy', 'Bus'],
        }).names,
        ['Allergy', 'Bus'],
      );
    });

    test('stringifies non-string entries rather than throwing', () {
      expect(
        StudentTagsResponse.fromJson(const {
          'tags': [1, true],
        }).names,
        ['1', 'true'],
      );
    });

    test('a missing or empty list yields no tags', () {
      expect(StudentTagsResponse.fromJson(const {}).names, isEmpty);
      expect(StudentTagsResponse.fromJson(const {'tags': []}).names, isEmpty);
    });
  });

  group('MediaAssetResolveResponse', () {
    MediaAssetResolveResponse wrap(List<dynamic> assets) =>
        MediaAssetResolveResponse.fromJson({
          'data': {'assets': assets},
        });

    test('returns the first asset', () {
      final asset = wrap([
        {'status': 'ready'},
        {'status': 'PENDING'},
      ]).firstAsset;

      expect(asset!.normalizedStatus, 'READY');
    });

    test('no data, no assets key and an empty list all give null', () {
      expect(MediaAssetResolveResponse.fromJson(const {}).firstAsset, isNull);
      expect(
        MediaAssetResolveResponse.fromJson(const {
          'data': <String, dynamic>{},
        }).firstAsset,
        isNull,
      );
      expect(wrap(const []).firstAsset, isNull);
    });

    test('a non-map `data` is tolerated, as it was before', () {
      expect(
        MediaAssetResolveResponse.fromJson(const {
          'data': 'nonsense',
        }).firstAsset,
        isNull,
      );
    });

    test('a loosely-typed `data` map is still read', () {
      expect(
        MediaAssetResolveResponse.fromJson({
          'data': <dynamic, dynamic>{
            'assets': [
              <String, dynamic>{'status': 'READY'},
            ],
          },
        }).firstAsset!.normalizedStatus,
        'READY',
      );
    });

    test('a missing status normalises to the empty string', () {
      expect(wrap([<String, dynamic>{}]).firstAsset!.normalizedStatus, '');
    });

    test('status is trimmed and upper-cased', () {
      expect(
        wrap([
          {'status': '  ready  '},
        ]).firstAsset!.normalizedStatus,
        'READY',
      );
    });
  });

  group('MediaAsset.downloadUrl preference order', () {
    MediaAsset asset(Map<String, dynamic> json) => MediaAsset.fromJson(json);

    test('the default variant wins over other variants', () {
      expect(
        asset({
          'variants': [
            {'deliveryUrl': 'other'},
            {'defaultVariant': true, 'deliveryUrl': 'default'},
          ],
        }).downloadUrl,
        'default',
      );
    });

    test('a `"true"` string counts as the default variant', () {
      expect(
        asset({
          'variants': [
            {'deliveryUrl': 'other'},
            {'defaultVariant': 'TRUE', 'deliveryUrl': 'default'},
          ],
        }).downloadUrl,
        'default',
      );
    });

    test('within a variant, delivery beats artifact beats url', () {
      expect(
        asset({
          'variants': [
            {
              'artifactUrl': 'artifact',
              'url': 'url',
              'deliveryUrl': 'delivery',
            },
          ],
        }).downloadUrl,
        'delivery',
      );
      expect(
        asset({
          'variants': [
            {'url': 'url', 'artifactUrl': 'artifact'},
          ],
        }).downloadUrl,
        'artifact',
      );
    });

    test('a default variant with no usable url falls through to the next', () {
      expect(
        asset({
          'variants': [
            {'defaultVariant': true, 'deliveryUrl': '   '},
            {'deliveryUrl': 'other'},
          ],
        }).downloadUrl,
        'other',
      );
    });

    test('asset-level fields are used when no variant has a url', () {
      expect(
        asset({
          'variants': [<String, dynamic>{}],
          'artifactUrl': 'asset-artifact',
        }).downloadUrl,
        'asset-artifact',
      );
    });

    test('the original download url is the last resort', () {
      expect(
        asset({'originalDownloadUrl': 'original'}).downloadUrl,
        'original',
      );
    });

    test('an asset with nothing usable returns null', () {
      expect(asset(const {}).downloadUrl, isNull);
      expect(asset(const {'deliveryUrl': '  '}).downloadUrl, isNull);
    });

    test('non-map entries in `variants` are skipped, not fatal', () {
      expect(
        asset({
          'variants': [
            'nonsense',
            42,
            {'deliveryUrl': 'good'},
          ],
        }).downloadUrl,
        'good',
      );
    });

    test('a non-list `variants` is ignored', () {
      expect(
        asset({'variants': 'nonsense', 'deliveryUrl': 'direct'}).downloadUrl,
        'direct',
      );
    });

    test('non-string url values are stringified rather than cast', () {
      expect(asset({'deliveryUrl': 1234}).downloadUrl, '1234');
    });
  });

  group('MediaAsset.hasProcessedVariant', () {
    MediaAsset asset(Map<String, dynamic> json) => MediaAsset.fromJson(json);

    test('true when the asset itself has a delivery url', () {
      expect(asset(const {'deliveryUrl': 'x'}).hasProcessedVariant, isTrue);
    });

    test('true when any variant has a delivery or artifact url', () {
      expect(
        asset({
          'variants': [
            {'artifactUrl': 'x'},
          ],
        }).hasProcessedVariant,
        isTrue,
      );
    });

    test('a plain `url` on a variant does not count as processed', () {
      expect(
        asset({
          'variants': [
            {'url': 'x'},
          ],
        }).hasProcessedVariant,
        isFalse,
      );
    });

    test('blank urls do not count', () {
      expect(
        asset({
          'deliveryUrl': '  ',
          'variants': [
            {'deliveryUrl': '', 'artifactUrl': '   '},
          ],
        }).hasProcessedVariant,
        isFalse,
      );
    });

    test('false for an empty asset', () {
      expect(asset(const {}).hasProcessedVariant, isFalse);
    });
  });
}
