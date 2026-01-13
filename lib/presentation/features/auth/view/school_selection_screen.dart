import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/dashboard/view/dashboard_screen.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/select_flow_header.dart';
import 'package:wowcare/shared/common/widgets/select_step_layout.dart';

class SchoolSelectionScreen extends StatefulWidget {
  const SchoolSelectionScreen({
    super.key,
    required this.selectedOrg,
  });

  final String selectedOrg;

  @override
  State<SchoolSelectionScreen> createState() => _SchoolSelectionScreenState();
}

class _SchoolSelectionScreenState extends State<SchoolSelectionScreen> {
  String? _selectedSchool;
  final List<String> _schools = const [
    'Wise Owl Academy, Nashua',
    'Wise Owl Academy, Boston',
  ];

  @override
  Widget build(BuildContext context) {
    return SelectStepLayout(
      showBackButton: true,
      header: const SelectFlowHeader(
        userName: 'Anna Smith',
        userRole: 'Org Admin',
      ),
      subtitle: widget.selectedOrg,
      title: 'Select your School',
      selector: CustomDropdown(
        hintText: 'Wise Owl Academy, Nashua',
        items: _schools,
        selectedItem: _selectedSchool,
        onSelect: (value) {
          setState(() {
            _selectedSchool = value;
          });
        },
      ),
      onNext: () {
        if (_selectedSchool == null) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const DashboardScreen(),
          ),
        );
      },
      isNextEnabled: _selectedSchool != null,
    );
  }
}
