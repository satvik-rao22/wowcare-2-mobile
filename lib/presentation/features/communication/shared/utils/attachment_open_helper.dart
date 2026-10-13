import 'package:flutter/material.dart';
import 'package:wowcare/core/network/file_download_service.dart';
import 'package:wowcare/core/utils/file_utils/file_utils.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/file_utils/file_actions.dart';
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

    final mimeType = attachment.mimeType.isNotEmpty
        ? attachment.mimeType
        : FileUtils.mimeType(attachment.name);

    try {
      final localPath = attachment.localPath;
      if (localPath != null && localPath.isNotEmpty) {
        await _openAndReport(
          context,
          filePath: localPath,
          fileName: attachment.name,
          mimeType: mimeType,
        );
        return;
      }

      if (attachment.remoteUrl.isEmpty) return;

      final cacheKey =
          '${attachment.code ?? attachment.remoteUrl.hashCode}_${attachment.name}';
      final cachedFile = await FileUtils.documentsFile(cacheKey);

      if (!await cachedFile.exists()) {
        // Streams straight into the cache file; a failed or empty download
        // leaves no file behind, so it is never mistaken for a cached copy.
        try {
          await FileDownloadService.instance.downloadToFile(
            attachment.remoteUrl,
            cachedFile.path,
          );
        } catch (_) {
          if (context.mounted) {
            CoreUtils.showTopSnackBar(
              context: context,
              message: 'Failed to download the file',
              isError: true,
            );
          }
          return;
        }
      }

      await _openAndReport(
        context,
        filePath: cachedFile.path,
        fileName: attachment.name,
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
    BuildContext context, {
    required String filePath,
    required String fileName,
    required String mimeType,
  }) async {
    // OpenFilex itself falls back to the device's native "open with" picker
    // when no app declares itself the default handler for this mime type.
    final result = await FileActions.open(filePath, mimeType: mimeType);
    if (!result.opened && context.mounted) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Cannot open this file',
        isError: true,
      );
    }
  }
}
