import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/di/messaging_resolvers.dart';
import 'package:wowcare/core/router/app_routes.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/usecases/create_or_open_conversation_usecase.dart';
import 'package:wowcare/presentation/features/communication/model/communication_route_args.dart';
import 'package:wowcare/presentation/features/communication/model/messaging_recipient.dart';
import 'package:wowcare/presentation/features/communication/model/thread_info.dart';

/// A recipient picked via checkboxes on any multi-select directory/roster
/// screen (Student Directory, Staff Directory, Classroom Students/Staff
/// tabs, ...), normalized so [openMessagingShortcut] can route it regardless
/// of which screen it came from.
class SelectedRecipient {
  const SelectedRecipient({
    required this.code,
    required this.name,
    required this.isStaff,
    this.userCode = '',
    this.avatar = '',
    this.designation = '',
    this.classroomCode = '',
  });

  /// The primary identity code.
  /// For staff this is the staff code (STF_*) used for display and navigation.
  /// For students this is the student code used as the API studentCode param.
  final String code;
  final String name;
  final bool isStaff;

  /// The user account code (USR_*) used as the messaging API participant code.
  /// Must be populated for staff recipients; unused for student recipients.
  final String userCode;
  final String avatar;
  final String designation;

  /// Room Chat's optional classroom scope — populated only by callers that
  /// already know it (e.g. a classroom's own Students tab). Left blank for
  /// screens like Student Directory that aren't scoped to one classroom;
  /// the backend resolves the conversation from studentCode alone in that
  /// case, same as it did before this field existed.
  final String classroomCode;
}

/// Guards against a rapid double-tap on the Message button firing two
/// `CreateOrOpenConversationUseCase` calls before the first one resolves.
bool _isOpeningMessagingShortcut = false;

/// Single entry point for the "select recipients via checkboxes, tap
/// Message" shortcut. Reuses the app's two existing messaging flows rather
/// than introducing a new one:
///
/// - Exactly one recipient: calls [CreateOrOpenConversationUseCase], which
///   already finds an existing 1:1 conversation before creating one, then
///   opens the existing [ConversationThreadScreen] — full history preserved,
///   no duplicate conversation.
/// - Two or more recipients: pushes straight to the existing
///   [MessageCompositionBulkMessaging], skipping the manual contact-picker
///   step ([StaffOrStudentSelectionBulkMessaging]) since recipients are
///   already selected.
Future<void> openMessagingShortcut(
  BuildContext context, {
  required List<SelectedRecipient> recipients,
}) async {
  if (recipients.isEmpty || _isOpeningMessagingShortcut) return;

  final allStaff = recipients.every((r) => r.isStaff);
  final allStudents = recipients.every((r) => !r.isStaff);
  if (!allStaff && !allStudents) {
    // None of today's multi-select screens produce a mixed student+staff
    // selection, and the bulk compose screen only supports one recipient
    // type at a time — decline gracefully rather than inventing a new,
    // unreviewed mixed-conversation flow.
    CoreUtils.showTopSnackBar(
      context: context,
      message:
          'Messaging a mix of students and staff together is not supported yet.',
      isWarning: true,
    );
    return;
  }

  _isOpeningMessagingShortcut = true;
  try {
    if (recipients.length == 1) {
      await _openSingleRecipientConversation(context, recipients.first);
    } else {
      _openBulkCompose(context, recipients, isStaff: allStaff);
    }
  } finally {
    _isOpeningMessagingShortcut = false;
  }
}

Future<void> _openSingleRecipientConversation(
  BuildContext context,
  SelectedRecipient recipient,
) async {
  final type = recipient.isStaff
      ? ConversationType.staffDirect
      : ConversationType.roomChat;

  // Staff conversations must use the USR_* user code, never the STF_* staff
  // code. Callers populate `userCode` for staff recipients; fall back to `code`
  // only for backward-compatibility with any path that predates this field.
  final staffParticipantCode = recipient.userCode.isNotEmpty
      ? recipient.userCode
      : recipient.code;

  final result = await resolveCreateOrOpenConversationUseCase()(
    type: type,
    studentCode: recipient.isStaff ? '' : recipient.code,
    classroomCode: recipient.isStaff ? null : recipient.classroomCode,
    participantCodes: recipient.isStaff ? [staffParticipantCode] : const [],
    title: recipient.name,
    avatarUrl: recipient.avatar,
  );

  if (!context.mounted) return;
  final conversation = result.fold((_) => null, (c) => c);
  if (conversation == null) {
    // Surface the backend's actual reason (e.g. "This student has no
    // parent/guardian added...") instead of a generic message that hides
    // why the conversation couldn't be opened.
    final failureMessage = result.fold((f) => f.message, (_) => null);
    CoreUtils.showTopSnackBar(
      context: context,
      message: (failureMessage != null && failureMessage.trim().isNotEmpty)
          ? failureMessage
          : 'Could not open a conversation with ${recipient.name}',
      isWarning: true,
    );
    return;
  }

  if (recipient.isStaff) {
    // STAFF_DIRECT conversations render through the same dedicated
    // StaffMessagingThread screen used by staff_messaging_tab.dart, not the
    // generic ConversationThreadScreen — matches the existing staff
    // conversation experience exactly (designation/online-status chrome,
    // staff-specific composer behavior, etc).
    // `conversation.title` for STAFF_DIRECT is frozen at creation time to
    // whoever CREATED the conversation's counterpart name — it does not
    // update per-viewer. If this conversation already existed (created by
    // someone else, e.g. the staff member messaging this recipient first),
    // rendering it verbatim shows the wrong name to everyone who isn't that
    // original creator. Resolve the actual staff participant's own name
    // from the roster instead; it's always correct regardless of who
    // created the conversation.
    final staffParticipant = conversation.participants
        .where((p) => p.userCode == staffParticipantCode)
        .firstOrNull;
    final staffParticipantName = (staffParticipant?.userName ?? '').trim();
    final name = staffParticipantName.isNotEmpty
        ? staffParticipantName
        : recipient.name;
    // Conversation-level avatarUrl is never populated for STAFF_DIRECT chats
    // (it only carries a nested `student` fallback for ROOM_CHAT) — resolve
    // the staff participant's own avatar first, falling back to whatever
    // avatar the caller already resolved for this recipient.
    final staffParticipantAvatar = (staffParticipant?.avatarUrl ?? '').trim();
    final resolvedAvatar = conversation.avatarUrl.trim().isNotEmpty
        ? conversation.avatarUrl
        : staffParticipantAvatar.isNotEmpty
        ? staffParticipantAvatar
        : recipient.avatar;
    // Total active participants minus the viewer themselves (always one of
    // them, having just created/opened this conversation) — seeded so the
    // fresh per-thread CommunicationCubit's read/delivered-by-all tick
    // aggregation has a recipient count to work with. See
    // CommunicationCubit.seedRecipientCount's own doc for why this is
    // required, not just an optimization.
    final recipientCount =
        conversation.participants.where((p) => p.isActive).length - 1;
    context.push(
      CommunicationRoutes.seededThread,
      extra: SeededThreadArgs(
        isStaffMessaging: true,
        conversationCode: conversation.code,
        recipientCount: recipientCount,
        staffInfo: StaffThreadInfo(
          name: name,
          avatar: resolvedAvatar,
          code: conversation.code,
          staffUserCode: staffParticipantCode,
          // recipient.code IS the staff code (STF_*) for staff recipients
          // (every caller of openMessagingShortcut sets it that way — see
          // SelectedRecipient's own doc) — a direct, reliable photo lookup
          // the header can use instead of depending on the userCode→
          // staffCode resolution succeeding.
          staffCode: recipient.isStaff ? recipient.code : null,
        ),
      ),
    );
    return;
  }

  context.push(
    CommunicationRoutes.conversationThread,
    extra: ConversationThreadArgs(conversation: conversation),
  );
}

void _openBulkCompose(
  BuildContext context,
  List<SelectedRecipient> recipients, {
  required bool isStaff,
}) {
  context.push(
    CommunicationRoutes.bulkCompose,
    extra: MessageCompositionArgs(
      selectedRecipients: recipients
          .map(
            (r) => MessagingRecipient(
              code: r.code,
              name: r.name,
              avatar: r.avatar,
              designation: r.designation,
            ),
          )
          .toList(),
      isStaff: isStaff,
      conversationType: isStaff ? 'STAFF_DIRECT' : 'ROOM_CHAT',
    ),
  );
}
