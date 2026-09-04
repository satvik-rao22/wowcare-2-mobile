import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// One student on the picker (8f).
///
/// The roster is the day's attendance rather than the class list, because an
/// activity has to belong to a student who was here. Somebody who has gone
/// home is still on it: the activity time only has to fall inside the day
/// they attended.
@immutable
class RosterEntry extends Equatable {
  const RosterEntry({
    required this.id,
    required this.name,
    required this.initials,
    required this.classroomName,
    required this.isSignedIn,
    this.signedInLabel = '',
    this.signedOutLabel = '',
    this.isNapping = false,
    this.tag,
  });

  final String id;
  final String name;
  final String initials;
  final String classroomName;

  /// Still in the building.
  final bool isSignedIn;

  /// "8:02 am".
  final String signedInLabel;

  /// "3:20 pm", once they have gone.
  final String signedOutLabel;

  /// Napping right now, which is what switches a mixed Nap selection off.
  final bool isNapping;

  /// A flag the school keeps on the record: "Nut free", "Inhaler".
  final String? tag;

  String get firstName => name.split(' ').first;

  @override
  List<Object?> get props => <Object?>[
    id,
    name,
    initials,
    classroomName,
    isSignedIn,
    signedInLabel,
    signedOutLabel,
    isNapping,
    tag,
  ];
}
