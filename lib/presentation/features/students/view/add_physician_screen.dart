import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

class AddPhysicianScreen extends StatefulWidget {
  const AddPhysicianScreen({
    super.key,
    required this.studentCode,
    this.physicianCode,
    this.initialFirstName,
    this.initialLastName,
    this.initialEmail,
    this.initialPhoneNumber,
    this.initialAddress,
    this.initialNotes,
    this.isEdit = false,
  });

  static const String routeName = '/add-physician-screen';

  final String studentCode;
  final String? physicianCode;
  final String? initialFirstName;
  final String? initialLastName;
  final String? initialEmail;
  final String? initialPhoneNumber;
  final String? initialAddress;
  final String? initialNotes;
  final bool isEdit;

  @override
  State<AddPhysicianScreen> createState() => _AddPhysicianScreenState();
}

class _AddPhysicianScreenState extends State<AddPhysicianScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _firstNameController.text = widget.initialFirstName ?? '';
    _lastNameController.text = widget.initialLastName ?? '';
    _emailController.text = widget.initialEmail ?? '';
    _phoneController.text = _formatPhoneNumber(widget.initialPhoneNumber ?? '');
    _addressController.text = widget.initialAddress ?? '';
    _notesController.text = widget.initialNotes ?? '';
  }

  String _formatPhoneNumber(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    if (digits.length <= 3) return '($digits';
    if (digits.length <= 6) {
      return '(${digits.substring(0, 3)}) ${digits.substring(3)}';
    }
    final take = digits.length >= 10 ? 10 : digits.length;
    final d = digits.substring(0, take);
    return '(${d.substring(0, 3)}) ${d.substring(3, 6)}-${d.substring(6)}';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    final notes = _notesController.text.trim();

    if (first.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'First Name is required',
        isError: true,
      );
      return;
    }
    if (last.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Last Name is required',
        isError: true,
      );
      return;
    }
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please enter a valid 10-digit phone number',
        isError: true,
      );
      return;
    }

    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final storage = serviceLocator<StorageService>();
      final schoolCode =
          await storage.getString(StorageKeys.schoolCode) ?? '';

      final studentRepo = serviceLocator<StudentRepository>();

      if (widget.isEdit &&
          widget.physicianCode != null &&
          widget.physicianCode!.isNotEmpty) {
        await studentRepo.updatePhysician(
          code: widget.physicianCode!,
          studentCode: widget.studentCode,
          firstName: first,
          lastName: last,
          email: email,
          phoneNumber: digits,
          address: address,
          notes: notes.isNotEmpty ? notes : null,
          specialty: null,
        );
      } else {
        await studentRepo.addPhysician(
          schoolCode: schoolCode,
          studentCode: widget.studentCode,
          firstName: first,
          lastName: last,
          email: email,
          phoneNumber: digits,
          address: address,
          notes: notes.isNotEmpty ? notes : null,
          specialty: null,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: const CustomAppBar(hasBackButton: true),
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: AppColors.buildScaffoldGradient(),
                ),
                child: Image.asset(
                  MediaRes.wowcareMobileBg,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),
            Column(
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.horizontalSpacing,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      widget.isEdit ? 'Edit Physician' : 'Add Physician',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: responsive.titleFontSize,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xff573353),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: responsive.isTablet ? 32.0 : 20.0),
                Expanded(
                  child: Container(
                    width: responsive.containerWidth,
                    margin: EdgeInsets.symmetric(
                      horizontal: responsive.horizontalSpacing,
                    ),
                    padding: EdgeInsets.all(
                      responsive.isTablet ? 32.0 : 16.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(
                        Radius.circular(
                          responsive.isTablet ? 40.0 : 24.0,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        SizedBox(height: responsive.verticalSpacing),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInputField(
                                label: 'First Name',
                                hint: 'E.g. John',
                                controller: _firstNameController,
                                isRequired: true,
                                textCapitalization: TextCapitalization.words,
                              ),
                            ),
                            SizedBox(
                              width:
                                  responsive.isTablet ? 24.0 : 16.0,
                            ),
                            Expanded(
                              child: _buildInputField(
                                label: 'Last Name',
                                hint: 'E.g. Smith',
                                controller: _lastNameController,
                                isRequired: true,
                                textCapitalization: TextCapitalization.words,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: responsive.verticalSpacing),
                        _buildInputField(
                          label: 'Email ID',
                          hint: 'E.g. name@example.com',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        SizedBox(height: responsive.verticalSpacing),
                        _buildInputField(
                          label: 'Phone Number',
                          hint: 'E.g. (000) 000-0000',
                          controller: _phoneController,
                          isRequired: true,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                            PhoneNumberFormatter(),
                          ],
                        ),
                        SizedBox(height: responsive.verticalSpacing),
                        _buildInputField(
                          label: 'Address',
                          hint: 'Enter address',
                          controller: _addressController,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        SizedBox(height: responsive.verticalSpacing),
                        _buildNotesField(),
                        SizedBox(height: responsive.verticalSpacing),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ],
        ),
        bottomNavigationBar: Container(
          padding: EdgeInsets.only(
            bottom: safeAreaBottom,
            left: 16,
            right: 16,
            top: 8,
          ),
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
          child: CustomButtonLayout(
            confirmButtonLabel: 'Save',
            cancelButtonLabel: 'Cancel',
            onPressedConfirm: _onSave,
            onPressedCancel: () => Navigator.pop(context, false),
            showCancelButton: true,
            isForm: false,
            isLoading: _isSubmitting,
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isRequired = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
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
        RichText(
          text: TextSpan(
            style: labelStyle,
            children: [
              TextSpan(text: label),
              if (isRequired)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        Container(
          constraints: BoxConstraints(
            minHeight: responsive.inputFieldHeight,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0x66573353)),
            borderRadius: BorderRadius.circular(
              responsive.isTablet ? 12.0 : 8.0,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            textCapitalization: textCapitalization,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: labelStyle.copyWith(color: Colors.grey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: responsive.isTablet ? 16.0 : 12.0,
                vertical: responsive.isTablet ? 16.0 : 12.0,
              ),
            ),
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: responsive.inputFontSize,
              fontWeight: FontWeight.w600,
              color: const Color(0xff573353),
              height: 19 / 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
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
        Text(
          'Notes',
          style: labelStyle,
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        Container(
          constraints: BoxConstraints(
            minHeight: responsive.inputFieldHeight * 2,
            maxHeight: responsive.inputFieldHeight * 4,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0x66573353)),
            borderRadius: BorderRadius.circular(
              responsive.isTablet ? 12.0 : 8.0,
            ),
          ),
          child: TextField(
            controller: _notesController,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Add notes...',
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
}

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }

    String formattedText;
    if (digits.length <= 3) {
      formattedText = '($digits';
    } else if (digits.length <= 6) {
      formattedText = '(${digits.substring(0, 3)}) ${digits.substring(3)}';
    } else {
      final d = digits.substring(0, 10);
      formattedText = '(${d.substring(0, 3)}) ${d.substring(3, 6)}-${d.substring(6)}';
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

