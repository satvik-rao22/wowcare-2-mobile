import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';

import 'package:wowcare/domain/features/communication/entities/conversation.dart';

abstract class CommunicationState extends Equatable {
  const CommunicationState();

  @override
  List<Object?> get props => [];
}

class CommunicationInitial extends CommunicationState {}

class CommunicationLoading extends CommunicationState {}

class CommunicationLoaded extends CommunicationState {
  final Map<String, List<Message>> threads;
  final String activeThreadId;

  /// Threads for which an older-history page request is in flight — drives
  /// the "loading older messages" spinner at the top of the list.
  final Set<String> threadsLoadingOlder;

  /// Threads confirmed to have no older history left to fetch (the last
  /// page came back shorter than the requested page size).
  final Set<String> threadsWithNoMoreHistory;

  const CommunicationLoaded({
    required this.threads,
    required this.activeThreadId,
    this.threadsLoadingOlder = const {},
    this.threadsWithNoMoreHistory = const {},
  });

  List<Message> get messages => threads[activeThreadId] ?? [];
  bool get isLoadingOlderMessages =>
      threadsLoadingOlder.contains(activeThreadId);
  bool get hasMoreOlderMessages =>
      !threadsWithNoMoreHistory.contains(activeThreadId);

  @override
  List<Object?> get props => [
    threads,
    activeThreadId,
    threadsLoadingOlder,
    threadsWithNoMoreHistory,
  ];

  CommunicationLoaded copyWith({
    Map<String, List<Message>>? threads,
    String? activeThreadId,
    Set<String>? threadsLoadingOlder,
    Set<String>? threadsWithNoMoreHistory,
  }) {
    return CommunicationLoaded(
      threads: threads ?? this.threads,
      activeThreadId: activeThreadId ?? this.activeThreadId,
      threadsLoadingOlder: threadsLoadingOlder ?? this.threadsLoadingOlder,
      threadsWithNoMoreHistory:
          threadsWithNoMoreHistory ?? this.threadsWithNoMoreHistory,
    );
  }
}

class CommunicationError extends CommunicationState {
  final String message;

  const CommunicationError(this.message);

  @override
  List<Object?> get props => [message];
}

class CommunicationConversationsLoading extends CommunicationState {}

class CommunicationConversationsLoaded extends CommunicationState {
  final Map<String?, List<Conversation>> conversationsByType;

  /// Per-type pagination bookkeeping — without this, "load more" has no
  /// way to know which page comes next, whether there even is one, or
  /// whether a fetch is already in flight (and would otherwise fire a
  /// duplicate request on every extra pixel of scroll).
  final Map<String?, int> currentPageByType;
  final Map<String?, bool> hasMoreByType;
  final Map<String?, bool> isLoadingMoreByType;

  const CommunicationConversationsLoaded(
    this.conversationsByType, {
    this.currentPageByType = const {},
    this.hasMoreByType = const {},
    this.isLoadingMoreByType = const {},
  });

  List<Conversation> get conversations => conversationsByType[null] ?? [];
  List<Conversation> getConversations(String? type) =>
      conversationsByType[type] ?? [];

  int getCurrentPage(String? type) => currentPageByType[type] ?? 0;
  bool getHasMore(String? type) => hasMoreByType[type] ?? false;
  bool getIsLoadingMore(String? type) => isLoadingMoreByType[type] ?? false;

  @override
  List<Object?> get props => [
    conversationsByType,
    currentPageByType,
    hasMoreByType,
    isLoadingMoreByType,
  ];

  CommunicationConversationsLoaded copyWith({
    Map<String?, List<Conversation>>? conversationsByType,
    Map<String?, int>? currentPageByType,
    Map<String?, bool>? hasMoreByType,
    Map<String?, bool>? isLoadingMoreByType,
  }) {
    return CommunicationConversationsLoaded(
      conversationsByType ?? this.conversationsByType,
      currentPageByType: currentPageByType ?? this.currentPageByType,
      hasMoreByType: hasMoreByType ?? this.hasMoreByType,
      isLoadingMoreByType: isLoadingMoreByType ?? this.isLoadingMoreByType,
    );
  }
}

class CommunicationSending extends CommunicationLoaded {
  const CommunicationSending({
    required super.threads,
    required super.activeThreadId,
  });
}
