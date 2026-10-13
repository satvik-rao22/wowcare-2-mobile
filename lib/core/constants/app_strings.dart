/// All user-visible UI strings.
///
/// Mandate 4: *"No user-visible string literal in a view file. Everything
/// through `AppStrings` (`lib/core/constants/app_strings.dart`)."* This file did
/// not exist — `lib/core/constants/` held only `app_sizes.dart` — so it is
/// created here with the first module's strings and grows per module.
///
/// **What does NOT belong here** (§4, "skip anything not user-visible"): log
/// tags, storage keys, API payload keys, backend enum values. In particular the
/// `SIGNED_IN` / `ABSENT` / `TUESDAY` style constants in the dashboard are
/// backend values compared against API responses, not display text, and are
/// deliberately left where they are.
///
/// Every value below is character-for-character what was rendered before,
/// including the em-dashes and the ellipsis character.
abstract final class AppStrings {
  // Populated per-feature during migration. Scheduling's entries land here
  // in the theming pass (Mandate 4).

  // ── Dashboard · My Day card ───────────────────────────────────────────────

  static const String myDayTitle = 'My Day';

  /// Initial status line, before the schedule resolves.
  static const String myDayLoadingSchedule = 'Loading schedule…';

  static const String myDayShiftStartsIn = 'Your shift starts in';
  static const String myDayShiftEndsIn = 'Your shift ends in';
  static const String myDayNextShiftStartsIn = 'Your next shift starts in';
  static const String myDayNoSchedules = 'No schedules available';
  static const String myDayNoUpcomingShifts =
      'No upcoming shifts in next 7 days';

  /// Prefixes for the two chips. The value is interpolated after them.
  static const String myDayWorkTimePrefix = 'Work Time : ';
  static const String myDayBreakTimePrefix = 'Break Time : ';

  static const String myDaySignInPinPrefix = 'Your Sign-In Pin: ';

  /// Placeholder shown in place of the PIN when none is stored.
  static const String myDaySignInPinPlaceholder = '--';

  // ── Dashboard · My Day card · self-attendance failures ────────────────────

  static const String myDayNoStaffProfileTransfer =
      'Unable to find your staff profile to transfer.';
  static const String myDayNoStaffProfileMarkAbsent =
      'Unable to find your staff profile to mark absent.';
  static const String myDayNoStaffProfile =
      'Unable to find your staff profile.';

  // ── Dashboard · My Day card · geofence status ─────────────────────────────
  // SEMANTIC: these lines are the non-colour differentiator for the geofence
  // state (§4.3) — the coloured dot alone must not carry the meaning.

  static const String geofenceNotInRange =
      'You are not within geofencing Range';
  static const String geofenceInsideRadius =
      'Inside School Radius — GPS attendance enabled';
  static const String geofenceOutsideRadius =
      'Outside School Radius — move closer to sign in';
  static const String geofenceDisabledByAdmin =
      'GPS sign-in is currently disabled by your school admin.';
  static const String geofencePermissionRequired =
      'Location permission required. Tap to enable.';
  static const String geofenceServicesDisabled =
      'Location services are disabled. Please enable GPS.';
  static const String geofenceChecking = 'Checking your location...';

  // ── Dashboard · My Day card · work-break reminder ─────────────────────────

  /// Button label when a reminder is already on.
  static const String reminderTurnOff = 'Turn off Reminder';

  /// Button label when no reminder is set.
  static const String reminderSend = 'Send reminder';

  // SUSPECT: these two are the SNACKBAR confirmations, and they read as
  // imperatives ("Turn on Reminder") where a confirmation is expected
  // ("Reminder turned on"). Preserved verbatim under GUARDRAIL 1 — flagging
  // rather than fixing, since changing them is a copy decision, not a refactor.
  static const String reminderTurnedOnConfirmation = 'Turn on Reminder';
  static const String reminderTurnedOffConfirmation = 'Turn off Reminder';

  // ── Dashboard · chat-preview row ──────────────────────────────────────────

  static const String chatPreviewEmpty = 'No recent chat';

  /// Fallback title for a classroom conversation whose classroom name has not
  /// resolved yet.
  static const String chatPreviewClassroomFallback = 'Classroom';

  /// Relative-time label for the previous day.
  static const String chatPreviewYesterday = 'Yesterday';

  // ── Newsletter ────────────────────────────────────────────────────────────
  // Naming: `<feature><Context><Thing>`, lowerCamelCase, feature first — the
  // same shape as the dashboard entries above.
  //
  // NOT here, deliberately: newsletter TITLES, SUBTITLES and BODY HTML. Those
  // arrive from the backend with the record and are author-written content,
  // not UI copy. Nor are the `SENT`/`DRAFT` status values, which are compared
  // against API responses (§4, "skip anything not user-visible").

  /// Tab label on the staff/admin newsletter tab.
  static const String newsletterSentTab = 'Sent';

  /// Screen header and tab label on the parent newsletter screen.
  static const String newsletterTitle = 'Newsletter';

  /// Search field placeholder on both newsletter lists.
  static const String newsletterSearchHint = 'Search';

  /// Classroom multi-select placeholder and its inner search placeholder.
  static const String newsletterClassroomFilterHint = 'Classroom';
  static const String newsletterClassroomSearchHint = 'Search classroom';

  // ── Empty and error states ────────────────────────────────────────────────

  /// Parent list, no newsletters for the selected child.
  static const String newsletterNoneParent = 'No Newsletters';

  /// Staff/admin list, nothing sent yet.
  static const String newsletterNoneSent = 'No Sent Newsletters';

  /// Parent list, before a child has been chosen.
  static const String newsletterSelectChild =
      'Select a child to view newsletters.';

  /// Preview screen, the newsletter could not be fetched.
  static const String newsletterLoadFailed = 'Unable to load newsletter.';

  /// Preview screen, the record arrived without a usable code.
  static const String newsletterCodeMissing = 'Newsletter code is missing.';

  /// Preview body, the newsletter has no renderable components.
  static const String newsletterNoContent = 'No newsletter content available.';

  /// Image preview overlay, the image failed to decode.
  static const String newsletterImageLoadFailed = 'Unable to load image';

  /// Sign-in state lost while resolving the school for the list query.
  static const String newsletterSchoolCodeMissing =
      'School code not available. Please sign in again.';

  // ── Hyperlink handling ────────────────────────────────────────────────────

  /// Snackbar when a tapped link has no usable URL.
  static const String newsletterLinkOpenFailed = 'Unable to open link.';

  /// Snackbar when a tapped link could not be launched. The URL is appended.
  static const String newsletterLinkOpenFailedPrefix = 'Unable to open link: ';

  /// Snackbar when a tapped ATTACHMENT could not be handed to any app. Distinct
  /// from [newsletterLinkOpenFailed] because the remedy differs: a link needs a
  /// browser, a document needs an app that can open that file type.
  static const String newsletterAttachmentOpenFailed =
      'Unable to open this attachment.';

  // ── Recipients sheet and card meta ────────────────────────────────────────

  static const String newsletterRecipients = 'Recipients';
  static const String newsletterRecipientsUnavailable =
      'Recipient names are not available.';
  static const String newsletterAttachments = 'Attachments';
  static const String newsletterMetaDate = 'Date';
  static const String newsletterMetaCreatedBy = 'Created by';

  /// Separator between a card meta label and its value. Kept as a constant
  /// because the surrounding spaces are load-bearing.
  static const String newsletterMetaSeparator = ' : ';

  /// Retry action on the newsletter preview's failure state.
  static const String newsletterRetry = 'Retry';

  /// Parent list, a search matched nothing in the whole (fully paged) history.
  static const String newsletterNoSearchMatches =
      'No newsletters match your search.';

  /// Parent list, a search matched nothing YET but more pages are still
  /// loading. Distinct from [newsletterNoSearchMatches] so the user is not
  /// told "nothing found" while the answer is still arriving.
  static const String newsletterSearching = 'Searching…';

  /// Shown to a classroom-scoped staff member when neither their staff profile
  /// nor the classroom list could be loaded, so there is no classroom to scope
  /// the newsletter query by. The alternative would be querying the whole
  /// school, which is what this message exists to prevent.
  static const String newsletterClassroomScopeUnavailable =
      'Unable to load your classrooms. Pull to refresh.';

  /// Classroom label on a card when a newsletter targets every classroom.
  /// Only shown to users who are not classroom-restricted.
  static const String newsletterAllClassrooms = 'All Classrooms';

  /// Singular / plural noun after the recipient count in the sheet header.
  static const String newsletterRecipientSingular = 'recipient';
  static const String newsletterRecipientPlural = 'recipients';

  /// Accessibility label for the image preview barrier.
  static const String newsletterCloseImagePreview = 'Close image preview';

  /// Shown in the "Created by" slot when the API returns an empty
  /// `createdByName`.
  ///
  /// Was the literal `'Demo Test'`, which shipped to real users against real
  /// newsletters. Now `'-'`, which is what the PARENT list already used for
  /// exactly the same case — the two lists disagreed. Aligned on the parent
  /// list's value rather than inventing a third.
  static const String newsletterUnknownAuthor = '-';
  // ── Communication / messaging (Mandate 4) ──────────────────────────────────
  /// Conversation-list preview when the last message was an attachment only.
  static const String attachmentPreview = '📎 Attachment';

  /// Conversation-list preview when a conversation has no messages yet.
  static const String startANewConversation = 'Start a new conversation';

  /// Unread-count badge overflow label (shown for counts above 99).
  static const String unreadCountOverflow = '99+';

  // Fallback participant names by role, shown on a chip when the participant's
  // display name is missing.
  static const String roleFallbackAdmin = 'Admin';
  static const String roleFallbackParent = 'Parent';
  static const String roleFallbackStaff = 'Staff';
  static const String roleFallbackTeacher = 'Teacher';
  static const String roleFallbackDirector = 'Director';
  static const String roleFallbackPrincipal = 'Principal';
  static const String roleFallbackAssistant = 'Assistant';
  static const String roleFallbackLeadTeacher = 'Lead Teacher';

  // Filter bottom sheets (Admin Chats / conversations).
  static const String filter = 'Filter';
  static const String apply = 'Apply';
  static const String clear = 'Clear';
  static const String classroom = 'Classroom';
  static const String tag = 'Tag';
  static const String status = 'Status';
  static const String noClassroomsAvailable = 'No classrooms available';
  static const String noTagsAvailable = 'No tags available';
  static const String filters = 'Filters';
  static const String clearAll = 'Clear All';
  static const String designation = 'Designation';
  static const String staffStatus = 'Staff Status';
  static const String classroomCode = 'Classroom Code';
  static const String classroomCodeHint = 'Enter classroom code (e.g., CLS_123)';

  /// Legacy composer input placeholder (MessagingInputArea).
  static const String typeAMessage = 'Type a message...';

  // Participant-info dialog.
  static const String close = 'Close';
  static const String participantsSectionAdmins = 'ADMINS';
  static const String participantsSectionStaff = 'STAFF';
  static const String participantsSectionParents = 'PARENTS';

  /// Participant-info dialog title, with the total participant count.
  static String groupChatParticipants(int total) =>
      'Group Chat Participants ($total)';

  /// Reaction-info dialog title.
  static const String reactions = 'Reactions';

  // Message-info dialog.
  static const String messageInfo = 'Message Info';
  static const String messageSectionLabel = 'Message';
  static const String noOneHasRead = 'No one has read this message yet.';
  static const String notYetDelivered = 'Not yet delivered.';
  static String readByCount(int count) => 'Read By ($count)';
  static String deliveredToCount(int count) => 'Delivered To ($count)';

  // Attachment viewer.
  static const String attachments = 'Attachments';
  static const String noAttachments = 'No attachments';
  static const String processing = 'Processing…';
  static String documentsCount(int count) => 'Documents ($count)';

  // Attachment bottom sheet.
  static const String quickReactions = 'Quick Reactions';
  static const String camera = 'Camera';
  static const String gallery = 'Gallery';
  static const String documentOption = 'Document';
  static const String viewParticipants = 'View Participants';
  static String comingSoon(String feature) => '$feature coming soon';

  /// "10 MB" style readable file-size label.
  static String megabytes(int mb) => '$mb MB';

  // Attachment rejection messages (character-for-character from the picker).
  static String fileExceedsLimit(String name, String limit) =>
      '$name exceeds the $limit limit';
  static String filesExceedLimit(int count, String limit) =>
      '$count files exceed the $limit limit';
  static String filesExceedMixedLimits(
    int count,
    String imageLimit,
    String videoLimit,
  ) =>
      '$count files exceed the size limit '
      '($imageLimit for images/documents, $videoLimit for video)';
  static String fileUnsupportedType(String name) =>
      '$name is not a supported file type';
  static String filesUnsupportedType(int count) =>
      '$count files are not a supported file type';
  static String fileUnreadable(String name) => '$name could not be read';
  static String filesUnreadable(int count) => '$count files could not be read';
  static String filesCouldNotBeAttached(int count) =>
      "$count files couldn't be attached";
  static String bulkMessagesFailed(int failed) =>
      '$failed bulk message${failed == 1 ? '' : 's'} failed to send';
  static const String bulkSendFailed =
      'Bulk message failed to send. Please try again.';
  static const String attachmentPickFailed =
      'Could not open the file picker. Please try again.';
  // Full-screen media viewer.
  static const String download = 'Download';
  static const String mediaStillProcessing =
      'Media is still processing. Please try again.';
  static const String mediaPermissionRequired =
      'Photos permission is required to save media to your gallery.';
  static const String savedToGallery = 'Saved to your photo gallery.';
  static const String mediaDownloadFailed =
      'Failed to download media. Please try again.';
  static const String failedToLoadImage = 'Failed to load image';

  // Link / contact preview cards.
  static const String email = 'Email';
  static const String phone = 'Phone';

  // Composer (chat input bar).
  static const String you = 'You';
  static const String editingMessage = 'Editing Message';

  // Message bubble — context menu (label doubles as the switch key, so the
  // same constant is used at both the MenuItem and the handler site).
  static const String menuEdit = 'Edit';
  static const String menuDelete = 'Delete';
  static const String menuReply = 'Reply';
  static const String menuCopy = 'Copy';
  static const String menuInfo = 'Info';

  // Message bubble — delete confirmation sheet.
  static const String deleteMessageTitle = 'Delete Message';
  static const String deleteMessageConfirm =
      'Are you sure you want to delete this message?';
  static const String delete = 'Delete';
  static const String cancel = 'Cancel';

  // Message bubble — inline status / body.
  static const String messageDeleted = 'This message has been deleted.';
  static const String edited = 'Edited';
  static const String failedRetry = 'Failed · Retry';
  static const String processingShort = 'Processing';
  static const String privateMessageToast = 'This is a private message.';

  // ── Conversation list ──────────────────────────────────────────────────────
  static const String searchConversations = 'Search conversations';
  static const String unreadOnly = 'Unread only';
  static const String newConversation = 'New conversation';
  static const String noUnreadConversations = 'No unread conversations';
  static String noResultsFor(String query) => 'No results for "$query"';
  static const String failedToSearchStaff = 'Failed to search staff';
  static const String retry = 'Retry';
  static String noStaffFoundFor(String query) => 'No staff found for "$query"';
  static const String staffDirectory = 'Staff Directory';
  static const String unknown = 'Unknown';
  static const String messageAction = 'Message';
  static const String unnamedConversation = 'Unnamed Conversation';
  static const String tryAgain = 'Try again';
  static const String tapComposeToStart = 'Tap the compose button to start one.';

  // Conversation-type indicator labels.
  static const String typeStaffDirect = 'Staff Direct';
  static const String typeRoomChat = 'Room Chat';
  static const String typeAdminChat = 'Admin Chat';

  // Empty-state messages per conversation type.
  static const String emptyStaffConversations = 'No staff conversations yet';
  static const String emptyParentConversations = 'No parent conversations yet';
  static const String emptyAdminChats = 'No admin chats yet';
  static const String emptyClassroomConversations =
      'No classroom conversations yet';

  // ── Admin chat host ─────────────────────────────────────────────────────────
  static const String searchConversationsEllipsis = 'Search conversations…';
  static const String refreshingConversations = 'Refreshing conversations…';
  static const String showOnlyUnread = 'Show Only Unread';
  static const String noParentLinked = 'No parent linked';
  static const String startConversationWithAdmin =
      'Start Conversation with Admin';
  static const String noConversationsMatchFilters =
      'No conversations match your filters';
  static const String tryClearingFilters = 'Try clearing your filters';
  static String startNewChat(int count) => 'START NEW CHAT ($count)';
  static String couldNotStartConversation(String name) =>
      'Could not start a conversation with $name';
  static String chatCreatedSuccessfully(String name) =>
      'Chat with $name created successfully';
  static String participantsCount(int count) => '$count participants';

  // ── Parent messaging thread ─────────────────────────────────────────────────
  static const String sayHelloToStart = 'Say hello to start the conversation';
  static const String chatNotCreatedYet = "This chat hasn't been created yet";
  static const String unableToLoadMessages = 'Unable to load messages';
  static const String goBackStartNew = 'Go back and start a new conversation.';
  static const String goBack = 'Go back';
  static const String privateLabel = 'Private';
  static const String groupChat = 'Group Chat';
  static String privateBy(String name) => 'Private by $name';
  static String participantCountLabel(int count) =>
      '$count participant${count == 1 ? '' : 's'}';
  static const String privateModeOnlyActivatorCanDisable =
      'Only the guardian who turned Private Mode on can turn it off.';
  static const String privateModeOnTooltip =
      'Private: Messages visible to staff only';
  static const String privateModeOffTooltip =
      'Private: OFF - Messages visible to all';

  // ── Staff messaging thread ──────────────────────────────────────────────────
  static const String messageUpdatedSuccessfully = 'Message updated successfully';
  static const String save = 'Save';
  static const String noMessagesYet = 'No messages yet';
  static const String designationLabelColon = 'Designation: ';
  static const String emailLabelColon = 'Email: ';
  static const String goBackStartNewWithPerson =
      'Go back and start a new conversation with this person.';

  // ── Conversation thread ─────────────────────────────────────────────────────
  static const String privateMode = 'Private Mode';
  static const String privateModeOn = 'Private Mode ON';
  static const String privateModeOff = 'Private Mode OFF';
  static const String privateModeEnabledByOther =
      'Private Mode was enabled by another guardian and can only be disabled by that guardian.';
  static const String messageCopiedSuccessfully = 'Message copied successfully';
  static const String messageDeletedSuccessfully = 'Message deleted successfully';
  static const String reactionRemoved = 'Reaction removed';
  static const String reactionAdded = 'Reaction added';
  static const String noMessagesYetSayHello = 'No messages yet. Say hello!';
  static const String chatNotCreatedGoBack =
      "This chat hasn't been created yet. Go back and start a new conversation.";
  static const String participantFallback = 'Participant';
  static const String conversationFallback = 'Conversation';
  static const String staffAccountInactiveMessage =
      'Your staff account is inactive. You can no longer send messages.';
  static const String studentInactiveMessage =
      'This student is inactive. You can no longer send messages.';
  static const String noActiveGuardianMessage =
      'No active parent or guardian is available in this conversation. You can no longer send messages.';

  // ── Parent direct messaging ─────────────────────────────────────────────────
  static const String pullToRetry = 'Pull to retry';
  static const String couldNotLoadConversations = 'Could not load conversations';
  static const String pullDownToTryAgain = 'Pull down to try again';
  static const String studentFallback = 'Student';
  static const String group = 'Group';
  static const String roomChatNotCreated = 'Room Chat not yet created';

  // ── Bulk messaging — recipient selection ────────────────────────────────────
  static const String newMessage = 'New Message';
  static const String selectStaff = 'Select Staff';
  static const String selectStudents = 'Select Students';
  static const String searchStaff = 'Search Staff';
  static const String searchStudents = 'Search Students';
  static const String selectClassroom = 'Select Classroom';
  static const String selectDesignation = 'Select Designation';
  static const String selectTags = 'Select Tags';
  static const String selectAll = 'Select All';
  static const String next = 'Next';
  static const String noStaffMatchFilters =
      'No staff match the selected filters';
  static const String noStudentMatchFilters =
      'No student match the selected filters';
  static const String selectAtLeastOneStaff = 'Select at least one staff.';
  static const String selectAtLeastOneStudent = 'Select at least one student.';
  static String showingFirstStaff(int count) =>
      'Showing first $count staff matching filters.';
  static String showingFirstStudents(int count) =>
      'Showing first $count students matching filters.';

  // ── Staff messaging tab ─────────────────────────────────────────────────────
  static const String searchStudent = 'Search student';
  static const String noStaffMatchTheseFilters = 'No staff match these filters';
  static const String noStudentsMatchTheseFilters =
      'No students match these filters';
  static const String noConversationsYet = 'No conversations yet';
  static const String useThePlusButton = 'Use the + button to start one';
  static const String inactive = 'Inactive';
  static const String selectClassroomHint = 'Select classroom';
  static const String selectDesignationHint = 'Select designation';
  static const String selectStatusHint = 'Select status';
  static const String selectTagsHint = 'Select tags';

  // ── Bulk messaging — composition ────────────────────────────────────────────
  static const String addPhoto = 'Add Photo';
  static const String attachFile = 'Attach File';
  static const String send = 'Send';
  static const String pleaseEnterMessage = 'Please enter your message';
  static const String createMessage = 'Create Message';
  static const String bulkMessageProcessing =
      'Bulk message is being processed in the background.';
  static const String newMessagesLabel = 'New Messages';

  // ── Messaging entry / tabs ──────────────────────────────────────────────────
  static const String messagingTitle = 'Messaging';
  static const String newsletter = 'Newsletter';
  static const String navStaff = 'Staff';
  static const String navAdmin = 'Admin';
  static const String navStudents = 'Students';
  static const String navClassroomNotes = 'Classroom Notes';
  static const String messagingInactiveUnreadNotice =
      'Unread message counts also include unread messages for Students / '
      'Staff made inactive. Apply filters accordingly to view them in '
      'messaging.';

  // ── Attachment options sheet ────────────────────────────────────────────────
  static const String addAttachment = 'Add Attachment';
  static const String photosMultiple = 'Photos (multiple allowed)';
  static const String photosSubtitle =
      'JPEG, PNG, WEBP, HEIC, HEIF, AVIF, GIF, BMP, TIFF';
  static const String takePhoto = 'Take Photo';
  static const String takePhotoSubtitle = 'Capture a photo with your camera';
  static const String documentOneFile = 'Document (one file)';
  static const String documentSubtitle = 'PDF, DOC, DOCX, XLS, XLSX • max 10 MB';

  static String filesPartiallyRejected(
    int total,
    int oversizedCount,
    int unsupportedCount,
  ) =>
      "$total files couldn't be attached: $oversizedCount "
      "exceed${oversizedCount == 1 ? 's' : ''} the size limit, "
      '$unsupportedCount unsupported file type'
      '${unsupportedCount == 1 ? '' : 's'}';
}
