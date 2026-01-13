import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/auth/view/school_selection_screen.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/select_flow_header.dart';
import 'package:wowcare/shared/common/widgets/select_step_layout.dart';

class OrganizationSelectionScreen extends StatefulWidget {
  const OrganizationSelectionScreen({super.key});

  @override
  State<OrganizationSelectionScreen> createState() =>
      _OrganizationSelectionScreenState();
}

class _OrganizationSelectionScreenState
    extends State<OrganizationSelectionScreen> {
  String? _selectedOrg;
  final List<String> _organizations = const [
    'Wise Owl Academy',
    'Kidi Academy',
  ];

  @override
  Widget build(BuildContext context) {
    return SelectStepLayout(
      showBackButton: true,
      header: const SelectFlowHeader(
        userName: 'Anna Smith',
        userRole: 'Org Admin',
      ),
      title: 'Select Organization',
      selector: CustomDropdown(
        hintText: 'Wise Owl Academy',
        items: _organizations,
        selectedItem: _selectedOrg,
        onSelect: (value) {
          setState(() {
            _selectedOrg = value;
          });
        },
      ),
      onNext: () {
        if (_selectedOrg == null) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SchoolSelectionScreen(selectedOrg: _selectedOrg!),
          ),
        );
      },
      isNextEnabled: _selectedOrg != null,
    );
  }
}
