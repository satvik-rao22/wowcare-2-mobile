part of 'transactions_cubit.dart';

class TransactionsState extends Equatable {
  const TransactionsState({
    required this.transactions,
    required this.searchQuery,
  });

  TransactionsState.initial()
      : transactions = TransactionsCubit.seedTransactions(),
        searchQuery = '';

  final List<TransactionRecord> transactions;
  final String searchQuery;

  List<TransactionRecord> get visibleTransactions {
    final query = searchQuery.trim().toLowerCase();
    return transactions.where((record) {
      final item = record.item;
      return query.isEmpty ||
          item.studentName.toLowerCase().contains(query) ||
          item.id.toString().contains(query) ||
          item.description.toLowerCase().contains(query);
    }).toList();
  }

  double totalAmountFor(Set<TransactionStatus> statuses) => transactions
      .where((record) => statuses.contains(record.status))
      .fold<double>(0, (sum, record) => sum + record.item.amount);

  double _percentage(double value, double total) =>
      total <= 0 ? 0 : (value / total) * 100;

  double get totalInvoiced => totalAmountFor(<TransactionStatus>{
        TransactionStatus.paid,
        TransactionStatus.inProcess,
        TransactionStatus.unpaid,
      });

  double get paidPercent =>
      _percentage(totalAmountFor(<TransactionStatus>{TransactionStatus.paid}),
          totalInvoiced);
  double get inProcessPercent => _percentage(
      totalAmountFor(<TransactionStatus>{TransactionStatus.inProcess}),
      totalInvoiced);
  double get unpaidPercent => _percentage(
      totalAmountFor(<TransactionStatus>{TransactionStatus.unpaid}),
      totalInvoiced);
  double get refundPercent => _percentage(
      totalAmountFor(<TransactionStatus>{TransactionStatus.refund}),
      totalInvoiced);

  TransactionsState copyWith({
    List<TransactionRecord>? transactions,
    String? searchQuery,
  }) {
    return TransactionsState(
      transactions: transactions ?? this.transactions,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [transactions, searchQuery];
}
