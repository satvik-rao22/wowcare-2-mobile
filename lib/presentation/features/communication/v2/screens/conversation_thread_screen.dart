import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_reactions/flutter_chat_reactions.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/util/message_content_processor.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/message_entity.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';
import 'package:wowcare/domain/features/communication/usecases/search_messages_usecase.dart';
import 'package:wowcare/presentation/features/auth/cubit/auth_cubit.dart';
import 'package:wowcare/presentation/features/communication/v2/cubit/conversation_thread_cubit.dart';
import 'package:wowcare/presentation/features/communication/v2/cubit/conversation_thread_state.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/participant_info_dialog.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/message_attachment_bottom_sheet.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/message_status_dialog.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/chat_input_bar.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/chat_thread_shimmer.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/message_bubble_widget.dart';
import 'package:wowcare/presentation/features/communication/v2/cubit/private_mode_toggle_cubit.dart';
import 'package:wowcare/presentation/features/communication/v2/cubit/private_mode_toggle_state.dart';
import 'package:wowcare/domain/features/communication/usecases/toggle_private_mode_usecase.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';

/// Full-screen conversation thread for v2 conversations (STAFF_DIRECT, ROOM_CHAT, ADMIN_CHAT).
class ConversationThreadScreen extends StatefulWidget {
  const ConversationThreadScreen({
    super.key,
    required this.conversation,
    /// When false the widget renders only its body (no GlobalScaffold / nav
    /// bar). Use this to embed the thread inline inside a parent screen.
    this.showOwnScaffold = true,
    /// When true a Private Mode toggle is shown at the top-right of the
    /// participant header. Only meaningful for the parent persona.
    this.showPrivateModeToggle = false,
    /// Initial private-mode state seed (from [ConversationEntity.privateModeStates]).
    this.initialPrivateModeEnabled = false,
  });

  final ConversationEntity conversation;
  final bool showOwnScaffold;
  final bool showPrivateModeToggle;
  final bool initialPrivateModeEnabled;

  @override
  State<ConversationThreadScreen> createState() =>
      _ConversationThreadScreenState();
}

class _ConversationThreadScreenState extends State<ConversationThreadScreen> {
  late final ConversationThreadCubit _cubit;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _senderCode = '';
  String _senderName = '';
  ParticipantRole _senderRole = ParticipantRole.staff;
  String _organizationCode = '';
  String _schoolCode = '';

  late final ReactionsController _reactionsController;
  MessageEntity? _quotedMessage;
  MessageEntity? _editingMessage;
  final FocusNode _inputFocusNode = FocusNode();

  /// Attachments selected from [MessageAttachmentBottomSheet] but not yet sent.
  List<ChatAttachment> _pendingAttachments = [];

  /// Only non-null when [widget.showPrivateModeToggle] is true.
  PrivateModeToggleCubit? _privateModeToggleCubit;

  // ── Draft persistence ─────────────────────────────────────────────────────

  /// SharedPreferences key for the per-conversation draft.
  String get _draftStorageKey =>
      'msg_draft_${widget.conversation.code}';

  // ── Per-message GlobalKeys (scroll-to-original) ───────────────────────────

  /// Maps message code → GlobalKey so [Scrollable.ensureVisible] can jump to
  /// any rendered bubble precisely.
  final Map<String, GlobalKey> _messageKeys = {};

  GlobalKey _keyForMessage(String code) =>
      _messageKeys.putIfAbsent(code, GlobalKey.new);

  // ── In-thread search ──────────────────────────────────────────────────────

  late final SearchMessagesUseCase _searchUseCase;
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  List<MessageEntity> _searchResults = [];
  bool _isSearching = false;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();

    final authState = context.read<AuthCubit>().state;
    final userCodeFromAuth = authState is AuthLoaded
        ? authState.loginResponse.userCode.trim()
        : '';

    _reactionsController = ReactionsController(
      currentUserId: userCodeFromAuth.isNotEmpty ? userCodeFromAuth : 'me',
    );

    _cubit = ConversationThreadCubit(
      conversationCode: widget.conversation.code,
      currentUserCode: userCodeFromAuth,
      watchMessagesUseCase: serviceLocator(),
      getMessagesUseCase: serviceLocator(),
      sendMessageUseCase: serviceLocator(),
      editMessageUseCase: serviceLocator(),
      deleteMessageUseCase: serviceLocator(),
      addReactionUseCase: serviceLocator(),
      removeReactionUseCase: serviceLocator(),
      markConversationReadUseCase: serviceLocator(),
    );
    _searchUseCase = SearchMessagesUseCase(serviceLocator());

    _cubit.startWatchingMessages();
    unawaited(_loadSenderInfo());
    unawaited(_loadDraft());

    if (widget.showPrivateModeToggle) {
      _privateModeToggleCubit = PrivateModeToggleCubit(
        togglePrivateModeUseCase: TogglePrivateModeUseCase(serviceLocator()),
        conversationCode: widget.conversation.code,
        initialEnabled: widget.initialPrivateModeEnabled,
      );
    }
  }

  Future<void> _loadSenderInfo() async {
    final storage = serviceLocator<StorageService>();
    final userCode = (await storage.getString(StorageKeys.userCode) ?? '')
        .trim();
    final displayName = (await storage.getString(StorageKeys.displayName) ?? '')
        .trim();
    final orgCode =
        (await storage.getString(StorageKeys.organizationCode) ?? '').trim();
    final school = (await storage.getString(StorageKeys.schoolCode) ?? '')
        .trim();
    final rolesRaw = (await storage.getString(StorageKeys.roles) ?? '')
        .trim()
        .toUpperCase();

    if (!mounted) return;
    setState(() {
      _senderCode = userCode;
      _senderName = displayName.isNotEmpty ? displayName : userCode;
      _organizationCode = orgCode;
      _schoolCode = school;
      _senderRole = ParticipantRole.fromApiString(rolesRaw);
    });
  }

  // ── Draft persistence ─────────────────────────────────────────────────────

  Future<void> _loadDraft() async {
    final storage = serviceLocator<StorageService>();
    final draft = await storage.getString(_draftStorageKey);
    if (draft != null && draft.isNotEmpty && mounted) {
      _inputController.text = draft;
      _inputController.selection = TextSelection.collapsed(
        offset: draft.length,
      );
    }
  }

  Future<void> _saveDraft() async {
    final storage = serviceLocator<StorageService>();
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      await storage.remove(_draftStorageKey);
    } else {
      await storage.saveString(_draftStorageKey, text);
    }
  }

  // ── In-thread search ──────────────────────────────────────────────────────

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    setState(() => _isSearching = true);
    _searchDebounce = Timer(const Duration(milliseconds: 400), () async {
      final result = await _searchUseCase(
        conversationCode: widget.conversation.code,
        query: query.trim(),
        limit: 30,
      );
      if (!mounted) return;
      result.fold(
        (_) => setState(() => _isSearching = false),
        (hits) => setState(() {
          _searchResults = hits;
          _isSearching = false;
        }),
      );
    });
  }

  void _closeSearch() {
    _searchDebounce?.cancel();
    setState(() {
      _showSearch = false;
      _searchResults = [];
      _isSearching = false;
    });
    _searchController.clear();
  }

  // ── Scroll to message (GlobalKey-based) ───────────────────────────────────

  void _scrollToMessage(String messageCode) {
    final key = _messageKeys[messageCode];
    if (key?.currentContext == null) return;
    Scrollable.ensureVisible(
      key!.currentContext!,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      alignment: 0.5,
    );
  }

  @override
  void dispose() {
    unawaited(_saveDraft());
    _searchDebounce?.cancel();
    unawaited(_cubit.close());
    _privateModeToggleCubit?.close();
    _inputController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _reactionsController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Participants ──────────────────────────────────────────────────────────

  List<ParticipantDisplayData> get _participantData =>
      widget.conversation.participants.map((p) {
        final roleStr = p.role.toApiString().toUpperCase();
        final normalised = roleStr == 'PARENT' ? 'GUARDIAN' : roleStr;
        return ParticipantDisplayData(
          userCode: p.userCode,
          displayName: p.userName.isNotEmpty ? p.userName : p.userCode,
          role: normalised,
        );
      }).toList();

  void _showParticipantsDialog() {
    ParticipantInfoDialog.show(
      context,
      participants: _participantData,
      studentName: widget.conversation.title,
    );
  }

  // ── Attachment sheet ──────────────────────────────────────────────────────

  void _showAttachmentSheet() {
    unawaited(
      MessageAttachmentBottomSheet.show(
        context,
        onAttachmentsSelected: (attachments) {
          setState(() => _pendingAttachments.addAll(attachments));
        },
        onEmojiSelected: (emoji) {
          final pos = _inputController.selection.isValid
              ? _inputController.selection.baseOffset
              : _inputController.text.length;
          final text = _inputController.text;
          _inputController.value = _inputController.value.copyWith(
            text: text.substring(0, pos) + emoji + text.substring(pos),
            selection: TextSelection.collapsed(offset: pos + emoji.length),
          );
        },
        onViewParticipants: _showParticipantsDialog,
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _senderCode.isEmpty) return;

    if (_editingMessage != null) {
      final messageCode = _editingMessage!.code;
      _inputController.clear();
      final originalEditMsg = _editingMessage!;
      setState(() {
        _editingMessage = null;
      });

      if (text != originalEditMsg.text) {
        await _cubit.editMessage(
          messageCode: messageCode,
          newText: text,
        );
        if (mounted) {
          CoreUtils.showTopSnackBar(
            context: context,
            message: 'Message updated successfully',
            isSuccess: true,
          );
        }
      }
      return;
    }

    _inputController.clear();
    unawaited(_saveDraft()); // clears the stored draft (text is now empty)
    await _cubit.sendMessage(
      text: text,
      senderCode: _senderCode,
      senderName: _senderName,
      senderRole: _senderRole,
      organizationCode: _organizationCode,
      schoolCode: _schoolCode,
      threadParentCode: _quotedMessage?.code,
    );
    setState(() {
      _quotedMessage = null;
      _pendingAttachments.clear();
    });
    _scrollToBottom();
  }

  // ── Date chip ─────────────────────────────────────────────────────────────

  String _dateSeparatorLabel(DateTime date) {
    final tz = SchoolTimezoneResolver.lastKnownTimeZone;
    final d = SchoolZoneDateTime.dateTimeFromInstantInSchool(date, tz);
    final now = SchoolZoneDateTime.dateTimeFromInstantInSchool(
      DateTime.now().toUtc(),
      tz,
    );
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return 'Today, ${d.day} ${months[d.month - 1]} ${d.year}';
    } else if (d.year == now.year &&
        d.month == now.month &&
        d.day == now.day - 1) {
      return 'Yesterday, ${d.day} ${months[d.month - 1]} ${d.year}';
    }
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  bool _isDifferentDay(DateTime a, DateTime b) {
    final tz = SchoolTimezoneResolver.lastKnownTimeZone;
    final da = SchoolZoneDateTime.dateTimeFromInstantInSchool(a, tz);
    final db = SchoolZoneDateTime.dateTimeFromInstantInSchool(b, tz);
    return da.year != db.year || da.month != db.month || da.day != db.day;
  }

  // ── Role color (matches parent messaging) ────────────────────────────────

  String _roleFallbackName(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return 'Admin';
      case 'GUARDIAN':
        return 'Guardian';
      case 'STAFF':
        return 'Staff';
      default:
        return role;
    }
  }

  Color _roleColor(String role) {
    switch (role.toUpperCase()) {
      case 'GUARDIAN':
        return const Color(0xFF6C63FF);
      case 'STAFF':
        return const Color(0xFF00897B);
      case 'ADMIN':
        return const Color(0xFFE65100);
      default:
        return AppColors.primaryColor;
    }
  }

  // ── Participant header ────────────────────────────────────────────────────

  Widget _buildParticipantHeader() {
    final participants = widget.conversation.participants;
    final title = widget.conversation.title.isNotEmpty
        ? widget.conversation.title
        : 'Conversation';
    final count = participants.isNotEmpty ? participants.length : null;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.transparent,
        border: Border(bottom: BorderSide(color: Color(0xFFE9ECEF), width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryColor.withValues(alpha: 0.12),
                child: Text(
                  title.isNotEmpty ? title[0].toUpperCase() : '?',
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomTextWidget(
                      text: title,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                    if (count != null)
                      Text(
                        '$count participant${count == 1 ? '' : 's'}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF636E72),
                        ),
                      ),
                  ],
                ),
              ),
              // Private Mode toggle — parent persona only
              if (widget.showPrivateModeToggle &&
                  _privateModeToggleCubit != null)
                BlocBuilder<PrivateModeToggleCubit, PrivateModeToggleState>(
                  bloc: _privateModeToggleCubit,
                  builder: (_, pmState) => Tooltip(
                    message: pmState.isEnabled
                        ? 'Private Mode ON'
                        : 'Private Mode OFF',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Private Mode',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: pmState.isEnabled
                                ? const Color(0xFF6C63FF)
                                : const Color(0xFFB2BEC3),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Switch.adaptive(
                          value: pmState.isEnabled,
                          onChanged: pmState.isLoading
                              ? null
                              : (_) => _privateModeToggleCubit!.toggle(),
                          activeThumbColor: const Color(0xFF6C63FF),
                          activeTrackColor: const Color(0xFF6C63FF).withValues(alpha: 0.4),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                  ),
                ),
              Tooltip(
                message: _showSearch ? 'Close search' : 'Search messages',
                child: IconButton(
                  icon: Icon(
                    _showSearch ? Icons.search_off_rounded : Icons.search_rounded,
                    color: AppColors.primaryColor,
                  ),
                  onPressed: () {
                    if (_showSearch) {
                      _closeSearch();
                    } else {
                      setState(() => _showSearch = true);
                    }
                  },
                ),
              ),
              Tooltip(
                message: 'View Participants',
                child: IconButton(
                  icon: const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.primaryColor,
                  ),
                  onPressed: _showParticipantsDialog,
                ),
              ),
            ],
          ),
          if (participants.isNotEmpty) ...[
            const SizedBox(height: 8),
            Builder(builder: (context) {
              final isAdminChat = widget.conversation.type == ConversationType.adminChat;
              final visibleParticipants = isAdminChat
                  ? participants.where((p) =>
                      p.role.toApiString().toUpperCase() == 'ADMIN').toList()
                  : participants;
              if (visibleParticipants.isEmpty) return const SizedBox.shrink();
              return SizedBox(
              height: 28,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: visibleParticipants.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  final p = visibleParticipants[index];
                  final roleStr = p.role.toApiString().toUpperCase() == 'PARENT'
                      ? 'GUARDIAN'
                      : p.role.toApiString().toUpperCase();
                  // Always show display name — never fall back to userCode
                  final name = p.userName.isNotEmpty
                      ? p.userName
                      : _roleFallbackName(roleStr);
                  final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
                  final color = _roleColor(roleStr);

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 8,
                          backgroundColor: color.withValues(alpha: 0.25),
                          child: Text(
                            initial,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            roleStr,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
            }),
          ],
        ],
      ),
    );
  }

  // ── Message list ──────────────────────────────────────────────────────────

  Widget _buildMessageList(ConversationThreadState state) {
    if (state.isLoading && !state.hasMessages) {
      return const ChatThreadShimmer();
    }

    if (!state.hasMessages && state.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: AppColors.primaryColor.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              Text(
                state.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF636E72)),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _cubit.loadMessages,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    if (!state.hasMessages) {
      return const Center(
        child: Text(
          'No messages yet. Say hello!',
          style: TextStyle(color: Color(0xFFB2BEC3), fontSize: 14),
        ),
      );
    }

    final messages = state.messages;

    return RefreshIndicator(
      onRefresh: _cubit.refreshMessages,
      color: AppColors.primaryColor,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        reverse: true,
        itemCount: messages.length,
        itemBuilder: (context, index) {
          // reverse: true means index 0 = last message
          final msg = messages[messages.length - 1 - index];
          final prevIndex = messages.length - 2 - index;

          bool showDateHeader;
          if (prevIndex >= 0) {
            showDateHeader = _isDifferentDay(
              msg.sentAt,
              messages[prevIndex].sentAt,
            );
          } else {
            showDateHeader = true;
          }

          final prevMsg = prevIndex >= 0 ? messages[prevIndex] : null;
          final isGrouped =
              !showDateHeader && _isSameSender(prevMsg, msg);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showDateHeader) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 10),
                  child: Center(
                    child: CustomTextWidget(
                      text: _dateSeparatorLabel(msg.sentAt),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      applyLetterSpacing: false,
                    ),
                  ),
                ),
              ],
              (() {
                final message = _mapEntityToMessage(msg, _senderCode);
                Message? quotedMessage;
                if (msg.threadParentCode != null) {
                  final parentMatches = messages.where(
                    (m) => m.code == msg.threadParentCode,
                  );
                  if (parentMatches.isNotEmpty) {
                    quotedMessage = _mapEntityToMessage(
                      parentMatches.first,
                      _senderCode,
                    );
                  }
                }
                return MessageBubble(
                  key: _keyForMessage(
                    msg.code.isNotEmpty ? msg.code : msg.id,
                  ),
                  message: message,
                  quotedMessage: quotedMessage,
                  currentUserCode: _senderCode,
                  reactionsController: _reactionsController,
                  onScrollToQuoted: (quoteId) => _scrollToMessage(quoteId),
                  // Swipe-to-reply and menu Reply are disabled for deleted messages.
                  onReply: msg.isDeleted
                      ? null
                      : () => setState(() => _quotedMessage = msg),
                  onReplyFromMenu: msg.isDeleted
                      ? null
                      : () => setState(() => _quotedMessage = msg),
                  onCopy: () {
                    Clipboard.setData(ClipboardData(
                      text: MessageContentProcessor.stripHtmlTags(msg.text),
                    ));
                    CoreUtils.showTopSnackBar(
                      context: context,
                      message: 'Message copied successfully',
                      isSuccess: true,
                    );
                  },
                  onEdit: () {
                    setState(() {
                      _editingMessage = msg;
                      _inputController.text =
                          MessageContentProcessor.stripHtmlTags(msg.text);
                    });
                    _inputFocusNode.requestFocus();
                  },
                  onDelete: () async {
                    await _cubit.deleteMessage(msg.code);
                    if (context.mounted) {
                      CoreUtils.showTopSnackBar(
                        context: context,
                        message: 'Message deleted successfully',
                        isSuccess: true,
                      );
                    }
                  },
                  onInfo: () => MessageStatusDialog.show(
                    context,
                    message: msg,
                  ),
                  onReactionAdded: (emoji) {
                    final myReaction = msg.reactions[_senderCode];
                    if (myReaction == emoji) {
                      _cubit.removeReaction(
                        messageCode: msg.code,
                        emoji: emoji,
                        currentUserCode: _senderCode,
                      );
                    } else {
                      _cubit.addReaction(
                        messageCode: msg.code,
                        emoji: emoji,
                        currentUserCode: _senderCode,
                      );
                    }
                  },
                  onRemoveReaction: (emoji) {
                    _cubit.removeReaction(
                      messageCode: msg.code,
                      emoji: emoji,
                      currentUserCode: _senderCode,
                    );
                  },
                  onReactionTap: () => _showEmojiPicker(context, msg),
                  isParentMessaging: _senderRole == ParticipantRole.parent,
                  isDeleted: msg.isDeleted,
                  isGrouped: isGrouped,
                );
              })(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThreadBody() {
    return BlocConsumer<ConversationThreadCubit, ConversationThreadState>(
      listener: (context, state) {
        if (state.hasMessages) _scrollToBottom();
      },
      builder: (context, state) {
        return Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showOwnScaffold) ...[
              CustomTextWidget(text: 'Messaging', fontSize: 16),
              const SizedBox(height: 10),
            ],
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFFF4F7FD),
                ),
                child: Column(
                  children: [
                    _buildParticipantHeader(),
                    // ── In-thread search bar ─────────────────────────────────
                    if (_showSearch) _buildSearchBar(),
                    Expanded(
                      child: Stack(
                        children: [
                          _buildMessageList(state),
                          // Search results overlay
                          if (_showSearch &&
                              (_searchResults.isNotEmpty || _isSearching))
                            _buildSearchResultsOverlay(),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(12),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: ChatInputBar(
                        controller: _inputController,
                        focusNode: _inputFocusNode,
                        isSending: state.isSending,
                        onSend: () => unawaited(_sendMessage()),
                        onAttachmentTap: _showAttachmentSheet,
                        pendingAttachments: _pendingAttachments,
                        onRemoveAttachment: (i) =>
                            setState(() => _pendingAttachments.removeAt(i)),
                        quotedMessage: _quotedMessage != null
                            ? _mapEntityToMessage(_quotedMessage!, _senderCode)
                            : null,
                        onCancelQuote: () =>
                            setState(() => _quotedMessage = null),
                        editingMessage: _editingMessage != null
                            ? _mapEntityToMessage(_editingMessage!, _senderCode)
                            : null,
                        onCancelEdit: () => setState(() {
                          _editingMessage = null;
                          _inputController.clear();
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    final body = BlocProvider<ConversationThreadCubit>.value(
      value: _cubit,
      child: _buildThreadBody(),
    );

    if (!widget.showOwnScaffold) return body;

    return GlobalScaffold(
      hasBackButton: true,
      showCustomNavigationBar: !isLandscape,
      body: Padding(padding: const EdgeInsets.all(10), child: body),
    );
  }

  Message _mapEntityToMessage(MessageEntity entity, String currentUserCode) {
    return Message(
      id: entity.id,
      code: entity.code,
      text: entity.text,
      isSentByMe: entity.senderCode == currentUserCode,
      time: entity.sentAt,
      editedAt: entity.editedAt,
      reactions: entity.reactions,
      senderName: entity.senderName,
      senderUserCode: entity.senderCode,
      quotedMessageId: entity.threadParentCode,
      isPrivate: entity.isPrivate,
      attachments: entity.attachments
          .map(
            (a) => ChatAttachment(
              name: a.fileName,
              type: a.attachmentType == AttachmentType.image ? 'image' : 'file',
              sizeBytes: a.fileSizeBytes,
              mimeType: a.mimeType,
              remoteUrl: a.fileUrl,
              localPath: a.localFilePath,
            ),
          )
          .toList(),
    );
  }

  bool _isSameSender(MessageEntity? prev, MessageEntity current) {
    if (prev == null) return false;
    final prevCode = prev.senderCode;
    final currCode = current.senderCode;
    if (prevCode.isNotEmpty && currCode.isNotEmpty) {
      return prevCode == currCode &&
          current.sentAt.difference(prev.sentAt).inMinutes <= 5;
    }
    return (prev.senderCode == _senderCode) == (current.senderCode == _senderCode) &&
        current.sentAt.difference(prev.sentAt).inMinutes <= 5;
  }

  // ── Search bar ────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: _onSearchChanged,
              style: const TextStyle(fontSize: 14, fontFamily: 'Manrope'),
              decoration: InputDecoration(
                hintText: 'Search messages…',
                hintStyle: const TextStyle(
                  color: Color(0xFFB2BEC3),
                  fontSize: 14,
                  fontFamily: 'Manrope',
                ),
                prefixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Icon(Icons.search_rounded,
                        color: Color(0xFFB2BEC3), size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Color(0xFFB2BEC3), size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: const Color(0xFFF4F7FD),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _closeSearch,
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.primaryColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search results overlay ────────────────────────────────────────────────

  Widget _buildSearchResultsOverlay() {
    return Positioned.fill(
      child: Material(
        color: Colors.white.withValues(alpha: 0.97),
        child: _isSearching && _searchResults.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _searchResults.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: AppColors.primaryColor.withValues(alpha: 0.25),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No messages found',
                          style: TextStyle(
                            color: const Color(0xFF636E72),
                            fontSize: 14,
                            fontFamily: 'Manrope',
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final hit = _searchResults[i];
                      final query = _searchController.text.trim().toLowerCase();
                      final plain = hit.text
                          .replaceAll(RegExp(r'<[^>]*>'), '')
                          .trim();

                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              AppColors.primaryColor.withValues(alpha: 0.12),
                          child: Text(
                            hit.senderName.isNotEmpty
                                ? hit.senderName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                        title: Text(
                          hit.senderName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF573353),
                          ),
                        ),
                        subtitle: _buildHighlightedText(plain, query),
                        trailing: Text(
                          _formatSearchTime(hit.sentAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        onTap: () {
                          _closeSearch();
                          // Give the list time to rebuild before scrolling.
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _scrollToMessage(
                              hit.code.isNotEmpty ? hit.code : hit.id,
                            );
                          });
                        },
                      );
                    },
                  ),
      ),
    );
  }

  /// Returns a [RichText] where every occurrence of [query] in [text] is
  /// rendered in bold / primary-colour so the match stands out.
  Widget _buildHighlightedText(String text, String query) {
    if (query.isEmpty) {
      return Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12, color: Color(0xFF636E72)),
      );
    }

    final lower = text.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (start < text.length) {
      final idx = lower.indexOf(query, start);
      if (idx == -1) {
        spans.add(TextSpan(
          text: text.substring(start),
          style: const TextStyle(fontSize: 12, color: Color(0xFF636E72)),
        ));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(
          text: text.substring(start, idx),
          style: const TextStyle(fontSize: 12, color: Color(0xFF636E72)),
        ));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + query.length),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryColor,
        ),
      ));
      start = idx + query.length;
    }

    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(children: spans),
    );
  }

  String _formatSearchTime(DateTime dt) {
    final tz = SchoolTimezoneResolver.lastKnownTimeZone;
    final d = SchoolZoneDateTime.dateTimeFromInstantInSchool(dt, tz);
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  void _showEmojiPicker(BuildContext context, MessageEntity message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final sheetHeight =
            (MediaQuery.of(context).size.height * 0.55).clamp(240.0, 400.0) +
            MediaQuery.of(context).padding.bottom;
        return Container(
          height: sheetHeight,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: EmojiPicker(
            onEmojiSelected: (category, emoji) {
              Navigator.pop(context); // close picker
              final myReaction = message.reactions[_senderCode];
              if (myReaction == emoji.emoji) {
                _cubit.removeReaction(
                  messageCode: message.code,
                  emoji: emoji.emoji,
                  currentUserCode: _senderCode,
                );
              } else {
                _cubit.addReaction(
                  messageCode: message.code,
                  emoji: emoji.emoji,
                  currentUserCode: _senderCode,
                );
              }
            },
            config: const Config(
              checkPlatformCompatibility: true,
              emojiSet: null,
              locale: Locale('en'),
              emojiTextStyle: null,
              customBackspaceIcon: null,
              customSearchIcon: null,
              viewOrderConfig: ViewOrderConfig(),
              emojiViewConfig: EmojiViewConfig(),
              skinToneConfig: SkinToneConfig(enabled: true),
              categoryViewConfig: CategoryViewConfig(
                recentTabBehavior: RecentTabBehavior.RECENT,
              ),
              bottomActionBarConfig: BottomActionBarConfig(enabled: false),
              searchViewConfig: SearchViewConfig(),
            ),
          ),
        );
      },
    );
  }
}
