import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/domain/features/staff_classroom/entities/staff_classroom_item.dart';
import 'package:wowcare/presentation/features/classroom/view_model/assign_staff_confirmation_cubit.dart';
import 'package:wowcare/presentation/features/classroom/view_model/assign_staff_confirmation_state.dart';
import 'package:wowcare/presentation/features/classroom/view_model/assign_staff_selection_cubit.dart';
import 'package:wowcare/presentation/features/classroom/view_model/assign_staff_selection_state.dart';
import 'package:wowcare/presentation/features/classroom/forms/widgets/assign_classroom_form_widgets.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/common/widgets/ellipsis_tooltip_text.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';

/// [StaffClassroomItem.profilePictureUrl] can hold either a full URL or a
/// bare media asset code — [DocumentImageWidget] needs to know which.
bool _looksLikeUrl(String raw) =>
    raw.startsWith('http://') || raw.startsWith('https://');

String? _staffImageUrl(StaffClassroomItem staff) {
  final raw = (staff.profilePictureUrl ?? '').trim();
  return _looksLikeUrl(raw) ? raw : null;
}

String? _staffAssetCode(StaffClassroomItem staff) {
  final raw = (staff.profilePictureUrl ?? '').trim();
  return (!_looksLikeUrl(raw) && raw.isNotEmpty) ? raw : null;
}

class AssignStaffToClassroomForm extends StatelessWidget {
  const AssignStaffToClassroomForm({
    required this.selectedRoomName,
    required this.classroomCode,
    required this.onStaffsAssigned,
    super.key,
  });

  final String selectedRoomName;
  final String classroomCode;
  final VoidCallback onStaffsAssigned;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AssignStaffSelectionCubit>(
      create: (_) =>
          serviceLocator<AssignStaffSelectionCubit>()
            ..init(classroomCode: classroomCode),
      child: _AssignStaffSelectionView(
        selectedRoomName: selectedRoomName,
        classroomCode: classroomCode,
        onStaffsAssigned: onStaffsAssigned,
      ),
    );
  }
}

class _AssignStaffSelectionView extends StatefulWidget {
  const _AssignStaffSelectionView({
    required this.selectedRoomName,
    required this.classroomCode,
    required this.onStaffsAssigned,
  });

  final String selectedRoomName;
  final String classroomCode;
  final VoidCallback onStaffsAssigned;

  @override
  State<_AssignStaffSelectionView> createState() =>
      _AssignStaffSelectionViewState();
}

class _AssignStaffSelectionViewState extends State<_AssignStaffSelectionView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    context.read<AssignStaffSelectionCubit>().onSearchChanged(
      _searchController.text,
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AssignStaffSelectionCubit>();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AssignFormHeader(title: 'Assign to ${widget.selectedRoomName}'),
          const SizedBox(height: 16),
          const Text(
            'Select Staffs',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          AssignFormSearchBar(
            controller: _searchController,
            hintText: 'Search Staff',
          ),
          const SizedBox(height: 12),
          BlocBuilder<AssignStaffSelectionCubit, AssignStaffSelectionState>(
            builder: (context, state) => Row(
              children: [
                Expanded(
                  flex: 4,
                  child: CustomDropdown(
                    onSelect: cubit.selectClassroom,
                    hintText: 'Classroom',
                    items: state.rooms,
                    isField: true,
                    isEnabled: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: CustomMultiSelectDropdown(
                    hintText: 'Designations',
                    showSelectAll: true,
                    items: state.designations,
                    selectedItems: state.selectedDesignations,
                    onChanged: cubit.selectDesignations,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          BlocBuilder<AssignStaffSelectionCubit, AssignStaffSelectionState>(
            builder: (context, state) => SelectAllCheckboxRow(
              value: state.isSelectAllChecked,
              onChanged: (value) => cubit.toggleSelectAll(value ?? false),
              checkboxBuilder: (value, onChanged) => CustomCheckbox(
                borderColor: AppColors.themeColor,
                value: value,
                onChanged: onChanged,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child:
                BlocBuilder<
                  AssignStaffSelectionCubit,
                  AssignStaffSelectionState
                >(
                  builder: (context, state) => AssignFormResultsArea(
                    isLoading: state.isLoading,
                    errorMessage: state.errorMessage,
                    onRetry: cubit.loadStaff,
                    content: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            mainAxisExtent: 72,
                          ),
                      itemCount: state.visibleStaff.length,
                      itemBuilder: (context, index) {
                        final staff = state.visibleStaff[index];
                        final isSelected = state.selectedStaff.contains(staff);
                        return StaffListItem(
                          staff: staff,
                          isSelected: isSelected,
                          isSignedIn: state.isStaffSignedIn(staff.staffCode),
                          todayStatusRaw:
                              state.todayStatusByCode[staff.staffCode],
                          onSelectionChanged: (value) =>
                              cubit.toggleStaff(staff, value ?? false),
                        );
                      },
                    ),
                  ),
                ),
          ),
          const SizedBox(height: 16),
          BlocBuilder<AssignStaffSelectionCubit, AssignStaffSelectionState>(
            builder: (context, state) => CustomButtonLayout(
              confirmButtonLabel: 'Next',
              cancelButtonLabel: 'Cancel',
              onPressedCancel: () => Navigator.pop(context),
              onPressedConfirm: () {
                if (state.selectedStaff.isEmpty) {
                  CoreUtils.showTopSnackBar(
                    context: context,
                    message: 'Please select at least one staff member',
                    isWarning: true,
                  );
                  return;
                }
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: AppColors.transparentColor,
                  builder: (context) => DraggableScrollableSheet(
                    maxChildSize: 0.95,
                    builder: (_, controller) => StaffConfirmationForm(
                      selectedStaffs: state.selectedStaff,
                      selectedRoomName: widget.selectedRoomName,
                      classroomCode: widget.classroomCode,
                      onStaffsAssigned: widget.onStaffsAssigned,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class StaffConfirmationForm extends StatelessWidget {
  const StaffConfirmationForm({
    required this.selectedStaffs,
    required this.selectedRoomName,
    required this.classroomCode,
    required this.onStaffsAssigned,
    super.key,
  });

  final Set<StaffClassroomItem> selectedStaffs;
  final String selectedRoomName;
  final String classroomCode;
  final VoidCallback onStaffsAssigned;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AssignStaffConfirmationCubit>(
      create: (_) =>
          serviceLocator<AssignStaffConfirmationCubit>()..init(selectedStaffs),
      child: _StaffConfirmationView(
        selectedRoomName: selectedRoomName,
        classroomCode: classroomCode,
        onStaffsAssigned: onStaffsAssigned,
      ),
    );
  }
}

class _StaffConfirmationView extends StatelessWidget {
  const _StaffConfirmationView({
    required this.selectedRoomName,
    required this.classroomCode,
    required this.onStaffsAssigned,
  });

  final String selectedRoomName;
  final String classroomCode;
  final VoidCallback onStaffsAssigned;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AssignStaffConfirmationCubit>();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AssignFormHeader(title: 'Assign to $selectedRoomName'),
          const SizedBox(height: 16),
          BlocBuilder<
            AssignStaffConfirmationCubit,
            AssignStaffConfirmationState
          >(
            builder: (context, state) {
              if (state.selectedStaff.isEmpty) {
                return const AssignFormEmptySelection(
                  message: 'No staff selected',
                );
              }
              final staffList = state.selectedStaff.toList();
              return Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 72,
                  ),
                  itemCount: staffList.length,
                  itemBuilder: (context, index) {
                    final staff = staffList[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.themeColor),
                        borderRadius: BorderRadius.circular(10),
                        color: AppColors.classroomNeutralTintColor,
                      ),
                      child: Row(
                        children: [
                          DocumentImageWidget(
                            fileUuid: '',
                            imageUrl: _staffImageUrl(staff),
                            mediaAssetCode: _staffAssetCode(staff),
                            name: staff.fullName,
                            staffCode: staff.staffCode,
                            size: 32,
                            fontSize: 12,
                            disableAttendanceStatusLookup: true,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: EllipsisTooltipText(
                              text: staff.fullName.trim().isEmpty
                                  ? 'Staff'
                                  : staff.fullName.trim(),
                              maxLines: 2,
                              preferLongPress: true,
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                color: AppColors.primaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => cubit.removeStaff(staff),
                            child: SvgPicture.asset(MediaRes.delete_icon),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          BlocBuilder<
            AssignStaffConfirmationCubit,
            AssignStaffConfirmationState
          >(
            builder: (context, state) => CustomButtonLayout(
              confirmButtonLabel: 'Submit',
              cancelButtonLabel: 'Cancel',
              onPressedCancel: () => Navigator.pop(context),
              onPressedConfirm: state.isSubmitting
                  ? () {}
                  : () => submitClassroomAssignment(
                      context: context,
                      isSelectionEmpty: state.selectedStaff.isEmpty,
                      emptySelectionMessage:
                          'Please select at least one staff member',
                      submit: () => cubit.submit(classroomCode: classroomCode),
                      onSuccess: onStaffsAssigned,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class StaffListItem extends StatelessWidget {
  const StaffListItem({
    required this.staff,
    required this.isSelected,
    required this.onSelectionChanged,
    this.isSignedIn = false,
    this.todayStatusRaw,
    super.key,
  });

  final StaffClassroomItem staff;
  final bool isSelected;
  final bool isSignedIn;
  final String? todayStatusRaw;
  final ValueChanged<bool?> onSelectionChanged;

  String get _disabledReason =>
      "${staff.fullName.trim().isEmpty ? 'This staff member' : staff.fullName.trim()} is already signed in. Please sign out before assigning to another classroom.";

  // Same green (signed in) / red (absent) attendance dot shown on the
  // classroom roster (classroom_staff_tab_card.dart) — passed in manually
  // here since the status is already batch-fetched for this whole grid.
  Color? get _attendanceDotColor {
    final normalized = (todayStatusRaw ?? '').trim().toUpperCase();
    if (normalized == 'SIGNED_IN')
      return AppColors.classroomPositiveStatusColor;
    if (normalized == 'ABSENT') return AppColors.classroomNegativeStatusColor;
    return null;
  }

  String? get _attendanceTooltip {
    final normalized = (todayStatusRaw ?? '').trim().toUpperCase();
    if (normalized == 'SIGNED_IN') return 'Staff is signed in';
    if (normalized == 'ABSENT') return 'Staff is absent';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final content = InkWell(
      onTap: () {
        if (isSignedIn) {
          CoreUtils.showTopSnackBar(
            context: context,
            message: _disabledReason,
            isWarning: true,
          );
          return;
        }
        onSelectionChanged(!isSelected);
      },
      child: Opacity(
        opacity: isSignedIn ? 0.45 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.themeColor),
            borderRadius: BorderRadius.circular(8),
            color: isSelected
                ? AppColors.classroomNeutralTintColor
                : AppColors.cardColor,
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
                    onChanged: isSignedIn ? null : onSelectionChanged,
                  ),
                ),
                DocumentImageWidget(
                  fileUuid: '',
                  imageUrl: _staffImageUrl(staff),
                  mediaAssetCode: _staffAssetCode(staff),
                  name: staff.fullName,
                  staffCode: staff.staffCode,
                  size: 32,
                  fontSize: 12,
                  statusColor: _attendanceDotColor,
                  statusTooltip: _attendanceTooltip,
                  disableAttendanceStatusLookup: true,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: EllipsisTooltipText(
                    text: staff.fullName.trim().isEmpty
                        ? 'Staff'
                        : staff.fullName.trim(),
                    maxLines: 2,
                    preferLongPress: true,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
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
      ),
    );

    if (isSignedIn) {
      return Tooltip(message: _disabledReason, child: content);
    }
    return content;
  }
}

// NOTE: Designation multi-select uses the shared `CustomMultiSelectDropdown`
// (`lib/shared/common/widgets/custom_multi_select_dropdown.dart`).
