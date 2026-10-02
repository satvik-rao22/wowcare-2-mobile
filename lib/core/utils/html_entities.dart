/// Decodes HTML character references in server-sent plain text.
///
/// Some backend templates HTML-escape user-typed text (an admin's note, a
/// reason) before dropping it into a notification, so "can't" arrives as
/// `can&#39;t`. The text is shown in a plain [Text], never as HTML, so the
/// reference has to be turned back into the character or it shows literally.
///
/// Handles decimal (`&#39;`), hex (`&#x27;`) and the named references that
/// actually occur in text. A reference it does not know is left as written.
/// Single pass, so `&amp;lt;` becomes `&lt;` and not `<`.
abstract final class HtmlEntities {
  static final RegExp _reference = RegExp(
    r'&(#[0-9]{1,7}|#[xX][0-9a-fA-F]{1,6}|[a-zA-Z]{2,8});',
  );

  static const Map<String, String> _named = <String, String>{
    'amp': '&',
    'lt': '<',
    'gt': '>',
    'quot': '"',
    'apos': "'",
    'nbsp': ' ',
    'ndash': '–',
    'mdash': '—',
    'hellip': '…',
    'lsquo': '‘',
    'rsquo': '’',
    'ldquo': '“',
    'rdquo': '”',
  };

  static String decode(String input) {
    if (!input.contains('&')) return input;
    return input.replaceAllMapped(_reference, (m) {
      final ref = m.group(1)!;
      if (ref.startsWith('#')) {
        final hex = ref.length > 1 && (ref[1] == 'x' || ref[1] == 'X');
        final code = int.tryParse(
          hex ? ref.substring(2) : ref.substring(1),
          radix: hex ? 16 : 10,
        );
        if (code == null || code > 0x10FFFF) return m.group(0)!;
        return String.fromCharCode(code);
      }
      return _named[ref] ?? m.group(0)!;
    });
  }

  /// [decode] for a nullable value, keeping null as null.
  static String? decodeOrNull(String? input) =>
      input == null ? null : decode(input);
}
