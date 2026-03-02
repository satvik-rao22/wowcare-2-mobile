import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_section_card.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'staff_entity.dart';
import 'staff_transfer_form.dart';

class StaffSelectionTransferForm extends StatefulWidget {
  const StaffSelectionTransferForm({super.key});

  static const String routeName = '/staff-selection-transfer-form';

  @override
  State<StaffSelectionTransferForm> createState() =>
      _StaffSelectionTransferFormState();
}

class _StaffSelectionTransferFormState
    extends State<StaffSelectionTransferForm> {
  bool isSelectAllChecked = false;
  String? _selectedClassroom = '';
  List<String> _selectedTag = [];
  Set<StaffEntity> selectedStaff = {};
  final TextEditingController _searchController = TextEditingController();

  // Mock data for UI-only implementation - only signed-in staff
  final List<StaffEntity> _allStaff = List.generate(
    15,
    (index) => StaffEntity(
      id: index + 1,
      name: 'Staff ${index + 1}',
      primaryRoomId: (index % 4) + 1,
      designation: index % 3 == 0 ? 'Teacher' : index % 3 == 1 ? 'Admin' : 'Staff',
    ),
  );

  final List<String> _classrooms = ['Classroom A', 'Classroom B', 'Classroom C', 'Classroom D'];
  final List<String> _tags = ['Tag 1', 'Tag 2', 'Tag 3', 'Tag 4'];

  List<StaffEntity> _filteredStaff = [];

  @override
  void initState() {
    super.initState();
    _filteredStaff = List.from(_allStaff);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterStaff() {
    setState(() {
      _filteredStaff = _allStaff.where((staff) {
        bool matchesSearch = true;
        bool matchesRoom = true;
        bool matchesTag = true;

        if (_searchController.text.isNotEmpty) {
          matchesSearch = staff.name
              .toLowerCase()
              .contains(_searchController.text.toLowerCase());
        }

        if (_selectedClassroom != null && _selectedClassroom!.isNotEmpty) {
          matchesRoom = true; // Simplified for UI-only
        }

        return matchesSearch && matchesRoom && matchesTag;
      }).toList();
    });
  }

  void _toggleSelectAll(bool? value) {
    if (value == null) return;

    setState(() {
      isSelectAllChecked = value;
      if (value) {
        selectedStaff.addAll(_filteredStaff);
      } else {
        selectedStaff.removeAll(_filteredStaff);
      }
    });
  }

  void _toggleStaffSelection(StaffEntity staff, bool? value) {
    if (value == null) return;

    setState(() {
      if (value) {
        selectedStaff.add(staff);
      } else {
        selectedStaff.remove(staff);
      }

      isSelectAllChecked = _filteredStaff.every(
        (staff) => selectedStaff.contains(staff),
      );
    });
  }

  void _handleNext() {
    if (selectedStaff.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one staff member'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StaffTransferForm(
          staff: selectedStaff.first,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveSizing.isTablet(context);
    final mediaQuery = MediaQuery.of(context);
    final safeAreaBottom = mediaQuery.padding.bottom;

    return StaffFormLayout(
      title: 'Transfer',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 24 : 16,
              vertical: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.title('Transfer'),
                const SizedBox(height: 20),
                AppText.sectionHeader('Select Staff'),
                const SizedBox(height: 12),
                CustomSearchBar(
                  controller: _searchController,
                  hintText: 'Search Staff',
                  onChanged: (_) => _filterStaff(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CustomDropdown(
                        hintText: 'Classroom',
                        items: _classrooms,
                        selectedItem: _selectedClassroom,
                        onSelect: (value) {
                          setState(() {
                            _selectedClassroom = value;
                            _filterStaff();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomMultiSelectDropdown(
                        hintText: 'Tags',
                        items: _tags,
                        selectedItems: _selectedTag,
                        onChanged: (selectedItems) {
                          setState(() {
                            _selectedTag = selectedItems;
                            _filterStaff();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    CustomCheckbox(
                      value: isSelectAllChecked,
                      onChanged: _toggleSelectAll,
                      borderColor: AppColors.themeColor,
                    ),
                    const SizedBox(width: 8),
                    AppText.body('Select All'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _filteredStaff.isEmpty
                ? const Center(child: AppText.body('No staff found'))
                : GridView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 24 : 16,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: isTablet ? 16 : 12,
                      mainAxisSpacing: isTablet ? 16 : 12,
                      mainAxisExtent: isTablet ? 60 : 52,
                    ),
                    itemCount: _filteredStaff.length,
                    itemBuilder: (context, index) {
                      final staff = _filteredStaff[index];
                      final isSelected = selectedStaff.contains(staff);

                      return _buildStaffItem(staff, isSelected);
                    },
                  ),
          ),
        ],
      ),
      bottomBar: Padding(
        padding: EdgeInsets.only(bottom: safeAreaBottom),
        child: CustomButtonLayout(
          confirmButtonLabel: 'Next',
          onPressedConfirm: _handleNext,
          showCancelButton: false,
        ),
      ),
    );
  }

  Widget _buildStaffItem(StaffEntity staff, bool isSelected) {
    return InkWell(
      onTap: () => _toggleStaffSelection(staff, !isSelected),
      child: CustomSectionCard(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        backgroundColor: isSelected
            ? AppColors.fieldBackgroundColor
            : AppColors.cardColor,
        child: Row(
          children: [
            CustomCheckbox(
              value: isSelected,
              onChanged: (value) => _toggleStaffSelection(staff, value),
              borderColor: AppColors.themeColor,
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 12,
              backgroundColor: AppColors.themeColor,
              child: Text(
                _getInitials(staff.name),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: AppText.value(
                staff.name.split(' ').first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}
