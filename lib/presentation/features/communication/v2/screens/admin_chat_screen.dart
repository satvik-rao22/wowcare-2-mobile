import 'package:flutter/material.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'conversation_list_screen.dart';

/// Thin wrapper — passes ADMIN_CHAT to [ConversationListScreen].
///
/// Participants: Parent, Admin, Director only (no Teachers or Staff).
class AdminChatScreen extends StatelessWidget {
  const AdminChatScreen({
    super.key,
    required this.onConversationTap,
    this.onCreateTap,
  });

  final void Function(ConversationEntity conversation) onConversationTap;
  final VoidCallback? onCreateTap;

  static const routeName = '/admin-chat';

  @override
  Widget build(BuildContext context) {
    return ConversationListScreen(
      conversationType: ConversationType.adminChat,
      onConversationTap: onConversationTap,
      onCreateTap: onCreateTap,
      title: 'Admin Chat',
    );
  }
}
