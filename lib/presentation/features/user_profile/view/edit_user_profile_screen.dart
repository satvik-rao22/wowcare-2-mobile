import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_fonts.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/domain/features/staff/entities/staff_my_profile_update.dart';
import 'package:wowcare/domain/features/staff/entities/staff_profile.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/constants/location_constants.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/presentation/features/user_profile/view_model/edit_user_profile_cubit.dart';

/// The [EditUserProfileCubit] is provided by the router's GoRoute builder
/// (which also kicks off the profile load), so this screen just renders
/// the form — it never resolves the cubit itself.
class EditUserProfileScreen extends StatelessWidget {
  const EditUserProfileScreen({
    super.key,
    this.initialFirstName,
    this.initialLastName,
    this.initialEmail,
    this.initialPhoneNo,
    this.initialStreet,
    this.initialCity,
    this.initialState,
    this.initialCountry,
    this.initialZipCode,
    this.role,
    this.signInPin,
    this.initialAddressLine2,
    this.isParent = false,
  });
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

  /// When true the screen edits the logged-in guardian's profile (guardian
  /// endpoints) instead of the staff profile.
  final bool isParent;

  @override
  Widget build(BuildContext context) {
    return _EditUserProfileForm(
      initialFirstName: initialFirstName,
      initialLastName: initialLastName,
      initialEmail: initialEmail,
      initialPhoneNo: initialPhoneNo,
      initialStreet: initialStreet,
      initialCity: initialCity,
      initialState: initialState,
      initialCountry: initialCountry,
      initialZipCode: initialZipCode,
      role: role,
      signInPin: signInPin,
      initialAddressLine2: initialAddressLine2,
      isParent: isParent,
    );
  }
}

class _EditUserProfileForm extends StatefulWidget {
  const _EditUserProfileForm({
    this.initialFirstName,
    this.initialLastName,
    this.initialEmail,
    this.initialPhoneNo,
    this.initialStreet,
    this.initialCity,
    this.initialState,
    this.initialCountry,
    this.initialZipCode,
    this.role,
    this.signInPin,
    this.initialAddressLine2,
    this.isParent = false,
  });

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
  final bool isParent;

  @override
  State<_EditUserProfileForm> createState() => _EditUserProfileFormState();
}

class _EditUserProfileFormState extends State<_EditUserProfileForm> {
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
  bool _hasShownProfileLoadError = false;
  int _appliedRevision = 0;

  // Full lists sourced from shared `location_constants.dart`
  final List<String> _stateOptions = US_STATES
      .map((state) => state.name)
      .toList();

  // First character A–Z, then up to 49 characters (letters, space, hyphen, apostrophe).
  static final RegExp _nameRegex = RegExp(r"^[A-Za-z][A-Za-z\-'\s]{0,49}$");
  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

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
    _selectedCountry =
        (widget.initialCountry != null &&
            widget.initialCountry!.trim().isNotEmpty)
        ? widget.initialCountry
        : null;
    _zipCodeController.text = widget.initialZipCode ?? '';
    // Country is fixed to United States in this form.
    _selectedCountry = 'United States';
    // The cubit (provided by the wrapper) prefetches the latest profile; this
    // form hydrates its controllers from the emitted state via BlocListener.
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

  /// Hydrates the form when the cubit emits a freshly loaded profile, and
  /// surfaces a one-time error if the load failed with no cached fallback.
  void _onCubitState(BuildContext context, EditUserProfileState state) {
    if (state.profile != null && state.profileRevision != _appliedRevision) {
      _appliedRevision = state.profileRevision;
      _applyProfileToControllers(state.profile!);
      setState(() {});
    }
    if (state.loadFailed && !_hasShownProfileLoadError) {
      _hasShownProfileLoadError = true;
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Failed to load profile. Please try again.',
        isError: true,
      );
    }
  }

  void _applyProfileToControllers(StaffProfile profile) {
    _firstNameController.text = profile.firstName.isNotEmpty
        ? _toTitleCase(profile.firstName)
        : _firstNameController.text;
    _lastNameController.text = profile.lastName.isNotEmpty
        ? _toTitleCase(profile.lastName)
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
      _streetController.text = _toTitleCase(address.street);
    }
    if (address.line2.isNotEmpty) {
      _addressLine2Controller.text = _toTitleCase(address.line2);
    }
    if (address.city.isNotEmpty) {
      _cityController.text = _toTitleCase(address.city);
    }
    if (address.zipCode.isNotEmpty) {
      _zipCodeController.text = _formatUsZipForDisplay(address.zipCode);
    }
    if (address.state.isNotEmpty) {
      final match = US_STATES.firstWhere(
        (s) =>
            s.name.toLowerCase() == address.state.toLowerCase() ||
            s.abbreviation.toLowerCase() == address.state.toLowerCase(),
        orElse: () => US_STATES.first,
      );
      _selectedState = match.name;
    }
    _selectedCountry = 'United States';
  }

  Future<void> _saveProfileDetails() async {
    final first = _toTitleCase(_firstNameController.text.trim());
    final last = _toTitleCase(_lastNameController.text.trim());
    final email = _emailController.text.trim().toLowerCase();
    final phoneRaw = _phoneNoController.text.trim();
    final phoneDigits = phoneRaw.replaceAll(RegExp(r'\D'), '');
    final zip = _zipCodeController.text.trim();
    final city = _toTitleCase(_cityController.text.trim());
    final street = _toTitleCase(_streetController.text.trim());
    final address2 = _toTitleCase(_addressLine2Controller.text.trim());

    if (first.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'First Name is required',
        isError: true,
      );
      return;
    }
    if (first.length > 50 || !_nameRegex.hasMatch(first)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'First Name must be letters only and max 50 characters',
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
    if (last.length > 50 || !_nameRegex.hasMatch(last)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Last Name must be letters only and max 50 characters',
        isError: true,
      );
      return;
    }
    if (email.isEmpty || !_emailRegex.hasMatch(email)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Email is required',
        isError: true,
      );
      return;
    }
    if (phoneDigits.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Phone Number is required',
        isError: true,
      );
      return;
    }
    if (phoneDigits.length != 10) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please enter a valid 10-digit phone number',
        isError: true,
      );
      return;
    }
    // The 10-digit check above is sufficient for both personas. Staff used
    // to also be run through an E.164 check (`_e164Regex`, which requires
    // the first digit after '+' to be 1-9) on top of that — but a genuine
    // 10-digit local number can legitimately start with 0 (exactly the
    // reasoning already applied to exempt guardians from this same check,
    // per the comment that used to be here), so it rejected valid staff
    // phone numbers like "0970291258" with the same "valid 10-digit phone
    // number" error, even though it already was one.
    if (!widget.isParent && _streetController.text.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Street is required',
        isError: true,
      );
      return;
    }
    if (street.length > 150) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Street address cannot exceed 150 characters',
        isError: true,
      );
      return;
    }
    if (!widget.isParent && _cityController.text.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'City is required',
        isError: true,
      );
      return;
    }
    if (city.length > 50) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'City name cannot exceed 50 characters',
        isError: true,
      );
      return;
    }
    if (!widget.isParent && _zipCodeController.text.trim().isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Zip Code is required',
        isError: true,
      );
      return;
    }
    final zipDigits = zip.replaceAll(RegExp(r'\D'), '');
    if (zipDigits.isNotEmpty && !RegExp(r'^\d{5}(\d{4})?$').hasMatch(zipDigits)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Zip Code must be 5 digits (12345) or ZIP+4 (12345-6789)',
        isError: true,
      );
      return;
    }
    if (!widget.isParent && (_selectedState ?? '').trim().isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'State is required',
        isError: true,
      );
      return;
    }
    if ((_selectedCountry ?? '').trim().isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Country is required',
        isError: true,
      );
      return;
    }

    if (address2.length > 150) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Address Line 2 cannot exceed 150 characters',
        isError: true,
      );
      return;
    }

    // Matches the my-profile PATCH contract; StaffMyProfileUpdate is the
    // typed carrier all the way into the cubit — no raw map (Mandate 8).
    final fields = StaffMyProfileUpdate(
      firstName: first,
      lastName: last,
      phoneNumber: '+$phoneDigits',
      addressStreet: street,
      addressLine2: address2,
      addressCity: city,
      addressState: _selectedState ?? '',
      addressZipCode: zipDigits,
      addressCountry: 'United States',
    );

    final cubit = context.read<EditUserProfileCubit>();
    final result = await cubit.saveProfile(
      fields: fields,
      email: email,
      isParent: widget.isParent,
    );
    if (!mounted) return;

    switch (result) {
      case EditProfileSaveResult.success:
        final message = (cubit.lastSaveMessage ?? '').trim();
        // A failed email-change attempt (see saveProfile's own doc) must
        // never read as an unqualified success — the rest of the profile
        // did save, but the email specifically didn't, so this warns
        // instead of celebrating.
        CoreUtils.showTopSnackBar(
          context: context,
          message:
              message.isNotEmpty ? message : 'Profile updated successfully',
          isSuccess: !cubit.emailChangeFailed,
          isWarning: cubit.emailChangeFailed,
        );
        // Pop with result so caller can refresh profile details.
        context.pop(true);
      case EditProfileSaveResult.unresolvedStaff:
        CoreUtils.showTopSnackBar(
          context: context,
          message: widget.isParent
              ? 'Unable to resolve your profile. Please try again.'
              : 'Unable to resolve staff profile. Please try again.',
          isError: true,
        );
      case EditProfileSaveResult.failed:
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Failed to save profile. Please try again.',
          isError: true,
        );
    }
  }

  /// Simple helper to capitalize each word's first letter.
  String _toTitleCase(String input) {
    if (input.isEmpty) return input;
    return input
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;
    final isSubmitting = context
        .watch<EditUserProfileCubit>()
        .state
        .isSubmitting;
    return BlocListener<EditUserProfileCubit, EditUserProfileState>(
      listener: _onCubitState,
      child: StaffFormLayout(
        title: 'Edit My Profile',
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _InputField(
                      "First Name",
                      "E.g. John",
                      _firstNameController,
                      isRequired: true,
                    ),
                  ),
                  SizedBox(width: responsive.horizontalSpacing),
                  Expanded(
                    child: _InputField(
                      "Last Name",
                      "E.g. Smith",
                      _lastNameController,
                      isRequired: true,
                    ),
                  ),
                ],
              ),
              SizedBox(height: responsive.verticalSpacing),
              _InputField(
                "Email",
                "E.g. Jessica@wowcare.com",
                _emailController,
                isRequired: true,
              ),
              SizedBox(height: responsive.verticalSpacing),
              _InputField(
                "Phone Number",
                "E.g. (000) 000-0000",
                _phoneNoController,
                isRequired: true,
              ),
              SizedBox(height: responsive.verticalSpacing),
              _InputField(
                "Street",
                "Eg. Street no",
                _streetController,
                isRequired: true,
              ),
              SizedBox(height: responsive.verticalSpacing),
              _InputField(
                "Address line 2",
                "E.g. Address line 2",
                _addressLine2Controller,
                isRequired: false,
              ),
              SizedBox(height: responsive.verticalSpacing),
              _InputField(
                "City",
                "Eg. Nashua",
                _cityController,
                isRequired: true,
              ),
              SizedBox(height: responsive.verticalSpacing),
              _CustomDropdownField(
                "State",
                "Select",
                _stateOptions,
                _selectedState,
                (v) => setState(() => _selectedState = v),
                isRequired: true,
              ),
              SizedBox(height: responsive.verticalSpacing),
              Opacity(
                opacity: 0.8,
                child: CustomDropdown(
                  label: "Country",
                  hintText: 'United States',
                  items: const <String>['United States'],
                  selectedItem: 'United States',
                  isEnabled: false,
                  showAsterisk: true,
                  labelStyle: TextStyle(
                    fontSize: responsive.labelFontSize + 1,
                    fontFamily: Fonts.manrope,
                    fontWeight: FontWeight.w400,
                    color: AppColors.userProfileTextColor,
                  ),
                  selectedTextStyle: TextStyle(
                    fontFamily: Fonts.manrope,
                    fontSize: responsive.inputFontSize,
                    fontWeight: FontWeight.w600,
                    color: AppColors.userProfileSecondaryTextColor,
                    height: 19 / 14,
                  ),
                  popupItemTextStyle: TextStyle(
                    fontFamily: Fonts.manrope,
                    fontSize: responsive.inputFontSize,
                    fontWeight: FontWeight.w400,
                    color: AppColors.userProfileTextColor,
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: responsive.isTablet ? 16.0 : 12.0,
                    vertical: responsive.isTablet ? 16.0 : 12.0,
                  ),
                  onSelect: null,
                ),
              ),
              SizedBox(height: responsive.verticalSpacing),
              _InputField(
                "Zip Code",
                "E.g. 12345 or 12345-6789",
                _zipCodeController,
                isRequired: true,
              ),
            ],
          ),
        ),
        bottomBar: Container(
          padding: EdgeInsets.only(
            bottom: safeAreaBottom,
            left: 16,
            right: 16,
            top: 8,
          ),
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            boxShadow: [
              BoxShadow(
                color: AppColors.blackColor.withValues(alpha: 0.05),
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
              gradient: isSubmitting ? null : AppColors.buildPrimaryGradient(),
              color: isSubmitting ? AppColors.userProfileDisabledButtonColor : null,
              borderRadius: BorderRadius.circular(
                responsive.isTablet ? 16.0 : 8.0,
              ),
            ),
            child: TextButton(
              onPressed: isSubmitting ? null : () => _saveProfileDetails(),
              child: Text(
                'Save',
                style: TextStyle(
                  fontFamily: Fonts.manrope,
                  fontSize: responsive.buttonFontSize,
                  fontWeight: FontWeight.w600,
                  color: AppColors.cardColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Extracted from a `_buildInputField()` method into a private widget class
/// (Mandate 6) — a pure function of its constructor params + [context].
class _InputField extends StatelessWidget {
  const _InputField(
    this.label,
    this.hint,
    this.controller, {
    this.isRequired = false,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final labelStyle = TextStyle(
      fontSize: responsive.labelFontSize + 1,
      fontFamily: Fonts.manrope,
      fontWeight: FontWeight.w400,
      color: AppColors.userProfileTextColor,
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
                  style: TextStyle(color: AppColors.userProfileErrorColor),
                ),
            ],
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        Container(
          constraints: BoxConstraints(minHeight: responsive.inputFieldHeight),
          decoration: BoxDecoration(
            color: AppColors.cardColor,
            border: Border.all(color: AppColors.userProfileBorderColor),
            borderRadius: BorderRadius.circular(
              responsive.isTablet ? 12.0 : 8.0,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: label == 'Zip Code'
                ? TextInputType.number
                : (label == 'Phone Number'
                      ? TextInputType.phone
                      : TextInputType.text),
            inputFormatters: label == 'Zip Code'
                ? <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9),
                    _ZipCodeFormatter(),
                  ]
                : (label == 'Phone Number'
                      ? <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                          _UserPhoneNumberFormatter(),
                        ]
                      : (label == 'City'
                            ? <TextInputFormatter>[
                                FilteringTextInputFormatter.allow(
                                  RegExp(r"[a-zA-Z\s.'-]"),
                                ),
                              ]
                            : const <TextInputFormatter>[])),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: labelStyle.copyWith(color: AppColors.userProfileMutedIconColor),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: responsive.isTablet ? 16.0 : 12.0,
                vertical: responsive.isTablet ? 16.0 : 12.0,
              ),
            ),
            style: TextStyle(
              fontFamily: Fonts.manrope,
              fontSize: responsive.inputFontSize,
              fontWeight: FontWeight.w600,
              color: AppColors.userProfileTextColor,
              height: 19 / 14,
            ),
          ),
        ),
      ],
    );
  }
}

/// Extracted from a `_buildCustomDropdown()` method into a private widget
/// class (Mandate 6) — a pure function of its constructor params + [context].
class _CustomDropdownField extends StatelessWidget {
  const _CustomDropdownField(
    this.label,
    this.hintText,
    this.items,
    this.selectedItem,
    this.onSelect, {
    this.isRequired = false,
  });

  final String label;
  final String hintText;
  final List<String> items;
  final String? selectedItem;
  final ValueChanged<String?> onSelect;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
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
        fontFamily: Fonts.manrope,
        fontWeight: FontWeight.w400,
        color: AppColors.userProfileTextColor,
      ),
      labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
      fieldHeight: responsive.isTablet ? 64.0 : 56.0,
      selectedTextStyle: TextStyle(
        fontFamily: Fonts.manrope,
        fontSize: responsive.inputFontSize,
        fontWeight: FontWeight.w600,
        color: AppColors.userProfileTextColor,
        height: 19 / 14,
      ),
      popupItemTextStyle: TextStyle(
        fontFamily: Fonts.manrope,
        fontSize: responsive.inputFontSize,
        fontWeight: FontWeight.w400,
        color: AppColors.userProfileTextColor,
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: responsive.isTablet ? 16.0 : 12.0,
        vertical: responsive.isTablet ? 16.0 : 12.0,
      ),
    );
  }
}

/// Formats US ZIP codes as either:
/// - 12345
/// - 12345-6789
class _ZipCodeFormatter extends TextInputFormatter {
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
    for (var i = 0; i < digitsOnly.length && i < 9; i++) {
      if (i == 5) buffer.write('-');
      buffer.write(digitsOnly[i]);
    }
    final formatted = buffer.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

String _formatUsZipForDisplay(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '';
  if (digits.length <= 5) return digits.substring(0, digits.length);
  final first5 = digits.substring(0, 5);
  final last4 = digits.substring(5, digits.length.clamp(5, 9));
  return last4.isEmpty ? first5 : '$first5-$last4';
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
