import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/repositories/conversation_entity_repository.dart';
import 'package:wowcare/presentation/features/communication/cubit/communication_cubit.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/screens/conversation_thread_screen.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/staff_messaging_thread.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/src/app_router.dart';

/// Opens the conversation thread for a messaging PUSH-NOTIFICATION tap.
///
/// A chat push carries only the [conversationCode] (+ [conversationType]), not
/// the full [ConversationEntity] the thread screens need — so this screen fetches
/// the entity by code, then renders the correct thread: [StaffMessagingThread]
/// for STAFF_DIRECT, [ConversationThreadScreen] for everything else (matching how
/// the rest of the app opens conversations).
///
/// Reached via the [AppRoutes.openConversation] route from
/// NotificationRouteResolver when a `NEW_MESSAGE` / `NEW_CONVERSATION` push is
/// tapped. It never traps the user: back always falls through to the messaging
/// list when there is nothing to pop.
class OpenConversationScreen extends StatefulWidget {
  const OpenConversationScreen({
    super.key,
    required this.conversationCode,
    this.conversationType,
  });

  static const String routeName = '/open-conversation';

  final String conversationCode;

  /// From the push payload — informational only; the authoritative type comes
  /// from the fetched entity (this may be empty on older backends).
  final String? conversationType;

  @override
  State<OpenConversationScreen> createState() => _OpenConversationScreenState();
}

class _OpenConversationScreenState extends State<OpenConversationScreen> {
  late final Future<ConversationEntity?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<ConversationEntity?> _load() async {
    final code = widget.conversationCode.trim();
    if (code.isEmpty) return null;
    final result = await serviceLocator<ConversationEntityRepository>()
        .getConversation(code);
    return result.fold((_) => null, (c) => c);
  }

  void _goBackOrHome() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.messaging);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBackOrHome();
      },
      child: FutureBuilder<ConversationEntity?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Scaffold(body: Center(child: PrimaryCircularLoader()));
          }
          final conversation = snapshot.data;
          if (conversation == null) {
            return Scaffold(
              appBar: AppBar(leading: BackButton(onPressed: _goBackOrHome)),
              body: const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'This conversation could not be opened. '
                    'It may have been removed.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }
          if (conversation.type == ConversationType.staffDirect) {
            // STAFF_DIRECT renders through the dedicated staff thread screen,
            // exactly like staff_messaging_tab / the messaging shortcut do.
            // Total active participants minus the viewer themselves — seeded
            // so the fresh per-thread CommunicationCubit's read/delivered-
            // by-all tick aggregation has a recipient count to work with.
            // See CommunicationCubit.seedRecipientCount's own doc for why
            // this is required, not just an optimization.
            final recipientCount =
                conversation.participants.where((p) => p.isActive).length - 1;
            return BlocProvider<CommunicationCubit>(
              create: (_) =>
                  serviceLocator<CommunicationCubit>()
                    ..seedRecipientCount(conversation.code, recipientCount),
              child: StaffMessagingThread(
                staffInfo: {
                  'name': conversation.title,
                  'avatar': conversation.avatarUrl,
                  'code': conversation.code,
                },
              ),
            );
          }
          return ConversationThreadScreen(conversation: conversation);
        },
      ),
    );
  }
}
