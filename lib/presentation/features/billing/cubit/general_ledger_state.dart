part of 'general_ledger_cubit.dart';

class GeneralLedgerState extends Equatable {
  const GeneralLedgerState({
    required this.allLedgers,
    required this.selectedType,
    required this.searchQuery,
  });

  GeneralLedgerState.initial()
      : allLedgers = List<LedgerAccountModel>.from(
          GeneralLedgerCubit._seedLedgers,
        ),
        selectedType = null,
        searchQuery = '';

  final List<LedgerAccountModel> allLedgers;
  final String? selectedType;
  final String searchQuery;

  /// Ledgers filtered by the active search query + type.
  List<LedgerAccountModel> get visibleLedgers {
    final query = searchQuery.trim().toLowerCase();
    return allLedgers.where((ledger) {
      final matchesQuery =
          query.isEmpty || ledger.name.toLowerCase().contains(query);
      final matchesType = selectedType == null || selectedType == 'All Types'
          ? true
          : ledger.type == selectedType;
      return matchesQuery && matchesType;
    }).toList();
  }

  /// [selectedType] is passed as a getter so callers can explicitly set it to
  /// null (clearing the filter).
  GeneralLedgerState copyWith({
    List<LedgerAccountModel>? allLedgers,
    String? Function()? selectedType,
    String? searchQuery,
  }) {
    return GeneralLedgerState(
      allLedgers: allLedgers ?? this.allLedgers,
      selectedType: selectedType != null ? selectedType() : this.selectedType,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [allLedgers, selectedType, searchQuery];
}
