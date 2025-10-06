import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
// import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
// import 'package:wowcare/shared/utils/core_utils.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'dart:async';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';

class AddStaffScreen extends StatefulWidget {
  const AddStaffScreen({
    super.key,
    this.isEdit = false,
    this.initialFirstName,
    this.initialLastName,
    this.initialEmail,
    this.initialPhone,
    this.initialRole,
    this.initialAllowedClassroomCodes,
    this.initialPrimaryClassroom,
    this.initialStatus,
  });
  static const String routeName = '/add-staff-screen';

  final bool isEdit;
  final String? initialFirstName;
  final String? initialLastName;
  final String? initialEmail;
  final String? initialPhone;
  final String? initialRole;
  final List<String>? initialAllowedClassroomCodes;
  final String? initialPrimaryClassroom;
  final String? initialStatus;

  @override
  _AddStaffScreenState createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends State<AddStaffScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String? _selectedRole;
  String? _selectedDesignation;
  String? _selectedPrimaryClassroom;
  final List<String> _classrooms = [
    'Classroom A',
    'Classroom B',
    'Classroom C'
  ]; // Mock data
  List<String> _selectedAllowedClassroomCodes = [];
  bool _isLoading = false;
  bool _isSubmitting = false;

  String? _selectedStatus;
  final List<String> _statuses = ['Active', 'Inactive'];
  bool get _isAdminSelected => (_selectedRole ?? '').toLowerCase() == 'admin';

  OverlayEntry? _overlayEntry;
  String? _warningMessage;
  Timer? _warningTimer;

  // Cached dropdown option lists (in-memory; not reloaded per build)
  static const List<String> _roleOptions = ['Admin', 'Staff'];
  static const List<String> _adminDesignationOptions = [
    'Director',
    'Admin',
    'Assistant Director',
    'Owner',
  ];
  static const List<String> _staffDesignationOptions = [
    'Lead teacher',
    'Associate Teacher',
    'Assistant teacher',
    'Floater',
  ];

  // Phone number validation regex - now requires exactly 10 digits
  static final RegExp _phoneRegex = RegExp(r'^\\(\\d{3}\\)\\s\\d{3}-\\d{4}$');
  // Email validation regex
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$',
  );

  @override
  void initState() {
    super.initState();
    // Prefill when editing
    if (widget.isEdit) {
      if (widget.initialFirstName != null) {
        _firstNameController.text = widget.initialFirstName!.trim();
      }
      if (widget.initialLastName != null) {
        _lastNameController.text = widget.initialLastName!.trim();
      }
      if (widget.initialEmail != null) {
        _emailController.text = widget.initialEmail!.trim();
      }
      if (widget.initialPhone != null) {
        _phoneController.text = widget.initialPhone!.trim();
      }
      _selectedRole = widget.initialRole;
      _selectedAllowedClassroomCodes =
          List<String>.from(widget.initialAllowedClassroomCodes ?? []);
      _selectedPrimaryClassroom = widget.initialPrimaryClassroom;
      _selectedStatus = widget.initialStatus;
    }
    // Default role when creating new entry
    _selectedRole ??= widget.initialRole ?? 'Staff';
    // If role is Admin, preselect allowed classrooms and primary classroom
    if (_isAdminSelected) {
      _selectedAllowedClassroomCodes = List<String>.from(_classrooms);
      // Ensure 'Office' is available as a default primary classroom
      if (!_classrooms.contains('Office')) {
        _classrooms.insert(0, 'Office');
      }
      _selectedPrimaryClassroom ??= 'Office';
      _selectedStatus ??= 'Active';
    }
  }

  @override
  void dispose() {
    _removeDropdownOverlay();
    _warningTimer?.cancel();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _addStaff() {
    _trimAllInputs();
    if (_firstNameController.text.isEmpty) {
      // CoreUtils.showTopSnackBar(
      //     context: context, message: 'First name is required', isError: true);
      return;
    }
    if (_lastNameController.text.isEmpty) {
      // CoreUtils.showTopSnackBar(
      //     context: context, message: 'Last name is required', isError: true);
      return;
    }

    final emailError = _validateEmail(_emailController.text);
    if (emailError != null) {
      // CoreUtils.showTopSnackBar(
      //     context: context, message: emailError, isError: true);
      return;
    }

    final phoneError = _validatePhoneNumber(_phoneController.text);
    if (phoneError != null) {
      // CoreUtils.showTopSnackBar(
      //     context: context, message: phoneError, isError: true);
      return;
    }

    if (_selectedRole == null) {
      // CoreUtils.showTopSnackBar(
      //     context: context, message: 'Please select a role', isError: true);
      return;
    }

    if (!_isAdminSelected && _selectedAllowedClassroomCodes.isEmpty) {
      // CoreUtils.showTopSnackBar(
      //     context: context,
      //     message: 'Please select at least one allowed classroom',
      //     isError: true);
      return;
    }

    if (_selectedPrimaryClassroom == null) {
      // CoreUtils.showTopSnackBar(
      //     context: context,
      //     message: 'Please select a primary classroom',
      //     isError: true);
      return;
    }

    if (_selectedStatus == null) {
      // CoreUtils.showTopSnackBar(
      //     context: context, message: 'Please select a status', isError: true);
      return;
    }

    // Additional validations based on role
    if (_isAdminSelected) {
      // Ensure designation picked from admin list
      if (_selectedDesignation == null || !_adminDesignationOptions.contains(_selectedDesignation)) {
        return;
      }
      // Admins have all classrooms allowed by default
      _selectedAllowedClassroomCodes = List<String>.from(_classrooms);
      if (_selectedPrimaryClassroom == null) {
        _selectedPrimaryClassroom = 'Office';
      }
    } else {
      // Staff designation validation
      if (_selectedDesignation == null || !_staffDesignationOptions.contains(_selectedDesignation)) {
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    // Mock API call
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isSubmitting = false;
      });
      // CoreUtils.showTopSnackBar(
      //     context: context, message: 'Staff created successfully', isSuccess: true);
      Navigator.pop(context);
    });
  }

  void _trimAllInputs() {
    _firstNameController.text = _firstNameController.text.trim();
    _lastNameController.text = _lastNameController.text.trim();
    _emailController.text = _emailController.text.trim();
    _phoneController.text = _phoneController.text.trim();
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
      // Use default behavior (not floating)
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.orange.shade100),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _removeDropdownOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showSingleSelectDropdown({
    required BuildContext context,
    required List<String> items,
    required Function(String) onSelected,
    required GlobalKey key,
  }) {
    if (_overlayEntry != null) {
      _removeDropdownOverlay();
      return;
    }

    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeDropdownOverlay,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            top: position.dy + size.height,
            left: position.dx,
            width: size.width,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      title: Text(item),
                      onTap: () {
                        onSelected(item);
                        _removeDropdownOverlay();
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _showMultiSelectDropdown({
    required BuildContext context,
    required List<String> items,
    required List<String> selectedItems,
    required Function(List<String>) onConfirm,
    required GlobalKey key,
  }) {
    if (_overlayEntry != null) {
      _removeDropdownOverlay();
      return;
    }

    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;
    final position = renderBox.localToGlobal(Offset.zero);

    final tempSelected = List<String>.from(selectedItems);

    _overlayEntry = OverlayEntry(
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: _removeDropdownOverlay,
                child: Container(color: Colors.transparent),
              ),
            ),
            Positioned(
              top: position.dy + size.height - 40,
              left: position.dx,
              width: size.width,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return CheckboxListTile(
                            title: Text(item),
                            value: tempSelected.contains(item),
                            onChanged: (value) {
                              setDialogState(() {
                                if (value == true) {
                                  tempSelected.add(item);
                                } else {
                                  tempSelected.remove(item);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          onConfirm(tempSelected);
                          _removeDropdownOverlay();
                        },
                        child: const Text('OK'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!_emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    final digits = value.replaceAll(RegExp(r'\\D'), '');
    if (digits.length != 10) {
      return 'Please enter a valid 10-digit phone number';
    }
    if (!_phoneRegex.hasMatch(value)) {
      return 'Please enter a valid US phone number (e.g., (123) 456-7890)';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;

    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
        _removeDropdownOverlay();
      },
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
                    padding: EdgeInsets.symmetric(
                        horizontal: responsive.horizontalSpacing),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                      widget.isEdit ? "Edit Staff" : "Add Staff",
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
                      padding:
                          EdgeInsets.all(responsive.isTablet ? 32.0 : 16.0),
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
                  child: Column(
                    children: [
                          if (_warningMessage != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                border: Border.all(color: Colors.orange.shade100),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning, color: Colors.orange),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _warningMessage!,
                                      style: const TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _warningMessage = null;
                                      });
                                    },
                                    child: const Icon(Icons.close, color: Colors.orange, size: 20),
                                  ),
                                ],
                              ),
                            ),
                          Expanded(
                            child: ListView(
                              padding: EdgeInsets.zero,
                              children: [
                          // Role dropdown (Admin / Staff) - first field
                          CustomDropdown(
                            label: "Role",
                            hintText: 'Select',
                            items: _roleOptions,
                            selectedItem: _selectedRole,
                            labelStyle: TextStyle(
                              fontSize: responsive.labelFontSize,
                              fontFamily: "Manrope",
                              fontWeight: FontWeight.w400,
                              color: const Color(0xff573353),
                            ),
                            showAsterisk: true,
                            labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
                            onSelect: (val) {
                              if (val == null) return;
                              setState(() {
                                _selectedRole = val;
                                if (_isAdminSelected) {
                                  _selectedAllowedClassroomCodes = List<String>.from(_classrooms);
                                  if (!_classrooms.contains('Office')) {
                                    _classrooms.insert(0, 'Office');
                                  }
                                  _selectedPrimaryClassroom = 'Office';
                                  _selectedStatus ??= 'Active';
                                } else {
                                  _selectedAllowedClassroomCodes = [];
                                  _selectedPrimaryClassroom = null;
                                }
                              });
                            },
                          ),
                                SizedBox(height: responsive.verticalSpacing),
                          _buildRowInputs(
                            context,
                            "First Name",
                            "Last Name",
                          ),
                                SizedBox(height: responsive.verticalSpacing),
                          _buildInputField(
                            "Email",
                            "E.g. name@example.com",
                            _emailController,
                            keyboardType: TextInputType.emailAddress,
                            inputFormatters: [TrimFormatter()],
                          ),
                                SizedBox(height: responsive.verticalSpacing),
                          _buildInputField(
                            "Phone Number",
                            "E.g. (000) 000-0000",
                            _phoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                              PhoneNumberFormatter(),
                              TrimFormatter(),
                            ],
                          ),
                                SizedBox(height: responsive.verticalSpacing),
                          // Designation
                          CustomDropdown(
                            label: "Designation",
                            hintText: 'Select',
                            items: _isAdminSelected
                                ? _adminDesignationOptions
                                : _staffDesignationOptions,
                            selectedItem: _selectedDesignation,
                            labelStyle: TextStyle(
                              fontSize: responsive.labelFontSize,
                              fontFamily: "Manrope",
                              fontWeight: FontWeight.w400,
                              color: const Color(0xff573353),
                            ),
                            showAsterisk: true,
                            labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
                            onSelect: (val) => setState(() => _selectedDesignation = val ?? _selectedDesignation),
                          ),
                                SizedBox(height: responsive.verticalSpacing),
                          if (!_isAdminSelected)
                            _buildMultiSelectDropdown(
                              label: "Allowed Classrooms",
                              selectedCount:
                                  _selectedAllowedClassroomCodes.length,
                              items: _classrooms,
                              selectedItems: _selectedAllowedClassroomCodes,
                              onConfirm: (values) => setState(
                                  () => _selectedAllowedClassroomCodes = values),
                            )
                          else
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6),
                                child: Text(
                                  'All classrooms are allowed for admin users',
                                  style: TextStyle(
                                    fontSize: responsive.labelFontSize,
                                    fontFamily: 'Manrope',
                                    color: const Color(0xff573353),
                                  ),
                                ),
                              ),
                            ),
                                SizedBox(height: responsive.verticalSpacing),
                          CustomDropdown(
                            label: "Primary Classroom",
                            hintText: 'Select',
                            items: _isAdminSelected
                                ? (['Office', ..._classrooms.where((e) => e != 'Office')])
                                : _classrooms,
                            selectedItem: _selectedPrimaryClassroom,
                            labelStyle: TextStyle(
                              fontSize: responsive.labelFontSize,
                              fontFamily: "Manrope",
                              fontWeight: FontWeight.w400,
                              color: const Color(0xff573353),
                            ),
                            showAsterisk: true,
                            labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
                            onSelect: (val) {
                              if (val == null) return;
                              setState(() => _selectedPrimaryClassroom = val);
                            },
                          ),
                                SizedBox(height: responsive.verticalSpacing),
                          CustomDropdown(
                            label: "Status",
                            hintText: 'Select',
                            items: const ['Active', 'Upcoming'],
                            selectedItem: _selectedStatus,
                            labelStyle: TextStyle(
                              fontSize: responsive.labelFontSize,
                              fontFamily: "Manrope",
                              fontWeight: FontWeight.w400,
                              color: const Color(0xff573353),
                            ),
                            showAsterisk: true,
                            labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
                            onSelect: (val) => setState(() => _selectedStatus = val ?? _selectedStatus),
                          ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
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
              bottom: safeAreaBottom, left: 16, right: 16, top: 8),
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
              borderRadius:
                  BorderRadius.circular(responsive.isTablet ? 16.0 : 8.0),
            ),
            child: TextButton(
              onPressed: _isSubmitting ? null : _addStaff,
              child: Text(
                widget.isEdit ? 'Save' : 'Add',
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

  Widget _buildRowInputs(BuildContext context, String label1, String label2) {
    final responsive = ResponsiveHelper(context);
    return Row(
      children: [
        Expanded(
          child: _buildInputField(
            label1,
            "E.g. John",
            _firstNameController,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z\s]")),
              NameCapitalizationFormatter(),
              TrimFormatter(),
            ],
          ),
        ),
        SizedBox(width: responsive.isTablet ? 24.0 : 16.0),
        Expanded(
          child: _buildInputField(
            label2,
            "E.g. Smith",
            _lastNameController,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z\s]")),
              NameCapitalizationFormatter(),
              TrimFormatter(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(
      String label, String hint, TextEditingController controller,
      {TextInputType? keyboardType,
      List<TextInputFormatter>? inputFormatters}) {
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
              const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        Container(
          constraints: BoxConstraints(minHeight: responsive.inputFieldHeight),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0x66573353)),
            borderRadius:
                BorderRadius.circular(responsive.isTablet ? 12.0 : 8.0),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: responsive.inputFontSize,
              fontWeight: FontWeight.w600, // typing weight
              color: const Color(0xff573353),
              height: 19 / 14,
            ),
            decoration: InputDecoration(
              hintText: hint,
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

  Widget _buildDropdown({
    required String label,
    String? value,
    required List<String> items,
    required Function(String) onSelected,
  }) {
    final responsive = ResponsiveHelper(context);
    final key = GlobalKey();
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: responsive.labelFontSize,
              fontFamily: "Manrope",
              fontWeight: FontWeight.w400,
              color: AppColors.primaryColor,
            ),
            children: [
              TextSpan(text: label),
              const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 4.0),
        GestureDetector(
          onTap: () {
            if (label == 'Primary Classroom' &&
                _selectedAllowedClassroomCodes.isEmpty) {
              // CoreUtils.showTopSnackBar(
              //   context: context,
              //   message: 'Please select allowed classrooms first',
              //   isWarning: true,
              // );
              return;
            }
            _showSingleSelectDropdown(
              context: context,
              items: items,
              onSelected: onSelected,
              key: key,
            );
          },
          child: Container(
            height: responsive.inputFieldHeight,
            padding: EdgeInsets.symmetric(
              horizontal: responsive.isTablet ? 20.0 : 16.0,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0x66573353)),
              borderRadius:
                  BorderRadius.circular(responsive.isTablet ? 12.0 : 8.0),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? 'Select',
                    style: TextStyle(
                      color: value == null ? Colors.grey : Colors.black,
                      fontSize: responsive.inputFontSize,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: const Color(0xff573353),
                  size: responsive.isTablet ? 28.0 : 24.0,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMultiSelectDropdown({
    required String label,
    required int selectedCount,
    required List<String> items,
    required List<String> selectedItems,
    required Function(List<String>) onConfirm,
  }) {
    final responsive = ResponsiveHelper(context);
    final key = GlobalKey();
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: responsive.labelFontSize,
              fontFamily: "Manrope",
              fontWeight: FontWeight.w400,
              color: AppColors.primaryColor,
            ),
            children: [
              TextSpan(text: label),
              const TextSpan(text: ' *', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 4.0),
        GestureDetector(
          onTap: () => _showMultiSelectDropdown(
            context: context,
            items: items,
            selectedItems: selectedItems,
            onConfirm: onConfirm,
            key: key,
          ),
          child: Container(
            height: responsive.inputFieldHeight,
            padding: EdgeInsets.symmetric(
              horizontal: responsive.isTablet ? 20.0 : 16.0,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0x66573353)),
              borderRadius:
                  BorderRadius.circular(responsive.isTablet ? 12.0 : 8.0),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedCount == 0
                        ? 'Select'
                        : '$selectedCount Classroom(s) selected',
                    style: TextStyle(
                      color: selectedCount == 0 ? Colors.grey : Colors.black,
                      fontSize: responsive.inputFontSize,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: const Color(0xff573353),
                  size: responsive.isTablet ? 28.0 : 24.0,
                ),
              ],
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
    final newText = newValue.text;

    if (newText.isEmpty) {
      return newValue;
    }

    final digitsOnly = newText.replaceAll(RegExp(r'\D'), '');
    final charCount = digitsOnly.length;

    String formattedText;
    if (charCount == 0) {
      formattedText = '';
    } else if (charCount <= 3) {
      formattedText = '($digitsOnly';
    } else if (charCount <= 6) {
      formattedText = '(${digitsOnly.substring(0, 3)}) ${digitsOnly.substring(3)}';
    } else {
      formattedText = '(${digitsOnly.substring(0, 3)}) ${digitsOnly.substring(3, 6)}-${digitsOnly.substring(6)}';
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

class NameCapitalizationFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;

    // Remove trailing spaces
    text = text.replaceFirst(RegExp(r"\s+"), ' '); // collapse multiple spaces inside
    text = text.replaceAll(RegExp(r"\s{2,}"), ' ');
    text = text.replaceAll(RegExp(r"\s+\z"), '');

    if (text.isEmpty) {
      return newValue.copyWith(text: text, selection: const TextSelection.collapsed(offset: 0));
    }

    // Enforce first letter uppercase, remaining lowercase
    final firstChar = text[0].toUpperCase();
    final rest = text.length > 1 ? text.substring(1).toLowerCase() : '';
    final formatted = firstChar + rest;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class TrimFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final trimmed = newValue.text.trimLeft();
    // Preserve caret at end for simplicity
    return TextEditingValue(
      text: trimmed,
      selection: TextSelection.collapsed(offset: trimmed.length),
    );
  }
} 