import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/presentation/features/reports/reports_strings.dart';
import 'package:wowcare/presentation/features/reports/widgets/xlsx_sheet_view.dart';

/// A one-sheet workbook holding [strings] laid out as [rows] rows of equal
/// width, built as a real zip so the widget parses what it would in the app.
Uint8List buildWorkbook(List<List<String>> rows) {
  final shared = <String>[];
  for (final row in rows) {
    for (final cell in row) {
      if (!shared.contains(cell)) shared.add(cell);
    }
  }

  final buffer = StringBuffer();
  for (var r = 0; r < rows.length; r++) {
    buffer.write('<row r="${r + 1}">');
    for (var c = 0; c < rows[r].length; c++) {
      final ref = '${String.fromCharCode(0x41 + c)}${r + 1}';
      buffer.write('<c r="$ref" t="s"><v>${shared.indexOf(rows[r][c])}</v></c>');
    }
    buffer.write('</row>');
  }

  final archive = Archive();
  void add(String path, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(path, bytes.length, bytes));
  }

  add(
    'xl/workbook.xml',
    '<workbook xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
    '<sheets><sheet name="Invoice" sheetId="1" r:id="rId1"/></sheets>'
    '</workbook>',
  );
  add(
    'xl/_rels/workbook.xml.rels',
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
    '<Relationship Id="rId1" Target="worksheets/sheet1.xml"/>'
    '</Relationships>',
  );
  add(
    'xl/sharedStrings.xml',
    '<sst>${shared.map((s) => '<si><t>$s</t></si>').join()}</sst>',
  );
  add(
    'xl/worksheets/sheet1.xml',
    '<worksheet><sheetData>$buffer</sheetData></worksheet>',
  );

  return Uint8List.fromList(ZipEncoder().encode(archive));
}

void main() {
  Widget wrap(Widget child) => MaterialApp(
    home: Scaffold(body: SizedBox(width: 400, height: 600, child: child)),
  );

  /// The view parses on a real isolate via [compute], which fake-async time
  /// never advances — so let real time pass until the spinner goes away.
  /// `pumpAndSettle` cannot be used here: the progress indicator animates
  /// forever and would never settle.
  Future<void> settleParse(WidgetTester tester) async {
    for (var attempt = 0; attempt < 100; attempt++) {
      await tester.pump();
      if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
        await tester.pump();
        return;
      }
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
    }
    fail('The workbook never finished parsing.');
  }

  testWidgets('renders the workbook\'s cells rather than a placeholder', (
    tester,
  ) async {
    final bytes = buildWorkbook([
      ['Student', 'Invoice', 'Amount'],
      ['Avira Jadhav', 'INV-001', '250.00'],
      ['Ravi Kumar', 'INV-002', '180.00'],
    ]);

    await tester.pumpWidget(
      wrap(XlsxSheetView(fileData: bytes, onDownload: () {})),
    );
    await settleParse(tester);

    // The header row and every data row are on screen — this is the whole
    // point on Android, where the OS shows nothing for an XLSX.
    expect(find.text('Student'), findsOneWidget);
    expect(find.text('Amount'), findsOneWidget);
    expect(find.text('Avira Jadhav'), findsOneWidget);
    expect(find.text('INV-002'), findsOneWidget);

    // The old placeholder copy is gone.
    expect(
      find.text(ReportsStrings.tapDownloadToSaveAndOpenThisExcelFile),
      findsNothing,
    );
  });

  testWidgets('offers the OS hand-off when the bytes are unreadable', (
    tester,
  ) async {
    final notAWorkbook = Uint8List.fromList(utf8.encode('definitely not xlsx'));
    var downloads = 0;

    await tester.pumpWidget(
      wrap(
        XlsxSheetView(fileData: notAWorkbook, onDownload: () => downloads++),
      ),
    );
    await settleParse(tester);

    expect(find.text(ReportsStrings.couldNotPreviewSpreadsheet), findsOneWidget);

    await tester.tap(find.text(ReportsStrings.downloadFile));
    expect(downloads, 1);
  });
}
