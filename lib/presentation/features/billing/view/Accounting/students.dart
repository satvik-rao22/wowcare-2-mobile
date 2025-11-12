import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/billing/widgets/accounting/amount_invoiced_stat_bar.dart';
import 'package:wowcare/presentation/features/billing/widgets/accounting/date_range_selector.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/shared/common/widgets/custom_section_card.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wowcare/presentation/features/billing/widgets/billing_student_card.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';

class StudentsAccountingSection extends StatefulWidget {
  final double totalAmountInvoiced;
  final double paidPercentage;
  final double inProcessPercentage;
  final double unpaidPercentage;

  const StudentsAccountingSection({
    super.key,
    required this.totalAmountInvoiced,
    required this.paidPercentage,
    required this.inProcessPercentage,
    required this.unpaidPercentage,
  });

  @override
  State<StudentsAccountingSection> createState() => _StudentsAccountingSectionState();
}

class _StudentsAccountingSectionState extends State<StudentsAccountingSection> {
  final TextEditingController _searchController = TextEditingController();
  bool _showOutstandingOnly = false;
  double _totalOutstandingAmount = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Non-scrollable content; parent page handles vertical scrolling.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AccountingDateRangeSelector(),
        const SizedBox(height: 8),
        AmountInvoicedStatBar(
          totalAmount: widget.totalAmountInvoiced,
          paidPercentage: widget.paidPercentage,
          inProcessPercentage: widget.inProcessPercentage,
          unpaidPercentage: widget.unpaidPercentage,
        ),
        const SizedBox(height: 8),
        CustomSectionCard(
          margin: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomSearchBar(
                  controller: _searchController,
                  hintText: 'Search',
                  onChanged: (_) {},
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {},
                        child: Center(
                          child: SvgPicture.asset(
                            MediaRes.filterIcon,
                            width: 20,
                            height: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  CustomClearAllChip(
                    onTap: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Row(
            children: [
              CustomToggle(
                key: ValueKey(_showOutstandingOnly),
                label: 'Show Total Outstanding',
                labelStyle: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff573353),
                ),
                isToggled: _showOutstandingOnly,
                onToggle: (val) {
                  setState(() {
                    _showOutstandingOnly = val;
                  });
                  // TODO: trigger filtering when data source is connected
                },
              ),
              const Spacer(),
              Text(
                '\$${_totalOutstandingAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff5978F7),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const BillingStudentCard(
          name: 'John Doe',
          classroom: 'Grade 5 - A',
          fileUuid: '',
          amount: 250,
          paidOn: '02 Nov 2025',
          paymentMethod: 'Bank Transfer',
          paymentNote: 'Reference: INV-2025-0001',
          lastPaymentStatus: 'Success',
          lastInvoiceAmount: 250,
          lastInvoiceSent: '02 Nov 2025',
          lastInvoiceDue: '12 Nov 2025',
          openBalance: 120,
        ),
      ],
    );
  }
}
