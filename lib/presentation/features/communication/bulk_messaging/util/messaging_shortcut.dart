import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/usecases/create_or_open_conversation_usecase.dart';
import 'package:wowcare/presentation/features/communication/bulk_messaging/view/message_composition_bulk_messaging.dart';
import 'package:wowcare/presentation/features/communication/cubit/communication_cubit.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/screens/conversation_thread_screen.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/staff_messaging_thread.dart';

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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Messaging a mix of students and staff together is not supported yet.',
        ),
      ),
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
  CoreUtils.showTopSnackBar(
    context: context,
    message: "Opening conversation with ${recipient.name}…",
    isSuccess: true,
  );

  final type = recipient.isStaff
      ? ConversationType.staffDirect
      : ConversationType.roomChat;

  // Staff conversations must use the USR_* user code, never the STF_* staff
  // code. Callers populate `userCode` for staff recipients; fall back to `code`
  // only for backward-compatibility with any path that predates this field.
  final staffParticipantCode = recipient.userCode.isNotEmpty
      ? recipient.userCode
      : recipient.code;

  final result = await serviceLocator<CreateOrOpenConversationUseCase>()(
    type: type,
    studentCode: recipient.isStaff ? '' : recipient.code,
    participantCodes: recipient.isStaff ? [staffParticipantCode] : const [],
    title: recipient.name,
    avatarUrl: recipient.avatar,
  );

  if (!context.mounted) return;
  final conversation = result.fold((_) => null, (c) => c);
  if (conversation == null) {
    CoreUtils.showTopSnackBar(
      context: context,
      message: 'Could not open a conversation with ${recipient.name}',
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
    final name = conversation.title.isNotEmpty
        ? conversation.title
        : recipient.name;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider<CommunicationCubit>(
          create: (context) => serviceLocator<CommunicationCubit>(),
          child: StaffMessagingThread(
            staffInfo: {
              'name': name,
              'avatar': conversation.avatarUrl,
              'code': conversation.code,
            },
          ),
        ),
      ),
    );
    return;
  }

  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ConversationThreadScreen(conversation: conversation),
    ),
  );
}

void _openBulkCompose(
  BuildContext context,
  List<SelectedRecipient> recipients, {
  required bool isStaff,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => MessageCompositionBulkMessaging(
        selectedRecipients: recipients
            .map(
              (r) => <String, dynamic>{
                'code': r.code,
                'name': r.name,
                'avatar': r.avatar,
                'designation': r.designation,
              },
            )
            .toList(),
        isStaff: isStaff,
        conversationType: isStaff ? 'STAFF_DIRECT' : 'ROOM_CHAT',
      ),
    ),
  );
}
