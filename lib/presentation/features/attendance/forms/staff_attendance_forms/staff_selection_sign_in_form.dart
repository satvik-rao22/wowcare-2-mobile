import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'staff_entity.dart';
import 'staff_sign_in_form.dart';

class StaffSelectionSignInForm extends StatefulWidget {
  static const String routeName = '/staff-selection-sign-in-form';

  const StaffSelectionSignInForm({
    super.key,
  });

  @override
  State<StaffSelectionSignInForm> createState() =>
      _StaffSelectionSignInFormState();
}

class _StaffSelectionSignInFormState
    extends State<StaffSelectionSignInForm> {
  bool isSelectAllChecked = false;
  String? _selectedClassroom = '';
  List<String> _selectedTag = [];
  Set<StaffEntity> selectedStaff = {};
  final TextEditingController _searchController = TextEditingController();

  // Mock data for UI-only implementation
  final List<StaffEntity> _allStaff = List.generate(
      20,
      (index) => StaffEntity(
            id: index + 1,
            name: 'Staff ${index + 1}',
            primaryRoomId: (index % 4) + 1,
            photoUuid: '',
            designation: index % 3 == 0
                ? 'Teacher'
                : index % 3 == 1
                    ? 'Admin'
                    : 'Staff',
          ));

  final List<String> _classrooms = [
    'Classroom A',
    'Classroom B',
    'Classroom C',
    'Classroom D'
  ];
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
          // Map staff primary room to classroom name (A-D) for UI-only filtering
          final classroomName = 'Classroom '
              '${String.fromCharCode(65 + ((staff.primaryRoomId - 1) % 4))}';
          matchesRoom = _selectedClassroom == classroomName;
        }

        // Tag matching would be implemented with actual tag data
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

    // For UI-only, navigate to the first selected staff's form
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StaffSignInForm(
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
      title: 'Sign-In',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText.subtitle('Select Staff'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F7FA),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search Staff',
                hintStyle: AppTextStyles.body.copyWith(
                  color: Colors.grey[700],
                ),
                border: InputBorder.none,
                icon: const Icon(Icons.search, color: Colors.grey),
              ),
              onChanged: (_) => _filterStaff(),
            ),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: CustomCheckbox(
                  value: isSelectAllChecked,
                  onChanged: _toggleSelectAll,
                  borderColor: AppColors.themeColor,
                ),
              ),
              const AppText.body('Select All'),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _filteredStaff.isEmpty
                ? const Center(child: AppText.body("No staff found"))
                : GridView.builder(
                    shrinkWrap: false,
                    physics: const AlwaysScrollableScrollPhysics(),
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: isTablet ? 16 : 12,
                      mainAxisSpacing: isTablet ? 16 : 12,
                      mainAxisExtent: 52,
                    ),
                    itemCount: _filteredStaff.length,
                    itemBuilder: (context, index) {
                      final staff = _filteredStaff[index];
                      final isSelected =
                          selectedStaff.contains(staff);

                      return StaffListItem(
                        staff: staff,
                        isSelected: isSelected,
                        onSelectionChanged: (value) =>
                            _toggleStaffSelection(staff, value),
                      );
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

}

class StaffListItem extends StatelessWidget {
  final StaffEntity staff;
  final bool isSelected;
  final ValueChanged<bool?> onSelectionChanged;

  const StaffListItem({
    super.key,
    required this.staff,
    required this.isSelected,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onSelectionChanged(!isSelected),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.themeColor,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? const Color.fromARGB(255, 249, 245, 250)
              : Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: CustomCheckbox(
                  borderColor: AppColors.themeColor,
                  value: isSelected,
                  onChanged: onSelectionChanged,
                ),
              ),
              DocumentImageWidget(
                fileUuid: staff.photoUuid ?? '',
                name: staff.name,
                size: 32,
                fontSize: 14,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  staff.name.split(' ').first,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

