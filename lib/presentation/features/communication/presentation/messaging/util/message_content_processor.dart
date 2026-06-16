import 'dart:async';
import 'package:url_launcher/url_launcher.dart';

/// Enriches HTML message content with auto-linked URLs / emails, and
/// provides a single entry-point for launching links.
///
/// Clean Architecture note: this is a pure presentation utility with no
/// dependency on domain or data layers.
class MessageContentProcessor {
  MessageContentProcessor._();

  // ── Patterns ───────────────────────────────────────────────────────────────

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

  // ── Smart bubble timestamp ─────────────────────────────────────────────────

  /// Returns a human-friendly timestamp for a chat bubble.
  ///
  /// • < 30 s old → "Now"
  /// • < 60 min old → "Xm ago"  (e.g. "3m ago")
  /// • otherwise → the pre-formatted [hhMM] string (e.g. "14:05")
  static String smartBubbleTime(DateTime sentAt, String hhMM) {
    final diff = DateTime.now().toUtc().difference(sentAt.toUtc());
    if (diff.inSeconds < 30) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return hhMM;
  }

  // ── Sender display name ────────────────────────────────────────────────────

  /// Returns the best available display label for a message sender.
  ///
  /// Priority: `senderName` → `senderUserCode` (truncated) → `'User'`.
  /// Never returns an empty string or "Unknown User".
  static String senderDisplay(String? senderName, String? senderUserCode) {
    if (senderName != null && senderName.trim().isNotEmpty) {
      return senderName.trim();
    }
    if (senderUserCode != null && senderUserCode.trim().isNotEmpty) {
      final code = senderUserCode.trim();
      return code.length > 16 ? code.substring(0, 16) : code;
    }
    return 'User';
  }
}
