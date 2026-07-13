import 'package:wowcare/core/util/logger_service.dart';
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
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/shared/common/widgets/confirmation_bottom_sheet.dart';
import 'package:wowcare/presentation/features/staff/cubit/create_school_user_cubit.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'dart:convert';
import 'dart:io';
import 'package:wowcare/presentation/features/staff/util/staff_photo_background.dart';

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
  File? _profilePhoto;
  bool get _isAdminSelected => (_selectedRole ?? '').toLowerCase() == 'admin';

  /// True when the *logged-in* user has an admin persona (e.g. SCHOOL_ADMIN / ORGANIZATION_ADMIN).
  /// Used to make classroom fields read-only in edit flow for admin persona users.
  bool _isLoggedInAdminPersona = false;
  Set<String> _loggedInStaffAllowedClassroomCodes = <String>{};

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
  static final RegExp _phoneRegex = RegExp(r'^\(\d{3}\)\s\d{3}-\d{4}$');
  // First/Last name: first character A–Z, then up to 49 characters (letters, space, hyphen, apostrophe).
  static final RegExp _nameRegex = RegExp(r"^[A-Za-z][A-Za-z\-'\s]{0,49}$");
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
      _selectedAllowedClassroomNames = List<String>.from(
        widget.initialAllowedClassroomCodes ?? [],
      );
      _selectedPrimaryClassroomName = widget.initialPrimaryClassroom;
      _selectedStatus = widget.initialStatus;
    }
    // Default role when creating new entry
    _selectedRole ??= widget.initialRole ?? 'Staff';

    _loadClassrooms();
    _loadCurrentPersonaAdminFlag();
  }

  /// Best-effort duplicate-name check run on Save (like the Add Student flow).
  /// Returns true to proceed (no duplicate, or the user chose "Add anyway"),
  /// false to cancel. Never blocks the flow if the lookup fails.
  Future<bool> _confirmIfDuplicateNameExists({
    required String firstName,
    required String lastName,
  }) async {
    if (widget.isEdit) return true;
    if (firstName.isEmpty || lastName.isEmpty) return true;

    try {
      final storage = serviceLocator<StorageService>();
      final org =
          (await storage.getString(StorageKeys.organizationCode) ?? '').trim();
      final school =
          (await storage.getString(StorageKeys.schoolCode) ?? '').trim();
      if (org.isEmpty || school.isEmpty) return true;

      String norm(String s) =>
          s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      final full = '$firstName $lastName';
      final fullNorm = norm(full);

      // Fetch the full staff list and match client-side (mirrors the Add Student
      // duplicate check). Avoids relying on the search param / first-page window.
      final allStaff = await serviceLocator<StaffRepository>().getAllStaff(
        organizationCode: org,
        schoolCode: school,
        size: 500,
      );
      final exists = allStaff.any((m) => norm(m.name) == fullNorm);
      if (!exists) return true;
      if (!mounted) return true;

      // Duplicate found → confirm. "Add" proceeds, close/cancel aborts.
      return await _showStaffExistsDialog(full);
    } catch (e) {
      CoreUtils.logApiError('Staff duplicate check failed: $e');
      return true;
    }
  }

  Future<bool> _showStaffExistsDialog(String name) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return ConfirmationBottomSheet(
          icon: Icons.info_outline_rounded,
          title:
              'A Staff named $name already exists. Do you still want to add this staff?',
          confirmText: 'Add',
          cancelText: 'Cancel',
          onConfirm: () => Navigator.of(ctx).pop(true),
          onCancel: () => Navigator.of(ctx).pop(false),
        );
      },
    );
    return result == true;
  }

  Future<void> _loadCurrentPersonaAdminFlag() async {
    try {
      final storage = serviceLocator<StorageService>();
      // Prefer staffType from profile.
      String staffType = (await storage.getString(StorageKeys.staffType) ?? '')
          .trim()
          .toUpperCase();
      bool isAdmin =
          staffType == 'SCHOOL_ADMIN' || staffType == 'ORGANIZATION_ADMIN';

      // Fallback to roles JSON when staffType is not available.
      if (!isAdmin) {
        final rolesJson = await storage.getString(StorageKeys.roles);
        if (rolesJson != null && rolesJson.isNotEmpty) {
          try {
            final List<dynamic> roles = jsonDecode(rolesJson) as List<dynamic>;
            for (final r in roles) {
              final roleCode = ((r as Map<String, dynamic>)['role'] ?? '')
                  .toString()
                  .toUpperCase();
              if (roleCode == 'SCHOOL_ADMIN' ||
                  roleCode == 'ORGANIZATION_ADMIN') {
                isAdmin = true;
                break;
              }
            }
          } catch (_) {
            // Ignore parsing errors; default to non-admin persona.
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _isLoggedInAdminPersona = isAdmin;
      });
    } catch (_) {
      // If anything fails, default to non-admin persona (fields stay editable).
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

  Future<void> _addStaff() async {
    _trimAllInputs();
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();

    if (firstName.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'First name is required',
        isError: true,
      );
      return;
    }
    if (firstName.length > 50 || !_nameRegex.hasMatch(firstName)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'First name must be letters only and max 50 characters',
        isError: true,
      );
      return;
    }
    if (lastName.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Last name is required',
        isError: true,
      );
      return;
    }
    if (lastName.length > 50 || !_nameRegex.hasMatch(lastName)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Last name must be letters only and max 50 characters',
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
        _allowedClassroomsError =
            'Please select at least one allowed classroom';
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

    if (!_isAdminSelected && _selectedStatus == null) {
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
      if (_selectedDesignation == null ||
          !_adminDesignationOptions.contains(_selectedDesignation)) {
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
      if (_selectedDesignation == null ||
          !_staffDesignationOptions.contains(_selectedDesignation)) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Please select a valid designation',
          isError: true,
        );
        return;
      }
    }

    // firstName / lastName already trimmed and validated above
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
        setState(
          () => _primaryClassroomError = 'Please select a primary classroom',
        );
      }
      CoreUtils.showTopSnackBar(
        context: context,
        message:
            'Could not resolve classroom code. Please refresh the page and try again.',
        isError: true,
      );
      return;
    }
    if (!_isAdminSelected &&
        allowedClassroomCodes.isEmpty &&
        _selectedAllowedClassroomNames.isNotEmpty) {
      setState(
        () => _allowedClassroomsError = 'Could not resolve classroom codes',
      );
      CoreUtils.showTopSnackBar(
        context: context,
        message:
            'Could not resolve classroom codes. Please refresh the page and try again.',
        isError: true,
      );
      return;
    }

    // Duplicate-name check on Save (like Add Student): if a staff with this name
    // exists, confirm before creating. "Add" proceeds; cancel aborts.
    final proceed = await _confirmIfDuplicateNameExists(
      firstName: firstName,
      lastName: lastName,
    );
    if (!proceed || !mounted) return;

    _createSchoolUserCubit.create(
      isAdmin: isAdmin,
      firstName: firstName,
      lastName: lastName,
      displayName: displayName,
      mobile: mobileDigits,
      email: email,
      role: role,
      designation: _mapDesignationToApiValue(_selectedDesignation),
      // Admin: no status UI — backend always receives ACTIVE.
      status: _isAdminSelected ? 'Active' : _selectedStatus,
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
    // Load classrooms via cubit using the classroom-only API
    // (maps to type=CLASSROOM in the backend URL for all roles).
    _classroomCubit!.loadActiveClassrooms(onlyTypeClassroom: true);
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
        if (_classrooms.isNotEmpty && _selectedPrimaryClassroomName == null) {
          _selectedPrimaryClassroomName = _classrooms.first;
        }
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
    AppLogger.d('[Email Validation] raw: "$raw"');
    AppLogger.d('[Email Validation] trimmed: "$trimmed"');
    AppLogger.d(
      '[Email Validation] strict regex: ${_emailRegexStrict.pattern}',
    );
    AppLogger.d(
      '[Email Validation] permissive regex: ${_emailRegexPermissive.pattern}',
    );

    if (trimmed.isEmpty) {
      AppLogger.d('[Email Validation] FAIL: empty');
      return 'Email is required';
    }

    final hasAt = trimmed.contains('@');
    final hasDot =
        trimmed.contains('.') &&
        trimmed.lastIndexOf('.') > trimmed.indexOf('@');
    final strictMatch = _emailRegexStrict.hasMatch(trimmed);
    final permissiveMatch = _emailRegexPermissive.hasMatch(trimmed);
    final matches =
        strictMatch ||
        permissiveMatch ||
        (hasAt && hasDot && trimmed.length >= 6);
    AppLogger.d('[Email Validation] hasAt: $hasAt, hasDotAfterAt: $hasDot');
    AppLogger.d(
      '[Email Validation] strictMatch: $strictMatch, permissiveMatch: $permissiveMatch',
    );
    AppLogger.d('[Email Validation] final hasMatch: $matches');
    if (!matches) {
      // Pinpoint common issues
      if (trimmed.contains(' ')) {
        AppLogger.d('[Email Validation] contains spaces');
      }
      if (!trimmed.contains('@')) {
        AppLogger.d('[Email Validation] missing @');
      }
      if (!trimmed.contains('.')) {
        AppLogger.d('[Email Validation] missing dot in domain');
      }
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePhoneNumber(String? value) {
    final raw = (value ?? '').trim();
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    AppLogger.d('[Phone Validation] raw: "$raw"');
    AppLogger.d('[Phone Validation] digitsOnly: "$digits"');
    AppLogger.d('[Phone Validation] regex: ${_phoneRegex.pattern}');

    if (raw.isEmpty) {
      return 'Phone number is required';
    }
    if (digits.length != 10) {
      AppLogger.d('[Phone Validation] FAIL: digits length = ${digits.length}');
      return 'Please enter a valid 10-digit phone number';
    }
    // Accept either formatted string OR any 10-digit input (formatter will format on type)
    final formattedMatch = _phoneRegex.hasMatch(raw);
    AppLogger.d('[Phone Validation] formattedMatch: $formattedMatch');
    return null; // digits == 10 is sufficient
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;
    final bool isEditAdminReadOnly = widget.isEdit && _isLoggedInAdminPersona;

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
            // Update local caches once classrooms are loaded from cubit.
            // We no longer rely on any prefetched classroom list for this screen.
            if (!classroomState.isLoading &&
                classroomState.classrooms.isNotEmpty &&
                _classrooms.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _updateClassroomsFromCubitState(classroomState);
              });
            } else if (classroomState.errorMessage != null &&
                _classrooms.isEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _updateClassroomsFromCubitState(classroomState);
              });
            }

            return BlocListener<CreateSchoolUserCubit, CreateSchoolUserState>(
              listener: (context, state) {
                if (!mounted) return;

                if (state.errorMessage != null &&
                    state.errorMessage!.isNotEmpty) {
                  CoreUtils.logApiError(state.errorMessage!);
                  CoreUtils.showTopSnackBar(
                    context: context,
                    message: state.errorMessage!,
                    isError: true,
                  );
                  return;
                }

                final result = state.result;
                if (result != null) {
                  final staffName = _composeStaffName();
                  // Prefill from API response so edit profile shows exactly what was saved
                  final u = result.user;
                  // Fire the profile-photo upload in the BACKGROUND (don't block
                  // navigation); it keeps running after this screen is popped.
                  final photo = _profilePhoto;
                  final newStaffCode = (u.staffCode ?? u.userCode).trim();
                  if (photo != null && newStaffCode.isNotEmpty) {
                    unawaited(() async {
                      final storage = serviceLocator<StorageService>();
                      final sc =
                          (await storage.getString(StorageKeys.schoolCode) ??
                                  '')
                              .trim();
                      final oc =
                          (await storage.getString(
                                    StorageKeys.organizationCode,
                                  ) ??
                                  '')
                              .trim();
                      await uploadStaffPhotoInBackground(
                        staffCode: newStaffCode,
                        file: photo,
                        schoolCode: sc,
                        organizationCode: oc,
                      );
                    }());
                  }
                  CoreUtils.showTopSnackBar(
                    context: context,
                    message:
                        (result.message.isNotEmpty
                            ? result.message
                            : 'User created successfully') +
                        (photo != null
                            ? ' Photo is uploading in the background…'
                            : ''),
                    isSuccess: true,
                  );
                  Navigator.pop(context, {
                    'showPostAddPrompt': true,
                    'staffName': staffName,
                    'userCode': u.userCode,
                    'staffCode': u.staffCode ?? u.userCode,
                    'initialFirstName': u.firstName,
                    'initialLastName': u.lastName,
                    'initialEmail': u.email,
                    'initialDesignation': u.designation,
                    'initialPhoneNumber': u.mobile,
                    'initialPrimaryClassroom': _selectedPrimaryClassroomName,
                    'initialAllowedClassrooms': List<String>.from(
                      _selectedAllowedClassroomNames,
                    ),
                    'initialClassroomNames': List<String>.from(_classrooms),
                    'initialClassroomCodeByName': Map<String, String>.from(
                      _classroomCodeByName,
                    ),
                    'initialStatus': u.status ?? _selectedStatus,
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
                              horizontal: responsive.horizontalSpacing,
                            ),
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
                                horizontal: responsive.horizontalSpacing,
                              ),
                              padding: EdgeInsets.all(
                                responsive.isTablet ? 32.0 : 16.0,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.all(
                                  Radius.circular(
                                    responsive.isTablet ? 40.0 : 24.0,
                                  ),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
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
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        border: Border.all(
                                          color: Colors.orange.shade100,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.warning,
                                            color: Colors.orange,
                                          ),
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
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.orange,
                                              size: 20,
                                            ),
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
                                          labelBottomSpacing:
                                              responsive.isTablet ? 8.0 : 6.0,
                                          onSelect: (val) {
                                            if (val == null) return;
                                            setState(() {
                                              _selectedRole = val;
                                              if (_isAdminSelected) {
                                                _selectedAllowedClassroomNames =
                                                    List<String>.from(
                                                      _classrooms,
                                                    );
                                                if (_classrooms.isNotEmpty) {
                                                  _selectedPrimaryClassroomName =
                                                      _classrooms.first;
                                                }
                                              } else {
                                                _selectedAllowedClassroomNames =
                                                    [];
                                                _selectedPrimaryClassroomName =
                                                    null;
                                              }
                                            });
                                            // Reload classrooms for the selected role.
                                            // For both Admin and Staff, use type=CLASSROOM
                                            // so the dropdown is populated only with classrooms.
                                            final classroomCubit = context
                                                .read<ClassroomCubit>();
                                            classroomCubit.loadActiveClassrooms(
                                              force: true,
                                              onlyTypeClassroom: true,
                                            );
                                          },
                                        ),
                                        SizedBox(
                                          height: responsive.verticalSpacing,
                                        ),
                                        _buildRowInputs(
                                          context,
                                          "First Name",
                                          "Last Name",
                                        ),
                                        SizedBox(
                                          height: responsive.verticalSpacing,
                                        ),
                                        _buildInputField(
                                          "Email",
                                          "E.g. name@example.com",
                                          _emailController,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          inputFormatters: [TrimFormatter()],
                                        ),
                                        SizedBox(
                                          height: responsive.verticalSpacing,
                                        ),
                                        _buildInputField(
                                          "Phone Number",
                                          "E.g. (000) 000-0000",
                                          _phoneController,
                                          keyboardType: TextInputType.phone,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                            LengthLimitingTextInputFormatter(
                                              10,
                                            ),
                                            PhoneNumberFormatter(),
                                            TrimFormatter(),
                                          ],
                                        ),
                                        SizedBox(
                                          height: responsive.verticalSpacing,
                                        ),
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
                                          labelBottomSpacing:
                                              responsive.isTablet ? 8.0 : 6.0,
                                          onSelect: (val) => setState(
                                            () => _selectedDesignation =
                                                val ?? _selectedDesignation,
                                          ),
                                        ),
                                        SizedBox(
                                          height: responsive.verticalSpacing,
                                        ),
                                        // Classroom Selection Widget
                                        if (!_isAdminSelected)
                                          Column(
                                            children: [
                                              // Allowed Classrooms
                                              Opacity(
                                                opacity: isEditAdminReadOnly
                                                    ? 0.6
                                                    : 1.0,
                                                child: IgnorePointer(
                                                  ignoring: isEditAdminReadOnly,
                                                  child: ClassroomSelectionWidgetExact(
                                                    primaryClassroom:
                                                        _selectedPrimaryClassroomName,
                                                    allowedClassrooms:
                                                        _selectedAllowedClassroomNames,
                                                    availableClassrooms:
                                                        _classrooms,
                                                    onPrimaryClassroomChanged:
                                                        (classroom) {
                                                          setState(() {
                                                            _selectedPrimaryClassroomName =
                                                                classroom;
                                                            _primaryClassroomError =
                                                                null;
                                                          });
                                                        },
                                                    onAllowedClassroomsChanged: (classrooms) {
                                                      setState(() {
                                                        _selectedAllowedClassroomNames =
                                                            classrooms;
                                                        _allowedClassroomsError =
                                                            null;
                                                        // Clear primary classroom if it's not in allowed classrooms anymore
                                                        if (_selectedPrimaryClassroomName !=
                                                                null &&
                                                            !classrooms.contains(
                                                              _selectedPrimaryClassroomName,
                                                            )) {
                                                          _selectedPrimaryClassroomName =
                                                              null;
                                                        }
                                                      });
                                                    },
                                                    primaryClassroomError:
                                                        _primaryClassroomError,
                                                    allowedClassroomsError:
                                                        _allowedClassroomsError,
                                                    showPrimaryClassroom:
                                                        false, // Hide primary classroom section
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                height:
                                                    responsive.verticalSpacing,
                                              ),
                                              // Primary Classroom Dropdown
                                              Stack(
                                                children: [
                                                  Opacity(
                                                    opacity: isEditAdminReadOnly
                                                        ? 0.6
                                                        : 1.0,
                                                    child: CustomDropdown(
                                                      label:
                                                          "Primary Classroom",
                                                      hintText: 'Select',
                                                      items:
                                                          _selectedAllowedClassroomNames,
                                                      selectedItem:
                                                          _selectedPrimaryClassroomName,
                                                      labelStyle: TextStyle(
                                                        fontSize: responsive
                                                            .labelFontSize,
                                                        fontFamily: "Manrope",
                                                        fontWeight:
                                                            FontWeight.w400,
                                                        color: const Color(
                                                          0xff573353,
                                                        ),
                                                      ),
                                                      showAsterisk: true,
                                                      labelBottomSpacing:
                                                          responsive.isTablet
                                                          ? 8.0
                                                          : 6.0,
                                                      fieldHeight:
                                                          responsive.isTablet
                                                          ? 64.0
                                                          : 56.0, // Bigger height
                                                      onSelect: (val) {
                                                        if (val == null ||
                                                            isEditAdminReadOnly)
                                                          return;
                                                        setState(() {
                                                          _selectedPrimaryClassroomName =
                                                              val;
                                                          _primaryClassroomError =
                                                              null;
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                  if (_selectedAllowedClassroomNames
                                                          .isEmpty &&
                                                      !isEditAdminReadOnly)
                                                    Positioned.fill(
                                                      child: GestureDetector(
                                                        behavior:
                                                            HitTestBehavior
                                                                .opaque,
                                                        onTap: () {
                                                          CoreUtils.showTopSnackBar(
                                                            context: context,
                                                            message:
                                                                'Please select Allowed Classrooms first',
                                                            isError: true,
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  if (isEditAdminReadOnly)
                                                    const Positioned.fill(
                                                      child: IgnorePointer(
                                                        ignoring: false,
                                                        child:
                                                            SizedBox.expand(),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ],
                                          )
                                        else
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 6,
                                            ),
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
                                                      fontSize: responsive
                                                          .labelFontSize,
                                                      fontFamily: 'Manrope',
                                                      color: const Color(
                                                        0xff573353,
                                                      ),
                                                      // fontStyle: FontStyle.italic,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        SizedBox(
                                          height: responsive.verticalSpacing,
                                        ),
                                        if (!_isAdminSelected) ...[
                                          CustomDropdown(
                                            label: "Status",
                                            hintText: 'Select',
                                            items: const ['Active', 'Upcoming'],
                                            selectedItem: _selectedStatus,
                                            labelStyle: TextStyle(
                                              fontSize:
                                                  responsive.labelFontSize,
                                              fontFamily: "Manrope",
                                              fontWeight: FontWeight.w400,
                                              color: const Color(0xff573353),
                                            ),
                                            showAsterisk: true,
                                            labelBottomSpacing:
                                                responsive.isTablet ? 8.0 : 6.0,
                                            onSelect: (val) => setState(
                                              () => _selectedStatus =
                                                  val ?? _selectedStatus,
                                            ),
                                          ),
                                          SizedBox(
                                            height: responsive.verticalSpacing,
                                          ),
                                        ],
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
                      bottom: safeAreaBottom,
                      left: 16,
                      right: 16,
                      top: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          offset: const Offset(0, -4),
                          blurRadius: 16,
                        ),
                      ],
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(
                          responsive.isTablet ? 40.0 : 24.0,
                        ),
                        topRight: Radius.circular(
                          responsive.isTablet ? 40.0 : 24.0,
                        ),
                      ),
                    ),
                    child:
                        BlocBuilder<
                          CreateSchoolUserCubit,
                          CreateSchoolUserState
                        >(
                          bloc: _createSchoolUserCubit,
                          builder: (context, state) {
                            return CustomButtonLayout(
                              confirmButtonLabel: widget.isEdit
                                  ? 'Save'
                                  : 'Add',
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
              FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z\s'-]")),
              LengthLimitingTextInputFormatter(50),
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
              FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z\s'-]")),
              LengthLimitingTextInputFormatter(50),
              NameCapitalizationFormatter(),
              TrimFormatter(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(
    String label,
    String hint,
    TextEditingController controller, {
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    FocusNode? focusNode,
    ValueChanged<String>? onChanged,
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
            borderRadius: BorderRadius.circular(
              responsive.isTablet ? 12.0 : 8.0,
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
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

    // Extract only digits from the new text
    final digitsOnly = newText.replaceAll(RegExp(r'\D'), '');
    final charCount = digitsOnly.length;

    // Build the formatted text from the digits
    String formattedText;
    if (charCount == 0) {
      formattedText = '';
    } else if (charCount <= 3) {
      formattedText = '($digitsOnly';
    } else if (charCount <= 6) {
      formattedText =
          '(${digitsOnly.substring(0, 3)}) ${digitsOnly.substring(3)}';
    } else {
      formattedText =
          '(${digitsOnly.substring(0, 3)}) ${digitsOnly.substring(3, 6)}-${digitsOnly.substring(6)}';
    }

    // Preserve the caret position by:
    // 1. Counting how many digits are before the current caret.
    // 2. Placing the caret after the same number of digits in the formatted text.
    final oldSelectionIndex = newValue.selection.extentOffset.clamp(
      0,
      newText.length,
    );
    final substringBeforeCaret = newText.substring(0, oldSelectionIndex);
    final digitsBeforeCaret = substringBeforeCaret
        .replaceAll(RegExp(r'\D'), '')
        .length;

    int caretIndex = 0;
    int digitCount = 0;
    while (caretIndex < formattedText.length &&
        digitCount < digitsBeforeCaret) {
      if (RegExp(r'\d').hasMatch(formattedText[caretIndex])) {
        digitCount++;
      }
      caretIndex++;
    }

    caretIndex = caretIndex.clamp(0, formattedText.length);

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: caretIndex),
    );
  }
}

class NameCapitalizationFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String original = newValue.text;

    // Normalize spaces: collapse multiple and remove trailing spaces
    String text = original;
    text = text.replaceFirst(RegExp(r"\s+"), ' '); // collapse first occurrence
    text = text.replaceAll(RegExp(r"\s{2,}"), ' ');
    text = text.replaceAll(RegExp(r"\s+\z"), '');

    if (text.isEmpty) {
      return newValue.copyWith(
        text: text,
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    // Enforce first letter uppercase, remaining lowercase
    final firstChar = text[0].toUpperCase();
    final rest = text.length > 1 ? text.substring(1).toLowerCase() : '';
    final formatted = firstChar + rest;

    // Try to preserve caret position relative to the transformation
    final oldOffset = newValue.selection.extentOffset;
    final lengthDelta = formatted.length - original.length;
    final newOffset = (oldOffset + lengthDelta).clamp(0, formatted.length);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }
}

class TrimFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final original = newValue.text;
    final trimmed = original.trimLeft();

    // Number of leading characters removed
    final leadingRemoved = original.length - trimmed.length;

    // Adjust caret to account for removed leading spaces
    final oldOffset = newValue.selection.extentOffset;
    final newOffset = (oldOffset - leadingRemoved).clamp(0, trimmed.length);

    return TextEditingValue(
      text: trimmed,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }
}
