import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/billing/widgets/subsidies/subsidies_section.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/billing/view/Accounting/students.dart';
import 'package:wowcare/shared/common/widgets/gradient_add_button.dart';
import 'package:wowcare/presentation/features/billing/widgets/create_invoice_dialog.dart';
import 'package:wowcare/presentation/features/billing/widgets/select_students_screen.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/transaction_action_dialog.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/receive_payment_issue_refund_screen.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/transaction_item.dart';
import 'package:wowcare/presentation/features/billing/widgets/models/student_models.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/transactions_section.dart';
import 'package:wowcare/presentation/features/billing/widgets/analytics/analytics_section.dart';
import 'package:wowcare/presentation/features/billing/widgets/general_ledger/create_ledger_screen.dart';
import 'package:wowcare/presentation/features/billing/widgets/general_ledger/general_ledger_section.dart';
import 'package:wowcare/presentation/features/billing/widgets/general_ledger/models/ledger_account_model.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/presentation/features/billing/widgets/billing_settings/billing_settings_section.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  static const String routeName = '/dashboard/billing';

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen>
    with SingleTickerProviderStateMixin {
  static const List<String> _tabs = <String>[
    'Student(s)',
    'Transactions',
    // 'Recurring Plans',
    'General Ledger',
    'Subsidies',
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

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _ledgerCreationNotifier.dispose();
    super.dispose();
  }

  void _onScroll() => _maybeLoadNextPage();

  void _maybeLoadNextPage() {
    if (!_scrollController.hasClients) return;
    final tc = _tabController;
    if (tc == null) return;
    final position = _scrollController.position;

    VoidCallback? loadFn;
    if (tc.index == 2) loadFn = _ledgerLoadNextFn;
    if (tc.index == 5) loadFn = _discountLoadNextFn;
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
      date: DateTime.now(),
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
                        case 4:
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
                                    color: const Color(0xff573353),
                                    height: titleLineHeight,
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                              AnimatedBuilder(
                                animation: controller,
                                builder: (_, __) {
                                  final int idx = controller.index;
                                  if (idx == 4 || idx == 5) {
                                    return const SizedBox.shrink();
                                  }
                                  return GradientAddButton(
                                    onTap: () async {
                                      final bool isGeneralLedgerTab =
                                          controller.index ==
                                              _tabs.indexOf('General Ledger');
                                      if (isGeneralLedgerTab) {
                                        final result =
                                            await Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const CreateLedgerScreen(),
                                          ),
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
                                              unawaited(Navigator.of(context)
                                                  .push(MaterialPageRoute(
                                                builder: (_) =>
                                                    const SelectStudentsScreen(),
                                              )));
                                            },
                                            onSelectReceivePayment: () {
                                              unawaited(Navigator.of(ctx)
                                                  .maybePop());
                                              unawaited(Navigator.of(context)
                                                  .push(MaterialPageRoute(
                                                builder: (_) =>
                                                    SelectStudentsScreen(
                                                  onNext: (selCtx, students) {
                                                    Navigator.of(selCtx)
                                                        .pushReplacement(
                                                      MaterialPageRoute(
                                                        builder: (_) =>
                                                            ReceivePaymentIssueRefundScreen(
                                                          transaction:
                                                              _buildReceivePaymentTransaction(
                                                                  students),
                                                          studentCode: students
                                                              .first.code,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              )));
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
                                            unawaited(Navigator.of(context)
                                                .push(MaterialPageRoute(
                                              builder: (_) =>
                                                  const SelectStudentsScreen(),
                                            )));
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
                              color: Colors.transparent,
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
                                  icon: const Icon(Icons.chevron_left, color: Color(0xff573353), size: 25),
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
                                    unselectedLabelColor: const Color(0xff573353),
                                    dividerColor: Colors.transparent,
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
                                  icon: const Icon(Icons.chevron_right, color: Color(0xff573353), size: 25),
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
                                content = StudentsAccountingSection(
                                  onRegisterRefresh: (fn) {
                                    _studentsRefreshFn = fn;
                                  },
                                );
                              } else if (current == 1) {
                                content = TransactionsSection(
                                  onRegisterRefresh: (fn) {
                                    _transactionsRefreshFn = fn;
                                  },
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
                                content = const SubsidiesSection();
                              } else if (current == 4) {
                                content = AnalyticsSection(
                                  onRegisterRefresh: (fn) {
                                    _analyticsRefreshFn = fn;
                                  },
                                );
                              } else if (current == 5) {
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


