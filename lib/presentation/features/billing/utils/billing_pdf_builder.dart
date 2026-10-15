import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:wowcare/core/utils/string_utils.dart';
import 'package:wowcare/domain/features/billing/entities/invoice_list_entity.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/transaction_item.dart';
import 'package:wowcare/core/utils/app_string_extension.dart';

/// Builds invoice/receipt PDFs entirely on-device from data already loaded
/// for the View Invoice / View Receipt screens — there is no backend PDF
/// endpoint for either document, so the PDF mirrors exactly what those
/// screens already render rather than fetching a rendered file.
class BillingPdfBuilder {
  BillingPdfBuilder._();

  static final DateFormat _dateFormat = DateFormat('MMM d, yyyy');
  static String _formatDate(DateTime date) => _dateFormat.format(date);

  static const PdfColor _primaryColor = PdfColor.fromInt(0xFF573353);
  static const PdfColor _mutedColor = PdfColor.fromInt(0xFF8C7B89);

  /// A real opaque tint, not an alpha-blended one: this renderer paints a
  /// [pw.BoxDecoration] fill as a flat rect — it does not composite alpha
  /// against the page the way Flutter's own `Color.withValues(alpha: …)`
  /// does on-screen. Using an alpha'd `_primaryColor` here previously
  /// produced a fully-opaque dark block with the same-color text invisible
  /// on top of it. This is `_primaryColor` blended 6% over white, computed
  /// by hand to render identically regardless of that limitation.
  static const PdfColor _totalRowBackground = PdfColor.fromInt(0xFFF4F2F4);

  /// Loaded once per document so every default `pw.Text` gets Manrope
  /// (matching the on-screen font) with full Unicode coverage — the
  /// package's built-in Helvetica has none, which silently turned an
  /// em dash ("—", used in several activity/plan names) into a tofu box.
  static Future<pw.ThemeData> _loadTheme() async {
    final regular = await rootBundle.load(
      'assets/fonts/manrope/Manrope-Regular.ttf',
    );
    final bold = await rootBundle.load('assets/fonts/manrope/Manrope-Bold.ttf');
    return pw.ThemeData.withFont(
      base: pw.Font.ttf(regular),
      bold: pw.Font.ttf(bold),
    );
  }

  /// Mirrors [ViewInvoiceScreen]'s layout: billed-for row, invoice meta
  /// (number / due date / period, falling back to the issue date), and the
  /// line-items table with total.
  static Future<Uint8List> buildInvoicePdf({
    required TransactionItem transaction,
    required String schoolName,
    String schoolTagline = '',
    String schoolAddress = '',
    String? roomName,
    InvoiceListItemEntity? detail,
  }) async {
    final doc = pw.Document(theme: await _loadTheme());
    final classroom = (roomName ?? transaction.classroom).trim();

    final invoiceNumber = (detail?.code ?? transaction.invoiceCode ?? '')
        .trim();
    final dueDate = detail?.dueDate ?? _tryParse(transaction.endDate);
    final periodStart = detail?.periodStart;
    final periodEnd = detail?.periodEnd;

    final metaRows = <List<String>>[
      if (invoiceNumber.isNotEmpty) ['Invoice Number', invoiceNumber],
      if (dueDate != null) ['Due Date', _formatDate(dueDate)],
      if (periodStart != null && periodEnd != null)
        [
          'Invoice Period',
          '${_formatDate(periodStart)} to ${_formatDate(periodEnd)}',
        ],
    ];
    if (metaRows.isEmpty) {
      metaRows.add(['Invoice Date', _formatDate(transaction.date)]);
    }

    final lineItems = detail?.items ?? const <InvoiceListLineItemEntity>[];
    final tableRows = lineItems.isEmpty
        ? [
            [
              transaction.displayDescription,
              '\$${transaction.amount.toStringAsFixed(2)}',
            ],
          ]
        : lineItems
              .map(
                (i) => [
                  i.description.isEmpty ? '-' : i.description,
                  '\$${i.totalPrice.toStringAsFixed(2)}',
                ],
              )
              .toList();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _schoolHeader(schoolName, schoolTagline, schoolAddress),
            pw.SizedBox(height: 20),
            _billedForRow('Billed For :', transaction.studentName, classroom),
            pw.SizedBox(height: 16),
            for (final row in metaRows) _metaRow(row[0], row[1]),
            pw.SizedBox(height: 12),
            _itemsTable(tableRows, transaction.amount),
          ],
        ),
      ),
    );

    return doc.save();
  }

  /// Mirrors [ViewReceiptScreen]'s 'receipt' layout: payment-for row, payment
  /// date, description + mode + amount, total.
  static Future<Uint8List> buildReceiptPdf({
    required TransactionItem transaction,
    required String schoolName,
    String schoolTagline = '',
    String schoolAddress = '',
  }) async {
    final doc = pw.Document(theme: await _loadTheme());

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _schoolHeader(schoolName, schoolTagline, schoolAddress),
            pw.SizedBox(height: 20),
            _billedForRow(
              'Payment For :',
              transaction.studentName,
              transaction.classroom,
            ),
            pw.SizedBox(height: 16),
            _metaRow('Payment Date', _formatDate(transaction.date)),
            pw.SizedBox(height: 12),
            pw.Table(
              columnWidths: const {
                0: pw.FlexColumnWidth(4),
                1: pw.FlexColumnWidth(2),
                2: pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  children: [
                    _headerCell('Description'),
                    _headerCell('Mode', align: pw.TextAlign.center),
                    _headerCell('Amount', align: pw.TextAlign.right),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _bodyCell(transaction.displayDescription),
                    _bodyCell(
                      transaction.paymentMode ?? '-',
                      align: pw.TextAlign.center,
                    ),
                    _bodyCell(
                      '\$${transaction.amount.toStringAsFixed(2)}',
                      align: pw.TextAlign.right,
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 12),
            _totalRow(transaction.amount),
          ],
        ),
      ),
    );

    return doc.save();
  }

  static DateTime? _tryParse(String? raw) {
    final trimmed = raw?.trim() ?? '';
    return trimmed.isEmpty ? null : DateTime.tryParse(trimmed);
  }

  static const PdfColor _avatarBackground = PdfColor.fromInt(0xFFB79FE0);

  /// Mirrors [BillingSchoolHeader]: initials avatar + name + tagline + address.
  static pw.Widget _schoolHeader(
    String schoolName,
    String tagline,
    String address,
  ) {
    final name = schoolName.isEmpty ? 'WowCare' : schoolName;
    final initials = name.initials;

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 48,
          height: 48,
          alignment: pw.Alignment.center,
          decoration: const pw.BoxDecoration(
            color: _avatarBackground,
            shape: pw.BoxShape.circle,
          ),
          child: pw.Text(
            initials,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                name,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              if (tagline.trim().isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2),
                  child: pw.Text(
                    tagline.trim(),
                    style: pw.TextStyle(fontSize: 13, color: _primaryColor),
                  ),
                ),
              if (address.trim().isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2),
                  child: pw.Text(
                    address.trim(),
                    style: pw.TextStyle(fontSize: 12, color: _primaryColor),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _billedForRow(String label, String name, String classroom) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(label, style: pw.TextStyle(color: _primaryColor, fontSize: 15)),
        pw.SizedBox(width: 8),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              name,
              style: pw.TextStyle(
                color: _primaryColor,
                fontSize: 15,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            if (classroom.trim().isNotEmpty)
              pw.Text(
                classroom.trim(),
                style: pw.TextStyle(
                  color: _primaryColor,
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _metaRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label : ',
              style: pw.TextStyle(color: _mutedColor, fontSize: 14),
            ),
            pw.TextSpan(
              text: value,
              style: pw.TextStyle(
                color: _primaryColor,
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _headerCell(String text, {pw.TextAlign? align}) =>
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: pw.Text(
          text,
          textAlign: align,
          style: pw.TextStyle(fontSize: 13, color: _mutedColor),
        ),
      );

  static pw.Widget _bodyCell(String text, {pw.TextAlign? align}) => pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
    child: pw.Text(
      text,
      textAlign: align,
      style: pw.TextStyle(
        fontSize: 14,
        color: _primaryColor,
        fontWeight: pw.FontWeight.bold,
      ),
    ),
  );

  static pw.Widget _itemsTable(List<List<String>> rows, double total) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Table(
          columnWidths: const {
            0: pw.FlexColumnWidth(4),
            1: pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              children: [
                _headerCell('Description'),
                _headerCell('Amount', align: pw.TextAlign.right),
              ],
            ),
            for (final row in rows)
              pw.TableRow(
                children: [
                  _bodyCell(row[0]),
                  _bodyCell(row[1], align: pw.TextAlign.right),
                ],
              ),
          ],
        ),
        pw.SizedBox(height: 12),
        _totalRow(total),
      ],
    );
  }

  static pw.Widget _totalRow(double total) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: const pw.BoxDecoration(color: _totalRowBackground),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Text(
            'Total Amount : \$${total.toStringAsFixed(2)}',
            style: pw.TextStyle(
              color: _primaryColor,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
