import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

class EditProfileDetailsScreen extends StatefulWidget {
  const EditProfileDetailsScreen({
    super.key,
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
  });
  static const String routeName = '/edit-profile-details-screen';

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
  final TextEditingController _pinController = TextEditingController();
  
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
  final List<String> _designationOptions = ['Admin', 'Teacher', 'Assistant', 'Manager', 'Director'];
  final List<String> _classroomOptions = ['5 Days X', '1-Blue D X', '3-Orange-D X', 'Office X', '2-Red A X'];
  final List<String> _jobTagOptions = ['Full Time', 'Part Time', 'Contract', 'Temporary'];
  final List<String> _stateOptions = ['New Hampshire', 'Massachusetts', 'Vermont', 'Maine', 'Connecticut'];
  final List<String> _countryOptions = ['United States', 'Canada', 'Mexico'];

  // Simple validators (align with Add Staff)
  static final RegExp _nameRegex = RegExp(r"^[A-Za-z][A-Za-z\-'\s]{0,49}");
  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');
  static final RegExp _e164Regex = RegExp(r'^\+?[1-9]\d{7,14}$');

  @override
  void initState() {
    super.initState();
    // Prefill when editing
    _firstNameController.text = widget.initialFirstName ?? 'Jessica';
    _lastNameController.text = widget.initialLastName ?? 'Rhodes';
    _selectedStatus = widget.initialStatus ?? 'Active';
    _selectedDesignation = widget.initialDesignation ?? 'Admin';
    _selectedAllowedClassrooms = widget.initialAllowedClassrooms ?? ['5 Days X', '1-Blue D X', '3-Orange-D X'];
    _selectedPrimaryClassroom = widget.initialPrimaryClassroom ?? 'Office X';
    _selectedBirthDate = widget.initialBirthDate;
    _selectedJobTag = widget.initialJobTag ?? 'Full Time';
    _emailController.text = widget.initialEmail ?? 'Jessica@wowcare.com';
    _phoneNumberController.text = widget.initialPhoneNumber ?? '(986) 027-1627';
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
    _emailController.dispose();
    _phoneNumberController.dispose();
    _street2Controller.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  void _saveProfileDetails() {
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final phoneRaw = _phoneNumberController.text.trim();
    final phoneDigits = phoneRaw.replaceAll(RegExp(r'\D'), '');

    if (first.isEmpty || !_nameRegex.hasMatch(first)) {
      _showWarningMessage('First Name is required');
      return;
    }
    if (last.isEmpty || !_nameRegex.hasMatch(last)) {
      _showWarningMessage('Last Name is required');
      return;
    }
    if (_selectedAllowedClassrooms.isEmpty) {
      _showWarningMessage('At least one classroom must be selected');
      return;
    }
    if (_selectedPrimaryClassroom == null) {
      _showWarningMessage('Primary Classroom is required');
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

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;

    return StaffFormLayout(
      title: "Edit Profile Details",
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Personal Details Section
          _buildInputField("First Name", "E.g. Jessica", _firstNameController, isRequired: true),
          SizedBox(height: responsive.verticalSpacing),
          _buildInputField("Last Name", "E.g. Rhodes", _lastNameController, isRequired: true),
          SizedBox(height: responsive.verticalSpacing),
          _buildCustomDropdown("Status", "Select", _statusOptions, _selectedStatus, (value) => setState(() => _selectedStatus = value)),
          SizedBox(height: responsive.verticalSpacing),
          _buildCustomDropdown("Designation", "Select", _designationOptions, _selectedDesignation, (value) => setState(() => _selectedDesignation = value)),
          
          SizedBox(height: responsive.verticalSpacing),
          
          // Classroom Information Section
          _buildClassroomSection(),
          SizedBox(height: responsive.verticalSpacing),
          _buildPrimaryClassroomSection(),
          
          SizedBox(height: responsive.verticalSpacing),
          
          // Dates & Employment Section
          _buildDateField("Birthdate", _selectedBirthDate),
          SizedBox(height: responsive.verticalSpacing),
          _buildCustomDropdown("Job Tag", "Select", _jobTagOptions, _selectedJobTag, (value) => setState(() => _selectedJobTag = value)),
          
          SizedBox(height: responsive.verticalSpacing),
          
          // Contact Information Section
          _buildInputField("Email", "E.g. Jessica@wowcare.com", _emailController, isRequired: true),
          SizedBox(height: responsive.verticalSpacing),
          _buildInputField("Phone Number", "E.g. (986) 027-1627", _phoneNumberController, isRequired: true),
          
          SizedBox(height: responsive.verticalSpacing),
          
          // Address Information Section
          _buildInputField("Street", "Eg. Street no", _streetController, isRequired: true),
          SizedBox(height: responsive.verticalSpacing),
          _buildInputField("Address line 2", "(Optional)", _street2Controller, isRequired: false),
          SizedBox(height: responsive.verticalSpacing),
          _buildInputField("City", "Eg. Nashua", _cityController, isRequired: true),
          SizedBox(height: responsive.verticalSpacing),
          _buildCustomDropdown("State", "Select", _stateOptions, _selectedState, (value) => setState(() => _selectedState = value), isRequired: true),
          SizedBox(height: responsive.verticalSpacing),
          _buildCustomDropdown("Country", "Select", _countryOptions, _selectedCountry, (value) => setState(() => _selectedCountry = value), isRequired: true),
          SizedBox(height: responsive.verticalSpacing),
          _buildInputField("Zip Code", "Eg. 85001", _zipCodeController, isRequired: true),
          SizedBox(height: responsive.verticalSpacing),
          _buildPinField(responsive),
          SizedBox(height: responsive.verticalSpacing),
          _buildWorkTimeSection(responsive),
          SizedBox(height: responsive.verticalSpacing),
          _buildBreakTimeSection(responsive),
          
          const SizedBox(height: 12),
        ],
      ),
      bottomBar: Container(
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
            color: const Color(0xFFF8F7FA),
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: labelStyle.copyWith(color: AppColors.primaryColor.withOpacity(0.6)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            style: TextStyle(
              color: AppColors.primaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
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
    return CustomDropdown(
      label: isRequired ? "$label *" : label,
      hintText: hintText,
      items: items,
      selectedItem: selectedItem,
      onSelect: onSelect,
    );
  }

  Widget _buildPinField(ResponsiveHelper responsive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: responsive.labelFontSize,
              fontFamily: "Manrope",
              fontWeight: FontWeight.w400,
              color: const Color(0xff573353),
            ),
            children: const [
              TextSpan(text: 'Clock In-Out PIN'),
              TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        Row(
          children: [
            Expanded(
              child: Container(
                constraints: BoxConstraints(minHeight: responsive.inputFieldHeight),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F7FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: responsive.inputFieldHeight,
              decoration: BoxDecoration(
                gradient: AppColors.buildPrimaryGradient(),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextButton(
                onPressed: _generatePin,
                child: const Text(
                  'Generate',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _generatePin() {
    final now = DateTime.now().millisecondsSinceEpoch.toString();
    final pin = now.substring(now.length - 4);
    setState(() {
      _pinController.text = pin;
    });
  }

  Widget _buildWorkTimeSection(ResponsiveHelper responsive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Work Time',
          style: TextStyle(
            fontSize: responsive.labelFontSize,
            fontFamily: "Manrope",
            fontWeight: FontWeight.w400,
            color: const Color(0xff573353),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: responsive.inputFieldHeight,
          decoration: BoxDecoration(
            color: const Color(0xFFF8F7FA),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: const Text('Select working days & time (coming soon)', style: TextStyle(color: AppColors.primaryColor)),
        ),
      ],
    );
  }

  Widget _buildBreakTimeSection(ResponsiveHelper responsive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Break Time',
          style: TextStyle(
            fontSize: responsive.labelFontSize,
            fontFamily: "Manrope",
            fontWeight: FontWeight.w400,
            color: const Color(0xff573353),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: responsive.inputFieldHeight,
          decoration: BoxDecoration(
            color: const Color(0xFFF8F7FA),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: const Text('Select break days & time (coming soon)', style: TextStyle(color: AppColors.primaryColor)),
        ),
      ],
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
            constraints: const BoxConstraints(minHeight: 40),
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F7FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      selectedDate != null 
                          ? DateFormat('MMM dd, yyyy').format(selectedDate)
                          : 'Select Date',
                      style: TextStyle(
                        color: selectedDate == null 
                            ? AppColors.primaryColor.withOpacity(0.6)
                            : AppColors.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
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

  Widget _buildClassroomSection() {
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
              const TextSpan(text: 'Allowed Classrooms'),
              const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _selectedAllowedClassrooms.map((classroom) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedAllowedClassrooms.remove(classroom);
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F7FA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.primaryColor.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      classroom,
                      style: const TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.close,
                      size: 16,
                      color: AppColors.primaryColor,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            // Show dialog to add more classrooms
            _showClassroomSelectionDialog();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.add,
                  size: 16,
                  color: AppColors.primaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  'Add Classroom',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryClassroomSection() {
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
              const TextSpan(text: 'Primary Classroom'),
              const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        GestureDetector(
          onTap: () {
            _showPrimaryClassroomSelectionDialog();
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F7FA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      _selectedPrimaryClassroom ?? 'Select Primary Classroom',
                      style: TextStyle(
                        color: _selectedPrimaryClassroom == null 
                            ? AppColors.primaryColor.withOpacity(0.6)
                            : AppColors.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.primaryColor,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showClassroomSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Classrooms'),
        content: SingleChildScrollView(
          child: Column(
            children: _classroomOptions.map((classroom) {
              final isSelected = _selectedAllowedClassrooms.contains(classroom);
              return CheckboxListTile(
                title: Text(classroom),
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedAllowedClassrooms.add(classroom);
                    } else {
                      _selectedAllowedClassrooms.remove(classroom);
                    }
                  });
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _showPrimaryClassroomSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Primary Classroom'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _classroomOptions.map((classroom) {
            return ListTile(
              title: Text(classroom),
              onTap: () {
                setState(() {
                  _selectedPrimaryClassroom = classroom;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
