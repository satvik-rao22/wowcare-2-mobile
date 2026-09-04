import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// What a tag means, which is the only thing that decides its colour.
///
/// The school's tag list is free text, so the tone is inferred once, in the
/// source, rather than at every place a tag is drawn.
enum TagTone {
  /// Peanut allergy, EpiPen, Inhaler: anything a room has to act on.
  allergy,

  /// Naps, Sibling, Second language: an everyday note about the student.
  student,

  /// State subsidy, Halal, Bus: administrative, and quiet.
  neutral,
}

/// One of the school's own student tags.
@immutable
class StudentTag extends Equatable {
  const StudentTag({required this.label, this.tone = TagTone.neutral});

  final String label;
  final TagTone tone;

  @override
  List<Object?> get props => [label, tone];
}
