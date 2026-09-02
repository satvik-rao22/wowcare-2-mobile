import 'dart:async' show unawaited;
import 'package:wowcare/core/util/billing_school_time.dart';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/core/util/billing_events.dart';
import 'package:wowcare/presentation/features/billing/model/billing_route_args.dart';
// import 'package:wowcare/presentation/features/billing/widgets/subsidies/subsidies_section.dart'; // Subsidies not implemented yet
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/billing/view/Accounting/students.dart';
import 'package:wowcare/presentation/features/billing/widgets/accounting/amount_invoiced_stat_bar.dart';
import 'package:wowcare/shared/common/widgets/gradient_add_button.dart';
import 'package:wowcare/presentation/features/billing/widgets/create_invoice_dialog.dart';
import 'package:wowcare/presentation/features/billing/view/select_students_screen.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/transaction_action_dialog.dart';
import 'package:wowcare/presentation/features/billing/view/transactions/receive_payment_issue_refund_screen.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/transaction_item.dart';
import 'package:wowcare/presentation/features/billing/model/student_models.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/transactions_section.dart';
import 'package:wowcare/presentation/features/billing/widgets/analytics/analytics_section.dart';
import 'package:wowcare/presentation/features/billing/view/general_ledger/create_ledger_screen.dart';
import 'package:wowcare/presentation/features/billing/widgets/general_ledger/general_ledger_section.dart';
import 'package:wowcare/presentation/features/billing/model/ledger_account_model.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/presentation/features/billing/widgets/billing_settings/billing_settings_section.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/core/util/school_switch_events.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  static const String routeName = '/dashboard/billing';

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen>
    with SingleTickerProviderStateMixin, SchoolSwitchReloadMixin {
  static const List<String> _tabs = <String>[
    'Student(s)',
    'Transactions',
    // 'Recurring Plans',
    'General Ledger',
    // 'Subsidies', // Not implemented yet - hidden for all personas
    'Analytics',
    'Billing Settings',
  ];
  final ValueNotifier<LedgerAccountModel?> _ledgerCreationNotifier =
      ValueNotifier<LedgerAccountModel?>(null);
  final ScrollController _scrollController = ScrollController();
  TabController? _tabController;

  Future<void> Function()? _ledgerRefreshFn;
  Future<void> Function()? _studentsRefreshFn;
  Future<void> Function()? _transactionsRefreshFn;
  Future<void> Function()? _analyticsRefreshFn;
  VoidCallback? _ledgerLoadNextFn;
  VoidCallback? _discountLoadNextFn;
  VoidCallback? _transactionsLoadNextFn;

  /// One-shot hand-off of a summary-card filter across a tab switch. Consumed
  /// (and cleared) by the destination tab's section on its next build.
  BillingSummaryFilter? _pendingTransactionFilter;
  bool _pendingStudentOutstanding = false;

  static const int _studentsTabIndex = 0;
  static const int _transactionsTabIndex = 1;

  /// Switches to the Transactions tab with [filter] pre-applied (from a tap on
  /// the Student(s) summary card).
  void _openTransactionsWithFilter(BillingSummaryFilter filter) {
    _pendingTransactionFilter = filter;
    _tabController?.animateTo(_transactionsTabIndex);
  }

  /// Switches to the Student(s) tab with the outstanding-only filter enabled
  /// (from an Outstanding tap on the Transactions summary card).
  void _openStudentsOutstanding() {
    _pendingStudentOutstanding = true;
    _tabController?.animateTo(_studentsTabIndex);
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Refresh the visible tab after any billing mutation (invoice CRUD,
    // payment, refund, credit) — fired globally by the invoice repository.
    BillingEvents.tick.addListener(_onBillingChanged);
  }

  @override
  void dispose() {
    BillingEvents.tick.removeListener(_onBillingChanged);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _ledgerCreationNotifier.dispose();
    super.dispose();
  }

  /// Re-fetches whichever tab is currently shown when a billing mutation fires.
  void _onBillingChanged() {
    if (!mounted) return;
    switch (_tabController?.index) {
      case 0:
        _studentsRefreshFn?.call();
        break;
      case 1:
        _transactionsRefreshFn?.call();
        break;
      case 2:
        _ledgerRefreshFn?.call();
        break;
      case 3:
        _analyticsRefreshFn?.call();
        break;
    }
  }

  /// On an org/school switch, re-fetch EVERY tab (not just the visible one) so
  /// no billing tab keeps showing the previous school's invoices / ledger /
  /// analytics after the switch (BILL-INV-01). Tabs not yet built load fresh on
  /// first visit; already-built ones refetch under the now-current school.
  @override
  void onSchoolSwitched() {
    if (!mounted) return;
    _studentsRefreshFn?.call();
    _transactionsRefreshFn?.call();
    _ledgerRefreshFn?.call();
    _analyticsRefreshFn?.call();
  }

  void _onScroll() => _maybeLoadNextPage();

  void _maybeLoadNextPage() {
    if (!_scrollController.hasClients) return;
    final tc = _tabController;
    if (tc == null) return;
    final position = _scrollController.position;

    VoidCallback? loadFn;
    if (tc.index == 1) loadFn = _transactionsLoadNextFn;
    if (tc.index == 2) loadFn = _ledgerLoadNextFn;
    if (tc.index == 4) loadFn = _discountLoadNextFn;
    if (loadFn == null) return;

    if (position.maxScrollExtent <= 0) {
      loadFn();
      return;
    }
    if (position.pixels >= position.maxScrollExtent - 400) {
      loadFn();
    }
  }

  /// Builds a minimal [TransactionItem] from the selected student(s) so the
  /// Receive Payment screen can be opened for a fresh (zero-balance) payment.
  TransactionItem _buildReceivePaymentTransaction(List<Student> students) {
    final Student first = students.first;
    final String name = students.length > 1
        ? '${first.fullName} +${students.length - 1}'
        : first.fullName;
    return TransactionItem(
      id: 0,
      transactionType: 'Payment',
      date: billingSchoolNow(),
      amount: 0,
      status: '',
      description: 'Receive Payment',
      studentName: name,
      classroom: first.roomName ?? '',
      balance: 0,
      studentOpenBalance: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double titleFontSize = ResponsiveSizing.titleFontSize(context);
    final double titleLineHeight = ResponsiveSizing.titleLineHeight(context);
    final EdgeInsets contentPadding = ResponsiveSizing.contentPadding(context);

    return GlobalScaffold(
      body: DefaultTabController(
        length: _tabs.length,
        child: Builder(
          builder: (context) {
            final TabController controller = DefaultTabController.of(context);
            _tabController = controller;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomRefreshIndicator(
                    onRefresh: () async {
                      // Refresh the data for whichever tab is currently shown.
                      switch (controller.index) {
                        case 0:
                          await _studentsRefreshFn?.call();
                          break;
                        case 1:
                          await _transactionsRefreshFn?.call();
                          break;
                        case 2:
                          await _ledgerRefreshFn?.call();
                          break;
                        case 3:
                          await _analyticsRefreshFn?.call();
                          break;
                      }
                    },
                    child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Padding(
                      padding: contentPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Billing',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: titleFontSize,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.billingTextColor,
                                    height: titleLineHeight,
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                              AnimatedBuilder(
                                animation: controller,
                                builder: (_, __) {
                                  final int idx = controller.index;
                                  if (idx == 3 || idx == 4) {
                                    return const SizedBox.shrink();
                                  }
                                  return GradientAddButton(
                                    onTap: () async {
                                      final bool isGeneralLedgerTab =
                                          controller.index ==
                                              _tabs.indexOf('General Ledger');
                                      if (isGeneralLedgerTab) {
                                        final result = await context.push(
                                          CreateLedgerScreen.routeName,
                                        );
                                        if (result is LedgerAccountModel) {
                                          _ledgerCreationNotifier.value =
                                              result;
                                        }
                                        return;
                                      }
                                      final bool isTransactionsTab =
                                          controller.index ==
                                              _tabs.indexOf('Transactions');
                                      if (isTransactionsTab) {
                                        showDialog<void>(
                                          context: context,
                                          builder: (ctx) =>
                                              TransactionActionDialog(
                                            onSelectCreateInvoice: () {
                                              unawaited(Navigator.of(ctx)
                                                  .maybePop());
                                              unawaited(context.push(
                                                SelectStudentsScreen.routeName,
                                              ));
                                            },
                                            onSelectReceivePayment: () {
                                              unawaited(Navigator.of(ctx)
                                                  .maybePop());
                                              unawaited(context.push(
                                                SelectStudentsScreen.routeName,
                                                extra: SelectStudentsArgs(
                                                  onNext: (selCtx, students) {
                                                    selCtx.pushReplacement(
                                                      ReceivePaymentIssueRefundScreen
                                                          .routeName,
                                                      extra:
                                                          ReceivePaymentRefundArgs(
                                                        transaction:
                                                            _buildReceivePaymentTransaction(
                                                                students),
                                                        studentCode:
                                                            students.first.code,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ));
                                            },
                                          ),
                                        );
                                        return;
                                      }
                                      showDialog<void>(
                                        context: context,
                                        builder: (ctx) => CreateInvoiceDialog(
                                          onSelectOneTime: () {
                                            unawaited(
                                                Navigator.of(ctx).maybePop());
                                            unawaited(context.push(
                                              SelectStudentsScreen.routeName,
                                            ));
                                          },
                                          onSelectRecurring: () {
                                            unawaited(
                                                Navigator.of(ctx).maybePop());
                                          },
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Scrollable TabBar (horizontal only)
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.transparentColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 0,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  tooltip: 'Scroll tabs',
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                  constraints: const BoxConstraints.tightFor(width: 26, height: 32),
                                  splashRadius: 14,
                                  icon: const Icon(Icons.chevron_left, color: AppColors.billingTextColor, size: 25),
                                  onPressed: () {
                                    final int current = controller.index;
                                    if (current > 0) {
                                      controller.animateTo(current - 1);
                                    }
                                  },
                                ),
                                Expanded(
                                  child: TabBar(
                                    isScrollable: true,
                                    padding: EdgeInsets.zero,
                                    labelPadding: EdgeInsets.zero,
                                    tabAlignment: TabAlignment.start,
                                    labelColor: AppColors.themeColor,
                                    unselectedLabelColor: AppColors.billingTextColor,
                                    dividerColor: AppColors.transparentColor,
                                    indicatorSize: TabBarIndicatorSize.label,
                                    indicator: UnderlineTabIndicator(
                                      borderSide: BorderSide(
                                        color: AppColors.themeColor,
                                        width: 2,
                                      ),
                                    ),
                                    tabs: List<Widget>.generate(
                                      _tabs.length,
                                      (int index) => Padding(
                                        padding: EdgeInsets.fromLTRB(
                                          index == 0 ? 4 : 12,
                                          6,
                                          12,
                                          6,
                                        ),
                                        child: Text(
                                          _tabs[index],
                                          style: const TextStyle(
                                            fontFamily: 'Manrope',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Scroll tabs',
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity.compact,
                                  constraints: const BoxConstraints.tightFor(width: 26, height: 32),
                                  splashRadius: 14,
                                  icon: const Icon(Icons.chevron_right, color: AppColors.billingTextColor, size: 25),
                                  onPressed: () {
                                    final int current = controller.index;
                                    if (current < _tabs.length - 1) {
                                      controller.animateTo(current + 1);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Inline tab content so the entire page scrolls together
                          AnimatedBuilder(
                            animation: controller,
                            builder: (context, _) {
                              final int current = controller.index;
                              Widget content;
                              if (current == 0) {
                                // Consume the one-shot Outstanding hand-off so
                                // it only applies on the triggering switch.
                                final bool showOutstanding =
                                    _pendingStudentOutstanding;
                                _pendingStudentOutstanding = false;
                                content = StudentsAccountingSection(
                                  onRegisterRefresh: (fn) {
                                    _studentsRefreshFn = fn;
                                  },
                                  initialShowOutstanding: showOutstanding,
                                  onNavigateToTransactions:
                                      _openTransactionsWithFilter,
                                );
                              } else if (current == 1) {
                                // Consume the one-shot filter hand-off.
                                final BillingSummaryFilter? pendingFilter =
                                    _pendingTransactionFilter;
                                _pendingTransactionFilter = null;
                                content = TransactionsSection(
                                  onRegisterRefresh: (fn) {
                                    _transactionsRefreshFn = fn;
                                  },
                                  onRegisterLoadNextPage: (fn) {
                                    _transactionsLoadNextFn = fn;
                                  },
                                  onLoadMoreNeeded: _maybeLoadNextPage,
                                  initialFilter: pendingFilter,
                                  onNavigateToOutstanding:
                                      _openStudentsOutstanding,
                                );
                              } else if (current == 2) {
                                content = GeneralLedgerSection(
                                  ledgerCreationNotifier:
                                      _ledgerCreationNotifier,
                                  onRegisterRefresh: (fn) {
                                    _ledgerRefreshFn = fn;
                                  },
                                  onRegisterLoadNextPage: (fn) {
                                    _ledgerLoadNextFn = fn;
                                  },
                                  onLoadMoreNeeded: _maybeLoadNextPage,
                                );
                              } else if (current == 3) {
                                // 'Subsidies' tab is not implemented yet; the
                                // tab entry above is disabled so this index
                                // now maps to Analytics instead.
                                content = AnalyticsSection(
                                  onRegisterRefresh: (fn) {
                                    _analyticsRefreshFn = fn;
                                  },
                                );
                              } else if (current == 4) {
                                content = BillingSettingsSection(
                                  onRegisterLoadNextPage: (fn) {
                                    _discountLoadNextFn = fn;
                                  },
                                  onLoadMoreNeeded: _maybeLoadNextPage,
                                );
                              } else {
                                final String t = _tabs[current];
                                content = Align(
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    '$t content goes here.',
                                    style: AppTextStyles.body.copyWith(
                                      color: AppColors.billingTextColor,
                                    ),
                                  ),
                                );
                              }
                              return content;
                            },
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).padding.bottom + 12,
                          ),
                        ],
                      ),
                    ),
                  ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      showCustomNavigationBar: true,
    );
  }
}


