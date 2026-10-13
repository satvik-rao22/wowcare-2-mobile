import 'dart:io';

import 'package:flutter/material.dart';
import 'package:wowcare/core/network/file_download_service.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/file_utils/file_actions.dart';
import 'package:wowcare/core/utils/file_utils/file_picker_utils.dart';
import 'package:wowcare/core/utils/file_utils/file_utils.dart';
import 'package:wowcare/domain/features/tasks/entities/task_attachment.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/show_full_screen_media_view.dart';
import 'package:wowcare/shared/services/asset/asset_service.dart';

/// Shared rules and behaviours for task attachments, so the form picker, the
/// card strip and the detail list can't drift apart on limits or on what
/// tapping an attachment does.
class TaskAttachmentUtils {
  const TaskAttachmentUtils._();

  /// Server-side cap per attachment (TASK_SYSTEM_DESIGN_DOC §"Caps":
  /// "attachment ≤ 10 MB"). Enforced client-side too so an oversized file is
  /// rejected at pick time instead of after a wasted upload.
  static const int maxAttachmentBytes = 10 * 1024 * 1024;

  /// How many attachments one task may carry. Not a documented server cap —
  /// a UI guard so a single task can't be turned into a file dump.
  static const int maxAttachmentCount = 10;

  /// Extensions the backend validates for (same doc: "allowed types
  /// JPEG/PNG/WebP/PDF"). Anything outside this list is refused server-side, so
  /// the picker never offers it.
  static const List<String> allowedExtensions = [
    'jpg',
    'jpeg',
    'png',
    'webp',
    'pdf',
  ];

  /// Helper text under the picker — kept in one place so the copy always
  /// matches [allowedExtensions] and [maxAttachmentBytes].
  static const String limitsLabel = 'JPEG, PNG, WebP or PDF • up to 10MB each';

  /// Uppercase extension label for the doctype badge (`PDF`, `PNG`, …).
  static String extensionLabel(String fileName) {
    final ext = FileUtils.extension(fileName).toUpperCase();
    return ext.isEmpty ? 'FILE' : ext;
  }

  /// Glyph + tint for a non-previewable attachment, keyed by its type. Excel
  /// and Word are covered even though the current server allowlist excludes
  /// them — the read side renders whatever the API hands back, and a green
  /// spreadsheet glyph beats a generic page if that list ever widens.
  static ({IconData icon, Color color}) docTypeStyle(
    String fileName,
    String contentType,
  ) {
    final ext = FileUtils.extension(fileName);
    final type = contentType.toLowerCase();

    if (ext == 'pdf' || type.contains('pdf')) {
      return (icon: Icons.picture_as_pdf_rounded, color: AppPalette.dataPink);
    }
    if (ext == 'xls' ||
        ext == 'xlsx' ||
        ext == 'csv' ||
        type.contains('excel') ||
        type.contains('spreadsheet')) {
      return (icon: Icons.table_chart_rounded, color: AppPalette.dataGreen);
    }
    if (ext == 'doc' ||
        ext == 'docx' ||
        type.contains('word') ||
        type.contains('wordprocessing')) {
      return (icon: Icons.article_rounded, color: AppPalette.dataTeal);
    }
    if (ext == 'ppt' || ext == 'pptx' || type.contains('presentation')) {
      return (icon: Icons.slideshow_rounded, color: AppPalette.dataOrange);
    }
    return (icon: Icons.insert_drive_file_rounded, color: AppPalette.textMuted);
  }

  /// Whether an upload round that was responsible for [attempted] (file paths)
  /// achieved anything, given what is [stillOutstanding] afterwards.
  ///
  /// The upload loop needs this to know when to stop, and it must compare the
  /// *same files* rather than list lengths: picking another attachment while a
  /// batch is in flight grows the outstanding list, so a length comparison reads
  /// a perfectly successful round as "no progress" and abandons the newly added
  /// file. Getting this wrong is silent — the file simply never uploads until
  /// the save retries it.
  static bool uploadRoundMadeProgress({
    required Set<String> attempted,
    required Set<String> stillOutstanding,
  }) {
    if (attempted.isEmpty) return false;
    return !stillOutstanding.containsAll(attempted);
  }

  /// Resolves an attachment to a playable/viewable URL, preferring what the
  /// list payload already carried and falling back to a document-microservice
  /// lookup by asset code (cached and de-duped by [AssetService]).
  static Future<String> resolveUrl(
    TaskAttachment attachment,
    AssetService service,
  ) async {
    if (attachment.url.trim().isNotEmpty) return attachment.url.trim();
    if (attachment.assetCode.trim().isEmpty) return '';
    return service.getMediaAssetUrlByCode(assetCode: attachment.assetCode);
  }

  /// Opens [attachment] the way its type warrants: images and video go to the
  /// in-app full-screen viewer, everything else is downloaded to the cache and
  /// handed to whatever app the OS has registered for it.
  ///
  /// Safe to call from a tap handler — every failure path surfaces a snackbar
  /// rather than throwing.
  static Future<void> open({
    required BuildContext context,
    required TaskAttachment attachment,
    required AssetService service,
  }) async {
    if (!attachment.isReady) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'This attachment is still processing. Try again in a moment.',
        isWarning: true,
      );
      return;
    }

    final url = await resolveUrl(attachment, service);
    if (!context.mounted) return;
    if (url.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'This attachment is not available right now.',
        isError: true,
      );
      return;
    }

    // An attachment known only by asset code has no type until the URL resolves,
    // so classify against the resolved URL rather than the bare code — otherwise
    // every such image would be handed to the OS as a document.
    final resolved = attachment.withResolvedUrl(url);

    if (resolved.isImage || resolved.isVideo) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ShowFullScreenMediaView(
            imageUrl: resolved.isImage ? url : null,
            videoUrl: resolved.isVideo ? url : null,
            title: resolved.fileName.isEmpty ? null : resolved.fileName,
          ),
        ),
      );
      return;
    }

    await _openExternally(
      context: context,
      url: url,
      fileName: resolved.fileName,
    );
  }

  /// Opens a locally picked (not yet uploaded) file — the form's preview path,
  /// so a user can check what they attached before saving.
  static Future<void> openLocal({
    required BuildContext context,
    required PickedFile attachment,
  }) async {
    if (attachment.isImage || attachment.isVideo) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ShowFullScreenMediaView(
            imageFile: attachment.isImage ? attachment.file : null,
            videoUrl: null,
            title: attachment.name,
          ),
        ),
      );
      return;
    }
    final result = await FileActions.open(
      attachment.path,
      mimeType: attachment.mimeType,
    );
    if (!context.mounted || result.opened) return;
    CoreUtils.showTopSnackBar(
      context: context,
      message: _noAppMessage,
      isError: true,
    );
  }

  /// Downloads to the cache directory (a remote URL can't be handed to another
  /// app directly) and opens it. The file keeps its original name so the
  /// receiving app shows something recognisable.
  static Future<void> _openExternally({
    required BuildContext context,
    required String url,
    required String fileName,
  }) async {
    try {
      final dir = Directory(
        FileUtils.join(
          (await FileUtils.tempDirectory()).path,
          'task_attachments',
        ),
      );
      await dir.create(recursive: true);
      final ext = FileUtils.extension(url);
      final safeName = fileName.trim().isEmpty
          ? 'attachment${ext.isEmpty ? '' : '.$ext'}'
          : FileUtils.safeFileName(fileName.trim());
      final target = FileUtils.join(dir.path, safeName);

      final file = File(target);
      // Re-opening the same attachment shouldn't re-download it.
      if (!await file.exists() || await file.length() == 0) {
        await FileDownloadService.instance.downloadToFile(url, target);
      }

      final result = await FileActions.open(
        target,
        mimeType: FileUtils.mimeType(target),
      );
      if (!context.mounted || result.opened) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: _noAppMessage,
        isError: true,
      );
    } catch (_) {
      if (!context.mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Could not open this attachment.',
        isError: true,
      );
    }
  }

  /// A failed hand-off of a file that exists means no app takes this type
  /// (FileActions reports a missing file the same way, but both paths here
  /// open a file that was just checked or downloaded).
  static const String _noAppMessage =
      'No app on this device can open this file type.';
}
