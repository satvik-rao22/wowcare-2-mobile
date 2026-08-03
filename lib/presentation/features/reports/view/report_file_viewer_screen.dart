import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/logger_service.dart';

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
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  Future<void> _downloadFile() async {
    AppLogger.d('Starting file save process...');

    if (_isDownloading) return;

    setState(() => _isDownloading = true);

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
        setState(() => _isDownloading = false);
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
          if (_isDownloading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _downloadFile,
              tooltip: 'Download',
            ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Close',
          ),
        ],
      ),
      body: _buildFileViewer(),
    );
  }

  Widget _buildFileViewer() {
    if (widget.fileType.toLowerCase() == 'pdf') {
      return PDFView(pdfData: widget.fileData);
    } else if (widget.fileType.toLowerCase() == 'xlsx') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.table_chart,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Excel File Preview',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap download to save and open this Excel file',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Download File'),
              onPressed: _downloadFile,
            ),
          ],
        ),
      );
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'File Preview',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'File type not supported for preview',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Download File'),
              onPressed: _downloadFile,
            ),
          ],
        ),
      );
    }
  }
}
