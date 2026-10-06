import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/attendance_classroom_scope.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_active_classrooms_usecase.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/usecases/get_cached_conversations_entity_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/get_conversations_entity_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/watch_conversations_usecase.dart';

part 'chat_preview_state.dart';

/// Owns the "recent chat" preview rows shown on the dashboard's My Day card.
///
/// **Why this exists (Mandate 2, §2.4).** All of this — the conversation list,
/// the loading flag, the classroom-name map, the current user code, the
/// primary-classroom pin — used to live in `_CommunicationRowWidgetState` and
/// be driven by nine `setState` calls across three concurrent data sources.
/// That is the "state that should never have been in a widget" case in its
/// purest form: it comes from an API (three of them), it survives parent
/// rebuilds, and it is read by more than one part of the row. Bucket A is "no
/// exceptions".
///
/// **Why it lives in the dashboard and not in communication.** The *data* is
/// communication-owned, but this is a dashboard-specific projection of it:
/// top-two-by-recency with the staff member's own classroom Notes pinned
/// first. `CommunicationCubit` models the full inbox and is provided only by
/// the parent dashboard's coordinator, whereas this card renders on the staff
/// and admin dashboards. Reusing it would mean adding it to two more
/// coordinators to get a projection neither needs.
///
/// The fetch pipeline is carried over unchanged, including its ordering
/// guarantees: seed from the Isar cache for a fast first frame, fall back to
/// REST concurrently in case Firestore is empty for this persona, and watch the
/// Firestore inbox in realtime — with an 8-second timeout that clears the
/// loading flag if none of them has answered.
class ChatPreviewCubit extends Cubit<ChatPreviewState> {
  ChatPreviewCubit({
    required StorageService storageService,
    required GetCachedConversationsEntityUseCase getCachedConversations,
    required GetConversationsEntityUseCase getConversations,
    required WatchConversationsUseCase watchConversations,
    required GetActiveClassroomsUseCase getActiveClassrooms,
  }) : _storage = storageService,
       _getCachedConversations = getCachedConversations,
       _getConversations = getConversations,
       _watchConversations = watchConversations,
       _getActiveClassrooms = getActiveClassrooms,
       super(const ChatPreviewState());

  final StorageService _storage;
  final GetCachedConversationsEntityUseCase _getCachedConversations;
  final GetConversationsEntityUseCase _getConversations;
  final WatchConversationsUseCase _watchConversations;
  final GetActiveClassroomsUseCase _getActiveClassrooms;

  StreamSubscription<List<ConversationEntity>>? _sub;
  Timer? _timeout;
  bool _started = false;
  bool _isGuardianViewer = false;

  /// Classroom codes a classroom-scoped staff viewer may see. Null means the
  /// viewer is not scoped. Until resolved, classroom-bound rooms are held back
  /// so a scoped staff member never briefly sees one outside their classes.
  Set<String>? _scopedClassroomCodes;
  bool _scopeResolved = false;
  final Map<String, ConversationEntity> _known = {};

  /// Idempotent: the card can be rebuilt without re-running the pipeline.
  ///
  /// [isGuardianViewer] — when the viewer is acting as a guardian, rooms where
  /// another guardian has private messaging enabled are kept off the preview
  /// (their last-message text and unread count would otherwise leak it).
  Future<void> load({bool isGuardianViewer = false}) async {
    if (_started) return;
    _started = true;
    _isGuardianViewer = isGuardianViewer;

    if (!isGuardianViewer) {
      unawaited(
        resolveScopedStaffClassroomCodes(storage: _storage)
            .then((codes) {
              if (isClosed) return;
              _scopedClassroomCodes = codes;
              _scopeResolved = true;
              _safeEmit(state.copyWith(items: _rank(const [])));
            })
            .catchError((_) {
              if (isClosed) return;
              _scopedClassroomCodes = <String>{};
              _scopeResolved = true;
              _safeEmit(state.copyWith(items: _rank(const [])));
            }),
      );
    } else {
      _scopeResolved = true;
    }

    final currentUserCode =
        (await _storage.getString(StorageKeys.userCode))?.trim() ?? '';
    _safeEmit(state.copyWith(currentUserCode: currentUserCode));

    // Fire-and-forget: don't block the fast cache-first-frame path below.
    // Re-applies the ranking once either resolves so already-loaded items get
    // retroactively re-ranked.
    unawaited(
      resolveStaffPrimaryClassroomCode(storage: _storage)
          .then((code) {
            if (isClosed) return;
            _safeEmit(
              state.copyWith(
                primaryClassroomCode: code,
                items: _rank(state.items, primaryClassroomCode: code),
              ),
            );
          })
          .catchError((_) {}),
    );

    unawaited(
      _storage.getString(StorageKeys.schoolCode).then((schoolCode) async {
        final trimmed = (schoolCode ?? '').trim();
        if (trimmed.isEmpty) return;
        try {
          final classrooms = await _getActiveClassrooms(
            schoolCode: trimmed,
            onlyTypeClassroom: false,
          );
          if (isClosed) return;
          _safeEmit(
            state.copyWith(
              classroomNames: <String, String>{
                ...state.classroomNames,
                for (final c in classrooms) c.code: c.name,
              },
            ),
          );
        } catch (_) {
          // Best-effort — the Notes row falls back to "Classroom".
        }
      }),
    );

    _timeout = Timer(const Duration(seconds: 8), () {
      _safeEmit(state.copyWith(isLoading: false));
    });

    try {
      final cached = await _getCachedConversations.call();
      cached.fold((_) {}, (list) {
        if (isClosed) return;
        _safeEmit(state.copyWith(items: _rank(list), isLoading: false));
      });
    } catch (_) {
      _safeEmit(state.copyWith(isLoading: false));
    }

    // Fallback to REST concurrently in case Firestore fails or is empty.
    // includeRestUnreadCounts: false — unread counts are Firestore-only
    // app-wide; these REST-sourced items would otherwise carry a stale/wrong
    // unreadCount that the merge (by most-recent timestamp, not by source)
    // could pick over the live Firestore value.
    unawaited(
      _getConversations.call(includeRestUnreadCounts: false).then((result) {
        if (isClosed) return;
        result.fold((_) {}, (list) {
          // If REST found chats, merge them with current items so nothing is
          // missed, and take the top two most recent.
          if (list.isNotEmpty) {
            _safeEmit(
              state.copyWith(
                items: _rank([...state.items, ...list]),
                isLoading: false,
              ),
            );
          }
        });
      }),
    );

    _sub = _watchConversations.call().listen(
      (list) {
        if (isClosed) return;
        _timeout?.cancel();
        // If Firestore returns items, use them (merged to preserve names if
        // needed). If it returns empty, only overwrite if we didn't get any
        // from REST/cache.
        _safeEmit(
          state.copyWith(
            items: list.isNotEmpty
                ? _rank([...state.items, ...list])
                : state.items,
            isLoading: false,
          ),
        );
      },
      onError: (_) {
        _timeout?.cancel();
        _safeEmit(state.copyWith(isLoading: false));
      },
      onDone: () {
        _timeout?.cancel();
        _safeEmit(state.copyWith(isLoading: false));
      },
    );
  }

  void _safeEmit(ChatPreviewState next) {
    if (!isClosed) emit(next);
  }

  // ---------------------------------------------------------------------------
  // Ranking — moved verbatim from the widget (§6.4: pure logic out of build())
  // ---------------------------------------------------------------------------

  /// Ranks a conversation by its own last MESSAGE, never `updatedAt`.
  ///
  /// `updatedAt` is a generic "last modified" stamp that background sync
  /// (unread-count reconciliation, participant/read-receipt updates, a
  /// Firestore re-sync of the per-user inbox) can bump with NO new message at
  /// all — using it as a recency fallback let a conversation nobody had
  /// actually messaged in briefly jump to the top the moment one of those
  /// unrelated fields ticked, then fall back once the next snapshot arrived.
  /// A conversation with no messages yet ranks as the oldest possible instant
  /// instead, so it can never out-rank one with real activity.
  static DateTime _rankTime(ConversationEntity c) =>
      c.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  /// True when the viewer must not see [c] on the dashboard. A guardian is kept
  /// out of rooms with private messaging on or a private last message; the list
  /// payload does not say which message is private, so the whole room is held.
  bool _hiddenFromViewer(ConversationEntity c) {
    if (_isGuardianViewer) {
      // The REST preview is the neutral placeholder whenever the room's last
      // message is private, and the per-parent flags can lag behind — so a
      // room with private messaging active, or showing that placeholder, is
      // held back from the guardian preview entirely.
      final preview = c.lastMessagePreview.trim().toLowerCase();
      return c.hasActivePrivateMode || preview == 'private message';
    }

    final classroomBound =
        c.type == ConversationType.roomChat ||
        c.type == ConversationType.classroomChat;
    if (!classroomBound) return false;
    if (!_scopeResolved) return true;

    final scope = _scopedClassroomCodes;
    if (scope == null) return false;
    final code = c.classroomCode?.trim() ?? '';
    return code.isEmpty || !scope.contains(code);
  }

  List<ConversationEntity> _rank(
    List<ConversationEntity> input, {
    String? primaryClassroomCode,
  }) {
    // Every conversation ever seen is kept, so a room hidden while the viewer's
    // scope was still loading comes back once that scope resolves.
    for (final c in input) {
      final code = c.code.trim();
      if (code.isEmpty) continue;
      final known = _known[code];
      if (known == null || !_rankTime(c).isBefore(_rankTime(known))) {
        // REST copies carry unreadCount 0 (Firestore is the only source of
        // unread counts), so never let one blank a live count on a tie.
        _known[code] =
            (known != null &&
                c.unreadCount == 0 &&
                known.unreadCount > 0 &&
                _rankTime(c) == _rankTime(known))
            ? c.copyWith(unreadCount: known.unreadCount)
            : c;
      }
    }
    final list = _known.values.where((c) => !_hiddenFromViewer(c)).toList();
    // Callers pass `[...items, ...freshSnapshot]` — the OLD top-2 selection
    // first, the fresh cache/REST/Firestore data second. Cache, REST and the
    // live watch all resolve independently and can arrive in ANY order (a slow
    // REST fallback can land after Firestore already delivered a newer
    // snapshot), so dedup can't trust arrival position either way: "keep the
    // first copy seen" freezes a conversation at whatever it was when it first
    // entered the list; "keep the last copy seen" is just as wrong the moment a
    // stale response resolves AFTER a fresher one. Compare each duplicate's own
    // timestamp instead and keep whichever is actually more recent — the only
    // ordering that can't be defeated by network/cache timing.
    final byCode = <String, ConversationEntity>{};
    for (final item in list) {
      final code = item.code.trim();
      if (code.isEmpty) continue;
      final existing = byCode[code];
      if (existing == null || !_rankTime(item).isBefore(_rankTime(existing))) {
        byCode[code] = item;
      }
    }
    final unique = byCode.values.toList()
      ..sort((a, b) => _rankTime(b).compareTo(_rankTime(a)));

    final primary = (primaryClassroomCode ?? state.primaryClassroomCode)
        ?.trim();
    ConversationEntity? primaryNotes;
    if (primary != null && primary.isNotEmpty) {
      for (final item in unique) {
        if (item.type == ConversationType.classroomChat &&
            item.classroomCode?.trim() == primary) {
          primaryNotes = item;
          break;
        }
      }
    }

    if (primaryNotes == null) return unique.take(2).toList(growable: false);
    return <ConversationEntity>[
      primaryNotes,
      ...unique.where((c) => c.code != primaryNotes!.code).take(1),
    ];
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    _timeout?.cancel();
    return super.close();
  }
}
