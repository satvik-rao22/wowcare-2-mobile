import 'dart:io';

import 'package:wowcare/domain/features/communication/entities/message.dart'
    show ChatAttachment;
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/shared/common/view/filter_screen.dart'
    show FilerSection;
import 'package:wowcare/presentation/features/communication/model/messaging_recipient.dart';
import 'package:wowcare/presentation/features/communication/model/thread_info.dart';

/// Typed arguments for the communication feature's GoRoutes (Mandate 1).
///
/// Every messaging navigation used to build its destination widget inline
/// inside a `MaterialPageRoute`, passing live objects (a [ConversationEntity],
/// picked [File]s, an `onApply` closure) straight into the constructor. Those
/// objects have no URL representation, so the routes carry them through
/// GoRouter's `extra` as the typed classes below — the same approach the
/// reports feature uses for `ReportFileViewerArgs` — instead of an untyped
/// `Object?` at each `context.push` (Mandate 8).

/// Arguments for the generic [ConversationThreadScreen] route.
///
/// The screen creates and owns its own `ConversationThreadCubit` in
/// `initState` (§5.4), so no cubit travels with the arguments — only the
/// conversation it renders.
class ConversationThreadArgs {
  const ConversationThreadArgs({required this.conversation});

  final ConversationEntity conversation;
}

/// Arguments for the seeded staff/parent thread route.
///
/// Backs both the staff-directory "Message" shortcut (staff only) and the
/// Admin/Room Chat list's own thread open (staff or parent). The route wraps
/// the destination in a fresh per-thread `CommunicationCubit` seeded via
/// `seedRecipientCount` — the read/delivered-by-all tick aggregation needs a
/// recipient count because that cubit never loads the conversation list
/// itself. [staffInfo] / [parentInfo] keep the untyped shape the two thread
/// screens accept as typed [StaffThreadInfo]/[ParentThreadInfo] (Mandate 8).
class SeededThreadArgs {
  const SeededThreadArgs({
    required this.isStaffMessaging,
    required this.conversationCode,
    required this.recipientCount,
    this.staffInfo,
    this.parentInfo,
    this.conversationType,
  });

  final bool isStaffMessaging;
  final String conversationCode;
  final int recipientCount;

  /// Populated when [isStaffMessaging] is true.
  final StaffThreadInfo? staffInfo;

  /// Populated when [isStaffMessaging] is false.
  final ParentThreadInfo? parentInfo;

  /// Conversation type for the parent thread branch (defaults handled by the
  /// screen when null).
  final Object? conversationType;
}

/// Arguments for the bulk message-composition route.
///
/// [MessageCompositionBulkMessaging] provides its own cubit, so the route
/// builds the screen directly with no `BlocProvider` wrapper.
class MessageCompositionArgs {
  const MessageCompositionArgs({
    required this.selectedRecipients,
    required this.isStaff,
    required this.conversationType,
  });

  final List<MessagingRecipient> selectedRecipients;
  final bool isStaff;
  final String conversationType;
}

/// Arguments for the recipient-selection route.
///
/// [StaffOrStudentSelectionBulkMessaging] reads `StaffCubit`, `ClassroomCubit`
/// and `StudentCubit` from ancestors, so the route wraps it in the same
/// `MultiBlocProvider` the push it replaced used.
class RecipientSelectionArgs {
  const RecipientSelectionArgs({
    required this.isStaffSelection,
    required this.conversationType,
    this.restrictToDesignationCodes,
    this.hideFilters = false,
  });

  final bool isStaffSelection;
  final String conversationType;
  final List<String>? restrictToDesignationCodes;
  final bool hideFilters;
}

/// Arguments for the full-screen media viewer route.
///
/// Carries the picked/remote sources the viewer opens; the [File]s are live
/// objects with no URL form, hence `extra`.
class MediaViewerArgs {
  const MediaViewerArgs({
    this.imageUrl,
    this.imageFile,
    this.videoUrl,
    this.videoFile,
    this.title,
    this.heroTag,
  });

  final String? imageUrl;
  final File? imageFile;
  final String? videoUrl;
  final File? videoFile;
  final String? title;
  final String? heroTag;
}

/// Arguments for the multi-attachment gallery route.
class AttachmentGalleryArgs {
  const AttachmentGalleryArgs({required this.attachments});

  final List<ChatAttachment> attachments;
}

/// Arguments for the shared full-screen [FilterScreen] as opened from
/// messaging.
///
/// [onApply] is a live callback and [sections] hold live selection state, so
/// both travel through `extra`.
class MessagingFilterArgs {
  const MessagingFilterArgs({
    required this.sections,
    required this.onApply,
    this.title = 'Filter',
  });

  final List<FilerSection> sections;
  final void Function(Map<String, List<String>> appliedFilters) onApply;
  final String title;
}
