import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// One parsed worksheet: a rectangular grid of already-formatted cell text.
class XlsxSheet {
  const XlsxSheet({required this.name, required this.rows});

  final String name;

  /// Row-major cell text. Every row is padded to the same length, so callers
  /// can index by column without bounds checks.
  final List<List<String>> rows;

  int get columnCount => rows.isEmpty ? 0 : rows.first.length;
}

/// The sheets of one workbook, plus whether the preview stopped early.
class XlsxWorkbook {
  const XlsxWorkbook({required this.sheets, required this.truncated});

  final List<XlsxSheet> sheets;

  /// True when [XlsxSheetReader.cellBudget] was hit and later rows were
  /// dropped, so the UI can say the preview is partial.
  final bool truncated;
}

/// Thrown when the bytes are not a workbook this reader can make sense of.
class XlsxParseException implements Exception {
  const XlsxParseException(this.message);

  final String message;

  @override
  String toString() => 'XlsxParseException: $message';
}

/// Reads the cell text out of an `.xlsx` file.
///
/// An `.xlsx` is a zip of XML parts, so this needs no platform channel and no
/// installed spreadsheet app — which is the whole point. On iOS, open_filex
/// hands the file to QuickLook and the user sees the report; on Android the
/// same call is an `ACTION_VIEW` intent that does nothing at all when no app
/// declares the XLSX mime type. Parsing the sheet here is what lets the
/// in-app viewer show the same content on both platforms.
///
/// This reads *values*, not styling: fonts, colours, borders and merges are
/// ignored. Number formats are honoured only far enough to render dates as
/// dates instead of as their serial number, because a report full of `45892`
/// where a date belongs is worse than no preview at all.
class XlsxSheetReader {
  const XlsxSheetReader();

  /// Stop after this many cells so a pathologically large workbook cannot
  /// exhaust memory on a phone. ~60 columns × 1600 rows of a real report.
  static const int cellBudget = 100000;

  /// Excel's day-zero. Serial 1 is 1900-01-01, and Excel's deliberate
  /// 1900-leap-year bug means counting from 1899-12-30 lands correctly for
  /// every date from 1900-03-01 on — which is every date a report contains.
  static final DateTime _serialEpoch = DateTime.utc(1899, 12, 30);

  /// Built-in `numFmtId`s that mean "this number is a date and/or a time".
  static const Set<int> _builtInDateFormats = {
    14, 15, 16, 17, 18, 19, 20, 21, 22, 45, 46, 47,
  };

  XlsxWorkbook parse(Uint8List bytes) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (e) {
      throw XlsxParseException('This file is not a readable spreadsheet.');
    }

    final files = <String, ArchiveFile>{
      for (final file in archive.files)
        if (file.isFile) _normalize(file.name): file,
    };

    final workbookXml = _document(files, 'xl/workbook.xml');
    if (workbookXml == null) {
      throw XlsxParseException('This file is not a readable spreadsheet.');
    }

    final sharedStrings = _readSharedStrings(files);
    final dateStyles = _readDateStyles(files);
    final relations = _readRelations(files);

    final sheets = <XlsxSheet>[];
    var remainingCells = cellBudget;
    var truncated = false;

    for (final node in workbookXml.findAllElements('sheet')) {
      final name = node.getAttribute('name') ?? 'Sheet${sheets.length + 1}';
      final target = _sheetTarget(node, relations, sheets.length);
      final sheetXml = _document(files, target);
      if (sheetXml == null) continue;

      final result = _readSheet(
        sheetXml,
        sharedStrings: sharedStrings,
        dateStyles: dateStyles,
        cellBudget: remainingCells,
      );
      remainingCells -= result.cellsRead;
      truncated = truncated || result.truncated;
      sheets.add(XlsxSheet(name: name, rows: result.rows));

      if (remainingCells <= 0) {
        truncated = true;
        break;
      }
    }

    if (sheets.isEmpty) {
      throw XlsxParseException('This spreadsheet has no readable sheets.');
    }

    return XlsxWorkbook(sheets: sheets, truncated: truncated);
  }

  // —— parts ——————————————————————————————————————————————

  /// Zip entries are sometimes written with a leading `/` or with backslashes;
  /// look everything up under one spelling.
  static String _normalize(String path) =>
      path.replaceAll('\\', '/').replaceFirst(RegExp(r'^/+'), '');

  XmlDocument? _document(Map<String, ArchiveFile> files, String path) {
    final file = files[_normalize(path)];
    if (file == null) return null;
    try {
      // These parts are UTF-8, and report data is full of names and addresses
      // that are not ASCII — decoding byte-per-code-unit would mangle them.
      final content = utf8.decode(
        file.content as List<int>,
        allowMalformed: true,
      );
      return XmlDocument.parse(content);
    } catch (_) {
      return null;
    }
  }

  /// `rId` → part path, from `xl/_rels/workbook.xml.rels`.
  Map<String, String> _readRelations(Map<String, ArchiveFile> files) {
    final document = _document(files, 'xl/_rels/workbook.xml.rels');
    if (document == null) return const <String, String>{};

    final relations = <String, String>{};
    for (final node in document.findAllElements('Relationship')) {
      final id = node.getAttribute('Id');
      final target = node.getAttribute('Target');
      if (id == null || target == null) continue;
      // Targets are relative to `xl/`, except the absolute ones.
      relations[id] = target.startsWith('/')
          ? _normalize(target)
          : 'xl/${_normalize(target)}';
    }
    return relations;
  }

  String _sheetTarget(
    XmlElement sheet,
    Map<String, String> relations,
    int index,
  ) {
    // The r:id attribute is namespaced; match on local name so a workbook
    // that binds the relationship namespace to a different prefix still works.
    final relationId = sheet.attributes
        .where((a) => a.name.local == 'id')
        .map((a) => a.value)
        .firstOrNull;
    final target = relationId == null ? null : relations[relationId];
    // Positional fallback for workbooks with no usable rels part.
    return target ?? 'xl/worksheets/sheet${index + 1}.xml';
  }

  /// The shared string table, which is where most text in a sheet lives —
  /// a cell with `t="s"` holds an index into this list, not the text itself.
  List<String> _readSharedStrings(Map<String, ArchiveFile> files) {
    final document = _document(files, 'xl/sharedStrings.xml');
    if (document == null) return const <String>[];

    return document
        .findAllElements('si')
        // Rich text splits one string across several <r><t> runs; concatenating
        // every descendant <t> reassembles it and is a no-op for plain <t>.
        .map((si) => si.findAllElements('t').map((t) => t.innerText).join())
        .toList();
  }

  /// Indices into `cellXfs` whose number format renders as a date or time.
  Set<int> _readDateStyles(Map<String, ArchiveFile> files) {
    final document = _document(files, 'xl/styles.xml');
    if (document == null) return const <int>{};

    final customDateFormats = <int>{};
    for (final node in document.findAllElements('numFmt')) {
      final id = int.tryParse(node.getAttribute('numFmtId') ?? '');
      final code = node.getAttribute('formatCode');
      if (id == null || code == null) continue;
      if (_looksLikeDateFormat(code)) customDateFormats.add(id);
    }

    final dateStyles = <int>{};
    final cellXfs = document.findAllElements('cellXfs').firstOrNull;
    if (cellXfs == null) return dateStyles;

    var index = 0;
    for (final xf in cellXfs.findElements('xf')) {
      final id = int.tryParse(xf.getAttribute('numFmtId') ?? '');
      if (id != null &&
          (_builtInDateFormats.contains(id) || customDateFormats.contains(id))) {
        dateStyles.add(index);
      }
      index++;
    }
    return dateStyles;
  }

  /// A format code is a date format when it uses date/time tokens outside of
  /// quoted literals — `"y"` in `0.00"yards"` must not count.
  static bool _looksLikeDateFormat(String code) {
    final unquoted = code
        .replaceAll(RegExp(r'"[^"]*"'), '')
        .replaceAll(RegExp(r'\[[^\]]*\]'), '')
        .replaceAll(RegExp(r'\\.'), '');
    return RegExp('[ymdhs]', caseSensitive: false).hasMatch(unquoted);
  }

  // —— sheet ——————————————————————————————————————————————

  _SheetResult _readSheet(
    XmlDocument document, {
    required List<String> sharedStrings,
    required Set<int> dateStyles,
    required int cellBudget,
  }) {
    final rows = <List<String>>[];
    var widest = 0;
    var cellsRead = 0;
    var truncated = false;

    outer:
    for (final rowNode in document.findAllElements('row')) {
      final cells = <int, String>{};
      var rightmost = -1;

      for (final cellNode in rowNode.findElements('c')) {
        if (cellsRead >= cellBudget) {
          truncated = true;
          break outer;
        }
        cellsRead++;

        final column = _columnIndex(cellNode.getAttribute('r'), rightmost + 1);
        final text = _cellText(
          cellNode,
          sharedStrings: sharedStrings,
          dateStyles: dateStyles,
        );
        rightmost = column > rightmost ? column : rightmost;
        if (text.isNotEmpty) cells[column] = text;
      }

      final width = rightmost + 1;
      if (width > widest) widest = width;
      rows.add(
        List<String>.generate(width, (i) => cells[i] ?? '', growable: false),
      );
    }

    // Drop trailing all-blank rows, which spreadsheets emit freely, then pad
    // every remaining row to the widest so the grid is rectangular.
    while (rows.isNotEmpty && rows.last.every((cell) => cell.isEmpty)) {
      rows.removeLast();
    }
    final padded = rows
        .map(
          (row) => List<String>.generate(
            widest,
            (i) => i < row.length ? row[i] : '',
            growable: false,
          ),
        )
        .toList();

    return _SheetResult(
      rows: padded,
      cellsRead: cellsRead,
      truncated: truncated,
    );
  }

  /// `"BC12"` → 54. Falls back to [ifAbsent] for a cell with no `r`, which is
  /// legal and means "the next column along".
  static int _columnIndex(String? reference, int ifAbsent) {
    if (reference == null || reference.isEmpty) return ifAbsent;

    var index = 0;
    var sawLetter = false;
    for (final unit in reference.codeUnits) {
      if (unit >= 0x41 && unit <= 0x5A) {
        index = index * 26 + (unit - 0x40);
        sawLetter = true;
      } else if (unit >= 0x61 && unit <= 0x7A) {
        index = index * 26 + (unit - 0x60);
        sawLetter = true;
      } else {
        break;
      }
    }
    return sawLetter ? index - 1 : ifAbsent;
  }

  String _cellText(
    XmlElement cell, {
    required List<String> sharedStrings,
    required Set<int> dateStyles,
  }) {
    final type = cell.getAttribute('t');

    // Inline strings keep their text in the cell rather than the shared table.
    if (type == 'inlineStr') {
      final inline = cell.findElements('is').firstOrNull;
      if (inline == null) return '';
      return inline.findAllElements('t').map((t) => t.innerText).join();
    }

    final value = cell.findElements('v').firstOrNull?.innerText;
    if (value == null || value.isEmpty) return '';

    switch (type) {
      case 's':
        final index = int.tryParse(value);
        if (index == null || index < 0 || index >= sharedStrings.length) {
          return '';
        }
        return sharedStrings[index];
      case 'b':
        return value == '1' ? 'TRUE' : 'FALSE';
      case 'e':
      case 'str':
        return value;
    }

    // Untyped (or t="n") is a number — which is also how a date is stored.
    final styleIndex = int.tryParse(cell.getAttribute('s') ?? '');
    final number = double.tryParse(value);
    if (number == null) return value;
    if (styleIndex != null && dateStyles.contains(styleIndex)) {
      return _formatSerialDate(number);
    }
    return _formatNumber(number, value);
  }

  static String _formatSerialDate(double serial) {
    final whole = serial.floor();
    final dayFraction = serial - whole;
    final date = _serialEpoch.add(Duration(days: whole));
    final time = Duration(milliseconds: (dayFraction * 86400000).round());

    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    final day = '$mm/$dd/${date.year}';

    // A serial below 1 is a bare time-of-day, and any fraction means the cell
    // carries a time worth showing alongside the date.
    if (dayFraction == 0) return serial < 1 ? '12:00 AM' : day;

    final totalMinutes = time.inMinutes % 1440;
    final hour24 = totalMinutes ~/ 60;
    final minute = (totalMinutes % 60).toString().padLeft(2, '0');
    final suffix = hour24 < 12 ? 'AM' : 'PM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final clock = '$hour12:$minute $suffix';

    return serial < 1 ? clock : '$day $clock';
  }

  /// Keeps whole numbers whole (`3` not `3.0`) and otherwise leaves the
  /// stored precision alone, trimming only the float noise `double` adds.
  static String _formatNumber(double number, String raw) {
    if (number == number.roundToDouble() && number.abs() < 1e15) {
      return number.toStringAsFixed(0);
    }
    final rendered = number.toString();
    return rendered.length <= raw.length ? rendered : raw;
  }
}

class _SheetResult {
  const _SheetResult({
    required this.rows,
    required this.cellsRead,
    required this.truncated,
  });

  final List<List<String>> rows;
  final int cellsRead;
  final bool truncated;
}
