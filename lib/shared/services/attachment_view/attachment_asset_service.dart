import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/utils/api_constants.dart';
import 'package:wowcare/core/utils/api_paths.dart';
import 'package:wowcare/shared/services/attachment_view/attachment_asset.dart';

/// Resolves asset codes to viewable files, with caching.
///
/// The read-side counterpart to `AttachmentUploadManager`: upload turns files
/// into asset codes, this turns asset codes back into files. Anything holding a
/// `List<String>` of asset codes — tasks, events, and whatever attaches files
/// next — goes through this rather than resolving URLs itself.
///
/// Three things it does that `AssetService.getMediaAssetUrlByCode` did
/// not, each of which was a visible bug:
///
/// * **Cache entries expire.** Delivery URLs are presigned and short-lived, so a
///   URL cached for the life of the app eventually renders as a broken image.
///   Entries older than [cacheTtl] are re-resolved.
/// * **Failure is a value, not an empty string.** The old resolver swallowed
///   every exception and returned `''`, so "still processing", "deleted" and
///   "network died" were indistinguishable — which is why the UI could only show
///   a spinner forever.
/// * **Metadata comes back too**, so a row can show name/type/size without a
///   second request.
class AttachmentAssetService {
  AttachmentAssetService(this._apiClient);

  final ApiClient _apiClient;

  /// How long a resolved URL is trusted. Comfortably inside the presign window
  /// the document service issues, so a cached URL is never handed out after it
  /// has expired.
  static const Duration cacheTtl = Duration(minutes: 10);

  /// Failed lookups are cached briefly too, so a broken asset in a long list
  /// does not re-request on every rebuild. Short, so Retry stays meaningful.
  static const Duration failureTtl = Duration(seconds: 20);

  /// A freshly completed asset can take a moment to become servable, so a
  /// not-ready result is retried a couple of times before being reported.
  /// Deliberately short: the old code polled silently for 15 seconds.
  static const int _readyRetries = 2;
  static const Duration _readyRetryDelay = Duration(milliseconds: 700);

  /// Concurrency cap for [resolveAll] so a long attachment list does not open a
  /// socket per file.
  static const int _maxConcurrent = 4;

  final Map<String, AttachmentAsset> _cache = {};
  final Map<String, Future<AttachmentAsset>> _inFlight = {};

  /// Cached value for [assetCode] if it is still fresh, else null.
  ///
  /// Lets a widget paint resolved content on its first frame instead of showing
  /// a loading state it does not need.
  AttachmentAsset? cached(String assetCode) {
    final code = assetCode.trim();
    final hit = _cache[code];
    if (hit == null) return null;
    return _isFresh(hit) ? hit : null;
  }

  /// Drops [assetCode] from the cache so the next resolve goes to the network.
  /// Call after a Retry, or when an image fails to load from a cached URL.
  void invalidate(String assetCode) => _cache.remove(assetCode.trim());

  void invalidateAll() => _cache.clear();

  /// Resolves one asset code. Never throws — failures come back on the result.
  ///
  /// Concurrent calls for the same code share one request, so a list of rows all
  /// asking at once costs a single round trip.
  Future<AttachmentAsset> resolve(
    String assetCode, {
    bool forceRefresh = false,
  }) async {
    final code = assetCode.trim();
    if (code.isEmpty) {
      return AttachmentAsset.failed(
        assetCode: code,
        failure: AttachmentAssetFailure.notFound,
        message: 'Empty asset code',
      );
    }

    if (forceRefresh) {
      _cache.remove(code);
    } else {
      final hit = cached(code);
      if (hit != null) return hit;
    }

    final existing = _inFlight[code];
    if (existing != null) return existing;

    Future<AttachmentAsset> run() async {
      try {
        final asset = await _resolveFromNetwork(code);
        _cache[code] = asset;
        return asset;
      } finally {
        _inFlight.remove(code);
      }
    }

    final future = run();
    _inFlight[code] = future;
    return future;
  }

  /// Resolves several codes, bounded-parallel, in the order given.
  ///
  /// Cache hits and in-flight sharing apply per code, so overlapping lists are
  /// cheap. Never throws — each entry carries its own failure.
  Future<List<AttachmentAsset>> resolveAll(
    List<String> assetCodes, {
    bool forceRefresh = false,
  }) async {
    final codes = assetCodes
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList(growable: false);
    if (codes.isEmpty) return const <AttachmentAsset>[];

    final results = List<AttachmentAsset?>.filled(codes.length, null);
    var next = 0;

    // Single-threaded Dart makes the counter handoff safe: nothing runs between
    // the read and the increment.
    Future<void> worker() async {
      while (true) {
        if (next >= codes.length) return;
        final index = next++;
        results[index] = await resolve(
          codes[index],
          forceRefresh: forceRefresh,
        );
      }
    }

    await Future.wait(
      List.generate(math.min(_maxConcurrent, codes.length), (_) => worker()),
    );
    return results.map((a) => a!).toList(growable: false);
  }

  bool _isFresh(AttachmentAsset asset) {
    final at = asset.resolvedAt;
    if (at == null) return false;
    final age = DateTime.now().difference(at);
    return age < (asset.hasFailed ? failureTtl : cacheTtl);
  }

  Future<AttachmentAsset> _resolveFromNetwork(String assetCode) async {
    final origin = ApiConstants.documentMsBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final endpoint = '$origin${ApiPaths.documentMediaAssetByCodePath(assetCode)}';

    for (var attempt = 0; attempt <= _readyRetries; attempt++) {
      try {
        final response = await _apiClient.client.get<dynamic>(endpoint);
        var asset = _parse(assetCode, response.data);

        // The media-asset payload carries metadata but no delivery URL, so the
        // URL is fetched separately. Skipped for a terminal failure, and for an
        // asset the service is still processing — there is nothing to sign yet.
        if (!asset.isReady &&
            asset.failure == AttachmentAssetFailure.notReady &&
            asset.status != 'PROCESSING') {
          final url = await _resolveDeliveryUrl(assetCode);
          if (url.isNotEmpty) {
            asset = AttachmentAsset(
              assetCode: assetCode,
              url: url,
              fileName: asset.fileName,
              contentType: asset.contentType,
              mediaType: asset.mediaType,
              sizeBytes: asset.sizeBytes,
              status: asset.status,
              resolvedAt: DateTime.now(),
            );
          }
        }
        // Resolved, or a permanent verdict → done.
        if (asset.isReady || asset.failure == AttachmentAssetFailure.notFound) {
          return asset;
        }
        // Not servable yet — give finalization a moment, then report honestly.
        if (attempt == _readyRetries) return asset;
      } on DioException catch (e) {
        final status = e.response?.statusCode ?? 0;
        if (status == 404 || status == 410) {
          return AttachmentAsset.failed(
            assetCode: assetCode,
            failure: AttachmentAssetFailure.notFound,
            message: 'HTTP $status',
            resolvedAt: DateTime.now(),
          );
        }
        if (attempt == _readyRetries) {
          return AttachmentAsset.failed(
            assetCode: assetCode,
            failure: AttachmentAssetFailure.error,
            message: _dioMessage(e),
            resolvedAt: DateTime.now(),
          );
        }
      } catch (e) {
        if (attempt == _readyRetries) {
          return AttachmentAsset.failed(
            assetCode: assetCode,
            failure: AttachmentAssetFailure.error,
            message: e.toString(),
            resolvedAt: DateTime.now(),
          );
        }
      }
      await Future<void>.delayed(_readyRetryDelay);
    }

    return AttachmentAsset.failed(
      assetCode: assetCode,
      failure: AttachmentAssetFailure.error,
      message: 'Unresolved',
      resolvedAt: DateTime.now(),
    );
  }

  /// Asks the document service for a downloadable URL for [assetCode].
  ///
  /// `GET /media-assets/{code}` returns metadata only — no URL — so this is the
  /// step that produces something the app can actually fetch bytes from. The URL
  /// points at storage/CDN, not at our backend, so the image download itself
  /// never touches the API.
  ///
  /// The request/response shape of this endpoint is not documented anywhere in
  /// the repo, so the parsing below accepts the shapes it is most likely to
  /// take: a list at `data`, a list under `data.assets`/`data.items`/`data.urls`,
  /// or a map keyed by asset code. **Confirm against the real endpoint** — if it
  /// differs, this method is the only place that needs changing.
  ///
  /// Returns an empty string rather than throwing, so a missing URL degrades to
  /// "not ready" instead of failing the whole resolve.
  Future<String> _resolveDeliveryUrl(String assetCode) async {
    final origin = ApiConstants.documentMsBaseUrl.replaceAll(RegExp(r'/+$'), '');
    try {
      final response = await _apiClient.client.post<dynamic>(
        '$origin${ApiPaths.documentMediaAssetsResolve}',
        data: <String, dynamic>{'assetCodes': <String>[assetCode]},
      );
      return _pickResolvedUrl(response.data, assetCode);
    } catch (_) {
      return '';
    }
  }

  /// Pulls the URL for [assetCode] out of whatever shape the resolve endpoint
  /// returned.
  static String _pickResolvedUrl(dynamic body, String assetCode) {
    if (body is! Map) return '';
    final data = body['data'];

    Iterable<Map<dynamic, dynamic>> rows() {
      if (data is List) return data.whereType<Map>();
      if (data is Map) {
        for (final key in const ['assets', 'items', 'urls', 'resolved']) {
          final nested = data[key];
          if (nested is List) return nested.whereType<Map>();
        }
        // A map keyed by asset code, whose values are either URLs or objects.
        final direct = data[assetCode];
        if (direct is Map) return [direct];
        if (direct is String && direct.trim().isNotEmpty) {
          return [
            {'url': direct},
          ];
        }
        return [data];
      }
      return const [];
    }

    for (final row in rows()) {
      final code = (row['assetCode'] ?? row['code'] ?? '').toString().trim();
      // A single-entry response need not echo the code back.
      if (code.isNotEmpty && code != assetCode) continue;
      final url = _pickUrl(row);
      if (url.isNotEmpty) return url;
    }
    return '';
  }

  /// Reads the media-asset payload into an [AttachmentAsset].
  ///
  /// The URL can arrive under several keys and may live on a variant rather than
  /// the asset itself, so every known shape is tried before giving up.
  AttachmentAsset _parse(String assetCode, dynamic body) {
    final now = DateTime.now();
    if (body is! Map) {
      return AttachmentAsset.failed(
        assetCode: assetCode,
        failure: AttachmentAssetFailure.error,
        message: 'Unexpected media-asset response format',
        resolvedAt: now,
      );
    }
    final data = body['data'];
    if (data is! Map) {
      return AttachmentAsset.failed(
        assetCode: assetCode,
        failure: AttachmentAssetFailure.notFound,
        message: 'No asset payload',
        resolvedAt: now,
      );
    }

    final url = _pickUrl(data);
    final asset = AttachmentAsset(
      assetCode: assetCode,
      url: url,
      fileName: (data['fileName'] ?? '').toString().trim(),
      contentType: (data['contentType'] ?? '').toString().trim().toLowerCase(),
      mediaType: (data['mediaType'] ?? '').toString().trim().toUpperCase(),
      sizeBytes: _asInt(data['sizeBytes']),
      status: (data['status'] ?? '').toString().trim().toUpperCase(),
      resolvedAt: now,
    );

    if (url.isEmpty) {
      return AttachmentAsset(
        assetCode: assetCode,
        fileName: asset.fileName,
        contentType: asset.contentType,
        mediaType: asset.mediaType,
        sizeBytes: asset.sizeBytes,
        status: asset.status,
        failure: asset.status == 'FAILED'
            ? AttachmentAssetFailure.notFound
            : AttachmentAssetFailure.notReady,
        failureMessage: 'No delivery URL on the payload',
        resolvedAt: now,
      );
    }
    return asset;
  }

  static String _pickUrl(Map<dynamic, dynamic> data) {
    String fromMap(Map<dynamic, dynamic> map) {
      for (final key in const [
        'deliveryUrl',
        'artifactUrl',
        'url',
        'originalDownloadUrl',
        'thumbnailUrl',
      ]) {
        final value = (map[key] ?? '').toString().trim();
        if (value.isNotEmpty) return value;
      }
      return '';
    }

    final direct = fromMap(data);
    if (direct.isNotEmpty) return direct;

    final variants = data['variants'];
    if (variants is List) {
      // Prefer the variant the service marks default, then anything usable.
      for (final row in variants.whereType<Map>()) {
        if ((row['defaultVariant'] ?? false).toString().toLowerCase() ==
            'true') {
          final url = fromMap(row);
          if (url.isNotEmpty) return url;
        }
      }
      for (final row in variants.whereType<Map>()) {
        final url = fromMap(row);
        if (url.isNotEmpty) return url;
      }
    }
    return '';
  }

  static int _asInt(Object? raw) {
    if (raw is num) return raw.toInt();
    return int.tryParse((raw ?? '').toString()) ?? 0;
  }

  static String _dioMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map) {
      final message = (data['message'] ?? '').toString().trim();
      if (message.isNotEmpty) return message;
    }
    return e.message?.trim() ?? 'Request failed';
  }
}
