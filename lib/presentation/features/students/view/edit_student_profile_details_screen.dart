import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_fonts.dart';
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/constants/location_constants.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/domain/features/student/entities/student_guardian.dart';
import 'package:wowcare/domain/features/student/entities/update_student_address_request.dart';
import 'package:wowcare/domain/features/student/entities/update_student_profile_request.dart';
import 'package:wowcare/domain/features/student/entities/update_guardian_request.dart';
import 'package:wowcare/presentation/features/students/view_model/student_profile_edit_cubit.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/presentation/features/classroom/view_model/classroom_cubit.dart';
import 'package:wowcare/domain/features/classroom/entities/classroom.dart';
import 'package:wowcare/domain/features/classroom/services/classroom_age_rules.dart';
import 'package:wowcare/shared/common/widgets/confirmation_bottom_sheet.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/student/usecases/get_tag_names_for_school_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_tag_name_code_map_for_school_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_today_sign_in_status_usecase.dart';
import 'package:wowcare/presentation/features/students/widgets/student_attendance_action_availability.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/presentation/features/students/student_strings.dart';

class EditStudentProfileDetailsScreen extends StatefulWidget {
  const EditStudentProfileDetailsScreen({
    super.key,
    required this.studentCode,
    this.initialFirstName,
    this.initialLastName,
    this.initialStatus,
    this.initialClassroom,
    this.initialBirthDate,
    this.initialNotes,
    this.initialStreet,
    this.initialCity,
    this.initialState,
    this.initialCountry,
    this.initialZipCode,
    this.initialTags = const [],
    this.initialSiblings = const [],
    this.initialLegalCustodians = const [],
    this.initialSubsidy = false,
    this.initialGender,
  });
  static const String routeName = '/edit-student-profile-details-screen';

  final String studentCode;
  final String? initialFirstName;
  final String? initialLastName;
  final String? initialStatus;
  final String? initialNotes;
  final String? initialClassroom;
  final DateTime? initialBirthDate;
  final String? initialStreet;
  final String? initialCity;
  final String? initialState;
  final String? initialCountry;
  final String? initialZipCode;
  final List<String> initialTags;
  final List<String> initialSiblings;
  final List<String> initialLegalCustodians;
  final bool initialSubsidy;

  /// Raw API value e.g. MALE, FEMALE, or null.
  final String? initialGender;

  @override
  _EditStudentProfileDetailsScreenState createState() =>
      _EditStudentProfileDetailsScreenState();
}

class _EditStudentProfileDetailsScreenState
    extends State<EditStudentProfileDetailsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Single cubit instance that routes every read/write for this screen through
  // use cases → repository, so the view never touches StudentRepository or
  // StudentRemoteDataSource directly. Closed in dispose().
  final StudentProfileEditCubit _profileEditCubit =
      serviceLocator<StudentProfileEditCubit>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _street2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();

  // The full profile form model + server-fetched options/maps now live in
  // StudentProfileEditCubit's state (see the `_selected*`/`_available*` getters
  // below that read it). Guardians are kept as typed `StudentGuardian` records
  // keyed by code (`guardianRawByCode`): the custody PATCH validates as a FULL
  // update (firstName/lastName/email/mobile/relationToStudent/userCode/schoolCode
  // all required), not a partial patch, so `legalCustody` alone 400s — the rest
  // are echoed back from the loaded record.
  //
  // Waitlist and Graduated are intentionally omitted from the status options:
  // no mobile workflow exists for either, so offering them just lets a student
  // get stuck in a status nothing on mobile can act on. A student already
  // carrying one (set on web) still displays it — CustomDropdown shows
  // selectedItem as plain text without requiring membership in items.
  final List<String> _statusOptions = ['Active', 'Inactive', 'Upcoming'];
  final List<String> _stateSubsidyOptions = ['Yes', 'No'];
  final List<String> _genderOptions = const ['Male', 'Female', 'Other'];

  // Read-through getters onto the cubit-owned form model — all writes go through
  // the cubit setters; reads stay reactive under the build's BlocBuilder.
  String? get _selectedStatus => _profileEditCubit.state.status;
  String? get _selectedStateSubsidyOption =>
      _profileEditCubit.state.stateSubsidyOption;
  List<String> get _selectedSiblings =>
      _profileEditCubit.state.selectedSiblings;
  List<String> get _selectedTags => _profileEditCubit.state.selectedTags;
  String? get _selectedClassroom => _profileEditCubit.state.classroom;
  bool get _classroomChangedByUser =>
      _profileEditCubit.state.classroomChangedByUser;
  DateTime? get _selectedBirthDate => _profileEditCubit.state.birthDate;
  List<String> get _selectedChildCustody =>
      _profileEditCubit.state.selectedChildCustody;
  String? get _selectedState => _profileEditCubit.state.stateName;
  String? get _selectedCountry => _profileEditCubit.state.country;
  String? get _selectedGender => _profileEditCubit.state.gender;
  bool get _isSubmitting => _profileEditCubit.state.submitting;
  bool get _isTodayStatusLoading =>
      _profileEditCubit.state.isTodayStatusLoading;
  bool get _isSignedInToday => _profileEditCubit.state.isSignedInToday;
  List<String> get _availableTagNames =>
      _profileEditCubit.state.availableTagNames;
  Map<String, String> get _tagNameToCode =>
      _profileEditCubit.state.tagNameToCode;
  List<String> get _availableStudentNames =>
      _profileEditCubit.state.availableStudentNames;
  Map<String, String> get _studentNameToCode =>
      _profileEditCubit.state.studentNameToCode;
  List<String> get _availableGuardianNames =>
      _profileEditCubit.state.availableGuardianNames;
  Map<String, String> get _guardianNameToCode =>
      _profileEditCubit.state.guardianNameToCode;
  Map<String, bool> get _guardianInitialCustody =>
      _profileEditCubit.state.guardianInitialCustody;
  Map<String, StudentGuardian> get _guardianRawByCode =>
      _profileEditCubit.state.guardianRawByCode;
  final List<String> _stateOptions = US_STATES
      .map((s) => s.name)
      .toList(growable: false);
  // Country is fixed to United States for this form.

  // Simple validators (align with Add Staff)
  // First character A-Z, then up to 49 letters/space/hyphen/apostrophe.
  static final RegExp _nameRegex = RegExp(r"^[A-Za-z][A-Za-z\-'\s]{0,49}$");
  static final RegExp _zipDigitsRegex = RegExp(
    r'^\d{5}(\d{4})?$',
  ); // 5 or 9 digits (ZIP / ZIP+4)

  static String _digitsOnly(String input) =>
      input.replaceAll(RegExp(r'\D'), '');

  static String? _genderDisplayFromApi(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    switch (raw.trim().toUpperCase()) {
      case 'MALE':
        return 'Male';
      case 'FEMALE':
        return 'Female';
      case 'OTHER':
      case 'NON_BINARY':
      case 'NONBINARY':
      case 'PREFER_NOT_TO_SAY':
        return 'Other';
      default:
        return null;
    }
  }

  /// API expects uppercase: MALE, FEMALE, OTHER.
  static String? _genderApiFromDisplay(String? display) {
    if (display == null || display.trim().isEmpty) return null;
    switch (display) {
      case 'Male':
        return 'MALE';
      case 'Female':
        return 'FEMALE';
      case 'Other':
        return 'OTHER';
      default:
        return null;
    }
  }

  @override
  void initState() {
    super.initState();
    // Prefill when editing (use existing profile values; no mock defaults).
    _firstNameController.text = widget.initialFirstName ?? '';
    _lastNameController.text = widget.initialLastName ?? '';
    _notesController.text = widget.initialNotes ?? '';
    _streetController.text = widget.initialStreet ?? '';
    _street2Controller.text = '';
    _cityController.text = widget.initialCity ?? '';

    // Map initial state (name or abbreviation) to display name from US_STATES.
    String? initialStateName;
    if (widget.initialState != null && widget.initialState!.isNotEmpty) {
      final raw = widget.initialState!;
      final match = US_STATES.firstWhere(
        (s) =>
            s.name.toLowerCase() == raw.toLowerCase() ||
            s.abbreviation.toLowerCase() == raw.toLowerCase(),
        orElse: () => US_STATES.first,
      );
      initialStateName = match.name;
    }

    // Accept legacy stored formats: "12345", "123456789", or "12345-6789"
    final initialZipRaw = widget.initialZipCode ?? '';
    _zipCodeController.text = _formatUsZipForDisplay(initialZipRaw);

    final g = _genderDisplayFromApi(widget.initialGender);

    // Controllers stay local; the rest of the form model seeds the cubit.
    // Country is fixed to United States on this screen.
    _profileEditCubit.initialize(
      status: widget.initialStatus,
      stateSubsidyOption: widget.initialSubsidy ? 'Yes' : 'No',
      classroom: widget.initialClassroom,
      birthDate: widget.initialBirthDate,
      selectedTags: List<String>.from(widget.initialTags),
      selectedSiblings: List<String>.from(widget.initialSiblings),
      selectedChildCustody: List<String>.from(widget.initialLegalCustodians),
      stateName: initialStateName,
      country: 'United States',
      gender: g != null && _genderOptions.contains(g) ? g : null,
    );

    // Load dynamic dropdown data
    _loadTags();
    _loadStudentsForSiblings();
    _loadGuardiansForCustody();
    _loadTodayStatus();
  }

  /// Mirrors student_attendance_profile.dart's `_loadTodayStatus()` — reuses
  /// the same use case so "currently signed in" is determined identically
  /// everywhere in the app.
  Future<void> _loadTodayStatus() async {
    final code = widget.studentCode.trim();
    if (code.isEmpty) {
      if (!mounted) return;
      _profileEditCubit.setTodayStatus(isSignedInToday: false);
      return;
    }
    try {
      final useCase = serviceLocator<GetStudentTodaySignInStatusUseCase>();
      final status = await useCase(studentCode: code);
      if (!mounted) return;
      final gate = studentAttendanceGateFromTodayStatus(
        isActiveProfile: true,
        todayStatusRaw: status,
      );
      _profileEditCubit.setTodayStatus(isSignedInToday: gate.isSignedInToday);
    } catch (_) {
      if (!mounted) return;
      // Fail closed: keep the Classroom field disabled if the status can't
      // be determined, same convention as student_attendance_profile.dart.
      _profileEditCubit.setTodayStatus(isSignedInToday: true);
    }
  }

  Future<void> _loadTags() async {
    try {
      final storage = serviceLocator<StorageService>();
      final schoolCode = await storage.getString(StorageKeys.schoolCode) ?? '';
      if (schoolCode.isEmpty) return;

      final namesUseCase = serviceLocator<GetTagNamesForSchoolUseCase>();
      final mapUseCase = serviceLocator<GetTagNameCodeMapForSchoolUseCase>();

      final names = await namesUseCase(schoolCode: schoolCode);
      final nameCodeMap = await mapUseCase(schoolCode: schoolCode);
      if (!mounted) return;

      // Drop any selected tags that no longer exist.
      final prunedTags = _profileEditCubit.state.selectedTags
          .where(names.contains)
          .toList();
      _profileEditCubit.applyTagsLoaded(
        names: names,
        nameToCode: nameCodeMap,
        selectedTags: prunedTags,
      );
    } catch (_) {
      // Non-critical for this form; keep selections as-is.
    }
  }

  Future<void> _loadStudentsForSiblings() async {
    try {
      final storage = serviceLocator<StorageService>();
      final schoolCode = await storage.getString(StorageKeys.schoolCode) ?? '';
      if (schoolCode.isEmpty) return;

      // Always fetch from API (no cached student list for this dropdown).
      final page = await _profileEditCubit.fetchStudentPage(
        schoolCode: schoolCode,
        status: 'ACTIVE',
        page: 0,
        size: 150,
      );

      if (!mounted) return;

      final currentStudentCode = widget.studentCode.trim();
      final currentStudentName =
          '${widget.initialFirstName ?? ''} ${widget.initialLastName ?? ''}'
              .trim()
              .toLowerCase();

      final rawRows = <Map<String, String>>[];
      for (final s in page.items) {
        if (s.code.toString().trim() == currentStudentCode) {
          continue;
        }
        final display = '${s.firstName} ${s.lastName}'.trim();
        if (display.isEmpty) continue;
        if (currentStudentName.isNotEmpty &&
            display.trim().toLowerCase() == currentStudentName) {
          continue;
        }
        rawRows.add(<String, String>{
          'name': display,
          'code': s.code.toString().trim(),
        });
      }

      final nameToCode = <String, String>{};
      final codeToDisplay = <String, String>{};
      final names = <String>[];
      for (final row in rawRows) {
        final base = row['name']!;
        final code = row['code']!;
        final displayLabel = base;
        names.add(displayLabel);
        nameToCode[displayLabel] = code;
        codeToDisplay[code] = displayLabel;
      }

      // If initial siblings are codes, map them to names for display; else
      // ensure existing selected names still exist in the fetched list.
      final List<String> selectedSiblings;
      if (widget.initialSiblings.isNotEmpty) {
        selectedSiblings = widget.initialSiblings
            .map((code) => codeToDisplay[code] ?? code)
            .where((n) => n.trim().isNotEmpty)
            .toList();
      } else {
        selectedSiblings = _profileEditCubit.state.selectedSiblings
            .where(names.contains)
            .toList();
      }

      _profileEditCubit.applyStudentsLoaded(
        names: names,
        nameToCode: nameToCode,
        selectedSiblings: selectedSiblings,
      );
    } catch (_) {
      // Non-critical; leave siblings dropdown empty.
    }
  }

  Future<void> _loadGuardiansForCustody() async {
    try {
      if (widget.studentCode.trim().isEmpty) return;
      final guardians = await _profileEditCubit.fetchGuardians(
        widget.studentCode,
      );

      final rawRows = <Map<String, dynamic>>[];
      for (final g in guardians) {
        final base = g.fullName.trim();
        final code = g.guardianCode.trim();
        final legalCustody = g.legalCustody;
        if (base.isEmpty || code.isEmpty) continue;
        rawRows.add(<String, dynamic>{
          'name': base,
          'code': code,
          'legalCustody': legalCustody,
          'raw': g,
        });
      }

      final names = <String>[];
      final nameToCode = <String, String>{};
      final initialCustody = <String, bool>{};
      final rawByCode = <String, StudentGuardian>{};
      for (final row in rawRows) {
        final base = row['name'] as String;
        final code = row['code'] as String;
        names.add(base);
        nameToCode[base] = code;
        initialCustody[base] = row['legalCustody'] as bool;
        rawByCode[code] = row['raw'] as StudentGuardian;
      }
      if (!mounted) return;

      final prunedCustody = _profileEditCubit.state.selectedChildCustody
          .where(names.contains)
          .toList();
      _profileEditCubit.applyGuardiansLoaded(
        names: names,
        nameToCode: nameToCode,
        initialCustody: initialCustody,
        rawByCode: rawByCode,
        selectedChildCustody: prunedCustody,
      );
    } catch (_) {
      // Non-critical; keep any existing selections.
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _notesController.dispose();
    _street2Controller.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _zipCodeController.dispose();
    _profileEditCubit.close();
    super.dispose();
  }

  Future<void> _saveProfileDetails() async {
    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();

    if (first.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: StudentStrings.firstNameIsRequired,
        isError: true,
      );
      return;
    }
    if (first.length > 50 || !_nameRegex.hasMatch(first)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: StudentStrings.firstNameMustBeLettersOnlyAndMax50Characters2,
        isError: true,
      );
      return;
    }
    if (last.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: StudentStrings.lastNameIsRequired,
        isError: true,
      );
      return;
    }
    if (last.length > 50 || !_nameRegex.hasMatch(last)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: StudentStrings.lastNameMustBeLettersOnlyAndMax50Characters2,
        isError: true,
      );
      return;
    }
    if (_selectedStatus == null || _selectedStatus!.trim().isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: StudentStrings.statusIsRequired,
        isError: true,
      );
      return;
    }
    if (_selectedClassroom == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: StudentStrings.classroomIsRequired,
        isError: true,
      );
      return;
    }
    // Birthdate: required and must be in the past
    if (_selectedBirthDate == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: StudentStrings.birthdateIsRequired,
        isError: true,
      );
      return;
    } else {
      final now = AppTime.now();
      final today = DateTime(now.year, now.month, now.day);
      if (_selectedBirthDate!.isAfter(
        today.subtract(const Duration(days: 1)),
      )) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: StudentStrings.birthdateMustBeAPastDate,
          isError: true,
        );
        return;
      }
    }
    // Notes: optional, max 500 chars
    if (_notesController.text.trim().length > 500) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: StudentStrings.notesCannotExceed500Characters,
        isError: true,
      );
      return;
    }
    final street = _streetController.text.trim();
    final city = _cityController.text.trim();
    final zipDigits = _digitsOnly(_zipCodeController.text);

    if (street.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: StudentStrings.streetIsRequired,
        isError: true,
      );
      return;
    }
    if (street.length > 150) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: StudentStrings.streetAddressCannotExceed150Characters,
        isError: true,
      );
      return;
    }
    if (city.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: StudentStrings.cityIsRequired,
        isError: true,
      );
      return;
    }
    if (city.length > 50) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: StudentStrings.cityNameCannotExceed50Characters,
        isError: true,
      );
      return;
    }
    if (zipDigits.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: StudentStrings.zipCodeIsRequired,
        isError: true,
      );
      return;
    }
    if (!_zipDigitsRegex.hasMatch(zipDigits)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: StudentStrings.zipCodeMustBe5Digits12345OrZip4123456789,
        isError: true,
      );
      return;
    }
    if ((_selectedState ?? '').trim().isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: StudentStrings.stateIsRequired,
        isError: true,
      );
      return;
    }
    if ((_selectedCountry ?? '').trim().isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: StudentStrings.countryIsRequired,
        isError: true,
      );
      return;
    }

    // WARN (never block) when the DOB is outside the selected classroom's age
    // range. An out-of-range placement is a legitimate staff decision, so we
    // surface it and let them proceed — matching the web "warn but allow".
    // Only relevant when the user actually changed the classroom on this
    // screen; editing unrelated fields shouldn't re-trigger it.
    if (_classroomChangedByUser) {
      ClassroomCubit? classroomCubitForWarning;
      try {
        classroomCubitForWarning = context.read<ClassroomCubit>();
      } catch (_) {
        classroomCubitForWarning = null;
      }
      final classroomsForWarning =
          classroomCubitForWarning?.state.classrooms ?? const <Classroom>[];
      final matchingClassrooms = classroomsForWarning.where(
        (c) => c.name == _selectedClassroom || c.code == _selectedClassroom,
      );
      if (matchingClassrooms.isNotEmpty) {
        final ageWarning = classroomAgeRangeWarning(
          classroom: matchingClassrooms.first,
          birthDate: _selectedBirthDate,
          studentName: first,
        );
        if (ageWarning != null) {
          final proceedAnyway = await _confirmAgeOutsideRange(ageWarning);
          if (!proceedAnyway || !mounted) return;
        }
      }
    }

    _profileEditCubit.setSubmitting(true);

    try {
      // Map status display name to API value (e.g., "Active" -> "ACTIVE")
      String statusApi = _selectedStatus ?? '';
      if (statusApi.isNotEmpty) {
        final statusMap = {
          'Active': 'ACTIVE',
          'Inactive': 'INACTIVE',
          'Upcoming': 'UPCOMING',
          'Waitlist': 'WAITLIST',
          'Graduated': 'GRADUATED',
        };
        statusApi = statusMap[statusApi] ?? statusApi.toUpperCase();
      }

      // Map classroom display name -> classroom code for API (falls back to raw value).
      ClassroomCubit? classroomCubit;
      try {
        classroomCubit = context.read<ClassroomCubit>();
      } catch (_) {
        classroomCubit = null;
      }

      final classrooms =
          classroomCubit?.state.classrooms ?? const <Classroom>[];
      final classroomCodeByName = <String, String>{
        for (final c in classrooms) c.name: c.code,
      };
      final selectedClassroomName = _selectedClassroom ?? '';
      final classroomCode =
          classroomCodeByName[selectedClassroomName] ?? selectedClassroomName;

      // Map state/country display names back to codes for API
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

      // Format dates as yyyy-MM-dd for API
      final dateFormatter = DateFormat('yyyy-MM-dd');
      String? dobFormatted;
      if (_selectedBirthDate != null) {
        dobFormatted = dateFormatter.format(_selectedBirthDate!);
      }

      // Map subsidy
      final subsidy = _selectedStateSubsidyOption == 'Yes';

      // 1) Core profile PATCH /api/v1/student/{code}/profile
      final genderApi = _genderApiFromDisplay(_selectedGender);

      final message = await _profileEditCubit.updateProfile(
        code: widget.studentCode,
        request: UpdateStudentProfileRequest(
          firstName: first,
          lastName: last,
          status: statusApi,
          dob: dobFormatted,
          notes: _notesController.text.trim(),
          subsidy: subsidy,
          gender: genderApi?.toUpperCase(),
          classroomCode: classroomCode,
          classroomName: selectedClassroomName,
        ),
      );

      // 2) Address PATCH /api/v1/student/{studentCode}/address
      await _profileEditCubit.updateAddress(
        studentCode: widget.studentCode,
        request: UpdateStudentAddressRequest(
          street: street,
          line2: _street2Controller.text.trim(),
          city: city,
          state: stateCode,
          country: countryCode,
          // Backend uses postalCode; UI display layer formats as needed.
          postalCode: zipDigits,
          addressType: 'CURRENT',
        ),
      );

      // 3) Tags POST /api/v1/student-tags
      final selectedTagCodes = _selectedTags
          .map((n) => _tagNameToCode[n])
          .whereType<String>()
          .toList();
      if (selectedTagCodes.isNotEmpty) {
        final storage = serviceLocator<StorageService>();
        final schoolCode =
            await storage.getString(StorageKeys.schoolCode) ?? '';
        if (schoolCode.isNotEmpty) {
          await _profileEditCubit.updateTags(
            studentCode: widget.studentCode,
            schoolCode: schoolCode,
            tagCodes: selectedTagCodes,
          );
        }
      }

      // 4) Siblings PUT /api/v1/student/{studentCode}/siblings
      final siblingCodes = _selectedSiblings
          .map((name) => _studentNameToCode[name] ?? name)
          .where((code) => code.trim().isNotEmpty)
          .toList();
      if (siblingCodes.isNotEmpty) {
        await _profileEditCubit.updateSiblings(
          studentCode: widget.studentCode,
          siblingCodes: siblingCodes,
        );
      }

      // 5) Child custody PATCH /api/v1/guardian/{code} — only for guardians
      // whose custody selection actually changed, so unrelated guardians
      // aren't touched. The endpoint validates as a full guardian update
      // (firstName/lastName/email/mobile/relationToStudent/userCode/
      // schoolCode all required), so `legalCustody` alone 400s — the rest of
      // the fields are echoed back unchanged from the guardian record loaded
      // in `_loadGuardiansForCustody`.
      if (_guardianNameToCode.entries.any(
        (entry) =>
            _selectedChildCustody.contains(entry.key) !=
            (_guardianInitialCustody[entry.key] ?? false),
      )) {
        final storage = serviceLocator<StorageService>();
        final schoolCode =
            await storage.getString(StorageKeys.schoolCode) ?? '';

        for (final entry in _guardianNameToCode.entries) {
          final name = entry.key;
          final code = entry.value;
          final desiredCustody = _selectedChildCustody.contains(name);
          final currentCustody = _guardianInitialCustody[name] ?? false;
          if (desiredCustody == currentCustody) continue;

          final raw = _guardianRawByCode[code];
          if (raw == null) continue;
          await _profileEditCubit.updateGuardian(
            code: code,
            studentCode: widget.studentCode,
            request: UpdateGuardianRequest(
              userCode: raw.userCode,
              schoolCode: schoolCode,
              studentCode: widget.studentCode,
              firstName: raw.firstName,
              lastName: raw.lastName,
              email: raw.email,
              mobile: raw.mobile,
              relationToStudent: raw.relationToStudent,
              primaryContact: raw.primaryContact,
              legalCustody: desiredCustody,
            ),
          );
        }
      }

      if (!mounted) return;
      _profileEditCubit.setSubmitting(false);

      CoreUtils.showTopSnackBar(
        context: context,
        message: message,
        isSuccess: true,
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      _profileEditCubit.setSubmitting(false);
      final message = ApiErrorHandler.extractErrorMessage(e);
      CoreUtils.showTopSnackBar(
        context: context,
        message: message,
        isError: true,
      );
    }
  }

  /// Amber confirm for an out-of-range DOB. Returns true to proceed anyway.
  Future<bool> _confirmAgeOutsideRange(String message) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparentColor,
      builder: (ctx) => ConfirmationBottomSheet(
        icon: Icons.warning_amber_rounded,
        title: message,
        confirmText: StudentStrings.continueAnyway,
        cancelText: StudentStrings.cancel,
        onConfirm: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
    return result == true;
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
        final now = AppTime.now();
        final today = DateTime(now.year, now.month, now.day);

        // Birthdate must be a past date (not today or future)
        if (selectedDate.isAfter(today.subtract(const Duration(days: 1)))) {
          CoreUtils.showTopSnackBar(
            context: context,
            message: StudentStrings.birthdateMustBeAPastDate,
            isError: true,
          );
          return;
        }

        _profileEditCubit.setBirthDate(selectedDate);
      }
    } catch (e) {
      AppLogger.d('Error opening calendar dialog: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure classrooms are available for the Classroom dropdown.
    // If a ClassroomCubit is already provided (e.g. from Students flow), reuse it (no refetch).
    // Otherwise, create it here and load once.
    final hasClassroomCubit = (() {
      try {
        context.read<ClassroomCubit>();
        return true;
      } catch (_) {
        return false;
      }
    })();

    if (!hasClassroomCubit) {
      return BlocProvider<ClassroomCubit>(
        create: (_) => serviceLocator<ClassroomCubit>()..loadActiveClassrooms(),
        child: Builder(builder: (context) => _buildScreen(context)),
      );
    }

    return _buildScreen(context);
  }

  Widget _buildScreen(BuildContext context) {
    return BlocBuilder<StudentProfileEditCubit, StudentProfileEditState>(
      bloc: _profileEditCubit,
      builder: (context, editState) => _buildScreenBody(context),
    );
  }

  Widget _buildScreenBody(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;

    ClassroomState classroomState;
    try {
      classroomState = context.watch<ClassroomCubit>().state;
    } catch (_) {
      classroomState = const ClassroomState.initial();
    }
    final classroomOptions = classroomState.classrooms
        .map((c) => c.name)
        .toList(growable: false);

    // Keep selected classroom as display name in UI, even if initial value is a code.
    String? selectedClassroomName = _selectedClassroom;
    if (selectedClassroomName != null && selectedClassroomName.isNotEmpty) {
      final byCode = <String, String>{
        for (final c in classroomState.classrooms) c.code: c.name,
      };
      selectedClassroomName =
          byCode[selectedClassroomName] ?? selectedClassroomName;
    }

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: AppColors.whiteColor,
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
                AppSpacing.gapVMd,
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.horizontalSpacing,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      StudentStrings.editStudent,
                      style: TextStyle(
                        fontFamily: Fonts.manrope,
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
                    padding: EdgeInsets.all(responsive.isTablet ? 32.0 : 16.0),
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor,
                      borderRadius: BorderRadius.all(
                        Radius.circular(responsive.isTablet ? 40.0 : 24.0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.blackColor.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        // Same green/red "signed in today" indicator used in
                        // the Student Attendance module — gives a visible
                        // reason alongside the disabled Classroom field.
                        Row(
                          children: [
                            DocumentImageWidget(
                              fileUuid: '',
                              studentCode: widget.studentCode,
                              name:
                                  '${widget.initialFirstName ?? ''} ${widget.initialLastName ?? ''}',
                              size: 40,
                              fontSize: 14,
                            ),
                            const SizedBox(width: AppSpacing.s10),
                            Expanded(
                              child: Text(
                                '${widget.initialFirstName ?? ''} ${widget.initialLastName ?? ''}'
                                    .trim(),
                                style: const TextStyle(
                                  fontFamily: Fonts.manrope,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: responsive.verticalSpacing),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInputField(
                                StudentStrings.firstName,
                                StudentStrings.eGJohn,
                                _firstNameController,
                              ),
                            ),
                            SizedBox(width: responsive.isTablet ? 24.0 : 16.0),
                            Expanded(
                              child: _buildInputField(
                                StudentStrings.lastName,
                                StudentStrings.eGSmith,
                                _lastNameController,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: responsive.verticalSpacing),
                        _buildCustomDropdown(
                          StudentStrings.status,
                          StudentStrings.select,
                          _statusOptions,
                          _selectedStatus,
                          (v) => _profileEditCubit.setStatus(v),
                          isRequired: true,
                        ),
                        SizedBox(height: responsive.verticalSpacing),
                        _buildCustomDropdown(
                          StudentStrings.gender,
                          StudentStrings.select,
                          _genderOptions,
                          _selectedGender,
                          (v) => _profileEditCubit.setGender(v),
                        ),
                        SizedBox(height: responsive.verticalSpacing),
                        _buildCustomDropdown(
                          StudentStrings.classroom,
                          (classroomState.isLoading && classroomOptions.isEmpty)
                              ? StudentStrings.loadingEllipsis
                              : StudentStrings.select,
                          classroomOptions,
                          selectedClassroomName,
                          (v) => _profileEditCubit.setClassroom(v),
                          isRequired: true,
                          isEnabled:
                              !_isTodayStatusLoading && !_isSignedInToday,
                          disabledTooltip: _isTodayStatusLoading
                              ? null
                              : StudentStrings
                                    .classroomCantBeChangedWhileSignedIn,
                        ),
                        SizedBox(height: responsive.verticalSpacing),
                        CustomMultiSelectDropdown(
                          label: StudentStrings.tags,
                          hintText: StudentStrings.select,
                          items: _availableTagNames,
                          selectedItems: _selectedTags,
                          onChanged: (tags) =>
                              _profileEditCubit.setSelectedTags(tags),
                          isField: true,
                        ),
                        SizedBox(height: responsive.verticalSpacing),
                        _buildDateField(
                          StudentStrings.dateOfBirth,
                          _selectedBirthDate,
                        ),
                        SizedBox(height: responsive.verticalSpacing),
                        _buildInputField(
                          StudentStrings.notes,
                          "",
                          _notesController,
                        ),
                        SizedBox(height: responsive.verticalSpacing),
                        CustomMultiSelectDropdown(
                          label: StudentStrings.siblings,
                          hintText: StudentStrings.selectStudent,
                          items: _availableStudentNames,
                          selectedItems: _selectedSiblings,
                          onChanged: (siblings) =>
                              _profileEditCubit.setSelectedSiblings(siblings),
                          maxDropdownHeight: 200,
                          isField: true,
                        ),
                        SizedBox(height: responsive.verticalSpacing),
                        CustomMultiSelectDropdown(
                          label: StudentStrings.childCustody,
                          hintText: StudentStrings.selectGuardian,
                          items: _availableGuardianNames,
                          selectedItems: _selectedChildCustody,
                          onChanged: (custodyOptions) => _profileEditCubit
                              .setSelectedChildCustody(custodyOptions),
                          isField: true,
                        ),
                        SizedBox(height: responsive.verticalSpacing),
                        _buildCustomDropdown(
                          StudentStrings.stateSubsidy,
                          StudentStrings.select,
                          _stateSubsidyOptions,
                          _selectedStateSubsidyOption,
                          (v) => _profileEditCubit.setStateSubsidyOption(v),
                        ),
                        SizedBox(height: responsive.verticalSpacing),
                        _buildInputField(
                          StudentStrings.street,
                          StudentStrings.egStreetNo,
                          _streetController,
                          isRequired: true,
                          textCapitalization: TextCapitalization.words,
                        ),
                        SizedBox(height: responsive.verticalSpacing),
                        _buildInputField(
                          StudentStrings.addressLine2,
                          StudentStrings.optionalParenthetical,
                          _street2Controller,
                          isRequired: false,
                          textCapitalization: TextCapitalization.words,
                        ),
                        SizedBox(height: responsive.verticalSpacing),
                        _buildInputField(
                          StudentStrings.city,
                          StudentStrings.egNashua,
                          _cityController,
                          isRequired: true,
                          textCapitalization: TextCapitalization.words,
                        ),
                        SizedBox(height: responsive.verticalSpacing),
                        _buildCustomDropdown(
                          StudentStrings.state,
                          StudentStrings.select,
                          _stateOptions,
                          _selectedState,
                          (v) => _profileEditCubit.setStateName(v),
                          isRequired: true,
                        ),
                        SizedBox(height: responsive.verticalSpacing),
                        Opacity(
                          opacity: 0.8,
                          child: CustomDropdown(
                            label: StudentStrings.country,
                            hintText: StudentStrings.unitedStates,
                            items: const <String>['United States'],
                            selectedItem: 'United States',
                            isEnabled: false,
                            showAsterisk: true,
                            labelStyle: TextStyle(
                              fontSize: responsive.labelFontSize,
                              fontFamily: Fonts.manrope,
                              fontWeight: FontWeight.w400,
                              color: AppColors.primaryColor,
                            ),
                            selectedTextStyle: TextStyle(
                              fontFamily: Fonts.manrope,
                              fontSize: responsive.inputFontSize,
                              fontWeight: FontWeight.w600,
                              color: AppColors.attendanceSearchHintColor,
                              height: 19 / 14,
                            ),
                            popupItemTextStyle: TextStyle(
                              fontFamily: Fonts.manrope,
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
                          StudentStrings.zipCode,
                          StudentStrings.egZipExample,
                          _zipCodeController,
                          isRequired: true,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(9),
                            _ZipCodeFormatter(),
                          ],
                        ),
                        SizedBox(height: responsive.verticalSpacing),
                      ],
                    ),
                  ),
                ),
                AppSpacing.gapVSm,
              ],
            ),
          ],
        ),
        bottomNavigationBar: Container(
          padding: EdgeInsets.only(
            bottom: safeAreaBottom,
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.whiteColor,
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
          child: CustomButtonLayout(
            confirmButtonLabel: StudentStrings.save,
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
      fontFamily: Fonts.manrope,
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
          decoration: BoxDecoration(
            color: AppColors.whiteColor,
            border: Border.all(color: AppColors.inputBorderColor),
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
              hintStyle: labelStyle.copyWith(
                color: AppColors.attendanceMutedTextColor,
              ),
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
    bool isEnabled = true,
    String? disabledTooltip,
  }) {
    final responsive = ResponsiveHelper(context);
    final dropdown = CustomDropdown(
      label: label,
      hintText: hintText,
      items: items,
      selectedItem: selectedItem,
      onSelect: onSelect,
      showAsterisk: isRequired,
      isEnabled: isEnabled,
      labelStyle: TextStyle(
        fontSize: responsive.labelFontSize,
        fontFamily: Fonts.manrope,
        fontWeight: FontWeight.w400,
        color: AppColors.primaryColor,
      ),
      labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
      fieldHeight: responsive.isTablet ? 64.0 : 56.0,
      selectedTextStyle: TextStyle(
        fontFamily: Fonts.manrope,
        fontSize: responsive.inputFontSize,
        fontWeight: FontWeight.w600,
        color: AppColors.primaryColor,
        height: 19 / 14,
      ),
      popupItemTextStyle: TextStyle(
        fontFamily: Fonts.manrope,
        fontSize: responsive.inputFontSize,
        fontWeight: FontWeight.w400,
        color: AppColors.primaryColor,
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: responsive.isTablet ? 16.0 : 12.0,
        vertical: responsive.isTablet ? 16.0 : 12.0,
      ),
    );

    if (!isEnabled && disabledTooltip != null) {
      return Tooltip(message: disabledTooltip, child: dropdown);
    }
    return dropdown;
  }

  Widget _buildDateField(String label, DateTime? selectedDate) {
    final responsive = ResponsiveHelper(context);
    final labelStyle = TextStyle(
      fontSize: responsive.labelFontSize,
      fontFamily: Fonts.manrope,
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
              color: AppColors.whiteColor,
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
                          : StudentStrings.selectDate,
                      style: TextStyle(
                        fontFamily: Fonts.manrope,
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
                  AppSpacing.gapHXxs,
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
