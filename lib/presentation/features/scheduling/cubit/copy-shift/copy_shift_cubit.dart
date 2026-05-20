import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../domain/features/staff_scheduling/copy-shift/domain/copy_shift_params.dart';
import '../../../../../domain/features/staff_scheduling/copy-shift/domain/copy_shift_usecase.dart';
import 'copy_shift_state.dart';

class CopyShiftCubit extends Cubit<CopyShiftState> {
  final CopyShiftUseCase copyShiftUseCase;

  CopyShiftCubit({required this.copyShiftUseCase}) : super(CopyShiftInitial());

  Future<void> copyShift({required CopyShiftParams params}) async {
    try {
      emit(CopyShiftLoading());

      final response = await copyShiftUseCase(params);

      emit(CopyShiftSuccess(response));
    } catch (e) {
      emit(CopyShiftError(e.toString()));
    }
  }
}
