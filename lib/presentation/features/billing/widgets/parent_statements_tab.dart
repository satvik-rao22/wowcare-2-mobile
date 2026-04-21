import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import '../../../../core/util/safe_state_mixin.dart';

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

class _ParentStatementsTabState extends State<ParentStatementsTab> with SafeStateMixin {

  late DateTime? _customStartDate;
  late DateTime? _customEndDate;
  bool _isStatementsLoading = false;
  bool _isGenerating = false;

  // Demo statements data (UI only)
  List<DemoStatement> get _demoStatements {
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;
    
    return [
      DemoStatement(
        id: 'st_001',
        studentName: 'Lux Stud',
        statementType: 'Yearly',
        generatedOn: DateTime(currentYear, 1, 22),
        periodFrom: DateTime(currentYear, 1, 1),
        periodTo: DateTime(currentYear, 12, 31),
      ),
      DemoStatement(
        id: 'st_002',
        studentName: 'Lux Stud',
        statementType: 'Monthly',
        generatedOn: DateTime(currentYear, currentMonth, 15),
        periodFrom: DateTime(currentYear, currentMonth, 1),
        periodTo: DateTime(currentYear, currentMonth + 1, 0),
      ),
      DemoStatement(
        id: 'st_003',
        studentName: 'Lux Stud',
        statementType: 'Monthly',
        generatedOn: DateTime(currentYear, currentMonth - 1, 20),
        periodFrom: DateTime(currentYear, currentMonth - 1, 1),
        periodTo: DateTime(currentYear, currentMonth, 0),
      ),
      DemoStatement(
        id: 'st_004',
        studentName: 'Lux Stud',
        statementType: 'Quarterly',
        generatedOn: DateTime(currentYear, currentMonth, 10),
        periodFrom: DateTime(currentYear, currentMonth - 2, 1),
        periodTo: DateTime(currentYear, currentMonth, 0),
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _customStartDate = widget.customStartDate;
    _customEndDate = widget.customEndDate;
    
    // Set default dates if not provided
    if (_customStartDate == null || _customEndDate == null) {
      final now = DateTime.now();
      final defaultStart = DateTime(now.year, now.month, 1);
      final defaultEnd = DateTime(now.year, now.month + 1, 0);
      setState(() {
        _customStartDate = defaultStart;
        _customEndDate = defaultEnd;
      });
    }
  }

  @override
  void didUpdateWidget(covariant ParentStatementsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.customStartDate != widget.customStartDate ||
        oldWidget.customEndDate != widget.customEndDate) {
      setState(() {
        _customStartDate = widget.customStartDate;
        _customEndDate = widget.customEndDate;
      });
    }
  }

  Future<void> _refresh() async {
    setState(() => _isStatementsLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _isStatementsLoading = false);
  }

  Future<void> _onGenerate() async {
    setState(() => _isGenerating = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isGenerating = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Statement generated successfully'),
      ),
    );
    // Refresh statements after generation
    await _refresh();
  }

  void _onDateRangeSelected(DateTime startDate, DateTime? endDate) {
    setState(() {
      _customStartDate = startDate;
      _customEndDate = endDate ??
          DateTime(startDate.year, startDate.month, startDate.day, 23, 59, 59);
    });
    // Trigger statements fetch
    _refresh();
  }

  List<DemoStatement> _getFilteredStatements() {
    if (_customStartDate != null && _customEndDate != null) {
      return _demoStatements.where((stmt) {
        // Check if statement period overlaps with selected date range
        // Statement overlaps if: stmt.periodFrom <= selectedEndDate AND stmt.periodTo >= selectedStartDate
        final stmtStart = DateTime(
          stmt.periodFrom.year,
          stmt.periodFrom.month,
          stmt.periodFrom.day,
        );
        final stmtEnd = DateTime(
          stmt.periodTo.year,
          stmt.periodTo.month,
          stmt.periodTo.day,
        );
        final selectedStart = DateTime(
          _customStartDate!.year,
          _customStartDate!.month,
          _customStartDate!.day,
        );
        final selectedEnd = DateTime(
          _customEndDate!.year,
          _customEndDate!.month,
          _customEndDate!.day,
        );
        // Check for overlap: statement period overlaps with selected range
        return stmtStart.isBefore(selectedEnd.add(const Duration(days: 1))) &&
            stmtEnd.isAfter(selectedStart.subtract(const Duration(days: 1)));
      }).toList()
        ..sort((a, b) => b.generatedOn.compareTo(a.generatedOn));
    }
    return List.from(_demoStatements)
      ..sort((a, b) => b.generatedOn.compareTo(a.generatedOn));
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
    final filteredStatements = _getFilteredStatements();
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
              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Center(
                  child: CircularProgressIndicator(),
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
  }
}

