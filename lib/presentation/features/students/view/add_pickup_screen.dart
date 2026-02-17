import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/data/features/student/datasources/student_remote_datasource.dart';
import 'package:wowcare/core/util/api_error_handler.dart';

class AddPickupScreen extends StatefulWidget {
  const AddPickupScreen({
    super.key,
    required this.studentCode,
  });

  static const String routeName = '/add-pickup-screen';

  final String studentCode;

  @override
  State<AddPickupScreen> createState() => _AddPickupScreenState();
}

class _AddPickupScreenState extends State<AddPickupScreen> {
  bool _selectFromExisting = true;
  String? _selectedCarer;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _relationController = TextEditingController();

  // Mock - should come from API (same UI as AddStudentStep2Screen "Select from existing").
  final List<String> _existingCarers = const [
    'John Smith (john@example.com)',
    'Jane Doe (jane@example.com)',
    'Mike Johnson (mike@example.com)',
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _relationController.dispose();
    super.dispose();
  }

  bool _isSubmitting = false;

  Future<void> _onSave() async {
    if (_selectFromExisting) {
      if (_selectedCarer == null || _selectedCarer!.isEmpty) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Please select a carer',
          isError: true,
        );
        return;
      }

      // TODO: In future, POST a different endpoint to attach an existing carer.
      Navigator.pop(context, true);
      return;
    }

    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    final phone = _phoneController.text.trim();
    final relation = _relationController.text.trim();

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
    if (relation.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Relation is required',
        isError: true,
      );
      return;
    }

    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final dataSource = serviceLocator<StudentRemoteDataSource>();
      final message = await dataSource.addPickup(
        studentCode: widget.studentCode,
        firstName: first,
        lastName: last,
        email: '', // backend allows empty email per contract
        phoneNumber: phone,
        relation: relation,
      );

      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: message,
        isSuccess: true,
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final msg = ApiErrorHandler.extractErrorMessage(e);
      CoreUtils.showTopSnackBar(
        context: context,
        message: msg,
        isError: true,
      );
      setState(() {
        _isSubmitting = false;
      });
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
                  padding:
                      EdgeInsets.symmetric(horizontal: responsive.horizontalSpacing),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Add Pickup',
                      style: TextStyle(
                        fontFamily: "Manrope",
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
                        horizontal: responsive.horizontalSpacing),
                    padding: EdgeInsets.all(responsive.isTablet ? 32.0 : 16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(
                        Radius.circular(responsive.isTablet ? 40.0 : 24.0),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Select from existing',
                              style: TextStyle(
                                fontSize: responsive.labelFontSize,
                                fontFamily: "Manrope",
                                fontWeight: FontWeight.w400,
                                color: const Color(0xff573353),
                              ),
                            ),
                            CustomToggle(
                              label: '',
                              isToggled: _selectFromExisting,
                              onToggle: (value) {
                                setState(() {
                                  _selectFromExisting = value;
                                });
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: responsive.verticalSpacing),
                        if (_selectFromExisting) ...[
                          CustomDropdown(
                            label: 'Carer',
                            hintText: 'Select Carer',
                            items: _existingCarers,
                            selectedItem: _selectedCarer,
                            showAsterisk: true,
                            labelStyle: TextStyle(
                              fontSize: responsive.labelFontSize,
                              fontFamily: "Manrope",
                              fontWeight: FontWeight.w400,
                              color: const Color(0xff573353),
                            ),
                            labelBottomSpacing:
                                responsive.isTablet ? 8.0 : 6.0,
                            fieldHeight: responsive.isTablet ? 64.0 : 56.0,
                            selectedTextStyle: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: responsive.inputFontSize,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xff573353),
                              height: 19 / 14,
                            ),
                            popupItemTextStyle: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: responsive.inputFontSize,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xff573353),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: responsive.isTablet ? 16.0 : 12.0,
                              vertical: responsive.isTablet ? 16.0 : 12.0,
                            ),
                            onSelect: (val) => setState(() {
                              _selectedCarer = val;
                            }),
                          ),
                        ] else ...[
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
                              SizedBox(width: responsive.isTablet ? 24.0 : 16.0),
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
                            label: 'Phone Number',
                            hint: 'E.g. (000) 000-0000',
                            controller: _phoneController,
                            isRequired: true,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                          ),
                          SizedBox(height: responsive.verticalSpacing),
                          _buildInputField(
                            label: 'Relation',
                            hint: 'E.g. Mother',
                            controller: _relationController,
                            isRequired: true,
                            textCapitalization: TextCapitalization.words,
                          ),
                        ],
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
      fontFamily: "Manrope",
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
          constraints: BoxConstraints(minHeight: responsive.inputFieldHeight),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0x66573353)),
            borderRadius: BorderRadius.circular(responsive.isTablet ? 12.0 : 8.0),
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
}

