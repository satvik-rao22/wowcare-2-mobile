import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../widgets/general_ledger/models/ledger_account_model.dart';

part 'general_ledger_state.dart';

/// Owns the General Ledger tab's list + filter state. Ledgers are demo data
/// today (see [_seedLedgers]); swap [loadInitial] for a repository call when
/// billing is wired to a backend.
class GeneralLedgerCubit extends Cubit<GeneralLedgerState> {
  GeneralLedgerCubit() : super(GeneralLedgerState.initial());

  static const List<LedgerAccountModel> _seedLedgers = <LedgerAccountModel>[
    LedgerAccountModel(
      id: 'ledger-1',
      name: 'Instructional Supplies',
      type: 'General',
      openBalance: 1850,
      invoiced: 4600,
      received: 3900,
      description: 'Classroom supplies and teaching aids',
    ),
    LedgerAccountModel(
      id: 'ledger-2',
      name: 'Transportation - Agency',
      type: '(Legacy) Subsidy/Agency',
      openBalance: 3250,
      invoiced: 2200,
      received: 1800,
      description: 'Agency managed bus reimbursements',
      isSubsidy: true,
    ),
    LedgerAccountModel(
      id: 'ledger-3',
      name: 'Summer Program Expenses',
      type: 'Expense Tracking',
      openBalance: 900,
      invoiced: 1450,
      received: 1200,
      description: 'Seasonal enrichment program costs',
    ),
    LedgerAccountModel(
      id: 'ledger-4',
      name: 'After School Club',
      type: 'General',
      openBalance: 1325,
      invoiced: 2800,
      received: 1940,
      description: 'Clubs and extracurriculars',
    ),
    LedgerAccountModel(
      id: 'ledger-5',
      name: 'Grant - STEM Initiative',
      type: '(Legacy) Subsidy/Agency',
      openBalance: 5100,
      invoiced: 7200,
      received: 4400,
      description: 'STEM focused public grant',
      isSubsidy: true,
    ),
  ];

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  void setType(String? type) {
    emit(state.copyWith(selectedType: () => type));
  }

  void clearFilters() {
    emit(state.copyWith(searchQuery: '', selectedType: () => null));
  }

  void addLedger(LedgerAccountModel ledger) {
    emit(state.copyWith(
      allLedgers: <LedgerAccountModel>[ledger, ...state.allLedgers],
    ));
  }

  void updateLedger(LedgerAccountModel ledger) {
    final index = state.allLedgers.indexWhere((e) => e.id == ledger.id);
    if (index == -1) return;
    final updated = List<LedgerAccountModel>.from(state.allLedgers);
    updated[index] = ledger;
    emit(state.copyWith(allLedgers: updated));
  }
}
