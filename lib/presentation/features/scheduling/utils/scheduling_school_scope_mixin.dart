import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/school_code_resolver.dart';
import 'package:wowcare/core/util/storage_keys.dart';

/// Shared, per-instance-memoized org/school code resolution for the
/// scheduling cubits.
///
/// Was previously copy-pasted verbatim across [SchedulingCubit],
/// [SchedulingStaffListCubit] and [StaffSchedulingCubit] as a naive
/// `_storageService.getString(StorageKeys.schoolCode) ?? ''` — which returns
/// the literal `'-'` placeholder [StorageKeys.schoolCode] holds for
/// organization-level personas (no single school selected), instead of
/// resolving a concrete school the way [resolveLoggedInSchoolCode] (already
/// relied on elsewhere in the app for this exact ambiguity) does. Consuming
/// it here fixes that same latent gap for scheduling, not just deduplicates.
mixin SchedulingSchoolScopeMixin {
  StorageService get storageService;

  String? _schoolCode;
  String? _organizationCode;

  Future<String> resolveSchoolCode() async {
    if (_schoolCode != null) return _schoolCode!;
    _schoolCode = await resolveLoggedInSchoolCode(storageService);
    return _schoolCode!;
  }

  Future<String> resolveOrganizationCode() async {
    if (_organizationCode != null) return _organizationCode!;
    _organizationCode =
        (await storageService.getString(StorageKeys.organizationCode)) ?? '';
    return _organizationCode!;
  }
}
