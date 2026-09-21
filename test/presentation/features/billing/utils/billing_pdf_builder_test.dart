import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/billing/entities/invoice_list_entity.dart';
import 'package:wowcare/presentation/features/billing/utils/billing_pdf_builder.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/transaction_item.dart';

TransactionItem _transaction({String? invoiceCode}) => TransactionItem(
      id: 1,
      transactionId: 'TXN_1',
      transactionType: 'Invoice',
      date: DateTime(2026, 9, 1),
      amount: 150.0,
      status: 'PAID',
      description: 'September tuition',
      studentName: 'Jamie Doe',
      classroom: 'Room 1',
      invoiceCode: invoiceCode,
      paymentMode: 'Cash',
    );

/// PDF files always start with the `%PDF-` magic bytes — the cheapest way to
/// confirm the generator actually produced a real PDF, not just some bytes.
bool _looksLikePdf(List<int> bytes) {
  const magic = [0x25, 0x50, 0x44, 0x46, 0x2d]; // "%PDF-"
  if (bytes.length < magic.length) return false;
  for (var i = 0; i < magic.length; i++) {
    if (bytes[i] != magic[i]) return false;
  }
  return true;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BillingPdfBuilder.buildInvoicePdf', () {
    test('produces non-empty, well-formed PDF bytes with no invoice detail',
        () async {
      final bytes = await BillingPdfBuilder.buildInvoicePdf(
        transaction: _transaction(invoiceCode: 'INV_1'),
        schoolName: 'Test School',
      );
      expect(bytes, isNotEmpty);
      expect(_looksLikePdf(bytes), isTrue);
    });

    test('produces well-formed PDF bytes with a full invoice detail',
        () async {
      final detail = InvoiceListItemEntity(
        code: 'INV_1',
        organization: 'ORG_1',
        school: 'SCH_1',
        studentCode: 'STD_1',
        subjectOwnerType: 'STUDENT',
        subjectOwnerCode: 'STD_1',
        amount: 150,
        total: 150,
        paidAmount: 0,
        status: 'UNPAID',
        invoiceStatus: 'ISSUED',
        dueDate: DateTime(2026, 9, 10),
        periodStart: DateTime(2026, 9, 1),
        periodEnd: DateTime(2026, 9, 30),
        items: const [
          InvoiceListLineItemEntity(
            description: 'Tuition',
            quantity: 1,
            unitPrice: 150,
            totalPrice: 150,
          ),
        ],
      );
      final bytes = await BillingPdfBuilder.buildInvoicePdf(
        transaction: _transaction(invoiceCode: 'INV_1'),
        schoolName: 'Test School',
        roomName: 'Room 2',
        detail: detail,
      );
      expect(bytes, isNotEmpty);
      expect(_looksLikePdf(bytes), isTrue);
    });

    test('falls back gracefully with an empty school name', () async {
      final bytes = await BillingPdfBuilder.buildInvoicePdf(
        transaction: _transaction(),
        schoolName: '',
      );
      expect(bytes, isNotEmpty);
      expect(_looksLikePdf(bytes), isTrue);
    });

    test('includes tagline and address in the header when provided',
        () async {
      final bytes = await BillingPdfBuilder.buildInvoicePdf(
        transaction: _transaction(invoiceCode: 'INV_1'),
        schoolName: 'Podar Jumbo Kids',
        schoolTagline: 'Where learning meets fun',
        schoolAddress: '123 Karnik Road, Mumbai, 400001',
      );
      expect(bytes, isNotEmpty);
      expect(_looksLikePdf(bytes), isTrue);
    });

    test(
        'renders line items containing an em dash without throwing '
        '(regression: default Helvetica has no Unicode support and turned '
        '"—" into a tofu box until Manrope was embedded)', () async {
      final detail = InvoiceListItemEntity(
        code: 'INV_1',
        organization: 'ORG_1',
        school: 'SCH_1',
        studentCode: 'STD_1',
        subjectOwnerType: 'STUDENT',
        subjectOwnerCode: 'STD_1',
        amount: 100,
        total: 100,
        paidAmount: 0,
        status: 'UNPAID',
        invoiceStatus: 'ISSUED',
        items: const [
          InvoiceListLineItemEntity(
            description: 'Toddler — WEEKLY',
            quantity: 1,
            unitPrice: 100,
            totalPrice: 100,
          ),
        ],
      );
      final bytes = await BillingPdfBuilder.buildInvoicePdf(
        transaction: _transaction(invoiceCode: 'INV_1'),
        schoolName: 'Test School',
        detail: detail,
      );
      expect(bytes, isNotEmpty);
      expect(_looksLikePdf(bytes), isTrue);
    });
  });

  group('BillingPdfBuilder.buildReceiptPdf', () {
    test('produces non-empty, well-formed PDF bytes', () async {
      final bytes = await BillingPdfBuilder.buildReceiptPdf(
        transaction: _transaction(),
        schoolName: 'Test School',
      );
      expect(bytes, isNotEmpty);
      expect(_looksLikePdf(bytes), isTrue);
    });
  });
}
