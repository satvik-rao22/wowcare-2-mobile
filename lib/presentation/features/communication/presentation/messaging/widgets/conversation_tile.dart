import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/presentation/features/communication/view_model/conversation_list_cubit.dart';
import 'package:wowcare/presentation/features/communication/view_model/conversation_list_state.dart';

/// Renders a single conversation row driven by its own [BlocSelector] over
/// [ConversationListCubit], keyed by [conversationCode] — mirrors
/// `ThreadMessageTile`'s pattern for message bubbles.
///
/// Without this, every row rebuilds on every Firestore emission for the
/// whole list (unread count changes, last-message updates, badge zeroing),
/// even rows whose own conversation didn't change. [ConversationEntity] is
/// `Equatable`, so this selector's default `previous != current` check means
/// only the row whose own conversation actually changed value re-renders.
///
/// [contentBuilder] renders the actual row chrome, which differs per screen
/// (Admin Chat's host screen has different chrome than the shared
/// [ConversationListScreen]) — only the rebuild-scoping is shared.
class ConversationListTile extends StatelessWidget {
  const ConversationListTile({
    super.key,
    required this.conversationCode,
    required this.contentBuilder,
  });

  final String conversationCode;
  final Widget Function(BuildContext context, ConversationEntity conversation)
  contentBuilder;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      ConversationListCubit,
      ConversationListState,
      ConversationEntity?
    >(
      selector: (state) {
        for (final c in state.conversations) {
          if (c.code == conversationCode) return c;
        }
        return null;
      },
      builder: (context, conversation) {
        if (conversation == null) return const SizedBox.shrink();
        return contentBuilder(context, conversation);
      },
    );
  }
}
