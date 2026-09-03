import 'package:flutter/foundation.dart';

/// One choice in a select sheet: the value it stands for and how it reads.
@immutable
class SelectOption<T> {
  const SelectOption({required this.value, required this.label, this.subtitle});

  final T value;
  final String label;
  final String? subtitle;

  /// Whether [query] matches this option, case-insensitively, on either line.
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return label.toLowerCase().contains(q) ||
        (subtitle?.toLowerCase().contains(q) ?? false);
  }
}
