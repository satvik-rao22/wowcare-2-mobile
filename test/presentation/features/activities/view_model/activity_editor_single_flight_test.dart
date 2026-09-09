import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/activity/entities/activity_attachment.dart';
import 'package:wowcare/domain/features/activity/entities/activity_parameter_value.dart';
import 'package:wowcare/domain/features/activity/repositories/activity_repository.dart';
import 'package:wowcare/domain/features/activity/usecases/approve_activity_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/create_activity_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/create_shared_activities_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/get_activity_type_details_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/get_activity_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/get_classroom_activity_settings_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/guardian_parent_signature_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/reject_activity_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/update_activity_usecase.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_sign_in_status_at_time_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_today_sign_in_status_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_sign_in_status_at_time_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_today_sign_in_status_map_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/wait_activity_assets_ready_usecase.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/get_guardian_name_code_map_for_school_usecase.dart';
import 'package:wowcare/presentation/features/activities/view_model/activity_editor_cubit.dart';
import 'package:wowcare/domain/features/activity/repositories/activity_media_upload_repository.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/domain/features/staff/usecases/get_staff_page_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/upload_activity_assets_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/get_activity_upload_asset_statuses_usecase.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';

class _LoudActivityRepo implements ActivityRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _LoudStudentRepo implements StudentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _LoudAttendanceRepo implements AttendanceRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _LoudStaffRepo implements StaffRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _LoudMediaUploadRepo implements ActivityMediaUploadRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _LoudApiClient implements ApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _FakeStorage implements StorageService {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

/// Counts invocations and gates the result so we can hold two calls concurrent.
class _GatedCreateUseCase extends CreateActivityUseCase {
  _GatedCreateUseCase() : super(_LoudActivityRepo());
  int calls = 0;
  final Completer<String> gate = Completer<String>();

  @override
  Future<String> call({
    required String activityTypeCode,
    required String classroomCode,
    required List<String> studentCodes,
    required String staffCode,
    required String schoolCode,
    required String organizationCode,
    required String activityDate,
    required String description,
    bool? napStart,
    bool? napEnd,
    bool? napReminderEnabled,
    String? napReminderUserCode,
    String? napReminderRole,
    bool? requireAdminApproval,
    List<ActivityParameterValue> parameterValues = const [],
    List<ActivityAttachment> attachments = const [],
  }) {
    calls++;
    return gate.future;
  }
}

ActivityEditorCubit _buildCubit(CreateActivityUseCase create) {
  final act = _LoudActivityRepo();
  return ActivityEditorCubit(
    getClassroomActivitySettingsUseCase:
        GetClassroomActivitySettingsUseCase(act),
    getActivityTypeDetailsUseCase: GetActivityTypeDetailsUseCase(act),
    createActivityUseCase: create,
    getActivityUseCase: GetActivityUseCase(act),
    updateActivityUseCase: UpdateActivityUseCase(act),
    approveActivityUseCase: ApproveActivityUseCase(act),
    rejectActivityUseCase: RejectActivityUseCase(act),
    createSharedActivitiesUseCase: CreateSharedActivitiesUseCase(act),
    guardianParentSignatureUseCase: GuardianParentSignatureUseCase(act),
    getGuardianNameCodeMapForSchoolUseCase:
        GetGuardianNameCodeMapForSchoolUseCase(_LoudStudentRepo()),
    getStaffTodaySignInStatusUseCase:
        GetStaffTodaySignInStatusUseCase(_LoudAttendanceRepo()),
    getStaffSignInStatusAtTimeUseCase:
        GetStaffSignInStatusAtTimeUseCase(_LoudAttendanceRepo()),
    getStudentSignInStatusAtTimeUseCase:
        GetStudentSignInStatusAtTimeUseCase(_LoudAttendanceRepo()),
    getStudentTodaySignInStatusMapUseCase:
        GetStudentTodaySignInStatusMapUseCase(_LoudAttendanceRepo()),
    waitActivityAssetsReadyUseCase:
        WaitActivityAssetsReadyUseCase(_LoudMediaUploadRepo()),
    storageService: _FakeStorage(),
    uploadActivityAssetsUseCase: UploadActivityAssetsUseCase(_LoudMediaUploadRepo()),
    getActivityUploadAssetStatusesUseCase:
        GetActivityUploadAssetStatusesUseCase(_LoudMediaUploadRepo()),
    apiClient: _LoudApiClient(),
    staffRepository: _LoudStaffRepo(),
    getStaffPageUseCase: GetStaffPageUseCase(_LoudStaffRepo()),
  );
}

Future<String> _create(ActivityEditorCubit c) => c.createActivity(
  activityTypeCode: 'T',
  classroomCode: 'C',
  studentCodes: const ['STU-1'],
  staffCode: 'STAFF-1',
  schoolCode: 'SCH-1',
  organizationCode: 'ORG-1',
  activityDate: '2026-01-01T00:00:00Z',
  description: 'd',
);

void main() {
  test(
    'two concurrent identical createActivity calls are coalesced into ONE '
    'underlying create; both callers get the same result',
    () async {
      final create = _GatedCreateUseCase();
      final cubit = _buildCubit(create);

      final f1 = _create(cubit);
      final f2 = _create(cubit); // fired while f1 is still in flight

      await Future<void>.delayed(Duration.zero);
      expect(create.calls, 1); // only ONE create dispatched

      create.gate.complete('created');
      expect(await f1, 'created');
      expect(await f2, 'created');

      // After completion the key is released — a later submit dispatches again.
      final create2 = _GatedCreateUseCase();
      final cubit2 = _buildCubit(create2);
      final g1 = _create(cubit2);
      await Future<void>.delayed(Duration.zero);
      create2.gate.complete('ok');
      await g1;
      _create(cubit2); // sequential, not concurrent
      await Future<void>.delayed(Duration.zero);
      expect(create2.calls, 2);
      await cubit.close();
      await cubit2.close();
    },
  );
}
