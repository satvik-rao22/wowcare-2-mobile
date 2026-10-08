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

  static const String idPlaceholder = '{id}';

  /// API version segments (`v1`, `v2`): the only static segments with a digit.
  static final RegExp _versionSegment = RegExp(r'^v\d+$');
  static final RegExp _idSegment = RegExp(r'[0-9@]');

  /// Turns a concrete path into its template, for grouping and for keeping
  /// record codes out: every segment holding a digit or an `@` becomes
  /// `{id}`, so `/api/v1/events/EVT_99E5/rsvps` reads
  /// `/api/v1/events/{id}/rsvps`. Record codes all carry digits; no static
  /// API or app route segment does, apart from the version.
  ///
  /// Takes a path, not a URL; any query or fragment is dropped.
  static String templatePath(String path) {
    return stripQueryString(path)
        .split('/')
        .map(
          (segment) =>
              _idSegment.hasMatch(segment) && !_versionSegment.hasMatch(segment)
              ? idPlaceholder
              : segment,
        )
        .join('/');
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
