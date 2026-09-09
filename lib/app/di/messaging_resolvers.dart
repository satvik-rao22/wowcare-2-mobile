import 'package:dartz/dartz.dart' show Either;
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/attendance_classroom_scope.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/data/services/file_download_service.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/repositories/conversation_entity_repository.dart';
import 'package:wowcare/domain/features/communication/usecases/create_or_open_conversation_usecase.dart';
import 'package:wowcare/domain/features/communication/usecases/get_communication_settings_usecase.dart';
import 'package:wowcare/domain/features/staff/entities/staff_profile.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/domain/features/student/usecases/get_tag_name_code_map_for_school_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_tag_names_for_school_usecase.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_service.dart';

/// DI resolvers for the communication feature's shared utilities and the few
/// screens with no natural owning cubit, kept OUT of the presentation layer
/// (Mandate 5: the module references no `serviceLocator`).
///
/// - Plain services and use-cases are returned as-is (they are not forbidden
///   view types) so callers keep their exact behaviour.
/// - Repository- and storage-backed calls are wrapped to return a DOMAIN value
///   (a profile, a conversation, a code), so the forbidden `Repository` /
///   `StorageService` types never appear in the module. Every call forwards to
///   the same service-locator registration used before — no behaviour change.

// ── Plain services (not forbidden view types) ────────────────────────────────
ImageUploadService resolveImageUploadService() =>
    serviceLocator<ImageUploadService>();

FileDownloadService resolveFileDownloadService() =>
    serviceLocator<FileDownloadService>();

// ── Use-cases (not forbidden view types) ─────────────────────────────────────
GetCommunicationSettingsUseCase resolveGetCommunicationSettingsUseCase() =>
    serviceLocator<GetCommunicationSettingsUseCase>();

CreateOrOpenConversationUseCase resolveCreateOrOpenConversationUseCase() =>
    serviceLocator<CreateOrOpenConversationUseCase>();

GetTagNamesForSchoolUseCase resolveGetTagNamesForSchoolUseCase() =>
    serviceLocator<GetTagNamesForSchoolUseCase>();

GetTagNameCodeMapForSchoolUseCase resolveGetTagNameCodeMapForSchoolUseCase() =>
    serviceLocator<GetTagNameCodeMapForSchoolUseCase>();

// ── Forbidden types wrapped to return domain values only ─────────────────────
Future<Either<Failure, ConversationEntity>> resolveConversationByCode(
  String conversationCode,
) => serviceLocator<ConversationEntityRepository>().getConversation(
  conversationCode,
);

Future<StaffProfile> resolveStaffProfile({required String staffCode}) =>
    serviceLocator<StaffRepository>().getStaffProfile(staffCode: staffCode);

Future<String?> resolveStoredStaffCode() =>
    serviceLocator<StorageService>().getString(StorageKeys.staffCode);

Future<String?> resolveStoredSchoolCode() =>
    serviceLocator<StorageService>().getString(StorageKeys.schoolCode);

/// The logged-in staff's primary classroom code — wraps the shared scope
/// helper, feeding it the service-located [StorageService] here so callers
/// don't touch storage directly.
Future<String?> resolveStaffPrimaryClassroom({bool forceRefresh = false}) =>
    resolveStaffPrimaryClassroomCode(
      storage: serviceLocator<StorageService>(),
      forceRefresh: forceRefresh,
    );
