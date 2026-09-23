import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/constants/app_sizes.dart';
import 'package:wowcare/presentation/features/reports/reports_strings.dart';
import 'package:wowcare/presentation/features/reports/widgets/xlsx_sheet_view.dart';

class ReportFileViewerScreen extends StatefulWidget {
  final Uint8List fileData;
  final String fileName;
  final String fileType; // 'pdf' or 'xlsx'

  const ReportFileViewerScreen({
    super.key,
    required this.fileData,
    required this.fileName,
    required this.fileType,
  });

  @override
  State<ReportFileViewerScreen> createState() => _ReportFileViewerScreenState();
}

class _ReportFileViewerScreenState extends State<ReportFileViewerScreen> {
  late ScrollController scrollController;

  /// §2.2 bucket B — the save-in-progress spinner is UI micro-state.
  final ValueNotifier<bool> _isDownloading = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
  }

  @override
  void dispose() {
    scrollController.dispose();
    _isDownloading.dispose();
    super.dispose();
  }

  Future<void> _downloadFile() async {
    AppLogger.d('Starting file save process...');

    if (_isDownloading.value) return;

    _isDownloading.value = true;

    try {
      // Save to app documents directory (no special permissions required)
      String filePath;

      if (Platform.isAndroid) {
        final appDir = await getApplicationDocumentsDirectory();
        filePath = '${appDir.path}/${widget.fileName}';
        AppLogger.d('Saving file to Android app documents: $filePath');
      } else {
        // iOS
        final directory = await getApplicationDocumentsDirectory();
        filePath = '${directory.path}/${widget.fileName}';
        AppLogger.d('Saving file to iOS documents: $filePath');
      }

      final file = File(filePath);
      await file.writeAsBytes(widget.fileData);
      AppLogger.d('File saved successfully to: $filePath');

      if (mounted) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: '${widget.fileName} saved successfully',
          isSuccess: true,
        );
      }
    } catch (e) {
      AppLogger.e('Error saving file: $e');
      if (mounted) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Error saving file: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        _isDownloading.value = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.fileName),
        elevation: 0,
        actions: [
          ValueListenableBuilder<bool>(
            valueListenable: _isDownloading,
            builder: (context, downloading, _) => downloading
                ? const Padding(
                    padding: EdgeInsets.all(AppSizes.md),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.cardColor,
                        ),
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.download),
                    onPressed: _downloadFile,
                    tooltip: ReportsStrings.download,
                  ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
            tooltip: ReportsStrings.close,
          ),
        ],
      ),
      body: _FileViewerBody(
        fileType: widget.fileType,
        fileData: widget.fileData,
        onDownload: _downloadFile,
      ),
    );
  }
}

/// Renders the report's bytes: a PDF view, or a placeholder with a download
/// action for formats that cannot be previewed in-app.
///
/// Was `Widget _buildFileViewer()` on the State (§6.4).
class _FileViewerBody extends StatelessWidget {
  const _FileViewerBody({
    required this.fileType,
    required this.fileData,
    required this.onDownload,
  });

  final String fileType;
  final Uint8List fileData;
  final VoidCallback onDownload;

  @override
  Widget build(BuildContext context) {
    if (fileType.toLowerCase() == 'pdf') {
      return PDFView(pdfData: fileData);
    } else if (fileType.toLowerCase() == 'xlsx') {
      // Was an icon and a Download button — no report content at all, which
      // left Android users with nothing to look at whenever no spreadsheet app
      // was installed to take the OS hand-off. [XlsxSheetView] reads the
      // workbook itself, so the report is on screen the way iOS QuickLook
      // shows it, and Download still hands the file to the OS.
      return XlsxSheetView(fileData: fileData, onDownload: onDownload);
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description,
              size: 64,
              color: AppColors.reportsMutedColor,
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              ReportsStrings.filePreview,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSizes.xs),
            Text(
              ReportsStrings.fileTypeNotSupportedForPreview,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSizes.xl),
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text(ReportsStrings.downloadFile),
              onPressed: onDownload,
            ),
          ],
        ),
      );
    }
  }
}
