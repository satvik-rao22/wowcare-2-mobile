import '../../../../../domain/features/staff_scheduling/copy-shift/domain/copy_shift_response.dart';

abstract class CopyShiftState {}

class CopyShiftInitial extends CopyShiftState {}

class CopyShiftLoading extends CopyShiftState {}

class CopyShiftSuccess extends CopyShiftState {
  final CopyShiftResponse response;

  CopyShiftSuccess(this.response);
}

class CopyShiftError extends CopyShiftState {
  final String message;

  CopyShiftError(this.message);
}
