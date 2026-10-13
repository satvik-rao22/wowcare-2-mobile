import 'dart:async';
import 'dart:convert';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

/// Metadata needed to draw a link preview. Only [url] is guaranteed; the UI
/// decides how to lay out whatever else is present.
class UrlPreviewData {
  const UrlPreviewData({
    required this.url,
    this.title,
    this.description,
    this.imageUrl,
    this.siteName,
  });

  final String url;
  final String? title;
  final String? description;
  final String? imageUrl;
  final String? siteName;
}

/// Outcome of [UrlPreviewResolver.resolve]. Switch on it in the UI:
/// [UrlPreviewFound] → draw a card, [UrlPreviewNotFound] → show the plain URL.
sealed class UrlPreviewResult {
  const UrlPreviewResult();
}

class UrlPreviewFound extends UrlPreviewResult {
  const UrlPreviewFound(this.data);
  final UrlPreviewData data;
}

class UrlPreviewNotFound extends UrlPreviewResult {
  const UrlPreviewNotFound();
}

/// Resolves Open Graph / Twitter / HTML metadata for a URL.
///
/// Results are cached in memory for the app session, and concurrent calls for
/// the same URL share one request — chat lists rebuild bubbles constantly, so
/// the same link must not be fetched repeatedly. Network errors are NOT cached,
/// so a link opened offline can still resolve later.
///
/// Temporary: to be replaced by backend-provided preview metadata.
class UrlPreviewResolver {
  UrlPreviewResolver._();

  static const _timeout = Duration(seconds: 6);
  // YouTube puts its OG tags ~700KB into a huge <head>.
  static const _maxChars = 1024 * 1024;
  // Many sites (X, Instagram, YouTube…) only serve OG tags to crawler UAs.
  static const _userAgent =
      'Mozilla/5.0 (compatible; facebookexternalhit/1.1; +http://www.facebook.com/externalhit_uatext.php)';

  static final Map<String, Future<UrlPreviewResult>> _cache = {};
  static final Map<String, UrlPreviewResult> _resolved = {};

  /// Already-resolved result for [url], or null. Lets the UI paint a cached
  /// preview on the first frame instead of flashing a loading state.
  static UrlPreviewResult? cached(String url) => _resolved[url];

  static Future<UrlPreviewResult> resolve(String url) {
    return _cache[url] ??= _fetch(url).then(
      (result) => _resolved[url] = result,
      onError: (Object _) {
        // Timeout, DNS, TLS… — forget it so the next call retries.
        _cache.remove(url);
        return const UrlPreviewNotFound();
      },
    );
  }

  static Future<UrlPreviewResult> _fetch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      return const UrlPreviewNotFound();
    }

    final client = http.Client();
    try {
      final request = http.Request('GET', uri)
        ..headers['User-Agent'] = _userAgent
        ..headers['Accept'] = 'text/html,image/*;q=0.8,*/*;q=0.5';
      final response = await client.send(request).timeout(_timeout);
      if (response.statusCode != 200) return const UrlPreviewNotFound();

      final finalUrl = response.request?.url ?? uri;
      final contentType = response.headers['content-type'] ?? '';

      // Direct image link — the image itself is the preview.
      if (contentType.startsWith('image/')) {
        return UrlPreviewFound(
          UrlPreviewData(url: url, imageUrl: finalUrl.toString()),
        );
      }
      if (!contentType.contains('html')) return const UrlPreviewNotFound();

      final html = await _readHead(response.stream).timeout(_timeout);
      return _parse(url, finalUrl, html_parser.parse(html));
    } finally {
      client.close();
    }
  }

  /// Reads the body only until `</head>` (or [_maxChars]) — metadata lives in
  /// the head, so there's no need to download the whole page.
  static Future<String> _readHead(Stream<List<int>> stream) async {
    final buffer = StringBuffer();
    await for (final chunk in stream.transform(
      const Utf8Decoder(allowMalformed: true),
    )) {
      buffer.write(chunk);
      if (buffer.length >= _maxChars ||
          chunk.toLowerCase().contains('</head>')) {
        break;
      }
    }
    return buffer.toString();
  }

  static UrlPreviewResult _parse(String url, Uri baseUrl, dom.Document doc) {
    String? meta(String key) {
      final el =
          doc.querySelector('meta[property="$key"]') ??
          doc.querySelector('meta[name="$key"]');
      final value = el?.attributes['content']?.trim();
      return (value == null || value.isEmpty) ? null : value;
    }

    final title =
        meta('og:title') ??
        meta('twitter:title') ??
        _nonEmpty(doc.querySelector('title')?.text);
    final description =
        meta('og:description') ??
        meta('twitter:description') ??
        meta('description');
    final image =
        meta('og:image') ??
        meta('og:image:url') ??
        meta('twitter:image') ??
        meta('twitter:image:src');

    if (title == null && description == null && image == null) {
      return const UrlPreviewNotFound();
    }

    return UrlPreviewFound(
      UrlPreviewData(
        url: url,
        title: title,
        description: description,
        // og:image is often relative ("/img/cover.png") — resolve against the
        // post-redirect page URL.
        imageUrl: image == null ? null : baseUrl.resolve(image).toString(),
        siteName: meta('og:site_name') ?? baseUrl.host,
      ),
    );
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
