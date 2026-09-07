import 'package:flutter/material.dart';
import 'package:wowcare/core/constants/app_strings.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity_display.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/screens/conversation_thread_screen.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/message_content_processor.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/chat_preview_cubit.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/util/app_time.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/src/app_router.dart' show AppRoutes;

/// Shows the logged-in user's latest conversations (up to 2) using the same row
/// representation as the messaging inbox (avatar + title + last message + time +
/// unread). Tapping a row opens that conversation thread. Empty → "No recent chat".
///
/// Mandate 2: this was a `StatefulWidget` holding the conversation list, a
/// loading flag, the current user code, a classroom-name map and the
/// primary-classroom pin, driven by nine `setState` calls across a cache read,
/// a REST call and a Firestore stream. All of that is bucket A and now lives in
/// [ChatPreviewCubit] (§2.4). What remains here is rendering.
class MyDayChatPreviewRow extends StatelessWidget {
  const MyDayChatPreviewRow();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChatPreviewCubit>(
      // §5.4: constructed here, loaded once. `load()` is itself idempotent, so
      // a rebuild of this widget cannot re-fire the three fetches.
      create: (_) => serviceLocator<ChatPreviewCubit>()..load(),
      child: const _ChatPreviewRowView(),
    );
  }
}

class _ChatPreviewRowView extends StatelessWidget {
  const _ChatPreviewRowView();

  String _displayTitle(
    ConversationEntity conversation,
    ChatPreviewState state,
  ) {
    if (conversation.type == ConversationType.classroomChat) {
      final classroomCode = conversation.classroomCode?.trim() ?? '';
      if (classroomCode.isNotEmpty) {
        final classroomName = state.classroomNames[classroomCode]?.trim();
        if (classroomName != null && classroomName.isNotEmpty) {
          return classroomName;
        }
      }
      // _classroomNames is a separate, fire-and-forget fetch that races the
      // conversation list — this row could render before it resolves (or if
      // it fails, never gets it at all). The conversation's OWN stored
      // title is set to the classroom's name at creation time
      // (GetOrCreateClassroomChatUseCase) and doesn't depend on that second
      // fetch succeeding, so try it before giving up to the generic
      // "Classroom" label — displayTitle already does exactly this for
      // every other conversation type below, CLASSROOM_CHAT just never
      // reached it.
      return conversation.displayTitle(
        state.currentUserCode,
        fallback: AppStrings.chatPreviewClassroomFallback,
      );
    }
    return conversation.displayTitle(state.currentUserCode);
  }

  void _openConversation(
    BuildContext context,
    ConversationEntity conversation,
  ) {
    if (conversation.type == ConversationType.classroomChat &&
        (conversation.classroomCode ?? '').trim().isNotEmpty) {
      // Classroom Notes lives on the Classroom screen's own Notes tab (tab
      // index 2 — see AppRoutes.classroom's route definition), not as a
      // standalone thread — matches how every other Notes entry point in
      // the app (notifications, the Classrooms list) opens it.
      context.go(
        '${AppRoutes.classroom}?classroomCode=${conversation.classroomCode!.trim()}&tab=2',
      );
      return;
    }
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ConversationThreadScreen(conversation: conversation),
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final local = dt.toLocal();
    final now = AppTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final msgDay = DateTime(local.year, local.month, local.day);
    final diff = today.difference(msgDay).inDays;
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    final time = '$hh:$mm';
    if (diff == 0) return time;
    if (diff == 1) return AppStrings.chatPreviewYesterday;
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (diff < 7) return days[local.weekday - 1];
    return '${local.day}/${local.month}/${local.year % 100}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
        color: AppColors.chatPreviewSurface,
      ),
      child: BlocBuilder<ChatPreviewCubit, ChatPreviewState>(
        builder: (context, state) => _buildContent(context, state),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ChatPreviewState state) {
    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (state.items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Icon(
              Icons.forum_outlined,
              size: 20,
              color: AppColors.primaryColor.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 10),
            Text(
              AppStrings.chatPreviewEmpty,
              style: AppTextStyles.chatPreviewEmpty,
            ),
          ],
        ),
      );
    }
    final items = state.items;
    return Column(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0)
            Divider(
              height: 1,
              thickness: 1,
              color: AppColors.primaryColor.withValues(alpha: 0.06),
            ),
          _RecentChatRow(
            conversation: items[i],
            timeLabel: _formatTime(items[i].lastMessageAt),
            onTap: () => _openConversation(context, items[i]),
            currentUserCode: state.currentUserCode,
            displayTitle: _displayTitle(items[i], state),
          ),
        ],
      ],
    );
  }
}

class _RecentChatRow extends StatelessWidget {
  const _RecentChatRow({
    required this.conversation,
    required this.timeLabel,
    required this.onTap,
    required this.currentUserCode,
    required this.displayTitle,
  });

  final ConversationEntity conversation;
  final String timeLabel;
  final VoidCallback onTap;
  final String currentUserCode;
  final String displayTitle;

  @override
  Widget build(BuildContext context) {
    final unread = conversation.unreadCount;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            DocumentImageWidget(
              fileUuid: conversation.avatarUrl,
              name: displayTitle,
              size: 50,
              fontSize: 20,
              disableProfileLookupFallback: true,
              disableAttendanceStatusLookup: true,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayTitle,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.chatPreviewTitle,
                        ),
                      ),
                      if (timeLabel.isNotEmpty)
                        Text(timeLabel, style: AppTextStyles.chatPreviewTime),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          MessageContentProcessor.previewText(
                            conversation.lastMessagePreview,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.chatPreviewSnippet,
                        ),
                      ),
                      if (unread > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.chatUnreadBadge,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unread > 99 ? '99+' : '$unread',
                            style: AppTextStyles.chatPreviewUnreadBadge,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
