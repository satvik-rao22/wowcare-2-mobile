import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/data/services/xlsx_sheet_reader.dart';
import 'package:wowcare/presentation/features/reports/reports_strings.dart';

/// Parses [bytes] off the UI thread. Top-level so it can run under [compute].
XlsxWorkbook _parseWorkbook(Uint8List bytes) =>
    const XlsxSheetReader().parse(bytes);

/// Renders an `.xlsx` report's contents in-app.
///
/// iOS previews spreadsheets for free — open_filex hands the file to
/// QuickLook, which renders it. Android has no such system preview: the
/// equivalent call is an `ACTION_VIEW` intent that simply does nothing when no
/// spreadsheet app is installed, so a generated billing report appeared to
/// vanish. Reading the sheet ourselves is what puts the same content on screen
/// on both platforms.
class XlsxSheetView extends StatefulWidget {
  const XlsxSheetView({
    super.key,
    required this.fileData,
    required this.onDownload,
  });

  final Uint8List fileData;

  /// Hands the file to the OS, for anyone who wants it in Excel or Sheets.
  final VoidCallback onDownload;

  @override
  State<XlsxSheetView> createState() => _XlsxSheetViewState();
}

class _XlsxSheetViewState extends State<XlsxSheetView> {
  late final Future<XlsxWorkbook> _workbook;
  final ValueNotifier<int> _sheetIndex = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    // A large report is tens of thousands of cells of zip + XML work; on the
    // UI thread that is a visible freeze.
    _workbook = compute(_parseWorkbook, widget.fileData);
  }

  @override
  void dispose() {
    _sheetIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<XlsxWorkbook>(
      future: _workbook,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _XlsxMessage(
            icon: Icons.table_chart,
            title: ReportsStrings.excelFilePreview,
            detail: ReportsStrings.preparingPreview,
            showSpinner: true,
          );
        }

        if (snapshot.hasError) {
          // A workbook we cannot read is not a dead end — the file is already
          // saved, so offer the OS hand-off that used to be the only option.
          return _XlsxMessage(
            icon: Icons.table_chart,
            title: ReportsStrings.excelFilePreview,
            detail: ReportsStrings.couldNotPreviewSpreadsheet,
            onDownload: widget.onDownload,
          );
        }

        final workbook = snapshot.data!;
        return ValueListenableBuilder<int>(
          valueListenable: _sheetIndex,
          builder: (context, index, __) {
            final safeIndex = index.clamp(0, workbook.sheets.length - 1);
            final sheet = workbook.sheets[safeIndex];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (workbook.sheets.length > 1)
                  _SheetTabs(
                    sheets: workbook.sheets,
                    selectedIndex: safeIndex,
                    onSelected: (i) => _sheetIndex.value = i,
                  ),
                if (workbook.truncated)
                  const _PreviewNotice(
                    text: ReportsStrings.previewShowsPartOfThisSheet,
                  ),
                Expanded(
                  child: sheet.rows.isEmpty
                      ? _XlsxMessage(
                          icon: Icons.table_chart,
                          title: ReportsStrings.excelFilePreview,
                          detail: ReportsStrings.thisSheetHasNoData,
                          onDownload: widget.onDownload,
                        )
                      : _SheetGrid(key: ValueKey(safeIndex), sheet: sheet),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// The grid itself: the first row pinned as a header, every later row lazily
/// built, the whole thing scrolling sideways as one piece.
class _SheetGrid extends StatefulWidget {
  const _SheetGrid({super.key, required this.sheet});

  final XlsxSheet sheet;

  @override
  State<_SheetGrid> createState() => _SheetGridState();
}

class _SheetGridState extends State<_SheetGrid> {
  static const double _minColumnWidth = 84;
  static const double _maxColumnWidth = 260;
  static const double _rowHeight = 40;

  final ScrollController _horizontal = ScrollController();

  /// Widths are measured from content once, not per build.
  late final List<double> _columnWidths = _measureColumns(widget.sheet);
  late final double _totalWidth = _columnWidths.fold<double>(
    0,
    (sum, width) => sum + width,
  );

  @override
  void dispose() {
    _horizontal.dispose();
    super.dispose();
  }

  /// Sampling the first rows is enough to size a report's columns and keeps
  /// this O(columns) rather than O(cells) on a long sheet.
  static List<double> _measureColumns(XlsxSheet sheet) {
    const sampleRows = 60;
    final widths = List<double>.filled(sheet.columnCount, _minColumnWidth);

    final rowCount = sheet.rows.length < sampleRows
        ? sheet.rows.length
        : sampleRows;
    for (var r = 0; r < rowCount; r++) {
      final row = sheet.rows[r];
      for (var c = 0; c < row.length && c < widths.length; c++) {
        // ~7.2px per character at 13px Manrope, plus the cell's padding.
        final width = row[c].length * 7.2 + 24;
        if (width > widths[c]) {
          widths[c] = width > _maxColumnWidth ? _maxColumnWidth : width;
        }
      }
    }
    return widths;
  }

  @override
  Widget build(BuildContext context) {
    final header = widget.sheet.rows.first;
    final bodyRows = widget.sheet.rows.skip(1).toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        // A narrow report should still fill the screen rather than leave a
        // bare strip down the side; a wide one scrolls.
        final gridWidth = _totalWidth > constraints.maxWidth
            ? _totalWidth
            : constraints.maxWidth;

        return Scrollbar(
          // Horizontal scroll views never attach to the primary controller,
          // so the scrollbar needs its own to have a position to track.
          controller: _horizontal,
          child: SingleChildScrollView(
            controller: _horizontal,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: gridWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Outside the ListView, so the header stays put while the
                  // rows scroll under it and moves with them sideways.
                  _SheetRow(
                    cells: header,
                    widths: _columnWidths,
                    rowHeight: _rowHeight,
                    isHeader: true,
                  ),
                  Expanded(
                    child: ListView.builder(
                      primary: false,
                      itemCount: bodyRows.length,
                      itemExtent: _rowHeight,
                      itemBuilder: (context, index) => _SheetRow(
                        cells: bodyRows[index],
                        widths: _columnWidths,
                        rowHeight: _rowHeight,
                        // Banding, so a wide row stays readable across the
                        // scroll.
                        isBanded: index.isOdd,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({
    required this.cells,
    required this.widths,
    required this.rowHeight,
    this.isHeader = false,
    this.isBanded = false,
  });

  final List<String> cells;
  final List<double> widths;
  final double rowHeight;
  final bool isHeader;
  final bool isBanded;

  @override
  Widget build(BuildContext context) {
    final style = isHeader
        ? AppTextStyles.reportsFieldValue(fontSize: 13)
        : AppTextStyles.reportsFieldLabel(fontSize: 13);

    return Container(
      height: rowHeight,
      decoration: BoxDecoration(
        color: isHeader
            ? AppColors.fieldBackgroundColor
            : isBanded
            ? AppColors.fieldBackgroundColor.withValues(alpha: 0.04)
            : AppColors.cardColor,
        border: const Border(
          bottom: BorderSide(color: AppColors.reportsCardDividerColor),
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < widths.length; i++)
            Container(
              width: widths[i],
              height: rowHeight,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.xs),
              child: Text(
                i < cells.length ? cells[i] : '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
        ],
      ),
    );
  }
}

class _SheetTabs extends StatelessWidget {
  const _SheetTabs({
    required this.sheets,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<XlsxSheet> sheets;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm,
          vertical: AppSizes.xs,
        ),
        itemCount: sheets.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSizes.xs),
        itemBuilder: (context, index) {
          final selected = index == selectedIndex;
          return ChoiceChip(
            label: Text(sheets[index].name),
            selected: selected,
            onSelected: (_) => onSelected(index),
            labelStyle: AppTextStyles.reportsFieldValue(fontSize: 13).copyWith(
              color: selected ? AppColors.cardColor : AppColors.primaryColor,
            ),
            selectedColor: AppColors.primaryColor,
            backgroundColor: AppColors.fieldBackgroundColor,
            showCheckmark: false,
          );
        },
      ),
    );
  }
}

class _PreviewNotice extends StatelessWidget {
  const _PreviewNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.fieldBackgroundColor,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.sm,
        vertical: AppSizes.xs,
      ),
      child: Text(text, style: AppTextStyles.reportsNote),
    );
  }
}

/// Shared loading / empty / unreadable state, matching the placeholder this
/// view replaced.
class _XlsxMessage extends StatelessWidget {
  const _XlsxMessage({
    required this.icon,
    required this.title,
    required this.detail,
    this.onDownload,
    this.showSpinner = false,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback? onDownload;
  final bool showSpinner;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (showSpinner)
              const CircularProgressIndicator()
            else
              Icon(icon, size: 64, color: AppColors.reportsMutedColor),
            const SizedBox(height: AppSizes.md),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSizes.xs),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (onDownload != null) ...[
              const SizedBox(height: AppSizes.xl),
              ElevatedButton.icon(
                icon: const Icon(Icons.download),
                label: const Text(ReportsStrings.downloadFile),
                onPressed: onDownload,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
