import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/presentation/features/attendance/widgets/attendance_select_all_row.dart';
import 'package:wowcare/presentation/features/attendance/widgets/attendance_staff_list_item.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_forms/view_model/staff_sign_out_selection_cubit.dart';
import 'package:wowcare/presentation/features/classroom/view_model/classroom_cubit.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import '../../model/staff_entity.dart';

class StaffSelectionSignOutForm extends StatefulWidget {
  static const String routeName = '/staff-selection-sign-out-form';

  const StaffSelectionSignOutForm({super.key, this.initialStaffCodes});

  final Set<String>? initialStaffCodes;

  @override
  State<StaffSelectionSignOutForm> createState() =>
      _StaffSelectionSignOutFormState();
}

class _StaffSelectionSignOutFormState extends State<StaffSelectionSignOutForm> {
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

  late final StaffSignOutSelectionCubit _selectionCubit;
  late final ClassroomCubit _classroomCubit;

  @override
  void initState() {
    super.initState();
    _selectionCubit = serviceLocator<StaffSignOutSelectionCubit>();
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
    _selectionCubit.close();
    _classroomCubit.close();
    super.dispose();
  }

  /// Delegates the fetch to [StaffSignOutSelectionCubit] (owns timezone
  /// bootstrap, "today" resolution, and the raw API call). Loading/error
  /// state is read reactively from the cubit in [build] — this only
  /// triggers the fetch.
  Future<void> _loadStaff() {
    final selectedClassroomCode = _selectedClassroomCode;
    final tagCodes = _selectedTag.isNotEmpty ? _selectedTag : null;
    final searchText = _searchController.text.trim().isNotEmpty
        ? _searchController.text.trim()
        : null;

    return _selectionCubit.loadStaff(
      classroomCode: selectedClassroomCode,
      tagCodes: tagCodes,
      search: searchText,
    );
  }

  /// Designation/search post-filter — UI-derived filtering on top of the
  /// cubit's fetch, not a data concern (same as before the reactive
  /// conversion).
  List<StaffEntity> _applyLocalFilters(List<StaffEntity> staff) {
    var locallyFiltered = staff;
    if (_selectedTag.isNotEmpty) {
      final selected = _selectedTag.map((e) => e.trim().toUpperCase()).toSet();
      locallyFiltered = locallyFiltered.where((s) {
        final d = s.designation.trim().toUpperCase();
        return selected.contains(d);
      }).toList();
    }
    final searchText = _searchController.text.trim();
    if (searchText.isNotEmpty) {
      final q = searchText.toLowerCase();
      locallyFiltered = locallyFiltered
          .where((s) => s.name.toLowerCase().contains(q))
          .toList();
    }
    return locallyFiltered;
  }

  /// Reacts to a fresh staff list: matches the pre-conversion behavior
  /// exactly — re-applies the initialStaffCodes preselection on every load
  /// when provided, then recomputes select-all.
  void _onStaffChanged(List<StaffEntity> filteredStaff) {
    if (widget.initialStaffCodes != null &&
        widget.initialStaffCodes!.isNotEmpty) {
      selectedStaff = filteredStaff
          .where((e) => widget.initialStaffCodes!.contains(e.staffCode))
          .toSet();
    }
    isSelectAllChecked =
        filteredStaff.isNotEmpty &&
        filteredStaff.every((s) => selectedStaff.contains(s));
  }

  void _toggleSelectAll(bool? value, List<StaffEntity> filteredStaff) {
    if (value == null) return;

    setState(() {
      isSelectAllChecked = value;
      if (value) {
        selectedStaff.addAll(filteredStaff);
      } else {
        selectedStaff.removeAll(filteredStaff);
      }
    });
  }

  void _toggleStaffSelection(
    StaffEntity staff,
    bool? value,
    List<StaffEntity> filteredStaff,
  ) {
    if (value == null) return;

    setState(() {
      if (value) {
        selectedStaff.add(staff);
      } else {
        selectedStaff.remove(staff);
      }

      isSelectAllChecked = filteredStaff.every(
        (staff) => selectedStaff.contains(staff),
      );
    });
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
      '/attendance/staff-sign-out',
      extra: {'staffList': selectedStaff.toList()},
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = ResponsiveHelper(context).isTabletCompact;
    final safeAreaBottom = MediaQuery.paddingOf(context).bottom;

    return BlocProvider<ClassroomCubit>.value(
      value: _classroomCubit,
      child:
          BlocConsumer<StaffSignOutSelectionCubit, StaffSignOutSelectionState>(
            bloc: _selectionCubit,
            listenWhen: (previous, current) => previous.staff != current.staff,
            listener: (context, state) {
              setState(() {
                _onStaffChanged(_applyLocalFilters(state.staff));
              });
            },
            builder: (context, state) {
              final filteredStaff = _applyLocalFilters(state.staff);
              return StaffFormLayout(
                title: 'Sign-Out',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppText.subtitle('Select Staff'),
                    const SizedBox(height: AppSpacing.sm),
                    CustomSearchBar(
                      controller: _searchController,
                      hintText: 'Search Staff',
                      onChanged: (_) => _loadStaff(),
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
                              for (final entry
                                  in _classroomNameToCode.entries) {
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
                    AttendanceSelectAllRow(
                      isChecked: isSelectAllChecked,
                      onChanged: (value) =>
                          _toggleSelectAll(value, filteredStaff),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: state.isLoading
                          ? const Center(child: PrimaryCircularLoader())
                          : state.errorMessage != null
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AppText.body(
                                    state.errorMessage ??
                                        'Failed to load staff',
                                    style: AppTextStyles.body.copyWith(
                                      color: AppColors.errorColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  TextButton(
                                    onPressed: _loadStaff,
                                    child: const AppText.body('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : filteredStaff.isEmpty
                          ? const Center(child: AppText.body('No staff found'))
                          : GridView.builder(
                              shrinkWrap: false,
                              physics: const AlwaysScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: isTablet ? 16 : 12,
                                    mainAxisSpacing: isTablet ? 16 : 12,
                                    mainAxisExtent: 72,
                                  ),
                              itemCount: filteredStaff.length,
                              itemBuilder: (context, index) {
                                final staff = filteredStaff[index];
                                final isSelected = selectedStaff.contains(
                                  staff,
                                );

                                return AttendanceStaffListItem(
                                  staff: staff,
                                  isSelected: isSelected,
                                  onSelectionChanged: (value) =>
                                      _toggleStaffSelection(
                                        staff,
                                        value,
                                        filteredStaff,
                                      ),
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
            },
          ),
    );
  }
}
