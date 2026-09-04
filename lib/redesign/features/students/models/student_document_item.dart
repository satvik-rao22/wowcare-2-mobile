import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// What the little tile on a document row says, which follows the mime type.
enum DocumentKind {
  pdf,
  image;

  static DocumentKind fromMimeType(String mimeType) =>
      mimeType.startsWith('image/') ? DocumentKind.image : DocumentKind.pdf;
}

/// One file on a student's record (5c Documents, 5f).
///
/// Mirrors `StudentDocument`: `documentUuid`, `documentName`, `documentType`,
/// `expiryDate`, `expired`, `documentSizeKb`, `mimeType` and `createdAt`.
///
/// There is deliberately no "missing" state: the backend returns expiry
/// counts and nothing else, so a required-documents checklist is out of scope.
@immutable
class StudentDocumentItem extends Equatable {
  const StudentDocumentItem({
    required this.id,
    required this.name,
    required this.type,
    required this.kind,
    required this.detail,
    this.isExpired = false,
    this.sizeKb = 0,
  });

  final String id;
  final String name;

  /// "Health Forms", "Registration Forms": the school's own document types.
  final String type;

  final DocumentKind kind;

  /// "Health Forms · expires 12 Sep 2026", already assembled.
  final String detail;

  final bool isExpired;
  final int sizeKb;

  @override
  List<Object?> get props => [id, name, type, kind, detail, isExpired, sizeKb];
}
