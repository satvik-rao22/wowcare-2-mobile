import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/domain/features/scheduling/repositories/staff_shift_repository.dart';
import 'package:wowcare/domain/features/scheduling/usecases/bootstrap_scheduling_school_timezone_usecase.dart';
import 'package:wowcare/domain/features/scheduling/usecases/publish_staff_shifts_usecase.dart';
import 'package:wowcare/presentation/features/scheduling/view_model/publish_shifts_cubit.dart';

class _UnusedStorage implements StorageService {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _UnusedApiClient implements ApiClient {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _UnusedShiftRepo implements StaffShiftRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

/// Stubbed so [PublishShiftsCubit.init]'s fire-and-forget timezone warm-up
/// doesn't reach the network from a unit test.
class _FakeBootstrapTimezoneUseCase
    extends BootstrapSchedulingSchoolTimezoneUseCase {
  _FakeBootstrapTimezoneUseCase()
      : super(storage: _UnusedStorage(), apiClient: _UnusedApiClient());

  @override
  Future<String> call() async => 'UTC';
}

void main() {
  PublishShiftsCubit buildCubit() => PublishShiftsCubit(
        publishStaffShiftsUseCase: PublishStaffShiftsUseCase(
          _UnusedShiftRepo(),
        ),
        storageService: _UnusedStorage(),
        bootstrapSchedulingSchoolTimezoneUseCase:
            _FakeBootstrapTimezoneUseCase(),
      );

  test('init leaves the staff selection empty', () {
    final cubit = buildCubit();
    addTearDown(cubit.close);

    cubit.init(initialUntilDate: DateTime(2026, 9, 10));

    expect(cubit.state.selectedStaffCodes, isEmpty);
    expect(cubit.state.untilDate, DateTime(2026, 9, 10));
  });

  test('Publish stays disabled until the user picks a staff member', () {
    final cubit = buildCubit();
    addTearDown(cubit.close);

    cubit.init(initialUntilDate: DateTime(2026, 9, 10));
    cubit.selectMode(PublishMode.untilDate);

    // Mode + date are set, but nobody is selected yet.
    expect(cubit.state.isFormValid, isFalse);

    cubit.setSelectedStaffCodes(const <String>['STF-1']);
    expect(cubit.state.isFormValid, isTrue);
  });
}
