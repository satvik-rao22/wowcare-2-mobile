import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
// import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:wowcare/core/common/widgets/custom_curved_appbar.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PdfViewerPage extends StatefulWidget {
  final Uint8List pdfData;
  final String year;
  final String month;

  const PdfViewerPage({super.key, required this.pdfData, required this.year, required this.month});

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  ScrollController scrollController = ScrollController();
  final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

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

  Future<bool> _requestPermissions() async {
    debugPrint("Requesting permissions...");
    
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      final sdkInt = androidInfo.version.sdkInt;
      debugPrint("Android SDK Version: $sdkInt");

      if (sdkInt >= 33) {
        // For Android 13+, only request all media permissions
        final status = await Permission.manageExternalStorage.request();
        debugPrint("Manage external storage permission status: $status");
        return status.isGranted;
      } else {
        // For Android 12 and below
        final status = await Permission.storage.request();
        debugPrint("Storage permission status: $status");
        return status.isGranted;
      }
    }
    return true; // For iOS
  }

  Future<void> _downloadPdf(Uint8List fileBytes, BuildContext context) async {
    debugPrint("Starting PDF download process...");
    
    try {
      final hasPermission = await _requestPermissions();
      debugPrint("Has permission: $hasPermission");

      if (!hasPermission) {
        debugPrint("Permission not granted");
        final bool shouldOpenSettings = await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Storage Permission Required'),
            content: const Text(
              'To save PDF files, this app needs storage permission.\n\n'
              'Please grant "All files access" permission in the next screen.',
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: const Text('Open Settings'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ) ?? false;

        if (shouldOpenSettings) {
          await openAppSettings();
        }
        return;
      }

      String? filePath;
      if (Platform.isAndroid) {
        try {
          final downloadsDir = Directory('/storage/emulated/0/Download');
          bool dirExists = await downloadsDir.exists();
          if (!dirExists) {
            await downloadsDir.create(recursive: true);
            debugPrint("Downloads directory created");
          }
          
          final fileName = 'payslip_${widget.month}_${widget.year}.pdf';
          filePath = '${downloadsDir.path}/$fileName';
          debugPrint("Attempting to save file to: $filePath");
          
          final file = File(filePath);
          await file.writeAsBytes(fileBytes);
          debugPrint("File written successfully");
          
          CoreUtils.showSnackBar(
            context,
            'File saved to Downloads folder',
          );
        } catch (e) {
          debugPrint("Error saving to downloads: $e");
          // Fallback to app documents directory
          final appDir = await getApplicationDocumentsDirectory();
          final fileName = 'payslip_${DateTime.now().millisecondsSinceEpoch}.pdf';
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
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'payslip_${DateTime.now().millisecondsSinceEpoch}.pdf';
        filePath = '${directory.path}/$fileName';
        
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);
        
        CoreUtils.showSnackBar(
          context,
          'File saved to Documents folder',
        );
      }
    } catch (e) {
      debugPrint("Error in download process: $e");
      CoreUtils.showSnackBar(
        context,
        'Error saving file: ${e.toString()}',
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
              debugPrint("Download button pressed");
              _downloadPdf(widget.pdfData, context);
            },
          ),
        ],
        scrollController: scrollController,
      ),
      body: PDFView(
        pdfData: widget.pdfData,
      ),
    );
  }
}
