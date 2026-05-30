part of 'transaction_card_cubit.dart';

class TransactionCardState extends Equatable {
  const TransactionCardState({
    required this.isExpanded,
    required this.localSelected,
  });

  final bool isExpanded;
  final bool localSelected;

  TransactionCardState copyWith({bool? isExpanded, bool? localSelected}) {
    return TransactionCardState(
      isExpanded: isExpanded ?? this.isExpanded,
      localSelected: localSelected ?? this.localSelected,
    );
  }

  @override
  List<Object?> get props => [isExpanded, localSelected];
}
