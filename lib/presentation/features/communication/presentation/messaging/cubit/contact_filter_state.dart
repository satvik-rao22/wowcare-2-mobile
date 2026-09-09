import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/communication/entities/conversation.dart';

/// View-state for a messaging tab's contact filter/search bar
/// (`StaffMessagingTab`). Extracted from the screen's `setState` fields
/// (Mandate 2, Bucket A → cubit): the active filter map, the unread toggle,
/// server-side search results, the school tag map, the derived contact
/// code/name sets used to hide existing contacts, and the viewer's identity.
class ContactFilterState extends Equatable {
  const ContactFilterState({
    this.currentFilters = const {
      'Status': ['Active'],
    },
    this.showUnread = false,
    this.serverSearchResults,
    this.tagNameToCode = const {},
    this.allContactCodes = const {},
    this.allContactNames = const {},
    this.currentUserCode,
    this.currentAccountCode,
  });

  /// The active filter selections, keyed by section
  /// (Classroom/Designation/Status/Tags/Unread).
  final Map<String, List<String>> currentFilters;

  /// The "Show only unread" toggle (mirrored into `currentFilters['Unread']`).
  final bool showUnread;

  /// Existing conversations matching the current search text, from the server
  /// (null = no active search).
  final List<Conversation>? serverSearchResults;

  /// Tag display-name → backend tag code, resolved once per school.
  final Map<String, String> tagNameToCode;

  /// Codes/names of contacts who already have a conversation (staff by
  /// userCode, students by lowercased title) — used to hide them from the
  /// "Start new chat" list.
  final Set<String> allContactCodes;
  final Set<String> allContactNames;

  /// The viewer's staff/user code and canonical userCode.
  final String? currentUserCode;
  final String? currentAccountCode;

  ContactFilterState copyWith({
    Map<String, List<String>>? currentFilters,
    bool? showUnread,
    List<Conversation>? serverSearchResults,
    bool clearSearchResults = false,
    Map<String, String>? tagNameToCode,
    Set<String>? allContactCodes,
    Set<String>? allContactNames,
    String? currentUserCode,
    String? currentAccountCode,
  }) {
    return ContactFilterState(
      currentFilters: currentFilters ?? this.currentFilters,
      showUnread: showUnread ?? this.showUnread,
      serverSearchResults: clearSearchResults
          ? null
          : (serverSearchResults ?? this.serverSearchResults),
      tagNameToCode: tagNameToCode ?? this.tagNameToCode,
      allContactCodes: allContactCodes ?? this.allContactCodes,
      allContactNames: allContactNames ?? this.allContactNames,
      currentUserCode: currentUserCode ?? this.currentUserCode,
      currentAccountCode: currentAccountCode ?? this.currentAccountCode,
    );
  }

  @override
  List<Object?> get props => [
    currentFilters,
    showUnread,
    serverSearchResults,
    tagNameToCode,
    allContactCodes,
    allContactNames,
    currentUserCode,
    currentAccountCode,
  ];
}
