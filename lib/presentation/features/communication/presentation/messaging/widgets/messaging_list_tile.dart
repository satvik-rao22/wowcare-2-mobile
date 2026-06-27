import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/domain/features/communication/entities/conversation.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/message_content_processor.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';

class MessagingListTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const MessagingListTile({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  /// The backend's conversation-list summary only carries a plain-text
  /// `lastMessagePreview` — empty for an attachment-only last message,
  /// with no field at all for attachment name/type or reactions (those
  /// only exist on the full `Message` entity inside a thread, not on this
  /// list-level summary). `lastMessageAt` is what actually distinguishes
  /// "no messages yet" from "the last message just had no text", so use
  /// that instead of treating both cases as the empty-preview case.
  String _lastMessagePreviewText(Conversation conversation) {
    if (conversation.lastMessagePreview.isNotEmpty) {
      return MessageContentProcessor.previewText(
        conversation.lastMessagePreview,
      );
    }
    if (conversation.lastMessageAt != null) {
      return '📎 Attachment';
    }
    return 'Start a new conversation';
  }

  String _formatMessageTime(DateTime? dateTime) {
    if (dateTime == null) return '—';

    final schoolTz = SchoolTimezoneResolver.lastKnownTimeZone;
    final schoolDateTime = SchoolZoneDateTime.dateTimeFromInstantInSchool(
      dateTime,
      schoolTz,
    );
    final schoolNow = SchoolZoneDateTime.dateTimeFromInstantInSchool(
      DateTime.now().toUtc(),
      schoolTz,
    );

    final today = DateTime(schoolNow.year, schoolNow.month, schoolNow.day);
    final messageDate = DateTime(
      schoolDateTime.year,
      schoolDateTime.month,
      schoolDateTime.day,
    );
    final difference = today.difference(messageDate).inDays;
    final timeStr =
        "${schoolDateTime.hour.toString().padLeft(2, '0')}:${schoolDateTime.minute.toString().padLeft(2, '0')}";

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
      return "${days[schoolDateTime.weekday - 1]} | $timeStr";
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
    return "${schoolDateTime.day} ${months[schoolDateTime.month - 1]} ${schoolDateTime.year} | $timeStr";
  }

  @override
  Widget build(BuildContext context) {
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
          // No staffCode/studentCode is available on this legacy
          // Conversation model (only the participant's userCode is, which
          // isn't what the attendance "today sign-in status" API expects)
          // — so there's no reliable signal to drive a real presence dot
          // here. Showing one based on `conversation.status` (the
          // conversation's own archived/active flag, unrelated to whether
          // the person is actually signed in) was actively misleading, so
          // it's removed rather than left showing the wrong thing.
          leading: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
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
                    fontColor: AppColors.primaryColor,
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
                  _lastMessagePreviewText(conversation),
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
                    color: const Color(0xFF00B894),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00B894).withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    conversation.unreadCount > 99
                        ? '99+'
                        : '${conversation.unreadCount}',
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
