import 'package:flutter/material.dart';
import 'package:wowcare/core/util/app_time.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/domain/features/classroom/entities/classroom.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/usecases/get_or_create_classroom_chat_usecase.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/screens/conversation_thread_screen.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/chat_thread_shimmer.dart';

import '../../../../../app/theme/colors.dart';

/// Re-exported for backwards compatibility: reusable_modal_bottom_sheet.dart imports DataMap
/// from this file.
typedef DataMap = Map<String, dynamic>;

/// Notes tab = the classroom's staff chat (CLASSROOM_CHAT). Resolves (creating on first use, with
/// the classroom name as title + staff roster) the classroom's conversation, then embeds the
/// shared [ConversationThreadScreen] for the full chat experience (history, send, realtime).
class ClassroomNotesTabCard extends StatefulWidget {
  const ClassroomNotesTabCard({
    required this.scrollController,
    required this.selectedRoom,
    super.key,
  });

  final ScrollController scrollController;
  final Classroom? selectedRoom;
  static const routeName = '/classroom-notes-screen';

  @override
  State<ClassroomNotesTabCard> createState() => _ClassroomNotesTabCardState();
}

class _ClassroomNotesTabCardState extends State<ClassroomNotesTabCard> {
  bool _loading = true;
  String? _error;
  ConversationEntity? _conversation;

  /// True when [_conversation] is a placeholder (no classroom chat exists yet).
  /// The thread opens as a draft — composer over an empty list — and the
  /// conversation is created on the first message. Mirrors the web Notes tab.
  bool _isDraft = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ClassroomNotesTabCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedRoom?.code != widget.selectedRoom?.code) {
      _load();
    }
  }

  Future<void> _load() async {
    final code = widget.selectedRoom?.code;
    if (code == null || code.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'No classroom selected';
        _conversation = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    // GET-only: do NOT create the chat on open (web parity). If the classroom
    // chat already exists, open the real thread; otherwise open a draft thread
    // (composer over an empty list) and create it on the first message.
    final existing = await serviceLocator<GetOrCreateClassroomChatUseCase>()
        .findExisting(code);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = null;
      if (existing != null) {
        _conversation = existing;
        _isDraft = false;
      } else {
        _conversation = _draftConversation(code, widget.selectedRoom?.name);
        _isDraft = true;
      }
    });
  }

  /// A placeholder [ConversationEntity] for a classroom that has no chat yet.
  /// Carries no server `code` — the real conversation is created on first send
  /// via [_resolveConversation]. org/school come from the real conversation
  /// once created; the send path sources them from the signed-in session.
  ConversationEntity _draftConversation(String classroomCode, String? name) {
    final now = AppTime.now();
    return ConversationEntity(
      id: 0,
      code: '',
      title: (name ?? '').isNotEmpty ? name! : 'Classroom',
      type: ConversationType.classroomChat,
      organizationCode: '',
      schoolCode: '',
      status: 'ACTIVE',
      description: '',
      avatarUrl: '',
      createdAt: now,
      createdBy: '',
      updatedAt: now,
      updatedBy: '',
      participantCount: 0,
      unreadCount: 0,
      lastMessagePreview: '',
      participants: const [],
      classroomCode: classroomCode,
    );
  }

  /// Creates the classroom chat on the server (title = classroom name + staff
  /// roster) and returns the now-real conversation. Invoked on first send for a
  /// draft thread.
  Future<ConversationEntity?> _resolveConversation() async {
    final code = widget.selectedRoom?.code;
    if (code == null || code.isEmpty) return null;
    final result = await serviceLocator<GetOrCreateClassroomChatUseCase>().call(
      code,
      classroomName: widget.selectedRoom?.name,
    );
    final conversation = result.fold((_) => null, (c) => c);
    if (conversation != null && mounted) {
      // Keep our own reference in sync so a later rebuild embeds the real thread.
      _conversation = conversation;
      _isDraft = false;
    }
    return conversation;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      // Matches StaffMessagingThread/ParentMessagingThread/
      // ConversationThreadScreen's own loading state.
      return const ChatThreadShimmer();
    }
    if (_error != null || _conversation == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.forum_outlined, size: 40, color: AppColors.grey),
              const SizedBox(height: 12),
              Text(
                _error ?? 'Classroom chat is not available',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.grey),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    // Embed the shared chat thread inline (no own scaffold/nav bar). When the
    // classroom chat doesn't exist yet this is a draft — the thread shows the
    // composer over an empty list and creates the conversation on first send.
    return ConversationThreadScreen(
      // Rebuild the thread when a draft becomes a real conversation so the
      // cubit binds to the real conversationCode from the start.
      key: ValueKey(
        _isDraft ? 'draft:${widget.selectedRoom?.code}' : _conversation!.code,
      ),
      conversation: _conversation!,
      showOwnScaffold: false,
      isDraft: _isDraft,
      onResolveConversation: _isDraft ? _resolveConversation : null,
    );
  }
}
