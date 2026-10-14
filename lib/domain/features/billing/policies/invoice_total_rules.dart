/// Which invoice totals may be saved or sent.
///
/// A total may be positive, and it may be exactly zero when a discount or
/// subsidy is what brought it there — a fully subsidised child still gets an
/// invoice, because it is the record that the place was charged for and who
/// covered it. Zero with nothing taken off is an invoice for nothing, and a
/// negative total says the school owes the family money. The API refuses both.
class InvoiceTotalRules {
  const InvoiceTotalRules._();

  /// Money as whole cents.
  ///
  /// Totals are sums of doubles: `19.99 - 9.99 - 10` is `-1.78e-15`, not zero.
  /// Compared as it stands, an invoice a subsidy takes exactly to zero reads as
  /// negative and is refused (and prints as `$-0.00`).
  static int toCents(double amount) => (amount * 100).round();

  /// A total rounded to the cent, with no `-0` — the figure to show and compare.
  static double roundToCents(double total) {
    final cents = toCents(total);
    return cents == 0 ? 0.0 : cents / 100;
  }

  /// Whether a discount or subsidy on the invoice actually takes something off.
  /// [deductionAmounts] are the amounts of the discount / subsidy lines.
  static bool hasAppliedReduction(Iterable<double> deductionAmounts) =>
      deductionAmounts.any((amount) => toCents(amount.abs()) > 0);

  /// Why this total cannot be invoiced, or null when it can.
  static String? totalProblem(double total, {required bool hasReduction}) {
    final cents = toCents(total);
    if (cents < 0) {
      return 'The total cannot be negative — the discounts and subsidies are '
          'more than the charges.';
    }
    if (cents == 0 && !hasReduction) {
      return 'The total can be zero only when a discount or subsidy brings it '
          'to zero.';
    }
    return null;
  }
}
