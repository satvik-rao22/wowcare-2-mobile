import 'dart:convert';

import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/attendance_classroom_scope.dart';
import 'package:wowcare/core/utils/staff_code_resolver.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';

/// Staff newsletter list scope: allowed classrooms + primary classroom minimum filter.
class NewsletterStaffScope {
  const NewsletterStaffScope({
    required this.isScoped,
    this.primaryClassroomCode,
    this.allowedClassroomCodes = const <String>[],
  });

  final bool isScoped;
  final String? primaryClassroomCode;
  final List<String> allowedClassroomCodes;
}

Future<NewsletterStaffScope> resolveNewsletterStaffScope({
  StorageService? storage,
}) async {
  final resolvedStorage = storage ?? serviceLocator<StorageService>();
  final isScoped = await isAttendanceScopedStaffPersona(
    storage: resolvedStorage,
  );
  if (!isScoped) {
    return const NewsletterStaffScope(isScoped: false);
  }

  List<String> decodeCodes(String raw) {
    if (raw.trim().isEmpty) return <String>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    } catch (_) {}
    return <String>[];
  }

  var allowed = decodeCodes(
    (await resolvedStorage.getString(StorageKeys.staffAllowedClassroomCodes) ??
            '')
        .trim(),
  );
  String? primary;

  try {
    final staffCode = (await resolveStaffCodeForLoggedInUser()).trim();
    if (staffCode.isNotEmpty) {
      final profile = await serviceLocator<StaffRepository>().getStaffProfile(
        staffCode: staffCode,
        forEditStaff: true,
      );
      final profileAllowed = profile.allowedClassroomCodes
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (profileAllowed.isNotEmpty) {
        allowed = profileAllowed;
        await resolvedStorage.saveString(
          StorageKeys.staffAllowedClassroomCodes,
          jsonEncode(profileAllowed),
        );
      }
      final profilePrimary = profile.primaryClassroomCode.trim();
      if (profilePrimary.isNotEmpty) {
        primary = profilePrimary;
      }
    }
  } catch (_) {
    // Fall back to cached allowed codes.
  }

  if (primary == null && allowed.isNotEmpty) {
    primary = allowed.first;
  }

  return NewsletterStaffScope(
    isScoped: true,
    primaryClassroomCode: primary,
    allowedClassroomCodes: allowed,
  );
}
