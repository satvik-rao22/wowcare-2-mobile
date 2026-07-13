import 'dart:async';
import 'dart:io';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:flutter/material.dart';
import 'package:wowcare/core/util/file_picker_utils.dart';
import 'package:wowcare/presentation/features/staff/util/staff_photo_background.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'package:wowcare/domain/features/staff/usecases/get_staff_profile_usecase.dart';
import 'package:wowcare/presentation/features/scheduling/utils/scheduling_cache_gate.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/constants/location_constants.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';

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
  static const String routeName = '/dashboard/edit-profile-details-screen';

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
  _EditProfileDetailsScreenState createState() =>
      _EditProfileDetailsScreenState();
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

  ClassroomCubit? _classroomCubit;

  String? _selectedStatus;
  String? _selectedDesignation;
  List<String> _selectedAllowedClassrooms = [];
  String? _selectedPrimaryClassroom;
  DateTime? _selectedBirthDate;
  String? _selectedJobTag;
  // Gender is not needed for this form (per product requirement).
  // String? _selectedGender;
  String? _selectedState;
  String? _selectedCountry;
  bool _isSubmitting = false;
  File? _profilePhoto;
  String _originalEmail = '';
  String _profileUserCode = '';
  String _profileOrganizationCode = '';
  String _profileSchoolCode = '';

  static const List<String> _staffStatusOptions = [
    'Active',
    'Inactive',
    'Upcoming',
  ];
  static const List<String> _adminStatusOptions = ['Active', 'Inactive'];
  // Full designation list (union of admin + staff) for mapping helpers.
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
  // Admin-only designations (used when role is admin).
  static const List<String> _adminDesignationOptions = [
    'Director',
    'Admin',
    'Assistant Director',
    'Owner',
  ];
  // Staff-only designations (used when role is staff).
  static const List<String> _staffDesignationOptions = [
    'Lead teacher',
    'Associate Teacher',
    'Assistant teacher',
    'Floater',
  ];
  // Backed by classroom names; populated from widget.initialClassroomNames/CodeByName.
  final List<String> _classroomOptions = [];
  final List<String> _jobTagOptions = ['Full Time', 'Part Time'];
  // Gender is not needed for this form (per product requirement).
  // final List<String> _genderOptions = ['Male', 'Female'];
  final List<String> _stateOptions = US_STATES
      .map((s) => s.name)
      .toList(growable: false);
  // Country is fixed to United States for this screen; no need to build a dropdown list.

  late final GetStaffProfileUseCase _getStaffProfileUseCase;

  // Simple validators (align with Add Staff)
  // First character A–Z, then up to 49 characters (letters, space, hyphen, apostrophe).
  static final RegExp _nameRegex = RegExp(r"^[A-Za-z][A-Za-z\-'\s]{0,49}$");
  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');
  static final RegExp _e164Regex = RegExp(r'^\+?[1-9]\d{7,14}$');

  /// Map from classroom display name -> classroom code (for API payload).
  final Map<String, String> _classroomCodeByName = {};

  /// Admin designations share the "admin" classroom behavior (no type filter).
  bool get _isAdminSelected {
    const adminDesignations = <String>[
      'Director',
      'Admin',
      'Assistant Director',
      'Owner',
    ];
    return _selectedDesignation != null &&
        adminDesignations.contains(_selectedDesignation);
  }

  /// Staff: Active / Inactive / Upcoming. Admin: no Upcoming option.
  List<String> get _statusOptionsForCurrentRole =>
      _isAdminSelected ? _adminStatusOptions : _staffStatusOptions;

  @override
  void initState() {
    super.initState();
    _getStaffProfileUseCase = serviceLocator<GetStaffProfileUseCase>();
    _classroomCubit = serviceLocator<ClassroomCubit>();

    // Country is fixed to United States for staff address in this form.
    // Keep it prefilled and non-editable.
    _selectedCountry = 'United States';

    // Hydrate classrooms from cached metadata if available (before cubit load).
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

    // Prefill selected classrooms from navigation args immediately.
    // (These are display names when available; if they are codes we will
    // normalize them once classroom metadata loads.)
    _selectedAllowedClassrooms = List<String>.from(
      widget.initialAllowedClassrooms ?? const <String>[],
    );
    _selectedPrimaryClassroom = widget.initialPrimaryClassroom;

    // Load classrooms via cubit using role-aware filter:
    // - Staff: type=CLASSROOM (onlyTypeClassroom=true)
    // - Admin: all active locations (onlyTypeClassroom=false)
    _loadClassrooms();

    // All fields are prefilled from GET /api/v1/staff/{staffCode}/profile (see _loadProfileForPrefill).
    if (widget.staffCode.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _loadProfileForPrefill(),
      );
    }
  }

  Future<void> _loadClassrooms({bool force = false}) async {
    final isAdmin = _isAdminSelected;
    _classroomCubit?.loadActiveClassrooms(
      force: force,
      // Staff: type=CLASSROOM; Admin: no type filter.
      onlyTypeClassroom: !isAdmin,
    );
  }

  void _updateClassroomsFromCubitState(ClassroomState state) {
    if (state.classrooms.isEmpty) {
      if (state.errorMessage != null) {
        CoreUtils.logApiError(state.errorMessage!);
      }
      return;
    }

    final names = state.classrooms.map((c) => c.name).toList();
    final codeByName = <String, String>{};
    for (final c in state.classrooms) {
      codeByName[c.name] = c.code;
    }
    // Build reverse map (code -> name) so we can normalize selections
    // even when initial values were passed as codes.
    final nameByCode = <String, String>{
      for (final e in codeByName.entries) e.value: e.key,
    };

    setState(() {
      _classroomOptions
        ..clear()
        ..addAll(names);
      _classroomCodeByName
        ..clear()
        ..addAll(codeByName);

      // Normalize selected allowed classrooms:
      // If an entry looks like a code and we can resolve it, replace with name.
      if (_selectedAllowedClassrooms.isNotEmpty) {
        _selectedAllowedClassrooms = _selectedAllowedClassrooms
            .map((v) => nameByCode[v] ?? v)
            .where((v) => v.trim().isNotEmpty)
            .toList();
      }

      // Normalize selected primary classroom.
      if ((_selectedPrimaryClassroom ?? '').trim().isNotEmpty) {
        _selectedPrimaryClassroom =
            nameByCode[_selectedPrimaryClassroom!] ?? _selectedPrimaryClassroom;
      }
    });
  }

  String _statusApiToLabel(String? status) {
    if (status == null) return 'Active';
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return 'Active';
      case 'INACTIVE':
        return 'Inactive';
      case 'UPCOMING':
        return 'Upcoming';
      default:
        return status;
    }
  }

  Future<void> _loadProfileForPrefill() async {
    if (!mounted) return;
    try {
      final profile = await _getStaffProfileUseCase(
        staffCode: widget.staffCode,
      );
      if (!mounted) return;
      final codeToName = {
        for (final e in _classroomCodeByName.entries) e.value: e.key,
      };
      final hasCodeToName = codeToName.isNotEmpty;
      final a = profile.address;
      setState(() {
        _firstNameController.text = profile.firstName;
        _lastNameController.text = profile.lastName;
        _emailController.text = profile.email;
        _originalEmail = profile.email.trim().toLowerCase();
        _profileUserCode = profile.userCode.trim();
        _profileOrganizationCode = profile.organizationCode.trim();
        _profileSchoolCode = profile.schoolCode.trim();
        _phoneNumberController.text = _formatUsPhone(profile.phoneNumber);
        _selectedDesignation = _mapDesignationFromApiOrLabel(
          profile.designation,
        );
        _selectedStatus = _statusApiToLabel(profile.status);
        // Admin roles cannot be Upcoming — normalize to Active if API returned it.
        if (_isAdminSelected && _selectedStatus == 'Upcoming') {
          _selectedStatus = 'Active';
        }

        // Derive allowed classrooms display names:
        // 1) Prefer mapping from code -> name using cached metadata.
        // 2) Fallback to already-passed initialAllowedClassrooms when mapping is missing.
        final mappedAllowed = hasCodeToName
            ? profile.allowedClassroomCodes
                  .map((c) => codeToName[c] ?? c)
                  .toList()
            : const <String>[];
        if (mappedAllowed.isNotEmpty) {
          _selectedAllowedClassrooms = mappedAllowed;
        } else if (widget.initialAllowedClassrooms != null &&
            widget.initialAllowedClassrooms!.isNotEmpty) {
          _selectedAllowedClassrooms = List<String>.from(
            widget.initialAllowedClassrooms!,
          );
        } else {
          _selectedAllowedClassrooms = const <String>[];
        }

        // Derive primary classroom display name:
        // 1) Prefer mapping from primaryClassroomCode using cached metadata.
        // 2) Fallback to initialPrimaryClassroom passed into the screen.
        if (profile.primaryClassroomCode.isNotEmpty && hasCodeToName) {
          _selectedPrimaryClassroom =
              codeToName[profile.primaryClassroomCode] ??
              profile.primaryClassroomCode;
        } else {
          _selectedPrimaryClassroom = widget.initialPrimaryClassroom;
        }

        // Ensure dropdown options contain any preselected values.
        if (_classroomOptions.isEmpty) {
          _classroomOptions.addAll(
            Set<String>.from(_selectedAllowedClassrooms).toList(),
          );
        }
        if (_selectedPrimaryClassroom != null &&
            _selectedPrimaryClassroom!.isNotEmpty &&
            !_classroomOptions.contains(_selectedPrimaryClassroom)) {
          _classroomOptions.add(_selectedPrimaryClassroom!);
        }

        _selectedBirthDate = profile.birthDate.isEmpty
            ? null
            : DateTime.tryParse(profile.birthDate);
        _selectedJobTag = profile.jobTag.isEmpty
            ? null
            : _mapJobTagFromApiOrLabel(profile.jobTag);
        // Gender is currently not included in StaffProfileModel; keep null for now.

        _streetController.text = a.street;
        _street2Controller.text = a.line2;
        _cityController.text = a.city;
        _zipCodeController.text = _formatUsZipForDisplay(a.zipCode);
        if (a.state.isNotEmpty) {
          final match = US_STATES.firstWhere(
            (s) =>
                s.name.toLowerCase() == a.state.toLowerCase() ||
                s.abbreviation.toLowerCase() == a.state.toLowerCase(),
            orElse: () => US_STATES.first,
          );
          _selectedState = match.name;
        }

        // Country is fixed to United States for this screen; ignore API value.
        _selectedCountry = 'United States';
      });
    } catch (_) {
      // Ignore; form stays empty
    }
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
    // Do not close _classroomCubit here; it may be provided higher in the tree.
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    try {
      final picked = await FilePickerUtils.pickFile(
        allowedExtensions: FilePickerUtils.allowedImageExtensions,
        context: context,
      );
      final path = picked?.path;
      if (path == null || path.isEmpty) return;
      final file = File(path);
      final fileSizeInMB = await file.length() / (1024 * 1024);
      if (fileSizeInMB > 10) {
        if (!mounted) return;
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Image size must be less than 10MB',
          isError: true,
        );
        return;
      }
      setState(() => _profilePhoto = file);
    } catch (e) {
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Failed to pick image: $e',
        isError: true,
      );
    }
  }

  Widget _buildStaffPhotoField(ResponsiveHelper responsive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile Photo',
          style: TextStyle(
            fontSize: responsive.labelFontSize,
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w400,
            color: const Color(0xff573353),
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        GestureDetector(
          onTap: _pickProfileImage,
          child: Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x66573353)),
            ),
            child: _profilePhoto != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_profilePhoto!, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        color: Colors.grey.shade600,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload Photo',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'JPG, PNG, max 10MB (Optional)',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontFamily: 'Manrope',
          ),
        ),
      ],
    );
  }

  Future<void> _saveProfileDetails() async {
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    final email = _emailController.text.trim().toLowerCase();
    final phoneRaw = _phoneNumberController.text.trim();
    final phoneDigits = phoneRaw.replaceAll(RegExp(r'\D'), '');
    final street = _streetController.text.trim();
    final city = _cityController.text.trim();
    final zip = _zipCodeController.text.trim();
    final zipDigits = zip.replaceAll(RegExp(r'\D'), '');

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
    if (!_isAdminSelected) {
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
    if (phoneDigits.length != 10 || !_e164Regex.hasMatch('+' + phoneDigits)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please enter a valid 10-digit phone number',
        isError: true,
      );
      return;
    }
    // Address - Street: required, max 150 chars.
    if (street.isEmpty) {
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

    // Address - City: required, max 50 chars.
    if (city.isEmpty) {
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

    // Address - Zip: required, US ZIP format: 5 digits or ZIP+4 (9 digits).
    if (zip.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Zip Code is required',
        isError: true,
      );
      return;
    }
    // Validate using digits-only (formatter may insert a hyphen).
    if (!RegExp(r'^\d{5}(\d{4})?$').hasMatch(zipDigits)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Zip Code must be 5 digits (12345) or ZIP+4 (12345-6789)',
        isError: true,
      );
      return;
    }

    // Address - State / Country: required dropdowns.
    if ((_selectedState ?? '').trim().isEmpty) {
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

    setState(() {
      _isSubmitting = true;
    });

    try {
      final statusApi = _mapStatusToApiValue(_selectedStatus!);
      final designationApi = _mapDesignationToApiValue(_selectedDesignation);
      final jobTagApi = _selectedJobTag == null
          ? null
          : _mapJobTagToApiValue(_selectedJobTag!);
      // Backend contract uses `birthdate` (lowercase) and expects ISO timestamp.
      final birthDateApi = _selectedBirthDate == null
          ? null
          : _selectedBirthDate!.toIso8601String();
      // Gender is not collected in this form (per product requirement).

      final primaryClassroomCode = _selectedPrimaryClassroom == null
          ? null
          : (_classroomCodeByName[_selectedPrimaryClassroom!] ??
                _selectedPrimaryClassroom);
      final allowedClassroomCodes = _selectedAllowedClassrooms
          .map((name) => _classroomCodeByName[name] ?? name)
          .toList();

      // Classrooms are updated via dedicated /staff-classrooms endpoints below;
      // the /profile endpoint ignores them, so we don't send them here.
      final profilePayload = <String, dynamic>{
        'firstName': first,
        'lastName': last,
        'status': statusApi,
        'phoneNumber': phoneDigits,
        'designation': designationApi,
        if (jobTagApi != null) 'jobTag': jobTagApi,
        if (birthDateApi != null) 'birthdate': birthDateApi,
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
        // Send digits-only to backend for consistent storage.
        'addressZipCode': zipDigits,
        'addressCountry': countryCode,
      };

      final repository = serviceLocator<StaffRepository>();

      // If email changed, call email-change API first (same behavior as EditUserProfileScreen).
      final newEmail = email.trim().toLowerCase();
      if (_profileUserCode.isNotEmpty &&
          _profileOrganizationCode.isNotEmpty &&
          _profileSchoolCode.isNotEmpty &&
          _originalEmail.isNotEmpty &&
          _originalEmail != newEmail) {
        await repository.changeUserEmail(
          userCode: _profileUserCode,
          oldEmail: _originalEmail,
          newEmail: newEmail,
          organizationCode: _profileOrganizationCode,
          schoolCode: _profileSchoolCode,
        );
      }

      // Update core profile fields
      final profileMessage = await repository.updateStaffProfile(
        staffCode: widget.staffCode,
        fields: profilePayload,
      );

      // Classrooms have dedicated endpoints (the /profile PATCH ignores them).
      // Update allowed classrooms first so the primary is valid within the set,
      // then update the primary classroom.
      if (allowedClassroomCodes.isNotEmpty) {
        await repository.updateStaffAllowedClassrooms(
          staffCode: widget.staffCode,
          classroomCodes: allowedClassroomCodes,
        );
      }
      if (primaryClassroomCode != null && primaryClassroomCode.isNotEmpty) {
        await repository.updateStaffPrimaryClassroom(
          staffCode: widget.staffCode,
          classroomCode: primaryClassroomCode,
        );
      }

      // Then update address via dedicated endpoint
      final addressMessage = await repository.updateStaffAddress(
        staffCode: widget.staffCode,
        fields: addressPayload,
      );

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });

      // Profile mutation — poke the scheduling screens so they silently
      // re-pull the staff list on the next visit.
      SchedulingCacheGate.invalidate();

      // Upload the picked photo in the BACKGROUND so saving returns instantly;
      // it keeps running even after this screen is popped.
      final photo = _profilePhoto;
      if (photo != null && widget.staffCode.trim().isNotEmpty) {
        unawaited(
          uploadStaffPhotoInBackground(
            staffCode: widget.staffCode.trim(),
            file: photo,
            schoolCode: _profileSchoolCode,
            organizationCode: _profileOrganizationCode,
          ),
        );
      }

      CoreUtils.showTopSnackBar(
        context: context,
        message:
            (addressMessage.isNotEmpty ? addressMessage : profileMessage) +
            (photo != null ? ' Photo is uploading in the background…' : ''),
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
    // If it's already a friendly label from dropdown (admin or staff), just return it.
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
        final selectedDate = result['date'] as DateTime;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        // Birthdate must be a past date (not today or future)
        if (selectedDate.isAfter(today.subtract(const Duration(days: 1)))) {
          CoreUtils.showTopSnackBar(
            context: context,
            message: 'Birthdate must be a past date',
            isError: true,
          );
          return;
        }

        setState(() {
          _selectedBirthDate = selectedDate;
        });
      }
    } catch (e) {
      AppLogger.d('Error opening calendar dialog: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;

    // Get ClassroomCubit from context if available, otherwise use the one from service locator.
    ClassroomCubit classroomCubit;
    try {
      classroomCubit = context.read<ClassroomCubit>();
    } catch (_) {
      classroomCubit = _classroomCubit ?? serviceLocator<ClassroomCubit>();
      _classroomCubit = classroomCubit;
    }

    return BlocProvider<ClassroomCubit>.value(
      value: classroomCubit,
      child: BlocBuilder<ClassroomCubit, ClassroomState>(
        builder: (context, classroomState) {
          final desiredOnlyTypeClassroom = !_isAdminSelected;

          // If cubit is loaded with the wrong filter for current role,
          // trigger a reload with correct onlyTypeClassroom.
          if (!classroomState.isLoading &&
              classroomState.classrooms.isNotEmpty &&
              classroomState.onlyTypeClassroom != desiredOnlyTypeClassroom) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadClassrooms(force: true);
            });
          } else if (!classroomState.isLoading &&
              classroomState.classrooms.isNotEmpty &&
              classroomState.onlyTypeClassroom == desiredOnlyTypeClassroom) {
            // Sync local options from correctly-filtered cubit state.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _updateClassroomsFromCubitState(classroomState);
            });
          }

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
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive.horizontalSpacing,
                        ),
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
                          child: ListView(
                            padding: EdgeInsets.zero,
                            children: [
                              _buildStaffPhotoField(responsive),
                              SizedBox(
                                height: responsive.isTablet ? 24.0 : 16.0,
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInputField(
                                      "First Name",
                                      "E.g. John",
                                      _firstNameController,
                                    ),
                                  ),
                                  SizedBox(
                                    width: responsive.isTablet ? 24.0 : 16.0,
                                  ),
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
                              // Gender is not needed for this form (per product requirement).
                              // _buildCustomDropdown(
                              //   "Gender",
                              //   "Select",
                              //   _genderOptions,
                              //   _selectedGender,
                              //   (v) => setState(() => _selectedGender = v),
                              //   isRequired: false,
                              // ),
                              // SizedBox(height: responsive.verticalSpacing),
                              _buildCustomDropdown(
                                "Status",
                                "Select",
                                _statusOptionsForCurrentRole,
                                _selectedStatus,
                                (v) => setState(() => _selectedStatus = v),
                                isRequired: true,
                              ),
                              SizedBox(height: responsive.verticalSpacing),
                              _buildCustomDropdown(
                                "Designation",
                                "Select",
                                // Show only admin or staff designations based on current role.
                                _isAdminSelected
                                    ? _adminDesignationOptions
                                    : _staffDesignationOptions,
                                _selectedDesignation,
                                (v) {
                                  setState(() {
                                    _selectedDesignation = v;
                                    // Upcoming is not valid for admin designations.
                                    if (_isAdminSelected &&
                                        _selectedStatus == 'Upcoming') {
                                      _selectedStatus = 'Active';
                                    }
                                  });
                                  // Reload classrooms when switching between admin/staff
                                  // so we use the correct API (with or without type filter).
                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    _loadClassrooms(force: true);
                                  });
                                },
                                isRequired: true,
                              ),
                              SizedBox(height: responsive.verticalSpacing),

                              // Allowed / Primary Classroom section (same view for staff & admin).
                              // For admin roles: disabled (greyish), values visible but not editable.
                              Opacity(
                                opacity: _isAdminSelected ? 0.7 : 1.0,
                                child: IgnorePointer(
                                  ignoring: _isAdminSelected,
                                  child: ClassroomSelectionWidgetExact(
                                    primaryClassroom: _selectedPrimaryClassroom,
                                    allowedClassrooms:
                                        _selectedAllowedClassrooms,
                                    availableClassrooms: _classroomOptions,
                                    onPrimaryClassroomChanged: (classroom) {
                                      setState(() {
                                        _selectedPrimaryClassroom = classroom;
                                      });
                                    },
                                    onAllowedClassroomsChanged: (classrooms) {
                                      setState(() {
                                        _selectedAllowedClassrooms = classrooms;
                                        if (_selectedPrimaryClassroom != null &&
                                            !classrooms.contains(
                                              _selectedPrimaryClassroom,
                                            )) {
                                          _selectedPrimaryClassroom = null;
                                        }
                                      });
                                    },
                                    primaryClassroomError: null,
                                    allowedClassroomsError: null,
                                    showPrimaryClassroom: false,
                                  ),
                                ),
                              ),
                              SizedBox(height: responsive.verticalSpacing),
                              // Primary Classroom Dropdown (disabled for admin roles)
                              Stack(
                                children: [
                                  Opacity(
                                    opacity: 1.0,
                                    child: CustomDropdown(
                                      label: "Primary Classroom",
                                      hintText: 'Select',
                                      items: _selectedAllowedClassrooms.isEmpty
                                          ? []
                                          : _selectedAllowedClassrooms,
                                      selectedItem: _selectedPrimaryClassroom,
                                      isEnabled: true,
                                      labelStyle: TextStyle(
                                        fontSize: responsive.labelFontSize,
                                        fontFamily: "Manrope",
                                        fontWeight: FontWeight.w400,
                                        color: const Color(0xff573353),
                                      ),
                                      showAsterisk: !_isAdminSelected,
                                      labelBottomSpacing: responsive.isTablet
                                          ? 8.0
                                          : 6.0,
                                      fieldHeight: responsive.isTablet
                                          ? 64.0
                                          : 56.0,
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
                                        horizontal: responsive.isTablet
                                            ? 16.0
                                            : 12.0,
                                        vertical: responsive.isTablet
                                            ? 16.0
                                            : 12.0,
                                      ),
                                      onSelect: (val) => setState(
                                        () => _selectedPrimaryClassroom = val,
                                      ),
                                    ),
                                  ),
                                  if (_selectedAllowedClassrooms.isEmpty &&
                                      !_isAdminSelected)
                                    Positioned.fill(
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
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
                                ],
                              ),
                              SizedBox(height: responsive.verticalSpacing),

                              _buildDateField("Birthdate", _selectedBirthDate),
                              SizedBox(height: responsive.verticalSpacing),
                              _buildCustomDropdown(
                                "Job Tag",
                                "Select",
                                _jobTagOptions,
                                _selectedJobTag,
                                (v) => setState(() => _selectedJobTag = v),
                              ),
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
                              _buildCustomDropdown(
                                "State",
                                "Select",
                                _stateOptions,
                                _selectedState,
                                (v) => setState(() => _selectedState = v),
                                isRequired: true,
                              ),
                              SizedBox(height: responsive.verticalSpacing),
                              // Country is fixed to United States; show as non-editable.
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
                                    fontSize: responsive.labelFontSize,
                                    fontFamily: "Manrope",
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xff573353),
                                  ),
                                  selectedTextStyle: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: responsive.inputFontSize,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                    height: 19 / 14,
                                  ),
                                  popupItemTextStyle: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: responsive.inputFontSize,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xff573353),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: responsive.isTablet
                                        ? 16.0
                                        : 12.0,
                                    vertical: responsive.isTablet ? 16.0 : 12.0,
                                  ),
                                  onSelect: null,
                                ),
                              ),
                              SizedBox(height: responsive.verticalSpacing),
                              _buildInputField(
                                "Zip Code",
                                "E.g. 12345 or 12345-6789",
                                _zipCodeController,
                                isRequired: true,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  // Limit to 9 digits; formatter will render it as either 12345 or 12345-6789.
                                  LengthLimitingTextInputFormatter(9),
                                  _ZipCodeFormatter(),
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
                      color: Colors.black.withValues(alpha: 0.05),
                      offset: const Offset(0, -4),
                      blurRadius: 16,
                    ),
                  ],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(responsive.isTablet ? 40.0 : 24.0),
                    topRight: Radius.circular(
                      responsive.isTablet ? 40.0 : 24.0,
                    ),
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
        },
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
              if (isRequired)
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
              borderRadius: BorderRadius.circular(
                responsive.isTablet ? 12.0 : 8.0,
              ),
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
                        fontWeight: selectedDate != null
                            ? FontWeight.w600
                            : FontWeight.w500,
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
                    colorFilter: const ColorFilter.mode(
                      AppColors.primaryColor,
                      BlendMode.srcIn,
                    ),
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

/// Formats US ZIP codes as either:
/// - 12345
/// - 12345-6789
/// while keeping only digits for validation/API submission.
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
