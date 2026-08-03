import 'package:isar/isar.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/entities/sync_queue_entity.dart';
part 'sync_queue_collection.g.dart';

/// Isar collection for offline sync operations awaiting retry.
@collection
class SyncQueueCollection {
  Id get isarId => id;

  late int id;

  /// Raw string; convert via [SyncOperationType.fromStorageString].
  @Index()
  late String operation;

  late String entityCode;

  /// Raw string; convert via [SyncOperationStatus.fromStorageString].
  @Index()
  late String status;

  /// JSON-serialised payload — reconstructed on retry.
  late String payload;

  late int attempts;
  String? lastError;
  late DateTime createdAt;
  DateTime? lastAttemptAt;

  // Tenancy
  @Index()
  late String organizationCode;

  @Index()
  late String schoolCode;

  SyncQueueCollection();

  factory SyncQueueCollection.fromEntity(SyncQueueEntity entity) {
    return SyncQueueCollection()
      ..id = entity.id
      ..operation = entity.operation.toStorageString()
      ..entityCode = entity.entityCode
      ..status = entity.status.toStorageString()
      ..payload = entity.payload
      ..attempts = entity.attempts
      ..lastError = entity.lastError
      ..createdAt = entity.createdAt
      ..lastAttemptAt = entity.lastAttemptAt
      ..organizationCode = entity.organizationCode
      ..schoolCode = entity.schoolCode;
  }

  SyncQueueEntity toEntity() {
    return SyncQueueEntity(
      id: id,
      operation: SyncOperationType.fromStorageString(operation),
      entityCode: entityCode,
      status: SyncOperationStatus.fromStorageString(status),
      payload: payload,
      attempts: attempts,
      lastError: lastError,
      createdAt: createdAt,
      lastAttemptAt: lastAttemptAt,
      organizationCode: organizationCode,
      schoolCode: schoolCode,
    );
  }
}
