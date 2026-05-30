import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/billing/cubit/general_ledger_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_section_card.dart';
import 'package:wowcare/presentation/features/billing/widgets/general_ledger/ledger_card.dart';
import 'package:wowcare/presentation/features/billing/widgets/general_ledger/edit_ledger_screen.dart';
import 'package:wowcare/presentation/features/billing/widgets/general_ledger/models/ledger_account_model.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';

/// UI-only representation of the General Ledger tab.
/// This widget mirrors the structure from the legacy AdminBillingScreen
/// while remaining self-contained until data wiring is available.
class GeneralLedgerSection extends StatefulWidget {
  const GeneralLedgerSection({
    this.ledgerCreationNotifier,
    super.key,
  });

  final ValueNotifier<LedgerAccountModel?>? ledgerCreationNotifier;

  @override
  State<GeneralLedgerSection> createState() => _GeneralLedgerSectionState();
}

class _GeneralLedgerSectionState extends State<GeneralLedgerSection> {
  late final GeneralLedgerCubit _cubit = GeneralLedgerCubit();
  final TextEditingController _searchController = TextEditingController();

  final List<String> _ledgerTypes = const [
    'All Types',
    'General',
    '(Legacy) Subsidy/Agency',
    'Expense Tracking',
  ];

  String? get _selectedType => _cubit.state.selectedType;

  @override
  void initState() {
    super.initState();
    widget.ledgerCreationNotifier?.addListener(_handleLedgerCreated);
  }

  @override
  void didUpdateWidget(covariant GeneralLedgerSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ledgerCreationNotifier != widget.ledgerCreationNotifier) {
      oldWidget.ledgerCreationNotifier?.removeListener(_handleLedgerCreated);
      widget.ledgerCreationNotifier?.addListener(_handleLedgerCreated);
    }
  }

  void _clearFilters() {
    _searchController.clear();
    _cubit.clearFilters();
  }

  void _handleLedgerCreated() {
    final LedgerAccountModel? newLedger = widget.ledgerCreationNotifier?.value;
    if (newLedger == null) return;
    _cubit.addLedger(newLedger);
    widget.ledgerCreationNotifier?.value = null;
  }

  Future<void> _onEditLedger(LedgerAccountModel ledger) async {
    final LedgerAccountModel? updatedLedger = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditLedgerScreen(ledger: ledger),
      ),
    );
    if (updatedLedger == null) return;
    _cubit.updateLedger(updatedLedger);
  }

  void _handleUnavailableAction(String actionLabel) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$actionLabel coming soon'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    widget.ledgerCreationNotifier?.removeListener(_handleLedgerCreated);
    _searchController.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<GeneralLedgerCubit>.value(
      value: _cubit,
      child: BlocBuilder<GeneralLedgerCubit, GeneralLedgerState>(
        builder: (context, state) {
          final ledgers = state.visibleLedgers;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
        CustomSectionCard(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: CustomSearchBar(
                      controller: _searchController,
                      hintText: 'Search Ledger',
                      onChanged: (value) => _cubit.setSearchQuery(value),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CustomClearAllChip(onTap: _clearFilters),
                ],
              ),
              const SizedBox(height: 12),
              CustomDropdown(
                hintText: 'Select Type',
                items: _ledgerTypes,
                selectedItem: _selectedType ?? _ledgerTypes.first,
                onSelect: (value) {
                  _cubit.setType(value == _ledgerTypes.first ? null : value);
                },
              ),
            ],
          ),
        ),
        if (ledgers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Column(
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 56,
                  color: AppColors.primaryColor.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 12),
                Text(
                  'No ledger accounts match the current filters.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.title.copyWith(
                    fontSize: 15,
                    color: AppColors.billingTextColor,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Reset filters'),
                ),
              ],
            ),
          )
        else
          ...ledgers.map(
            (ledger) => LedgerCard(
              ledgerName: ledger.name,
              type: ledger.type,
              openBalance: ledger.openBalance,
              onEdit: () => _onEditLedger(ledger),
              onDelete: () => _handleUnavailableAction('Delete ledger'),
            ),
          ),
            ],
          );
        },
      ),
    );
  }
}

