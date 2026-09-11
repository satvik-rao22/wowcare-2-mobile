import 'package:intl/intl.dart';

/// Money formatting for the billing module.
///
/// Every billing amount renders to **two decimal places** with thousands
/// separators. The accounting screens previously mixed four different formats
/// side by side — `NumberFormat('#,##0')` in the stat bar (`$1,721`),
/// `toStringAsFixed(0)` with no separators beside the outstanding toggle
/// (`$1045`), and `NumberFormat.currency` in the transaction rows
/// (`$1,234.50`) — so cents were dropped in the summaries while the rows below
/// them showed cents, and the figures visibly failed to add up.
///
/// Cached at the top level: [NumberFormat] construction parses its pattern,
/// and these are called from `build` on every rebuild.
final NumberFormat _billingAmountFormat = NumberFormat('#,##0.00');

/// Formats [value] as a billing amount — `$1,234.56`, `-$1,234.56`, `$0.00`.
///
/// The sign is placed outside the currency symbol, and the symbol is applied
/// here rather than through `NumberFormat.currency`, so amounts share one
/// shape across the module (the stat-bar headline previously rendered a
/// negative total as `$-1,234`).
///
/// Values carrying more precision than cents are rounded half-away-from-zero
/// at the second decimal, matching `NumberFormat`'s default. Backend amounts
/// are cents-precision already, so this only affects floating-point residue
/// from summing rows client-side.
String billingAmount(double value) {
  // `value < 0` rather than `isNegative`, so -0.0 renders as `$0.00`.
  final sign = value < 0 ? '-' : '';
  return '$sign\$${_billingAmountFormat.format(value.abs())}';
}
