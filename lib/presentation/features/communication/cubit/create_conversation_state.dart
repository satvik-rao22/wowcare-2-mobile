import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';

class CreateConversationState extends Equatable {
  const CreateConversationState({
    required this.status,
    this.conversationType,
    this.createdConversation,
    this.validationError,
    this.errorMessage,
  });

  const CreateConversationState.initial()
    : status = CreateConversationStatus.idle,
      conversationType = null,
      createdConversation = null,
      validationError = null,
      errorMessage = null;

  final CreateConversationStatus status;

  /// The type being created — set before the API call so the UI can respond.
  final ConversationType? conversationType;

  /// Non-null on success.
  final ConversationEntity? createdConversation;

  /// Non-null when client-side validation fails (before any API call).
  final String? validationError;

  /// Non-null when the API call itself fails.
  final String? errorMessage;

  bool get isIdle => status == CreateConversationStatus.idle;
  bool get isLoading => status == CreateConversationStatus.loading;
  bool get isSuccess => status == CreateConversationStatus.success;
  bool get isFailure => status == CreateConversationStatus.failure;
  bool get isValidationError => validationError != null;

  CreateConversationState copyWith({
    CreateConversationStatus? status,
    ConversationType? conversationType,
    ConversationEntity? createdConversation,
    String? validationError,
    String? errorMessage,
    bool clearValidationError = false,
    bool clearError = false,
  }) {
    return CreateConversationState(
      status: status ?? this.status,
      conversationType: conversationType ?? this.conversationType,
      createdConversation: createdConversation ?? this.createdConversation,
      validationError: clearValidationError
          ? null
          : (validationError ?? this.validationError),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    conversationType,
    createdConversation,
    validationError,
    errorMessage,
  ];
}

enum CreateConversationStatus { idle, loading, success, failure }
