import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_multi_select_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/student/usecases/get_guardian_names_for_school_usecase.dart';

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

  @override
  _AddStudentStep2ScreenState createState() => _AddStudentStep2ScreenState();
}

class _AddStudentStep2ScreenState extends State<AddStudentStep2Screen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _relationOtherController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  static const int _nameMaxLength = 50;

  bool _selectFromExisting = false;
  List<String> _selectedExistingParents = [];
  String? _selectedRelation;
  bool _isEmergencyContact = true;
  bool _isChildCustody = true;
  File? _profilePhoto;
  bool _isSubmitting = false;

  final List<String> _relationOptions = [
    'Mother',
    'Father',
    'Grandmother',
    'Grandfather',
    'Stepmother',
    'Stepfather',
    'Other',
  ];
  List<String> _existingParents = const [];

  late final GetGuardianNamesForSchoolUseCase _getGuardianNamesForSchoolUseCase;
  late final StorageService _storageService;

  // Email validation regexes: strict and permissive; accept if any matches
  static final RegExp _emailRegexStrict = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static final RegExp _emailRegexPermissive = RegExp(
    r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$',
  );

  bool get _showRelationOther => _selectedRelation == 'Other';

  @override
  void initState() {
    super.initState();
    _getGuardianNamesForSchoolUseCase =
        serviceLocator<GetGuardianNamesForSchoolUseCase>();
    _storageService = serviceLocator<StorageService>();
    _selectFromExisting = widget.initialSelectFromExisting;
    _selectedExistingParents = List<String>.from(widget.initialSelectedExistingParents);
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
      _phoneController.text = widget.initialPhoneNumber!.trim();
    }
    _selectedRelation = widget.initialRelation;
    if (widget.initialRelationOther != null) {
      _relationOtherController.text = widget.initialRelationOther!.trim();
    }
    _isEmergencyContact = widget.initialIsEmergencyContact;
    _isChildCustody = widget.initialIsChildCustody;
    _profilePhoto = widget.initialProfilePhoto;

    _loadExistingParents();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _relationOtherController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image == null) return;

      final file = File(image.path);
      final fileSizeInMB = await file.length() / (1024 * 1024);

      if (fileSizeInMB > 10) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Image size must be less than 10MB',
          isError: true,
        );
        return;
      }

      setState(() {
        _profilePhoto = file;
      });
    } catch (e) {
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
      return 'Email is required';
    }

    final hasAt = trimmed.contains('@');
    final hasDot = trimmed.contains('.') && trimmed.lastIndexOf('.') > trimmed.indexOf('@');
    final strictMatch = _emailRegexStrict.hasMatch(trimmed);
    final permissiveMatch = _emailRegexPermissive.hasMatch(trimmed);
    final matches = strictMatch || permissiveMatch || (hasAt && hasDot && trimmed.length >= 6);
    
    if (!matches) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePhoneNumber(String? value) {
    final raw = (value ?? '').trim();
    final digits = raw.replaceAll(RegExp(r'\D'), '');

    if (raw.isEmpty) {
      return 'Phone number is required';
    }
    if (digits.length != 10) {
      return 'Please enter a valid 10-digit phone number';
    }
    return null;
  }

  Future<void> _createGuardiansForExistingParents({
    required String schoolCode,
    required String studentCode,
  }) async {
    final repo = serviceLocator<StudentRepository>();
    // Map display names back to guardian codes.
    final nameCodeMap =
        await repo.getGuardianNameCodeMapForSchool(schoolCode: schoolCode);

    for (final selected in _selectedExistingParents) {
      final key = selected.trim();
      if (key.isEmpty) continue;
      final guardianCode = nameCodeMap[key];
      if (guardianCode == null || guardianCode.isEmpty) continue;

      await repo.linkExistingGuardian(
        guardianCode: guardianCode,
        studentCode: studentCode,
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

      final names =
          await _getGuardianNamesForSchoolUseCase(schoolCode: schoolCode);
      if (!mounted) return;

      setState(() {
        _existingParents = names;
        // Ensure initially selected parents still exist in the latest list.
        _selectedExistingParents.removeWhere(
          (parent) => !_existingParents.contains(parent),
        );
      });
    } catch (_) {
      // Non-critical for this screen; ignore errors and keep list empty.
    }
  }

  void _onNext() {
    _trimAllInputs();

    if (_selectFromExisting) {
      // Validate existing parents selection
      if (_selectedExistingParents.isEmpty) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Please select at least one parent',
          isError: true,
        );
        return;
      }
    } else {
      // Validate new parent form
      if (_firstNameController.text.isEmpty) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'First name is required',
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

      if (_lastNameController.text.isEmpty) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Last name is required',
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

      if (_selectedRelation == null) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Please select a relation',
          isError: true,
        );
        return;
      }

      if (_selectedRelation == 'Other' &&
          _relationOtherController.text.trim().isEmpty) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Please specify the relation',
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
      if (_isSubmitting) return;
      setState(() => _isSubmitting = true);

      () async {
        try {
          if (_selectFromExisting) {
            // Use full guardian details from guardian API for existing parents.
            await _createGuardiansForExistingParents(
              schoolCode: schoolCode,
              studentCode: studentCode,
            );

            if (!mounted) return;
            CoreUtils.showTopSnackBar(
              context: context,
              message: 'Parents linked successfully',
              isSuccess: true,
            );
            Navigator.pop(context, true);
          } else {
            final repo = serviceLocator<StudentRepository>();
            final first = _firstNameController.text.trim();
            final last = _lastNameController.text.trim();
            final email = _emailController.text.trim().toLowerCase();
            final rawPhone = _phoneController.text.trim();
            final digits = rawPhone.replaceAll(RegExp(r'\D'), '');

            final relationLabel = (_selectedRelation ?? '').trim();
            final relationOther = _relationOtherController.text.trim();
            final relationToStudent =
                (relationLabel == 'Other' && relationOther.isNotEmpty
                        ? relationOther
                        : relationLabel)
                    .toUpperCase();

            final primaryContact = _isEmergencyContact;
            final legalCustody = _isChildCustody;

            final message = await repo.createGuardianUser(
              schoolCode: schoolCode,
              studentCode: studentCode,
              firstName: first,
              lastName: last,
              email: email,
              mobile: digits,
              relationToStudent: relationToStudent,
              primaryContact: primaryContact,
              legalCustody: legalCustody,
            );

            if (!mounted) return;
            CoreUtils.showTopSnackBar(
              context: context,
              message: message,
              isSuccess: true,
            );
            Navigator.pop(context, true);
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
            setState(() => _isSubmitting = false);
          }
        }
      }();
      return;
    }

    final step2Data = {
      'selectFromExisting': _selectFromExisting,
      'selectedExistingParents': _selectedExistingParents,
      'firstName': _selectFromExisting ? null : _firstNameController.text.trim(),
      'lastName': _selectFromExisting ? null : _lastNameController.text.trim(),
      'email': _selectFromExisting ? null : _emailController.text.trim().toLowerCase(),
      'phoneNumber': _selectFromExisting ? null : _phoneController.text.trim(),
      'relation': _selectedRelation,
      'relationOther': _showRelationOther ? _relationOtherController.text.trim() : null,
      'isEmergencyContact': _isEmergencyContact,
      'isChildCustody': _isChildCustody,
      'profilePhoto': _profilePhoto,
    };

    Navigator.pop(context, step2Data);
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
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
                      'Add parent',
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
                    margin: EdgeInsets.symmetric(horizontal: responsive.horizontalSpacing),
                    padding: EdgeInsets.all(responsive.isTablet ? 32.0 : 16.0),
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
                        Expanded(
                          child: ListView(
                            padding: EdgeInsets.zero,
                            children: [
                              SizedBox(height: responsive.verticalSpacing),
                              // Toggle: Select from existing
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Select from existing',
                                    style: TextStyle(
                                      fontSize: responsive.labelFontSize,
                                      fontFamily: "Manrope",
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xff573353),
                                    ),
                                  ),
                                  CustomToggle(
                                    label: '',
                                    isToggled: _selectFromExisting,
                                    onToggle: (value) {
                                      setState(() {
                                        _selectFromExisting = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: responsive.verticalSpacing),
                              // Show either existing parents dropdown or new parent form
                              if (_selectFromExisting) ...[
                                // Existing parents multiselect
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Select Parents',
                                      style: TextStyle(
                                        fontSize: responsive.labelFontSize,
                                        fontFamily: "Manrope",
                                        fontWeight: FontWeight.w400,
                                        color: const Color(0xff573353),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    CustomMultiSelectDropdown(
                                      hintText: 'Select parents',
                                      items: _existingParents,
                                      selectedItems: _selectedExistingParents,
                                      onChanged: (selected) {
                                        setState(() {
                                          _selectedExistingParents = selected;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ] else ...[
                                // New parent form
                                _buildRowInputs(context),
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
                                // Relation dropdown
                                CustomDropdown(
                                  label: "Relation",
                                  hintText: 'Select',
                                  items: _relationOptions,
                                  selectedItem: _selectedRelation,
                                  labelStyle: TextStyle(
                                    fontSize: responsive.labelFontSize,
                                    fontFamily: "Manrope",
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xff573353),
                                  ),
                                  showAsterisk: true,
                                  labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
                                  onSelect: (val) {
                                    setState(() {
                                      _selectedRelation = val;
                                    });
                                  },
                                ),
                                if (_showRelationOther) ...[
                                  SizedBox(height: responsive.verticalSpacing),
                                  _buildInputField(
                                    "Specify Relation",
                                    "E.g. Grandmother",
                                    _relationOtherController,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(RegExp(r"[A-Za-z\s\-']")),
                                      LengthLimitingTextInputFormatter(50),
                                      NameCapitalizationFormatter(),
                                      TrimFormatter(),
                                    ],
                                  ),
                                ],
                                SizedBox(height: responsive.verticalSpacing),
                                // Emergency Contact toggle
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Emergency Contact',
                                      style: TextStyle(
                                        fontSize: responsive.labelFontSize,
                                        fontFamily: "Manrope",
                                        fontWeight: FontWeight.w400,
                                        color: const Color(0xff573353),
                                      ),
                                    ),
                                    CustomToggle(
                                      label: '',
                                      isToggled: _isEmergencyContact,
                                      onToggle: (value) {
                                        setState(() {
                                          _isEmergencyContact = value;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                SizedBox(height: responsive.verticalSpacing),
                                // Child Custody toggle
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Child Custody',
                                      style: TextStyle(
                                        fontSize: responsive.labelFontSize,
                                        fontFamily: "Manrope",
                                        fontWeight: FontWeight.w400,
                                        color: const Color(0xff573353),
                                      ),
                                    ),
                                    CustomToggle(
                                      label: '',
                                      isToggled: _isChildCustody,
                                      onToggle: (value) {
                                        setState(() {
                                          _isChildCustody = value;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                SizedBox(height: responsive.verticalSpacing),
                                // Profile Photo
                                _buildProfilePhotoField(responsive),
                              ],
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
            confirmButtonLabel: 'ADD',
            onPressedConfirm: _isSubmitting ? null : _onNext,
            showCancelButton: false,
            isForm: false,
            isLoading: _isSubmitting,
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
            "First Name",
            "E.g. John",
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
            "Last Name",
            "E.g. Smith",
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
            borderRadius: BorderRadius.circular(responsive.isTablet ? 12.0 : 8.0),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: responsive.inputFontSize,
              fontWeight: FontWeight.w600,
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

  Widget _buildProfilePhotoField(ResponsiveHelper responsive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile Photo',
          style: TextStyle(
            fontSize: responsive.labelFontSize,
            fontFamily: "Manrope",
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
                    child: Image.file(
                      _profilePhoto!,
                      fit: BoxFit.cover,
                    ),
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
      return newValue.copyWith(
        text: text,
        selection: const TextSelection.collapsed(offset: 0),
      );
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
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final trimmed = newValue.text.trimLeft();
    return TextEditingValue(
      text: trimmed,
      selection: TextSelection.collapsed(offset: trimmed.length),
    );
  }
}

