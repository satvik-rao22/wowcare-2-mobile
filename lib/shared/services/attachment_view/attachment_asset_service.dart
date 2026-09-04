import 'dart:collection';

import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/shared/services/attachment_view/attachment_asset.dart';

/// Turns asset codes into viewable files.
///
/// The read-side counterpart to `AttachmentUploadManager`: upload turns files
/// into asset codes, this turns asset codes back into files. Anything holding a
/// `List<String>` of asset codes — tasks, events, and whatever attaches files
/// next — goes through this instead of resolving URLs itself.
///
/// **One request for the whole list.** `POST /media-assets/resolve` takes an
/// array, so N attachments cost one round trip, and codes already cached are not
/// re-requested at all.
///
/// ## Two caching layers, only one of which lives here
///
/// 1. **code → metadata + URLs** (this class). Bounded in-memory LRU. The URLs
///    it holds ([AttachmentAsset.thumbnailUrl], [AttachmentAsset.deliveryUrl])
///    are unsigned CloudFront links, so they stay valid for the life of the app
///    and need no expiry handling.
/// 2. **URL → bytes** (`cached_network_image`, used by the view widgets). Its
///    own memory + disk LRU already does this well, so there is deliberately no
///    second byte cache here — reimplementing it would only add a way to leak
///    memory.
///
/// The presigned [AttachmentAsset.downloadUrl] is the exception: it expires in
/// minutes, so callers that need the original should re-resolve with
/// `forceRefresh` rather than reuse a cached one.
class AttachmentAssetService {
  AttachmentAssetService(this._apiClient);

  final ApiClient _apiClient;

  /// Entries kept before the oldest is evicted. Each is a few hundred bytes of
  /// metadata, so this is a small, predictable ceiling that keeps long sessions
  /// from growing without bound.
  static const int maxCacheEntries = 300;

  /// Insertion-ordered so the oldest entry is the first key — re-inserting on
  /// read is what makes it least-recently-*used* rather than -added.
  final LinkedHashMap<String, AttachmentAsset> _cache = LinkedHashMap();

  int get cacheSize => _cache.length;

  /// Cached asset for [assetCode], or null. Lets a widget paint on its first
  /// frame with no loading state.
  AttachmentAsset? cached(String assetCode) {
    final code = assetCode.trim();
    final hit = _cache.remove(code);
    if (hit == null) return null;
    _cache[code] = hit; // touch → most recently used
    return hit;
  }

  void invalidate(String assetCode) => _cache.remove(assetCode.trim());

  void clearCache() => _cache.clear();

  /// Resolves one code. Convenience over [resolveAll]; never throws.
  Future<AttachmentAsset> resolve(
    String assetCode, {
    bool forceRefresh = false,
  }) async {
    final results = await resolveAll([assetCode], forceRefresh: forceRefresh);
    return results.isEmpty
        ? AttachmentAsset.missing(assetCode.trim())
        : results.first;
  }

  /// Resolves every code in one request, in the order given.
  ///
  /// Never throws: a code the service reports under `missingAssetCodes`, and any
  /// code at all if the request fails, comes back as
  /// [AttachmentAsset.missing] so the UI can say so per row.
  Future<List<AttachmentAsset>> resolveAll(
    List<String> assetCodes, {
    bool forceRefresh = false,
  }) async {
    final codes = <String>[];
    for (final raw in assetCodes) {
      final code = raw.trim();
      if (code.isNotEmpty && !codes.contains(code)) codes.add(code);
    }
    if (codes.isEmpty) return const <AttachmentAsset>[];

    if (forceRefresh) {
      for (final code in codes) {
        _cache.remove(code);
      }
    }

    // One request for everything not already cached.
    final needed = codes.where((c) => cached(c) == null).toList();
    if (needed.isNotEmpty) await _fetch(needed);

    // Read back through the cache so the order matches the caller's list. A code
    // that isn't cached was reported missing or its request failed — both render
    // as "unavailable", and neither is cached, so a retry genuinely re-asks.
    return codes
        .map((code) => cached(code) ?? AttachmentAsset.missing(code))
        .toList(growable: false);
  }

  /// One `POST /media-assets/resolve` for [codes]; result keyed by asset code.
  Future<Map<String, AttachmentAsset>> _fetch(List<String> codes) async {
    final origin = ApiConstants.documentMsBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final byCode = <String, AttachmentAsset>{};

    try {
      final response = await _apiClient.client.post<dynamic>(
        '$origin${ApiPaths.documentMediaAssetsResolve}',
        data: <String, dynamic>{'assetCodes': codes},
      );

      final body = response.data;
      final data = body is Map ? body['data'] : null;
      if (data is Map) {
        final assets = data['assets'];
        if (assets is List) {
          for (final row in assets.whereType<Map>()) {
            final asset = AttachmentAsset.fromJson(row);
            if (asset.assetCode.isNotEmpty) byCode[asset.assetCode] = asset;
          }
        }
        final missing = data['missingAssetCodes'];
        if (missing is List) {
          for (final raw in missing) {
            final code = raw.toString().trim();
            if (code.isNotEmpty) byCode[code] = AttachmentAsset.missing(code);
          }
        }
      }
    } catch (_) {
      // Leave byCode empty — every requested code becomes `missing`, which the
      // UI renders as an explicit failure with a Retry rather than a spinner.
    }

    for (final code in codes) {
      final asset = byCode[code] ?? AttachmentAsset.missing(code);
      byCode[code] = asset;
      // Only cache a real answer. A failed request must not poison the cache,
      // or Retry would keep returning the same failure without asking again.
      if (!asset.isMissing) _remember(code, asset);
    }
    return byCode;
  }

  void _remember(String code, AttachmentAsset asset) {
    _cache.remove(code);
    _cache[code] = asset;
    while (_cache.length > maxCacheEntries) {
      _cache.remove(_cache.keys.first);
    }
  }
}
