import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// One note on a classroom's board (7c's Notes tab).
///
/// The classroom's own thread, which the existing
/// `classroom_notes_tab_card.dart` posts into.
@immutable
class ClassroomNote extends Equatable {
  const ClassroomNote({
    required this.id,
    required this.author,
    required this.initials,
    required this.timeLabel,
    required this.text,
    this.isMine = false,
    this.isFirstUnread = false,
  });

  final String id;
  final String author;
  final String initials;

  /// "12:41".
  final String timeLabel;

  final String text;

  /// Written by the signed-in person: navy bubble, right-aligned.
  final bool isMine;

  /// The rule that says how many notes arrived since the last visit sits
  /// above this one.
  final bool isFirstUnread;

  @override
  List<Object?> get props => [
    id,
    author,
    initials,
    timeLabel,
    text,
    isMine,
    isFirstUnread,
  ];
}
