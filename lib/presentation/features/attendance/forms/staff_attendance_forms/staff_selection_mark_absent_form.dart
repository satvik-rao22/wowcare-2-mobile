import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_absent_form_list_usecase.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'staff_entity.dart';
import 'staff_mark_absent_form.dart';

class StaffSelectionMarkAbsentForm extends StatefulWidget {
  static const String routeName = '/staff-selection-mark-absent-form';

  const StaffSelectionMarkAbsentForm({super.key, this.initialStaffCodes});

  final Set<String>? initialStaffCodes;

  @override
  State<StaffSelectionMarkAbsentForm> createState() =>
      _StaffSelectionMarkAbsentFormState();
}

class _StaffSelectionMarkAbsentFormState
    extends State<StaffSelectionMarkAbsentForm> {
  bool isSelectAllChecked = false;
  String? _selectedClassroom = null;
  List<String> _selectedTag = [];
  List<StaffEntity> _filteredStaff = [];
  Set<StaffEntity> selectedStaff = {};
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;

  final List<StaffEntity> _allStaff = [];

  final List<String> _classrooms = [
    'Classroom A',
    'Classroom B',
    'Classroom C',
    'Classroom D'
  ];
  final List<String> _designations = [
    'OWNER',
    'DIRECTOR',
    'ADMIN',
    'ASSISTANT_DIRECTOR',
    'LEAD_TEACHER',
    'ASSOCIATE_TEACHER',
    'ASSISTANT_TEACHER',
    'FLOATER',
    'KIOSK_USER',
  ];

  late final GetStaffAbsentFormListUseCase _getStaffAbsentFormListUseCase;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _getStaffAbsentFormListUseCase =
        serviceLocator<GetStaffAbsentFormListUseCase>();
    _loadStaff();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterStaff();
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
          final classroomName = 'Classroom '
              '${String.fromCharCode(65 + ((staff.primaryRoomId - 1) % 4))}';
          matchesRoom = _selectedClassroom == classroomName;
        }

        if (_selectedTag.isNotEmpty) {
          final selected = _selectedTag.map((e) => e.trim().toUpperCase()).toSet();
          final d = (staff.designation ?? '').trim().toUpperCase();
          matchesTag = selected.contains(d);
        }

        return matchesSearch && matchesRoom && matchesTag;
      }).toList();
    });
  }

  void _toggleSelectAll(bool? value) {
    if (value == null) return;

    setState(() {
      isSelectAllChecked = value;

      final List<StaffEntity> visibleStaff = _getVisibleStaff();

      if (value) {
        selectedStaff.addAll(visibleStaff);
      } else {
        selectedStaff.removeAll(visibleStaff);
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

      final visibleStaff = _getVisibleStaff();
      isSelectAllChecked = visibleStaff.every(
        (s) => selectedStaff.contains(s),
      );
    });
  }

  List<StaffEntity> _getVisibleStaff() {
    return _filteredStaff.isEmpty &&
            _searchController.text.isEmpty &&
            (_selectedClassroom == null || _selectedClassroom!.isEmpty) &&
            _selectedTag.isEmpty
        ? _allStaff
        : _filteredStaff;
  }

  Widget _buildShimmerGrid() {
    return const Center(child: PrimaryCircularLoader());
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadStaff() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final today = DateTime.now();
      final dateString = _formatDate(today);

      final classroomCodes =
          _selectedClassroom != null && _selectedClassroom!.isNotEmpty
              ? <String>[_selectedClassroom!]
              : null;

      final tagCodes = _selectedTag.isNotEmpty ? _selectedTag : null;

      final searchText =
          _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null;

      final page = await _getStaffAbsentFormListUseCase(
        fromAbsenceDate: dateString,
        toAbsenceDate: dateString,
        classroomCodes: classroomCodes,
        tagCodes: tagCodes,
        search: searchText,
        page: 0,
        size: 100,
      );

      if (!mounted) return;

      final staffList = page.items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return StaffEntity(
          id: index + 1,
          name: item.staffName,
          primaryRoomId: 0,
          photoUuid: null,
          // Absent form entity doesn't expose designation list; use a safe default label.
          designation: 'Staff',
          staffCode: item.staffCode,
        );
      }).toList();

      setState(() {
        _allStaff
          ..clear()
          ..addAll(staffList);
        _filteredStaff = List.from(staffList);
        _isLoading = false;
      });

      // Preselect based on initial staff codes if provided
      if (widget.initialStaffCodes != null &&
          widget.initialStaffCodes!.isNotEmpty) {
        selectedStaff = _allStaff
            .where((e) => e.staffCode != null && widget.initialStaffCodes!.contains(e.staffCode!))
            .toSet();
        _filterStaff();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleNext() {
    if (selectedStaff.isEmpty) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: 
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
        builder: (context) => StaffMarkAbsentForm(
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
      title: 'Mark Absent',
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
                  hintText: 'Designation',
                  items: _designations,
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
            child: _isLoading
                ? _buildShimmerGrid()
                : _getVisibleStaff().isEmpty
                    ? const Center(child: AppText.body('No staff found'))
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
                        itemCount: _getVisibleStaff().length,
                        itemBuilder: (context, index) {
                          final staff = _getVisibleStaff()[index];
                          final isSelected =
                              selectedStaff.contains(staff);

                          return StaffListItem(
                            staff: staff,
                            isSelected: isSelected,
                            onSelectionChanged: (value) {
                              _toggleStaffSelection(staff, value);
                            },
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
      onTap: () {
        onSelectionChanged(!isSelected);
      },
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

