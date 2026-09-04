import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// What the 36px tile on a document row says: PDF or IMG.
enum StaffDocumentKind { pdf, image }

/// A file on a staff member's record (6c Documents).
///
/// Mirrors `StaffDocument` from `lib/domain/features/staff/entities/`, read
/// off `/api/v1/staff-documents`. There is no viewer endpoint, so a row opens
/// nothing: it reports what is on file and when it runs out.
@immutable
class StaffDocument extends Equatable {
  const StaffDocument({
    required this.id,
    required this.name,
    required this.type,
    required this.kind,
    this.addedOn,
    this.expiresOn,
  });

  final String id;
  final String name;

  /// Certificate, Contract, Identification, Other.
  final String type;

  final StaffDocumentKind kind;
  final DateTime? addedOn;
  final DateTime? expiresOn;

  /// Expired against [today], which is the school's day rather than the
  /// device's: time is school-timezone based everywhere in this app.
  bool isExpired(DateTime today) =>
      expiresOn != null && expiresOn!.isBefore(today);

  @override
  List<Object?> get props => [id, name, type, kind, addedOn, expiresOn];
}
