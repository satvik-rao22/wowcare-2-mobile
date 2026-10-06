/// Text scrubbing shared by every Sentry hook and by [MediaUploadTrace].
///
/// Two levels, because the two places they are used tolerate different
/// losses:
///
/// * [redactPathsAndUrls] is blunt. It is for exception messages, where the
///   diagnostic value is the exception type and error code, not the file name
///   or host, and where a path routinely carries a child's name or a presigned
///   URL carries a bearer signature.
/// * [stripQueryStrings] keeps scheme, host and path and removes only the
///   query and fragment. It is for breadcrumbs, logs and request data, where
///   the path is the whole point and record codes travel in the query.
abstract final class TelemetryRedactor {
  TelemetryRedactor._();

  static const String urlPlaceholder = '<url>';
  static const String pathPlaceholder = '<path>';

  /// Anything with a scheme, up to whitespace, a closing paren or a quote.
  static final RegExp _url = RegExp(
    r'[a-zA-Z][a-zA-Z0-9+.-]*://[^\s)"'
    "'"
    r']+',
  );

  /// POSIX absolute paths, including the body of a `file://` URL.
  static final RegExp _posixPath = RegExp(r'/(?:[\w .@+-]+/)*[\w .@+-]+');

  /// Replaces every URL with `<url>` and every absolute path with `<path>`.
  ///
  /// URLs go first; otherwise the path rule would eat only their tail and
  /// leave the host and query behind.
  static String redactPathsAndUrls(String text) {
    return text
        .replaceAll(_url, urlPlaceholder)
        .replaceAll(_posixPath, pathPlaceholder);
  }

  /// Removes the query string and fragment from every URL inside [text].
  static String stripQueryStrings(String text) {
    return text.replaceAllMapped(_url, (match) => stripQueryString(match[0]!));
  }

  /// Returns [url] cut before its first `?` or `#`.
  static String stripQueryString(String url) {
    final query = url.indexOf('?');
    final fragment = url.indexOf('#');
    final cutAt = switch ((query, fragment)) {
      (-1, -1) => url.length,
      (-1, final f) => f,
      (final q, -1) => q,
      (final q, final f) => q < f ? q : f,
    };
    return url.substring(0, cutAt);
  }
}
