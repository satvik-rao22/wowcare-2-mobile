import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/billing/widgets/subsidies/subsidy_card.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_section_card.dart';

import '../../../../../shared/common/widgets/custom_toggle.dart';
class SubsidiesSection extends StatefulWidget {
  const SubsidiesSection({super.key});

  @override
  State<SubsidiesSection> createState() => _SubsidiesSectionState();
}

class _SubsidiesSectionState extends State<SubsidiesSection> {
  final TextEditingController _searchController = TextEditingController();
  bool _showInactive = false;

  final List<SubsidyItem> _subsidyItems = [
    SubsidyItem(subsidyName: 'Food Assistance', invoiced: 12, received: 30, balance: 19),
    SubsidyItem(subsidyName: 'Housing vouchers', invoiced: 0, received: 0, balance: 19),
    SubsidyItem(subsidyName: 'Federal assistance', invoiced: 0, received: 0, balance: 19),
    SubsidyItem(subsidyName: 'Local Community Fund', invoiced: 0, received: 0, balance: 19),
  ];

  @override
  void dispose(){
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _filteredSubsidies = _subsidyItems;
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomSectionCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                      child: CustomSearchBar(
                          controller: _searchController,
                          hintText: 'Search Subsidy'
                      )
                  ),
                  SizedBox(width: 20,),
                  CustomToggle(
                    label: '',
                    isToggled: _showInactive,
                    onToggle: (v) => setState(() => _showInactive = v),
                  ),
                ],
              )
          ),
          const SizedBox(height: 12),
          Column(
            children:
              _filteredSubsidies.map( (subsidy) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: SubsidyCard(
                  subsidy: subsidy,
                ),
              )).toList()

          )

        ],

      ),
    );
  }
}

class SubsidyItem {
  final String subsidyName;
  final num? invoiced;
  final num? received;
  final num? balance;
  SubsidyItem({required this.subsidyName, this.invoiced, this.received, this.balance});
}