import 'dart:io';

import 'package:flutter/foundation.dart';

/// How the bytes behind an [AppImageSource] must be decoded.
enum AppImageFormat { raster, svg, lottie }

/// Where an image comes from and how to decode it.
///
/// Most callers never build one directly — [AppImage] accepts a plain `String`
/// (URL / asset path / file path), `Uint8List` or `File` and runs it through
/// [AppImageSource.from]. Build one explicitly only when auto-detection cannot
/// know the answer, e.g. a network SVG whose URL has no `.svg` extension:
///
/// ```dart
/// AppImage(source: AppImageSource.network(url, format: AppImageFormat.svg))
/// ```
sealed class AppImageSource {
  const AppImageSource(this.format);

  final AppImageFormat format;

  const factory AppImageSource.network(
    String url, {
    AppImageFormat format,
    Map<String, String>? headers,
    String? cacheKey,
  }) = NetworkAppImageSource;

  const factory AppImageSource.asset(String path, {AppImageFormat format}) =
      AssetAppImageSource;

  const factory AppImageSource.file(String path, {AppImageFormat format}) =
      FileAppImageSource;

  const factory AppImageSource.memory(
    Uint8List bytes, {
    AppImageFormat format,
  }) = MemoryAppImageSource;

  /// Detects the source from a loosely-typed value. Returns `null` for null,
  /// blank strings and unsupported types so the caller can show its error
  /// state instead of throwing mid-build.
  ///
  /// Detection is by prefix, never by substring: a presigned URL such as
  /// `https://…/media-assets/x.png?X-Amz-…` contains "asset" and maybe ".svg"
  /// in its query, so `contains()` checks misroute it.
  static AppImageSource? from(Object? value) {
    return switch (value) {
      null => null,
      final AppImageSource source => source,
      final Uint8List bytes =>
        bytes.isEmpty
            ? null
            : MemoryAppImageSource(bytes, format: _formatFromBytes(bytes)),
      final File file => FileAppImageSource(
        file.path,
        format: _formatFromPath(file.path),
      ),
      final String raw => _fromString(raw),
      _ => _unsupported(value),
    };
  }

  static AppImageSource? _fromString(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;

    final lower = value.toLowerCase();
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      return NetworkAppImageSource(value, format: _formatFromPath(value));
    }
    if (lower.startsWith('file://')) {
      final path = Uri.parse(value).toFilePath();
      return FileAppImageSource(path, format: _formatFromPath(path));
    }
    if (lower.startsWith('assets/') || lower.startsWith('packages/')) {
      return AssetAppImageSource(value, format: _formatFromPath(value));
    }
    // Absolute paths from image_picker / path_provider / the media staging dir.
    if (value.startsWith('/') || RegExp(r'^[a-zA-Z]:[\\/]').hasMatch(value)) {
      return FileAppImageSource(value, format: _formatFromPath(value));
    }
    return _unsupported(value);
  }

  static AppImageSource? _unsupported(Object value) {
    if (kDebugMode) {
      debugPrint(
        'AppImage: cannot resolve source of type ${value.runtimeType}: '
        '"$value". Pass a URL, an assets/ path, an absolute file path, '
        'Uint8List, File, or an explicit AppImageSource.',
      );
    }
    return null;
  }

  /// Uses the URI *path* only, so query strings on signed URLs are ignored.
  static AppImageFormat _formatFromPath(String value) {
    final path = (Uri.tryParse(value)?.path ?? value).toLowerCase();
    if (path.endsWith('.svg')) return AppImageFormat.svg;
    if (path.endsWith('.json')) return AppImageFormat.lottie;
    return AppImageFormat.raster;
  }

  /// Sniffs the first non-whitespace bytes: SVG is XML, Lottie is JSON.
  static AppImageFormat _formatFromBytes(Uint8List bytes) {
    final head = String.fromCharCodes(bytes.take(256)).trimLeft();
    if (head.startsWith('<svg') || head.startsWith('<?xml')) {
      return AppImageFormat.svg;
    }
    if (head.startsWith('{')) return AppImageFormat.lottie;
    return AppImageFormat.raster;
  }
}

final class NetworkAppImageSource extends AppImageSource {
  const NetworkAppImageSource(
    this.url, {
    AppImageFormat format = AppImageFormat.raster,
    this.headers,
    this.cacheKey,
  }) : super(format);

  final String url;
  final Map<String, String>? headers;

  /// Disk/memory cache identity. Defaults to [stableCacheKey], which drops
  /// signature params so a re-signed URL for the same object hits the cache.
  final String? cacheKey;

  String get effectiveCacheKey => cacheKey ?? stableCacheKey(url);

  /// Query params that change every time a URL is re-signed (S3, CloudFront,
  /// Azure SAS) without the underlying object changing.
  static const Set<String> _signatureParams = {
    'x-amz-algorithm',
    'x-amz-credential',
    'x-amz-date',
    'x-amz-expires',
    'x-amz-security-token',
    'x-amz-signature',
    'x-amz-signedheaders',
    'expires',
    'signature',
    'key-pair-id',
    'policy',
    'se',
    'sig',
    'sp',
    'st',
    'sv',
  };

  static String stableCacheKey(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasQuery) return url;
    final kept = Map<String, String>.fromEntries(
      uri.queryParameters.entries.where(
        (e) => !_signatureParams.contains(e.key.toLowerCase()),
      ),
    );
    final base = url.split('?').first;
    return kept.isEmpty ? base : '$base?${Uri(queryParameters: kept).query}';
  }
}

final class AssetAppImageSource extends AppImageSource {
  const AssetAppImageSource(
    this.path, {
    AppImageFormat format = AppImageFormat.raster,
  }) : super(format);

  final String path;
}

final class FileAppImageSource extends AppImageSource {
  const FileAppImageSource(
    this.path, {
    AppImageFormat format = AppImageFormat.raster,
  }) : super(format);

  final String path;
}

final class MemoryAppImageSource extends AppImageSource {
  const MemoryAppImageSource(
    this.bytes, {
    AppImageFormat format = AppImageFormat.raster,
  }) : super(format);

  final Uint8List bytes;
}
