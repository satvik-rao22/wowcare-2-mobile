import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/school_switch_events.dart';
import 'package:wowcare/core/utils/tab_visibility_events.dart';
import 'package:wowcare/presentation/features/billing/billing_strings.dart';
import 'package:wowcare/presentation/features/billing/view_model/parent_billing_cubit.dart';
import 'package:wowcare/presentation/features/billing/model/billing_family_member.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/common/widgets/highlightable_card.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/presentation/features/billing/widgets/parent_transaction_card.dart';
import 'package:wowcare/presentation/features/billing/widgets/sibling_cards_widget.dart';
import 'package:wowcare/presentation/features/billing/widgets/parent_statements_tab.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/presentation/features/billing/view/auto_pay_payment_methods_screen.dart';
import 'package:wowcare/presentation/features/billing/view/pay_now_amount_screen.dart';

/// Parent Billing UI — fetches live data from
/// `GET /api/v1/invoices/family-ledger/by-guardian`.
class ParentBillingScreen extends StatefulWidget {
  const ParentBillingScreen({super.key, this.highlightCode});

  /// Invoice code from a billing-notification deep-link. Its transaction card is
  /// revealed (page window grown), scrolled into view and briefly flashed. Null
  /// for normal navigation.
  final String? highlightCode;

  static const String routeName = '/parent-billing';

  @override
  State<ParentBillingScreen> createState() => _ParentBillingScreenState();
}

class _ParentBillingScreenState extends State<ParentBillingScreen>
    with
        TickerProviderStateMixin,
        SchoolSwitchReloadMixin,
        TabBecameVisibleMixin {
  // Parent Billing is branch index 4 in app_router.dart's shell.
  @override
  int get tabBranchIndex => 4;

  @override
  void onTabBecameVisible() {
    // Kept-alive billing branch — same call onSchoolSwitched() uses, just
    // triggered by switching back to this tab instead of a school change.
    if (mounted) _cubit.refresh();
  }

  late final TabController _tabController;
  final ScrollController _billingScrollController = ScrollController();

  /// Deep-linked invoice to flash, and whether we've already revealed it.
  String? _highlightCode;
  bool _highlightApplied = false;

  ParentBillingCubit get _cubit => context.read<ParentBillingCubit>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _billingScrollController.addListener(_onBillingScroll);
    _highlightCode = widget.highlightCode?.trim();
    _cubit.load();
    // Covers the case where the ledger is already loaded (kept-alive branch), so
    // no state change arrives to drive the listener below.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _maybeRevealHighlight(_cubit.state);
    });
  }

  @override
  void didUpdateWidget(ParentBillingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The billing branch is kept alive and built with `builder:` (not a
    // query-keyed page), so a SECOND billing notification rebuilds this widget
    // rather than re-running initState. Re-arm the highlight for the new code.
    if (widget.highlightCode != oldWidget.highlightCode) {
      setState(() {
        _highlightCode = widget.highlightCode?.trim();
        _highlightApplied = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _maybeRevealHighlight(_cubit.state);
      });
    }
  }

  /// Grows the client-side page window so the deep-linked invoice's card is
  /// mounted before [HighlightableCard] tries to flash it (an unmounted card
  /// never fires). Runs once per highlight code, after the ledger has arrived.
  void _maybeRevealHighlight(ParentBillingState state) {
    final code = _highlightCode;
    if (code == null || code.isEmpty || _highlightApplied) return;
    if (state.isLoading || state.ledger == null) return;
    _highlightApplied = true;
    // The invoice lives on the Billing tab — make sure that's the visible one.
    if (_tabController.index != 0) _tabController.animateTo(0);
    _cubit.revealTransaction(code);
  }

  @override
  void onSchoolSwitched() {
    // Kept-alive billing branch — reload the ledger for the new school.
    if (mounted) _cubit.refresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _billingScrollController.removeListener(_onBillingScroll);
    _billingScrollController.dispose();
    super.dispose();
  }

  void _onBillingScroll() {
    if (!_billingScrollController.hasClients) return;
    final pos = _billingScrollController.position;
    if (pos.maxScrollExtent <= 0) {
      _cubit.loadNextPage();
      return;
    }
    if (pos.pixels >= pos.maxScrollExtent - 400) {
      _cubit.loadNextPage();
    }
  }

  void _maybeLoadNextBillingPage() {
    if (!_billingScrollController.hasClients) return;
    final pos = _billingScrollController.position;
    if (pos.maxScrollExtent <= 0 && _cubit.state.hasMoreTransactions) {
      _cubit.loadNextPage();
    }
  }

  Widget _builtRangeSelector(ParentBillingState state) {
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
              initialDate: state.startDate,
              label: BillingStrings.dateRange,
              fetchInitialTime: false,
              onRangeSelected: (start, end) => _cubit.setDateRange(start, end),
            ),
          ),
        ],
      ),
    );
  }

  Widget _builtStudentGridSkeleton(ParentBillingState state) {
    return SiblingCardsWidget(
      students: state.students,
      currentBalance: state.openBalance,
      paid: state.paid,
      netPaid: state.netPaid,
      refunded: state.refunded,
      unpaid: state.unpaid,
      inProcess: state.inProcess,
      isPaymentLoading: state.isPaymentLoading,
      isAutoPayLoading: state.isAutoPayLoading,
      onPayNow: () async {
        if (state.isPaymentLoading) return;
        final paid = await context.push<bool>(
          PayNowAmountScreen.routeName,
        );
        // Reload the ledger so the just-made payment appears (In Process →
        // Success/Failed once settled).
        if (paid == true && mounted) _cubit.refresh();
      },
      onAutoPay: () async {
        if (state.isAutoPayLoading) return;
        _cubit.beginAutoPay();
        final result = await context.push(
          AutoPayPaymentMethodsScreen.routeName,
        );
        if (!mounted) return;
        _cubit.endAutoPay();
        if (result == true) {
          CoreUtils.showTopSnackBar(
            context: context,
            message: BillingStrings.autoPaySettingsUpdated,
            isSuccess: true,
          );
        }
      },
    );
  }

  Widget _buildBillingTab(ParentBillingState state) {
    return CustomRefreshIndicator(
      onRefresh: _cubit.refresh,
      child: SingleChildScrollView(
        controller: _billingScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                children: [
                  AppText.title(BillingStrings.billing),
                ],
              ),
            ),
            Column(
              children: [
                _builtStudentGridSkeleton(state),
                const SizedBox(height: 15),
                _builtRangeSelector(state),
              ],
            ),
            const SizedBox(height: 15),
            if (state.isLoading)
              // Shimmer cards during initial load
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  children: List.generate(
                    5,
                    (_) => const ParentTransactionCardShimmer(
                      margin: EdgeInsets.only(bottom: 8),
                    ),
                  ),
                ),
              )
            else if (state.errorMessage != null && state.ledger == null)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.primaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        state.errorMessage!,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.primaryColor.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _cubit.load,
                        child: const Text(BillingStrings.retry),
                      ),
                    ],
                  ),
                ),
              )
            else if (state.filteredTransactions.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 48,
                        color: AppColors.primaryColor,
                      ),
                      const SizedBox(height: 16),
                      const AppText.value(BillingStrings.noRecordsFound),
                      const SizedBox(height: 8),
                      Text(
                        state.hasDateRange
                            ? BillingStrings.noTransactionsAvailableForTheSelectedDateRange
                            : BillingStrings.noTransactionsAvailable,
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
              Builder(builder: (context) {
                // After list renders, check if we should load more
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _maybeLoadNextBillingPage();
                });
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: state.visibleTransactions.map((txn) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: HighlightableCard(
                          // Match on invoiceCode — `id` is a display/numeric key.
                          code: txn.invoiceCode,
                          highlightCode: _highlightCode,
                          scrollOnHighlight: true,
                          // StaffStyleCard (under ParentTransactionCard) paints an
                          // opaque, full-bleed white background, which would hide a
                          // behind-painted flash entirely — draw it on top instead,
                          // at StaffStyleCard's own 12px radius so the border aligns.
                          foreground: true,
                          borderRadius: 12,
                          child: ParentTransactionCard(
                            transaction: txn,
                            familyName: state.ledger?.familyName ?? '',
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              }),
            // Load-more indicator at bottom
            if (state.hasMoreTransactions && !state.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: PrimaryCircularLoader()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatementsTab(ParentBillingState state) {
    return ParentStatementsTab(
      familyChildren: state.students.map((s) {
        return BillingFamilyMember(
          code: s.code,
          name: s.fullName,
          fullName: s.fullName,
          room: s.role,
          roomName: s.role,
        );
      }).toList(),
      subscriberCode: state.ledger?.ownerCode ?? '',
      ownerType: state.ledger?.ownerType ?? 'GUARDIAN',
      currentBalance: state.openBalance,
      customStartDate: state.startDate,
      customEndDate: state.endDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ParentBillingCubit, ParentBillingState>(
      // Reveal the deep-linked invoice as soon as the ledger arrives.
      listener: (context, state) => _maybeRevealHighlight(state),
      builder: (context, state) {
        return GlobalScaffold(
          body: Column(
            children: [
              ColoredBox(
                color: AppColors.cardColor,
                child: TabBar(
                  labelColor: AppColors.themeColor,
                  unselectedLabelColor:
                      AppColors.primaryColor.withValues(alpha: 0.6),
                  controller: _tabController,
                  dividerColor: AppColors.transparentColor,
                  indicatorSize: TabBarIndicatorSize.label,
                  indicator: const _TabUnderlineIndicator(
                    color: AppColors.themeColor,
                  ),
                  tabs: const [
                    Tab(text: BillingStrings.billing),
                    Tab(text: BillingStrings.statements),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildBillingTab(state),
                    _buildStatementsTab(state),
                  ],
                ),
              ),
            ],
          ),
          showCustomNavigationBar: true,
        );
      },
    );
  }
}

// ─── Gradient tab indicator ───────────────────────────────────────────────────

/// The selected tab's underline: a flat rule in the brand colour, drawn only
/// under the label rather than the whole tab.
class _TabUnderlineIndicator extends Decoration {
  const _TabUnderlineIndicator({required this.color, this.height = 2.5});

  final Color color;
  final double height;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _TabUnderlinePainter(color: color, height: height);
}

class _TabUnderlinePainter extends BoxPainter {
  _TabUnderlinePainter({required this.color, required this.height});

  final Color color;
  final double height;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration cfg) {
    final size = cfg.size ?? Size.zero;
    final rect = Rect.fromLTWH(
      offset.dx,
      offset.dy + size.height - height,
      size.width,
      height,
    );
    canvas.drawRect(rect, Paint()..color = color);
  }
}