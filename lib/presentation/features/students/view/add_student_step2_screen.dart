import 'dart:async';
import 'package:wowcare/domain/features/student/entities/update_guardian_request.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:wowcare/presentation/features/students/view/student_form_formatters.dart';
import 'package:wowcare/core/utils/file_picker_utils.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_fonts.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/core/theme/app_radius.dart';
import 'package:wowcare/core/theme/app_dimensions.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/presentation/features/students/utils/profile_photo_background.dart';
import 'package:wowcare/presentation/features/students/view_model/student_create_cubit.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/student/usecases/get_guardian_names_for_school_usecase.dart';
import 'package:wowcare/presentation/features/students/student_strings.dart';

class AddStudentStep2Screen extends StatefulWidget {
  const AddStudentStep2Screen({
    super.key,
    this.initialSelectFromExisting = false,
    this.initialSelectedExistingParents = const [],
    this.initialFirstName,
    this.initialLastName,
    this.initialEmail,
    this.initialPhoneNumber,
    this.initialRelation,
    this.initialRelationOther,
    this.initialIsEmergencyContact = true,
    this.initialIsChildCustody = true,
    this.initialProfilePhoto,
    this.studentCode,
    this.schoolCode,
    this.createGuardianDirectly = false,
    this.editGuardianCode,
    this.initialUserCode,
    this.isOptionalStep = false,
  });

  static const String routeName = '/add-student-step2-screen';

  final bool initialSelectFromExisting;
  final List<String> initialSelectedExistingParents;
  final String? initialFirstName;
  final String? initialLastName;
  final String? initialEmail;
  final String? initialPhoneNumber;
  final String? initialRelation;
  final String? initialRelationOther;
  final bool initialIsEmergencyContact;
  final bool initialIsChildCustody;
  final File? initialProfilePhoto;
  final String? studentCode;
  final String? schoolCode;
  final bool createGuardianDirectly;
  final String? editGuardianCode;
  final String? initialUserCode;

  /// True when this screen is the (optional) Add Parent step inside the Add
  /// Student wizard — shows "(Optional)" in the heading. False for the
  /// standalone add/edit-guardian entry points on the Family tab.
  final bool isOptionalStep;

  @override
  _AddStudentStep2ScreenState createState() => _AddStudentStep2ScreenState();
}

class _AddStudentStep2ScreenState extends State<AddStudentStep2Screen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _relationOtherController =
      TextEditingController();

  static const int _nameMaxLength = 50;
  static final RegExp _nameRegex = RegExp(r"^[A-Za-z][A-Za-z\-'\s]{0,49}$");

  final StudentCreateCubit _createCubit = serviceLocator<StudentCreateCubit>();

  final List<String> _relationOptions = [
    'Mother',
    'Father',
    'Grandmother',
    'Grandfather',
    'Stepmother',
    'Stepfather',
    'Other',
  ];

  late final GetGuardianNamesForSchoolUseCase _getGuardianNamesForSchoolUseCase;
  late final StorageService _storageService;

  // Email validation regexes: strict and permissive; accept if any matches
  static final RegExp _emailRegexStrict = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static final RegExp _emailRegexPermissive = RegExp(
    r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$',
  );
  static final RegExp _phoneRegex = RegExp(r'^\(\d{3}\)\s\d{3}-\d{4}$');

  bool get _showRelationOther => _createCubit.state.step2Relation == 'Other';
  bool get _isEditMode =>
      widget.editGuardianCode != null &&
      widget.editGuardianCode!.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _getGuardianNamesForSchoolUseCase =
        serviceLocator<GetGuardianNamesForSchoolUseCase>();
    _storageService = serviceLocator<StorageService>();
    if (widget.initialFirstName != null) {
      _firstNameController.text = widget.initialFirstName!.trim();
    }
    if (widget.initialLastName != null) {
      _lastNameController.text = widget.initialLastName!.trim();
    }
    if (widget.initialEmail != null) {
      _emailController.text = widget.initialEmail!.trim();
    }
    if (widget.initialPhoneNumber != null) {
      _phoneController.text = _formatPhoneNumber(
        widget.initialPhoneNumber!.trim(),
      );
    }
    if (widget.initialRelationOther != null) {
      _relationOtherController.text = widget.initialRelationOther!.trim();
    }

    // Controllers stay local; the rest of the step-2 form model seeds the cubit.
    // Edit mode always uses the direct-parent form (no "select from existing").
    _createCubit.initializeStep2(
      selectFromExisting: _isEditMode
          ? false
          : widget.initialSelectFromExisting,
      selectedExistingParents: _isEditMode
          ? const <String>[]
          : List<String>.from(widget.initialSelectedExistingParents),
      relation: widget.initialRelation,
      isEmergencyContact: widget.initialIsEmergencyContact,
      isChildCustody: widget.initialIsChildCustody,
      profilePhoto: widget.initialProfilePhoto,
    );

    _loadExistingParents();
  }

  String _formatPhoneNumber(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 3) return digits;
    if (digits.length <= 6) {
      return '(${digits.substring(0, 3)}) ${digits.substring(3)}';
    }
    final take = digits.length >= 10 ? 10 : digits.length;
    final d = digits.substring(0, take);
    return '(${d.substring(0, 3)}) ${d.substring(3, 6)}-${d.substring(6)}';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _relationOtherController.dispose();
    _createCubit.close();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    try {
      // Shared file picker → every allowed image format is selectable
      // (jpeg/jpg/png/webp/heic/heif/avif/gif/bmp/tiff).
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
          message: StudentStrings.imageSizeMustBeLessThan10mb,
          isError: true,
        );
        return;
      }

      _createCubit.setStep2ProfilePhoto(file);
    } catch (e) {
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Failed to pick image: $e',
        isError: true,
      );
    }
  }

  void _trimAllInputs() {
    _firstNameController.text = _firstNameController.text.trim();
    _lastNameController.text = _lastNameController.text.trim();
    _emailController.text = _emailController.text.trim();
    _phoneController.text = _phoneController.text.trim();
    _relationOtherController.text = _relationOtherController.text.trim();
  }

  String? _validateEmail(String? value) {
    final raw = value ?? '';
    final trimmed = raw.trim().toLowerCase();

    if (trimmed.isEmpty) {
      return StudentStrings.emailIsRequired;
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

    if (!matches) {
      return StudentStrings.pleaseEnterAValidEmailAddress;
    }
    return null;
  }

  String? _validatePhoneNumber(String? value) {
    final raw = (value ?? '').trim();
    final digits = raw.replaceAll(RegExp(r'\D'), '');

    if (raw.isEmpty) {
      return StudentStrings.phoneNumberIsRequired;
    }
    if (digits.length != 10) {
      return StudentStrings.pleaseEnterAValid10DigitPhoneNumber;
    }
    if (!_phoneRegex.hasMatch(raw)) {
      return StudentStrings.pleaseEnterAValid10DigitPhoneNumber;
    }
    return null;
  }

  Future<void> _createGuardiansForExistingParents({
    required String schoolCode,
    required String studentCode,
  }) async {
    // Map display names back to guardian codes.
    final nameCodeMap = await _createCubit.fetchGuardianNameCodeMapForSchool(
      schoolCode: schoolCode,
    );

    final relationLabel = (_createCubit.state.step2Relation ?? '').trim();
    final relationOther = _relationOtherController.text.trim();
    final relationEnum = relationLabel.toUpperCase().replaceAll(' ', '_');
    final relationDescription =
        relationLabel == 'Other' && relationOther.isNotEmpty
        ? relationOther
        : null;

    for (final selected in _createCubit.state.step2SelectedExistingParents) {
      final key = selected.trim();
      if (key.isEmpty) continue;
      final guardianCode = nameCodeMap[key];
      if (guardianCode == null || guardianCode.isEmpty) continue;

      await _createCubit.linkExistingGuardian(
        guardianCode: guardianCode,
        studentCode: studentCode,
        relation: relationEnum,
        relationDescription: relationDescription,
      );
    }
  }

  Future<void> _loadExistingParents() async {
    try {
      // Prefer explicit schoolCode from widget; fall back to storage.
      String schoolCode = widget.schoolCode ?? '';
      if (schoolCode.isEmpty) {
        schoolCode =
            await _storageService.getString(StorageKeys.schoolCode) ?? '';
      }
      if (schoolCode.isEmpty) {
        return;
      }

      final names = await _getGuardianNamesForSchoolUseCase(
        schoolCode: schoolCode,
      );
      if (!mounted) return;
      // Cubit stores the names + prunes any now-stale selected parents.
      _createCubit.setStep2ExistingParents(names);
    } catch (_) {
      // Non-critical for this screen; ignore errors and keep list empty.
    }
  }

  void _onCancel() {
    if (_createCubit.state.step2Submitting) return;
    context.pop();
  }

  void _onNext() {
    _trimAllInputs();

    if (_createCubit.state.step2SelectFromExisting) {
      // Validate existing parents selection
      if (_createCubit.state.step2SelectedExistingParents.isEmpty) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: StudentStrings.pleaseSelectAtLeastOneParent,
          isError: true,
        );
        return;
      }
      if (_createCubit.state.step2Relation == null) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: StudentStrings.pleaseSelectARelation,
          isError: true,
        );
        return;
      }
      if (_createCubit.state.step2Relation == 'Other' &&
          _relationOtherController.text.trim().isEmpty) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: StudentStrings.pleaseSpecifyTheRelation,
          isError: true,
        );
        return;
      }
    } else {
      // Validate new parent form
      if (_firstNameController.text.isEmpty) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: StudentStrings.firstNameIsRequired2,
          isError: true,
        );
        return;
      }

      if (_firstNameController.text.length > _nameMaxLength) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'First name must be at most $_nameMaxLength characters',
          isError: true,
        );
        return;
      }
      if (!_nameRegex.hasMatch(_firstNameController.text)) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: StudentStrings.firstNameMustBeLettersOnlyAndMax50Characters,
          isError: true,
        );
        return;
      }

      if (_lastNameController.text.isEmpty) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: StudentStrings.lastNameIsRequired2,
          isError: true,
        );
        return;
      }

      if (_lastNameController.text.length > _nameMaxLength) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Last name must be at most $_nameMaxLength characters',
          isError: true,
        );
        return;
      }
      if (!_nameRegex.hasMatch(_lastNameController.text)) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: StudentStrings.lastNameMustBeLettersOnlyAndMax50Characters,
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

      if (_createCubit.state.step2Relation == null) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: StudentStrings.pleaseSelectARelation,
          isError: true,
        );
        return;
      }

      if (_createCubit.state.step2Relation == 'Other' &&
          _relationOtherController.text.trim().isEmpty) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: StudentStrings.pleaseSpecifyTheRelation,
          isError: true,
        );
        return;
      }
    }

    // If launched from Family tab to create guardian immediately
    final studentCode = widget.studentCode ?? '';
    final schoolCode = widget.schoolCode ?? '';
    if (widget.createGuardianDirectly &&
        studentCode.isNotEmpty &&
        schoolCode.isNotEmpty) {
      if (_createCubit.state.step2Submitting) return;
      _createCubit.setStep2Submitting(true);

      () async {
        try {
          if (_createCubit.state.step2SelectFromExisting) {
            // Use full guardian details from guardian API for existing parents.
            await _createGuardiansForExistingParents(
              schoolCode: schoolCode,
              studentCode: studentCode,
            );

            if (!mounted) return;
            CoreUtils.showTopSnackBar(
              context: context,
              message: StudentStrings.parentsLinkedSuccessfully,
              isSuccess: true,
            );
            context.pop(true);
          } else {
            final orgCode =
                await _storageService.getString(StorageKeys.organizationCode) ??
                '';
            final loggedInUserCode =
                await _storageService.getString(StorageKeys.userCode) ?? '';
            if (orgCode.trim().isEmpty) {
              if (!mounted) return;
              CoreUtils.showTopSnackBar(
                context: context,
                message: StudentStrings
                    .organizationIsMissingReSelectYourSchoolFromThe,
                isError: true,
              );
              return;
            }

            final first = _firstNameController.text.trim();
            final last = _lastNameController.text.trim();
            final email = _emailController.text.trim().toLowerCase();
            final rawPhone = _phoneController.text.trim();
            final digits = rawPhone.replaceAll(RegExp(r'\D'), '');

            final relationLabel = (_createCubit.state.step2Relation ?? '')
                .trim();
            final relationToStudent = relationLabel.toUpperCase();
            // Free-text description backing an "Other" relation — the
            // backend expects this whenever relationToStudent is OTHER.
            final relationshipDescription =
                relationLabel == 'Other' &&
                    _relationOtherController.text.trim().isNotEmpty
                ? _relationOtherController.text.trim()
                : null;

            final primaryContact = _createCubit.state.step2IsEmergencyContact;
            final legalCustody = _createCubit.state.step2IsChildCustody;
            final String message;
            if (_isEditMode) {
              final guardianCode = widget.editGuardianCode!.trim();
              message = await _createCubit.updateGuardian(
                code: guardianCode,
                studentCode: studentCode,
                request: UpdateGuardianRequest(
                  userCode: (widget.initialUserCode ?? '').trim(),
                  code: guardianCode,
                  schoolCode: schoolCode,
                  studentCode: studentCode,
                  firstName: first,
                  lastName: last,
                  email: email,
                  mobile: digits,
                  relationToStudent: relationToStudent,
                  relationshipDescription: relationshipDescription,
                  primaryContact: primaryContact,
                  legalCustody: legalCustody,
                  updatedBy: loggedInUserCode.trim(),
                ),
              );
              // Photo upload runs in the BACKGROUND so the form returns
              // instantly; it keeps going even after this screen is closed.
              final editFile = _createCubit.state.step2ProfilePhoto;
              if (editFile != null) {
                unawaited(
                  uploadGuardianPhotoInBackground(
                    file: editFile,
                    guardianCode: guardianCode,
                    studentCode: studentCode,
                    email: email,
                    mobile: digits,
                    schoolCode: schoolCode,
                    organizationCode: orgCode.trim(),
                    userCode: (widget.initialUserCode ?? '').trim(),
                  ),
                );
              }
            } else {
              // Create guardian FIRST, then upload the photo in the background
              // using the new code (resolved inside the detached task).
              final created = await _createCubit.createGuardianUser(
                schoolCode: schoolCode,
                studentCode: studentCode,
                firstName: first,
                lastName: last,
                email: email,
                mobile: digits,
                relationToStudent: relationToStudent,
                primaryContact: primaryContact,
                legalCustody: legalCustody,
                userCode: loggedInUserCode.trim().isEmpty
                    ? null
                    : loggedInUserCode.trim(),
                organizationCode: orgCode.trim(),
              );
              message = created.message;
              final createFile = _createCubit.state.step2ProfilePhoto;
              if (createFile != null) {
                unawaited(
                  uploadGuardianPhotoInBackground(
                    file: createFile,
                    guardianCode: (created.guardianCode ?? '').trim(),
                    studentCode: studentCode,
                    email: email,
                    mobile: digits,
                    schoolCode: schoolCode,
                    organizationCode: orgCode.trim(),
                    userCode: '',
                  ),
                );
              }
            }

            if (!mounted) return;
            CoreUtils.showTopSnackBar(
              context: context,
              message: _createCubit.state.step2ProfilePhoto != null
                  ? '$message Photo is uploading in the background…'
                  : message,
              isSuccess: true,
            );
            context.pop(true);
          }
        } catch (e) {
          if (!mounted) return;
          CoreUtils.showTopSnackBar(
            context: context,
            message: ApiErrorHandler.extractErrorMessage(e),
            isError: true,
          );
        } finally {
          if (mounted) {
            _createCubit.setStep2Submitting(false);
          }
        }
      }();
      return;
    }

    final step2Data = {
      'selectFromExisting': _createCubit.state.step2SelectFromExisting,
      'selectedExistingParents':
          _createCubit.state.step2SelectedExistingParents,
      'firstName': _createCubit.state.step2SelectFromExisting
          ? null
          : _firstNameController.text.trim(),
      'lastName': _createCubit.state.step2SelectFromExisting
          ? null
          : _lastNameController.text.trim(),
      'email': _createCubit.state.step2SelectFromExisting
          ? null
          : _emailController.text.trim().toLowerCase(),
      'phoneNumber': _createCubit.state.step2SelectFromExisting
          ? null
          : _phoneController.text.trim(),
      'relation': _createCubit.state.step2Relation,
      'relationOther': _showRelationOther
          ? _relationOtherController.text.trim()
          : null,
      'isEmergencyContact': _createCubit.state.step2IsEmergencyContact,
      'isChildCustody': _createCubit.state.step2IsChildCustody,
      'profilePhoto': _createCubit.state.step2ProfilePhoto,
    };

    context.pop(step2Data);
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;

    return BlocBuilder<StudentCreateCubit, StudentCreateState>(
      bloc: _createCubit,
      builder: (context, createState) => GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          backgroundColor: AppColors.whiteColor,
          appBar: const CustomAppBar(hasBackButton: false),
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
                        _isEditMode
                            ? StudentStrings.editParent
                            : (widget.isOptionalStep
                                  ? StudentStrings.addParentOptional
                                  : StudentStrings.addParent),
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
                      padding: EdgeInsets.all(
                        responsive.isTablet ? 32.0 : 16.0,
                      ),
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
                      child: Column(
                        children: [
                          Expanded(
                            child: ListView(
                              padding: EdgeInsets.zero,
                              children: [
                                SizedBox(height: responsive.verticalSpacing),
                                // Toggle is hidden in edit mode so the screen remains
                                // the same prefilled form UI as Add Step 2.
                                if (!_isEditMode) ...[
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        StudentStrings.selectFromExisting,
                                        style: TextStyle(
                                          fontSize: responsive.labelFontSize,
                                          fontFamily: Fonts.manrope,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.primaryColor,
                                        ),
                                      ),
                                      CustomToggle(
                                        label: '',
                                        isToggled: _createCubit
                                            .state
                                            .step2SelectFromExisting,
                                        onToggle: (value) => _createCubit
                                            .setStep2SelectFromExisting(value),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: responsive.verticalSpacing),
                                ],
                                // Show either existing parents dropdown or new parent form
                                if (_createCubit
                                    .state
                                    .step2SelectFromExisting) ...[
                                  // Existing parents multiselect
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        StudentStrings.selectParent2,
                                        style: TextStyle(
                                          fontSize: responsive.labelFontSize,
                                          fontFamily: Fonts.manrope,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.primaryColor,
                                        ),
                                      ),
                                      AppSpacing.gapVXs,
                                      // Single-select existing parent (searchable).
                                      // One parent only — store as a 0/1 list so the
                                      // downstream create/validation logic is unchanged.
                                      CustomDropdown(
                                        hintText: StudentStrings.selectParent,
                                        items: _createCubit
                                            .state
                                            .step2ExistingParents,
                                        enableSearch: true,
                                        selectedItem:
                                            _createCubit
                                                .state
                                                .step2SelectedExistingParents
                                                .isEmpty
                                            ? null
                                            : _createCubit
                                                  .state
                                                  .step2SelectedExistingParents
                                                  .first,
                                        onSelect: (selected) => _createCubit
                                            .setStep2SelectedExistingParents(
                                              selected == null
                                                  ? <String>[]
                                                  : <String>[selected],
                                            ),
                                      ),
                                      SizedBox(
                                        height: responsive.verticalSpacing,
                                      ),
                                      CustomDropdown(
                                        label: StudentStrings.relation,
                                        hintText: StudentStrings.select,
                                        items: _relationOptions,
                                        selectedItem:
                                            _createCubit.state.step2Relation,
                                        labelStyle: TextStyle(
                                          fontSize: responsive.labelFontSize,
                                          fontFamily: Fonts.manrope,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.primaryColor,
                                        ),
                                        showAsterisk: true,
                                        labelBottomSpacing: responsive.isTablet
                                            ? 8.0
                                            : 6.0,
                                        onSelect: (val) =>
                                            _createCubit.setStep2Relation(val),
                                      ),
                                      if (_showRelationOther) ...[
                                        SizedBox(
                                          height: responsive.verticalSpacing,
                                        ),
                                        _buildInputField(
                                          StudentStrings.specifyRelation,
                                          StudentStrings.egGrandmother,
                                          _relationOtherController,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                              RegExp(r"[A-Za-z\s\-']"),
                                            ),
                                            LengthLimitingTextInputFormatter(
                                              50,
                                            ),
                                            NameCapitalizationFormatter(),
                                            TrimFormatter(),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ] else ...[
                                  // New parent form
                                  _buildRowInputs(context),
                                  SizedBox(height: responsive.verticalSpacing),
                                  _buildInputField(
                                    StudentStrings.email,
                                    StudentStrings.eGNameExampleCom,
                                    _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    inputFormatters: [TrimFormatter()],
                                  ),
                                  SizedBox(height: responsive.verticalSpacing),
                                  _buildInputField(
                                    StudentStrings.phoneNumber,
                                    StudentStrings.eG0000000000,
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
                                  // Relation dropdown
                                  CustomDropdown(
                                    label: StudentStrings.relation,
                                    hintText: StudentStrings.select,
                                    items: _relationOptions,
                                    selectedItem:
                                        _createCubit.state.step2Relation,
                                    labelStyle: TextStyle(
                                      fontSize: responsive.labelFontSize,
                                      fontFamily: Fonts.manrope,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.primaryColor,
                                    ),
                                    showAsterisk: true,
                                    labelBottomSpacing: responsive.isTablet
                                        ? 8.0
                                        : 6.0,
                                    onSelect: (val) =>
                                        _createCubit.setStep2Relation(val),
                                  ),
                                  if (_showRelationOther) ...[
                                    SizedBox(
                                      height: responsive.verticalSpacing,
                                    ),
                                    _buildInputField(
                                      StudentStrings.specifyRelation,
                                      StudentStrings.egGrandmother,
                                      _relationOtherController,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r"[A-Za-z\s\-']"),
                                        ),
                                        LengthLimitingTextInputFormatter(50),
                                        NameCapitalizationFormatter(),
                                        TrimFormatter(),
                                      ],
                                    ),
                                  ],
                                  SizedBox(height: responsive.verticalSpacing),
                                  // Emergency Contact toggle
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        StudentStrings.emergencyContact,
                                        style: TextStyle(
                                          fontSize: responsive.labelFontSize,
                                          fontFamily: Fonts.manrope,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.primaryColor,
                                        ),
                                      ),
                                      CustomToggle(
                                        label: '',
                                        isToggled: _createCubit
                                            .state
                                            .step2IsEmergencyContact,
                                        onToggle: (value) => _createCubit
                                            .setStep2IsEmergencyContact(value),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: responsive.verticalSpacing),
                                  // Child Custody toggle
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        StudentStrings.childCustody,
                                        style: TextStyle(
                                          fontSize: responsive.labelFontSize,
                                          fontFamily: Fonts.manrope,
                                          fontWeight: FontWeight.w400,
                                          color: AppColors.primaryColor,
                                        ),
                                      ),
                                      CustomToggle(
                                        label: '',
                                        isToggled: _createCubit
                                            .state
                                            .step2IsChildCustody,
                                        onToggle: (value) => _createCubit
                                            .setStep2IsChildCustody(value),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: responsive.verticalSpacing),
                                  // Profile Photo
                                  _buildProfilePhotoField(responsive),
                                ],
                                AppSpacing.gapVSm,
                              ],
                            ),
                          ),
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
              onPressedConfirm: _createCubit.state.step2Submitting
                  ? null
                  : _onNext,
              cancelButtonLabel: StudentStrings.cancel,
              onPressedCancel: _createCubit.state.step2Submitting
                  ? null
                  : _onCancel,
              showCancelButton: true,
              isForm: false,
              isLoading: _createCubit.state.step2Submitting,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRowInputs(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return Row(
      children: [
        Expanded(
          child: _buildInputField(
            StudentStrings.firstName,
            StudentStrings.eGJohn,
            _firstNameController,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z\s\-']")),
              LengthLimitingTextInputFormatter(_nameMaxLength),
              NameCapitalizationFormatter(),
              TrimFormatter(),
            ],
          ),
        ),
        SizedBox(width: responsive.isTablet ? 24.0 : 16.0),
        Expanded(
          child: _buildInputField(
            StudentStrings.lastName,
            StudentStrings.eGSmith,
            _lastNameController,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z\s\-']")),
              LengthLimitingTextInputFormatter(_nameMaxLength),
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
            style: TextStyle(
              fontFamily: Fonts.manrope,
              fontSize: responsive.inputFontSize,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
              height: 19 / 14,
            ),
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
          ),
        ),
      ],
    );
  }

  Widget _buildProfilePhotoField(ResponsiveHelper responsive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          StudentStrings.profilePhoto,
          style: TextStyle(
            fontSize: responsive.labelFontSize,
            fontFamily: Fonts.manrope,
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
              color: AppColors.attendanceShimmerHighlightColor,
              borderRadius: AppRadius.allMd,
              border: Border.all(color: AppColors.inputBorderColor),
            ),
            child: _createCubit.state.step2ProfilePhoto != null
                ? ClipRRect(
                    borderRadius: AppRadius.allMd,
                    child: Image.file(
                      _createCubit.state.step2ProfilePhoto!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        color: AppColors.attendanceDialogHintTextColor,
                        size: AppDimensions.iconLg,
                      ),
                      AppSpacing.gapVXs,
                      Text(
                        StudentStrings.uploadPhoto,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.attendanceDialogHintTextColor,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        AppSpacing.gapVXxs,
        Text(
          StudentStrings.jpgPngMax10mbOptional,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.attendanceDialogHintTextColor,
            fontFamily: Fonts.manrope,
          ),
        ),
      ],
    );
  }
}
