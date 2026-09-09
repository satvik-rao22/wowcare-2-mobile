import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';

/// Copies picked attachments out of the OS's ephemeral temp directory into
/// the app's own permanent storage, so the local preview survives navigating
/// away mid-upload, the app being backgrounded, or an app restart.
///
/// `image_picker`/`file_picker` hand back paths under the OS temp dir
/// (`NSTemporaryDirectory` on iOS, the equivalent cache dir on Android) —
/// the OS is free to clear that at any time under memory pressure or once
/// the app backgrounds, which is exactly what happens when a user sends an
/// attachment and immediately switches screens: the message and its Isar
/// record survive (see [ConversationThreadCubit]'s draft persistence), but
/// the file the local preview reads from does not, so it silently fails to
/// render. Copying into `getApplicationSupportDirectory()` (not cleared by
/// the OS) up front — before the message is even shown — fixes that.
abstract final class PendingAttachmentStorage {
  PendingAttachmentStorage._();

  static Future<String> _pendingUploadsDir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, 'pending_chat_uploads'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  /// Copies [attachments]' [ChatAttachment.localPath] files into permanent
  /// app storage, returning the same list with [ChatAttachment.localPath]
  /// pointing at the durable copy. Entries with no local path (already
  /// uploaded, or a remote-only attachment) pass through unchanged. A copy
  /// failure for one file falls back to leaving that entry's original path
  /// untouched rather than dropping the attachment.
  static Future<List<ChatAttachment>> persistLocally(
    List<ChatAttachment> attachments,
  ) async {
    if (attachments.isEmpty) return attachments;
    final dirPath = await _pendingUploadsDir();
    final result = <ChatAttachment>[];
    for (final a in attachments) {
      final source = a.localPath;
      if (source == null || source.isEmpty) {
        result.add(a);
        continue;
      }
      try {
        final stamp = AppTime.nowUtc().microsecondsSinceEpoch;
        final destPath = p.join(dirPath, 'chat_${stamp}_${p.basename(source)}');
        final copied = await File(source).copy(destPath);
        result.add(a.copyWith(localPath: copied.path));
      } catch (e) {
        AppLogger.e(
          '[PendingAttachmentStorage] Failed to persist $source locally; '
          'keeping original path',
          e,
        );
        result.add(a);
      }
    }
    return result;
  }

  /// Best-effort delete of a durable local copy once it's no longer needed
  /// (the attachment's real delivery URL has resolved). Safe to call even if
  /// the file is already gone.
  static Future<void> delete(String? localPath) async {
    if (localPath == null || localPath.isEmpty) return;
    try {
      final file = File(localPath);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Non-fatal — an orphaned file in app support storage costs nothing
      // functionally.
    }
  }
}
