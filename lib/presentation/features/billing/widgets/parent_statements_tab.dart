import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';

import 'package:wowcare/presentation/features/billing/cubit/parent_statements_cubit.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/presentation/features/billing/widgets/parent_statements_widget.dart';
import 'package:wowcare/presentation/features/billing/widgets/parent_transaction_card.dart';

/// Statements tab widget for parent billing screen
class ParentStatementsTab extends StatefulWidget {
  final List<Map<String, dynamic>> familyChildren;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  const ParentStatementsTab({
    super.key,
    required this.familyChildren,
    this.customStartDate,
    this.customEndDate,
  });

  @override
  State<ParentStatementsTab> createState() => _ParentStatementsTabState();
}

class _ParentStatementsTabState extends State<ParentStatementsTab> {
  late final ParentStatementsCubit _cubit = ParentStatementsCubit();

  // Read-only proxies onto the cubit state.
  DateTime? get _customStartDate => _cubit.state.customStartDate;
  DateTime? get _customEndDate => _cubit.state.customEndDate;
  bool get _isStatementsLoading => _cubit.state.isStatementsLoading;
  bool get _isGenerating => _cubit.state.isGenerating;

  @override
  void initState() {
    super.initState();
    _cubit.initialize(widget.customStartDate, widget.customEndDate);
  }

  @override
  void didUpdateWidget(covariant ParentStatementsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.customStartDate != widget.customStartDate ||
        oldWidget.customEndDate != widget.customEndDate) {
      _cubit.syncDates(widget.customStartDate, widget.customEndDate);
    }
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _refresh() => _cubit.refresh();

  Future<void> _onGenerate() async {
    await _cubit.generate();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Statement generated successfully'),
      ),
    );
    // Refresh statements after generation
    await _cubit.refresh();
  }

  void _onDateRangeSelected(DateTime startDate, DateTime? endDate) {
    _cubit.applyDateRange(startDate, endDate);
  }

  Widget _buildDateFilterCard() {
    return Card(
      elevation: 0,
      color: AppColors.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.primaryColor.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText.label(
                  'Select Date Range',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.billingGreyMedium,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CustomDateTimeField(
              hasLabel: false,
              isRangePicker: true,
              initialDate: _customStartDate,
              label: 'Date Range',
              fetchInitialTime: false,
              onRangeSelected: (start, end) => _onDateRangeSelected(start, end),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ParentStatementsCubit>.value(
      value: _cubit,
      child: BlocBuilder<ParentStatementsCubit, ParentStatementsState>(
        builder: (context, state) {
    final filteredStatements = state.filteredStatements;
    final currentBalance = 0.0; // TODO: Calculate from actual data

    // Convert familyChildren to the format expected by ParentStatementsWidget
    final formattedChildren = widget.familyChildren.map((child) {
      return {
        'name': child['name'] ?? child['fullName'] ?? 'Unknown',
        'fullName': child['name'] ?? child['fullName'] ?? 'Unknown',
        'room': child['room'] ?? child['roomName'] ?? '',
        'roomName': child['room'] ?? child['roomName'] ?? '',
      };
    }).toList();

    return CustomRefreshIndicator(
      onRefresh: _refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                children: [
                  AppText.title('Statements'),
                ],
              ),
            ),
            // Sibling cards and balance - matching billing tab structure
            Column(
              children: [
                ParentStatementsWidget(
                  isLoading: _isGenerating,
                  familyChildren: formattedChildren,
                  currentBalance: currentBalance,
                  onGenerate: _onGenerate,
                ),
                const SizedBox(height: 15),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: _buildDateFilterCard(),
                ),
              ],
            ),
            const SizedBox(height: 15),
            // Statements list
            if (_isStatementsLoading)
              Column(
                children: List.generate(
                  5,
                  (_) => const BillingTransactionShimmer(),
                ),
              )
            else if (filteredStatements.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 48,
                        color: AppColors.primaryColor.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      AppText.value('No statements found'),
                      const SizedBox(height: 8),
                      Text(
                        _customStartDate != null && _customEndDate != null
                            ? 'No statements available for the selected date range'
                            : 'No statements available',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primaryColor.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  children: filteredStatements.map(
                    (statement) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ParentStatementCard(statement: statement),
                    ),
                  ).toList(),
                ),
              ),
          ],
        ),
      ),
    );
        },
      ),
    );
  }
}

