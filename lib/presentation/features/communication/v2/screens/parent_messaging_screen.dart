import 'package:flutter/material.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'conversation_list_screen.dart';

/// Thin wrapper — passes ROOM_CHAT to [ConversationListScreen].
///
/// Participants: Parent, Teacher, Staff, Admin, Director.
class ParentMessagingScreen extends StatelessWidget {
  const ParentMessagingScreen({
    super.key,
    required this.onConversationTap,
    this.onCreateTap,
  });

  final void Function(ConversationEntity conversation) onConversationTap;
  final VoidCallback? onCreateTap;

  static const routeName = '/parent-messaging';

  @override
  Widget build(BuildContext context) {
    return ConversationListScreen(
      conversationType: ConversationType.roomChat,
      onConversationTap: onConversationTap,
      onCreateTap: onCreateTap,
      title: 'Parent Messaging',
    );
  }
}
