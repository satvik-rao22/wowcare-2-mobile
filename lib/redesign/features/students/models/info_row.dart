import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// How loudly a value reads. The label is always quiet; only the value moves.
enum InfoTone {
  /// The everyday value, in ink.
  ink,

  /// An allergy, an overdue date: red.
  danger,

  /// A completed exam, a record kept: green.
  success,

  /// Running prose, and anything not filled in yet.
  muted,
}

/// A label and its value, the row every detail card on 5c is made of.
@immutable
class InfoRow extends Equatable {
  const InfoRow(this.label, this.value, {this.tone = InfoTone.ink});

  final String label;
  final String value;
  final InfoTone tone;

  @override
  List<Object?> get props => [label, value, tone];
}
