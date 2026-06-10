import 'package:flutter/material.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'conversation_list_screen.dart';

/// Thin wrapper — passes STAFF_DIRECT to [ConversationListScreen].
///
/// Participants: Teacher, Staff, Admin, Director (no Parents).
class StaffMessagingScreen extends StatelessWidget {
  const StaffMessagingScreen({
    super.key,
    required this.onConversationTap,
    this.onCreateTap,
  });

  final void Function(ConversationEntity conversation) onConversationTap;
  final VoidCallback? onCreateTap;

  static const routeName = '/staff-messaging';

  @override
  Widget build(BuildContext context) {
    return ConversationListScreen(
      conversationType: ConversationType.staffDirect,
      onConversationTap: onConversationTap,
      onCreateTap: onCreateTap,
      title: 'Staff Messaging',
    );
  }
}
