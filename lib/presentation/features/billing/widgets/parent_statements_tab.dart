import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/router/app_routes.dart';
import 'package:wowcare/presentation/features/billing/model/billing_route_args.dart';
import 'package:wowcare/presentation/features/reports/model/report_route_args.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/billing/billing_strings.dart';
import 'package:wowcare/domain/features/billing/entities/billing_statement_entity.dart';
import 'package:wowcare/presentation/features/billing/view_model/admin_statements_cubit.dart';
import 'package:wowcare/presentation/features/billing/model/billing_family_member.dart';
import 'package:wowcare/presentation/features/billing/view_model/parent_statements_cubit.dart';
import 'package:wowcare/presentation/features/billing/view/generate_statement_screen.dart';
import 'package:wowcare/presentation/features/billing/widgets/parent_statements_widget.dart';
import 'package:wowcare/presentation/features/billing/widgets/parent_transaction_card.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';

/// Statements tab widget for parent billing screen.
///
/// [subscriberCode] is the guardian's owner code, used as the statement
/// subscriber when generating.  [ownerType] is the ledger owner type
/// (e.g. 'GUARDIAN').  [familyChildren] must contain the guardian's own
/// children only — each map requires a `'code'` key.
class ParentStatementsTab extends StatefulWidget {
  final List<BillingFamilyMember> familyChildren;
  final String subscriberCode;
  final String ownerType;

  /// The family's current open balance, shown alongside the Generate button —
  /// mirrors the value on the parent Billing tab.
  final double currentBalance;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  const ParentStatementsTab({
    super.key,
    required this.familyChildren,
    required this.subscriberCode,
    required this.ownerType,
    this.currentBalance = 0,
    this.customStartDate,
    this.customEndDate,
  });

  @override
  State<ParentStatementsTab> createState() => _ParentStatementsTabState();
}

class _ParentStatementsTabState extends State<ParentStatementsTab> {
  late final ParentStatementsCubit _cubit =
      serviceLocator<ParentStatementsCubit>();
  final ScrollController _scrollController = ScrollController();

  DateTime? get _customStartDate => _cubit.state.customStartDate;
  DateTime? get _customEndDate => _cubit.state.customEndDate;
  bool get _isStatementsLoading => _cubit.state.isStatementsLoading;
  bool get _isGenerating => _cubit.state.isGenerating;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _cubit.initialize(widget.customStartDate, widget.customEndDate);
    _cubit.load(widget.subscriberCode);
  }

  @override
  void didUpdateWidget(covariant ParentStatementsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subscriberCode != widget.subscriberCode) {
      _cubit.load(widget.subscriberCode);
    }
    if (oldWidget.customStartDate != widget.customStartDate ||
        oldWidget.customEndDate != widget.customEndDate) {
      _cubit.syncDates(widget.customStartDate, widget.customEndDate);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.maxScrollExtent <= 0) {
      _cubit.loadNextPage();
      return;
    }
    if (pos.pixels >= pos.maxScrollExtent - 400) {
      _cubit.loadNextPage();
    }
  }

  void _maybeLoadNextPage() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.maxScrollExtent <= 0 && _cubit.state.hasMoreStatements) {
      _cubit.loadNextPage();
    }
  }

  Future<void> _refresh() => _cubit.refresh();

  /// Opens the Generate Statement form (same UI as the admin persona).
  /// The family children list is scoped to this guardian's students only,
  /// so no data from other families can be selected or submitted.
  Future<void> _onGenerate() async {
    if (widget.subscriberCode.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: BillingStrings.unableToGenerateStatement,
        isWarning: true,
      );
      return;
    }

    // Owned solely by this call: created fresh for the pushed screen and
    // closed the moment it's popped, so nothing outlives the round trip.
    final statementsCubit = serviceLocator<AdminStatementsCubit>();

    final result = await context.push<bool>(
      GenerateStatementScreen.routeName,
      extra: GenerateStatementArgs(
        cubit: statementsCubit,
        subscriberCode: widget.subscriberCode,
        ownerType: widget.ownerType,
        familyChildren: widget.familyChildren,
      ),
    );
    unawaited(statementsCubit.close());

    if (!mounted) return;
    if (result == true) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: BillingStrings.statementGeneratedSuccessfully,
        isSuccess: true,
      );
      await _cubit.refresh();
    }
  }

  void _onDateRangeSelected(DateTime startDate, DateTime? endDate) {
    _cubit.applyDateRange(startDate, endDate);
  }

  /// Downloads the statement PDF and opens it, surfacing any error.
  Future<void> _handleDownload(BillingStatementEntity statement) async {
    if (!mounted) return;
    CoreUtils.showTopSnackBar(
      context: context,
      message: BillingStrings.downloadingStatementPdf,
    );
    final error = await _cubit.downloadStatement(statement);
    if (!mounted || error == null) return;
    CoreUtils.showTopSnackBar(
      context: context,
      message: error,
      isError: true,
    );
  }

  /// Opens an in-app PDF preview instead of saving/handing off to an
  /// external viewer (that's what Download is for).
  Future<void> _handleView(BillingStatementEntity statement) async {
    final result = await _cubit.fetchStatementForPreview(statement);
    if (!mounted) return;
    final bytes = result.bytes;
    if (bytes == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: result.error ?? BillingStrings.unableToPreviewThisStatement,
        isError: true,
      );
      return;
    }
    context.push(
      ReportRoutes.billingFileViewer,
      extra: ReportFileViewerArgs(
        fileData: bytes,
        fileName: 'statement-${statement.code}.pdf',
        fileType: 'pdf',
      ),
    );
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
                  BillingStrings.selectDateRange,
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
              label: BillingStrings.dateRange,
              fetchInitialTime: false,
              onRangeSelected: (start, end) =>
                  _onDateRangeSelected(start, end),
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
          final visibleStatements = state.visibleStatements;
          final currentBalance = widget.currentBalance;

          final studentNames = widget.familyChildren
              .map((c) => (c.fullName ?? c.name ?? '').toString())
              .where((n) => n.isNotEmpty)
              .join(', ');

          final formattedChildren = widget.familyChildren.map((child) {
            final name = child.name ?? child.fullName ?? BillingStrings.unknown;
            final room = child.room ?? child.roomName ?? '';
            return BillingFamilyMember(
              name: name,
              fullName: name,
              room: room,
              roomName: room,
            );
          }).toList();

          return CustomRefreshIndicator(
            onRefresh: _refresh,
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Row(children: [AppText.title(BillingStrings.statements)]),
                  ),
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
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8.0),
                        child: _buildDateFilterCard(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  if (_isStatementsLoading)
                    // Shimmer cards during loading
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        children: List.generate(
                          3,
                          (_) => const ParentStatementCardShimmer(
                            margin: EdgeInsets.only(bottom: 8),
                          ),
                        ),
                      ),
                    )
                  else if (state.errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 40,
                              color: AppColors.billingErrorIconColor,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              state.errorMessage,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: AppColors.billingErrorTextColor),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () => _cubit.refresh(),
                              child: const Text(BillingStrings.retry),
                            ),
                          ],
                        ),
                      ),
                    )
                  else if (state.filteredStatements.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 48,
                              color: AppColors.primaryColor
                                  .withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            AppText.value(BillingStrings.noStatementsFound),
                            const SizedBox(height: 8),
                            Text(
                              _customStartDate != null &&
                                      _customEndDate != null
                                  ? BillingStrings.noStatementsAvailableForSelectedDateRange
                                  : BillingStrings.noStatementsAvailable,
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.primaryColor
                                    .withValues(alpha: 0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Builder(builder: (context) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _maybeLoadNextPage();
                      });
                      return Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Column(
                          children: visibleStatements
                              .map(
                                (statement) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8.0),
                                  child: ParentStatementCard(
                                    statement: statement,
                                    studentNames: studentNames,
                                    isDownloading:
                                        state.isDownloading(statement.code),
                                    onDownload: () => _handleDownload(statement),
                                    onView: () => _handleView(statement),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      );
                    }),
                  // Load-more indicator at bottom
                  if (state.hasMoreStatements && !_isStatementsLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: PrimaryCircularLoader()),
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