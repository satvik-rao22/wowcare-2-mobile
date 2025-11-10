import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/billing/widgets/accounting/amount_invoiced_stat_bar.dart';
import 'package:wowcare/presentation/features/billing/widgets/accounting/date_range_selector.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/shared/common/widgets/custom_section_card.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:flutter_svg/svg.dart';

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: true,
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 4),
        physics: const ClampingScrollPhysics(),
        child: Column(
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
          ],
        ),
      ),
    );
  }
}
