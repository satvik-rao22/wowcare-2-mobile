import 'package:flutter/foundation.dart';

/// Minimal student entity for UI-only mock flows.
///
/// Keep this file lightweight so we can later replace it with the
/// real domain/entity model without changing UI widgets too much.
@immutable
class StudentEntity {
  final int id;
  final String fullName;
  final int roomId;
  final String roomName;
  final String? photoUuid;

  const StudentEntity({
    required this.id,
    required this.fullName,
    required this.roomId,
    required this.roomName,
    this.photoUuid,
  });

  @override
  bool operator ==(Object other) => identical(this, other) || (other is StudentEntity && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

