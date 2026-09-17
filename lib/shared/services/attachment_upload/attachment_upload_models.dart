import 'package:equatable/equatable.dart';
import 'package:wowcare/core/utils/file_picker_utils.dart';

/// Where one file is in the upload pipeline.
///
/// `processing` is its own state because the document service finalizes
/// asynchronously: `complete` returns `UPLOADED`, and the asset only becomes
/// `READY` a few seconds later. The bytes are gone from the device's point of
/// view, but the asset is not yet attachable — showing that as "uploading"
/// would misreport a wait the user cannot influence.
enum AttachmentUploadStatus { pending, uploading, processing, done, failed }

/// One file's upload state, from picked through to an asset code.
class AttachmentUploadItem extends Equatable {
  const AttachmentUploadItem({
    required this.file,
    this.status = AttachmentUploadStatus.pending,
    this.sentBytes = 0,
    this.assetCode,
    this.error,
  });

  final PickedFile file;
  final AttachmentUploadStatus status;
  final int sentBytes;

  /// Set once the asset is ready to be attached; null until then.
  final String? assetCode;

  /// Human-readable reason this file failed, or null.
  final String? error;

  bool get isDone => status == AttachmentUploadStatus.done;
  bool get isFailed => status == AttachmentUploadStatus.failed;

  bool get isInFlight =>
      status == AttachmentUploadStatus.uploading ||
      status == AttachmentUploadStatus.processing;

  /// 0..1 for this file. Byte progress covers the transfer only, so the
  /// asynchronous `processing` tail reports as complete-but-not-done rather
  /// than sitting at 99%.
  double get progress {
    switch (status) {
      case AttachmentUploadStatus.pending:
        return 0;
      case AttachmentUploadStatus.uploading:
        if (file.sizeBytes <= 0) return 0;
        return (sentBytes / file.sizeBytes).clamp(0.0, 1.0);
      case AttachmentUploadStatus.processing:
      case AttachmentUploadStatus.done:
        return 1;
      case AttachmentUploadStatus.failed:
        return 0;
    }
  }

  AttachmentUploadItem copyWith({
    AttachmentUploadStatus? status,
    int? sentBytes,
    String? assetCode,
    String? error,
  }) {
    return AttachmentUploadItem(
      file: file,
      status: status ?? this.status,
      sentBytes: sentBytes ?? this.sentBytes,
      assetCode: assetCode ?? this.assetCode,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [file, status, sentBytes, assetCode, error];
}

/// Snapshot of a whole upload batch — emitted repeatedly while it runs and
/// returned once when it finishes.
class AttachmentUploadState extends Equatable {
  const AttachmentUploadState({this.items = const [], this.fatalError});

  factory AttachmentUploadState.pending(List<PickedFile> files) {
    return AttachmentUploadState(
      items: files.map((f) => AttachmentUploadItem(file: f)).toList(),
    );
  }

  final List<AttachmentUploadItem> items;

  /// Set when the batch failed as a whole — the session could not be opened, or
  /// presigning failed — so no individual file got far enough to have its own
  /// error. Per-file failures live on the items instead.
  final String? fatalError;

  bool get isEmpty => items.isEmpty;
  bool get isUploading => items.any((i) => i.isInFlight);
  bool get hasFailures => fatalError != null || items.any((i) => i.isFailed);

  List<AttachmentUploadItem> get failedItems =>
      items.where((i) => i.isFailed).toList();

  /// Asset codes for the files that made it, in the order they were picked.
  List<String> get assetCodes => items
      .where((i) => i.isDone && (i.assetCode ?? '').isNotEmpty)
      .map((i) => i.assetCode!)
      .toList();

  bool get allSucceeded =>
      fatalError == null && items.isNotEmpty && items.every((i) => i.isDone);

  /// Byte-weighted 0..1 across the batch, so a large file moves the bar more
  /// than a small one and the number matches what the user sees happening.
  double get overallProgress {
    if (items.isEmpty) return 0;
    final totalBytes = items.fold<int>(0, (sum, i) => sum + i.file.sizeBytes);
    if (totalBytes <= 0) {
      final done = items.where((i) => i.isDone).length;
      return done / items.length;
    }
    final sent = items.fold<double>(
      0,
      (sum, i) => sum + i.progress * i.file.sizeBytes,
    );
    return (sent / totalBytes).clamp(0.0, 1.0);
  }

  /// One-line status for a button or banner.
  String get summary {
    if (fatalError != null) return fatalError!;
    if (items.isEmpty) return '';
    if (isUploading) {
      final processing = items.every(
        (i) => i.status != AttachmentUploadStatus.uploading,
      );
      if (processing) return 'Processing attachments…';
      return 'Uploading ${(overallProgress * 100).round()}%';
    }
    if (hasFailures) {
      final failed = failedItems.length;
      return failed == 1
          ? 'Could not upload ${failedItems.first.file.name}'
          : 'Could not upload $failed attachments';
    }
    return 'Attachments uploaded';
  }

  AttachmentUploadState copyWith({
    List<AttachmentUploadItem>? items,
    String? fatalError,
  }) {
    return AttachmentUploadState(
      items: items ?? this.items,
      fatalError: fatalError ?? this.fatalError,
    );
  }

  @override
  List<Object?> get props => [items, fatalError];
}
