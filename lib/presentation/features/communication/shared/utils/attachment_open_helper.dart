import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wowcare/app/di/messaging_resolvers.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/data/services/file_download_service.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/attachment_url_resolver.dart';

/// Opens a chat attachment using the same download/open mechanism already
/// used by the Reports module ([FileDownloadService]) instead of the ad-hoc
/// per-widget download logic that used to live in the message bubble and
/// attachment viewer.
///
/// Remote attachments are downloaded once and cached under a key derived
/// from the attachment's asset code (or, failing that, its URL) so the same
/// file is never re-downloaded on a second tap.
class AttachmentOpenHelper {
  const AttachmentOpenHelper._();

  static Future<void> open(
    BuildContext context,
    ChatAttachment attachment,
  ) async {
    // Attachments loaded from conversation history only carry the
    // document-service asset code — resolve it to a delivery URL on demand
    // before giving up (see attachment_url_resolver.dart for why this can't
    // just come from the message payload).
    if (attachment.displaySource == null) {
      final resolvedUrl = await resolveAttachmentUrl(attachment);
      if (resolvedUrl != null && resolvedUrl.isNotEmpty) {
        attachment = attachment.copyWith(remoteUrl: resolvedUrl);
      }
    }

    if (attachment.displaySource == null) {
      if (context.mounted) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'No file available to open',
          isError: true,
        );
      }
      return;
    }

    final downloadService = resolveFileDownloadService();
    final mimeType = attachment.mimeType.isNotEmpty
        ? attachment.mimeType
        : downloadService.getMimeType(attachment.name);
    final assetCode = attachment.code ?? attachment.name;

    try {
      final localPath = attachment.localPath;
      if (localPath != null && localPath.isNotEmpty) {
        await _openAndReport(
          context,
          downloadService,
          filePath: localPath,
          fileName: attachment.name,
          assetCode: assetCode,
          mimeType: mimeType,
        );
        return;
      }

      if (attachment.remoteUrl.isEmpty) return;

      final cacheKey =
          '${attachment.code ?? attachment.remoteUrl.hashCode}_${attachment.name}';
      final cachedFile = await downloadService.resolveCacheFile(cacheKey);

      if (!await cachedFile.exists()) {
        final response = await http.get(Uri.parse(attachment.remoteUrl));
        if (response.statusCode != 200) {
          if (context.mounted) {
            CoreUtils.showTopSnackBar(
              context: context,
              message: 'Failed to download the file',
              isError: true,
            );
          }
          return;
        }
        final savedPath = await downloadService.saveFile(
          fileData: response.bodyBytes,
          fileName: cacheKey,
          assetCode: assetCode,
          mimeType: mimeType,
        );
        if (savedPath == null) {
          if (context.mounted) {
            CoreUtils.showTopSnackBar(
              context: context,
              message: 'Failed to save the file',
              isError: true,
            );
          }
          return;
        }
      }

      await _openAndReport(
        context,
        downloadService,
        filePath: cachedFile.path,
        fileName: attachment.name,
        assetCode: assetCode,
        mimeType: mimeType,
      );
    } catch (e) {
      if (context.mounted) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Error opening file: $e',
          isError: true,
        );
      }
    }
  }

  static Future<void> _openAndReport(
    BuildContext context,
    FileDownloadService downloadService, {
    required String filePath,
    required String fileName,
    required String assetCode,
    required String mimeType,
  }) async {
    // OpenFilex itself falls back to the device's native "open with" picker
    // when no app declares itself the default handler for this mime type.
    final opened = await downloadService.openFile(
      filePath: filePath,
      fileName: fileName,
      assetCode: assetCode,
      mimeType: mimeType,
    );
    if (!opened && context.mounted) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Cannot open this file',
        isError: true,
      );
    }
  }
}
