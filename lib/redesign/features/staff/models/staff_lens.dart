import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/core/session/persona.dart';

/// Who is looking at Staff, and therefore what they get (6a's two lenses,
/// 6e's three states).
///
/// The read boundary is the existing app's: an Admin sees the school, a staff
/// member sees the colleagues they share a classroom with plus their own
/// record in full, and a guardian has no Staff module at all. It is decided
/// on the client and fails closed, exactly as `TaskPersona` does.
@immutable
class StaffLens extends Equatable {
  const StaffLens({
    required this.persona,
    this.viewerId = '',
    this.viewerClassroom,
  });

  final Persona persona;

  /// The signed-in staff member's own record, so 6e can lift it out.
  final String viewerId;

  /// The classroom that decides which colleagues are visible.
  final String? viewerClassroom;

  /// Guardians have no Staff module: 6e's "Staff is closed for this school".
  bool get canOpen => persona.isSchoolSide;

  /// Adding, editing, deactivating and scheduling are Admin work. A staff
  /// member gets 6e's view-only screen instead.
  bool get canWrite => persona == Persona.admin;

  /// A staff member sees names, classrooms and a way to call. Phone numbers,
  /// email addresses and PINs stay private to each person, so the only record
  /// they read in full is their own.
  bool seesDetailsOf(String staffId) => canWrite || staffId == viewerId;

  bool isSelf(String staffId) => staffId == viewerId;

  @override
  List<Object?> get props => [persona, viewerId, viewerClassroom];
}
