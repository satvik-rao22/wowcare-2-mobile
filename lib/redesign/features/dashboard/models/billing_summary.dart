import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// The Admin's billing card, the one impact surface on 3A2.
@immutable
class BillingSummary extends Equatable {
  const BillingSummary({
    required this.rangeLabel,
    required this.invoiced,
    required this.netPaid,
    required this.inProcess,
    required this.outstanding,
    required this.allUnpaid,
  });

  /// "1 – 31 Aug".
  final String rangeLabel;

  final double invoiced;
  final double netPaid;
  final double inProcess;
  final double outstanding;

  /// Every open invoice, not just this range.
  final double allUnpaid;

  @override
  List<Object?> get props => [
    rangeLabel,
    invoiced,
    netPaid,
    inProcess,
    outstanding,
    allUnpaid,
  ];
}
