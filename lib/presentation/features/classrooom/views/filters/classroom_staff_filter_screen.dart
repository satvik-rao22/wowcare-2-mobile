import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/classrooom/views/filters/designation_display_utils.dart';
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
  /// Backend designation codes (same set as legacy staff filter).
  static const List<String> _designationCodes = [
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

  late final Map<String, String> _labelToDesignationCode;
  late final List<String> _designationLabels;

  static const List<String> _statusUiItems = ['Active', 'Upcoming'];

  /// UI strings for status dropdown (matches student filter wording).
  final List<String> _selectedStatusUi = [];

  /// API codes multi-select from designation labels.
  final List<String> _selectedDesignationCodes = [];

  @override
  void initState() {
    super.initState();

    _labelToDesignationCode = {
      for (final c in _designationCodes)
        formatDesignationForDisplay(c): c,
    };
    _designationLabels = _labelToDesignationCode.keys.toList()..sort();

    final st = widget.initialStatus
        .map((e) => e.trim().toUpperCase())
        .where((e) => e.isNotEmpty)
        .toSet();
    if (st.contains('ACTIVE')) _selectedStatusUi.add('Active');
    if (st.contains('UPCOMING')) _selectedStatusUi.add('Upcoming');

    final des = widget.initialDesignation
        .map((e) => e.trim().toUpperCase())
        .where((e) => e.isNotEmpty)
        .toSet();
    for (final c in _designationCodes) {
      if (des.contains(c)) _selectedDesignationCodes.add(c);
    }
  }

  List<String> _designationLabelsSelected() {
    return _selectedDesignationCodes
        .map(formatDesignationForDisplay)
        .where(_labelToDesignationCode.containsKey)
        .toList();
  }

  void _onDesignationLabelsChanged(List<String> labels) {
    setState(() {
      final codes = <String>{};
      for (final lb in labels) {
        final c = _labelToDesignationCode[lb];
        if (c != null && c.trim().isNotEmpty) codes.add(c.trim());
      }
      _selectedDesignationCodes
        ..clear()
        ..addAll(codes);
    });
  }

  void _apply() {
    final statusApi = <String>[];
    for (final s in _selectedStatusUi) {
      if (s == 'Active') statusApi.add('ACTIVE');
      if (s == 'Upcoming') statusApi.add('UPCOMING');
    }

    Navigator.of(context).pop<ClassroomStaffFilterResult>(
      ClassroomStaffFilterResult(
        status: statusApi,
        designation: List<String>.from(_selectedDesignationCodes),
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
            items: _statusUiItems,
            selectedItems: List<String>.from(_selectedStatusUi),
            onChanged: (selectedItems) {
              setState(() {
                _selectedStatusUi
                  ..clear()
                  ..addAll(selectedItems);
              });
            },
          );
        }
        return CustomMultiSelectDropdown(
          label: labels[1],
          hintText: 'Select',
          items: _designationLabels,
          selectedItems: _designationLabelsSelected(),
          onChanged: _onDesignationLabelsChanged,
        );
      },
    );
  }
}
