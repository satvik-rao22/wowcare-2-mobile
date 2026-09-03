import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// One line on a guardian's invoice list (3P2).
@immutable
class InvoiceRow extends Equatable {
  const InvoiceRow({
    required this.title,
    required this.meta,
    required this.amount,
  });

  final String title;

  /// "Paid 24 Jul · Visa 4471".
  final String meta;
  final double amount;

  @override
  List<Object?> get props => [title, meta, amount];
}

/// A newsletter a guardian can open from the dashboard (3P2).
@immutable
class NewsletterRow extends Equatable {
  const NewsletterRow({required this.title, required this.meta});

  final String title;

  /// "Sunflower · 2 days ago".
  final String meta;

  @override
  List<Object?> get props => [title, meta];
}

/// The guardian's money card (3P2).
@immutable
class GuardianBilling extends Equatable {
  const GuardianBilling({
    required this.balanceDue,
    required this.dueLabel,
    required this.monthLabel,
    required this.invoices,
    this.isAutopayOn = false,
  });

  final double balanceDue;

  /// "25 Aug".
  final String dueLabel;

  /// "March", the month the balance is for.
  final String monthLabel;

  final bool isAutopayOn;
  final List<InvoiceRow> invoices;

  bool get isSettled => balanceDue <= 0;

  @override
  List<Object?> get props => [
    balanceDue,
    dueLabel,
    monthLabel,
    isAutopayOn,
    invoices,
  ];
}
