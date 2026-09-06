import 'package:json_annotation/json_annotation.dart';

part 'media_asset_resolve_response.g.dart';

/// The `{data: {assets: [...]}}` response from the media-asset resolve
/// endpoint, which turns an asset code into a download URL.
@JsonSerializable(createToJson: false)
class MediaAssetResolveResponse {
  const MediaAssetResolveResponse({this.data});

  factory MediaAssetResolveResponse.fromJson(Map<String, dynamic> json) =>
      _$MediaAssetResolveResponseFromJson(json);

  /// Decoded leniently: the old dynamic `responseData['data']?['assets']`
  /// accepted any map, so a `Map<dynamic, dynamic>` must not fail here either.
  @JsonKey(fromJson: MediaAssetResolveData.fromAny)
  final MediaAssetResolveData? data;

  /// The first asset in the response, or `null` when there is none.
  ///
  /// Every caller only ever wants the first: the endpoint is asked to resolve
  /// exactly one asset code.
  MediaAsset? get firstAsset {
    final assets = data?.assets;
    if (assets == null || assets.isEmpty) return null;
    return MediaAsset.fromJson(assets.first as Map<String, dynamic>);
  }
}

@JsonSerializable(createToJson: false)
class MediaAssetResolveData {
  const MediaAssetResolveData({this.assets});

  factory MediaAssetResolveData.fromJson(Map<String, dynamic> json) =>
      _$MediaAssetResolveDataFromJson(json);

  /// `null` for anything that is not a map, rather than an error.
  static MediaAssetResolveData? fromAny(Object? raw) =>
      raw is Map ? MediaAssetResolveData(assets: raw['assets'] as List?) : null;

  final List<dynamic>? assets;
}

/// One media asset.
///
/// Every URL-bearing field is `Object?` rather than `String?` on purpose: the
/// media service has been observed to send non-string values here, and the
/// resolve logic stringifies rather than casts, so a wrong type must not throw
/// during decoding.
@JsonSerializable(createToJson: false)
class MediaAsset {
  const MediaAsset({
    this.status,
    this.deliveryUrl,
    this.artifactUrl,
    this.url,
    this.originalDownloadUrl,
    this.variants = const [],
  });

  factory MediaAsset.fromJson(Map<String, dynamic> json) =>
      _$MediaAssetFromJson(json);

  final Object? status;
  final Object? deliveryUrl;
  final Object? artifactUrl;
  final Object? url;
  final Object? originalDownloadUrl;

  @JsonKey(fromJson: MediaAssetVariant.listFromJson)
  final List<MediaAssetVariant> variants;

  /// The status, upper-cased and trimmed — `''` when absent.
  String get normalizedStatus => (status ?? '').toString().trim().toUpperCase();

  /// Whether processing has produced something downloadable yet.
  ///
  /// A delivery URL directly on the asset counts, as does any variant with a
  /// delivery or artifact URL.
  bool get hasProcessedVariant {
    if (_nonEmpty(deliveryUrl).isNotEmpty) return true;
    for (final variant in variants) {
      if (_nonEmpty(variant.deliveryUrl).isNotEmpty ||
          _nonEmpty(variant.artifactUrl).isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  /// The best download URL this asset offers, or `null` if it has none.
  ///
  /// Preference order: the default variant, then any other variant, then the
  /// asset's own URL fields, then the unprocessed original.
  String? get downloadUrl {
    for (final variant in variants) {
      if (!variant.isDefault) continue;
      final fromDefault = variant.bestUrl;
      if (fromDefault.isNotEmpty) return fromDefault;
    }
    for (final variant in variants) {
      final any = variant.bestUrl;
      if (any.isNotEmpty) return any;
    }

    final direct = _pick([deliveryUrl, artifactUrl, url]);
    if (direct.isNotEmpty) return direct;

    final original = _nonEmpty(originalDownloadUrl);
    if (original.isNotEmpty) return original;

    return null;
  }

  static String _nonEmpty(Object? raw) => (raw ?? '').toString().trim();

  static String _pick(List<Object?> candidates) {
    for (final raw in candidates) {
      final value = _nonEmpty(raw);
      if (value.isNotEmpty) return value;
    }
    return '';
  }
}

@JsonSerializable(createToJson: false)
class MediaAssetVariant {
  const MediaAssetVariant({
    this.deliveryUrl,
    this.artifactUrl,
    this.url,
    this.defaultVariant,
  });

  factory MediaAssetVariant.fromJson(Map<String, dynamic> json) =>
      _$MediaAssetVariantFromJson(json);

  /// Decodes the `variants` array, skipping anything that is not a map —
  /// entries of other shapes are ignored rather than treated as an error.
  static List<MediaAssetVariant> listFromJson(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (row) => MediaAssetVariant(
            deliveryUrl: row['deliveryUrl'],
            artifactUrl: row['artifactUrl'],
            url: row['url'],
            defaultVariant: row['defaultVariant'],
          ),
        )
        .toList();
  }

  final Object? deliveryUrl;
  final Object? artifactUrl;
  final Object? url;
  final Object? defaultVariant;

  /// Stringified rather than cast: the flag has been seen as both a bool and
  /// the string `"true"`.
  bool get isDefault =>
      (defaultVariant ?? false).toString().toLowerCase() == 'true';

  String get bestUrl => MediaAsset._pick([deliveryUrl, artifactUrl, url]);
}
