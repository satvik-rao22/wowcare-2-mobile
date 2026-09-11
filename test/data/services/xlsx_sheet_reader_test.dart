import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/services/xlsx_sheet_reader.dart';

/// Builds a minimal but structurally real `.xlsx` — a zip of the same XML
/// parts Excel writes — so the reader is exercised against the format rather
/// than against a stub.
Uint8List buildWorkbook({
  required String sheetXml,
  List<String> sharedStrings = const <String>[],
  String? stylesXml,
  String sheetName = 'Report',
}) {
  final archive = Archive();

  void add(String path, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(path, bytes.length, bytes));
  }

  add(
    'xl/workbook.xml',
    '<?xml version="1.0"?>'
    '<workbook xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
    '<sheets><sheet name="$sheetName" sheetId="1" r:id="rId1"/></sheets>'
    '</workbook>',
  );
  add(
    'xl/_rels/workbook.xml.rels',
    '<?xml version="1.0"?>'
    '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
    '<Relationship Id="rId1" Target="worksheets/sheet1.xml"/>'
    '</Relationships>',
  );
  add('xl/worksheets/sheet1.xml', sheetXml);

  if (sharedStrings.isNotEmpty) {
    final items = sharedStrings
        .map((s) => '<si><t>${const HtmlEscape().convert(s)}</t></si>')
        .join();
    add(
      'xl/sharedStrings.xml',
      '<?xml version="1.0"?><sst count="${sharedStrings.length}">$items</sst>',
    );
  }
  if (stylesXml != null) add('xl/styles.xml', stylesXml);

  return Uint8List.fromList(ZipEncoder().encode(archive));
}

String sheet(String rows) =>
    '<?xml version="1.0"?><worksheet><sheetData>$rows</sheetData></worksheet>';

void main() {
  const reader = XlsxSheetReader();

  test('reads shared strings, inline strings and numbers into a grid', () {
    final bytes = buildWorkbook(
      sharedStrings: ['Student', 'Amount', 'Avira Jadhav'],
      sheetXml: sheet(
        '<row r="1">'
        '<c r="A1" t="s"><v>0</v></c>'
        '<c r="B1" t="s"><v>1</v></c>'
        '</row>'
        '<row r="2">'
        '<c r="A2" t="s"><v>2</v></c>'
        '<c r="B2"><v>250</v></c>'
        '</row>'
        '<row r="3">'
        '<c r="A3" t="inlineStr"><is><t>Ravi Kumar</t></is></c>'
        '<c r="B3"><v>99.5</v></c>'
        '</row>',
      ),
    );

    final workbook = reader.parse(bytes);

    expect(workbook.sheets, hasLength(1));
    expect(workbook.sheets.single.name, 'Report');
    expect(workbook.truncated, isFalse);
    expect(workbook.sheets.single.rows, [
      ['Student', 'Amount'],
      ['Avira Jadhav', '250'],
      ['Ravi Kumar', '99.5'],
    ]);
  });

  test('places sparse cells at the column their reference names', () {
    final bytes = buildWorkbook(
      sharedStrings: ['A', 'C', 'Z'],
      // B is skipped entirely, which is how spreadsheets store a blank cell.
      sheetXml: sheet(
        '<row r="1">'
        '<c r="A1" t="s"><v>0</v></c>'
        '<c r="C1" t="s"><v>1</v></c>'
        '<c r="Z1" t="s"><v>2</v></c>'
        '</row>',
      ),
    );

    final row = reader.parse(bytes).sheets.single.rows.single;

    expect(row, hasLength(26));
    expect(row[0], 'A');
    expect(row[1], '');
    expect(row[2], 'C');
    expect(row[25], 'Z');
  });

  test('renders a date-formatted serial as a date, not as its number', () {
    // cellXfs index 1 uses built-in numFmtId 14 (m/d/yyyy); index 0 does not.
    const styles =
        '<?xml version="1.0"?><styleSheet>'
        '<cellXfs count="2">'
        '<xf numFmtId="0"/>'
        '<xf numFmtId="14" applyNumberFormat="1"/>'
        '</cellXfs>'
        '</styleSheet>';

    final bytes = buildWorkbook(
      stylesXml: styles,
      sheetXml: sheet(
        '<row r="1">'
        '<c r="A1" s="1"><v>45000</v></c>'
        '<c r="B1" s="0"><v>45000</v></c>'
        '</row>',
      ),
    );

    final row = reader.parse(bytes).sheets.single.rows.single;

    // 45000 days after 1899-12-30 is 2023-03-15.
    expect(row[0], '03/15/2023');
    // Same serial, no date format — stays a plain number.
    expect(row[1], '45000');
  });

  test('a custom format whose date letters are all quoted is not a date', () {
    const styles =
        '<?xml version="1.0"?><styleSheet>'
        '<numFmts count="1">'
        '<numFmt numFmtId="200" formatCode="0.00&quot;yards&quot;"/>'
        '</numFmts>'
        '<cellXfs count="1"><xf numFmtId="200"/></cellXfs>'
        '</styleSheet>';

    final bytes = buildWorkbook(
      stylesXml: styles,
      sheetXml: sheet('<row r="1"><c r="A1" s="0"><v>12.5</v></c></row>'),
    );

    expect(reader.parse(bytes).sheets.single.rows.single.single, '12.5');
  });

  test('keeps non-ASCII text intact', () {
    final bytes = buildWorkbook(
      sharedStrings: ['José Muñoz', 'Crèche — Café'],
      sheetXml: sheet(
        '<row r="1">'
        '<c r="A1" t="s"><v>0</v></c>'
        '<c r="B1" t="s"><v>1</v></c>'
        '</row>',
      ),
    );

    expect(reader.parse(bytes).sheets.single.rows.single, [
      'José Muñoz',
      'Crèche — Café',
    ]);
  });

  test('drops trailing blank rows and pads the grid rectangular', () {
    final bytes = buildWorkbook(
      sharedStrings: ['H1', 'H2', 'only'],
      sheetXml: sheet(
        '<row r="1">'
        '<c r="A1" t="s"><v>0</v></c>'
        '<c r="B1" t="s"><v>1</v></c>'
        '</row>'
        '<row r="2"><c r="A2" t="s"><v>2</v></c></row>'
        '<row r="3"></row>'
        '<row r="4"></row>',
      ),
    );

    final rows = reader.parse(bytes).sheets.single.rows;

    expect(rows, hasLength(2));
    expect(rows.every((row) => row.length == 2), isTrue);
    expect(rows[1], ['only', '']);
  });

  test('rejects bytes that are not a workbook', () {
    expect(
      () => reader.parse(Uint8List.fromList(utf8.encode('not a zip at all'))),
      throwsA(isA<XlsxParseException>()),
    );
  });
}
