import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/presentation/features/billing/widgets/parent_statements_widget.dart';
import 'package:wowcare/presentation/features/billing/widgets/parent_statement_card.dart';

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
  late DateTime? _customStartDate;
  late DateTime? _customEndDate;
  bool _isStatementsLoading = false;
  bool _isGenerating = false;

  // Demo statements data (UI only)
  final List<DemoStatement> _demoStatements = [
    DemoStatement(
      id: '1',
      statementType: 'Monthly',
      statementDate: DateTime.now().subtract(const Duration(days: 5)),
      periodStartDate: DateTime(2024, 1, 1),
      periodEndDate: DateTime(2024, 1, 31),
      studentName: 'Emma Johnson',
    ),
    DemoStatement(
      id: '2',
      statementType: 'Quarterly',
      statementDate: DateTime.now().subtract(const Duration(days: 15)),
      periodStartDate: DateTime(2023, 10, 1),
      periodEndDate: DateTime(2023, 12, 31),
      studentName: 'Liam Johnson',
    ),
    DemoStatement(
      id: '3',
      statementType: 'Monthly',
      statementDate: DateTime.now().subtract(const Duration(days: 30)),
      periodStartDate: DateTime(2023, 12, 1),
      periodEndDate: DateTime(2023, 12, 31),
      studentName: 'Olivia Johnson',
    ),
  ];

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
        final stmtDate = DateTime(
          stmt.periodStartDate.year,
          stmt.periodStartDate.month,
          stmt.periodStartDate.day,
        );
        final start = DateTime(
          _customStartDate!.year,
          _customStartDate!.month,
          _customStartDate!.day,
        );
        final end = DateTime(
          _customEndDate!.year,
          _customEndDate!.month,
          _customEndDate!.day,
        );
        return (stmtDate.isAtSameMomentAs(start) || stmtDate.isAfter(start)) &&
            (stmtDate.isAtSameMomentAs(end) || stmtDate.isBefore(end));
      }).toList()
        ..sort((a, b) => b.statementDate.compareTo(a.statementDate));
    }
    return List.from(_demoStatements)
      ..sort((a, b) => b.statementDate.compareTo(a.statementDate));
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
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          AppText.title(
            'Statements',
            style: AppTextStyles.title.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          ParentStatementsWidget(
            isLoading: _isGenerating,
            familyChildren: formattedChildren,
            currentBalance: currentBalance,
            onGenerate: _onGenerate,
          ),
          const SizedBox(height: 16),
          _buildDateFilterCard(),
          const SizedBox(height: 30),
          // Statements list
          if (_isStatementsLoading)
            const Padding(
              padding: EdgeInsets.all(16),
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
            ...filteredStatements.map(
              (statement) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: ParentStatementCard(statement: statement),
              ),
            ),
        ],
      ),
    );
  }
}

