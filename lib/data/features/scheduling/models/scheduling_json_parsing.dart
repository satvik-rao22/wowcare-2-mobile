/// Shared JSON-value coercion for scheduling's wire models. The backend
/// sometimes sends numbers as JSON numbers and sometimes as numeric strings,
/// and a string field is sometimes absent entirely — this centralizes the
/// defaulting rule instead of restating it per field, per model.
abstract final class SchedulingJsonParsing {
  static String string(dynamic value, {String fallback = ''}) =>
      (value ?? fallback).toString();

  static int intValue(dynamic value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static double doubleValue(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
