import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/features/students/models/student_document_item.dart';

/// What the device handed back after the file picker or the camera closed.
///
/// The picker itself is a platform call rather than an API one, so it sits
/// behind the source with everything else the screen cannot do by itself.
@immutable
class PickedFile extends Equatable {
  const PickedFile({
    required this.name,
    required this.kind,
    required this.sizeKb,
  });

  final String name;
  final DocumentKind kind;
  final int sizeKb;

  @override
  List<Object?> get props => [name, kind, sizeKb];
}

/// The file being added on 5f: what was chosen, what it is, and when it
/// stops counting.
///
/// Mirrors the arguments `addStudentDocument` takes: `name`, `type`,
/// `expiryDate`, `mimeType` and `size`.
@immutable
class DocumentDraft extends Equatable {
  const DocumentDraft({
    this.fileName,
    this.kind = DocumentKind.pdf,
    this.sizeKb = 0,
    this.type,
    this.expiryDate,
  });

  /// "exam-mar-2026.pdf". Null until a file is chosen.
  final String? fileName;

  final DocumentKind kind;
  final int sizeKb;

  /// One of the school's document types. Required before anything is sent.
  final String? type;

  final DateTime? expiryDate;

  bool get isReady => fileName != null && type != null;

  DocumentDraft copyWith({
    String? fileName,
    DocumentKind? kind,
    int? sizeKb,
    String? type,
    DateTime? expiryDate,
    bool clearFile = false,
  }) => DocumentDraft(
    fileName: clearFile ? null : fileName ?? this.fileName,
    kind: kind ?? this.kind,
    sizeKb: clearFile ? 0 : sizeKb ?? this.sizeKb,
    type: type ?? this.type,
    expiryDate: expiryDate ?? this.expiryDate,
  );

  @override
  List<Object?> get props => [fileName, kind, sizeKb, type, expiryDate];
}
