import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/billing/cubit/select_students_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_search_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_clear_all_chip.dart';
import 'package:wowcare/shared/common/widgets/gradient_circular_progress.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/presentation/features/billing/widgets/create_invoice_screen.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/presentation/features/billing/widgets/models/student_models.dart';

// NOTE: UI-only screen. All API/backend-related code has been removed or commented out.
// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:wowcare/core/util/api_paths.dart';
// import 'package:wowcare/core/util/constants.dart';
// import 'package:wowcare/core/common/app/providers/auth_providers.dart';
// import 'package:wowcare/core/util/core_utils.dart';
// import 'selected_students_receipt_screen.dart';

class SelectStudentsScreen extends StatefulWidget {
  const SelectStudentsScreen({Key? key, this.invoiceData}) : super(key: key);
  final Map<String, dynamic>? invoiceData;

  @override
  State<SelectStudentsScreen> createState() => _SelectStudentsScreenState();
}

class _SelectStudentsScreenState extends State<SelectStudentsScreen> {
  late final SelectStudentsCubit _cubit = SelectStudentsCubit();
  final TextEditingController _searchController = TextEditingController();

  // Read-only proxies onto the cubit state so the build stays unchanged.
  List<Student> get students => _cubit.state.students;
  List<String> get classrooms => _cubit.state.classrooms;
  List<String> get tags => _cubit.state.tags;
  String get selectedClassroom => _cubit.state.selectedClassroom;
  String get selectedTag => _cubit.state.selectedTag;
  Set<int> get _selectedStudentIds => _cubit.state.selectedStudentIds;
  bool get isLoading => _cubit.state.isLoading;
  List<Student> get filteredStudents => _cubit.state.filteredStudents;

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
          final filtered = filteredStudents;
          final bool areAllSelected = filtered.isNotEmpty &&
              filtered.every(
                  (student) => _selectedStudentIds.contains(student.id));

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
                              onChanged: (value) => _cubit.setSearchQuery(value),
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
                      CustomDropdown(
                        hintText: selectedClassroom,
                        items: classrooms,
                        selectedItem: selectedClassroom,
                        onSelect: (val) {
                          if (val != null) _cubit.setClassroom(val);
                        },
                      ),
                      const SizedBox(height: 12),
                      CustomDropdown(
                        hintText: selectedTag,
                        items: tags,
                        selectedItem: selectedTag,
                        onSelect: (val) {
                          if (val != null) _cubit.setTag(val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: areAllSelected,
                      onChanged: (val) => _cubit.setAllSelected(
                        filtered.map((student) => student.id),
                        val ?? false,
                      ),
                      activeColor: AppColors.themeColor,
                      checkColor: AppColors.billingButtonTextColor,
                      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
                        if (states.contains(MaterialState.selected)) {
                          return AppColors.themeColor;
                        }
                        return AppColors.billingTransparentColor;
                      }),
                    ),
                    const Text(
                      'Select All',
                      style: TextStyle(
                        fontFamily: "Manrope",
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.billingTextColor,
                        height: 19 / 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: isLoading
                      ? const Center(child: GradientCircularProgress())
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final student = filtered[index];
                            final isChecked = _selectedStudentIds.contains(student.id);
                            return GestureDetector(
                              onTap: () => _cubit.toggleStudent(student.id),
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
                                      fileUuid: (student.photoUuid ?? student.fullName),
                                      name: student.fullName,
                                      size: 40,
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
                                          if (student.roomName != null) ...[
                                            const SizedBox(height: 2),
                                            Text(
                                              student.roomName!,
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
                                    Checkbox(
                                      value: isChecked,
                                      onChanged: (val) => _cubit
                                          .setStudentSelected(
                                              student.id, val ?? false),
                                      activeColor: AppColors.themeColor,
                                      checkColor: AppColors.billingButtonTextColor,
                                      fillColor: MaterialStateProperty.resolveWith<Color>((states) {
                                        if (states.contains(MaterialState.selected)) {
                                          return AppColors.themeColor;
                                        }
                                        return AppColors.billingTransparentColor;
                                      }),
                                    ),
                                  ],
                                ),
                              ),
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
          onPressed: () {
            // UI-only: handle "Next" with a placeholder
            final selectedStudents = _cubit.selectedStudents;
            if (selectedStudents.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Please select at least one student')),
              );
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreateInvoiceScreen(
                  selectedStudents: selectedStudents,
                  initialInvoiceData: widget.invoiceData,
                ),
              ),
            );
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