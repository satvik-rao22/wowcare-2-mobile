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
  bool _isToggled = false;

  final List<SubsidyItem> _subsidyItems = [
    SubsidyItem(
      subsidyName: 'Food Assistance',
      invoiced: 12,
      received: 30,
      balance: 19,
    ),
    SubsidyItem(
      subsidyName: 'Housing vouchers',
      invoiced: 0,
      received: 0,
      balance: 19,
    ),
    SubsidyItem(
      subsidyName: 'Federal assistance',
      invoiced: 0,
      received: 0,
      balance: 19,
    ),
    SubsidyItem(
      subsidyName: 'Local Community Fund',
      invoiced: 0,
      received: 0,
      balance: 19,
    ),
  ];

  @override
  void initState(){
    super.initState();
    _searchController.addListener((){
      if (_searchController.text.trim().isEmpty && _isToggled){
        setState(() {
          _isToggled = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SubsidyItem> get _filteredSubsidiesList {
    final query = _searchController.text.trim().toLowerCase();

    if (_isToggled || query.isEmpty){
      return _subsidyItems;
    }
    return _subsidyItems
        .where((subsidy) => subsidy.subsidyName.toLowerCase().contains(query))
        .toList();
  }

  void _deleteSubsidy(SubsidyItem subsidy) {
    final int index = _subsidyItems.indexOf(subsidy);
    setState(() {
      _subsidyItems.remove(subsidy);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${subsidy.subsidyName} deleted"),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() {
              // the order of the subsidy items will be maintained even after undo
              if (index <= _subsidyItems.length) {
                _subsidyItems.insert(index, subsidy);
              } else {
                _subsidyItems.add(subsidy);
              }
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final _filteredSubsidies = _filteredSubsidiesList;
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
                    hintText: 'Search Subsidy',
                    onChanged: (text) => setState(() {
                      // Auto-turn OFF toggle when user starts typing
                      if (_isToggled && text.isNotEmpty) {
                        _isToggled = false;
                      }
                    }),
                  ),
                ),
                SizedBox(width: 30),
                CustomToggle(
                  key: ValueKey(_isToggled),
                  label: '',
                  isToggled: _isToggled,
                  onToggle: (v) => setState(() {
                    _searchController.clear();
                    _isToggled = v;
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Column(
            children: _filteredSubsidies
                .map(
                  (subsidy) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: SubsidyCard(
                      subsidy: subsidy,
                      onDelete: () => _deleteSubsidy(subsidy),
                    ),
                  ),
                )
                .toList(),
          ),
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
  SubsidyItem({
    required this.subsidyName,
    this.invoiced,
    this.received,
    this.balance,
  });
}
