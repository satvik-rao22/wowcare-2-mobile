import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/billing/widgets/subsidies/subsidies_section.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/billing/view/Accounting/students.dart';
import 'package:wowcare/shared/common/widgets/gradient_add_button.dart';
import 'package:wowcare/presentation/features/billing/widgets/create_invoice_dialog.dart';
import 'package:wowcare/presentation/features/billing/widgets/select_students_screen.dart';
import 'package:wowcare/presentation/features/billing/widgets/transactions/transactions_section.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  static const String routeName = '/billing';

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen>
    with SingleTickerProviderStateMixin {
  static const List<String> _tabs = <String>[
    'Student(s)',
    'Transactions',
    'Recurring Plans',
    'General Ledger',
    'Subsidies',
    'Analytics',
    'Billing Settings',
  ];

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
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
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
                              GradientAddButton(
                                onTap: () {
                                  showDialog<void>(
                                    context: context,
                                    builder: (ctx) => CreateInvoiceDialog(
                                      onSelectOneTime: () {
                                        Navigator.of(ctx).maybePop();
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => const SelectStudentsScreen(),
                                          ),
                                        );
                                      },
                                      onSelectRecurring: () {
                                        Navigator.of(ctx).maybePop();
                                        // TODO: navigate to recurring invoice flow
                                      },
                                    ),
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
                                content = const StudentsAccountingSection(
                                  totalAmountInvoiced: 100750,
                                  paidPercentage: 85,
                                  inProcessPercentage: 10,
                                  unpaidPercentage: 5,
                                );
                              } else if (current == 1) {
                                content = const TransactionsSection();
                              } else if (current == 4){
                                content = SubsidiesSection();
                              } else {
                                final String t = _tabs[current];
                                content = Align(
                                  alignment: Alignment.topLeft,
                                  child: Text(
                                    '$t content goes here.',
                                    style: const TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xff573353),
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
              ],
            );
          },
        ),
      ),
      showCustomNavigationBar: true,
    );
  }
}


