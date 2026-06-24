import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/attendance/util/attendance_school_time.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/ellipsis_tooltip_text.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/shared/utils/responsive_sizing.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_transfer_form_list_usecase.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'staff_entity.dart';
import 'staff_transfer_form.dart';

class StaffSelectionTransferForm extends StatefulWidget {
  const StaffSelectionTransferForm({super.key, this.initialStaffCodes});

  static const String routeName = '/staff-selection-transfer-form';

  final Set<String>? initialStaffCodes;

  @override
  State<StaffSelectionTransferForm> createState() =>
      _StaffSelectionTransferFormState();
}

class _StaffSelectionTransferFormState
    extends State<StaffSelectionTransferForm> {
  bool isSelectAllChecked = false;
  String? _selectedClassroomCode;
  List<String> _selectedTag = [];
  Set<StaffEntity> selectedStaff = {};
  final TextEditingController _searchController = TextEditingController();

  final Map<String, String> _classroomNameToCode = <String, String>{};
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

  List<StaffEntity> _filteredStaff = [];

  bool _isLoading = false;
  String? _errorMessage;

  late final GetStaffTransferFormListUseCase _getStaffTransferFormListUseCase;
  late final ClassroomCubit _classroomCubit;

  @override
  void initState() {
    super.initState();
    _getStaffTransferFormListUseCase =
        serviceLocator<GetStaffTransferFormListUseCase>();
    _classroomCubit = serviceLocator<ClassroomCubit>()
      ..loadActiveClassrooms(
        onlyTypeClassroom: false,
        applyAttendanceStaffScope: true,
      );
    _loadStaff();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadStaff() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await bootstrapAttendanceSchoolTimezone();
      final today = attendanceSchoolToday();
      final dateString = _formatDate(today);

      final selectedClassroomCode = _selectedClassroomCode;
      final classroomCodes =
          selectedClassroomCode != null && selectedClassroomCode.isNotEmpty
              ? <String>[selectedClassroomCode]
              : null;

      final tagCodes = _selectedTag.isNotEmpty ? _selectedTag : null;

      final searchText =
          _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null;

      final page = await _getStaffTransferFormListUseCase(
        fromAbsenceDate: dateString,
        toAbsenceDate: dateString,
        classroomCodes: classroomCodes,
        tagCodes: tagCodes,
        search: searchText,
        page: 0,
        size: 200,
      );

      if (!mounted) return;

      final staffList = page.items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return StaffEntity(
          id: index + 1,
          name: item.staffName,
          primaryRoomId: 0,
          classroomCode: item.classroomCode,
          classroomName: item.classroomName,
          photoUuid: null,
          designation: item.designation.isNotEmpty ? item.designation.first : 'Staff',
          staffCode: item.staffCode,
        );
      }).toList();

      // Local filtering for Designation and Search
      List<StaffEntity> locallyFiltered = staffList;
      if (_selectedTag.isNotEmpty) {
        final selected = _selectedTag.map((e) => e.trim().toUpperCase()).toSet();
        locallyFiltered = locallyFiltered.where((s) {
          final d = s.designation.trim().toUpperCase();
          return selected.contains(d);
        }).toList();
      }
      if (searchText != null && searchText.trim().isNotEmpty) {
        final q = searchText.toLowerCase();
        locallyFiltered = locallyFiltered
            .where((s) => s.name.toLowerCase().contains(q))
            .toList();
      }

      // Preselect based on initial staff codes if provided
      if (widget.initialStaffCodes != null &&
          widget.initialStaffCodes!.isNotEmpty) {
        selectedStaff = locallyFiltered
            .where((e) => widget.initialStaffCodes!.contains(e.staffCode))
            .toSet();
      }

      setState(() {
        _filteredStaff = List.from(locallyFiltered);
        _isLoading = false;
        isSelectAllChecked = _filteredStaff.isNotEmpty &&
            _filteredStaff.every((s) => selectedStaff.contains(s));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = ApiErrorHandler.extractErrorMessage(e);
      });
    }
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

    return BlocProvider<ClassroomCubit>.value(
      value: _classroomCubit,
      child: StaffFormLayout(
      title: 'Transfer',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText.subtitle('Select Staff'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
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
              onChanged: (_) => _loadStaff(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: BlocBuilder<ClassroomCubit, ClassroomState>(
                  builder: (context, state) {
                    final classroomNames = state.classrooms.map((c) => c.name).toList();
                    if (_classroomNameToCode.isEmpty && state.classrooms.isNotEmpty) {
                      for (final c in state.classrooms) {
                        _classroomNameToCode[c.name] = c.code;
                      }
                    }
                    String? selectedName;
                    for (final entry in _classroomNameToCode.entries) {
                      if (entry.value == _selectedClassroomCode) {
                        selectedName = entry.key;
                        break;
                      }
                    }
                    return CustomDropdown(
                      hintText: 'Classroom',
                      items: classroomNames,
                      selectedItem: selectedName,
                      onSelect: (value) {
                        setState(() {
                          _selectedClassroomCode =
                              value == null ? null : _classroomNameToCode[value];
                        });
                        _loadStaff();
                      },
                    );
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
                    });
                    _loadStaff();
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
                ? const Center(child: PrimaryCircularLoader())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppText.body(
                              _errorMessage ?? 'Failed to load staff',
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _loadStaff,
                              child: const AppText.body('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredStaff.isEmpty
                        ? const Center(child: AppText.body('No staff found'))
                        : GridView.builder(
                            shrinkWrap: false,
                            physics: const AlwaysScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: isTablet ? 16 : 12,
                              mainAxisSpacing: isTablet ? 16 : 12,
                              mainAxisExtent: 72,
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
    ));
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
                staffCode: staff.staffCode,
                size: 32,
                fontSize: 14,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: EllipsisTooltipText(
                  text: staff.name,
                  maxLines: 2,
                  preferLongPress: true,
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

