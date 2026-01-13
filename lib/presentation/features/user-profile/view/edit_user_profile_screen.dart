import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/user-profile/widgets/non_editable_info_widget.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/media_res.dart';
import '../../../../shared/common/widgets/custom_dropdown.dart';
import '../../../../shared/utils/responsive_helper.dart';

class EditUserProfileScreen extends StatefulWidget {
  const EditUserProfileScreen({super.key, this.initialFirstName, this.initialLastName, this.initialEmail, this.initialPhoneNo, this.initialStreet, this.initialCity, this.initialState, this.initialCountry, this.initialZipCode, this.role, this.signInPin, this.initialAddressLine2});
  static const String routeName = '/edit-user-profile-details-screen';

  final String? initialFirstName;
  final String? initialLastName;
  final String? initialEmail;
  final String? initialPhoneNo;
  final String? initialStreet;
  final String? initialCity;
  final String? initialState;
  final String? initialCountry;
  final String? initialZipCode;
  final String? role;
  final String? signInPin;
  final String? initialAddressLine2;


  @override
  State<EditUserProfileScreen> createState() => _EditUserProfileScreenState();
}

class _EditUserProfileScreenState extends State<EditUserProfileScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNoController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _addressLine2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();

  String? _selectedState;
  String? _selectedCountry;
  bool _isSubmitting = false;

  final List<String> _stateOptions = ['New Hampshire', 'Massachusetts', 'Vermont', 'Maine', 'Connecticut'];
  final List<String> _countryOptions = ['United States', 'Canada', 'Mexico'];

  static final RegExp _nameRegex = RegExp(r"^[A-Za-z][A-Za-z\-'\s]{0,49}");
  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');
  static final RegExp _e164Regex = RegExp(r'^\+?[1-9]\d{7,14}$');

  @override
  void initState() {
    super.initState();
    _firstNameController.text = widget.initialFirstName ?? 'Anna';
    _lastNameController.text = widget.initialLastName ?? 'Smith';
    _emailController.text = widget.initialEmail ?? 'annasmith@wowcare.com';
    _phoneNoController.text = widget.initialPhoneNo ?? '(986) 027-1627';
    _streetController.text = widget.initialStreet ?? '';
    _addressLine2Controller.text = widget.initialAddressLine2 ?? '';
    _cityController.text = widget.initialCity ?? '';
    _selectedState = widget.initialState ?? 'New Hampshire';
    _selectedCountry = widget.initialCountry ?? 'United States';
    _zipCodeController.text = widget.initialZipCode ?? '';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneNoController.dispose();
    _addressLine2Controller.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  void _saveProfileDetails() {
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final phoneRaw = _phoneNoController.text.trim();
    final phoneDigits = phoneRaw.replaceAll(RegExp(r'\D'), '');
    final zip = _zipCodeController.text.trim();
    final city = _cityController.text.trim();
    final street = _streetController.text.trim();
    final address2 = _addressLine2Controller.text.trim();

    if (first.isEmpty || !_nameRegex.hasMatch(first)) {
      _showWarningMessage('First Name is required');
      return;
    }
    if (last.isEmpty || !_nameRegex.hasMatch(last)) {
      _showWarningMessage('Last Name is required');
      return;
    }
    if (email.isEmpty || !_emailRegex.hasMatch(email)) {
      _showWarningMessage('Email is required');
      return;
    }
    if (phoneDigits.length < 10 || (!_e164Regex.hasMatch('+' + phoneDigits))) {
      _showWarningMessage('Phone Number is required');
      return;
    }
    if (_streetController.text.isEmpty) {
      _showWarningMessage('Street is required');
      return;
    }
    if (street.length > 150) {
      _showWarningMessage('Street address cannot exceed 150 characters');
      return;
    }
    if (_cityController.text.isEmpty) {
      _showWarningMessage('City is required');
      return;
    }
    if (city.length > 50) {
      _showWarningMessage('City name cannot exceed 50 characters');
      return;
    }
    if (_zipCodeController.text.trim().isEmpty) {
      _showWarningMessage('Zip Code is required');
      return;
    }
    if (!RegExp(r'^\d{3,10}$').hasMatch(zip)) {
      _showWarningMessage('Zip Code must contain only numbers (3–10 digits)');
      return;
    }



    if (address2.length > 150) {
      _showWarningMessage('Address Line 2 cannot exceed 150 characters');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Mock API call
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isSubmitting = false;
      });
      Navigator.pop(context);
    });
  }

  void _showWarningMessage(String message) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    final snackBar = SnackBar(
      content: Row(
        children: [
          const Icon(Icons.warning, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.orange.shade50,
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.orange.shade100),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }


  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        appBar: const CustomAppBar(hasBackButton: true,),
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
                Expanded(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: responsive.horizontalSpacing,
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Edit My Profile',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: responsive.titleFontSize,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xff573353),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: responsive.isTablet ? 32.0 : 10.0),
                          Container(
                            width: responsive.containerWidth,
                            margin: EdgeInsets.symmetric(
                                horizontal: responsive.horizontalSpacing
                            ),
                            padding: EdgeInsets.all(responsive.isTablet ? 32.0 : 16.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.all(
                                Radius.circular(responsive.isTablet ? 30.0 : 20.0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildInputField(
                                          "First Name",
                                          "E.g. John",
                                          _firstNameController,
                                          isRequired: true
                                      ),
                                    ),
                                    SizedBox(width: responsive.horizontalSpacing),
                                    Expanded(
                                      child: _buildInputField(
                                          "Last Name",
                                          "E.g. Smith",
                                          _lastNameController,
                                          isRequired: true
                                      ),
                                    ),

                                  ],
                                ),
                                SizedBox(height: responsive.verticalSpacing),
                                _buildInputField("Email", "E.g. Jessica@wowcare.com", _emailController, isRequired: true),
                                SizedBox(height: responsive.verticalSpacing),
                                _buildInputField("Phone Number", "E.g. +19860271627", _phoneNoController, isRequired: true),
                                SizedBox(height: responsive.verticalSpacing),
                                _buildInputField("Street", "Eg. Street no", _streetController, isRequired: true),
                                SizedBox(height: responsive.verticalSpacing),
                                _buildInputField("Address line 2", "(Optional)", _addressLine2Controller, isRequired: false),
                                SizedBox(height: responsive.verticalSpacing),
                                _buildInputField("City", "Eg. Nashua", _cityController, isRequired: true),
                                SizedBox(height: responsive.verticalSpacing),
                                _buildCustomDropdown("State", "Select", _stateOptions, _selectedState, (v) => setState(() => _selectedState = v), isRequired: true),
                                SizedBox(height: responsive.verticalSpacing),
                                _buildCustomDropdown("Country", "Select", _countryOptions, _selectedCountry, (v) => setState(() => _selectedCountry = v), isRequired: true),
                                SizedBox(height: responsive.verticalSpacing),
                                _buildInputField("Zip Code", "Eg. 85001", _zipCodeController, isRequired: true),
                                SizedBox(height: responsive.verticalSpacing),
                                NonEditableInfoWidget(label: 'Role', isEditable: false, value: widget.role,),
                                SizedBox(height: responsive.verticalSpacing),
                                NonEditableInfoWidget(label: 'Sign In Pin', isEditable: false, value: widget.signInPin,),

                              ],

                            ),
                          )
                        ],
                      ),
                    )
                )
              ],
            )
          ],
        ),
        bottomNavigationBar: Container(
          padding: EdgeInsets.only(
            bottom: safeAreaBottom, left: 16, right: 16, top: 8,
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
          child: Container(
            height: responsive.buttonHeight,
            decoration: BoxDecoration(
              gradient: _isSubmitting ? null : AppColors.buildPrimaryGradient(),
              color: _isSubmitting ? Colors.grey[300] : null,
              borderRadius: BorderRadius.circular(responsive.isTablet ? 16.0 : 8.0),
            ),
            child: TextButton(
              onPressed: _isSubmitting ? null : _saveProfileDetails,
              child: Text(
                'Save',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: responsive.buttonFontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
      String label,
      String hint,
      TextEditingController controller, {
        bool isRequired = false,
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
              if (isRequired) const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
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

  Widget _buildCustomDropdown(
      String label,
      String hintText,
      List<String> items,
      String? selectedItem,
      ValueChanged<String?> onSelect, {
        bool isRequired = false,
      }) {
    final responsive = ResponsiveHelper(context);
    return CustomDropdown(
      label: label,
      hintText: hintText,
      items: items,
      selectedItem: selectedItem,
      onSelect: onSelect,
      showAsterisk: isRequired,
      labelStyle: TextStyle(
        fontSize: responsive.labelFontSize,
        fontFamily: "Manrope",
        fontWeight: FontWeight.w400,
        color: const Color(0xff573353),
      ),
      labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
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
    );
  }
}
