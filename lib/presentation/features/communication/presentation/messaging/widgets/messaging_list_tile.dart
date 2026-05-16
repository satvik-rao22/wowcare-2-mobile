import 'package:flutter/material.dart';
import 'package:wowcare/domain/features/communication/entities/conversation.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

class MessagingListTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const MessagingListTile({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  String _formatMessageTime(DateTime? dateTime) {
    if (dateTime == null) return '—';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final difference = today.difference(messageDate).inDays;
    final timeStr =
        "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";

    if (difference == 0) return "Today | $timeStr";
    if (difference == 1) return "Yesterday | $timeStr";
    if (difference < 7) {
      final days = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ];
      return "${days[dateTime.weekday - 1]} | $timeStr";
    }
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return "${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year} | $timeStr";
  }

  @override
  Widget build(BuildContext context) {
    final bool isActive = conversation.status == 'ACTIVE';

    return InkWell(
      onTap: onTap,
      splashColor: const Color(0x1A6C5CE7), // Subtle theme splash
      highlightColor: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            bottom: BorderSide(color: Color(0xFFF1F3F5), width: 1),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          leading: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: DocumentImageWidget(
                  fileUuid: conversation.avatarUrl,
                  name: conversation.title,
                  size: 52,
                ),
              ),
              if (isActive)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00B115),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                    ),
                  ),
                ),
            ],
          ),
          title: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: CustomTextWidget(
                    text: conversation.title.isNotEmpty
                        ? conversation.title
                        : 'Unnamed Conversation',
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    fontColor: const Color(0xFF2D3436),
                  ),
                ),
                Text(
                  _formatMessageTime(conversation.lastMessageAt),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFA0A0A0),
                  ),
                ),
              ],
            ),
          ),
          subtitle: Row(
            children: [
              Expanded(
                child: Text(
                  conversation.lastMessagePreview.isEmpty
                      ? 'Start a new conversation'
                      : conversation.lastMessagePreview,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF636E72),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
              if (conversation.unreadCount > 0)
                Container(
                  margin: const EdgeInsets.only(left: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C5CE7), // Theme color
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6C5CE7).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    conversation.unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
