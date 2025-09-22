import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';

class StaffFilterScreen extends StatefulWidget {
  const StaffFilterScreen({super.key});

  static const String routeName = '/staff-filter';

  @override
  State<StaffFilterScreen> createState() => _StaffFilterScreenState();
}

class _StaffFilterScreenState extends State<StaffFilterScreen> {
  final TextEditingController _nameController = TextEditingController();
  String? _designation; // ADMIN, STAFF
  String? _status; // Active, Inactive

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);

    return StaffFormLayout(
      title: 'Filter Staff',
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildInput(
            context: context,
            label: 'Name',
            hint: 'Search by name',
            controller: _nameController,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z\s]")),
            ],
          ),
          SizedBox(height: responsive.verticalSpacing),
          _buildDropdown(
            context: context,
            label: 'Designation',
            value: _designation,
            items: const ['ADMIN', 'STAFF'],
            onChanged: (v) => setState(() => _designation = v),
          ),
          SizedBox(height: responsive.verticalSpacing),
          _buildDropdown(
            context: context,
            label: 'Status',
            value: _status,
            items: const ['Active', 'Inactive'],
            onChanged: (v) => setState(() => _status = v),
          ),
          const SizedBox(height: 12),
        ],
      ),
      bottomBar: _buildBottomBar(context, responsive),
    );
  }

  Widget _buildInput({
    required BuildContext context,
    required String label,
    required String hint,
    required TextEditingController controller,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final responsive = ResponsiveHelper(context);
    final labelStyle = TextStyle(
      fontSize: responsive.labelFontSize,
      fontFamily: 'Manrope',
      fontWeight: FontWeight.w400,
      color: const Color(0xff573353),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        Container(
          constraints: BoxConstraints(minHeight: responsive.inputFieldHeight),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0x66573353)),
            borderRadius: BorderRadius.circular(responsive.isTablet ? 12.0 : 8.0),
          ),
          child: TextField(
            controller: controller,
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: labelStyle.copyWith(color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: responsive.isTablet ? 16.0 : 12.0,
                vertical: responsive.isTablet ? 16.0 : 12.0,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required BuildContext context,
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final responsive = ResponsiveHelper(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: responsive.labelFontSize,
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w400,
            color: const Color(0xff573353),
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        Container(
          height: responsive.inputFieldHeight,
          padding: EdgeInsets.symmetric(
            horizontal: responsive.isTablet ? 16.0 : 12.0,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0x66573353)),
            borderRadius: BorderRadius.circular(responsive.isTablet ? 12.0 : 8.0),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: const Text('Select'),
              items: items
                  .map((e) => DropdownMenuItem<String>(
                        value: e,
                        child: Text(e),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, ResponsiveHelper responsive) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;
    return Container(
      padding: EdgeInsets.only(bottom: safeAreaBottom, left: 16, right: 16, top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(responsive.isTablet ? 40.0 : 24.0),
          topRight: Radius.circular(responsive.isTablet ? 40.0 : 24.0),
        ),
      ),
      child: Container(
        height: responsive.buttonHeight,
        decoration: BoxDecoration(
          gradient: AppColors.buildPrimaryGradient(),
          borderRadius: BorderRadius.circular(responsive.isTablet ? 16.0 : 8.0),
        ),
        child: TextButton(
          onPressed: () {
            Navigator.pop(context, {
              'name': _nameController.text.trim(),
              'designation': _designation,
              'status': _status,
            });
          },
          child: Text(
            'Apply Filters',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: responsive.buttonFontSize,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}


