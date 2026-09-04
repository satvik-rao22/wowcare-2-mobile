import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// What 4b's four options mean.
enum DayChoice {
  today,
  yesterday,
  pickADay,

  /// Leaves the day behind entirely: totals and hours instead of sign in
  /// keys, which is 4f.
  range,
}

/// A from and a to, inclusive. 4b's second half and 4f's own field.
@immutable
class DateRange extends Equatable {
  const DateRange({required this.from, required this.to});

  final DateTime from;
  final DateTime to;

  /// The whole days it spans, both ends counted.
  int get dayCount => to.difference(from).inDays.abs() + 1;

  DateRange copyWith({DateTime? from, DateTime? to}) =>
      DateRange(from: from ?? this.from, to: to ?? this.to);

  @override
  List<Object?> get props => <Object?>[from, to];
}

/// What the day sheet resolved to.
@immutable
class DaySelection extends Equatable {
  const DaySelection({required this.choice, this.day, this.range});

  final DayChoice choice;

  /// The day chosen, for everything but [DayChoice.range].
  final DateTime? day;

  /// The range chosen, for [DayChoice.range] only.
  final DateRange? range;

  @override
  List<Object?> get props => <Object?>[choice, day, range];
}
