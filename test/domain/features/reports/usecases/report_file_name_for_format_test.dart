import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/reports/usecases/report_file_name_for_format.dart';

void main() {
  group('reportFileNameForFormat', () {
    test('re-labels the streamed *.xlsx name when PDF was requested', () {
      expect(
        reportFileNameForFormat('BILLING_TRANSACTION_report.xlsx', 'PDF'),
        'BILLING_TRANSACTION_report.pdf',
      );
    });

    test('keeps the xlsx extension for XLSX', () {
      expect(
        reportFileNameForFormat('BILLING_INVOICE_report.xlsx', 'XLSX'),
        'BILLING_INVOICE_report.xlsx',
      );
    });

    test('handles a missing or extension-less file name', () {
      expect(reportFileNameForFormat(null, 'PDF'), 'report.pdf');
      expect(reportFileNameForFormat('  ', 'XLSX'), 'report.xlsx');
      expect(reportFileNameForFormat('invoice', 'PDF'), 'invoice.pdf');
    });

    test('is case insensitive on the format', () {
      expect(reportFileNameForFormat('a.xlsx', 'pdf'), 'a.pdf');
    });
  });
}
