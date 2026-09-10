import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:wowcare/presentation/features/students/view/student_form_formatters.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_fonts.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_toggle.dart';
import 'package:wowcare/shared/common/widgets/relation_selector.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/student/usecases/get_guardian_names_for_school_usecase.dart';
import 'package:wowcare/presentation/features/students/view_model/student_pickup_cubit.dart';
import 'package:wowcare/presentation/features/students/student_strings.dart';

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

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _relationController = TextEditingController();

  late final GetGuardianNamesForSchoolUseCase _getGuardianNamesForSchoolUseCase;
  late final StorageService _storageService;

  /// One cubit instance for this screen so its single-flight mutation guard
  /// spans taps (serviceLocator registers it as a factory — a fresh call per
  /// tap would not dedupe).
  final StudentPickupCubit _pickupCubit = serviceLocator<StudentPickupCubit>();
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
      _firstNameController.text = (widget.initialFirstName ?? '').trim();
      _lastNameController.text = (widget.initialLastName ?? '').trim();
      _emailController.text = (widget.initialEmail ?? '').trim();
      _phoneController.text = _formatPhoneInput(
        (widget.initialPhoneNumber ?? '').trim(),
      );
      _relationController.text = (widget.initialRelation ?? '').trim();
      // Controllers stay local; the form model (toggle + relation) seeds the cubit.
      _pickupCubit.initializeForm(
        selectFromExisting: false,
        selectedRelation: (widget.initialRelation ?? '').trim().isEmpty
            ? null
            : (widget.initialRelation ?? '').trim(),
      );
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
    _pickupCubit.close();
    super.dispose();
  }

  Future<void> _loadExistingCarers() async {
    // The guardian display-names come from the same API the filters use (widget-
    // side); the cubit fetches the raw guardians + builds the name→details lookup.
    try {
      final schoolCode =
          await _storageService.getString(StorageKeys.schoolCode) ?? '';
      if (schoolCode.isEmpty) return;
      final names = await _getGuardianNamesForSchoolUseCase(
        schoolCode: schoolCode,
      );
      await _pickupCubit.loadCarers(schoolCode: schoolCode, names: names);
    } catch (_) {
      // Non-critical for pickups; keep the list empty on error.
    }
  }

  Future<void> _onSave() async {
    final formState = _pickupCubit.state;
    if (formState.selectFromExisting) {
      if (formState.selectedCarer == null || formState.selectedCarer!.isEmpty) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: StudentStrings.pleaseSelectACarer,
          isError: true,
        );
        return;
      }
      if ((formState.selectedRelation ?? '').trim().isEmpty) {
        CoreUtils.showTopSnackBar(
          context: context,
          message: StudentStrings.pleaseSelectARelation,
          isError: true,
        );
        return;
      }

      // Re-entry guard reads the cubit's own in-flight flag (single-flighted).
      if (_pickupCubit.state.mutationInProgress) return;

      try {
        // Call the same pickup POST API, using the selected guardian name
        // as first/last name. Other fields are left blank or defaulted,
        // but the payload shape matches the normal pickup create.
        final display = formState.selectedCarer!.trim();
        final guardian = formState.guardianDetailsByName[display];
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

        final relationEnum = (formState.selectedRelation ?? '')
            .trim()
            .toUpperCase()
            .replaceAll(' ', '_');
        final message = await _pickupCubit.add(
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
        context.pop(true);
      } catch (e) {
        if (!mounted) return;
        final msg = ApiErrorHandler.extractErrorMessage(e);
        CoreUtils.showTopSnackBar(
          context: context,
          message: msg,
          isError: true,
        );
      }
      return;
    }

    final first = _firstNameController.text.trim();
    final last = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final relation = _relationController.text.trim();
    final resolvedRelation = _resolveRelationForSubmit(relation);

    if (first.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: StudentStrings.firstNameIsRequired,
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
    if (!_nameRegex.hasMatch(first)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: StudentStrings.firstNameMustBeLettersOnlyAndMax50Characters,
        isError: true,
      );
      return;
    }
    if (!_nameRegex.hasMatch(last)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: StudentStrings.lastNameMustBeLettersOnlyAndMax50Characters,
        isError: true,
      );
      return;
    }
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: StudentStrings.pleaseEnterAValid10DigitPhoneNumber,
        isError: true,
      );
      return;
    }
    if (!_phoneRegex.hasMatch(phone)) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: StudentStrings.pleaseEnterPhoneAs0000000000,
        isError: true,
      );
      return;
    }
    if (relation.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: StudentStrings.relationIsRequired,
        isError: true,
      );
      return;
    }

    // Re-entry guard reads the cubit's own in-flight flag (single-flighted).
    if (_pickupCubit.state.mutationInProgress) return;

    try {
      final normalizedPhone = digits;

      final String message;
      if (_isEditLikeMode) {
        // Edit card flow must update existing pickup only.
        if (!_isEditMode) {
          throw Exception(
            'Pickup code is missing for edit. Please reopen the pickup card and try again.',
          );
        }
        message = await _pickupCubit.update(
          code: widget.pickupCode!.trim(),
          studentCode: widget.studentCode,
          firstName: first,
          lastName: last,
          email: email,
          phoneNumber: normalizedPhone,
          relation: resolvedRelation.relation,
          relationshipDescription: resolvedRelation.relationshipDescription,
          clockPin: (widget.initialClockPin ?? '').trim(),
          pickupType: 'CAREGIVER',
        );
      } else {
        message = await _pickupCubit.add(
          studentCode: widget.studentCode,
          firstName: first,
          lastName: last,
          email: email,
          phoneNumber: normalizedPhone,
          relation: resolvedRelation.relation,
          relationshipDescription: resolvedRelation.relationshipDescription,
          pickupType: 'CAREGIVER',
        );
      }

      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: message,
        isSuccess: true,
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      final msg = ApiErrorHandler.extractErrorMessage(e);
      CoreUtils.showTopSnackBar(context: context, message: msg, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final safeAreaBottom = bottomPadding > 0 ? bottomPadding : 16.0;

    return BlocBuilder<StudentPickupCubit, StudentPickupState>(
      bloc: _pickupCubit,
      builder: (context, state) => GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
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
                        _isEditMode
                            ? StudentStrings.editPickup
                            : StudentStrings.addPickup,
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
                          SizedBox(height: responsive.verticalSpacing),
                          if (!_isEditLikeMode) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  StudentStrings.selectFromExisting,
                                  style: TextStyle(
                                    fontSize: responsive.labelFontSize,
                                    fontFamily: AppFonts.body,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                                CustomToggle(
                                  label: '',
                                  isToggled: state.selectFromExisting,
                                  onToggle: (value) {
                                    _pickupCubit.setSelectFromExisting(value);
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: responsive.verticalSpacing),
                          ],
                          if (state.selectFromExisting && !_isEditLikeMode) ...[
                            CustomDropdown(
                              label: StudentStrings.carer,
                              hintText: StudentStrings.selectCarer,
                              items: state.existingCarers,
                              selectedItem: state.selectedCarer,
                              showAsterisk: true,
                              labelStyle: TextStyle(
                                fontSize: responsive.labelFontSize,
                                fontFamily: AppFonts.body,
                                fontWeight: FontWeight.w400,
                                color: AppColors.primaryColor,
                              ),
                              labelBottomSpacing: responsive.isTablet
                                  ? 8.0
                                  : 6.0,
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
                              onSelect: (val) =>
                                  _pickupCubit.setSelectedCarer(val),
                            ),
                            SizedBox(height: responsive.verticalSpacing),
                            RelationSelector(
                              initialRelation: widget.initialRelation,
                              labelBottomSpacing: responsive.isTablet
                                  ? 8.0
                                  : 6.0,
                              onChanged: (val) {
                                _pickupCubit.setSelectedRelation(val);
                                _relationController.text = (val ?? '').trim();
                              },
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInputField(
                                    label: StudentStrings.firstName,
                                    hint: StudentStrings.eGJohn,
                                    controller: _firstNameController,
                                    isRequired: true,
                                    textCapitalization:
                                        TextCapitalization.words,
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
                                    label: StudentStrings.lastName,
                                    hint: StudentStrings.eGSmith,
                                    controller: _lastNameController,
                                    isRequired: true,
                                    textCapitalization:
                                        TextCapitalization.words,
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
                              label: StudentStrings.email,
                              hint: StudentStrings.eGEmailExampleCom,
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            SizedBox(height: responsive.verticalSpacing),
                            _buildInputField(
                              label: StudentStrings.phoneNumber,
                              hint: StudentStrings.eG0000000000,
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
                              labelBottomSpacing: responsive.isTablet
                                  ? 8.0
                                  : 6.0,
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
              cancelButtonLabel: StudentStrings.cancel,
              onPressedConfirm: _onSave,
              onPressedCancel: () => context.pop(false),
              showCancelButton: true,
              isForm: false,
              isLoading: state.mutationInProgress,
            ),
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

  /// Resolves the `relation` field to send: a canonical enum drawn only
  /// from [RelationSelector.defaultRelationOptions] (the dropdown's fixed
  /// values), never arbitrary free text.
  ///
  /// [RelationSelector.onChanged] hands back the raw resolved string either
  /// way - a predefined option as-is, or (when "Other" was picked) whatever
  /// custom text the user typed in its reveal field - with no way for this
  /// caller to tell which case it is from the string alone. Naively
  /// enum-casing that string (uppercase + underscores) sent the free text
  /// straight through as `relation` (e.g. "family friend" ->
  /// "FAMILY_FRIEND", not a value the backend's relation enum recognizes).
  /// Only a match against the dropdown's own known options may become
  /// `relation`; anything else is the "Other" case and belongs in
  /// `relationshipDescription` instead, with `relation` fixed to 'OTHER'.
  ({String relation, String? relationshipDescription})
  _resolveRelationForSubmit(String raw) {
    for (final option in RelationSelector.defaultRelationOptions) {
      if (option.toUpperCase() == raw.toUpperCase()) {
        return (relation: option.toUpperCase(), relationshipDescription: null);
      }
    }
    return (
      relation: 'OTHER',
      relationshipDescription: raw.isEmpty ? null : raw,
    );
  }
}
