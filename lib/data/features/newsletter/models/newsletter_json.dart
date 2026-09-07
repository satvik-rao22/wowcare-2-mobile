/// Shared `@JsonKey` helpers for the newsletter models (Mandate 8).
///
/// ## Why these exist
///
/// json_serializable maps a field from exactly one key and does no
/// normalisation. The newsletter payloads need three things it cannot express
/// on its own, so each becomes a named function referenced from an annotation
/// rather than an inline expression in a hand-written factory:
///
/// * **Normalisation** — every string field was `.trim()`ed and defaulted to
///   `''`. That is `@JsonKey(fromJson: jsonTrimmedString)`.
/// * **Aliases** — several fields accept a chain of legacy key names. A
///   `fromJson:` function only receives the value at one key, so an alias
///   chain must be `@JsonKey(readValue: …)`, which receives the whole map.
/// * **Lenient types** — dates arrive as ISO strings, as `DateTime`, or as
///   junk. That is `@JsonKey(fromJson: jsonDateTime)`.
///
/// `readValue` and `fromJson` compose: the generator emits
/// `fromJsonFn(readValueFn(json, 'key'))`, so an aliased field can still be
/// trimmed.
///
/// **`readValue` functions must be top-level or static** — an annotation
/// cannot reference a closure, which is why each alias chain gets its own
/// named function next to the model that uses it.
library;

/// `(value ?? '').toString().trim()` — the normalisation every newsletter
/// string field applied by hand. A missing key arrives here as null and
/// becomes `''`, so this covers "default" and "trim" in one.
String jsonTrimmedString(Object? value) => (value ?? '').toString().trim();

/// `(value as String? ?? '').trim()` — the STRICT variant.
///
/// Distinct from [jsonTrimmedString] on purpose: this one THROWS when the key
/// holds a non-string, exactly as the sent-newsletter parser's
/// `json['x'] as String? ?? ''` did. [jsonTrimmedString] coerces instead,
/// matching the student parser's `(json['x'] ?? '').toString()`. The two
/// endpoints really do differ here, and collapsing them would change which
/// malformed payloads are rejected.
String jsonTrimmedStringStrict(Object? value) =>
    (value as String? ?? '').trim();

/// Nullable variant: null stays null, anything else is trimmed. Used where the
/// hand-written parser wrote `(json['x'] as String?)?.trim()`.
String? jsonTrimmedStringOrNull(Object? value) =>
    value == null ? null : value.toString().trim();

/// Lenient date parse, matching the hand-written `_parseDateTime`: passes a
/// `DateTime` straight through, parses a non-empty string, and returns null
/// for null, empty or unparseable input rather than throwing.
DateTime? jsonDateTime(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  final String text = value.toString().trim();
  if (text.isEmpty) return null;
  return DateTime.tryParse(text);
}

/// Like [jsonDateTime] but WITHOUT trimming, matching the student-newsletter
/// parser's `DateTime.tryParse((json['x'] ?? '').toString())`.
///
/// Both variants exist on purpose. The two model stacks parsed dates slightly
/// differently, and a whitespace-padded date string parses under [jsonDateTime]
/// but not here. Collapsing them onto one helper would silently widen what the
/// student endpoint accepts (§8: "parse behaviour must be identical, including
/// on malformed input").
DateTime? jsonDateTimeNoTrim(Object? value) =>
    DateTime.tryParse((value ?? '').toString());

/// Returns the first key present with a NON-NULL value.
///
/// Deliberately not "first non-empty": the hand-written parsers used `??`,
/// which only skips null, so a key present with `''` wins over a later key
/// that has content. Changing that would change parse behaviour.
Object? jsonFirstNonNull(Map<dynamic, dynamic> json, List<String> keys) {
  for (final String key in keys) {
    final Object? value = json[key];
    if (value != null) return value;
  }
  return null;
}
