import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/app_time.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import '../../../../domain/features/communication/entities/conversation.dart';
import '../../../../domain/features/communication/entities/message.dart';
import '../../../../domain/features/communication/entities/reaction_entry.dart';
import '../../../../domain/features/communication/usecases/get_conversations_usecase.dart';
import '../../../../domain/features/communication/usecases/get_messages_usecase.dart';
import '../../../../domain/features/communication/usecases/get_cached_conversations_usecase.dart';
import '../../../../domain/features/communication/usecases/get_cached_messages_usecase.dart';
import '../../../../domain/features/communication/usecases/cache_message_usecase.dart';
import '../../../../domain/features/communication/usecases/add_reaction_usecase.dart';
import '../../../../domain/features/communication/usecases/send_message_usecase.dart';
import '../../../../domain/features/communication/usecases/edit_message_usecase.dart';
import '../../../../domain/features/communication/usecases/delete_message_usecase.dart';
import '../../../../domain/features/communication/usecases/delete_attachment_usecase.dart';
import '../../../../domain/features/communication/usecases/remove_reaction_legacy_usecase.dart';
import '../../../../domain/features/communication/usecases/clear_cache_usecase.dart';
import '../../../../domain/features/communication/usecases/mark_conversation_delivered_usecase.dart';
import '../../../../domain/features/communication/usecases/mark_conversation_read_usecase.dart';
import '../../../../domain/features/communication/usecases/watch_messages_legacy_usecase.dart';
import '../../../../domain/features/communication/usecases/watch_conversations_legacy_usecase.dart';
import '../../../../domain/features/communication/usecases/get_legacy_unread_counts_per_conversation_usecase.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/chat_attachment_uploader.dart';
import 'package:wowcare/presentation/features/communication/shared/utils/pending_attachment_storage.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/communication/messaging_event_service.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import 'unread_badge_cubit.dart';
import 'communication_state.dart';

class CommunicationCubit extends Cubit<CommunicationState> {
  final GetMessagesUseCase getMessagesUseCase;
  final SendMessageUseCase sendMessageUseCase;
  final GetConversationsUseCase getConversationsUseCase;
  final GetCachedConversationsUseCase getCachedConversationsUseCase;
  final GetCachedMessagesUseCase getCachedMessagesUseCase;
  final AddReactionUseCase addReactionUseCase;
  final EditMessageUseCase editMessageUseCase;
  final DeleteMessageUseCase deleteMessageUseCase;
  final DeleteAttachmentUseCase deleteAttachmentUseCase;
  final RemoveReactionLegacyUseCase removeReactionLegacyUseCase;
  final ClearMessagesCacheUseCase clearMessagesCacheUseCase;
  final ClearConversationsCacheUseCase clearConversationsCacheUseCase;
  final ChatAttachmentUploader attachmentUploader;
  final WatchMessagesLegacyUseCase watchMessagesUseCase;
  final WatchConversationsLegacyUseCase watchConversationsUseCase;
  final MarkConversationDeliveredUseCase markConversationDeliveredUseCase;
  final MarkConversationReadUseCase markConversationReadUseCase;
  final StorageService storageService;
  final CacheMessageUseCase cacheMessageUseCase;
  final DiscardCachedMessageUseCase discardCachedMessageUseCase;
  final GetLegacyUnreadCountsPerConversationUseCase
  getUnreadCountsPerConversationUseCase;

  CommunicationCubit({
    required this.getMessagesUseCase,
    required this.sendMessageUseCase,
    required this.getConversationsUseCase,
    required this.getCachedConversationsUseCase,
    required this.getCachedMessagesUseCase,
    required this.addReactionUseCase,
    required this.editMessageUseCase,
    required this.deleteMessageUseCase,
    required this.deleteAttachmentUseCase,
    required this.removeReactionLegacyUseCase,
    required this.clearMessagesCacheUseCase,
    required this.clearConversationsCacheUseCase,
    required this.attachmentUploader,
    required this.watchMessagesUseCase,
    required this.watchConversationsUseCase,
    required this.markConversationDeliveredUseCase,
    required this.markConversationReadUseCase,
    required this.storageService,
    required this.cacheMessageUseCase,
    required this.discardCachedMessageUseCase,
    required this.getUnreadCountsPerConversationUseCase,
  }) : super(CommunicationInitial());

  /// Marks a conversation as read via the API so the unread badge and count
  /// clear immediately for the current user. Called by screens when they open
  /// a thread or receive new messages while the thread is in the foreground.
  Future<void> markConversationRead(String conversationCode) async {
    final result = await markConversationReadUseCase(conversationCode);
    result.fold(
      (_) {},
      (_) => MessagingEventService.instance.notifyMarkedRead(conversationCode),
    );
  }

  static const _uuid = Uuid();

  /// Page size used by [loadOlderMessages]'s incremental fetches — smaller
  /// than the initial-load window ([loadMessages] always asks for the
  /// latest 100) so each "load more" burst stays light.
  static const int _olderPageSize = 50;

  StreamSubscription<List<Message>>? _messagesSubscription;
  // One live conversation-list subscription PER type. The Staff (STAFF_DIRECT) and Parent
  // (ROOM_CHAT) tabs share this single cubit and both call startWatchingConversations; a single
  // shared subscription meant the second tab cancelled the first's, so one tab's list stopped
  // live-updating (last message / unread / new conversations). Keying by type keeps both alive,
  // mirroring UnreadBadgeCubit.
  final Map<String?, StreamSubscription<List<Conversation>>>
  _conversationsSubscriptions = {};
  String? _watchedThreadId;

  /// Debounces [_applyReliableUnreadCounts] per type — thread open/close
  /// fires several Firestore snapshots in quick succession (read receipt,
  /// delivery, message updates), and each one otherwise queued its own
  /// immediate follow-up fetch + emit. Stacking several list rebuilds right
  /// on top of the Navigator push/pop transition animation was tripping a
  /// Flutter semantics-tree assertion ('!semantics.parentDataDirty').
  /// Collapsing bursts into one fetch, after things settle, avoids it.
  final Map<String?, Timer> _unreadCountsDebounce = {};

  /// Next page to request from [loadOlderMessages] per thread — page 0 is
  /// always the initial/latest window fetched by [loadMessages], so the
  /// first older-history page is 1.
  final Map<String, int> _olderPageByThread = {};

  /// Dedup guard so a conversation's last message only triggers one
  /// markAllAsDelivered call per change — keyed by conversation code,
  /// valued by the `lastMessageAt` we already processed.
  final Map<String, DateTime> _deliveredMarkedAt = {};

  /// Messages with a field-level optimistic edit (reaction add/remove,
  /// attachment delete, message edit/delete) still settling against the
  /// backend — keyed by message code, valued by when the edit was made.
  ///
  /// The realtime stream is backed by Isar, which only reflects a change
  /// once it's round-tripped through the backend → Firestore → local merge
  /// — seconds behind the optimistic UI update. Without this guard, the
  /// very next realtime emission for the thread (for any reason — it
  /// carries the *whole* known message list) would wholesale-replace the
  /// message with its pre-edit version, making the reaction/attachment
  /// appear to revert itself a moment after the user's action.
  final Map<String, DateTime> _recentLocalMutations = {};
  static const Duration _localMutationGuardWindow = Duration(seconds: 8);

  void _markRecentlyMutated(String messageCode) {
    _recentLocalMutations[messageCode] = AppTime.nowUtc();
  }

  /// Starts (or restarts, if already watching a different thread) the
  /// Firestore delta listener for [threadId]'s messages. Safe to call
  /// repeatedly — only new updates flow through; history always comes from
  /// [loadMessages] (API → Isar → UI).
  /// [organizationCode]/[schoolCode] should be the conversation's own
  /// values (not necessarily the session's currently-active school) — a
  /// multi-school parent/admin, or a recent active-school switch, can leave
  /// the session's stored org/school pointing somewhere other than where
  /// this specific conversation actually lives, which builds the wrong
  /// Firestore path and surfaces as a permission-denied error rather than
  /// just empty results. Omit them to fall back to session resolution
  /// (unchanged prior behavior).
  void startWatchingThread(
    String threadId, {
    String? organizationCode,
    String? schoolCode,
  }) {
    if (_watchedThreadId == threadId && _messagesSubscription != null) return;
    _messagesSubscription?.cancel();
    _watchedThreadId = threadId;
    _messagesSubscription =
        watchMessagesUseCase(
          threadId,
          organizationCode: organizationCode,
          schoolCode: schoolCode,
        ).listen(
          (messages) {
            if (isClosed || messages.isEmpty) {
              return;
            }
            final priorState = state is CommunicationLoaded
                ? state as CommunicationLoaded
                : null;
            final latestThreads =
                priorState?.threads ?? <String, List<Message>>{};
            final newThreads = Map<String, List<Message>>.from(latestThreads);
            // Merge rather than replace: this stream is backed by the Isar
            // cache (see CommunicationRepository.watchMessages), which only
            // knows about a message once it's been persisted there — an
            // in-flight optimistic send (sendMessage's tempMessage) hasn't been
            // cached yet and would otherwise flicker out of the list the
            // instant an unrelated realtime update (e.g. someone else's
            // reaction) arrives while it's still pending.
            final currentMessages =
                latestThreads[threadId] ?? const <Message>[];
            final currentByCode = {for (final m in currentMessages) m.code: m};
            final incomingCodes = messages.map((m) => m.code).toSet();
            final stillPending = currentMessages.where(
              (m) => !incomingCodes.contains(m.code),
            );

            final cutoff = AppTime.nowUtc().subtract(_localMutationGuardWindow);
            _recentLocalMutations.removeWhere((_, t) => t.isBefore(cutoff));

            // For a message that's mid-settling from a local reaction/attachment/
            // edit/delete mutation, keep our in-memory version rather than the
            // realtime/Isar one, which doesn't know about it yet.
            final reconciled = messages.map((incoming) {
              final local = currentByCode[incoming.code];
              if (_recentLocalMutations.containsKey(incoming.code)) {
                return local ?? incoming;
              }
              // Preserve deleted state when Firestore/Isar hasn't caught up yet.
              // Without this, a realtime event for an unrelated change (e.g. a
              // reaction on another message) can overwrite the optimistic delete
              // and make "This message has been deleted." disappear.
              if (local != null && local.isDeleted && !incoming.isDeleted) {
                return local;
              }
              return incoming;
            });
            final mergedMessages = _sortByTime([
              ...reconciled,
              ...stillPending,
            ]);
            newThreads[threadId] = mergedMessages;
            final int debugPrevCount = currentMessages.length;
            final draftsInMerged =
                mergedMessages.where((m) => m.isSending || m.isFailed).toList();
            AppLogger.i(
              '[DRAFT SEED] startWatchingThread threadId=$threadId — '
              'incomingFromStream=${messages.length}, stillPending=${stillPending.length}, '
              'mergedTotal=${mergedMessages.length}, draftsInMerged=${draftsInMerged.length}',
            );
            emit(
              priorState?.copyWith(
                    threads: newThreads,
                    activeThreadId: threadId,
                  ) ??
                  CommunicationLoaded(
                    threads: newThreads,
                    activeThreadId: threadId,
                  ),
            );
          },
          // Firestore is a notification layer on top of API/Isar — if the
          // realtime stream errors (missing index, permissions, offline, etc.)
          // we must not crash; the screen keeps working off the last loaded data.
          onError: (Object error, StackTrace stackTrace) {
            AppLogger.e('[Realtime] watchMessages($threadId) failed: $error');
          },
        );
  }

  /// Starts the Firestore delta listener for the conversation list of [type]
  /// (or all types when null). Mirrors [startWatchingThread] — only deltas
  /// flow through; [loadConversations] remains the source of history.
  void startWatchingConversations({String? type}) {
    // Already watching this type — keep it (do NOT cancel other types' subscriptions).
    if (_conversationsSubscriptions.containsKey(type)) {
      return;
    }
    _conversationsSubscriptions[type] = watchConversationsUseCase(type: type)
        .listen(
          (conversations) {
            if (isClosed || conversations.isEmpty) {
              return;
            }
            final prior = state is CommunicationConversationsLoaded
                ? state as CommunicationConversationsLoaded
                : null;
            final currentMap =
                prior?.conversationsByType ?? <String?, List<Conversation>>{};
            final updatedMap = Map<String?, List<Conversation>>.from(
              currentMap,
            );
            final sorted = List<Conversation>.from(conversations)
              ..sort((a, b) {
                final aTime = a.lastMessageAt ?? a.updatedAt;
                final bTime = b.lastMessageAt ?? b.updatedAt;
                return bTime.compareTo(aTime);
              });
            updatedMap[type] = sorted;
            // Preserve pagination bookkeeping — this is a realtime delta, not a
            // fresh paged fetch, so it must not reset `hasMore`/`currentPage`
            // and silently cut off "load more" for the rest of the session.
            final int debugPrevCount = currentMap[type]?.length ?? 0;
            emit(
              CommunicationConversationsLoaded(
                updatedMap,
                currentPageByType: prior?.currentPageByType ?? const {},
                hasMoreByType: prior?.hasMoreByType ?? const {},
                isLoadingMoreByType: prior?.isLoadingMoreByType ?? const {},
              ),
            );
            unawaited(_markDeliveredForIncomingMessages(conversations));
            // Firestore's own unreadCount has been observed to drop for
            // conversations OTHER than the one just read — consistent with a
            // backend aggregate bug on the mark-read path. Correct it from
            // the confirmed-reliable per-conversation REST endpoint (the
            // same one already trusted for REST-driven loads, see
            // CommunicationRepositoryImpl._resolveUnreadCounts).
            // Debounced — see _unreadCountsDebounce.
            _scheduleReliableUnreadCounts(type);
          },
          // Same rationale as startWatchingThread — never let a Firestore
          // failure crash the screen; it just keeps showing API/Isar data.
          onError: (Object error, StackTrace stackTrace) {
            AppLogger.e(
              '[Realtime] watchConversations(type: $type) failed: $error',
            );
          },
        );
  }

  /// Mirrors AppTopbar.tsx's inbox-listener behaviour: whenever a
  /// conversation's last message was sent by someone else, mark it
  /// delivered for the current user — even if that thread isn't open —
  /// so the sender's ticks advance without waiting for the recipient to
  /// open the chat. Deduped per conversation by `lastMessageAt`.
  Future<void> _markDeliveredForIncomingMessages(
    List<Conversation> conversations,
  ) async {
    final currentUserCode = (await storageService.getString(
      StorageKeys.userCode,
    ))?.trim();
    if (currentUserCode == null || currentUserCode.isEmpty) return;

    for (final conversation in conversations) {
      final sender = conversation.lastMessageBy;
      final at = conversation.lastMessageAt;
      if (sender == null || sender == currentUserCode || at == null) continue;
      if (_deliveredMarkedAt[conversation.code] == at) continue;
      _deliveredMarkedAt[conversation.code] = at;
      unawaited(markConversationDeliveredUseCase(conversation.code));
    }
  }

  /// Debounce wrapper for [_applyReliableUnreadCounts] — see
  /// [_unreadCountsDebounce]'s doc comment.
  void _scheduleReliableUnreadCounts(String? type) {
    _unreadCountsDebounce[type]?.cancel();
    _unreadCountsDebounce[type] = Timer(const Duration(milliseconds: 700), () {
      unawaited(_applyReliableUnreadCounts(type));
    });
  }

  /// Fetches the confirmed-reliable per-conversation unread counts (see
  /// [CommunicationRepositoryImpl._resolveUnreadCounts]'s doc comment for
  /// how it was verified) and overrides them onto whatever's currently
  /// shown for [type]. Scheduled (debounced) after every Firestore
  /// snapshot, since Firestore's own embedded unreadCount has been
  /// observed to drop incorrectly for conversations other than the one
  /// just read.
  Future<void> _applyReliableUnreadCounts(String? type) async {
    final result = await getUnreadCountsPerConversationUseCase();
    if (isClosed) return;
    result.fold((_) {}, (counts) {
      if (counts.isEmpty) return;
      final current = state;
      if (current is! CommunicationConversationsLoaded) return;
      final existing = current.conversationsByType[type];
      if (existing == null || existing.isEmpty) return;
      final updated = existing.map((c) {
        final count = counts[c.code];
        if (count == null || count == c.unreadCount) return c;
        return c.copyWith(unreadCount: count);
      }).toList();
      final updatedMap = Map<String?, List<Conversation>>.from(
        current.conversationsByType,
      )..[type] = updated;
      emit(current.copyWith(conversationsByType: updatedMap));
    });
  }

  @override
  Future<void> close() {
    _messagesSubscription?.cancel();
    for (final sub in _conversationsSubscriptions.values) {
      sub.cancel();
    }
    _conversationsSubscriptions.clear();
    for (final timer in _unreadCountsDebounce.values) {
      timer.cancel();
    }
    _unreadCountsDebounce.clear();
    return super.close();
  }

  /// Clears Isar cache for a specific thread's messages.
  Future<void> clearThreadCache(String threadId) async {
    await clearMessagesCacheUseCase(threadId);
  }

  /// Clears the full Isar conversations cache then reloads from API.
  Future<void> refreshConversations({
    String? type,
    String status = 'ACTIVE',
    int page = 0,
    int size = 20,
  }) async {
    await clearConversationsCacheUseCase();
    await loadConversations(type: type, status: status, page: page, size: size);
    // The top app bar's bell badge (UnreadBadgeCubit) is a separate app-wide
    // singleton with its own Firestore stream, not touched by the above — a
    // pull-to-refresh here could otherwise leave it visibly stale. Its own
    // REST-vs-Firestore guard already protects against this clobbering a
    // live count, so this is safe to call unconditionally.
    unawaited(serviceLocator<UnreadBadgeCubit>().loadUnreadCounts());
  }

  Future<void> loadConversations({
    String? type,
    String status = 'ACTIVE',
    int page = 0,
    int size = 20,
  }) async {
    // 1. Try Loading from cache first for better UX
    if (page == 0) {
      final cacheResult = await getCachedConversationsUseCase();
      cacheResult.fold(
        (_) => null, // Ignore cache errors
        (conversations) {
          if (conversations.isNotEmpty && !isClosed) {
            // Merge into existing map so both tabs keep their own data.
            final currentMap = state is CommunicationConversationsLoaded
                ? (state as CommunicationConversationsLoaded)
                      .conversationsByType
                : <String?, List<Conversation>>{};
            final mergedMap = Map<String?, List<Conversation>>.from(currentMap);
            mergedMap[null] = conversations;
            if (type != null) mergedMap[type] = conversations;
            emit(CommunicationConversationsLoaded(mergedMap));
          }
        },
      );
    }

    // 2. Only show loading if we don't have cached data (or if not on first page)
    if (state is! CommunicationConversationsLoaded) {
      emit(CommunicationConversationsLoading());
    }

    // 3. Fetch fresh data from remote
    final result = await getConversationsUseCase(
      type: type,
      status: status,
      page: page,
      size: size,
    );
    if (isClosed) return;

    result.fold(
      (failure) {
        // If we already have cached data, don't show full error screen, maybe just a toast?
        // For now, let's stick to the failure if cache is empty.
        if (state is! CommunicationConversationsLoaded) {
          emit(CommunicationError(failure.message ?? 'Unknown error'));
        }
      },
      (conversationsPage) {
        final prior = state is CommunicationConversationsLoaded
            ? state as CommunicationConversationsLoaded
            : null;
        final currentMap =
            prior?.conversationsByType ?? <String?, List<Conversation>>{};

        final updatedMap = Map<String?, List<Conversation>>.from(currentMap);
        final sorted = List<Conversation>.from(conversationsPage.items)
          ..sort((a, b) {
            final aTime = a.lastMessageAt ?? a.updatedAt;
            final bTime = b.lastMessageAt ?? b.updatedAt;
            return bTime.compareTo(aTime);
          });
        updatedMap[type] = sorted;

        final updatedPages = Map<String?, int>.from(
          prior?.currentPageByType ?? {},
        )..[type] = conversationsPage.page;
        final updatedHasMore = Map<String?, bool>.from(
          prior?.hasMoreByType ?? {},
        )..[type] = conversationsPage.hasMore;

        emit(
          CommunicationConversationsLoaded(
            updatedMap,
            currentPageByType: updatedPages,
            hasMoreByType: updatedHasMore,
            isLoadingMoreByType: prior?.isLoadingMoreByType ?? const {},
          ),
        );
      },
    );
  }

  /// Fetches the next page for [type] and appends it to the existing list —
  /// called when the conversation list scrolls near its end, so the full
  /// list loads progressively instead of being capped at whatever the
  /// first fixed-size fetch returned.
  Future<void> loadMoreConversations({
    String? type,
    String status = 'ACTIVE',
    int size = 20,
  }) async {
    final current = state;
    if (current is! CommunicationConversationsLoaded) return;
    if (!current.getHasMore(type) || current.getIsLoadingMore(type)) return;

    final nextPage = current.getCurrentPage(type) + 1;
    emit(
      current.copyWith(
        isLoadingMoreByType: Map<String?, bool>.from(
          current.isLoadingMoreByType,
        )..[type] = true,
      ),
    );

    final result = await getConversationsUseCase(
      type: type,
      status: status,
      page: nextPage,
      size: size,
    );
    if (isClosed) return;

    result.fold(
      (failure) {
        // Stop spinning, but keep `hasMore` as-is so a transient failure
        // doesn't permanently cut off pagination — the next scroll retries.
        if (state is CommunicationConversationsLoaded) {
          final s = state as CommunicationConversationsLoaded;
          emit(
            s.copyWith(
              isLoadingMoreByType: Map<String?, bool>.from(
                s.isLoadingMoreByType,
              )..[type] = false,
            ),
          );
        }
      },
      (conversationsPage) {
        if (state is! CommunicationConversationsLoaded) return;
        final s = state as CommunicationConversationsLoaded;

        final existing = List<Conversation>.from(
          s.conversationsByType[type] ?? const [],
        );
        final existingCodes = existing.map((c) => c.code).toSet();
        // Dedupe — a conversation that received a new message between the
        // first page load and this one can otherwise show up twice.
        final appended = conversationsPage.items.where(
          (c) => !existingCodes.contains(c.code),
        );
        existing.addAll(appended);
        existing.sort((a, b) {
          final aTime = a.lastMessageAt ?? a.updatedAt;
          final bTime = b.lastMessageAt ?? b.updatedAt;
          return bTime.compareTo(aTime);
        });

        final updatedMap = Map<String?, List<Conversation>>.from(
          s.conversationsByType,
        )..[type] = existing;
        final updatedPages = Map<String?, int>.from(s.currentPageByType)
          ..[type] = conversationsPage.page;
        final updatedHasMore = Map<String?, bool>.from(s.hasMoreByType)
          ..[type] = conversationsPage.hasMore;
        final updatedLoadingMore = Map<String?, bool>.from(
          s.isLoadingMoreByType,
        )..[type] = false;

        emit(
          CommunicationConversationsLoaded(
            updatedMap,
            currentPageByType: updatedPages,
            hasMoreByType: updatedHasMore,
            isLoadingMoreByType: updatedLoadingMore,
          ),
        );
      },
    );
  }

  /// Sorts messages oldest-first so the ListView (reverse: false) shows the
  /// latest message at the bottom, matching standard chat UX.
  List<Message> _sortByTime(List<Message> messages) {
    final sorted = List<Message>.from(messages);
    sorted.sort((a, b) => a.time.compareTo(b.time));
    return sorted;
  }

  /// A refresh (pull-to-refresh, lifecycle resume, this thread's own
  /// [loadMessages] re-running) must never interrupt or visually roll back a
  /// send that's still in flight — [sendMessage]'s upload can take several
  /// seconds, easily long enough for a refresh to land mid-way. [fresh] is
  /// whatever a cache or remote fetch just returned (which only knows about
  /// confirmed/cached messages); this adds back any message CURRENTLY held
  /// in memory for [threadId] that's still [Message.isSending] or
  /// [Message.isFailed] and isn't represented in [fresh] yet, so the
  /// in-progress bubble (and its local attachment preview) keeps showing
  /// uninterrupted through the refresh instead of flickering out and back.
  List<Message> _preserveInFlightSend(String threadId, List<Message> fresh) {
    final inMemory = state is CommunicationLoaded
        ? (state as CommunicationLoaded).threads[threadId] ?? const []
        : const <Message>[];
    final freshCodes = fresh.map((m) => m.code).toSet();
    final stillInFlight = inMemory.where(
      (m) => (m.isSending || m.isFailed) && !freshCodes.contains(m.code),
    );
    return _sortByTime([...fresh, ...stillInFlight]);
  }

  Future<void> loadMessages(String threadId, {String? currentUserId}) async {
    // A fresh bootstrap/refresh of the latest window — whatever older-history
    // pagination progress existed before is no longer valid.
    _olderPageByThread[threadId] = 1;

    final Map<String, List<Message>> currentThreads =
        state is CommunicationLoaded
        ? (state as CommunicationLoaded).threads
        : {};

    // 1. Try Loading from Isar cache first for faster initial loading.
    //    Pass currentUserId so isSentByMe is re-derived from senderUserCode,
    //    preventing stale/null Isar booleans from flipping the bubble style.
    final cacheResult = await getCachedMessagesUseCase(
      threadId,
      currentUserId: currentUserId,
    );
    // Local-only drafts (still uploading/sending, or failed) — the API
    // response in step 3 below only knows about server-confirmed messages,
    // so without holding onto these separately and re-merging them back in,
    // an in-flight/failed send present in the cache gets wiped the instant
    // the remote fetch's result replaces the thread's message list.
    List<Message> cachedDrafts = const [];
    cacheResult.fold(
      (_) => null, // Ignore cache errors
      (cachedMessages) {
        cachedDrafts =
            cachedMessages.where((m) => m.isSending || m.isFailed).toList();
        AppLogger.i(
          '[DRAFT SEED] loadMessages threadId=$threadId — '
          'cachedTotal=${cachedMessages.length}, drafts=${cachedDrafts.length}, '
          'draftIds=${cachedDrafts.map((m) => m.id).toList()}',
        );
        if (cachedMessages.isNotEmpty && !isClosed) {
          final newThreads = Map<String, List<Message>>.from(currentThreads);
          // Merge, don't overwrite: a send that started just before this
          // refresh may not have landed its draft write to Isar yet — the
          // in-memory version (see _preserveInFlightSend) is still the most
          // current one for that narrow window.
          newThreads[threadId] = _preserveInFlightSend(threadId, cachedMessages);
          emit(
            CommunicationLoaded(threads: newThreads, activeThreadId: threadId),
          );
        }
      },
    );

    // 2. Only emit Loading if we have absolutely no cached messages in the state
    final Map<String, List<Message>> updatedThreads =
        state is CommunicationLoaded
        ? (state as CommunicationLoaded).threads
        : {};
    if (!updatedThreads.containsKey(threadId) ||
        updatedThreads[threadId]!.isEmpty) {
      emit(CommunicationLoading());
    }

    // 3. Fetch latest data from remote in the background and update state/cache
    final result = await getMessagesUseCase(
      threadId,
      currentUserId: currentUserId,
    );
    if (isClosed) return;

    result.fold(
      (failure) {
        // CommunicationLoaded.threads holds every thread's messages, not
        // just this one — emitting CommunicationError here used to replace
        // that entire map, which silently broke sendMessage() (guarded on
        // `state is CommunicationLoaded`) for every other already-loaded
        // thread too, not just the one that failed to fetch. If we already
        // have a loaded session, keep it: just make sure this thread has at
        // least an empty entry so its own UI can render an empty/retry
        // state locally instead of nuking everyone else's state.
        if (state is CommunicationLoaded) {
          final loaded = state as CommunicationLoaded;
          if (!loaded.threads.containsKey(threadId)) {
            final threads = Map<String, List<Message>>.from(loaded.threads);
            threads[threadId] = const [];
            emit(loaded.copyWith(threads: threads, activeThreadId: threadId));
          }
          return;
        }
        emit(CommunicationError(failure.message ?? 'Unknown error'));
      },
      (messages) {
        final Map<String, List<Message>> latestThreads =
            state is CommunicationLoaded
            ? (state as CommunicationLoaded).threads
            : {};
        final newThreads = Map<String, List<Message>>.from(latestThreads);
        final freshCodes = messages.map((m) => m.code).toSet();
        final unconfirmedDrafts = cachedDrafts
            .where((d) => !freshCodes.contains(d.code))
            .toList();
        AppLogger.i(
          '[DRAFT SEED] loadMessages threadId=$threadId — '
          'remoteCount=${messages.length}, unconfirmedDraftsMerged=${unconfirmedDrafts.length}',
        );
        // Merge in the Isar-known drafts, then also re-check against
        // whatever's CURRENTLY in memory (see _preserveInFlightSend) — a
        // send that made progress (or even fully completed) while this
        // remote fetch was in flight is the most up-to-date source, and
        // must win over this now-slightly-stale API response.
        final withCachedDrafts = [...messages, ...unconfirmedDrafts];
        final sortedMessages = _preserveInFlightSend(threadId, withCachedDrafts);
        newThreads[threadId] = sortedMessages;
        emit(
          CommunicationLoaded(threads: newThreads, activeThreadId: threadId),
        );
      },
    );
  }

  /// Fetches the next older page of [threadId]'s history and prepends it to
  /// whatever's already loaded — called when the user scrolls near the top
  /// of the message list. No-ops while a fetch is already in flight or once
  /// the thread is known to have no older history left.
  ///
  /// UNVERIFIED ASSUMPTION — confirm with backend before relying on this in
  /// production: this assumes `page=0&size=100&sort=createdAt,asc` (the
  /// existing [loadMessages] call) returns the *latest* window, so `page=1,
  /// 2, …` here walk further back in time. The sibling v2 entity endpoint
  /// (MessageEntityRemoteDataSourceImpl.getMessages) instead always uses
  /// `page=0&sort=createdAt,desc` plus a `beforeMessageCode` cursor — if the
  /// v1 endpoint's `asc` actually means page 0 is the *oldest* window (as
  /// the literal query string suggests), this page-number scheme fetches the
  /// wrong direction and should be replaced with the same cursor approach.
  Future<void> loadOlderMessages(
    String threadId, {
    String? currentUserId,
  }) async {
    if (state is! CommunicationLoaded) return;
    final currentState = state as CommunicationLoaded;
    if (currentState.threadsLoadingOlder.contains(threadId)) return;
    if (currentState.threadsWithNoMoreHistory.contains(threadId)) return;

    final page = _olderPageByThread[threadId] ?? 1;
    emit(
      currentState.copyWith(
        threadsLoadingOlder: {...currentState.threadsLoadingOlder, threadId},
      ),
    );

    final result = await getMessagesUseCase(
      threadId,
      currentUserId: currentUserId,
      page: page,
      size: _olderPageSize,
    );
    if (isClosed) return;
    if (state is! CommunicationLoaded) return;
    final latestState = state as CommunicationLoaded;

    result.fold(
      (failure) {
        AppLogger.e(
          '[Pagination] loadOlderMessages($threadId, page=$page) failed: ${failure.message}',
        );
        emit(
          latestState.copyWith(
            threadsLoadingOlder: {...latestState.threadsLoadingOlder}
              ..remove(threadId),
          ),
        );
      },
      (olderMessages) {
        _olderPageByThread[threadId] = page + 1;

        final existing = latestState.threads[threadId] ?? const <Message>[];
        final existingCodes = existing.map((m) => m.code).toSet();
        // The realtime/Isar layers could already have pulled in some of
        // these by code — only add ones we don't already have so a message
        // is never duplicated in the list.
        final newOnes = olderMessages.where(
          (m) => !existingCodes.contains(m.code),
        );

        final mergedThreads = Map<String, List<Message>>.from(
          latestState.threads,
        );
        mergedThreads[threadId] = _sortByTime([...existing, ...newOnes]);

        final loadingOlder = {...latestState.threadsLoadingOlder}
          ..remove(threadId);
        final noMoreHistory = {...latestState.threadsWithNoMoreHistory};
        if (olderMessages.length < _olderPageSize) {
          noMoreHistory.add(threadId);
        }

        emit(
          latestState.copyWith(
            threads: mergedThreads,
            threadsLoadingOlder: loadingOlder,
            threadsWithNoMoreHistory: noMoreHistory,
          ),
        );
      },
    );
  }

  Future<void> sendMessage(
    String threadId,
    String text, {
    List<ChatAttachment> attachments = const [],
    String? quotedMessageId,
    String? senderName,
    String? senderUserCode,
    List<String> receivers = const [],
    bool isPrivate = false,
    String? privateParentUserCode,
  }) async {
    // Previously this guarded with `if (state is! CommunicationLoaded) return`
    // and silently dropped the send — no API call, no error, nothing — any
    // time the cubit's *global* state wasn't CommunicationLoaded. Since the
    // cubit holds one shared state across every thread, a failed background
    // fetch for ANY thread (most commonly a brand-new conversation with no
    // messages yet, e.g. a parent sending the very first message) could leave
    // the whole cubit stuck in CommunicationError, breaking Send everywhere
    // until something else happened to re-emit CommunicationLoaded. Falling
    // back to an empty CommunicationLoaded here means Send always at least
    // attempts the API call, which is also what a parent-initiated
    // first-message flow requires (the conversation doesn't exist locally
    // yet, but the send must still go through and create it).
    final currentState = state is CommunicationLoaded
        ? state as CommunicationLoaded
        : CommunicationLoaded(threads: const {}, activeThreadId: threadId);

    // Copy picked files out of the OS's ephemeral temp dir into permanent
    // app storage before anything else — same reasoning as the v2 stack's
    // ConversationThreadCubit.sendMessage: the local preview must survive
    // navigating away or the app backgrounding mid-upload, neither of which
    // a temp-dir path can promise.
    attachments = await PendingAttachmentStorage.persistLocally(attachments);

    // id/code must be unique per message, not per thread/sender — reusing
    // threadId/senderUserCode meant two messages sent in quick succession
    // (before either round-trips) collided: same ValueKey in the list, same
    // lookup key for reactions/edit/delete, and the "latest message id"
    // change-detection used for auto-scroll couldn't tell them apart.
    final tempId = 'temp-${_uuid.v4()}';
    final tempMessage = Message(
      id: tempId,
      code: tempId,
      text: text,
      isSentByMe: true,
      senderUserCode: senderUserCode,
      time: SchoolZoneDateTime.utcNowInSchool(
        SchoolTimezoneResolver.lastKnownTimeZone,
      ),
      attachments: attachments,
      quotedMessageId: quotedMessageId,
      senderName: senderName,
      receivers: receivers,
      isPrivate: isPrivate,
      privateParentUserCode: privateParentUserCode,
      isSending: true,
    );

    // Optimistic update — append then re-sort so the new bubble lands at bottom
    final updatedThreads = Map<String, List<Message>>.from(
      currentState.threads,
    );
    updatedThreads[threadId] = _sortByTime(
      List<Message>.from(updatedThreads[threadId] ?? [])..add(tempMessage),
    );

    emit(
      CommunicationSending(threads: updatedThreads, activeThreadId: threadId),
    );
    // Persist right away too — before upload starts — so navigating away,
    // the thread's cubit being recreated (every reopen creates a fresh
    // CommunicationCubit — see _openThread), or the app being killed still
    // leaves something to resume/retry from, with its local attachment
    // previews, instead of the whole draft vanishing outright.
    final draftCacheResult = await cacheMessageUseCase(threadId, tempMessage);
    draftCacheResult.fold(
      (f) => AppLogger.e(
        '[DRAFT CACHE] FAILED TO CACHE — threadId=$threadId, tempId=$tempId: ${f.message}',
      ),
      (_) => AppLogger.i(
        '[DRAFT CACHE] CACHED — threadId=$threadId, tempId=$tempId, '
        'attachments=${tempMessage.attachments.length}, '
        'localPaths=${tempMessage.attachments.map((a) => a.localPath).toList()}',
      ),
    );

    // Upload any attachments that are still local-only before sending —
    // blocks until every attachment has a real delivery URL (see
    // ChatAttachmentUploader.uploadAll); the backend must never receive
    // (or the recipient ever see) a message whose attachment isn't ready
    // yet. On failure the optimistic bubble is kept and marked failed
    // (not rolled back/removed) so [retrySendMessage] has something to
    // retry from instead of the picked files silently vanishing.
    List<ChatAttachment> uploadedAttachments = attachments;
    if (attachments.any((a) => !a.isUploaded)) {
      try {
        uploadedAttachments = await attachmentUploader.uploadAll(
          conversationCode: threadId,
          attachments: attachments,
        );
      } catch (e) {
        if (isClosed) return;
        await _emitSendFailure(
          threadId: threadId,
          failedMessage: tempMessage,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
        );
        return;
      }
    }
    final messageToSend = tempMessage.copyWith(
      attachments: uploadedAttachments,
      isSending: true,
    );

    final result = await sendMessageUseCase(threadId, messageToSend);
    if (isClosed) return;

    await result.fold(
      (failure) => _emitSendFailure(
        threadId: threadId,
        failedMessage: messageToSend,
        errorMessage: failure.message ?? 'Unknown error',
      ),
      (sentMessage) async {
        // Update state with confirmed message — merged onto whatever is
        // CURRENT right now (see _latestLoadedState), not a pre-upload
        // snapshot, so nothing Firestore delivered during the upload wait
        // gets rolled back.
        final latestState = _latestLoadedState(threadId);
        final confirmedThreads = Map<String, List<Message>>.from(
          latestState.threads,
        );
        final threadMessages = List<Message>.from(
          confirmedThreads[threadId] ?? [],
        );
        final idx = threadMessages.indexWhere((m) => m.id == tempMessage.id);
        if (idx != -1) {
          threadMessages[idx] = sentMessage;
        } else {
          threadMessages.add(sentMessage);
        }
        confirmedThreads[threadId] = _sortByTime(threadMessages);

        emit(
          latestState.copyWith(
            threads: confirmedThreads,
            activeThreadId: threadId,
          ),
        );
      },
    );
  }

  /// Base state to merge a completed send's result onto — always the
  /// cubit's CURRENT state, never a snapshot captured back when the send
  /// started. Attachment uploads now block for several seconds (S3 PUT +
  /// register + wait-until-ready), which is plenty of time for
  /// [startWatchingThread]'s Firestore listener to merge in unrelated
  /// updates (another message, a reaction, a receipt). Building the final
  /// emission from a stale pre-upload snapshot instead of this would
  /// silently discard whatever arrived in that window the instant the send
  /// finishes — the message would flash in from the optimistic emit, then
  /// appear to vanish a few seconds later when the stale snapshot rolls
  /// the thread back.
  CommunicationLoaded _latestLoadedState(String threadId) {
    return state is CommunicationLoaded
        ? state as CommunicationLoaded
        : CommunicationLoaded(threads: const {}, activeThreadId: threadId);
  }

  /// Marks [failedMessage] failed in place within the thread's current
  /// message list, rather than rolling the send back and discarding the
  /// bubble outright — the discarded bubble was the actual cause of "no
  /// retry option" for every legacy (STAFF_DIRECT / Parent) thread: there
  /// was nothing left in state for a retry affordance to attach to. Still
  /// emits [CommunicationError] momentarily first so whatever BlocListener
  /// shows the error toast fires.
  Future<void> _emitSendFailure({
    required String threadId,
    required Message failedMessage,
    required String errorMessage,
  }) async {
    final latestState = _latestLoadedState(threadId);
    final failedThreads = Map<String, List<Message>>.from(latestState.threads);
    final threadMessages = List<Message>.from(failedThreads[threadId] ?? []);
    final idx = threadMessages.indexWhere((m) => m.id == failedMessage.id);
    final failed = failedMessage.copyWith(isFailed: true, isSending: false);
    if (idx != -1) {
      threadMessages[idx] = failed;
    } else {
      threadMessages.add(failed);
    }
    failedThreads[threadId] = threadMessages;
    emit(CommunicationError(errorMessage));
    emit(latestState.copyWith(threads: failedThreads, activeThreadId: threadId));
    // Persist the failed state too — otherwise a failed-but-not-retried
    // draft (attachments un-uploaded, message never confirmed) reverts to
    // whatever was cached by the last successful `sendMessage` write (i.e.
    // just disappears) the next time this thread's cubit is recreated.
    await cacheMessageUseCase(threadId, failed);
  }

  /// Retries a message that failed to send — re-runs the same
  /// upload-then-send pipeline, reusing [message]'s own id so the existing
  /// failed bubble is replaced in place rather than adding a new one.
  /// [ChatAttachmentUploader.uploadAll]'s own classification (ready /
  /// registered-but-unresolved / needs full upload) skips whatever already
  /// finished on the previous attempt.
  Future<void> retrySendMessage(String threadId, Message message) async {
    final currentState = state is CommunicationLoaded
        ? state as CommunicationLoaded
        : CommunicationLoaded(threads: const {}, activeThreadId: threadId);

    final retrying = message.copyWith(isFailed: false, isSending: true);
    final retryingThreads = Map<String, List<Message>>.from(
      currentState.threads,
    );
    final threadMessages = List<Message>.from(
      retryingThreads[threadId] ?? [],
    );
    final idx = threadMessages.indexWhere((m) => m.id == message.id);
    if (idx != -1) {
      threadMessages[idx] = retrying;
    } else {
      threadMessages.add(retrying);
    }
    retryingThreads[threadId] = threadMessages;

    emit(
      CommunicationSending(
        threads: retryingThreads,
        activeThreadId: threadId,
      ),
    );
    await cacheMessageUseCase(threadId, retrying);

    List<ChatAttachment> uploadedAttachments = retrying.attachments;
    if (retrying.attachments.any((a) => !a.isUploaded)) {
      try {
        uploadedAttachments = await attachmentUploader.uploadAll(
          conversationCode: threadId,
          attachments: retrying.attachments,
        );
      } catch (e) {
        if (isClosed) return;
        await _emitSendFailure(
          threadId: threadId,
          failedMessage: retrying,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
        );
        return;
      }
    }

    final messageToSend = retrying.copyWith(attachments: uploadedAttachments);
    final result = await sendMessageUseCase(threadId, messageToSend);
    if (isClosed) return;

    await result.fold(
      (failure) => _emitSendFailure(
        threadId: threadId,
        failedMessage: messageToSend,
        errorMessage: failure.message ?? 'Unknown error',
      ),
      (sentMessage) async {
        // Merge onto the CURRENT state, not the pre-upload `retryingThreads`
        // snapshot — see _latestLoadedState.
        final latestState = _latestLoadedState(threadId);
        final confirmedThreads = Map<String, List<Message>>.from(
          latestState.threads,
        );
        final msgs = List<Message>.from(confirmedThreads[threadId] ?? []);
        final confirmedIdx = msgs.indexWhere((m) => m.id == message.id);
        if (confirmedIdx != -1) {
          msgs[confirmedIdx] = sentMessage;
        } else {
          msgs.add(sentMessage);
        }
        confirmedThreads[threadId] = _sortByTime(msgs);
        emit(
          latestState.copyWith(
            threads: confirmedThreads,
            activeThreadId: threadId,
          ),
        );
      },
    );
  }

  Future<void> addReaction(
    String threadId,
    String messageCode,
    String emoji, {
    String? currentUserCode,
  }) async {
    if (state is! CommunicationLoaded) return;
    final currentState = state as CommunicationLoaded;
    final originalThreads = currentState.threads;
    final reactionKey = currentUserCode ?? 'me';

    // Optimistically update the UI
    final updatedThreads = Map<String, List<Message>>.from(
      currentState.threads,
    );
    final threadMessages = List<Message>.from(updatedThreads[threadId] ?? []);

    final updatedMessages = threadMessages.map((m) {
      if (m.code == messageCode) {
        // Append this (user, emoji) only if not already present — a user may
        // hold multiple distinct emojis; adding one must not drop the others.
        final newReactions = m.userHasReaction(reactionKey, emoji)
            ? m.reactions
            : [
                ...m.reactions,
                ReactionEntry(userCode: reactionKey, emoji: emoji),
              ];
        return Message(
          id: m.id,
          code: m.code,
          text: m.text,
          isSentByMe: m.isSentByMe,
          time: m.time,
          deliveredAt: m.deliveredAt,
          readAt: m.readAt,
          editedAt: m.editedAt,
          deliveredTo: m.deliveredTo,
          readBy: m.readBy,
          reactions: newReactions,
          quotedMessageId: m.quotedMessageId,
          attachments: m.attachments,
          senderName: m.senderName,
          senderUserCode: m.senderUserCode,
          receivers: m.receivers,
          // Preserve private-mode metadata across optimistic rebuilds —
          // dropping these made a private message lose isPrivate on
          // react/edit and jump into the Group tab.
          isPrivate: m.isPrivate,
          privateParentUserCode: m.privateParentUserCode,
        );
      }
      return m;
    }).toList();

    updatedThreads[threadId] = updatedMessages;
    emit(currentState.copyWith(threads: updatedThreads));
    _markRecentlyMutated(messageCode);

    final result = await addReactionUseCase(threadId, messageCode, emoji);
    if (isClosed) return;

    result.fold((failure) {
      emit(currentState.copyWith(threads: originalThreads));
    }, (_) {});
  }

  Future<void> editMessage(
    String threadId,
    String messageCode,
    String content,
  ) async {
    if (state is! CommunicationLoaded) return;
    final currentState = state as CommunicationLoaded;
    final originalThreads = currentState.threads;

    // Optimistically update the UI
    final updatedThreads = Map<String, List<Message>>.from(
      currentState.threads,
    );
    final threadMessages = List<Message>.from(updatedThreads[threadId] ?? []);

    final updatedMessages = threadMessages.map((m) {
      if (m.code == messageCode) {
        return Message(
          id: m.id,
          code: m.code,
          text: content,
          isSentByMe: m.isSentByMe,
          time: m.time,
          deliveredAt: m.deliveredAt,
          readAt: m.readAt,
          editedAt: SchoolZoneDateTime.utcNowInSchool(
            SchoolTimezoneResolver.lastKnownTimeZone,
          ),
          deliveredTo: m.deliveredTo,
          readBy: m.readBy,
          reactions: m.reactions,
          quotedMessageId: m.quotedMessageId,
          attachments: m.attachments,
          senderName: m.senderName,
          senderUserCode: m.senderUserCode,
          receivers: m.receivers,
          // Preserve private-mode metadata across optimistic rebuilds —
          // dropping these made a private message lose isPrivate on
          // react/edit and jump into the Group tab.
          isPrivate: m.isPrivate,
          privateParentUserCode: m.privateParentUserCode,
        );
      }
      return m;
    }).toList();

    updatedThreads[threadId] = updatedMessages;
    emit(currentState.copyWith(threads: updatedThreads));
    _markRecentlyMutated(messageCode);

    final result = await editMessageUseCase(messageCode, content);
    if (isClosed) return;

    result.fold((failure) {
      emit(currentState.copyWith(threads: originalThreads));
    }, (_) {});
  }

  /// Deletes a message. Returns `null` on success, or the [Failure] when the
  /// server rejects it (e.g. the delete window has passed) so the UI can show
  /// the reason instead of a false "deleted" acknowledgement.
  Future<Failure?> deleteMessage(String threadId, String messageCode) async {
    if (state is! CommunicationLoaded) return null;
    final currentState = state as CommunicationLoaded;
    final originalThreads = currentState.threads;

    // Optimistically mark as deleted — MessageBubble renders the proper
    // "This message has been deleted." placeholder (and hides text,
    // attachments, reactions) whenever `isDeleted` (derived from
    // `deletedAt`) is true, so the model itself stays untouched. This also
    // matches what a reload of the conversation will show, since the
    // backend's own `deletedAt` is what drives `MessageModel.fromJson`.
    final updatedThreads = Map<String, List<Message>>.from(
      currentState.threads,
    );
    final threadMessages = List<Message>.from(updatedThreads[threadId] ?? []);

    final deletedAt = SchoolZoneDateTime.utcNowInSchool(
      SchoolTimezoneResolver.lastKnownTimeZone,
    );
    final updatedMessages = threadMessages.map((m) {
      if (m.code == messageCode) {
        return m.copyWith(deletedAt: deletedAt);
      }
      return m;
    }).toList();

    updatedThreads[threadId] = updatedMessages;
    emit(currentState.copyWith(threads: updatedThreads));
    _markRecentlyMutated(messageCode);

    final result = await deleteMessageUseCase(messageCode);
    if (isClosed) return null;

    return result.fold((failure) {
      emit(currentState.copyWith(threads: originalThreads));
      return failure;
    }, (_) => null);
  }

  /// Removes a single attachment from its message without deleting the
  /// whole message — [attachmentId] is the messaging-service id assigned
  /// when the attachment was registered (see ChatAttachmentUploader), not
  /// the document-service asset code.
  Future<void> deleteAttachment(String threadId, int attachmentId) async {
    if (state is! CommunicationLoaded) return;
    final currentState = state as CommunicationLoaded;
    final originalThreads = currentState.threads;

    final updatedThreads = Map<String, List<Message>>.from(
      currentState.threads,
    );
    final threadMessages = List<Message>.from(updatedThreads[threadId] ?? []);

    String? owningMessageCode;
    final updatedMessages = threadMessages.map((m) {
      if (!m.attachments.any((a) => a.attachmentId == attachmentId)) {
        return m;
      }
      owningMessageCode = m.code;
      return m.copyWith(
        attachments: m.attachments
            .where((a) => a.attachmentId != attachmentId)
            .toList(),
      );
    }).toList();

    updatedThreads[threadId] = updatedMessages;
    emit(currentState.copyWith(threads: updatedThreads));
    if (owningMessageCode != null) _markRecentlyMutated(owningMessageCode!);

    final result = await deleteAttachmentUseCase(attachmentId);
    if (isClosed) return;

    result.fold((failure) {
      emit(currentState.copyWith(threads: originalThreads));
    }, (_) {});
  }

  Future<void> removeReaction(
    String threadId,
    String messageCode,
    String emoji, {
    String? currentUserCode,
  }) async {
    if (state is! CommunicationLoaded) return;
    final currentState = state as CommunicationLoaded;
    final originalThreads = currentState.threads;
    final reactionKey = currentUserCode ?? 'me';

    // Optimistically remove reaction from UI
    final updatedThreads = Map<String, List<Message>>.from(
      currentState.threads,
    );
    final threadMessages = List<Message>.from(updatedThreads[threadId] ?? []);

    final updatedMessages = threadMessages.map((m) {
      if (m.code == messageCode) {
        // Drop only the matching (user, emoji) entry — the user's other
        // emojis on this message stay put.
        final newReactions = m.reactions
            .where((r) => !(r.matchesUser(reactionKey) && r.emoji == emoji))
            .toList();
        return Message(
          id: m.id,
          code: m.code,
          text: m.text,
          isSentByMe: m.isSentByMe,
          time: m.time,
          deliveredAt: m.deliveredAt,
          readAt: m.readAt,
          editedAt: m.editedAt,
          deliveredTo: m.deliveredTo,
          readBy: m.readBy,
          reactions: newReactions,
          quotedMessageId: m.quotedMessageId,
          attachments: m.attachments,
          senderName: m.senderName,
          senderUserCode: m.senderUserCode,
          receivers: m.receivers,
          // Preserve private-mode metadata across optimistic rebuilds —
          // dropping these made a private message lose isPrivate on
          // react/edit and jump into the Group tab.
          isPrivate: m.isPrivate,
          privateParentUserCode: m.privateParentUserCode,
        );
      }
      return m;
    }).toList();

    updatedThreads[threadId] = updatedMessages;
    emit(currentState.copyWith(threads: updatedThreads));
    _markRecentlyMutated(messageCode);

    final result = await removeReactionLegacyUseCase(
      messageCode: messageCode,
      emoji: emoji,
    );
    if (isClosed) return;

    result.fold((failure) {
      emit(currentState.copyWith(threads: originalThreads));
    }, (_) {});
  }
}
