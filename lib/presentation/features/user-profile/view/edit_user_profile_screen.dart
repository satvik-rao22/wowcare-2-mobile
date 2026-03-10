import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:flutter/services.dart';

import '../../../../app/di/di.dart';
import '../../../../app/theme/colors.dart';
import '../../../../app/theme/media_res.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/util/core_utils.dart';
import '../../../../core/util/storage_keys.dart';
import '../../../../domain/features/staff/entities/staff_profile.dart';
import '../../../../domain/features/staff/repositories/staff_repository.dart';
import '../../../../shared/common/widgets/custom_dropdown.dart';
import '../../../../shared/utils/responsive_helper.dart';
import '../../../../shared/constants/location_constants.dart';

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
  bool _hasShownProfileLoadError = false;

  // Full lists sourced from shared `location_constants.dart`
  final List<String> _stateOptions =
      US_STATES.map((state) => state.name).toList();
  final List<String> _countryOptions =
      COUNTRY_LIST.map((country) => country.name).toList();

  // First character A–Z, then up to 49 characters (letters, space, hyphen, apostrophe).
  static final RegExp _nameRegex = RegExp(r"^[A-Za-z][A-Za-z\-'\s]{0,49}$");
  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');
  static final RegExp _e164Regex = RegExp(r'^\+?[1-9]\d{7,14}$');

  @override
  void initState() {
    super.initState();
    // Don't show demo/default values. Keep fields empty unless we have real data.
    _firstNameController.text = widget.initialFirstName ?? '';
    _lastNameController.text = widget.initialLastName ?? '';
    _emailController.text = widget.initialEmail ?? '';
    _phoneNoController.text = widget.initialPhoneNo ?? '';
    _streetController.text = widget.initialStreet ?? '';
    _addressLine2Controller.text = widget.initialAddressLine2 ?? '';
    _cityController.text = widget.initialCity ?? '';
    _selectedState =
        (widget.initialState != null && widget.initialState!.trim().isNotEmpty)
            ? widget.initialState
            : null;
    _selectedCountry = (widget.initialCountry != null &&
            widget.initialCountry!.trim().isNotEmpty)
        ? widget.initialCountry
        : null;
    _zipCodeController.text = widget.initialZipCode ?? '';

    // Prefetch latest profile from my-profile API and hydrate controllers.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _prefillFromStaffProfile();
    });
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

  /// Resolves staffCode for the currently logged-in user.
  /// Uses cached staffCode when valid; falls back to `/api/v1/staff/code`
  /// via the StaffRepository when needed.
  Future<String> _resolveLoggedInStaffCode() async {
    try {
      final storage = serviceLocator<StorageService>();
      final repo = serviceLocator<StaffRepository>();

      final currentUserCode =
          (await storage.getString(StorageKeys.userCode) ?? '').trim();
      final cachedStaffCode =
          (await storage.getString(StorageKeys.staffCode) ?? '').trim();
      final cachedStaffUser =
          (await storage.getString(StorageKeys.staffCodeUser) ?? '').trim();

      if (cachedStaffCode.isNotEmpty &&
          cachedStaffUser.isNotEmpty &&
          currentUserCode.isNotEmpty &&
          cachedStaffUser == currentUserCode) {
        return cachedStaffCode;
      } else {
        await storage.remove(StorageKeys.staffCode);
        await storage.remove(StorageKeys.staffCodeUser);
      }

      final organizationCode =
          (await storage.getString(StorageKeys.organizationCode) ?? '').trim();
      final schoolCode =
          (await storage.getString(StorageKeys.schoolCode) ?? '').trim();
      if (currentUserCode.isEmpty ||
          organizationCode.isEmpty ||
          schoolCode.isEmpty) {
        return '';
      }

      final resolvedCode = await repo.getStaffCodeForUser(
        userCode: currentUserCode,
        organizationCode: organizationCode,
        schoolCode: schoolCode,
      );

      final code = (resolvedCode ?? '').trim();
      if (code.isNotEmpty) {
        await storage.saveString(StorageKeys.staffCode, code);
        await storage.saveString(StorageKeys.staffCodeUser, currentUserCode);
      }

      return code;
    } catch (_) {
      return '';
    }
  }

  /// Prefills controllers using the staff profile fetched from the my-profile API.
  /// Cache-first, then background refresh; no explicit loader is shown.
  Future<void> _prefillFromStaffProfile() async {
    final staffCode = await _resolveLoggedInStaffCode();
    if (!mounted || staffCode.isEmpty) return;

    try {
      final repo = serviceLocator<StaffRepository>();
      var hadCached = false;

      // 1) Try cached profile first for instant UI.
      if (repo is StaffRepositoryWithCache) {
        final cached =
            await (repo as StaffRepositoryWithCache).loadCachedStaffProfile(
          staffCode,
        );
        if (!mounted) return;
        if (cached != null) {
          hadCached = true;
          _applyProfileToControllers(cached);
          setState(() {});
        }
      }

      // 2) Always prefetch latest via my-profile controller in background.
      try {
        final fresh = await repo.getStaffProfile(staffCode: staffCode);
        if (!mounted) return;
        _applyProfileToControllers(fresh);
        setState(() {});
      } catch (e) {
        CoreUtils.logApiError(e.toString());
        if (!hadCached && !_hasShownProfileLoadError) {
          _hasShownProfileLoadError = true;
          CoreUtils.showTopSnackBar(
            context: context,
            message: 'Failed to load profile. Please try again.',
            isError: true,
          );
        }
      }
    } catch (e) {
      CoreUtils.logApiError(e.toString());
      if (!_hasShownProfileLoadError) {
        _hasShownProfileLoadError = true;
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Failed to load profile. Please try again.',
          isError: true,
        );
      }
    }
  }

  void _applyProfileToControllers(StaffProfile profile) {
    _firstNameController.text = profile.firstName.isNotEmpty
        ? profile.firstName
        : _firstNameController.text;
    _lastNameController.text = profile.lastName.isNotEmpty
        ? profile.lastName
        : _lastNameController.text;
    _emailController.text = profile.email.isNotEmpty
        ? profile.email
        : _emailController.text;
    if (profile.phoneNumber.isNotEmpty) {
      final digits = profile.phoneNumber.replaceAll(RegExp(r'\D'), '');
      _phoneNoController.text = digits.length == 10
          ? CoreUtils.formatPhoneNumber(digits)
          : profile.phoneNumber;
    }

    final address = profile.address;
    if (address.street.isNotEmpty) {
      _streetController.text = address.street;
    }
    if (address.line2.isNotEmpty) {
      _addressLine2Controller.text = address.line2;
    }
    if (address.city.isNotEmpty) {
      _cityController.text = address.city;
    }
    if (address.zipCode.isNotEmpty) {
      _zipCodeController.text = address.zipCode;
    }

    _selectedState = address.state.isNotEmpty ? address.state : _selectedState;
    _selectedCountry =
        address.country.isNotEmpty ? address.country : _selectedCountry;
  }

  Future<void> _saveProfileDetails() async {
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final phoneRaw = _phoneNoController.text.trim();
    final phoneDigits = phoneRaw.replaceAll(RegExp(r'\D'), '');
    final zip = _zipCodeController.text.trim();
    final city = _cityController.text.trim();
    final street = _streetController.text.trim();
    final address2 = _addressLine2Controller.text.trim();

    if (first.isEmpty) {
      CoreUtils.showTopSnackBar(context: context, message:'First Name is required', isError: true);
      return;
    }
    if (first.length > 50 || !_nameRegex.hasMatch(first)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message:'First Name must be letters only and max 50 characters',
        isError: true,
      );
      return;
    }
    if (last.isEmpty) {
      CoreUtils.showTopSnackBar(context: context, message:'Last Name is required', isError: true);
      return;
    }
    if (last.length > 50 || !_nameRegex.hasMatch(last)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message:'Last Name must be letters only and max 50 characters',
        isError: true,
      );
      return;
    }
    if (email.isEmpty || !_emailRegex.hasMatch(email)) {
      CoreUtils.showTopSnackBar(context: context, message:'Email is required', isError: true);
      return;
    }
    if (phoneDigits.isEmpty) {
      CoreUtils.showTopSnackBar(context: context, message:'Phone Number is required', isError: true);
      return;
    }
    if (phoneDigits.length != 10 || (!_e164Regex.hasMatch('+' + phoneDigits))) {
      CoreUtils.showTopSnackBar(context: context, message:'Please enter a valid 10-digit phone number', isError: true);
      return;
    }
    if (_streetController.text.isEmpty) {
      CoreUtils.showTopSnackBar(context: context, message:'Street is required', isError: true);
      return;
    }
    if (street.length > 150) {
      CoreUtils.showTopSnackBar(context: context, message:'Street address cannot exceed 150 characters', isError: true);
      return;
    }
    if (_cityController.text.isEmpty) {
      CoreUtils.showTopSnackBar(context: context, message:'City is required', isError: true);
      return;
    }
    if (city.length > 50) {
      CoreUtils.showTopSnackBar(context: context, message:'City name cannot exceed 50 characters', isError: true);
      return;
    }
    if (_zipCodeController.text.trim().isEmpty) {
      CoreUtils.showTopSnackBar(context: context, message:'Zip Code is required', isError: true);
      return;
    }
    if (!RegExp(r'^\d{3,10}$').hasMatch(zip)) {
      CoreUtils.showTopSnackBar(context: context, message:'Zip Code must contain only numbers (3–10 digits)', isError: true);
      return;
    }
    if ((_selectedState ?? '').trim().isEmpty) {
      CoreUtils.showTopSnackBar(context: context, message:'State is required', isError: true);
      return;
    }
    if ((_selectedCountry ?? '').trim().isEmpty) {
      CoreUtils.showTopSnackBar(context: context, message:'Country is required', isError: true);
      return;
    }



    if (address2.length > 150) {
      CoreUtils.showTopSnackBar(context: context, message:'Address Line 2 cannot exceed 150 characters', isError: true);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final staffCode = await _resolveLoggedInStaffCode();
      if (staffCode.isEmpty) {
        setState(() {
          _isSubmitting = false;
        });
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Unable to resolve staff profile. Please try again.',
          isError: true,
        );
        return;
      }

      final repo = serviceLocator<StaffRepository>();

      // Build request body matching my-profile PATCH contract.
      final body = <String, dynamic>{
        'firstName': first,
        'lastName': last,
        'phoneNumber': '+$phoneDigits',
        'addressStreet': street,
        'addressLine2': address2,
        'addressCity': city,
        'addressState': _selectedState ?? '',
        'addressZipCode': zip,
        'addressCountry': _selectedCountry ?? '',
      };

      await repo.updateMyProfile(
        staffCode: staffCode,
        fields: body,
      );

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      // Pop with result so caller can refresh profile details.
      Navigator.pop(context, true);
    } catch (e) {
      CoreUtils.logApiError(e.toString());
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Failed to save profile. Please try again.',
        isError: true,
      );
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
                      padding: const EdgeInsets.only(bottom: 8),
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
                                  color: AppColors.primaryColor,
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
                                _buildInputField("Phone Number", "E.g. (000) 000-0000", _phoneNoController, isRequired: true),
                                SizedBox(height: responsive.verticalSpacing),
                                _buildInputField("Street", "Eg. Street no", _streetController, isRequired: true),
                                SizedBox(height: responsive.verticalSpacing),
                                _buildInputField("Address line 2", "E.g. Address line 2", _addressLine2Controller, isRequired: false),
                                SizedBox(height: responsive.verticalSpacing),
                                _buildInputField("City", "Eg. Nashua", _cityController, isRequired: true),
                                SizedBox(height: responsive.verticalSpacing),
                                _buildCustomDropdown("State", "Select", _stateOptions, _selectedState, (v) => setState(() => _selectedState = v), isRequired: true),
                                SizedBox(height: responsive.verticalSpacing),
                                _buildCustomDropdown("Country", "Select", _countryOptions, _selectedCountry, (v) => setState(() => _selectedCountry = v), isRequired: true),
                                SizedBox(height: responsive.verticalSpacing),
                                _buildInputField("Zip Code", "Eg. 85001", _zipCodeController, isRequired: true),

                              ],

                            ),
                          )
                        ],
                      ),
                    )
                ),
                const SizedBox(height: 12),
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
              onPressed: _isSubmitting ? null : () => _saveProfileDetails(),
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
      fontSize: responsive.labelFontSize + 1,
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
            keyboardType: label == 'Zip Code'
                ? TextInputType.number
                : (label == 'Phone Number'
                    ? TextInputType.phone
                    : TextInputType.text),
            inputFormatters: label == 'Zip Code'
                ? <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly]
                : (label == 'Phone Number'
                    ? <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                        _UserPhoneNumberFormatter(),
                      ]
                    : const <TextInputFormatter>[]),
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
        fontSize: responsive.labelFontSize + 1,
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

/// Simple phone formatter to display US numbers as (XXX) XXX-XXXX
/// while keeping only digits for API submission.
class _UserPhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final buffer = StringBuffer();
    for (var i = 0; i < digitsOnly.length && i < 10; i++) {
      if (i == 0) buffer.write('(');
      if (i == 3) buffer.write(') ');
      if (i == 6) buffer.write('-');
      buffer.write(digitsOnly[i]);
    }
    final formatted = buffer.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
