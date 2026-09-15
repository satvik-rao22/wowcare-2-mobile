import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_fonts.dart';
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
  static const List<String> _subTabs = ['Discounts'];
  final ValueNotifier<int> _selectedIndex = ValueNotifier<int>(0);

  @override
  void dispose() {
    _selectedIndex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: _selectedIndex,
      builder: (context, selectedIndex, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Sub-tab row ──────────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(_subTabs.length, (index) {
              final bool isSelected = index == selectedIndex;
              return GestureDetector(
                onTap: () => _selectedIndex.value = index,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(4, 6, 12, 6),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: isSelected
                            ? AppColors.themeColor
                            : AppColors.transparentColor,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    _subTabs[index],
                    style: TextStyle(
                      fontFamily: Fonts.manrope,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.themeColor
                          : AppColors.billingTextColor,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),

        // ── Tab content ──────────────────────────────────────────
        if (selectedIndex == 0)
          DiscountsSection(
            onRegisterLoadNextPage: widget.onRegisterLoadNextPage,
            onLoadMoreNeeded: widget.onLoadMoreNeeded,
          ),
      ],
      ),
    );
  }
}
