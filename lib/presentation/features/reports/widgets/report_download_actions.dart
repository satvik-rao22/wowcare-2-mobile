import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/router/app_routes.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/presentation/features/reports/model/report_route_args.dart';
import 'package:wowcare/presentation/features/reports/reports_strings.dart';
import 'package:wowcare/presentation/features/reports/view_model/reports_cubit.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/core/constants/app_sizes.dart';

/// Download / save / preview actions for a generated report.
///
/// Extracted from `reports_screen.dart` (§6.7) — it was ~180 lines of
/// orchestration on the screen's State. A mixin rather than a widget because
/// it needs `mounted` and the State's `context` for the progress dialogs.
mixin ReportDownloadActions<T extends StatefulWidget> on State<T> {
  /// Dismiss a dialog shown via [showDialog] (which defaults to the root
  /// navigator). Popping through the ambient [context] instead would hit
  /// go_router's branch navigator and pop the screen itself off the page
  /// stack, which crashes with `currentConfiguration.isNotEmpty` once no
  /// pages remain — always target the same (root) navigator the dialog was
  /// pushed on, and never pop when there's nothing left to pop.
  void dismissDialog(BuildContext context) {
    final navigator = Navigator.of(context, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  /// On-disk name for a downloaded report, made unique per [assetCode].
  ///
  /// Reports generated with different filters (e.g. Active vs Inactive staff)
  /// can come back with the same file name. Saving both to one path overwrote
  /// the first, and the OS viewer (iOS QuickLook in particular) kept showing
  /// its cached preview of the earlier file — the second report displayed the
  /// first one's data.
  ///
  /// Billing reports are generated synchronously and carry the whole file
  /// inline as `base64:<bytes>` in place of a real asset code. Appending that
  /// produced a name thousands of characters long — past the OS's 255-byte
  /// file-name limit — so every write threw and the billing forms showed
  /// "Failed to save file". Such codes get a timestamp suffix instead.
  String _uniqueStorageName(String fileName, String assetCode) {
    final suffix = assetCode.startsWith('base64:') || assetCode.length > 64
        ? '${DateTime.now().millisecondsSinceEpoch}'
        : assetCode;
    final dot = fileName.lastIndexOf('.');
    if (dot <= 0) return '${fileName}_$suffix';
    return '${fileName.substring(0, dot)}_$suffix${fileName.substring(dot)}';
  }

  Future<void> downloadAndViewReport(
    BuildContext context,
    String assetCode,
    String fileName,
  ) async {
    // Viewing renders the file bytes in memory (PDFView/Excel preview);
    // no storage permission is needed since nothing is written to shared
    // storage here.
    CoreUtils.showTopSnackBar(
      context: context,
      message: ReportsStrings.downloadingReport,
      isSuccess: true,
    );

    final fileData = await context.read<ReportsCubit>().downloadReport(
      assetCode,
    );

    if (!mounted) return;

    if (fileData == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: ReportsStrings.failedToDownloadReport,
        isError: true,
      );
      return;
    }

    // Determine file type
    final fileType = fileName.toLowerCase().endsWith('.pdf') ? 'pdf' : 'xlsx';

    if (!mounted) return;

    // Navigate to the viewer screen and navigate to it
    context.push<void>(
      ReportRoutes.fileViewer,
      extra: ReportFileViewerArgs(
        fileData: Uint8List.fromList(fileData),
        fileName: fileName,
        fileType: fileType,
      ),
    );
  }

  /// Downloads the report bytes, saves them to device storage, and opens
  /// the saved file with the OS's default handler — unlike
  /// [_downloadAndViewReport], which only renders bytes in-memory and never
  /// persists anything, this is what makes "Download" actually download.
  /// [previewInApp]: after saving, show the report in the app's own
  /// [ReportFileViewerScreen] instead of handing it to the OS — used for a
  /// report the user just generated, so the result is always visible.
  ///
  /// This covers XLSX as well as PDF. iOS gets an in-app preview from the OS
  /// for free (open_filex hands the file to QuickLook, which renders both),
  /// but the Android equivalent is an `ACTION_VIEW` intent that does nothing
  /// at all when no app declares the mime type — routine for XLSX, which is
  /// the billing forms' default format. Previewing in-app is what makes a
  /// generated report appear on Android the way it does on iPhone.
  Future<void> downloadAndSaveReport(
    BuildContext context,
    String assetCode,
    String fileName, {
    bool previewInApp = false,
  }) async {
    final cubit = context.read<ReportsCubit>();

    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSizes.md),
            Text(ReportsStrings.downloadingNamedFile(fileName)),
          ],
        ),
      ),
    );

    try {
      final fileData = await cubit.downloadReport(assetCode);

      if (!mounted) return;
      dismissDialog(context); // close downloading dialog

      if (fileData == null || fileData.isEmpty) {
        AppLogger.e('[REPORTS-UI-DOWN] Bytes empty for assetCode=$assetCode');
        CoreUtils.showTopSnackBar(
          context: context,
          message: ReportsStrings.failedToDownloadReport,
          isError: true,
        );
        return;
      }

      if (mounted) {
        showDialog(
          context: context,
          useRootNavigator: true,
          barrierDismissible: false,
          builder: (_) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: AppSizes.md),
                Text(ReportsStrings.savingFile),
              ],
            ),
          ),
        );
      }

      final filePath = await cubit.saveReportFile(
        fileData: Uint8List.fromList(fileData),
        fileName: _uniqueStorageName(fileName, assetCode),
        assetCode: assetCode,
      );

      if (!mounted) return;
      dismissDialog(context); // close saving dialog

      final lowerName = fileName.toLowerCase();
      final previewType = lowerName.endsWith('.pdf')
          ? 'pdf'
          : lowerName.endsWith('.xlsx')
          ? 'xlsx'
          : null;

      if (filePath == null) {
        AppLogger.e('[REPORTS-UI-DOWN] Save failed for assetCode=$assetCode');
        // The bytes are already in memory, so an in-app preview can still
        // show the report even though writing it to disk failed.
        if (previewInApp && previewType != null) {
          await context.push<void>(
            ReportRoutes.fileViewer,
            extra: ReportFileViewerArgs(
              fileData: Uint8List.fromList(fileData),
              fileName: fileName,
              fileType: previewType,
            ),
          );
          return;
        }
        CoreUtils.showTopSnackBar(
          context: context,
          message: ReportsStrings.failedToSaveFile,
          isError: true,
        );
        return;
      }

      AppLogger.i('[REPORTS-UI-DOWN] Saved: $filePath');
      if (mounted) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: ReportsStrings.savedSuccessfully(fileName),
          isSuccess: true,
        );
      }

      if (previewInApp && previewType != null) {
        if (!mounted) return;
        await context.push<void>(
          ReportRoutes.fileViewer,
          extra: ReportFileViewerArgs(
            fileData: Uint8List.fromList(fileData),
            fileName: fileName,
            fileType: previewType,
          ),
        );
        return;
      }

      final opened = await cubit.openReportFile(
        filePath: filePath,
        fileName: fileName,
        assetCode: assetCode,
      );

      if (!opened && mounted) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: ReportsStrings.savedOpenFromFileManager,
          isSuccess: true,
        );
      }
    } catch (e) {
      AppLogger.e('[REPORTS-UI-DOWN] Exception for assetCode=$assetCode: $e');
      if (mounted) {
        dismissDialog(context);
        CoreUtils.showTopSnackBar(
          context: context,
          message: ReportsStrings.errorWithDetail(e),
          isError: true,
        );
      }
    }
  }
}
