import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:wowcare/core/util/server_time_service.dart';

/// Supported preview types for composer/message cards.
enum PreviewKind { url, email, phone }

class PreviewMatch {
  const PreviewMatch({required this.kind, required this.value});

  final PreviewKind kind;
  final String value;
}

/// Enriches HTML message content with auto-linked URLs / emails, and
/// provides a single entry-point for launching links.
///
/// Clean Architecture note: this is a pure presentation utility with no
/// dependency on domain or data layers.
class MessageContentProcessor {
  MessageContentProcessor._();

  // ── Patterns ───────────────────────────────────────────────────────────────

  static final RegExp _urlPattern = RegExp(
    '(?:https?://[^\\s<>()"\']+|www\\.[a-zA-Z0-9\\-]+\\.[a-zA-Z]{2,}[^\\s<>()"\']*)',
    caseSensitive: false,
  );

  static final RegExp _emailPattern = RegExp(
    r'(?:[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,})',
    caseSensitive: false,
  );

  static final RegExp _phonePattern = RegExp(
    r'(?<!\w)(?:\+|00)?(?:\(?\d{2,4}\)?[\s.-]?){2,4}\d{2,4}(?!\w)',
    caseSensitive: false,
  );

  /// Matches bare URLs, email addresses, and phone numbers (in that order).
  /// URL must be matched first so that a phone-like sequence inside a URL
  /// path is not double-matched.
  static final _linkPattern = RegExp(
    // URLs: stop at whitespace, HTML angle-brackets, quotes or parentheses
    r'(?:https?://[^\s<>()"]+|www\.[a-zA-Z0-9\-]+\.[a-zA-Z]{2,}[^\s<>()"]*)'
    r'|'
    // Email addresses
    r'(?:[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,})'
    r'|'
    // Phone numbers: optional leading + or 00, then 7-15 digits with optional
    // spaces, dashes, dots, or parentheses as separators.
    r'(?:\+|00)?(?:\d[\s\-.]?){7,14}\d',
    caseSensitive: false,
  );

  // ── HTML enrichment ────────────────────────────────────────────────────────

  /// Returns enriched HTML where bare URLs and email addresses in text nodes
  /// are wrapped in tappable `<a href="">` tags.
  ///
  /// Content already inside `<a>…</a>` elements is left untouched.
  /// Pure plain-text input (no `<` characters) is also handled correctly.
  static String enrich(String raw) {
    if (raw.isEmpty) return raw;
    final trimmed = raw.trim();
    if (!trimmed.contains('<')) {
      // Pure text — wrap in <p> and linkify
      return '<p>${_linkifyText(trimmed)}</p>';
    }
    return _linkifyHtmlTextNodes(trimmed);
  }

  /// Walks [html] character-by-character, passing only text nodes through
  /// [_linkifyText]. Tag content and existing `<a>` element bodies are
  /// copied verbatim.
  static String _linkifyHtmlTextNodes(String html) {
    final buf = StringBuffer();
    int pos = 0;

    while (pos < html.length) {
      final tagStart = html.indexOf('<', pos);
      final textEnd = tagStart == -1 ? html.length : tagStart;

      if (textEnd > pos) {
        buf.write(_linkifyText(html.substring(pos, textEnd)));
      }

      if (tagStart == -1) break;

      final tagEnd = html.indexOf('>', tagStart);
      if (tagEnd == -1) {
        buf.write(html.substring(tagStart));
        break;
      }

      final tag = html.substring(tagStart, tagEnd + 1);
      buf.write(tag);

      // Skip everything inside an existing <a> element to avoid wrapping
      // links that are already marked up.
      if (RegExp(r'^<a[\s>]', caseSensitive: false).hasMatch(tag)) {
        final closeAnchor = html.toLowerCase().indexOf('</a>', tagEnd + 1);
        if (closeAnchor != -1) {
          buf.write(html.substring(tagEnd + 1, closeAnchor + 4));
          pos = closeAnchor + 4;
          continue;
        }
      }

      pos = tagEnd + 1;
    }

    return buf.toString();
  }

  static PreviewMatch? detectFirstPreview(String text) {
    if (text.trim().isEmpty) return null;

    final plain = stripHtmlTags(text).trim();
    if (plain.isEmpty) return null;

    final urlMatch = _urlPattern.firstMatch(plain);
    if (urlMatch != null) {
      var value = _trimTrailingPunctuation(urlMatch.group(0)!);
      if (value.toLowerCase().startsWith('www.')) {
        value = 'https://$value';
      }
      return PreviewMatch(kind: PreviewKind.url, value: value);
    }

    final emailMatch = _emailPattern.firstMatch(plain);
    if (emailMatch != null) {
      final value = _trimTrailingPunctuation(emailMatch.group(0)!);
      return PreviewMatch(kind: PreviewKind.email, value: value);
    }

    final phoneMatch = _phonePattern.firstMatch(plain);
    if (phoneMatch != null) {
      final value = _trimTrailingPunctuation(phoneMatch.group(0)!);
      return PreviewMatch(kind: PreviewKind.phone, value: value);
    }

    return null;
  }

  static String _trimTrailingPunctuation(String value) {
    var sanitized = value;
    while (sanitized.isNotEmpty &&
        (sanitized.endsWith('.') ||
            sanitized.endsWith(',') ||
            sanitized.endsWith('!') ||
            sanitized.endsWith('?') ||
            sanitized.endsWith(')'))) {
      sanitized = sanitized.substring(0, sanitized.length - 1);
    }
    return sanitized;
  }

  /// Converts bare URLs and email addresses in [text] to `<a href="">` tags.
  static String _linkifyText(String text) {
    if (text.isEmpty) return text;
    return text.replaceAllMapped(_linkPattern, (m) {
      var raw = m.group(0)!;

      // Trim common trailing punctuation that is unlikely to be part of the URL.
      while (raw.isNotEmpty &&
          (raw.endsWith('.') ||
              raw.endsWith(',') ||
              raw.endsWith('!') ||
              raw.endsWith('?') ||
              raw.endsWith(')'))) {
        raw = raw.substring(0, raw.length - 1);
      }
      if (raw.isEmpty) return m.group(0)!;

      final lower = raw.toLowerCase();
      if (lower.contains('@') &&
          !lower.startsWith('http') &&
          !lower.startsWith('www')) {
        return '<a href="mailto:$raw">$raw</a>';
      }
      if (lower.startsWith('http') || lower.startsWith('www.')) {
        final href = lower.startsWith('www.') ? 'https://$raw' : raw;
        return '<a href="$href">$raw</a>';
      }
      // Phone number — strip display separators for the tel: URI
      final digitsOnly = raw.replaceAll(RegExp(r'[\s\-.()]'), '');
      return '<a href="tel:$digitsOnly">$raw</a>';
    });
  }

  // ── Link launching ─────────────────────────────────────────────────────────

  /// Opens [href] in the most appropriate app (browser, mail client, dialer).
  static Future<void> launchLink(String? href) async {
    if (href == null || href.isEmpty) return;
    try {
      final uri = Uri.tryParse(href);
      if (uri == null) return;
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // Silently ignore — bad URI or no handler available.
    }
  }

  // ── Plain-text extraction ──────────────────────────────────────────────────

  /// Strips all HTML tags from [html] and decodes common HTML entities,
  /// returning plain text suitable for clipboard copy, list-tile previews,
  /// reply/quote previews, and edit-mode text fields.
  ///
  /// Examples:
  ///   `<b>Hello</b> <i>World</i>` → `Hello World`
  ///   `<p>Line 1</p><p>Line 2</p>` → `Line 1\nLine 2`
  ///   `&amp;lt;b&gt;` → `<b>`
  static String stripHtmlTags(String input) {
    if (input.isEmpty) return input;

    // Block-level tags that should become newlines rather than disappearing.
    var result = input
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</div>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</li>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '• ');

    // Remove all remaining tags.
    result = result.replaceAll(RegExp(r'<[^>]+>'), '');

    // Decode the five XML/HTML character references that appear most often
    // in rich-text content.
    result = result
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');

    // Collapse runs of blank lines into a single newline, then trim.
    result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
    return result;
  }

  /// Returns a single-line plain-text preview suitable for conversation-list
  /// tiles, notification text, and search results.  Never longer than
  /// [maxLength] characters; appends '…' when truncated.
  static String previewText(String rawContent, {int maxLength = 120}) {
    final plain = stripHtmlTags(
      rawContent,
    ).replaceAll('\n', ' ').replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    if (plain.length <= maxLength) return plain;
    return '${plain.substring(0, maxLength)}…';
  }

  // ── Smart bubble timestamp ─────────────────────────────────────────────────

  /// Returns a human-friendly timestamp for a chat bubble.
  ///
  /// • < 30 s old → "Now"
  /// • < 60 min old → "Xm ago"  (e.g. "3m ago")
  /// • otherwise → the pre-formatted [hhMM] string (e.g. "14:05")
  static String smartBubbleTime(DateTime sentAt, String hhMM) {
    final diff = ServerTimeService.instance.nowUtc().difference(sentAt.toUtc());
    if (diff.inSeconds < 30) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    return hhMM;
  }

  // ── Sender display name ────────────────────────────────────────────────────

  /// Returns the best available display label for a message sender.
  ///
  /// Only ever returns `senderName`, or the generic `'User'` placeholder —
  /// the internal `senderUserCode` must never reach the UI, so it's
  /// intentionally not part of this fallback chain.
  static String senderDisplay(String? senderName, String? senderUserCode) {
    if (senderName != null && senderName.trim().isNotEmpty) {
      return senderName.trim();
    }
    return senderName ?? 'User';
  }
}
