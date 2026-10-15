import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:wowcare/core/utils/file_utils/file_utils.dart';
import 'package:wowcare/core/utils/app_time.dart';
// import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'dart:io';

import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/logger_service.dart';

import '../widgets/custom_curved_appbar.dart';

class PdfViewerPage extends StatefulWidget {
  final Uint8List pdfData;
  final String year;
  final String month;

  const PdfViewerPage({
    super.key,
    required this.pdfData,
    required this.year,
    required this.month,
  });

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // _enableSecureMode();
  }

  @override
  void dispose() {
    // _disableSecureMode();
    super.dispose();
  }

  // Future<void> _enableSecureMode() async {
  //   try {
  //     await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
  //     debugPrint("Secure mode enabled");
  //   } catch (e) {
  //     debugPrint("Error enabling secure mode: $e");
  //   }
  // }

  // Future<void> _disableSecureMode() async {
  //   await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
  // }

  // No runtime permission is needed — or obtainable. The manifest removes
  // READ/WRITE_EXTERNAL_STORAGE and never declares MANAGE_EXTERNAL_STORAGE
  // (a Play-restricted permission), so the old storage request always came
  // back denied and sent users to Settings for a toggle that isn't there.
  // Android 11+ lets an app create its own files in Download/ without any
  // permission; on older versions the write fails and the fallback below
  // saves to the app's folder instead.
  Future<void> _downloadPdf(Uint8List fileBytes, BuildContext context) async {
    AppLogger.d("Starting PDF download process...");

    try {
      String? filePath;
      if (Platform.isAndroid) {
        try {
          final downloadsDir = Directory('/storage/emulated/0/Download');
          bool dirExists = await downloadsDir.exists();
          if (!dirExists) {
            await downloadsDir.create(recursive: true);
            AppLogger.d("Downloads directory created");
          }

          final fileName = 'payslip_${widget.month}_${widget.year}.pdf';
          filePath = '${downloadsDir.path}/$fileName';
          AppLogger.d("Attempting to save file to: $filePath");

          final file = File(filePath);
          await file.writeAsBytes(fileBytes);
          AppLogger.d("File written successfully");

          CoreUtils.showSnackBar(context, 'File saved to Downloads folder');
        } catch (e) {
          AppLogger.w("Error saving to downloads: $e");
          // Fallback to app documents directory
          final appDir = await FileUtils.documentsDirectory();
          final fileName =
              'payslip_${AppTime.nowUtc().millisecondsSinceEpoch}.pdf';
          filePath = '${appDir.path}/$fileName';

          final file = File(filePath);
          await file.writeAsBytes(fileBytes);

          CoreUtils.showSnackBar(
            context,
            'File saved to app folder (internal storage)',
          );
        }
      } else {
        // iOS implementation
        final directory = await FileUtils.documentsDirectory();
        final fileName =
            'payslip_${AppTime.nowUtc().millisecondsSinceEpoch}.pdf';
        filePath = '${directory.path}/$fileName';

        final file = File(filePath);
        await file.writeAsBytes(fileBytes);

        CoreUtils.showSnackBar(context, 'File saved to Documents folder');
      }
    } catch (e) {
      AppLogger.w("Error in download process: $e");
      CoreUtils.showSnackBar(
        context,
        'Could not save the file. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomCurvedAppBar(
        title: "Payslip",
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              AppLogger.d("Download button pressed");
              _downloadPdf(widget.pdfData, context);
            },
          ),
        ],
        scrollController: scrollController,
      ),
      body: PDFView(pdfData: widget.pdfData),
    );
  }
}
