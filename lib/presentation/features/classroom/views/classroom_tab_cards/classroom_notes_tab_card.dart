import 'package:flutter/material.dart';
import 'package:wowcare/core/util/app_time.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/domain/features/classroom/entities/classroom.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/usecases/get_or_create_classroom_chat_usecase.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/screens/conversation_thread_screen.dart';
import 'package:wowcare/presentation/features/communication/shared/widgets/chat_thread_shimmer.dart';

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
        _conversation = _withCurrentClassroomName(existing);
        _isDraft = false;
      } else {
        _conversation = _draftConversation(code, widget.selectedRoom?.name);
        _isDraft = true;
      }
    });
  }

  /// The classroom chat's stored `title` is whatever the classroom was named
  /// when the conversation was created (or last reconciled) - there is no
  /// mobile-side classroom-rename flow to trigger a re-reconcile, and a
  /// rename made elsewhere (e.g. web) doesn't retroactively update it. This
  /// screen already has the classroom's CURRENT name via [widget.selectedRoom]
  /// (freshly fetched by the parent Classroom screen), so prefer that for
  /// display over the possibly-stale stored title.
  ConversationEntity _withCurrentClassroomName(ConversationEntity conv) {
    final currentName = widget.selectedRoom?.name.trim() ?? '';
    if (currentName.isEmpty || currentName == conv.title) return conv;
    return ConversationEntity(
      id: conv.id,
      code: conv.code,
      title: currentName,
      type: conv.type,
      organizationCode: conv.organizationCode,
      schoolCode: conv.schoolCode,
      status: conv.status,
      description: conv.description,
      avatarUrl: conv.avatarUrl,
      createdAt: conv.createdAt,
      createdBy: conv.createdBy,
      updatedAt: conv.updatedAt,
      updatedBy: conv.updatedBy,
      participantCount: conv.participantCount,
      unreadCount: conv.unreadCount,
      lastMessagePreview: conv.lastMessagePreview,
      participants: conv.participants,
      studentCode: conv.studentCode,
      studentStatus: conv.studentStatus,
      classroomCode: conv.classroomCode,
      lastMessageAt: conv.lastMessageAt,
      lastMessageBy: conv.lastMessageBy,
      lastMessageSenderName: conv.lastMessageSenderName,
      privateModeActive: conv.privateModeActive,
      privateModeActivatedBy: conv.privateModeActivatedBy,
      privateModeActivatedAt: conv.privateModeActivatedAt,
      privateModeStates: conv.privateModeStates,
    );
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
    final result = await serviceLocator<GetOrCreateClassroomChatUseCase>()
        .call(code, classroomName: widget.selectedRoom?.name);
    final conversation = result.fold((_) => null, (c) => c);
    if (conversation != null && mounted) {
      // GetOrCreateClassroomChatUseCase.call() only passes classroomName
      // through to a fresh create/reconcile - if it found an already-
      // existing conversation instead, that title can be just as stale as
      // findExisting's in _load(). Apply the same current-name override.
      final resolved = _withCurrentClassroomName(conversation);
      // Keep our own reference in sync so a later rebuild embeds the real thread.
      _conversation = resolved;
      _isDraft = false;
      return resolved;
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
              const Icon(Icons.forum_outlined, size: 40, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                _error ?? 'Classroom chat is not available',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
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
      key: ValueKey(_isDraft ? 'draft:${widget.selectedRoom?.code}' : _conversation!.code),
      conversation: _conversation!,
      showOwnScaffold: false,
      isDraft: _isDraft,
      onResolveConversation: _isDraft ? _resolveConversation : null,
    );
  }
}
