import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/constants/location_constants.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/domain/features/classroom/entities/classroom.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/student/usecases/get_tag_names_for_school_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/get_tag_name_code_map_for_school_usecase.dart';
import 'package:wowcare/data/features/student/datasources/student_remote_datasource.dart';

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
    this.initialFTE,
    this.initialStreet,
    this.initialCity,
    this.initialState,
    this.initialCountry,
    this.initialZipCode,
    this.initialTags = const [],
    this.initialSiblings = const [],
    this.initialLegalCustodians = const [],
    this.initialSubsidy = false,
  });
  static const String routeName = '/edit-student-profile-details-screen';

  final String studentCode;
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
  final List<String> initialTags;
  final List<String> initialSiblings;
  final List<String> initialLegalCustodians;
  final bool initialSubsidy;

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
  String? _selectedAddressType;

  // API-backed options and mappings
  List<String> _availableTagNames = [];
  Map<String, String> _tagNameToCode = {};

  List<String> _availableStudentNames = [];
  Map<String, String> _studentNameToCode = {};

  List<String> _availableGuardianNames = [];
  final List<String> _statusOptions = ['Active', 'Inactive', 'Upcoming', 'Waitlist', 'Graduated'];
  final List<String> _stateSubsidyOptions = ['Yes', 'No'];
  final List<String> _addressTypeOptions = ['Current address', 'Permanent address', 'Other'];
  final List<String> _stateOptions =
      US_STATES.map((s) => s.name).toList(growable: false);
  // Country is fixed to United States for this form.

  // Simple validators (align with Add Staff)
  // First character A-Z, then up to 49 letters/space/hyphen/apostrophe.
  static final RegExp _nameRegex = RegExp(r"^[A-Za-z][A-Za-z\-'\s]{0,49}$");
  static final RegExp _fteRegex = RegExp(r"^(?:100|[1-9]?[0-9])$");
  static final RegExp _zipDigitsRegex = RegExp(r'^\d{5}(\d{4})?$'); // 5 or 9 digits (ZIP / ZIP+4)

  static String _digitsOnly(String input) => input.replaceAll(RegExp(r'\D'), '');

  String _displayNameWithOrdinal(String fullName, int index) {
    final cleanName = fullName.trim();
    if (index <= 1) return cleanName;
    return '$cleanName ($index)';
  }

  @override
  void initState() {
    super.initState();
    // Prefill when editing (use existing profile values; no mock defaults).
    _firstNameController.text = widget.initialFirstName ?? '';
    _lastNameController.text = widget.initialLastName ?? '';
    _notesController.text = widget.initialNotes ?? '';
    _FTEController.text = widget.initialFTE ?? '';
    _selectedStatus = widget.initialStatus;
    _selectedStateSubsidyOption = widget.initialSubsidy ? 'Yes' : 'No';
    _selectedClassroom = widget.initialClassroom;
    _selectedBirthDate = widget.initialBirthDate;
    _selectedTags = List<String>.from(widget.initialTags);
    _selectedSiblings = List<String>.from(widget.initialSiblings);
    _selectedChildCustody = List<String>.from(widget.initialLegalCustodians);
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

    // Country is fixed to United States on this screen.
    _selectedCountry = 'United States';

    // Accept legacy stored formats: "12345", "123456789", or "12345-6789"
    final initialZipRaw = widget.initialZipCode ?? '';
    _zipCodeController.text = _formatUsZipForDisplay(initialZipRaw);
    // Default address type to CURRENT; can be changed via dropdown.
    _selectedAddressType = _addressTypeOptions.first;

    // Load dynamic dropdown data
    _loadTags();
    _loadStudentsForSiblings();
    _loadGuardiansForCustody();
  }

  Future<void> _loadTags() async {
    try {
      final storage = serviceLocator<StorageService>();
      final schoolCode =
          await storage.getString(StorageKeys.schoolCode) ?? '';
      if (schoolCode.isEmpty) return;

      final namesUseCase =
          serviceLocator<GetTagNamesForSchoolUseCase>();
      final mapUseCase =
          serviceLocator<GetTagNameCodeMapForSchoolUseCase>();

      final names = await namesUseCase(schoolCode: schoolCode);
      final nameCodeMap = await mapUseCase(schoolCode: schoolCode);
      if (!mounted) return;

      setState(() {
        _availableTagNames = names;
        _tagNameToCode = nameCodeMap;
        // Drop any selected tags that no longer exist.
        _selectedTags.removeWhere((t) => !_availableTagNames.contains(t));
      });
    } catch (_) {
      // Non-critical for this form; keep selections as-is.
    }
  }

  Future<void> _loadStudentsForSiblings() async {
    try {
      final storage = serviceLocator<StorageService>();
      final schoolCode =
          await storage.getString(StorageKeys.schoolCode) ?? '';
      if (schoolCode.isEmpty) return;

      final repo = serviceLocator<StudentRepository>();

      // Always fetch from API (no cached student list for this dropdown).
      final page = await repo.getStudentPage(
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

      final baseNameCounts = <String, int>{};
      for (final row in rawRows) {
        final base = row['name']!;
        baseNameCounts[base] = (baseNameCounts[base] ?? 0) + 1;
      }
      final baseNameSeenIndex = <String, int>{};

      final nameToCode = <String, String>{};
      final codeToDisplay = <String, String>{};
      final names = <String>[];
      for (final row in rawRows) {
        final base = row['name']!;
        final code = row['code']!;
        final needsCode = (baseNameCounts[base] ?? 0) > 1;
        final seen = (baseNameSeenIndex[base] ?? 0) + 1;
        baseNameSeenIndex[base] = seen;
        final displayLabel =
            needsCode ? _displayNameWithOrdinal(base, seen) : base;
        names.add(displayLabel);
        nameToCode[displayLabel] = code;
        codeToDisplay[code] = displayLabel;
      }

      setState(() {
        _availableStudentNames = names;
        _studentNameToCode = nameToCode;

        // If initial siblings are codes, map them to names for display.
        if (widget.initialSiblings.isNotEmpty) {
          _selectedSiblings = widget.initialSiblings
              .map((code) => codeToDisplay[code] ?? code)
              .where((n) => n.trim().isNotEmpty)
              .toList();
        } else {
          // Ensure existing selected names still exist.
          _selectedSiblings
              .removeWhere((name) => !_availableStudentNames.contains(name));
        }
      });
    } catch (_) {
      // Non-critical; leave siblings dropdown empty.
    }
  }

  Future<void> _loadGuardiansForCustody() async {
    try {
      if (widget.studentCode.trim().isEmpty) return;
      final dataSource = serviceLocator<StudentRemoteDataSource>();
      final guardians =
          await dataSource.getStudentGuardians(studentCode: widget.studentCode);

      final rawRows = <Map<String, String>>[];
      for (final g in guardians) {
        final first = (g['firstName'] ?? '').toString().trim();
        final last = (g['lastName'] ?? '').toString().trim();
        final code = (g['guardianCode'] ?? g['code'] ?? '').toString().trim();
        final base = '$first $last'.trim();
        if (base.isEmpty) continue;
        rawRows.add(<String, String>{
          'name': base,
          'code': code,
        });
      }

      final baseNameCounts = <String, int>{};
      for (final row in rawRows) {
        final base = row['name']!;
        baseNameCounts[base] = (baseNameCounts[base] ?? 0) + 1;
      }
      final baseNameSeenIndex = <String, int>{};

      final names = <String>[];
      for (final row in rawRows) {
        final base = row['name']!;
        final needsCode = (baseNameCounts[base] ?? 0) > 1;
        final seen = (baseNameSeenIndex[base] ?? 0) + 1;
        baseNameSeenIndex[base] = seen;
        final displayLabel =
            needsCode ? _displayNameWithOrdinal(base, seen) : base;
        names.add(displayLabel);
      }
      if (!mounted) return;

      setState(() {
        _availableGuardianNames = names;
        _selectedChildCustody
            .removeWhere((g) => !_availableGuardianNames.contains(g));
      });
    } catch (_) {
      // Non-critical; keep any existing selections.
    }
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
    if (_selectedStatus == null || _selectedStatus!.trim().isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Status is required',
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
    // Birthdate: required and must be in the past
    if (_selectedBirthDate == null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Birthdate is required',
        isError: true,
      );
      return;
    } else {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      if (_selectedBirthDate!.isAfter(today.subtract(const Duration(days: 1)))) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Birthdate must be a past date',
          isError: true,
        );
        return;
      }
    }
    // Notes: optional, max 500 chars
    if (_notesController.text.trim().length > 500) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Notes cannot exceed 500 characters',
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

    final street = _streetController.text.trim();
    final city = _cityController.text.trim();
    final zipDigits = _digitsOnly(_zipCodeController.text);

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
    if (zipDigits.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Zip Code is required',
        isError: true,
      );
      return;
    }
    if (!_zipDigitsRegex.hasMatch(zipDigits)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Zip Code must be 5 digits (12345) or ZIP+4 (12345-6789)',
        isError: true,
      );
      return;
    }
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
    if (_selectedAddressType == null || _selectedAddressType!.trim().isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Address type is required',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

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

      final classrooms = classroomCubit?.state.classrooms ?? const <Classroom>[];
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

      // Map FTE to number
      int? fteNumber;
      if (fte.isNotEmpty) {
        fteNumber = int.tryParse(fte);
      }

      final repository = serviceLocator<StudentRepository>();

      // 1) Core profile PATCH /api/v1/student/{code}/profile
      final profilePayload = <String, dynamic>{
        'firstName': first,
        'lastName': last,
        'status': statusApi,
        if (dobFormatted != null) 'dob': dobFormatted,
        'notes': _notesController.text.trim(),
        if (fteNumber != null) 'fte': fteNumber,
        'subsidy': subsidy,
        // gender and profilePhotoUrl omitted for now (not in this form)
        'classroom': <String, dynamic>{
          'code': classroomCode,
          'name': selectedClassroomName,
        },
      };

      final message = await repository.updateStudentProfile(
        code: widget.studentCode,
        fields: profilePayload,
      );

      // 2) Address PATCH /api/v1/student/{studentCode}/address
      String _mapAddressTypeToApiValue(String uiLabel) {
        switch (uiLabel.toLowerCase()) {
          case 'current address':
            return 'CURRENT';
          case 'permanent address':
            // Keep backend's enum spelling.
            return 'PERMENENT';
          case 'other':
          default:
            return 'OTHER';
        }
      }

      final addressPayload = <String, dynamic>{
        'line1': street,
        'line2': _street2Controller.text.trim(),
        'street': street,
        'city': city,
        'state': stateCode,
        'country': countryCode,
        // Backend uses postalCode; UI display layer will format as needed.
        'postalCode': zipDigits,
        'addressType': _mapAddressTypeToApiValue(_selectedAddressType!),
      };

      await repository.updateStudentAddress(
        studentCode: widget.studentCode,
        fields: addressPayload,
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
          await repository.updateStudentTags(
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
        await repository.updateStudentSiblings(
          studentCode: widget.studentCode,
          siblingCodes: siblingCodes,
        );
      }

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });

      CoreUtils.showTopSnackBar(
        context: context,
        message: message,
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
      print('Error opening calendar dialog: $e');
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
        child: Builder(
          builder: (context) => _buildScreen(context),
        ),
      );
    }

    return _buildScreen(context);
  }

  Widget _buildScreen(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;

    ClassroomState classroomState;
    try {
      classroomState = context.watch<ClassroomCubit>().state;
    } catch (_) {
      classroomState = const ClassroomState.initial();
    }
    final classroomOptions =
        classroomState.classrooms.map((c) => c.name).toList(growable: false);

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
                        _buildCustomDropdown(
                          "Classroom",
                          (classroomState.isLoading && classroomOptions.isEmpty)
                              ? "Loading..."
                              : "Select",
                          classroomOptions,
                          selectedClassroomName,
                          (v) => setState(() => _selectedClassroom = v),
                          isRequired: true,
                        ),
                        SizedBox(height: responsive.verticalSpacing),
                        CustomMultiSelectDropdown(
                          label: 'Tags',
                          hintText: 'Select',
                          items: _availableTagNames,
                          selectedItems: _selectedTags,
                          onChanged: (tags) {
                            setState(() => _selectedTags = tags);
                          },
                          isField: true,
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
                        CustomMultiSelectDropdown(
                          label: 'Siblings',
                          hintText: 'Select student',
                          items: _availableStudentNames,
                          selectedItems: _selectedSiblings,
                          onChanged: (siblings) {
                            setState(() => _selectedSiblings = siblings);
                          },
                          maxDropdownHeight: 200,
                          isField: true,
                        ),
                        SizedBox(height: responsive.verticalSpacing),
                        CustomMultiSelectDropdown(
                          label: 'Child Custody',
                          hintText: 'Select guardian',
                          items: _availableGuardianNames,
                          selectedItems: _selectedChildCustody,
                          onChanged: (custodyOptions) {
                            setState(() => _selectedChildCustody = custodyOptions);
                          },
                          isField: true,
                        ),
                        SizedBox(height: responsive.verticalSpacing),
                        _buildCustomDropdown("State Subsidy", "Select", _stateSubsidyOptions, _selectedStateSubsidyOption, (v) => setState(() => _selectedStateSubsidyOption = v)),
                        SizedBox(height: responsive.verticalSpacing),
                        _buildCustomDropdown(
                          "Address Type",
                          "Select",
                          _addressTypeOptions,
                          _selectedAddressType,
                          (v) => setState(() => _selectedAddressType = v),
                          isRequired: true,
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
                              horizontal: responsive.isTablet ? 16.0 : 12.0,
                              vertical: responsive.isTablet ? 16.0 : 12.0,
                            ),
                            onSelect: null,
                          ),
                        ),
                        SizedBox(height: responsive.verticalSpacing),
                        _buildInputField(
                          "Zip Code",
                          "Eg. 85001 or 850012222",
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
