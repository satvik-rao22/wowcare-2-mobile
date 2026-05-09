import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

/// Result for classroom Staff tab — maps to staff-classrooms API `status` + `designation`.
class ClassroomStaffFilterResult {
  const ClassroomStaffFilterResult({
    required this.status,
    required this.designation,
  });

  /// API status values, e.g. `ACTIVE`, `UPCOMING`.
  final List<String> status;

  /// API designation codes, e.g. `ASSOCIATE_TEACHER`.
  final List<String> designation;
}

/// Filter UI for classroom Staff tab only: **Status** + **Designation**.
/// Same layout pattern as [StaffFormLayout] + grid [CustomMultiSelectDropdown]s.
class ClassroomStaffFilterScreen extends StatefulWidget {
  const ClassroomStaffFilterScreen({
    super.key,
    this.initialStatus = const [],
    this.initialDesignation = const [],
  });

  final List<String> initialStatus;
  final List<String> initialDesignation;

  @override
  State<ClassroomStaffFilterScreen> createState() =>
      _ClassroomStaffFilterScreenState();
}

class _ClassroomStaffFilterScreenState extends State<ClassroomStaffFilterScreen> {
  /// Same backend codes as [StaffFilterScreen] designation list.
  static const List<String> _designationList = [
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

  static const List<String> _statusList = ['ACTIVE', 'UPCOMING'];

  final List<String> _selectedStatus = [];
  final List<String> _selectedDesignation = [];

  @override
  void initState() {
    super.initState();

    final st = widget.initialStatus
        .map((e) => e.trim().toUpperCase())
        .where((e) => e.isNotEmpty)
        .toSet();
    for (final s in _statusList) {
      if (st.contains(s)) _selectedStatus.add(s);
    }

    final des = widget.initialDesignation
        .map((e) => e.trim().toUpperCase())
        .where((e) => e.isNotEmpty)
        .toSet();
    for (final d in _designationList) {
      if (des.contains(d)) _selectedDesignation.add(d);
    }
  }

  void _apply() {
    Navigator.of(context).pop<ClassroomStaffFilterResult>(
      ClassroomStaffFilterResult(
        status: List<String>.from(_selectedStatus),
        designation: List<String>.from(_selectedDesignation),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);

    return StaffFormLayout(
      title: 'Filter Staff',
      child: _buildGrid(),
      bottomBar: _buildBottomBar(context, responsive),
    );
  }

  Widget _buildBottomBar(BuildContext context, ResponsiveHelper responsive) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: safeAreaBottom,
      ),
      child: CustomButtonLayout(
        confirmButtonLabel: 'Apply Filters',
        onPressedConfirm: _apply,
        showCancelButton: false,
        isForm: false,
      ),
    );
  }

  Widget _buildGrid() {
    const labels = ['Status', 'Designation'];
    return GridView.builder(
      padding: EdgeInsets.zero,
      itemCount: 2,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.6,
      ),
      itemBuilder: (context, index) {
        if (index == 0) {
          return CustomMultiSelectDropdown(
            label: labels[0],
            hintText: 'Select',
            items: _statusList,
            selectedItems: List<String>.from(_selectedStatus),
            onChanged: (selectedItems) {
              setState(() {
                _selectedStatus
                  ..clear()
                  ..addAll(
                    selectedItems.isEmpty
                        ? const <String>[]
                        : <String>[selectedItems.last],
                  );
              });
            },
          );
        }
        return CustomMultiSelectDropdown(
          label: labels[1],
          hintText: 'Select',
          items: _designationList,
          selectedItems: List<String>.from(_selectedDesignation),
          onChanged: (selectedItems) {
            setState(() {
              _selectedDesignation
                ..clear()
                ..addAll(selectedItems);
            });
          },
        );
      },
    );
  }
}
