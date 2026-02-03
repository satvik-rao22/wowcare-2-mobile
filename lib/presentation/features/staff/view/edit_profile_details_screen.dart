import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/shared/common/widgets/classroom_selection_widget_exact.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/constants/location_constants.dart';

class EditProfileDetailsScreen extends StatefulWidget {
  const EditProfileDetailsScreen({
    super.key,
    required this.staffCode,
    this.initialFirstName,
    this.initialLastName,
    this.initialStatus,
    this.initialDesignation,
    this.initialAllowedClassrooms,
    this.initialPrimaryClassroom,
    this.initialBirthDate,
    this.initialJobTag,
    this.initialEmail,
    this.initialPhoneNumber,
    this.initialStreet,
    this.initialCity,
    this.initialState,
    this.initialCountry,
    this.initialZipCode,
    this.initialClassroomNames,
    this.initialClassroomCodeByName,
  });
  static const String routeName = '/edit-profile-details-screen';

  final String staffCode;
  final String? initialFirstName;
  final String? initialLastName;
  final String? initialStatus;
  final String? initialDesignation;
  final List<String>? initialAllowedClassrooms;
  final String? initialPrimaryClassroom;
  final DateTime? initialBirthDate;
  final String? initialJobTag;
  final String? initialEmail;
  final String? initialPhoneNumber;
  final String? initialStreet;
  final String? initialCity;
  final String? initialState;
  final String? initialCountry;
  final String? initialZipCode;
  /// Optional cached classroom names (to avoid extra classroom API calls).
  final List<String>? initialClassroomNames;
  /// Optional mapping from classroom name -> classroom code.
  final Map<String, String>? initialClassroomCodeByName;

  @override
  _EditProfileDetailsScreenState createState() => _EditProfileDetailsScreenState();
}

class _EditProfileDetailsScreenState extends State<EditProfileDetailsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _street2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();
  
  String? _selectedStatus;
  String? _selectedDesignation;
  List<String> _selectedAllowedClassrooms = [];
  String? _selectedPrimaryClassroom;
  DateTime? _selectedBirthDate;
  String? _selectedJobTag;
  String? _selectedState;
  String? _selectedCountry;
  bool _isSubmitting = false;

  final List<String> _statusOptions = ['Active', 'Inactive', 'Upcoming'];
  final List<String> _designationOptions = [
    'Director',
    'Admin',
    'Assistant Director',
    'Owner',
    'Lead teacher',
    'Associate Teacher',
    'Assistant teacher',
    'Floater',
  ];
  // Backed by classroom names; populated from widget.initialClassroomNames/CodeByName.
  final List<String> _classroomOptions = [];
  final List<String> _jobTagOptions = ['Full Time', 'Part Time'];
  final List<String> _stateOptions =
      US_STATES.map((s) => s.name).toList(growable: false);
  final List<String> _countryOptions =
      COUNTRY_LIST.map((c) => c.name).toList(growable: false);

  // Simple validators (align with Add Staff)
  static final RegExp _nameRegex = RegExp(r"^[A-Za-z][A-Za-z\-'\s]{0,49}");
  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');
  static final RegExp _e164Regex = RegExp(r'^\+?[1-9]\d{7,14}$');

  /// Map from classroom display name -> classroom code (for API payload).
  final Map<String, String> _classroomCodeByName = {};

  @override
  void initState() {
    super.initState();
    // Hydrate classrooms from cached metadata if available (no extra API calls).
    if (widget.initialClassroomNames != null &&
        widget.initialClassroomNames!.isNotEmpty) {
      _classroomOptions
        ..clear()
        ..addAll(widget.initialClassroomNames!);
    } else if (widget.initialAllowedClassrooms != null &&
        widget.initialAllowedClassrooms!.isNotEmpty) {
      // Fall back to allowed classrooms as the only selectable options.
      _classroomOptions
        ..clear()
        ..addAll(widget.initialAllowedClassrooms!);
    }

    _classroomCodeByName
      ..clear()
      ..addAll(widget.initialClassroomCodeByName ?? {});

    // Prefill when editing (use existing profile values; no mock defaults).
    _firstNameController.text = widget.initialFirstName ?? '';
    _lastNameController.text = widget.initialLastName ?? '';
    _selectedStatus = widget.initialStatus;
    _selectedDesignation =
        _mapDesignationFromApiOrLabel(widget.initialDesignation);
    _selectedAllowedClassrooms =
        List<String>.from(widget.initialAllowedClassrooms ?? const []);
    _selectedPrimaryClassroom = widget.initialPrimaryClassroom;
    _selectedBirthDate = widget.initialBirthDate;
    _selectedJobTag = widget.initialJobTag?.isNotEmpty == true
        ? _mapJobTagFromApiOrLabel(widget.initialJobTag)
        : null;
    _emailController.text = widget.initialEmail ?? '';
    _phoneNumberController.text =
        _formatUsPhone(widget.initialPhoneNumber ?? '');
    _streetController.text = widget.initialStreet ?? '';
    _street2Controller.text = '';
    _cityController.text = widget.initialCity ?? '';

    // Map initial state (name or abbreviation) to display name from US_STATES.
    if (widget.initialState != null && widget.initialState!.isNotEmpty) {
      final raw = widget.initialState!;
      final match = US_STATES.firstWhere(
        (s) =>
            s.name.toLowerCase() == raw.toLowerCase() ||
            s.abbreviation.toLowerCase() == raw.toLowerCase(),
        orElse: () => US_STATES.first,
      );
      _selectedState = match.name;
    }

    // Map initial country (name or code) to display name from COUNTRY_LIST.
    if (widget.initialCountry != null && widget.initialCountry!.isNotEmpty) {
      final raw = widget.initialCountry!;
      final match = COUNTRY_LIST.firstWhere(
        (c) =>
            c.name.toLowerCase() == raw.toLowerCase() ||
            c.code.toLowerCase() == raw.toLowerCase(),
        orElse: () => COUNTRY_LIST.first,
      );
      _selectedCountry = match.name;
    }

    _zipCodeController.text = widget.initialZipCode ?? '';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _street2Controller.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  Future<void> _saveProfileDetails() async {
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final phoneRaw = _phoneNumberController.text.trim();
    final phoneDigits = phoneRaw.replaceAll(RegExp(r'\D'), '');

    if (first.isEmpty || !_nameRegex.hasMatch(first)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'First Name is required',
        isError: true,
      );
      return;
    }
    if (last.isEmpty || !_nameRegex.hasMatch(last)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Last Name is required',
        isError: true,
      );
      return;
    }
    if (_selectedAllowedClassrooms.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'At least one classroom must be selected',
        isError: true,
      );
      return;
    }
    if (_selectedPrimaryClassroom == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Primary Classroom is required',
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
    if (phoneDigits.length < 10 || (!_e164Regex.hasMatch('+' + phoneDigits))) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Phone Number is required',
        isError: true,
      );
      return;
    }
    if (_streetController.text.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Street is required',
        isError: true,
      );
      return;
    }
    if (_cityController.text.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'City is required',
        isError: true,
      );
      return;
    }
    if (_zipCodeController.text.trim().isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Zip Code is required',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final statusApi = _mapStatusToApiValue(_selectedStatus!);
      final designationApi = _mapDesignationToApiValue(_selectedDesignation);
      final jobTagApi =
          _selectedJobTag == null ? null : _mapJobTagToApiValue(_selectedJobTag!);

      final primaryClassroomCode = _selectedPrimaryClassroom == null
          ? null
          : (_classroomCodeByName[_selectedPrimaryClassroom!] ??
              _selectedPrimaryClassroom);
      final allowedClassroomCodes = _selectedAllowedClassrooms
          .map((name) => _classroomCodeByName[name] ?? name)
          .toList();

      final profilePayload = <String, dynamic>{
        'firstName': first,
        'lastName': last,
        'status': statusApi,
        'phoneNumber': phoneDigits,
        'designation': designationApi,
        if (jobTagApi != null) 'jobTag': jobTagApi,
        if (_selectedBirthDate != null)
          'birthdate': _selectedBirthDate!.toIso8601String(),
        'primaryClassroomCode': primaryClassroomCode,
        'allowedClassroomCodes': allowedClassroomCodes,
      };

      // Map selected state/country display names back to codes for API.
      String stateCode = '';
      if (_selectedState != null && _selectedState!.isNotEmpty) {
        final match = US_STATES.firstWhere(
          (s) => s.name.toLowerCase() == _selectedState!.toLowerCase(),
          orElse: () => US_STATES.first,
        );
        stateCode = match.abbreviation;
      }

      String countryCode = '';
      if (_selectedCountry != null && _selectedCountry!.isNotEmpty) {
        final match = COUNTRY_LIST.firstWhere(
          (c) => c.name.toLowerCase() == _selectedCountry!.toLowerCase(),
          orElse: () => COUNTRY_LIST.first,
        );
        countryCode = match.code;
      }

      final addressPayload = <String, dynamic>{
        'addressStreet': _streetController.text.trim(),
        'addressLine2': _street2Controller.text.trim(),
        'addressCity': _cityController.text.trim(),
        'addressState': stateCode,
        'addressZipCode': _zipCodeController.text.trim(),
        'addressCountry': countryCode,
      };

      final repository = serviceLocator<StaffRepository>();

      // Update core profile fields
      final profileMessage = await repository.updateStaffProfile(
        staffCode: widget.staffCode,
        fields: profilePayload,
      );

      // Then update address via dedicated endpoint
      final addressMessage = await repository.updateStaffAddress(
        staffCode: widget.staffCode,
        fields: addressPayload,
      );

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });

      CoreUtils.showTopSnackBar(
        context: context,
        message: addressMessage.isNotEmpty ? addressMessage : profileMessage,
        isSuccess: true,
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      final message = ApiErrorHandler.extractErrorMessage(e);
      CoreUtils.showTopSnackBar(
        context: context,
        message: message,
        isError: true,
      );
    }
  }

  String _mapStatusToApiValue(String uiStatus) {
    switch (uiStatus.toLowerCase()) {
      case 'active':
        return 'ACTIVE';
      case 'inactive':
        return 'INACTIVE';
      case 'upcoming':
        return 'UPCOMING';
      default:
        return uiStatus.toUpperCase().replaceAll(' ', '_');
    }
  }

  String _mapDesignationToApiValue(String? uiDesignation) {
    if (uiDesignation == null) return '';

    const adminMapping = {
      'Director': 'DIRECTOR',
      'Admin': 'ADMIN',
      'Assistant Director': 'ASSISTANT_DIRECTOR',
      'Owner': 'OWNER',
    };

    const staffMapping = {
      'Lead teacher': 'LEAD_TEACHER',
      'Associate Teacher': 'ASSOCIATE_TEACHER',
      'Assistant teacher': 'ASSISTANT_TEACHER',
      'Floater': 'FLOATER',
    };

    return adminMapping[uiDesignation] ??
        staffMapping[uiDesignation] ??
        uiDesignation.toUpperCase().replaceAll(' ', '_');
  }

  String? _mapDesignationFromApiOrLabel(String? value) {
    if (value == null || value.isEmpty) return null;
    // If it's already a friendly label from dropdown, just return it.
    if (_designationOptions.contains(value)) return value;

    // Reverse mapping from known API enums to UI labels.
    const reverseMap = {
      'DIRECTOR': 'Director',
      'ADMIN': 'Admin',
      'ASSISTANT_DIRECTOR': 'Assistant Director',
      'OWNER': 'Owner',
      'LEAD_TEACHER': 'Lead teacher',
      'ASSOCIATE_TEACHER': 'Associate Teacher',
      'ASSISTANT_TEACHER': 'Assistant teacher',
      'FLOATER': 'Floater',
    };

    final upper = value.toUpperCase();
    return reverseMap[upper] ?? value;
  }

  String _mapJobTagToApiValue(String uiJobTag) {
    switch (uiJobTag.toLowerCase()) {
      case 'full time':
        return 'FULL_TIME';
      case 'part time':
        return 'PART_TIME';
      default:
        return uiJobTag.toUpperCase().replaceAll(' ', '_');
    }
  }

  String? _mapJobTagFromApiOrLabel(String? value) {
    if (value == null || value.isEmpty) return null;
    if (_jobTagOptions.contains(value)) return value;
    final upper = value.toUpperCase();
    if (upper == 'FULL_TIME') return 'Full Time';
    if (upper == 'PART_TIME') return 'Part Time';
    return value;
  }

  /// Formats a raw phone string into (XXX) XXX-XXXX when possible.
  String _formatUsPhone(String? input) {
    final raw = (input ?? '').trim();
    if (raw.isEmpty) return '';
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return raw;
    final area = digits.substring(0, 3);
    final mid = digits.substring(3, 6);
    final last = digits.substring(6, 10);
    return '($area) $mid-$last';
  }

  Future<void> _selectBirthDate() async {
    try {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => CalendarDialog(
          isRangePicker: false,
          isTimePicker: false,
          initialDate: _selectedBirthDate,
        ),
      );
      
      if (result != null && result['date'] != null) {
        setState(() {
          _selectedBirthDate = result['date'] as DateTime;
        });
      }
    } catch (e) {
      print('Error opening calendar dialog: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold
      (
        key: _scaffoldKey,
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
                  padding: EdgeInsets.symmetric(horizontal: responsive.horizontalSpacing),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Edit Staff',
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
                    margin: EdgeInsets.symmetric(horizontal: responsive.horizontalSpacing),
                    padding: EdgeInsets.all(responsive.isTablet ? 32.0 : 16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(responsive.isTablet ? 40.0 : 24.0)),
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
                        Row(
                          children: [
                            Expanded(
                              child: _buildInputField(
                                "First Name",
                                "E.g. John",
                                _firstNameController,
                              ),
                            ),
                            SizedBox(width: responsive.isTablet ? 24.0 : 16.0),
                            Expanded(
                              child: _buildInputField(
                                "Last Name",
                                "E.g. Smith",
                                _lastNameController,
                              ),
                            ),
                          ],
                        ),
          SizedBox(height: responsive.verticalSpacing),
                        _buildCustomDropdown("Status", "Select", _statusOptions, _selectedStatus, (v) => setState(() => _selectedStatus = v), isRequired: true),
          SizedBox(height: responsive.verticalSpacing),
                        _buildCustomDropdown("Designation", "Select", _designationOptions, _selectedDesignation, (v) => setState(() => _selectedDesignation = v), isRequired: true),
          SizedBox(height: responsive.verticalSpacing),

                        // Allowed Classrooms like Add Staff
                        ClassroomSelectionWidgetExact(
                          primaryClassroom: _selectedPrimaryClassroom,
                          allowedClassrooms: _selectedAllowedClassrooms,
                          availableClassrooms: _classroomOptions,
                          onPrimaryClassroomChanged: (classroom) {
                            setState(() {
                              _selectedPrimaryClassroom = classroom;
                            });
                          },
                          onAllowedClassroomsChanged: (classrooms) {
                            setState(() {
                              _selectedAllowedClassrooms = classrooms;
                              if (_selectedPrimaryClassroom != null && !classrooms.contains(_selectedPrimaryClassroom)) {
                                _selectedPrimaryClassroom = null;
                              }
                            });
                          },
                          primaryClassroomError: null,
                          allowedClassroomsError: null,
                          showPrimaryClassroom: false,
                        ),
          SizedBox(height: responsive.verticalSpacing),
          
                        // Primary Classroom Dropdown with guard
                        Stack(
                          children: [
                            CustomDropdown(
                              label: "Primary Classroom",
                              hintText: 'Select',
                              items: _selectedAllowedClassrooms.isEmpty ? [] : _selectedAllowedClassrooms,
                              selectedItem: _selectedPrimaryClassroom,
                              labelStyle: TextStyle(
                                fontSize: responsive.labelFontSize,
                                fontFamily: "Manrope",
                                fontWeight: FontWeight.w400,
                                color: const Color(0xff573353),
                              ),
                              showAsterisk: true,
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
                              onSelect: (val) => setState(() => _selectedPrimaryClassroom = val),
                            ),
                            if (_selectedAllowedClassrooms.isEmpty)
                              Positioned.fill(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    CoreUtils.showTopSnackBar(
                                      context: context,
                                      message: 'Please select Allowed Classrooms first',
                                      isError: true,
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
          SizedBox(height: responsive.verticalSpacing),
          
          _buildDateField("Birthdate", _selectedBirthDate),
          SizedBox(height: responsive.verticalSpacing),
                        _buildCustomDropdown("Job Tag", "Select", _jobTagOptions, _selectedJobTag, (v) => setState(() => _selectedJobTag = v)),
          SizedBox(height: responsive.verticalSpacing),
          _buildInputField(
            "Email",
            "E.g. Jessica@wowcare.com",
            _emailController,
            isRequired: true,
            keyboardType: TextInputType.emailAddress,
            textCapitalization: TextCapitalization.none,
          ),
          SizedBox(height: responsive.verticalSpacing),
                        _buildInputField(
                          "Phone Number",
                          "E.g. (000) 000-0000",
                          _phoneNumberController,
                          isRequired: true,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                            _EditPhoneNumberFormatter(),
                          ],
                        ),
          SizedBox(height: responsive.verticalSpacing),
          _buildInputField(
            "Street",
            "Eg. Street no",
            _streetController,
            isRequired: true,
            textCapitalization: TextCapitalization.words,
          ),
                        SizedBox(height: responsive.verticalSpacing),
                        _buildInputField(
                          "Address line 2",
                          "(Optional)",
                          _street2Controller,
                          isRequired: false,
                          textCapitalization: TextCapitalization.words,
                        ),
          SizedBox(height: responsive.verticalSpacing),
          _buildInputField(
            "City",
            "Eg. Nashua",
            _cityController,
            isRequired: true,
            textCapitalization: TextCapitalization.words,
          ),
          SizedBox(height: responsive.verticalSpacing),
                        _buildCustomDropdown("State", "Select", _stateOptions, _selectedState, (v) => setState(() => _selectedState = v), isRequired: true),
          SizedBox(height: responsive.verticalSpacing),
                        _buildCustomDropdown("Country", "Select", _countryOptions, _selectedCountry, (v) => setState(() => _selectedCountry = v), isRequired: true),
          SizedBox(height: responsive.verticalSpacing),
          _buildInputField(
            "Zip Code",
            "Eg. 85001",
            _zipCodeController,
            isRequired: true,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
          ),
                        SizedBox(height: responsive.verticalSpacing),
                        // _buildPinField(responsive),
                        // SizedBox(height: responsive.verticalSpacing),
                        // _buildWorkTimeSection(responsive),
                        // SizedBox(height: responsive.verticalSpacing),
                        // _buildBreakTimeSection(responsive),
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
            onPressedConfirm: _saveProfileDetails,
            showCancelButton: false,
            isForm: false,
            isLoading: _isSubmitting,
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


  Widget _buildDateField(String label, DateTime? selectedDate) {
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
        Text(label, style: labelStyle),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        GestureDetector(
          onTap: _selectBirthDate,
          child: Container(
            constraints: BoxConstraints(minHeight: responsive.inputFieldHeight),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0x66573353)),
              borderRadius: BorderRadius.circular(responsive.isTablet ? 12.0 : 8.0),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.isTablet ? 16.0 : 12.0,
                vertical: responsive.isTablet ? 16.0 : 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      selectedDate != null 
                          ? DateFormat('MMM dd, yyyy').format(selectedDate)
                          : 'Select Date',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: responsive.inputFontSize,
                        fontWeight: selectedDate != null ? FontWeight.w600 : FontWeight.w500,
                        color: const Color(0xff573353),
                        height: 19 / 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  SvgPicture.asset(
                    MediaRes.calender_icon,
                    height: 20.0,
                    colorFilter: const ColorFilter.mode(AppColors.primaryColor, BlendMode.srcIn),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

}

/// Simple phone formatter to display US numbers as (XXX) XXX-XXXX
/// while keeping only digits for API submission.
class _EditPhoneNumberFormatter extends TextInputFormatter {
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
