import 'dart:async';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'dart:io';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:flutter/material.dart';
import 'package:wowcare/core/utils/file_utils/file_picker_utils.dart';
import 'package:flutter/services.dart';
import 'package:wowcare/presentation/features/staff/view/edit_profile_details_screen_formatters.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/shared/common/widgets/classroom_selection_widget_exact.dart';
import 'package:wowcare/domain/features/staff/entities/staff_profile_update.dart';
import 'package:wowcare/domain/features/staff/entities/staff_address_update.dart';
import 'package:wowcare/presentation/features/staff/view_model/staff_profile_edit_cubit.dart';
import 'package:wowcare/core/events/scheduling_events.dart';
import 'package:wowcare/presentation/features/classroom/view/classroom_tab_cards/classroom_staff_tab_card.dart'
    show notifyClassroomStaffChanged;
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/constants/location_constants.dart';
import 'package:wowcare/presentation/features/classroom/view_model/classroom_cubit.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/core/theme/app_icon.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/shared/common/widgets/bottom_action_bar.dart';

class EditProfileDetailsScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // Cubits are created by the route builder (§1.6), not here.
    return _EditProfileDetailsScreenView(
      staffCode: staffCode,
      initialFirstName: initialFirstName,
      initialLastName: initialLastName,
      initialStatus: initialStatus,
      initialDesignation: initialDesignation,
      initialAllowedClassrooms: initialAllowedClassrooms,
      initialPrimaryClassroom: initialPrimaryClassroom,
      initialBirthDate: initialBirthDate,
      initialJobTag: initialJobTag,
      initialEmail: initialEmail,
      initialPhoneNumber: initialPhoneNumber,
      initialStreet: initialStreet,
      initialCity: initialCity,
      initialState: initialState,
      initialCountry: initialCountry,
      initialZipCode: initialZipCode,
      initialClassroomNames: initialClassroomNames,
      initialClassroomCodeByName: initialClassroomCodeByName,
    );
  }
}

class _EditProfileDetailsScreenView extends StatefulWidget {
  const _EditProfileDetailsScreenView({
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
  final List<String>? initialClassroomNames;
  final Map<String, String>? initialClassroomCodeByName;

  @override
  State<_EditProfileDetailsScreenView> createState() =>
      _EditProfileDetailsScreenViewState();
}

class _EditProfileDetailsScreenViewState
    extends State<_EditProfileDetailsScreenView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _street2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();

  late final ClassroomCubit _classroomCubit;

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
  final ValueNotifier<bool> _isSubmitting = ValueNotifier<bool>(false);
  File? _profilePhoto;
  String _originalEmail = '';
  String _profileUserCode = '';
  String _profileOrganizationCode = '';
  String _profileSchoolCode = '';
  String _profileStaffType = '';

  /// Raw API status (`ACTIVE`/`INACTIVE`/`UPCOMING`) as loaded, before any
  /// edits — compared against the newly-selected status at save time so the
  /// activate/deactivate side-effect API only fires on a real Active<->
  /// Inactive transition, not on every save. See _saveProfileDetails.
  String _originalStatusApi = '';

  /// Name/phone/address as loaded, before any edits — this form always
  /// resubmits every field on save (no per-field dirty tracking), so the
  /// /profile PATCH's generic success message can't by itself tell "only
  /// email changed" apart from "other fields changed too". Compared against
  /// the submitted values at save time; see _saveProfileDetails' message
  /// composition.
  String _originalFirstName = '';
  String _originalLastName = '';
  String _originalPhoneDigits = '';
  String _originalAddressStreet = '';
  String _originalAddressLine2 = '';
  String _originalAddressCity = '';
  String _originalAddressState = '';
  String _originalAddressZipDigits = '';

  static const List<String> _staffStatusOptions = [
    'Active',
    'Inactive',
    'Upcoming',
  ];
  static const List<String> _adminStatusOptions = ['Active', 'Inactive'];

  /// Shown on a successful email change instead of the raw email-change API
  /// response text — matches the web app's "Verification Email Sent" banner
  /// copy so both clients tell the user the same thing in the same words.
  static const String _emailVerificationSentMessage =
      'A verification email has been sent to your new email address.';
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

  late final StaffProfileEditCubit _profileEditCubit;

  // Simple validators (align with Add Staff)
  // First character A–Z, then up to 49 characters (letters, space, hyphen, apostrophe).
  static final RegExp _nameRegex = RegExp(r"^[A-Za-z][A-Za-z\-'\s]{0,49}$");
  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

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
    _profileEditCubit = context.read<StaffProfileEditCubit>();
    _classroomCubit = context.read<ClassroomCubit>();

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
    _classroomCubit.loadActiveClassrooms(
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
      final profile = await _profileEditCubit.loadProfileForPrefill(
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
        _originalFirstName = profile.firstName.trim().toLowerCase();
        _originalLastName = profile.lastName.trim().toLowerCase();
        _originalPhoneDigits = profile.phoneNumber.replaceAll(
          RegExp(r'\D'),
          '',
        );
        _emailController.text = profile.email;
        _originalEmail = profile.email.trim().toLowerCase();
        _profileUserCode = profile.userCode.trim();
        _profileOrganizationCode = profile.organizationCode.trim();
        _profileSchoolCode = profile.schoolCode.trim();
        _profileStaffType = profile.staffType.trim();
        _originalStatusApi = profile.status.trim().toUpperCase();
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
        _zipCodeController.text = formatUsZipForDisplay(a.zipCode);
        _originalAddressStreet = a.street.trim().toLowerCase();
        _originalAddressLine2 = a.line2.trim().toLowerCase();
        _originalAddressCity = a.city.trim().toLowerCase();
        _originalAddressZipDigits = a.zipCode.replaceAll(RegExp(r'\D'), '');
        if (a.state.isNotEmpty) {
          final match = US_STATES.firstWhere(
            (s) =>
                s.name.toLowerCase() == a.state.toLowerCase() ||
                s.abbreviation.toLowerCase() == a.state.toLowerCase(),
            orElse: () => US_STATES.first,
          );
          _selectedState = match.name;
          // Captured as the same display-name form _selectedState holds, so
          // the save-time comparison isn't comparing a full name against an
          // abbreviation (a.state's raw form can be either).
          _originalAddressState = match.name.toLowerCase();
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
    _isSubmitting.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    try {
      final picked = await FilePickerUtils.pickFile(
        allowedExtensions: FilePickerUtils.allowedImageExtensions,
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
      if (!mounted) return;
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
            fontFamily: AppFonts.body,
            fontWeight: FontWeight.w400,
            color: AppColors.primaryColor,
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        GestureDetector(
          onTap: _pickProfileImage,
          child: Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              color: AppColors.billingGreyLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.inputBorderColor),
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
                        color: AppColors.attendanceDialogHintTextColor,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload Photo',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.attendanceDialogHintTextColor,
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
            color: AppColors.attendanceDialogHintTextColor,
            fontFamily: AppFonts.body,
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
    // Only the 10-digit check matters here — the E.164 check this used to
    // also run (requiring the first digit to be 1-9) rejected genuinely
    // valid 10-digit numbers that start with 0 (see the matching fix in
    // EditUserProfileScreen for the same bug on the "My Profile" screen).
    if (phoneDigits.length != 10) {
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

    _isSubmitting.value = true;

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
      final profilePayload = StaffProfileUpdate(
        firstName: first,
        lastName: last,
        status: statusApi,
        phoneNumber: phoneDigits,
        designation: designationApi,
        jobTag: jobTagApi,
        birthdate: birthDateApi,
      );

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

      final addressPayload = StaffAddressUpdate(
        addressStreet: _streetController.text.trim(),
        addressLine2: _street2Controller.text.trim(),
        addressCity: _cityController.text.trim(),
        addressState: stateCode,
        // Send digits-only to backend for consistent storage.
        addressZipCode: zipDigits,
        addressCountry: countryCode,
      );

      // If email changed, call email-change API first (same behavior as
      // EditUserProfileScreen/EditUserProfileCubit). Its own response
      // `message` (e.g. "verification email sent to the new address") is
      // captured and preferred over the unrelated address/profile message
      // below — and, unlike the rest of this save, a failure here is caught
      // locally rather than aborting the whole save: an email failure alone
      // must not also block the classroom/address/activation updates that
      // follow, and the user must see the ACTUAL backend error for the
      // email specifically, not a generic one from whatever step happened
      // to fail next.
      String? emailChangeMessage;
      bool emailChangeFailed = false;
      final newEmail = email.trim().toLowerCase();
      final emailChanged =
          _profileUserCode.isNotEmpty &&
          _profileOrganizationCode.isNotEmpty &&
          _profileSchoolCode.isNotEmpty &&
          _originalEmail.isNotEmpty &&
          _originalEmail != newEmail;
      if (emailChanged) {
        try {
          await _profileEditCubit.changeUserEmail(
            userCode: _profileUserCode,
            oldEmail: _originalEmail,
            newEmail: newEmail,
            organizationCode: _profileOrganizationCode,
            schoolCode: _profileSchoolCode,
          );
          emailChangeMessage = _emailVerificationSentMessage;
        } catch (e) {
          emailChangeFailed = true;
          emailChangeMessage = ApiErrorHandler.extractErrorMessage(e);
        }
      }

      // Update core profile fields
      final profileMessage = await _profileEditCubit.updateProfile(
        staffCode: widget.staffCode,
        fields: profilePayload,
      );

      // Activate/deactivate is a SEPARATE backend action from the /profile
      // PATCH above (it toggles system login access, not just the status
      // field) — fire it only on an actual Active<->Inactive transition, not
      // on every save (e.g. Upcoming->Active, or an unrelated field edit
      // with status left unchanged must NOT call this). Mirrors
      // StaffCubit.activateStaff/deactivateStaff's own org-admin-vs-school-
      // user + role resolution exactly, since those hit the same endpoints.
      final becameActive =
          _originalStatusApi == 'INACTIVE' && statusApi == 'ACTIVE';
      final becameInactive =
          _originalStatusApi == 'ACTIVE' && statusApi == 'INACTIVE';
      if ((becameActive || becameInactive) &&
          _profileUserCode.isNotEmpty &&
          _profileOrganizationCode.isNotEmpty) {
        final staffTypeUpper = _profileStaffType.toUpperCase().trim();
        final bool isOrganizationAdmin =
            staffTypeUpper.contains('ORGANIZATION') &&
            staffTypeUpper.contains('ADMIN');
        final bool schoolCodeMissing =
            _profileSchoolCode.isEmpty || _profileSchoolCode == '-';
        if (isOrganizationAdmin || schoolCodeMissing) {
          if (becameActive) {
            await _profileEditCubit.activateOrganizationAdmin(
              userCode: _profileUserCode,
              organizationCode: _profileOrganizationCode,
            );
          } else {
            await _profileEditCubit.deactivateOrganizationAdmin(
              userCode: _profileUserCode,
              organizationCode: _profileOrganizationCode,
            );
          }
        } else {
          final role =
              (staffTypeUpper == 'ADMIN' || staffTypeUpper == 'SCHOOL_ADMIN')
              ? 'SCHOOL_ADMIN'
              : 'STAFF';
          if (becameActive) {
            await _profileEditCubit.activateSchoolUser(
              userCode: _profileUserCode,
              organizationCode: _profileOrganizationCode,
              schoolCode: _profileSchoolCode,
              role: role,
            );
          } else {
            await _profileEditCubit.deactivateSchoolUser(
              userCode: _profileUserCode,
              organizationCode: _profileOrganizationCode,
              schoolCode: _profileSchoolCode,
              role: role,
            );
          }
        }
      }

      // Classrooms have dedicated endpoints (the /profile PATCH ignores them).
      // Update allowed classrooms first so the primary is valid within the set,
      // then update the primary classroom. Always send the current selection,
      // even when empty — `_selectedAllowedClassrooms` is the form's own live
      // state (not an "untouched" sentinel), so an empty list is a genuine,
      // intentional "remove every classroom assignment". Skipping the call
      // when empty (the previous `isNotEmpty` guard) silently dropped that
      // removal — the staff member stayed assigned server-side even after
      // unchecking their only classroom and saving.
      await _profileEditCubit.updateAllowedClassrooms(
        staffCode: widget.staffCode,
        classroomCodes: allowedClassroomCodes,
      );
      if (primaryClassroomCode != null && primaryClassroomCode.isNotEmpty) {
        await _profileEditCubit.updatePrimaryClassroom(
          staffCode: widget.staffCode,
          classroomCode: primaryClassroomCode,
        );
      }

      // Then update address via dedicated endpoint
      final addressMessage = await _profileEditCubit.updateAddress(
        staffCode: widget.staffCode,
        fields: addressPayload,
      );

      if (!mounted) return;
      _isSubmitting.value = false;

      // Profile mutation — poke the scheduling screens so they silently
      // re-pull the staff list on the next visit.
      SchedulingEvents.notifyChanged();
      // Same idea for the Classroom module's own Staff tab: allowed/primary
      // classroom assignment may have just changed (including a full
      // removal above), so its cached roster is stale the moment this
      // returns — without this, a removed staff member kept showing in
      // that classroom's list until some unrelated refresh happened to
      // fire.
      notifyClassroomStaffChanged();

      // Upload the picked photo in the BACKGROUND so saving returns instantly;
      // it keeps running even after this screen is popped.
      final photo = _profilePhoto;
      if (photo != null && widget.staffCode.trim().isNotEmpty) {
        context.read<StaffProfileEditCubit>().uploadProfilePhotoInBackground(
          staffCode: widget.staffCode.trim(),
          file: photo,
          schoolCode: _profileSchoolCode,
          organizationCode: _profileOrganizationCode,
        );
      }

      // updateStaffAddress runs unconditionally on every save, just like
      // updateStaffProfile, regardless of whether the address itself
      // changed — so addressMessage is always non-empty, and preferring it
      // (as this used to) meant the banner said something address-specific
      // (e.g. "Staff address updated successfully") on EVERY save, even one
      // that only touched the name or phone number. The general profile
      // message is the correct default; address-specific text has no
      // reason to override it just because that endpoint also ran.
      final profileOrAddressMessage = profileMessage.isNotEmpty
          ? profileMessage
          : addressMessage;
      // This form always resubmits every field on save (no per-field dirty
      // tracking), so the /profile PATCH's generic success message can't by
      // itself tell "only email changed" apart from "other fields changed
      // too" — compare the submitted values against what was actually
      // loaded (captured in _original* at prefill time) to tell them apart.
      final otherFieldsChanged =
          first.trim().toLowerCase() != _originalFirstName ||
          last.trim().toLowerCase() != _originalLastName ||
          phoneDigits != _originalPhoneDigits ||
          _streetController.text.trim().toLowerCase() !=
              _originalAddressStreet ||
          _street2Controller.text.trim().toLowerCase() !=
              _originalAddressLine2 ||
          _cityController.text.trim().toLowerCase() != _originalAddressCity ||
          (_selectedState ?? '').trim().toLowerCase() !=
              _originalAddressState ||
          zipDigits != _originalAddressZipDigits;
      // The web app shows the profile-update confirmation and the
      // email-change endpoint's own message (e.g. a verification notice) as
      // two separate stacked notifications. This app's top banner only
      // shows one at a time (replacing any prior one instantly), so when
      // BOTH changed, both messages are combined into one instead of
      // picking just one and silently dropping the other; when only the
      // email changed, the email-change message alone is shown (matching
      // the web app exactly).
      final baseMessage = !emailChanged
          ? profileOrAddressMessage
          : emailChangeFailed
          ? 'Profile updated, but the email change failed: '
                '${(emailChangeMessage ?? '').trim().isNotEmpty ? emailChangeMessage : 'please try again.'}'
          : (() {
              final trimmedEmail = (emailChangeMessage ?? '').trim();
              if (!otherFieldsChanged) {
                return trimmedEmail.isNotEmpty
                    ? trimmedEmail
                    : profileOrAddressMessage.trim();
              }
              final trimmedProfile = profileOrAddressMessage.trim();
              if (trimmedEmail.isEmpty) return trimmedProfile;
              if (trimmedProfile.isEmpty) return trimmedEmail;
              return '$trimmedProfile $trimmedEmail';
            })();
      CoreUtils.showTopSnackBar(
        context: context,
        message:
            baseMessage +
            (photo != null ? ' Photo is uploading in the background…' : ''),
        isSuccess: !emailChangeFailed,
        isWarning: emailChangeFailed,
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      _isSubmitting.value = false;
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
          firstDate: DateTime(1900),
          lastDate: AppTime.now(),
        ),
      );

      if (!mounted) return;
      if (result != null && result['date'] != null) {
        final selectedDate = result['date'] as DateTime;
        final now = AppTime.now();
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

    return BlocBuilder<ClassroomCubit, ClassroomState>(
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
            backgroundColor: AppColors.pageBackgroundColor,
            appBar: const CustomAppBar(hasBackButton: true),
            body: Stack(
              children: [
                Positioned.fill(
                  child: ColoredBox(color: AppColors.pageBackgroundColor),
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
                            fontFamily: AppFonts.body,
                            fontSize: responsive.titleFontSize,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
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
                        decoration: AppSurfaces.card(
                          borderRadius: BorderRadius.all(
                            Radius.circular(responsive.isTablet ? 40.0 : 24.0),
                          ),
                        ),
                        child: ListView(
                          padding: EdgeInsets.zero,
                          children: [
                            _buildStaffPhotoField(responsive),
                            SizedBox(height: responsive.isTablet ? 24.0 : 16.0),
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
                                      if (_selectedPrimaryClassroom != null &&
                                          !classrooms.contains(
                                            _selectedPrimaryClassroom,
                                          )) {
                                        // The removed classroom was this
                                        // staff member's primary. Leaving
                                        // this null meant _saveProfile's
                                        // `primaryClassroomCode != null`
                                        // guard skipped calling
                                        // updateStaffPrimaryClassroom
                                        // entirely on save — the backend's
                                        // primaryClassroomCode (what the
                                        // Classroom -> Staff list actually
                                        // filters by, NOT allowedClassroomCodes)
                                        // stayed pointed at the just-removed
                                        // classroom, so the staff member kept
                                        // showing in its roster no matter how
                                        // many times that list refreshed.
                                        // Auto-picking a remaining allowed
                                        // classroom (when one exists) keeps
                                        // this field non-null so the save
                                        // actually persists a real change.
                                        _selectedPrimaryClassroom =
                                            classrooms.isNotEmpty
                                            ? classrooms.first
                                            : null;
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
                                      fontFamily: AppFonts.body,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.primaryColor,
                                    ),
                                    showAsterisk: !_isAdminSelected,
                                    labelBottomSpacing: responsive.isTablet
                                        ? 8.0
                                        : 6.0,
                                    fieldHeight: responsive.isTablet
                                        ? 64.0
                                        : 56.0,
                                    selectedTextStyle: TextStyle(
                                      fontFamily: AppFonts.body,
                                      fontSize: responsive.inputFontSize,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryColor,
                                      height: 19 / 14,
                                    ),
                                    popupItemTextStyle: TextStyle(
                                      fontFamily: AppFonts.body,
                                      fontSize: responsive.inputFontSize,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.primaryColor,
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
                                EditPhoneNumberFormatter(),
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
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r"[a-zA-Z\s.'-]"),
                                ),
                              ],
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
                                  fontFamily: AppFonts.body,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.primaryColor,
                                ),
                                selectedTextStyle: TextStyle(
                                  fontFamily: AppFonts.body,
                                  fontSize: responsive.inputFontSize,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.billingGreyDark,
                                  height: 19 / 14,
                                ),
                                popupItemTextStyle: TextStyle(
                                  fontFamily: AppFonts.body,
                                  fontSize: responsive.inputFontSize,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.primaryColor,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: responsive.isTablet ? 16.0 : 12.0,
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
                                ZipCodeFormatter(),
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
            bottomNavigationBar: BottomActionBar(
              child: ValueListenableBuilder<bool>(
                valueListenable: _isSubmitting,
                builder: (context, isSubmitting, _) {
                  return CustomButtonLayout(
                    confirmButtonLabel: 'Save',
                    onPressedConfirm: _saveProfileDetails,
                    showCancelButton: false,
                    isForm: false,
                    isLoading: isSubmitting,
                  );
                },
              ),
            ),
          ),
        );
      },
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
      fontFamily: AppFonts.body,
      fontWeight: FontWeight.w400,
      color: AppColors.primaryColor,
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
                  style: TextStyle(color: AppColors.errorColor),
                ),
            ],
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        Container(
          constraints: BoxConstraints(minHeight: responsive.inputFieldHeight),
          decoration: AppSurfaces.field(
            radius: responsive.isTablet ? 12.0 : 8.0,
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            textCapitalization: textCapitalization,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: labelStyle.copyWith(color: AppColors.billingGrey),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: responsive.isTablet ? 16.0 : 12.0,
                vertical: responsive.isTablet ? 16.0 : 12.0,
              ),
            ),
            style: TextStyle(
              fontFamily: AppFonts.body,
              fontSize: responsive.inputFontSize,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
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
        fontFamily: AppFonts.body,
        fontWeight: FontWeight.w400,
        color: AppColors.primaryColor,
      ),
      labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
      fieldHeight: responsive.isTablet ? 64.0 : 56.0,
      selectedTextStyle: TextStyle(
        fontFamily: AppFonts.body,
        fontSize: responsive.inputFontSize,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryColor,
        height: 19 / 14,
      ),
      popupItemTextStyle: TextStyle(
        fontFamily: AppFonts.body,
        fontSize: responsive.inputFontSize,
        fontWeight: FontWeight.w400,
        color: AppColors.primaryColor,
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
      fontFamily: AppFonts.body,
      fontWeight: FontWeight.w400,
      color: AppColors.primaryColor,
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
              color: AppColors.cardColor,
              border: Border.all(color: AppColors.inputBorderColor),
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
                        fontFamily: AppFonts.body,
                        fontSize: responsive.inputFontSize,
                        fontWeight: selectedDate != null
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: AppColors.primaryColor,
                        height: 19 / 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  AppIcon(
                    MediaRes.calender_icon,
                    height: 20.0,
                    color: AppColors.primaryColor,
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
