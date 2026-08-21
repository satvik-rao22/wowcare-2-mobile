import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/common/widgets/relation_selector.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/student/usecases/get_guardian_names_for_school_usecase.dart';

class AddPickupScreen extends StatefulWidget {
  const AddPickupScreen({
    super.key,
    required this.studentCode,
    this.pickupCode,
    this.initialFirstName,
    this.initialLastName,
    this.initialEmail,
    this.initialPhoneNumber,
    this.initialRelation,
    this.initialClockPin,
  });

  static const String routeName = '/add-pickup-screen';

  final String studentCode;
  final String? pickupCode;
  final String? initialFirstName;
  final String? initialLastName;
  final String? initialEmail;
  final String? initialPhoneNumber;
  final String? initialRelation;
  final String? initialClockPin;

  @override
  State<AddPickupScreen> createState() => _AddPickupScreenState();
}

class _AddPickupScreenState extends State<AddPickupScreen> {
  static final RegExp _nameRegex = RegExp(r"^[A-Za-z][A-Za-z\-'\s]{0,49}$");
  static final RegExp _phoneRegex = RegExp(r'^\(\d{3}\)\s\d{3}-\d{4}$');

  bool _selectFromExisting = true;
  String? _selectedCarer;
  String? _selectedRelation;

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _relationController = TextEditingController();

  // Loaded from guardian API (same as filters & AddStudentStep2Screen).
  List<String> _existingCarers = const [];
  Map<String, Map<String, String>> _guardianDetailsByName = const {};

  late final GetGuardianNamesForSchoolUseCase _getGuardianNamesForSchoolUseCase;
  late final StorageService _storageService;
  bool get _isEditMode =>
      widget.pickupCode != null && widget.pickupCode!.trim().isNotEmpty;
  bool get _hasPrefillData =>
      (widget.initialFirstName ?? '').trim().isNotEmpty ||
      (widget.initialLastName ?? '').trim().isNotEmpty ||
      (widget.initialEmail ?? '').trim().isNotEmpty ||
      (widget.initialPhoneNumber ?? '').trim().isNotEmpty ||
      (widget.initialRelation ?? '').trim().isNotEmpty;
  bool get _isEditLikeMode => _isEditMode || _hasPrefillData;

  @override
  void initState() {
    super.initState();
    _getGuardianNamesForSchoolUseCase =
        serviceLocator<GetGuardianNamesForSchoolUseCase>();
    _storageService = serviceLocator<StorageService>();
    if (_isEditLikeMode) {
      _selectFromExisting = false;
      _firstNameController.text = (widget.initialFirstName ?? '').trim();
      _lastNameController.text = (widget.initialLastName ?? '').trim();
      _emailController.text = (widget.initialEmail ?? '').trim();
      _phoneController.text = _formatPhoneInput(
        (widget.initialPhoneNumber ?? '').trim(),
      );
      _relationController.text = (widget.initialRelation ?? '').trim();
      _selectedRelation = (widget.initialRelation ?? '').trim().isEmpty
          ? null
          : (widget.initialRelation ?? '').trim();
    } else {
      _loadExistingCarers();
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _relationController.dispose();
    super.dispose();
  }

  bool _isSubmitting = false;

  Future<void> _loadExistingCarers() async {
    try {
      // Use same guardian names API & payload as filters.
      String schoolCode =
          await _storageService.getString(StorageKeys.schoolCode) ?? '';
      if (schoolCode.isEmpty) {
        return;
      }

      final names = await _getGuardianNamesForSchoolUseCase(
        schoolCode: schoolCode,
      );
      final repo = serviceLocator<StudentRepository>();
      final rawGuardians = await repo.getGuardiansRawForSchool(
        schoolCode: schoolCode,
      );
      final details = <String, Map<String, String>>{};
      for (final g in rawGuardians) {
        final first = (g['firstName'] ?? '').toString().trim();
        final last = (g['lastName'] ?? '').toString().trim();
        final email = (g['email'] ?? '').toString().trim();
        final mobile = (g['mobile'] ?? '').toString().trim();
        final code = (g['code'] ?? '').toString().trim();
        final display = '$first $last'.trim();
        if (display.isEmpty) continue;
        details[display] = <String, String>{
          'code': code,
          'firstName': first,
          'lastName': last,
          'email': email,
          'mobile': mobile,
        };
      }
      if (!mounted) return;

      setState(() {
        _existingCarers = names;
        _guardianDetailsByName = details;
        if (_selectedCarer != null &&
            !_existingCarers.contains(_selectedCarer)) {
          _selectedCarer = null;
        }
      });
    } catch (_) {
      // Non-critical for pickups; keep list empty on error.
    }
  }

  Future<void> _onSave() async {
    if (_selectFromExisting) {
      if (_selectedCarer == null || _selectedCarer!.isEmpty) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Please select a carer',
          isError: true,
        );
        return;
      }
      if ((_selectedRelation ?? '').trim().isEmpty) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: 'Please select a relation',
          isError: true,
        );
        return;
      }

      if (_isSubmitting) return;
      setState(() {
        _isSubmitting = true;
      });

      try {
        // Call the same pickup POST API, using the selected guardian name
        // as first/last name. Other fields are left blank or defaulted,
        // but the payload shape matches the normal pickup create.
        final display = _selectedCarer!.trim();
        final guardian = _guardianDetailsByName[display];
        final parts = display
            .split(' ')
            .where((e) => e.trim().isNotEmpty)
            .toList();
        final first = (guardian?['firstName'] ?? '').trim().isNotEmpty
            ? guardian!['firstName']!.trim()
            : (parts.isEmpty ? display : parts.first);
        final last = (guardian?['lastName'] ?? '').trim().isNotEmpty
            ? guardian!['lastName']!.trim()
            : (parts.length > 1 ? parts.sublist(1).join(' ').trim() : '');

        final guardianCode = (guardian?['code'] ?? '').trim();
        final email = (guardian?['email'] ?? '').trim();
        final mobileDigits = (guardian?['mobile'] ?? '').replaceAll(
          RegExp(r'\D'),
          '',
        );

        final relationEnum = (_selectedRelation ?? '')
            .trim()
            .toUpperCase()
            .replaceAll(' ', '_');
        final repo = serviceLocator<StudentRepository>();
        final message = await repo.addPickup(
          studentCode: widget.studentCode,
          firstName: first,
          lastName: last,
          email: email,
          phoneNumber: mobileDigits,
          relation: relationEnum.isEmpty ? 'OTHER' : relationEnum,
          pickupType: 'CARPOOL',
          carpoolId: guardianCode,
        );

        if (!mounted) return;
        CoreUtils.showTopSnackBar(
          context: context,
          message: message,
          isSuccess: true,
        );
        Navigator.pop(context, true);
      } catch (e) {
        if (!mounted) return;
        final msg = ApiErrorHandler.extractErrorMessage(e);
        CoreUtils.showTopSnackBar(
          context: context,
          message: msg,
          isError: true,
        );
        setState(() {
          _isSubmitting = false;
        });
      }
      return;
    }

    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final relation = _relationController.text.trim();
    final normalizedRelation = _toRelationEnum(relation);

    if (first.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'First Name is required',
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
    if (!_nameRegex.hasMatch(first)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'First name must be letters only and max 50 characters',
        isError: true,
      );
      return;
    }
    if (!_nameRegex.hasMatch(last)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Last name must be letters only and max 50 characters',
        isError: true,
      );
      return;
    }
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please enter a valid 10-digit phone number',
        isError: true,
      );
      return;
    }
    if (!_phoneRegex.hasMatch(phone)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please enter phone as (000) 000-0000',
        isError: true,
      );
      return;
    }
    if (relation.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Relation is required',
        isError: true,
      );
      return;
    }

    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final normalizedPhone = digits;

      final repo = serviceLocator<StudentRepository>();
      final String message;
      if (_isEditLikeMode) {
        // Edit card flow must update existing pickup only.
        if (!_isEditMode) {
          throw Exception(
            'Pickup code is missing for edit. Please reopen the pickup card and try again.',
          );
        }
        message = await repo.updatePickup(
          code: widget.pickupCode!.trim(),
          studentCode: widget.studentCode,
          firstName: first,
          lastName: last,
          email: email,
          phoneNumber: normalizedPhone,
          relation: normalizedRelation,
          clockPin: (widget.initialClockPin ?? '').trim(),
          pickupType: 'CAREGIVER',
        );
      } else {
        message = await repo.addPickup(
          studentCode: widget.studentCode,
          firstName: first,
          lastName: last,
          email: email,
          phoneNumber: normalizedPhone,
          relation: normalizedRelation,
          pickupType: 'CAREGIVER',
        );
      }

      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: message,
        isSuccess: true,
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final msg = ApiErrorHandler.extractErrorMessage(e);
      CoreUtils.showTopSnackBar(context: context, message: msg, isError: true);
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.white,
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
                      _isEditMode ? 'Edit Pickup' : 'Add Pickup',
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
                    padding: EdgeInsets.all(responsive.isTablet ? 32.0 : 16.0),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.all(
                        Radius.circular(responsive.isTablet ? 40.0 : 24.0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        SizedBox(height: responsive.verticalSpacing),
                        if (!_isEditLikeMode) ...[
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
                        ],
                        if (_selectFromExisting && !_isEditLikeMode) ...[
                          CustomDropdown(
                            label: 'Carer',
                            hintText: 'Select Carer',
                            items: _existingCarers,
                            selectedItem: _selectedCarer,
                            showAsterisk: true,
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
                            onSelect: (val) => setState(() {
                              _selectedCarer = val;
                            }),
                          ),
                          SizedBox(height: responsive.verticalSpacing),
                          RelationSelector(
                            initialRelation: widget.initialRelation,
                            labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
                            onChanged: (val) {
                              setState(() {
                                _selectedRelation = val;
                                _relationController.text = (val ?? '').trim();
                              });
                            },
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: _buildInputField(
                                  label: 'First Name',
                                  hint: 'E.g. John',
                                  controller: _firstNameController,
                                  isRequired: true,
                                  textCapitalization: TextCapitalization.words,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r"[A-Za-z\s'-]"),
                                    ),
                                    LengthLimitingTextInputFormatter(50),
                                    NameCapitalizationFormatter(),
                                    TrimFormatter(),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: responsive.isTablet ? 24.0 : 16.0,
                              ),
                              Expanded(
                                child: _buildInputField(
                                  label: 'Last Name',
                                  hint: 'E.g. Smith',
                                  controller: _lastNameController,
                                  isRequired: true,
                                  textCapitalization: TextCapitalization.words,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r"[A-Za-z\s'-]"),
                                    ),
                                    LengthLimitingTextInputFormatter(50),
                                    NameCapitalizationFormatter(),
                                    TrimFormatter(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: responsive.verticalSpacing),
                          _buildInputField(
                            label: 'Email',
                            hint: 'E.g. email@example.com',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          SizedBox(height: responsive.verticalSpacing),
                          _buildInputField(
                            label: 'Phone Number',
                            hint: 'E.g. (000) 000-0000',
                            controller: _phoneController,
                            isRequired: true,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                              PhoneNumberFormatter(),
                              TrimFormatter(),
                            ],
                          ),
                          SizedBox(height: responsive.verticalSpacing),
                          RelationSelector(
                            initialRelation: widget.initialRelation,
                            labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
                            onChanged: (val) {
                              setState(() {
                                _relationController.text = (val ?? '').trim();
                              });
                            },
                          ),
                        ],
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
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.05),
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
            cancelButtonLabel: 'Cancel',
            onPressedConfirm: _onSave,
            onPressedCancel: () => Navigator.pop(context, false),
            showCancelButton: true,
            isForm: false,
            isLoading: _isSubmitting,
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
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
                  style: TextStyle(color: AppColors.red),
                ),
            ],
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        Container(
          constraints: BoxConstraints(minHeight: responsive.inputFieldHeight),
          decoration: BoxDecoration(
            color: AppColors.white,
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
              hintStyle: labelStyle.copyWith(color: AppColors.grey),
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

  String _formatPhoneInput(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length <= 3) return digits;
    if (digits.length <= 6) {
      return '(${digits.substring(0, 3)}) ${digits.substring(3)}';
    }
    final take = digits.length >= 10 ? 10 : digits.length;
    final d = digits.substring(0, take);
    return '(${d.substring(0, 3)}) ${d.substring(3, 6)}-${d.substring(6)}';
  }

  String _toRelationEnum(String raw) {
    final normalized = raw.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '_');
    return normalized.isEmpty ? 'OTHER' : normalized;
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
      formattedText =
          '(${digitsOnly.substring(0, 3)}) ${digitsOnly.substring(3)}';
    } else {
      formattedText =
          '(${digitsOnly.substring(0, 3)}) ${digitsOnly.substring(3, 6)}-${digitsOnly.substring(6)}';
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
    text = text.replaceFirst(RegExp(r"\s+"), ' ');
    text = text.replaceAll(RegExp(r"\s{2,}"), ' ');
    text = text.replaceAll(RegExp(r"\s+\z"), '');

    if (text.isEmpty) {
      return newValue.copyWith(
        text: text,
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

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
