import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';

part 'incident_activity_state.dart';

/// ViewModel for the Incident screen's persona-detection/guardian-signature
/// data reads — the storage lookups and staff-name resolution that used to
/// be resolved directly via `serviceLocator` inside the View. Each method
/// here is a narrow, 1:1 stand-in for one of those direct calls (same
/// trimming, same fallback shape) — the View still owns how the values get
/// combined into persona/signature decisions, since that sequencing is
/// tightly interleaved with the form's own `setState`-driven UI state on
/// this legal/signature-record screen.
class IncidentActivityCubit extends Cubit<IncidentActivityState> {
  IncidentActivityCubit({
    required StorageService storageService,
    required StaffRepository staffRepository,
  }) : _storageService = storageService,
       _staffRepository = staffRepository,
       super(const IncidentActivityState());

  final StorageService _storageService;
  final StaffRepository _staffRepository;

  Future<String> readRoles() async =>
      (await _storageService.getString(StorageKeys.roles) ?? '').trim();

  Future<String> readGuardianCode() async =>
      (await _storageService.getString(StorageKeys.guardianCode) ?? '').trim();

  Future<String> readSchoolCode() async =>
      (await _storageService.getString(StorageKeys.schoolCode) ?? '').trim();

  Future<String> readStaffType() async =>
      (await _storageService.getString(StorageKeys.staffType) ?? '').trim();

  Future<String> readOrganizationCode() async =>
      (await _storageService.getString(StorageKeys.organizationCode) ?? '')
          .trim();

  /// Resolves display names for staff codes not already known to the caller.
  /// A code that fails to resolve (network error, unknown code) is simply
  /// omitted from the result — best-effort, matching the original inline
  /// behaviour this replaces.
  Future<Map<String, String>> resolveStaffDisplayNames(
    Iterable<String> staffCodes,
  ) async {
    final result = <String, String>{};
    await Future.wait(
      staffCodes.map((code) async {
        try {
          final profile = await _staffRepository.getStaffProfile(
            staffCode: code,
          );
          final full = profile.fullName.trim();
          final composed = '${profile.firstName} ${profile.lastName}'.trim();
          final resolved = full.isNotEmpty ? full : composed;
          if (resolved.isNotEmpty) result[code] = resolved;
        } catch (_) {}
      }),
    );
    return result;
  }
}
