import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// The one conversation a dashboard surfaces (3A1, 3S1).
///
/// Not a message list: one row, the most recent unread, so the dashboard
/// points at Messages rather than trying to be it.
@immutable
class MessagePreview extends Equatable {
  const MessagePreview({
    required this.conversationId,
    required this.name,
    required this.initials,
    required this.preview,
    required this.unreadCount,
    this.isFromStaff = true,
  });

  final String conversationId;
  final String name;
  final String initials;
  final String preview;
  final int unreadCount;

  /// Staff wear the sun avatar, guardians the student teal.
  final bool isFromStaff;

  @override
  List<Object?> get props => [
    conversationId,
    name,
    initials,
    preview,
    unreadCount,
    isFromStaff,
  ];
}
