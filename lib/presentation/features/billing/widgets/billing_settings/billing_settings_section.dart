import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/billing/widgets/billing_settings/discounts_section.dart';

class BillingSettingsSection extends StatefulWidget {
  const BillingSettingsSection({
    this.onRegisterLoadNextPage,
    this.onLoadMoreNeeded,
    super.key,
  });

  final void Function(VoidCallback)? onRegisterLoadNextPage;
  final VoidCallback? onLoadMoreNeeded;

  @override
  State<BillingSettingsSection> createState() =>
      _BillingSettingsSectionState();
}

class _BillingSettingsSectionState extends State<BillingSettingsSection> {
  static const List<String> _subTabs = ['Billing'];
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Sub-tab row ──────────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_subTabs.length, (index) {
              final bool isSelected = index == _selectedIndex;
              return GestureDetector(
                onTap: () => setState(() => _selectedIndex = index),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(4, 6, 12, 6),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isSelected
                            ? AppColors.themeColor
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    _subTabs[index],
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.themeColor
                          : const Color(0xFF0A1C5D),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),

        // ── Tab content ──────────────────────────────────────────
        if (_selectedIndex == 0)
          DiscountsSection(
            onRegisterLoadNextPage: widget.onRegisterLoadNextPage,
            onLoadMoreNeeded: widget.onLoadMoreNeeded,
          ),
      ],
    );
  }
}
