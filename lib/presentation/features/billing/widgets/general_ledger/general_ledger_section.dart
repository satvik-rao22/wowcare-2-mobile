import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
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
  _GeneralLedgerSectionState()
      : _allLedgers = List<LedgerAccountModel>.from(_seedLedgers);

  final TextEditingController _searchController = TextEditingController();
  final List<LedgerAccountModel> _allLedgers;

  static const List<LedgerAccountModel> _seedLedgers =
      <LedgerAccountModel>[
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

  final List<String> _ledgerTypes = const [
    'All Types',
    'General',
    '(Legacy) Subsidy/Agency',
    'Expense Tracking',
  ];

  String? _selectedType;

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

  @override
  void reassemble() {
    super.reassemble();
    if (_allLedgers.isNotEmpty &&
        _allLedgers.first.runtimeType.toString() == '_LedgerAccount') {
      _allLedgers
        ..clear()
        ..addAll(_seedLedgers);
      setState(() {});
    }
  }

  List<LedgerAccountModel> get _visibleLedgers {
    final String query = _searchController.text.trim().toLowerCase();
    return _allLedgers.where((ledger) {
      final matchesQuery =
          query.isEmpty || ledger.name.toLowerCase().contains(query);
      final matchesType =
          _selectedType == null || _selectedType == 'All Types'
              ? true
              : ledger.type == _selectedType;
      return matchesQuery && matchesType;
    }).toList();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedType = null;
    });
  }

  void _handleLedgerCreated() {
    final LedgerAccountModel? newLedger =
        widget.ledgerCreationNotifier?.value;
    if (newLedger == null) {
      return;
    }

    setState(() {
      _allLedgers.insert(0, newLedger);
    });
    widget.ledgerCreationNotifier?.value = null;
  }

  Future<void> _onEditLedger(LedgerAccountModel ledger) async {
    final LedgerAccountModel? updatedLedger = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditLedgerScreen(ledger: ledger),
      ),
    );

    if (updatedLedger == null) return;

    final int index =
        _allLedgers.indexWhere((element) => element.id == updatedLedger.id);
    if (index == -1) return;

    setState(() {
      _allLedgers[index] = updatedLedger;
    });
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ledgers = _visibleLedgers;
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
                      onChanged: (_) => setState(() {}),
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
                  setState(() {
                    _selectedType = value == _ledgerTypes.first ? null : value;
                  });
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
  }
}

