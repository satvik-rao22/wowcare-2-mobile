import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'dart:async';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/classroom_selection_widget_exact.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/presentation/features/staff/cubit/create_school_user_cubit.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';

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
    this.initialClassroomNames,
    this.initialClassroomCodeByName,
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
  // Prefetched classroom metadata (to avoid re-calling classrooms API)
  final List<String>? initialClassroomNames;
  final Map<String, String>? initialClassroomCodeByName;

  @override
  _AddStaffScreenState createState() => _AddStaffScreenState();
}

class _AddStaffScreenState extends State<AddStaffScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  late final CreateSchoolUserCubit _createSchoolUserCubit;
  ClassroomCubit? _classroomCubit;
  String? _selectedRole;
  String? _selectedDesignation;
  String? _selectedPrimaryClassroomName;
  final List<String> _classrooms = [];
  final Map<String, String> _classroomCodeByName = {};
  List<String> _selectedAllowedClassroomNames = [];
  String? _primaryClassroomError;
  String? _allowedClassroomsError;

  String? _selectedStatus;
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
  // Email validation regexes: strict and permissive; accept if any matches
  static final RegExp _emailRegexStrict = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static final RegExp _emailRegexPermissive = RegExp(
    r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$',
  );

  @override
  void initState() {
    super.initState();
    _createSchoolUserCubit = serviceLocator<CreateSchoolUserCubit>();
    // Get ClassroomCubit from service locator (will be created if not exists)
    _classroomCubit = serviceLocator<ClassroomCubit>();
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
      _selectedAllowedClassroomNames =
          List<String>.from(widget.initialAllowedClassroomCodes ?? []);
      _selectedPrimaryClassroomName = widget.initialPrimaryClassroom;
      _selectedStatus = widget.initialStatus;
    }
    // Default role when creating new entry
    _selectedRole ??= widget.initialRole ?? 'Staff';

    // If classrooms were prefetched by a parent screen (e.g. StaffScreen),
    // hydrate local caches from those and avoid hitting the classrooms API again.
    if (widget.initialClassroomNames != null &&
        widget.initialClassroomNames!.isNotEmpty) {
      _classrooms
        ..clear()
        ..addAll(widget.initialClassroomNames!);
      _classroomCodeByName
        ..clear()
        ..addAll(widget.initialClassroomCodeByName ?? {});

      // For admin, all classrooms are auto-allowed and primary defaults to first.
      if (_isAdminSelected) {
        _selectedAllowedClassroomNames = List<String>.from(_classrooms);
        if (_classrooms.isNotEmpty &&
            _selectedPrimaryClassroomName == null) {
          _selectedPrimaryClassroomName = _classrooms.first;
        }
        _selectedStatus ??= 'Active';
      }
    } else {
      // No prefetched classrooms available – fall back to API call.
      _loadClassrooms();
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
    _createSchoolUserCubit.close();
    // Only close _classroomCubit if we created it (not if it came from context)
    // We'll handle this in build method
    super.dispose();
  }

  void _addStaff() {
    _trimAllInputs();
    if (_firstNameController.text.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'First name is required',
        isError: true,
      );
      return;
    }
    if (_lastNameController.text.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Last name is required',
        isError: true,
      );
      return;
    }

    final emailError = _validateEmail(_emailController.text);
    if (emailError != null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: emailError,
        isError: true,
      );
      return;
    }

    final phoneError = _validatePhoneNumber(_phoneController.text);
    if (phoneError != null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: phoneError,
        isError: true,
      );
      return;
    }

    if (_selectedRole == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please select a role',
        isError: true,
      );
      return;
    }

    // Validate classroom selection
    setState(() {
      _primaryClassroomError = null;
      _allowedClassroomsError = null;
    });

    if (!_isAdminSelected && _selectedAllowedClassroomNames.isEmpty) {
      setState(() {
        _allowedClassroomsError = 'Please select at least one allowed classroom';
      });
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please select Allowed Classrooms',
        isError: true,
      );
      return;
    }

    if (!_isAdminSelected && _selectedPrimaryClassroomName == null) {
      setState(() {
        _primaryClassroomError = 'Please select a primary classroom';
      });
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please select a Primary Classroom',
        isError: true,
      );
      return;
    }

    if (_selectedStatus == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please select a status',
        isError: true,
      );
      return;
    }

    // Additional validations based on role
    if (_isAdminSelected) {
      // Ensure designation picked from admin list
      if (_selectedDesignation == null || !_adminDesignationOptions.contains(_selectedDesignation)) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Please select a valid designation',
          isError: true,
        );
        return;
      }
      // Admins have all classrooms allowed by default
      _selectedAllowedClassroomNames = List<String>.from(_classrooms);
      if (_selectedPrimaryClassroomName == null && _classrooms.isNotEmpty) {
        _selectedPrimaryClassroomName = _classrooms.first;
      }
    } else {
      // Staff designation validation
      if (_selectedDesignation == null || !_staffDesignationOptions.contains(_selectedDesignation)) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Please select a valid designation',
          isError: true,
        );
        return;
      }
    }

    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final displayName = _composeStaffName();
    final email = _emailController.text.trim();
    final mobileDigits = _phoneController.text.trim().replaceAll(
          RegExp(r'\D'),
          '',
        );

    final isAdmin = _isAdminSelected;
    final role = isAdmin ? 'SCHOOL_ADMIN' : 'STAFF';

    final primaryClassroomCode = _selectedPrimaryClassroomName == null
        ? ''
        : (_classroomCodeByName[_selectedPrimaryClassroomName!] ?? '').trim();
    var allowedClassroomCodes = _selectedAllowedClassroomNames
        .map((name) => _classroomCodeByName[name])
        .whereType<String>()
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();

    // Block submit if classroom codes could not be resolved (API needs valid codes)
    if (primaryClassroomCode.isEmpty) {
      if (!_isAdminSelected) {
        setState(() => _primaryClassroomError = 'Please select a primary classroom');
      }
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Could not resolve classroom code. Please refresh the page and try again.',
        isError: true,
      );
      return;
    }
    if (!_isAdminSelected && allowedClassroomCodes.isEmpty && _selectedAllowedClassroomNames.isNotEmpty) {
      setState(() => _allowedClassroomsError = 'Could not resolve classroom codes');
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Could not resolve classroom codes. Please refresh the page and try again.',
        isError: true,
      );
      return;
    }

    _createSchoolUserCubit.create(
      isAdmin: isAdmin,
      firstName: firstName,
      lastName: lastName,
      displayName: displayName,
      mobile: mobileDigits,
      email: email,
      role: role,
      designation: _mapDesignationToApiValue(_selectedDesignation),
      status: _selectedStatus,
      primaryClassroomCode: primaryClassroomCode,
      allowedClassroomCodes: allowedClassroomCodes,
    );
  }

  String _composeStaffName() {
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    final name = [first, last].where((p) => p.isNotEmpty).join(' ');
    return name;
  }

  Future<void> _loadClassrooms() async {
    // Load classrooms via cubit
    _classroomCubit!.loadActiveClassrooms();
  }

  void _updateClassroomsFromCubitState(ClassroomState state) {
    if (state.classrooms.isEmpty) {
      if (state.errorMessage != null) {
        CoreUtils.logApiError(state.errorMessage!);
      } else if (!state.isLoading) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'No classrooms found for this school',
          isWarning: true,
        );
      }
      return;
    }

    final names = state.classrooms.map((c) => c.name).toList();
    final codeByName = <String, String>{};
    for (final c in state.classrooms) {
      codeByName[c.name] = c.code;
    }

    setState(() {
      _classrooms
        ..clear()
        ..addAll(names);
      _classroomCodeByName
        ..clear()
        ..addAll(codeByName);

      if (_isAdminSelected) {
        _selectedAllowedClassroomNames = List<String>.from(_classrooms);
        if (_classrooms.isNotEmpty &&
            _selectedPrimaryClassroomName == null) {
          _selectedPrimaryClassroomName = _classrooms.first;
        }
        _selectedStatus ??= 'Active';
      }
    });
  }

  /// Maps UI designation values to API uppercase values
  String _mapDesignationToApiValue(String? uiDesignation) {
    if (uiDesignation == null) return '';
    
    // Admin designations mapping
    const adminMapping = {
      'Director': 'DIRECTOR',
      'Admin': 'ADMIN',
      'Assistant Director': 'ASSISTANT_DIRECTOR',
      'Owner': 'OWNER',
    };
    
    // Staff designations mapping
    const staffMapping = {
      'Lead teacher': 'LEAD_TEACHER',
      'Associate Teacher': 'ASSOCIATE_TEACHER',
      'Assistant teacher': 'ASSISTANT_TEACHER',
      'Floater': 'FLOATER',
    };
    
    // Check admin mapping first, then staff mapping
    return adminMapping[uiDesignation] ?? 
           staffMapping[uiDesignation] ?? 
           uiDesignation.toUpperCase().replaceAll(' ', '_');
  }

  void _trimAllInputs() {
    _firstNameController.text = _firstNameController.text.trim();
    _lastNameController.text = _lastNameController.text.trim();
    _emailController.text = _emailController.text.trim();
    _phoneController.text = _phoneController.text.trim();
  }

  void _removeDropdownOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }


  String? _validateEmail(String? value) {
    // Debug logging to diagnose email validation issues
    final raw = value ?? '';
    final trimmed = raw.trim().toLowerCase();
    print('[Email Validation] raw: "$raw"');
    print('[Email Validation] trimmed: "$trimmed"');
    print('[Email Validation] strict regex: ${_emailRegexStrict.pattern}');
    print('[Email Validation] permissive regex: ${_emailRegexPermissive.pattern}');

    if (trimmed.isEmpty) {
      print('[Email Validation] FAIL: empty');
      return 'Email is required';
    }

    final hasAt = trimmed.contains('@');
    final hasDot = trimmed.contains('.') && trimmed.lastIndexOf('.') > trimmed.indexOf('@');
    final strictMatch = _emailRegexStrict.hasMatch(trimmed);
    final permissiveMatch = _emailRegexPermissive.hasMatch(trimmed);
    final matches = strictMatch || permissiveMatch || (hasAt && hasDot && trimmed.length >= 6);
    print('[Email Validation] hasAt: $hasAt, hasDotAfterAt: $hasDot');
    print('[Email Validation] strictMatch: $strictMatch, permissiveMatch: $permissiveMatch');
    print('[Email Validation] final hasMatch: $matches');
    if (!matches) {
      // Pinpoint common issues
      if (trimmed.contains(' ')) {
        print('[Email Validation] contains spaces');
      }
      if (!trimmed.contains('@')) {
        print('[Email Validation] missing @');
      }
      if (!trimmed.contains('.')) {
        print('[Email Validation] missing dot in domain');
      }
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePhoneNumber(String? value) {
    final raw = (value ?? '').trim();
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    print('[Phone Validation] raw: "$raw"');
    print('[Phone Validation] digitsOnly: "$digits"');
    print('[Phone Validation] regex: ${_phoneRegex.pattern}');

    if (raw.isEmpty) {
      return 'Phone number is required';
    }
    if (digits.length != 10) {
      print('[Phone Validation] FAIL: digits length = ${digits.length}');
      return 'Please enter a valid 10-digit phone number';
    }
    // Accept either formatted string OR any 10-digit input (formatter will format on type)
    final formattedMatch = _phoneRegex.hasMatch(raw);
    print('[Phone Validation] formattedMatch: $formattedMatch');
    return null; // digits == 10 is sufficient
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;

    // Get ClassroomCubit from context if available, otherwise use the one from service locator
    ClassroomCubit classroomCubit;
    try {
      // Try to get from context (if provided by parent)
      classroomCubit = context.read<ClassroomCubit>();
    } catch (e) {
      // If not available in context, use the one from service locator
      classroomCubit = _classroomCubit!;
    }

    // Provide ClassroomCubit to ensure it's available in the widget tree
    return BlocProvider<ClassroomCubit>.value(
      value: classroomCubit,
      child: BlocProvider<CreateSchoolUserCubit>.value(
        value: _createSchoolUserCubit,
        child: BlocBuilder<ClassroomCubit, ClassroomState>(
        builder: (context, classroomState) {
          // Update local state when classrooms are loaded from cubit
          if (!classroomState.isLoading && 
              classroomState.classrooms.isNotEmpty && 
              _classrooms.isEmpty &&
              (widget.initialClassroomNames == null || widget.initialClassroomNames!.isEmpty)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _updateClassroomsFromCubitState(classroomState);
            });
          } else if (classroomState.errorMessage != null && _classrooms.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _updateClassroomsFromCubitState(classroomState);
            });
          }

          return BlocListener<CreateSchoolUserCubit, CreateSchoolUserState>(
            listener: (context, state) {
              if (!mounted) return;

              if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
                CoreUtils.logApiError(state.errorMessage!);
                return;
              }

              final result = state.result;
              if (result != null) {
                final staffName = _composeStaffName();
                CoreUtils.showTopSnackBar(
                  context: context,
                  message: result.message.isNotEmpty
                      ? result.message
                      : 'User created successfully',
                  isSuccess: true,
                );
                Navigator.pop(context, {
                  'showPostAddPrompt': true,
                  'staffName': staffName,
                  'userCode': result.user.userCode,
                });
              }
            },
            child: GestureDetector(
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
                                  _selectedAllowedClassroomNames = List<String>.from(_classrooms);
                                  if (_classrooms.isNotEmpty) {
                                    _selectedPrimaryClassroomName = _classrooms.first;
                                  }
                                  _selectedStatus ??= 'Active';
                                } else {
                                  _selectedAllowedClassroomNames = [];
                                  _selectedPrimaryClassroomName = null;
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
                          // Classroom Selection Widget
                          if (!_isAdminSelected)
                            Column(
                              children: [
                                // Allowed Classrooms
                                ClassroomSelectionWidgetExact(
                                  primaryClassroom: _selectedPrimaryClassroomName,
                                  allowedClassrooms: _selectedAllowedClassroomNames,
                                  availableClassrooms: _classrooms,
                                  onPrimaryClassroomChanged: (classroom) {
                                    setState(() {
                                      _selectedPrimaryClassroomName = classroom;
                                      _primaryClassroomError = null;
                                    });
                                  },
                                  onAllowedClassroomsChanged: (classrooms) {
                                    setState(() {
                                      _selectedAllowedClassroomNames = classrooms;
                                      _allowedClassroomsError = null;
                                      // Clear primary classroom if it's not in allowed classrooms anymore
                                      if (_selectedPrimaryClassroomName != null && 
                                          !classrooms.contains(_selectedPrimaryClassroomName)) {
                                        _selectedPrimaryClassroomName = null;
                                      }
                                    });
                                  },
                                  primaryClassroomError: _primaryClassroomError,
                                  allowedClassroomsError: _allowedClassroomsError,
                                  showPrimaryClassroom: false, // Hide primary classroom section
                                ),
                                SizedBox(height: responsive.verticalSpacing),
                                // Primary Classroom Dropdown
                                Stack(
                                  children: [
                                    CustomDropdown(
                                      label: "Primary Classroom",
                                      hintText: 'Select',
                                      items: _selectedAllowedClassroomNames,
                                      selectedItem: _selectedPrimaryClassroomName,
                                      labelStyle: TextStyle(
                                        fontSize: responsive.labelFontSize,
                                        fontFamily: "Manrope",
                                        fontWeight: FontWeight.w400,
                                        color: const Color(0xff573353),
                                      ),
                                      showAsterisk: true,
                                      labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
                                      fieldHeight: responsive.isTablet ? 64.0 : 56.0, // Bigger height
                                      onSelect: (val) {
                                        if (val == null) return;
                                        setState(() {
                                          _selectedPrimaryClassroomName = val;
                                          _primaryClassroomError = null;
                                        });
                                      },
                                    ),
                                    if (_selectedAllowedClassroomNames.isEmpty)
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
                              ],
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: Color(0xff573353),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Note: All classrooms are allowed for admin users',
                                      style: TextStyle(
                                        fontSize: responsive.labelFontSize,
                                        fontFamily: 'Manrope',
                                        color: const Color(0xff573353),
                                        // fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
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
                  child: BlocBuilder<CreateSchoolUserCubit, CreateSchoolUserState>(
                    bloc: _createSchoolUserCubit,
                    builder: (context, state) {
                      return CustomButtonLayout(
                        confirmButtonLabel: widget.isEdit ? 'Save' : 'Add',
                        onPressedConfirm: _addStaff,
                        showCancelButton: false,
                        isForm: false,
                        isLoading: state.isLoading,
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
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