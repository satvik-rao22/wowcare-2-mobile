import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/billing/policies/invoice_actions.dart';
import 'package:wowcare/domain/features/billing/policies/invoice_total_rules.dart';

void main() {
  group('InvoiceTotalRules.totalProblem', () {
    test('positive totals are fine', () {
      expect(InvoiceTotalRules.totalProblem(10, hasReduction: false), isNull);
    });

    test('zero is allowed when a discount or subsidy brought it there', () {
      expect(InvoiceTotalRules.totalProblem(0, hasReduction: true), isNull);
    });

    test('zero with nothing taken off is refused', () {
      expect(InvoiceTotalRules.totalProblem(0, hasReduction: false), isNotNull);
    });

    test('negative totals are refused', () {
      expect(InvoiceTotalRules.totalProblem(-5, hasReduction: true), isNotNull);
    });

    test('floating point dust around zero counts as zero', () {
      final total = 19.99 - 9.99 - 10; // -1.78e-15
      expect(total, isNot(0));
      expect(InvoiceTotalRules.totalProblem(total, hasReduction: true), isNull);
      expect(InvoiceTotalRules.roundToCents(total), 0.0);
      expect(InvoiceTotalRules.roundToCents(total).isNegative, isFalse);
    });
  });

  group('InvoiceTotalRules.hasAppliedReduction', () {
    test('needs a deduction that takes something off', () {
      expect(InvoiceTotalRules.hasAppliedReduction(const <double>[]), isFalse);
      expect(InvoiceTotalRules.hasAppliedReduction(const [0, 0.001]), isFalse);
      expect(InvoiceTotalRules.hasAppliedReduction(const [0, 5]), isTrue);
    });
  });

  group('isChangeableZeroInvoice', () {
    test('issued zero invoice the server marked fullyReduced is changeable', () {
      for (final s in ['Paid', 'SENT', 'overdue', 'Success', 'COMPLETED']) {
        expect(isChangeableZeroInvoice(s, true), isTrue, reason: s);
      }
    });

    test('an invoice a family paid stays locked', () {
      expect(isChangeableZeroInvoice('PAID', false), isFalse);
      expect(isChangeableZeroInvoice('PAID', null), isFalse);
    });

    test('drafts and cancelled invoices are not covered by this rule', () {
      expect(isChangeableZeroInvoice('DRAFT', true), isFalse);
      expect(isChangeableZeroInvoice('CANCELLED', true), isFalse);
      expect(isChangeableZeroInvoice(null, true), isFalse);
    });
  });
}
