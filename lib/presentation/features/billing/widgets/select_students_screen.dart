import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/billing/cubit/select_students_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/presentation/features/billing/widgets/create_invoice_screen.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/presentation/features/billing/widgets/models/student_models.dart';

class SelectStudentsScreen extends StatefulWidget {
  const SelectStudentsScreen({Key? key, this.invoiceData, this.onNext})
      : super(key: key);
  final Map<String, dynamic>? invoiceData;

  /// Optional override for the "Next" action. When provided, it's called with
  /// the selected students instead of the default Create Invoice navigation
  /// (used e.g. for the Receive Payment flow).
  final void Function(BuildContext context, List<Student> students)? onNext;

  @override
  State<SelectStudentsScreen> createState() => _SelectStudentsScreenState();
}

class _SelectStudentsScreenState extends State<SelectStudentsScreen> {
  final SelectStudentsCubit _cubit = serviceLocator<SelectStudentsCubit>();
  final TextEditingController _searchController = TextEditingController();

  /// Status filter options (display names), mirroring the student list screen.
  static const List<String> _statusOptions = ['Active', 'Upcoming'];

  @override
  void initState() {
    super.initState();
    _cubit.initialize();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SelectStudentsCubit>.value(
      value: _cubit,
      child: BlocBuilder<SelectStudentsCubit, SelectStudentsState>(
        builder: (context, state) {
          final filtered = state.filteredStudents;
          final visibleCodes =
              filtered.map((student) => student.code).toList();
          final bool areAllSelected = filtered.isNotEmpty &&
              filtered.every(
                (student) => state.selectedStudentCodes.contains(student.code),
              );

          return StaffFormLayout(
            title: 'Select Students',
            bottomBar: _buildBottomBar(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.cardBorderColor),
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.cardColor,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: CustomSearchBar(
                              controller: _searchController,
                              hintText: 'Search Students',
                              onChanged: (value) =>
                                  _cubit.setSearchQuery(value),
                            ),
                          ),
                          const SizedBox(width: 8),
                          CustomClearAllChip(
                            onTap: () {
                              _searchController.clear();
                              _cubit.clearAll();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      CustomMultiSelectDropdown(
                        hintText: 'Select Classroom',
                        items: state.classroomNames,
                        selectedItems: state.selectedClassroomNames,
                        showSelectAll: true,
                        onChanged: (values) => _cubit.setClassrooms(values),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: CustomMultiSelectDropdown(
                              hintText: 'Tags',
                              items: state.tagNames,
                              selectedItems: state.selectedTagNames,
                              showSelectAll: true,
                              onChanged: (values) => _cubit.setTags(values),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CustomMultiSelectDropdown(
                              hintText: 'Status',
                              items: _statusOptions,
                              selectedItems: [state.selectedStatus],
                              onChanged: (values) => _cubit.setStatus(values),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                CustomCheckbox(
                  value: areAllSelected,
                  label: 'Select All',
                  labelStyle: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.billingTextColor,
                  ),
                  onChanged: (val) =>
                      _cubit.setAllSelected(visibleCodes, val ?? false),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: state.isLoading
                      ? const Center(child: PrimaryCircularLoader())
                      : (state.errorMessage != null && filtered.isEmpty)
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Text(
                                  state.errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 14,
                                    color: AppColors.billingTextColor,
                                  ),
                                ),
                              ),
                            )
                          : filtered.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No students found.',
                                    style: TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 14,
                                      color: AppColors.billingTextColor,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: filtered.length,
                                  itemBuilder: (context, index) {
                                    final student = filtered[index];
                                    final isChecked = state.selectedStudentCodes
                                        .contains(student.code);
                                    return _StudentRow(
                                      student: student,
                                      isChecked: isChecked,
                                      onTap: () =>
                                          _cubit.toggleStudent(student.code),
                                      onChanged: (val) =>
                                          _cubit.setStudentSelected(
                                              student.code, val ?? false),
                                    );
                                  },
                                ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom > 0
            ? MediaQuery.of(context).padding.bottom
            : 16.0,
        left: 16,
        right: 16,
        top: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.billingCardColor,
        boxShadow: [
          BoxShadow(
            color: AppColors.billingShadowColorLight,
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
      ),
      child: Container(
        height: 48.0,
        decoration: BoxDecoration(
          gradient: AppColors.buildPrimaryGradient(),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: TextButton(
          onPressed: () async {
            final selectedStudents = _cubit.selectedStudents;
            if (selectedStudents.isEmpty) {
              CoreUtils.showTopSnackBar(
                context: context,
                message: 'Please select at least one student.',
                isWarning: true,
              );
              return;
            }
            if (widget.onNext != null) {
              widget.onNext!(context, selectedStudents);
              return;
            }
            final created = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => CreateInvoiceScreen(
                  selectedStudents: selectedStudents,
                  initialInvoiceData: widget.invoiceData,
                ),
              ),
            );
            // Invoice saved from the preview step → close the wizard back to
            // the billing list.
            if (created == true && context.mounted) {
              Navigator.of(context).pop(true);
            }
          },
          child: const Text(
            'Next',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 16.0,
              fontWeight: FontWeight.w600,
              color: AppColors.billingCardColor,
            ),
          ),
        ),
      ),
    );
  }
}

class _StudentRow extends StatelessWidget {
  const _StudentRow({
    required this.student,
    required this.isChecked,
    required this.onTap,
    required this.onChanged,
  });

  final Student student;
  final bool isChecked;
  final VoidCallback onTap;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    // Compose the subtitle: classroom + age (e.g. "Room 101 · 2 yrs 3 mos").
    final parts = <String>[
      if ((student.roomName ?? '').trim().isNotEmpty) student.roomName!.trim(),
      if (student.ageLabel.trim().isNotEmpty) student.ageLabel.trim(),
    ];
    final subtitle = parts.join('  ·  ');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF6657F8), width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            DocumentImageWidget(
              fileUuid: '',
              studentCode: student.code,
              mediaAssetCode: (student.photoAssetCode ?? '').trim().isNotEmpty
                  ? student.photoAssetCode!.trim()
                  : null,
              name: student.fullName,
              size: 50,
              shape: BoxShape.circle,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.fullName,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.billingTextColor,
                      height: 19 / 14,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12,
                        color: Color(0x99573353),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            CustomCheckbox(
              value: isChecked,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
