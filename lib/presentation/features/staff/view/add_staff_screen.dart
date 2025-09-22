import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/common_single_select_dropdown.dart';
import 'package:wowcare/shared/common/widgets/common_multi_select_dropdown.dart';

class AddStaffScreen extends StatefulWidget {
  const AddStaffScreen({super.key});
  static const String routeName = '/add-staff-screen';

  @override
  State<AddStaffScreen> createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends State<AddStaffScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String? _designation;
  String? _primaryClassroom;
  final List<String> _allowedClassrooms = [];
  String? _status;

  final List<String> _classroomsList = const ['Classroom A', 'Classroom B', 'Classroom C'];
  final List<String> _statusList = const ['Active', 'Inactive'];
  final List<String> _designationList = const ['ADMIN', 'STAFF'];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bool isTablet = media.size.width >= 600;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Add Staff'),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primaryColor,
          elevation: 0.5,
        ),
        body: Container(
          decoration: BoxDecoration(gradient: AppColors.buildScaffoldGradient()),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _textField('First Name', 'E.g. John', _firstNameController)),
                      const SizedBox(width: 16),
                      Expanded(child: _textField('Last Name', 'E.g. Smith', _lastNameController)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _textField('Email', 'E.g. name@example.com', _emailController, keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 12),
                  _textField(
                    'Phone Number',
                    'E.g. (000) 000-0000',
                    _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10), _PhoneMaskFormatter()],
                  ),
                  const SizedBox(height: 12),
                  CommonSingleSelectDropdown(
                    label: 'Designation',
                    value: _designation,
                    items: _designationList,
                    onSelected: (v) => setState(() => _designation = v),
                  ),
                  const SizedBox(height: 12),
                  CommonMultiSelectDropdown(
                    label: 'Allowed Classrooms',
                    items: _classroomsList,
                    selectedItems: _allowedClassrooms,
                    onConfirm: (vals) => setState(() => _allowedClassrooms
                        ..clear()
                        ..addAll(vals)),
                  ),
                  const SizedBox(height: 12),
                  CommonSingleSelectDropdown(
                    label: 'Primary Classroom',
                    value: _primaryClassroom,
                    items: _classroomsList,
                    onSelected: (v) => setState(() => _primaryClassroom = v),
                  ),
                  const SizedBox(height: 12),
                  CommonSingleSelectDropdown(
                    label: 'Status',
                    value: _status,
                    items: _statusList,
                    onSelected: (v) => setState(() => _status = v),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: isTablet ? 48 : 44,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.buildPrimaryGradient(),
                        borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
                      ),
                      child: TextButton(
                        onPressed: _submit,
                        child: const Text(
                          'Add',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _textField(String label, String hint, TextEditingController controller,
      {TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 14,
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w400,
              color: Color(0xff573353),
            ),
            children: const [
              TextSpan(text: ''),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0x66573353)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              labelStyle: const TextStyle(fontFamily: 'Manrope'),
              hintStyle: const TextStyle(color: Colors.grey, fontFamily: 'Manrope'),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _PhoneMaskFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    String out = '';
    if (digits.isEmpty) {
      out = '';
    } else if (digits.length <= 3) {
      out = '(${digits.substring(0, digits.length)}';
    } else if (digits.length <= 6) {
      out = '(${digits.substring(0, 3)}) ${digits.substring(3)}';
    } else {
      final last = digits.length > 10 ? digits.substring(6, 10) : digits.substring(6);
      out = '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-$last';
    }
    return TextEditingValue(text: out, selection: TextSelection.collapsed(offset: out.length));
  }
}


