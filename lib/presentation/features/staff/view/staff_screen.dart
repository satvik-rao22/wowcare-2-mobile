import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/shared/common/widgets/custom_stat_bar_card.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/common/widgets/custom_chip.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_list_item.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_card.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  static const String routeName = '/staff';

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showInactive = false;
  final List<bool> _selectedDemo = [false, false, false];
  bool _selectAll = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double titleFontSize = ResponsiveSizing.titleFontSize(context);
    final double titleLineHeight = ResponsiveSizing.titleLineHeight(context);

    return GlobalScaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: ResponsiveSizing.contentPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Staff List',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff573353),
                  height: titleLineHeight,
                ),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 16),
              // Total Staff stat card
              LayoutBuilder(
                builder: (context, constraints) {
                  final bool isTablet = constraints.maxWidth >= 600;
                  final EdgeInsets cardPadding = EdgeInsets.zero; // outer handled by container
                  // Static values for now
                  final double active = 21.0;
                  final double upcoming = 4.0;
                  final int totalCount = (active + upcoming).toInt();
                  final String total = '$totalCount';
                  final items = [
                    ProgressItemHelper(
                      label: 'Active (${active.toInt()})',
                      value: active,
                      color: AppColors.lightBlueProgressBar,
                    ),
                    ProgressItemHelper(
                      label: 'Upcoming (${upcoming.toInt()})',
                      value: upcoming,
                      color: AppColors.mustardProgressBar,
                    ),
                  ];
                  return Container(
                    margin: EdgeInsets.only(top: isTablet ? 16 : 12, bottom: isTablet ? 8 : 8),
                    child: CustomStatBarCard(
                      title: 'Total\nStaff',
                      number: total,
                      items: items,
                      fullWidthBar: false,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              // Filter card with search and filter icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.cardBorderColor),
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.cardColor,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CustomSearchBar(
                            controller: _searchController,
                            hintText: 'Search Staff',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {},
                            borderRadius: BorderRadius.circular(100),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: SvgPicture.asset(MediaRes.filterIcon, height: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 8,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                const CustomChip(
                                  label: 'Active',
                                  labelStyle: TextStyle(
                                    color: AppColors.secondaryColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  color: Color.fromRGBO(177, 175, 233, 0.3),
                                ),
                                const SizedBox(width: 8),
                                CustomToggle(
                                  label: '',
                                  isToggled: _showInactive,
                                  onToggle: (v) => setState(() => _showInactive = v),
                                ),
                              ],
                            ),
                          ),
                          const Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: CustomClearAllChip(onTap: null),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Select All outside the search box
              Align(
                alignment: Alignment.centerLeft,
                child: CustomCheckbox(
                  label: 'Select All',
                  value: _selectAll,
                  onChanged: (v) {
                    final newVal = v ?? false;
                    setState(() {
                      _selectAll = newVal;
                      for (int i = 0; i < _selectedDemo.length; i++) {
                        _selectedDemo[i] = newVal;
                      }
                    });
                  },
                ),
              ),
              // Placeholder for staff list content
              const SizedBox(height: 16),
              // Demo staff list using StaffCard with working checkbox
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                itemBuilder: (context, index) {
                  final demo = [
                    {
                      'name': 'Aarav Sharma',
                      'classroom': 'Nursery A',
                      'allowed': ['Nursery A', 'Playgroup'],
                      'schedule': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
                      'joinDate': '12 Jan 2022',
                      'statusDate': '05 Sep 2024',
                    },
                    {
                      'name': 'Isha Verma',
                      'classroom': 'Nursery B',
                      'allowed': ['Nursery B'],
                      'schedule': ['Mon', 'Wed', 'Fri'],
                      'joinDate': '22 Mar 2023',
                      'statusDate': '15 Aug 2024',
                    },
                    {
                      'name': 'Rahul Singh',
                      'classroom': 'Daycare',
                      'allowed': ['Daycare', 'Playgroup', 'Nursery A'],
                      'schedule': ['Tue', 'Thu', 'Sat'],
                      'joinDate': '10 Oct 2021',
                      'statusDate': '01 Sep 2024',
                    },
                  ][index];
                  return Column(
                    children: [
                      StaffCard(
                        name: demo['name'] as String,
                        classroom: demo['classroom'] as String,
                        allowedClassrooms: (demo['allowed'] as List<String>),
                        schedule: (demo['schedule'] as List<String>),
                        designation: index == 0
                            ? 'Teacher'
                            : index == 1
                                ? 'Assistant Teacher'
                                : 'Caretaker',
                        phoneNumber: index == 0
                            ? '5551234567'
                            : index == 1
                                ? '2125557890'
                                : '4155559876',
                        isSelected: _selectedDemo[index],
                        onSelected: (v) => setState(() => _selectedDemo[index] = v ?? false),
                      ),
                      if (index != 2) const SizedBox(height: 12),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
      showCustomNavigationBar: true,
    );
  }
}

void _noop(bool _) {}


