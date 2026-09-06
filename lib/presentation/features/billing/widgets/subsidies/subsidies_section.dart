import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/presentation/features/billing/billing_strings.dart';
import 'package:wowcare/presentation/features/billing/view_model/subsidies_cubit.dart';
import 'package:wowcare/presentation/features/billing/widgets/subsidies/subsidy_card.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_section_card.dart';

import 'package:wowcare/shared/common/widgets/custom_toggle.dart';

class SubsidiesSection extends StatefulWidget {
  const SubsidiesSection({super.key});

  @override
  State<SubsidiesSection> createState() => _SubsidiesSectionState();
}

class _SubsidiesSectionState extends State<SubsidiesSection> {
  late final SubsidiesCubit _cubit = SubsidiesCubit();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _cubit.close();
    super.dispose();
  }

  void _deleteSubsidy(SubsidyItem subsidy) {
    final int index = _cubit.deleteSubsidy(subsidy);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("${subsidy.subsidyName} deleted"),
        action: SnackBarAction(
          label: BillingStrings.undo,
          // Keeps the original ordering even after undo.
          onPressed: () => _cubit.restoreSubsidy(subsidy, index),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SubsidiesCubit>.value(
      value: _cubit,
      child: BlocBuilder<SubsidiesCubit, SubsidiesState>(
        builder: (context, state) {
          final filteredSubsidies = state.filteredItems;
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
                          hintText: BillingStrings.searchSubsidy,
                          onChanged: (text) => _cubit.setSearchQuery(text),
                        ),
                      ),
                      SizedBox(width: 30),
                      CustomToggle(
                        key: ValueKey(state.isToggled),
                        label: '',
                        isToggled: state.isToggled,
                        onToggle: (v) {
                          _searchController.clear();
                          _cubit.setToggle(v);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Column(
                  children: filteredSubsidies
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
        },
      ),
    );
  }
}
