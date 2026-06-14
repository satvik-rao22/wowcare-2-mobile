import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'transaction_card_state.dart';

/// Small cubit for a billing transaction card's local UI flags: expand/collapse
/// and (when the card manages its own selection) the checkbox value.
class TransactionCardCubit extends Cubit<TransactionCardState> {
  TransactionCardCubit({bool initialSelected = false})
      : super(TransactionCardState(isExpanded: false, localSelected: initialSelected));

  void toggleExpanded() =>
      emit(state.copyWith(isExpanded: !state.isExpanded));

  void setSelected(bool value) {
    if (state.localSelected == value) return;
    emit(state.copyWith(localSelected: value));
  }
}
