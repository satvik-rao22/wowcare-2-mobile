import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../../../shared/common/widgets/profile_show_widget.dart';
import '../../../../shared/common/widgets/schedule_picker.dart';
import '../../../../shared/common/widgets/multi_selection_widget.dart';

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
  final ImagePicker _picker = ImagePicker();

  String? _selectedStatus;
  String? _selectedStateSubsidyOption ;
  List<String> _selectedSiblings = [];
  List<String> _selectedTags = ['Full Day'];
  String? _selectedClassroom;
  DateTime? _selectedBirthDate;
  DateTime? _selectedUpcomingMoveDate;
  List<String> _selectedChildCustody = ['Mother'];
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
  final List<String> _stateOptions = ['New Hampshire', 'Massachusetts', 'Vermont', 'Maine', 'Connecticut'];
  final List<String> _countryOptions = ['United States', 'Canada', 'Mexico'];

  static final RegExp _nameRegex = RegExp(r"^[A-Za-z][A-Za-z\-'\s]{0,49}");
  static final RegExp _fteRegex = RegExp(r"^(?:100|[1-9]?[0-9])$");

  @override
  void initState() {
    super.initState();
    // Prefill when editing
    _firstNameController.text = widget.initialFirstName ?? 'Jessica';
    _lastNameController.text = widget.initialLastName ?? 'Rhodes';
    _notesController.text = widget.initialNotes ?? '';
    _FTEController.text = widget.initialFTE ?? '';
    _selectedStatus = widget.initialStatus ?? 'Active';
    _selectedStateSubsidyOption ='No';
    _selectedClassroom = widget.initialClassroom ?? '1-Blue D';
    _selectedBirthDate = widget.initialBirthDate;
    _streetController.text = widget.initialStreet ?? '';
    _street2Controller.text = '';
    _cityController.text = widget.initialCity ?? '';
    _selectedState = widget.initialState ?? 'New Hampshire';
    _selectedCountry = widget.initialCountry ?? 'United States';
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

  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      // TODO: wire this to upload/update avatar in your backend/state
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selected profile image')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  void _saveProfileDetails() {
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    final fte = _FTEController.text.trim();

    if (first.isEmpty || !_nameRegex.hasMatch(first)) {
      _showWarningMessage('First Name is required');
      return;
    }
    if (last.isEmpty || !_nameRegex.hasMatch(last)) {
      _showWarningMessage('Last Name is required');
      return;
    }
    if (_selectedClassroom == null) {
      _showWarningMessage('Classroom is required');
      return;
    }
    if (fte.isEmpty) {
      _showWarningMessage('FTE is required');
      return;
    }
    if (!_fteRegex.hasMatch(fte)) {
      _showWarningMessage('FTE must be a number between 0 and 100.');
      return;
    }

    if (_streetController.text.isEmpty) {
      _showWarningMessage('Street is required');
      return;
    }
    if (_cityController.text.isEmpty) {
      _showWarningMessage('City is required');
      return;
    }
    if (_zipCodeController.text.trim().isEmpty) {
      _showWarningMessage('Zip Code is required');
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

  Future<void> _selectUpcomingMoveDate() async {
    try {
      final result = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => CalendarDialog(
          isRangePicker: false,
          isTimePicker: false,
          initialDate: _selectedUpcomingMoveDate,
        ),
      );

      if (result != null && result['date'] != null) {
        setState(() {
          _selectedUpcomingMoveDate = result['date'] as DateTime;
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
                      'Edit Student Details',
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
                              child: Column(
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        fontSize: responsive.labelFontSize,
                                        fontFamily: "Manrope",
                                        fontWeight: FontWeight.w400,
                                        color: const Color(0xff573353),
                                      ),
                                      children: [
                                        TextSpan(text: 'Change Profile Photo'),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: responsive.verticalSpacing),
                                  GestureDetector(
                                  onTap: _pickProfileImage,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      DocumentImageWidget(
                                        fileUuid: 'cd',
                                        name: 'cd',
                                        size: 110,
                                        fontSize: 40,
                                      ),
                                      Positioned(
                                        right: -4,
                                        bottom: -4,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.08),
                                                blurRadius: 4,
                                                //offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              gradient:
                                              AppColors.buildPrimaryGradient(),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.camera_alt,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),],
                              ),
                            ),
                            SizedBox(width: responsive.isTablet ? 24.0 : 16.0),
                            Expanded(
                              child: Column(
                                children: [
                                  SizedBox(height: responsive.verticalSpacing),
                                  _buildInputField(
                                    "First Name",
                                    "E.g. John",
                                    _firstNameController,
                                    isRequired: true
                                  ),
                                  SizedBox(height: responsive.verticalSpacing),
                                  _buildInputField(
                                    "Last Name",
                                    "E.g. Smith",
                                    _lastNameController,
                                    isRequired: true
                                  ),

                                ],
                              ),
                            ),
                          ],
                        ),
                        // Row(
                        //   children: [
                        //     Expanded(
                        //       child: _buildInputField(
                        //         "First Name",
                        //         "E.g. John",
                        //         _firstNameController,
                        //       ),
                        //     ),
                        //     SizedBox(width: responsive.isTablet ? 24.0 : 16.0),
                        //     Expanded(
                        //       child: _buildInputField(
                        //         "Last Name",
                        //         "E.g. Smith",
                        //         _lastNameController,
                        //       ),
                        //     ),
                        //   ],
                        // ),
                        SizedBox(height: responsive.verticalSpacing),
                        _buildCustomDropdown("Status", "Select", _statusOptions, _selectedStatus, (v) => setState(() => _selectedStatus = v), isRequired: true),
                        SizedBox(height: responsive.verticalSpacing),
                        Stack(
                          children: [
                            CustomDropdown(
                              label: "Classroom",
                              hintText: 'Select',
                              items: _classroomOptions,
                              selectedItem: _selectedClassroom,
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
                              onSelect: (val) => setState(() => _selectedClassroom = val),
                            ),
                          ],
                        ),
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
                        Text(
                            "Schedule",
                            style: TextStyle(
                              fontSize: responsive.labelFontSize,
                              fontFamily: "Manrope",
                              fontWeight: FontWeight.w400,
                              color: const Color(0xff573353),
                            )
                        ),
                        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
                        SchedulePicker(),
                        SizedBox(height: responsive.verticalSpacing),

                        _buildDateField("Birthdate", _selectedBirthDate, _selectBirthDate, true),
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
                        //_buildCustomDropdown("Child Custody", "Select Parent", _childCustodyOptions, _selectedChildCustody, (v) => setState(() => _selectedChildCustody = v)),
                        SizedBox(height: responsive.verticalSpacing),
                        _buildCustomDropdown("State Subsidy", "", _stateSubsidyOptions, _selectedStateSubsidyOption, (v) => setState(() => _selectedStateSubsidyOption = v)),
                        SizedBox(height: responsive.verticalSpacing),
                        // _buildInputField("FTE", "E.g. 60", _FTEController, isRequired: true),
                        // SizedBox(height: responsive.verticalSpacing),
                        // _buildDateField("Upcoming Move", _selectedUpcomingMoveDate, _selectUpcomingMoveDate, false),
                        // SizedBox(height: responsive.verticalSpacing),
                        _buildInputField("Street", "Eg. Street no", _streetController, isRequired: true),
                        SizedBox(height: responsive.verticalSpacing),
                        _buildInputField("Address line 2", "(Optional)", _street2Controller, isRequired: false),
                        SizedBox(height: responsive.verticalSpacing),
                        _buildInputField("City", "Eg. Nashua", _cityController, isRequired: true),
                        SizedBox(height: responsive.verticalSpacing),
                        _buildCustomDropdown("State", "Select", _stateOptions, _selectedState, (v) => setState(() => _selectedState = v), isRequired: true),
                        SizedBox(height: responsive.verticalSpacing),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                              style: TextStyle(
                              color: AppColors.primaryColor,
                              fontSize:  13,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'Manrope',
                              ),
                              children: [
                                TextSpan(text: 'Country'),
                                const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
                              ],
                              ),
                            ),
                            SizedBox(height: responsive.isTablet ? 8.0 : 6.0 ),
                            InkWell(
                              onTap: (){
                                _showWarningMessage("Can not be edited.");
                              },
                              child: Container(
                                constraints: BoxConstraints(minHeight: responsive.isTablet ? 64.0 : 56.0 ),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F7FA),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child:Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: responsive.isTablet ? 16.0 : 12.0,
                                    vertical: responsive.isTablet ? 16.0 : 12.0,
                                    ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          "United States",
                                          style: TextStyle(
                                            fontFamily: 'Manrope',
                                            fontSize: responsive.inputFontSize,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade600,
                                            height: 19 / 14,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.left,
                                        ),
                                      ),
                                      const SizedBox(width: 4),

                                    ],
                                  ),
                                ),
                                ),
                            ),
                          ],
                        ),
                        //_buildCustomDropdown("Country", "Select", _countryOptions, _selectedCountry, (v) => setState(() => _selectedCountry = v), isRequired: true),
                        SizedBox(height: responsive.verticalSpacing),
                        _buildInputField("Zip Code", "Eg. 85001", _zipCodeController, isRequired: true),
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

  Widget _buildDateField(String label, DateTime? selectedDate, Future<void> Function() onTap, bool isRequired) {
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
        GestureDetector(
          onTap: onTap,
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
