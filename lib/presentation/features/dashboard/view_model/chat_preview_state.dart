part of 'chat_preview_cubit.dart';

/// State for the My Day card's recent-chat preview rows.
///
/// Every field here was a `_CommunicationRowWidgetState` field before Mandate 2
/// — see [ChatPreviewCubit]'s doc for why they are bucket A.
class ChatPreviewState extends Equatable {
  const ChatPreviewState({
    this.items = const <ConversationEntity>[],
    this.isLoading = true,
    this.currentUserCode = '',
    this.primaryClassroomCode,
    this.classroomNames = const <String, String>{},
  });

  /// Top two by recency, with the staff member's own classroom Notes pinned
  /// first when they have one.
  final List<ConversationEntity> items;

  /// True until the first of cache / REST / Firestore answers, or the 8-second
  /// timeout fires. Matches the previous `_loading` field exactly, including
  /// its `true` initial value.
  final bool isLoading;

  /// Needed to resolve a conversation's display title (which participant is
  /// "the other one").
  final String currentUserCode;

  /// The staff member's own primary classroom — its Notes conversation is
  /// always the first row regardless of recency, so a staff member never has to
  /// hunt for their own classroom's Notes. Null for admin/unscoped personas or
  /// before it resolves.
  final String? primaryClassroomCode;

  /// Classroom code → name, so the Notes row can show the classroom's actual
  /// name rather than the generic "Classroom" fallback.
  final Map<String, String> classroomNames;

  ChatPreviewState copyWith({
    List<ConversationEntity>? items,
    bool? isLoading,
    String? currentUserCode,
    String? primaryClassroomCode,
    Map<String, String>? classroomNames,
  }) {
    return ChatPreviewState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      currentUserCode: currentUserCode ?? this.currentUserCode,
      primaryClassroomCode: primaryClassroomCode ?? this.primaryClassroomCode,
      classroomNames: classroomNames ?? this.classroomNames,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    items,
    isLoading,
    currentUserCode,
    primaryClassroomCode,
    classroomNames,
  ];
}
