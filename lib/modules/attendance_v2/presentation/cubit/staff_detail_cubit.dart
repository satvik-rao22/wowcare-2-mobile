import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/util/api_error_handler.dart';

import '../../domain/usecases/get_staff_overtime_profile_usecase.dart';
import 'staff_detail_state.dart';

/// Drives the staff attendance & overtime detail screen.
class StaffDetailCubit extends Cubit<StaffDetailState> {
  StaffDetailCubit({required this.getStaffOvertimeProfileUseCase})
      : super(const StaffDetailState.initial());

  final GetStaffOvertimeProfileUseCase getStaffOvertimeProfileUseCase;

  Future<void> load({
    required String staffCode,
    String staffName = '',
    required DateTime from,
    required DateTime to,
  }) async {
    emit(state.copyWith(status: Av2Status.loading, errorMessage: null));
    try {
      final profile = await getStaffOvertimeProfileUseCase(
        staffCode: staffCode,
        staffName: staffName,
        from: from,
        to: to,
      );
      if (isClosed) return;
      emit(state.copyWith(status: Av2Status.loaded, profile: profile));
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: Av2Status.error,
          errorMessage: ApiErrorHandler.extractErrorMessage(e),
        ),
      );
    }
  }
}
