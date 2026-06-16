import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/usecases/get_cached_conversations_entity_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/get_conversations_entity_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/watch_conversations_usecase.dart';
import 'package:wowcare/presentation/features/communication/cubit/communication_cubit.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/view/parent_messaging_thread.dart';
import 'package:wowcare/presentation/features/communication/presentation/messaging/widgets/chat_thread_shimmer.dart';
import 'package:wowcare/presentation/features/communication/v2/cubit/conversation_list_cubit.dart';
import 'package:wowcare/presentation/features/communication/v2/cubit/conversation_list_state.dart';
import 'package:wowcare/shared/common/widgets/custom_text_widget.dart';

import '../../../../../../domain/features/communication/entities/conversation.dart';

/// Parent/Guardian messaging entry point.
///
/// Bypasses the conversation list and goes straight to the thread for the
/// selected student. A dropdown at the top lets the parent switch children.
/// Each student switch destroys and recreates the thread widget so messages
/// reload cleanly for the new conversation.
class ParentDirectMessagingScreen extends StatefulWidget {
  const ParentDirectMessagingScreen({super.key});

  @override
  State<ParentDirectMessagingScreen> createState() =>
      _ParentDirectMessagingScreenState();
}

class _ParentDirectMessagingScreenState
    extends State<ParentDirectMessagingScreen> {
  late final ConversationListCubit _listCubit;
  ConversationEntity? _selectedConversation;

  @override
  void initState() {
    super.initState();
    _listCubit = ConversationListCubit(
      conversationType: ConversationType.roomChat,
      watchConversationsUseCase: serviceLocator<WatchConversationsUseCase>(),
      getConversationsUseCase: serviceLocator<GetConversationsEntityUseCase>(),
      getCachedConversationsUseCase:
          serviceLocator<GetCachedConversationsEntityUseCase>(),
      conversationRepository: serviceLocator(),
      storageService: serviceLocator(),
    );
    _listCubit.startWatching();
  }

  @override
  void dispose() {
    _listCubit.close();
    super.dispose();
  }

  void _onConversationSelected(ConversationEntity conversation) {
    if (_selectedConversation?.code == conversation.code) return;
    setState(() => _selectedConversation = conversation);
  }

  /// Converts a v2 [ConversationEntity] into the legacy [parentInfo] map that
  /// [ParentMessagingThread] expects.
  Map<String, dynamic> _buildParentInfo(ConversationEntity conv) {
    final legacyParticipants = conv.participants.map((p) {
      final roleStr = p.role == ParticipantRole.parent
          ? 'GUARDIAN'
          : p.role.name.toUpperCase();
      return ConversationParticipant(
        id: 0,
        conversationId: 0,
        userCode: p.userCode,
        userName: p.userName,
        role: roleStr,
        joinedAt: DateTime.now(),
        muted: false,
        notificationsEnabled: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }).toList();

    final parentNames = legacyParticipants
        .where((p) => p.role == 'GUARDIAN' || p.role == 'PARENT')
        .map((p) => p.userName)
        .toList();

    final staffCodes = legacyParticipants
        .where((p) => p.role == 'STAFF' || p.role == 'ADMIN')
        .map((p) => p.userCode)
        .toList();

    return {
      'name': conv.title,
      'avatar': conv.avatarUrl,
      'code': conv.code,
      'parents': parentNames,
      'participants': legacyParticipants,
      'staffList': staffCodes,
      'privateModeParents': <String>[],
    };
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ConversationListCubit>.value(
      value: _listCubit,
      child: BlocConsumer<ConversationListCubit, ConversationListState>(
        listener: (context, state) {
          // Auto-select the first conversation when conversations first arrive.
          if (_selectedConversation == null && state.conversations.isNotEmpty) {
            setState(() => _selectedConversation = state.conversations.first);
          }
        },
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStudentDropdown(state.conversations),
              Expanded(child: _buildThreadArea(state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStudentDropdown(List<ConversationEntity> conversations) {
    if (conversations.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0x33B1AFE9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedConversation?.code ?? conversations.first.code,
            isExpanded: true,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.primaryColor,
            ),
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF241631),
            ),
            items: conversations.map((conv) {
              return DropdownMenuItem<String>(
                value: conv.code,
                child: Text(conv.title, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (code) {
              if (code == null) return;
              final conv = conversations.firstWhere((c) => c.code == code);
              _onConversationSelected(conv);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildThreadArea(ConversationListState state) {
    final selected = _selectedConversation;

    if (selected == null) {
      if (state.isLoading) {
        return const ChatThreadShimmer();
      }
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 56,
              color: Colors.grey.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 12),
            const CustomTextWidget(
              text: 'No conversations found',
              fontSize: 15,
              fontColor: Colors.grey,
            ),
          ],
        ),
      );
    }

    // Provide a dedicated CommunicationCubit for the thread so its state
    // (messages) is isolated from any outer cubit used for the list.
    return BlocProvider<CommunicationCubit>(
      create: (_) => serviceLocator<CommunicationCubit>(),
      child: ParentMessagingThread(
        key: ValueKey(selected.code),
        parentInfo: _buildParentInfo(selected),
        showOwnScaffold: false,
      ),
    );
  }
}
