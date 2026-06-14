import 'package:equatable/equatable.dart';

import 'enums.dart';

/// A pending offline operation that must be retried when connectivity resumes.
///
/// Created locally when an API call fails due to no network.
/// Processed by [CommunicationSyncManager] on reconnect.
class SyncQueueEntity extends Equatable {
  const SyncQueueEntity({
    required this.id,
    required this.operation,
    required this.entityCode,
    required this.status,
    required this.payload,
    required this.createdAt,
    required this.organizationCode,
    required this.schoolCode,
    this.attempts = 0,
    this.lastError,
    this.lastAttemptAt,
  });

  /// Auto-incremented local identifier.
  final int id;

  /// What kind of API call to retry.
  final SyncOperationType operation;

  /// The message/conversation/reaction code this operation targets.
  final String entityCode;

  final SyncOperationStatus status;

  /// JSON-serialised payload for the retry request.
  final String payload;

  final int attempts;
  final String? lastError;
  final DateTime createdAt;
  final DateTime? lastAttemptAt;

  final String organizationCode;
  final String schoolCode;

  bool get isPending => status == SyncOperationStatus.pending;
  bool get hasFailed => status == SyncOperationStatus.failed;

  /// Seconds to wait before the next retry (exponential backoff, capped at 60s).
  int get nextRetryDelaySeconds {
    if (attempts == 0) return 1;
    final delay = 1 << attempts; // 2^attempts
    return delay > 60 ? 60 : delay;
  }

  @override
  List<Object?> get props => [
        id,
        operation,
        entityCode,
        status,
        payload,
        attempts,
        lastError,
        createdAt,
        lastAttemptAt,
        organizationCode,
        schoolCode,
      ];
}
