import 'package:flutter/material.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/date_utils.dart';
import 'package:wowcare/domain/features/billing/entities/billing_statement_entity.dart';
import 'package:wowcare/presentation/features/billing/cubit/admin_statements_cubit.dart';
import 'package:wowcare/presentation/features/billing/model/billing_family_member.dart';
import 'package:wowcare/presentation/features/billing/widgets/staff_style_card.dart';
import 'package:wowcare/presentation/features/reports/view/report_file_viewer_screen.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

class AdminStatementsTab extends StatefulWidget {
  const AdminStatementsTab({
    super.key,
    required this.cubit,
    required this.ownerCode,
    required this.familyChildren,
    this.customStartDate,
    this.customEndDate,
  });

  final AdminStatementsCubit cubit;
  final String ownerCode;
  final List<BillingFamilyMember> familyChildren;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  @override
  State<AdminStatementsTab> createState() => _AdminStatementsTabState();
}

class _AdminStatementsTabState extends State<AdminStatementsTab> {
  @override
  void initState() {
    super.initState();
    widget.cubit.load(widget.ownerCode);
  }

  @override
  void didUpdateWidget(covariant AdminStatementsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ownerCode != widget.ownerCode) {
      widget.cubit.load(widget.ownerCode);
    }
    if (oldWidget.customStartDate != widget.customStartDate ||
        oldWidget.customEndDate != widget.customEndDate) {
      widget.cubit.applyDateRange(widget.customStartDate, widget.customEndDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminStatementsCubit>.value(
      value: widget.cubit,
      child: BlocBuilder<AdminStatementsCubit, AdminStatementsState>(
        builder: (context, state) {
          return CustomRefreshIndicator(
            onRefresh: widget.cubit.refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: AppText.title('Statements'),
                  ),
                  if (widget.familyChildren.isNotEmpty)
                    _FamilySiblingsCard(children: widget.familyChildren),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _DateFilterCard(cubit: widget.cubit, state: state),
                  ),
                  const SizedBox(height: 12),
                  _buildBody(state),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(AdminStatementsState state) {
    if (state.isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: List.generate(
            5,
            (_) => const BillingTransactionShimmer(),
          ),
        ),
      );
    }
    if (state.errorMessage.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.error_outline,
                  size: 40, color: AppColors.billingErrorIconColor),
              const SizedBox(height: 12),
              Text(
                state.errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.billingErrorTextColor),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => widget.cubit.refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    final items = state.filteredStatements;
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.description_outlined,
                  size: 48,
                  color: AppColors.primaryColor.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              const AppText.value('No statements found'),
            ],
          ),
        ),
      );
    }
    final studentNames = widget.familyChildren
        .map((c) => (c.fullName ?? c.name ?? '').toString())
        .where((n) => n.isNotEmpty)
        .join(', ');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: items
            .map((s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: _AdminStatementCard(
                    statement: s,
                    studentNames: studentNames,
                    isDownloading: state.isDownloading(s.code),
                    onDownload: () => _handleDownload(s),
                    onView: () => _handleView(s),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Future<void> _handleDownload(BillingStatementEntity statement) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Downloading statement PDF…'),
        duration: Duration(seconds: 2),
      ),
    );
    final error = await widget.cubit.downloadStatement(statement);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  /// Opens an in-app PDF preview instead of saving/handing off to an
  /// external viewer (that's what Download is for).
  Future<void> _handleView(BillingStatementEntity statement) async {
    final result = await widget.cubit.fetchStatementForPreview(statement);
    if (!mounted) return;
    final bytes = result.bytes;
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Unable to preview this statement.'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReportFileViewerScreen(
          fileData: bytes,
          fileName: 'statement-${statement.code}.pdf',
          fileType: 'pdf',
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Siblings summary card (read-only, no payment buttons)
// ─────────────────────────────────────────────────────────────────────────────

class _FamilySiblingsCard extends StatelessWidget {
  const _FamilySiblingsCard({required this.children});

  final List<BillingFamilyMember> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorderColor),
        ),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: children.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 20,
            mainAxisSpacing: 12,
            childAspectRatio: 3.5,
          ),
          itemBuilder: (context, index) {
            final child = children[index];
            final name =
                (child.fullName ?? child.name ?? '').toString();
            final room =
                (child.room ?? child.roomName ?? '').toString();
            return Row(
              children: [
                DocumentImageWidget(
                  fileUuid: '',
                  name: name,
                  size: 50,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.value(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.value.copyWith(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      if (room.isNotEmpty)
                        AppText.value(
                          room,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.value.copyWith(
                            fontSize: 11,
                            color: AppColors.primaryColor.withValues(alpha: 0.7),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Date filter card
// ─────────────────────────────────────────────────────────────────────────────

class _DateFilterCard extends StatelessWidget {
  const _DateFilterCard({required this.cubit, required this.state});

  final AdminStatementsCubit cubit;
  final AdminStatementsState state;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primaryColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: AppText.label(
              'Select Date Range',
              style: AppTextStyles.label.copyWith(
                color: AppColors.billingGreyMedium,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: CustomDateTimeField(
              hasLabel: false,
              isRangePicker: true,
              initialDate: state.customStartDate,
              label: 'Date Range',
              fetchInitialTime: false,
              onRangeSelected: (start, end) =>
                  cubit.applyDateRange(start, end),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual statement card
// ─────────────────────────────────────────────────────────────────────────────

class _AdminStatementCard extends StatelessWidget {
  const _AdminStatementCard({
    required this.statement,
    required this.studentNames,
    required this.isDownloading,
    required this.onDownload,
    required this.onView,
  });

  final BillingStatementEntity statement;
  final String studentNames;
  final bool isDownloading;
  final VoidCallback onDownload;
  final VoidCallback onView;

  String get _formattedType =>
      statement.statementType.isEmpty
          ? '—'
          : statement.statementType[0].toUpperCase() +
              statement.statementType.substring(1).toLowerCase();

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper(context).isTabletCompact;
    final statementDate = statement.generatedAt;

    return StaffStyleCard(
      leading: DocumentImageWidget(
        fileUuid: '',
        name: _formattedType,
        size: 50,
      ),
      header: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              statementDate != null
                  ? DateUtilsNew.formatToReadableDate(statementDate)
                  : '—',
              style: BillingCardText.name(isTablet),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          _StatusBadge(status: statement.status),
        ],
      ),
      expandedChildren: [
        StaffCardDetailRow(
          label: 'Statement Type',
          value: _formattedType,
        ),
        const SizedBox(height: 10),
        StaffCardDetailRow(
          label: 'Generated On',
          value: statementDate != null
              ? DateUtilsNew.formatToReadableDate(statementDate)
              : '—',
        ),
        const SizedBox(height: 10),
        StaffCardDetailRow(
          label: 'Period Start',
          value: DateUtilsNew.formatToReadableDate(statement.periodStart),
        ),
        const SizedBox(height: 10),
        StaffCardDetailRow(
          label: 'Period End',
          value: DateUtilsNew.formatToReadableDate(statement.periodEnd),
        ),
        const SizedBox(height: 10),
        StaffCardDetailRow(
          label: 'Student Names',
          value: studentNames.isNotEmpty ? studentNames : '—',
        ),
        const SizedBox(height: 16),
        StaffCardActions(
          // Both actions share the same fetch-in-flight flag (there's only
          // ever one request per statement at a time), so the label stays
          // generic rather than claiming "Downloading…" while a View fetch
          // is actually what's in flight.
          secondaryLabel: isDownloading ? 'Loading…' : 'View',
          onSecondary: isDownloading ? null : onView,
          primaryLabel: isDownloading ? 'Loading…' : 'Download',
          onPrimary: isDownloading ? null : onDownload,
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  Color get _color {
    switch (status.toUpperCase()) {
      case 'GENERATED':
      case 'SENT':
        return AppColors.billingPaymentBadgeColor;
      default:
        return AppColors.billingGreyMedium;
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = status.isEmpty
        ? 'Statement'
        : status[0].toUpperCase() + status.substring(1).toLowerCase();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: BillingCardText.label.copyWith(
          color: AppColors.secondaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
