import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/tasks/entities/task_attachment.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/show_full_screen_media_view.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_service.dart';

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
  static const List<String> allowedExtensions = ['jpg', 'jpeg', 'png', 'webp', 'pdf'];

  /// Helper text under the picker — kept in one place so the copy always
  /// matches [allowedExtensions] and [maxAttachmentBytes].
  static const String limitsLabel = 'JPEG, PNG, WebP or PDF • up to 10MB each';

  /// Uppercase extension label for the doctype badge (`PDF`, `PNG`, …).
  static String extensionLabel(String fileName) {
    final ext = p.extension(fileName).replaceFirst('.', '').toUpperCase();
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
    final ext = p.extension(fileName).replaceFirst('.', '').toLowerCase();
    final type = contentType.toLowerCase();

    if (ext == 'pdf' || type.contains('pdf')) {
      return (icon: Icons.picture_as_pdf_rounded, color: const Color(0xFFD64545));
    }
    if (ext == 'xls' ||
        ext == 'xlsx' ||
        ext == 'csv' ||
        type.contains('excel') ||
        type.contains('spreadsheet')) {
      return (icon: Icons.table_chart_rounded, color: const Color(0xFF1D7044));
    }
    if (ext == 'doc' ||
        ext == 'docx' ||
        type.contains('word') ||
        type.contains('wordprocessing')) {
      return (icon: Icons.article_rounded, color: const Color(0xFF2B5797));
    }
    if (ext == 'ppt' || ext == 'pptx' || type.contains('presentation')) {
      return (icon: Icons.slideshow_rounded, color: const Color(0xFFC7501B));
    }
    return (icon: Icons.insert_drive_file_rounded, color: const Color(0xFF6B7280));
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
  /// lookup by asset code (cached and de-duped by [ImageUploadService]).
  static Future<String> resolveUrl(
    TaskAttachment attachment,
    ImageUploadService service,
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
    required ImageUploadService service,
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
    required PendingTaskAttachment attachment,
  }) async {
    if (attachment.isImage || attachment.isVideo) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ShowFullScreenMediaView(
            imageFile: attachment.isImage ? File(attachment.filePath) : null,
            videoUrl: null,
            title: attachment.fileName,
          ),
        ),
      );
      return;
    }
    final result = await OpenFile.open(attachment.filePath);
    if (!context.mounted || result.type == ResultType.done) return;
    CoreUtils.showTopSnackBar(
      context: context,
      message: _openFailureMessage(result),
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
      final dir = await getTemporaryDirectory();
      final safeName = fileName.trim().isEmpty
          ? 'attachment${p.extension(Uri.parse(url).path)}'
          : fileName.trim();
      final target = p.join(dir.path, 'task_attachments', safeName);
      await Directory(p.dirname(target)).create(recursive: true);

      final file = File(target);
      // Re-opening the same attachment shouldn't re-download it.
      if (!await file.exists() || await file.length() == 0) {
        await Dio().download(url, target);
      }

      final result = await OpenFile.open(target);
      if (!context.mounted || result.type == ResultType.done) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: _openFailureMessage(result),
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

  static String _openFailureMessage(OpenResult result) {
    if (result.type == ResultType.noAppToOpen) {
      return 'No app on this device can open this file type.';
    }
    if (result.type == ResultType.permissionDenied) {
      return 'Permission denied while opening this file.';
    }
    return 'Could not open this attachment.';
  }
}
