import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/core/session/persona.dart';

/// What a classroom screen needs before it can ask for anything: which
/// classroom, who is looking, and whether it is their own.
///
/// One object because `GetIt` takes two factory parameters and this needs
/// three, and because the three always travel together.
@immutable
class ClassroomArgs extends Equatable {
  const ClassroomArgs({
    required this.classroomId,
    required this.persona,
    this.isOwnClassroom = false,
  });

  final String classroomId;
  final Persona persona;

  /// The signed-in teacher's own classroom, which draws 7e.
  final bool isOwnClassroom;

  @override
  List<Object?> get props => [classroomId, persona, isOwnClassroom];
}
