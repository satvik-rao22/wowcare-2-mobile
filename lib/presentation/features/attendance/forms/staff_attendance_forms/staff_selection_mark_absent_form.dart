import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/presentation/features/attendance/widgets/attendance_search_field.dart';
import 'package:wowcare/presentation/features/attendance/widgets/attendance_staff_list_item.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/spacing.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/cubit/staff_mark_absent_selection_cubit.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
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
  String? _selectedClassroomCode;
  List<String> _selectedTag = [];
  List<StaffEntity> _filteredStaff = [];
  Set<StaffEntity> selectedStaff = {};
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;

  final List<StaffEntity> _allStaff = [];

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

  late final StaffMarkAbsentSelectionCubit _selectionCubit;
  late final ClassroomCubit _classroomCubit;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _selectionCubit = serviceLocator<StaffMarkAbsentSelectionCubit>();
    _classroomCubit = serviceLocator<ClassroomCubit>()
      ..loadActiveClassrooms(
        onlyTypeClassroom: false,
        applyAttendanceStaffScope: true,
      );
    _loadStaff();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _selectionCubit.close();
    super.dispose();
  }

  void _onSearchChanged() => _loadStaff();

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
      isSelectAllChecked = visibleStaff.every((s) => selectedStaff.contains(s));
    });
  }

  List<StaffEntity> _getVisibleStaff() {
    final selectedClassroomCode = _selectedClassroomCode;
    return _filteredStaff.isEmpty &&
            _searchController.text.isEmpty &&
            (selectedClassroomCode == null || selectedClassroomCode.isEmpty) &&
            _selectedTag.isEmpty
        ? _allStaff
        : _filteredStaff;
  }

  Widget _buildShimmerGrid() {
    return const Center(child: PrimaryCircularLoader());
  }

  /// Delegates the fetch to [StaffMarkAbsentSelectionCubit] (owns timezone
  /// bootstrap, "today" resolution, and the raw API call). No client-side
  /// designation filter here — the absent-form-list item doesn't expose a
  /// designation list, matching the pre-cubit behavior exactly.
  Future<void> _loadStaff() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final selectedClassroomCode = _selectedClassroomCode;
    final tagCodes = _selectedTag.isNotEmpty ? _selectedTag : null;
    final searchText = _searchController.text.trim().isNotEmpty
        ? _searchController.text.trim()
        : null;

    await _selectionCubit.loadStaff(
      classroomCode: selectedClassroomCode,
      tagCodes: tagCodes,
      search: searchText,
    );
    if (!mounted) return;

    final selectionState = _selectionCubit.state;
    if (selectionState.errorMessage != null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final staffList = selectionState.allStaff;
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
          .where((e) => widget.initialStaffCodes!.contains(e.staffCode))
          .toSet();
    }
  }

  void _handleNext() {
    if (selectedStaff.isEmpty) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: const SnackBar(
          content: Text('Please select at least one staff member'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    context.push(
      '/attendance/staff-mark-absent',
      extra: {'staffList': selectedStaff.toList()},
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper(context).isTabletCompact;
    final mediaQuery = MediaQuery.of(context);
    final safeAreaBottom = mediaQuery.padding.bottom;

    return BlocProvider<ClassroomCubit>.value(
      value: _classroomCubit,
      child: StaffFormLayout(
        title: 'Mark Absent',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppText.subtitle('Select Staff'),
            const SizedBox(height: AppSpacing.sm),
            AttendanceSearchField(
              controller: _searchController,
              hintText: 'Search Staff',
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: BlocBuilder<ClassroomCubit, ClassroomState>(
                    builder: (context, state) {
                      final classroomNames = state.classrooms
                          .map((c) => c.name)
                          .toList();
                      if (_classroomNameToCode.isEmpty &&
                          state.classrooms.isNotEmpty) {
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
                            _selectedClassroomCode = value == null
                                ? null
                                : _classroomNameToCode[value];
                          });
                          _loadStaff();
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
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
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  child: CustomCheckbox(
                    value: isSelectAllChecked,
                    onChanged: _toggleSelectAll,
                    borderColor: AppColors.themeColor,
                  ),
                ),
                const AppText.body('Select All'),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: _isLoading
                  ? _buildShimmerGrid()
                  : _getVisibleStaff().isEmpty
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
                      itemCount: _getVisibleStaff().length,
                      itemBuilder: (context, index) {
                        final staff = _getVisibleStaff()[index];
                        final isSelected = selectedStaff.contains(staff);

                        return AttendanceStaffListItem(
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
      ),
    );
  }
}
