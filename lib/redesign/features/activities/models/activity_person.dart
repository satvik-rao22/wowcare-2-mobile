import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/core/widgets/app_avatar.dart';

/// Somebody named on an activity: a student in the stack at the foot of a
/// card, or the staff member and director who signed it.
///
/// Mirrors the `students[]` entries an activity carries and the staff record
/// `staffCode` resolves to, so Phase 5 fills it from what already comes back.
@immutable
class ActivityPerson extends Equatable {
  const ActivityPerson({
    required this.id,
    required this.name,
    required this.initials,
    this.role = '',
    this.tone = AvatarTone.student,
    this.signedInLabel,
    this.isOverflow = false,
  });

  /// The "+13" bubble that closes a stack. It stands for a count, not a
  /// person, so it never carries an id worth pushing.
  const ActivityPerson.overflow(int more)
    : id = 'overflow',
      name = '',
      initials = '+$more',
      role = '',
      tone = AvatarTone.neutral,
      signedInLabel = null,
      isOverflow = true;

  final String id;
  final String name;
  final String initials;

  /// "Lead Teacher", "Director", "Guardian": the line under a name on a
  /// form's sign-off row.
  final String role;

  final AvatarTone tone;

  /// "signed in 7:58 am", where a form shows it.
  final String? signedInLabel;

  final bool isOverflow;

  String get firstName => name.isEmpty ? name : name.split(' ').first;

  @override
  List<Object?> get props => <Object?>[
    id,
    name,
    initials,
    role,
    tone,
    signedInLabel,
    isOverflow,
  ];
}
