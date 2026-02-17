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
import 'package:wowcare/shared/common/widgets/multi_selection_widget.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/constants/location_constants.dart';
import 'package:wowcare/core/util/core_utils.dart';

class EditStudentProfileDetailsScreen extends StatefulWidget {
  const EditStudentProfileDetailsScreen({
    super.key,
    this.initialFirstName,
    this.initialLastName,
    this.initialStatus,
    this.initialClassroom,
    this.initialBirthDate,
    this.initialNotes,
    this.initialFTE,
    this.initialStreet,
    this.initialCity,
    this.initialState,
    this.initialCountry,
    this.initialZipCode,
  });
  static const String routeName = '/edit-student-profile-details-screen';

  final String? initialFirstName;
  final String? initialLastName;
  final String? initialStatus;
  final String? initialNotes;
  final String? initialClassroom;
  final DateTime? initialBirthDate;
  final String? initialFTE;
  final String? initialStreet;
  final String? initialCity;
  final String? initialState;
  final String? initialCountry;
  final String? initialZipCode;

  @override
  _EditStudentProfileDetailsScreenState createState() => _EditStudentProfileDetailsScreenState();
}

class _EditStudentProfileDetailsScreenState extends State<EditStudentProfileDetailsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _FTEController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _street2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();

  String? _selectedStatus;
  String? _selectedStateSubsidyOption;
  List<String> _selectedSiblings = [];
  List<String> _selectedTags = [];
  String? _selectedClassroom;
  DateTime? _selectedBirthDate;
  List<String> _selectedChildCustody = [];
  String? _selectedState;
  String? _selectedCountry;
  bool _isSubmitting = false;

  final List<String> _allTags = [
    '5 Days',
    'Full Day',
    'Photo Permission',
    'Vegetarian',
    'First Aid',
    'Allergy',
    'Pickup Authorized',
  ];
  final List<String> _allStudents = [
    'Raghave Gupta',
    'Rohan Gupta',
    'Ruhi Gupta',
    'Anya Mehta',
    'Kabir Mehta',
    'Sara Khan',
  ];
  final List<String> _statusOptions = ['Active', 'Inactive', 'Upcoming', 'Waitlist', 'Graduated'];
  final List<String> _stateSubsidyOptions = ['Yes', 'No'];
  final List<String> _classroomOptions = ['1-Blue D', '3-Orange-D', '2-Red A'];
  final List<String> _childCustodyOptions = ['Mother', 'Father', 'Both Mother and Father'];
  final List<String> _stateOptions =
      US_STATES.map((s) => s.name).toList(growable: false);
  final List<String> _countryOptions =
      COUNTRY_LIST.map((c) => c.name).toList(growable: false);

  // Simple validators (align with Add Staff)
  static final RegExp _nameRegex = RegExp(r"^[A-Za-z][A-Za-z\-'\s]{0,49}");
  static final RegExp _fteRegex = RegExp(r"^(?:100|[1-9]?[0-9])$");

  @override
  void initState() {
    super.initState();
    // Prefill when editing (use existing profile values; no mock defaults).
    _firstNameController.text = widget.initialFirstName ?? '';
    _lastNameController.text = widget.initialLastName ?? '';
    _notesController.text = widget.initialNotes ?? '';
    _FTEController.text = widget.initialFTE ?? '';
    _selectedStatus = widget.initialStatus;
    _selectedStateSubsidyOption = null;
    _selectedClassroom = widget.initialClassroom;
    _selectedBirthDate = widget.initialBirthDate;
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
    _notesController.dispose();
    _FTEController.dispose();
    _street2Controller.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  Future<void> _saveProfileDetails() async {
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    final fte = _FTEController.text.trim();

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
    if (_selectedClassroom == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Classroom is required',
        isError: true,
      );
      return;
    }
    if (fte.isNotEmpty && !_fteRegex.hasMatch(fte)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'FTE must be a number between 0 and 100.',
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

    // Mock API call
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Student profile updated successfully',
        isSuccess: true,
      );
      Navigator.pop(context, true);
    });
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
      child: Scaffold(
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
                      'Edit Student',
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
                        _buildCustomDropdown("Classroom", "Select", _classroomOptions, _selectedClassroom, (v) => setState(() => _selectedClassroom = v), isRequired: true),
                        SizedBox(height: responsive.verticalSpacing),
                        MultiSelectWidget(
                          availableOptions: _allTags,
                          selectedOptions: _selectedTags,
                          onSelectionChanged: (tags) {
                            setState(() => _selectedTags = tags);
                          },
                          isRequired: false,
                          showClearAllOption: true,
                          clearSelectionText: "Select Tags",
                        ),
                        SizedBox(height: responsive.verticalSpacing),
                        _buildDateField("Birthdate", _selectedBirthDate),
                        SizedBox(height: responsive.verticalSpacing),
                        _buildInputField(
                          "Notes",
                          "",
                          _notesController,
                        ),
                        SizedBox(height: responsive.verticalSpacing),
                        MultiSelectWidget(
                          availableOptions: _allStudents,
                          selectedOptions: _selectedSiblings,
                          onSelectionChanged: (siblings) {
                            setState(() => _selectedSiblings = siblings);
                          },
                          isRequired: false,
                          colorfulSelection: false,
                          label: "Siblings",
                          hintText: 'Select student',
                          showClearAllOption: true,
                          clearSelectionText: "Select Sibling/s",
                        ),
                        SizedBox(height: responsive.verticalSpacing),
                        MultiSelectWidget(
                          availableOptions: _childCustodyOptions,
                          selectedOptions: _selectedChildCustody,
                          onSelectionChanged: (custodyOptions) {
                            setState(() => _selectedChildCustody = custodyOptions);
                          },
                          isRequired: true,
                          colorfulSelection: false,
                          label: "Child Custody",
                          hintText: 'Select guardian',
                        ),
                        SizedBox(height: responsive.verticalSpacing),
                        _buildCustomDropdown("State Subsidy", "Select", _stateSubsidyOptions, _selectedStateSubsidyOption, (v) => setState(() => _selectedStateSubsidyOption = v)),
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
