import 'package:flutter/material.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/core/theme/app_radius.dart';
import 'package:wowcare/core/theme/app_dimensions.dart';
import 'package:wowcare/presentation/features/students/module_access.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/student/entities/student_guardian.dart';
import 'package:wowcare/presentation/features/students/view_model/student_guardian_cubit.dart';
import 'package:wowcare/presentation/features/students/student_strings.dart';
import 'package:wowcare/presentation/features/students/widgets/change_guardian_pin_dialog.dart';
import 'package:wowcare/presentation/features/students/widgets/guardian_action_panel.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/gradient_add_button.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/presentation/features/students/view/add_student_step2_screen.dart';
import 'package:wowcare/shared/common/widgets/delete_confirmation_bottom_sheet.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

class StudentFamilyTabCard extends StatefulWidget {
  const StudentFamilyTabCard({
    required this.scrollController,
    required this.name,
    required this.classroom,
    this.studentCode,
    this.schoolCode,
    this.onRefresh,
    super.key,
  });

  final ScrollController scrollController;
  final String name;
  final String classroom;
  final String? studentCode;
  final String? schoolCode;
  final Future<void> Function()? onRefresh;

  @override
  State<StudentFamilyTabCard> createState() => _StudentFamilyTabCardState();
}

class _StudentFamilyTabCardState extends State<StudentFamilyTabCard> {
  static const int _maxParentsPerStudent = 4;

  bool _isMutating = false;

  /// One cubit instance for this card so its single-flight delete guard spans
  /// taps (serviceLocator registers it as a factory — a fresh call per tap
  /// would not dedupe).
  final StudentGuardianCubit _guardianCubit =
      serviceLocator<StudentGuardianCubit>();

  String _extractGuardianClockPin(StudentGuardian guardian) {
    final raw = (guardian.clockPin ?? '').trim();
    return raw.isEmpty ? '—' : raw;
  }

  String _formatPhoneNumber(String? raw) {
    final digits = (raw ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) {
      return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
    }
    return (raw ?? '').trim().isEmpty ? '-' : raw!.trim();
  }

  Future<String> _resolveSchoolCode() async {
    final direct = (widget.schoolCode ?? '').trim();
    if (direct.isNotEmpty) return direct;

    final storage = serviceLocator<StorageService>();
    final fromStorage = (await storage.getString(StorageKeys.schoolCode) ?? '')
        .trim();
    if (fromStorage.isNotEmpty) return fromStorage;

    return '';
  }

  @override
  void initState() {
    super.initState();
    _guardianCubit.load(widget.studentCode ?? '');
  }

  @override
  void dispose() {
    _guardianCubit.close();
    super.dispose();
  }

  /// Reload the cubit-owned guardian list, then notify the parent.
  Future<void> _reload({bool force = false}) async {
    await _guardianCubit.load(widget.studentCode ?? '', forceRefresh: force);
    await widget.onRefresh?.call();
  }

  Future<void> _onAddParent() async {
    final studentCode = widget.studentCode ?? '';
    final schoolCode = await _resolveSchoolCode();
    if (studentCode.isEmpty || schoolCode.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: StudentStrings.studentDetailsNotLoadedYetPleaseTryAgain,
        isError: true,
      );
      return;
    }

    final existing = _guardianCubit.state.guardians;
    if (existing.length >= _maxParentsPerStudent) {
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message:
            'You can add up to $_maxParentsPerStudent parents or guardians per student.',
        isError: true,
      );
      return;
    }

    final result = await context.push<bool>(
      AddStudentStep2Screen.routeName,
      extra: <String, dynamic>{
        'studentCode': studentCode,
        'schoolCode': schoolCode,
        'createGuardianDirectly': true,
      },
    );

    if (!mounted || result != true) return;

    await _reload();
  }

  Future<void> _onEditParent(StudentGuardian guardian) async {
    final studentCode = widget.studentCode ?? '';
    final schoolCode = widget.schoolCode ?? '';
    final guardianCode = guardian.guardianCode.trim();
    if (studentCode.isEmpty || schoolCode.isEmpty || guardianCode.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: StudentStrings.guardianDetailsAreNotLoadedYetPleaseTryAgain,
        isError: true,
      );
      return;
    }

    final rawRelation = guardian.relationToStudent.trim();
    const relationOptions = <String>{
      'Mother',
      'Father',
      'Grandmother',
      'Grandfather',
      'Stepmother',
      'Stepfather',
      'Other',
    };
    final normalizedRelation = rawRelation.isEmpty
        ? null
        : '${rawRelation[0].toUpperCase()}${rawRelation.substring(1).toLowerCase()}';
    final isKnownRelation =
        normalizedRelation != null &&
        relationOptions.contains(normalizedRelation);

    final result = await context.push<bool>(
      AddStudentStep2Screen.routeName,
      extra: <String, dynamic>{
        'studentCode': studentCode,
        'schoolCode': schoolCode,
        'createGuardianDirectly': true,
        'editGuardianCode': guardianCode,
        'initialUserCode': guardian.userCode.trim(),
        'initialFirstName': guardian.firstName,
        'initialLastName': guardian.lastName,
        'initialEmail': guardian.email,
        'initialPhoneNumber': guardian.mobile,
        'initialRelation': isKnownRelation ? normalizedRelation : 'Other',
        'initialRelationOther': isKnownRelation
            ? null
            : (rawRelation.isEmpty ? null : rawRelation),
        'initialIsEmergencyContact': guardian.primaryContact,
        'initialIsChildCustody': guardian.legalCustody,
      },
    );

    if (!mounted || result != true) return;
    await _reload();
  }

  Future<void> _onDeleteParent(StudentGuardian guardian) async {
    final studentCode = widget.studentCode ?? '';
    final guardianCode = guardian.guardianCode.trim();
    final guardianName = guardian.fullName;

    if (studentCode.isEmpty || guardianCode.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: StudentStrings.guardianDetailsAreNotLoadedYetPleaseTryAgain,
        isError: true,
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparentColor,
      builder: (sheetContext) {
        return DeleteConfirmationBottomSheet(
          name: guardianName.isEmpty
              ? StudentStrings.thisGuardian
              : guardianName,
          type: 'guardian',
          isLoading: _isMutating,
          onCancel: () => Navigator.of(sheetContext).pop(),
          onDelete: () async {
            if (_isMutating) return;
            setState(() => _isMutating = true);
            try {
              final message = await _guardianCubit.delete(
                code: guardianCode,
                studentCode: studentCode,
              );
              if (!mounted) return;
              Navigator.of(sheetContext).pop();
              CoreUtils.showTopSnackBar(
                context: context,
                message: message,
                isSuccess: true,
              );
              await _reload();
            } catch (e) {
              if (!mounted) return;
              Navigator.of(sheetContext).pop();
              CoreUtils.showTopSnackBar(
                context: context,
                message: ApiErrorHandler.extractErrorMessage(e),
                isError: true,
              );
            } finally {
              if (mounted) {
                setState(() => _isMutating = false);
              }
            }
          },
        );
      },
    );
  }

  /// Guard shared by the not-yet-wired actions: both need a resolved guardian
  /// before they can call anything, so the check lands here once.
  bool _hasGuardianContext(StudentGuardian guardian) {
    final studentCode = widget.studentCode ?? '';
    if (studentCode.isEmpty || guardian.guardianCode.trim().isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: StudentStrings.guardianDetailsAreNotLoadedYetPleaseTryAgain,
        isError: true,
      );
      return false;
    }
    return true;
  }

  /// Re-sends the app invite to THIS parent only — keyed on their own
  /// `userCode` + `email`, never the student's or another guardian's.
  Future<void> _onResendInvite(StudentGuardian guardian) async {
    if (!mounted || !_hasGuardianContext(guardian)) return;

    final invitedEmail = guardian.email.trim();
    final userCode = guardian.userCode.trim();
    if (invitedEmail.isEmpty || userCode.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: StudentStrings.thisParentHasNoEmailOnFileAddOneBeforeSending,
        isError: true,
      );
      return;
    }

    if (_isMutating) return;
    setState(() => _isMutating = true);
    try {
      // The cubit resolves the org/school context from storage — a view must
      // not reach for StorageService itself (Mandate 5).
      final message = await _guardianCubit.resendInvite(
        invitedEmail: invitedEmail,
        userCode: userCode,
        schoolCode: widget.schoolCode ?? '',
      );
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: message,
        isSuccess: true,
      );
    } catch (e) {
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: ApiErrorHandler.extractErrorMessage(e),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isMutating = false);
      }
    }
  }

  /// Change / regenerate THIS parent's clock PIN.
  ///
  /// The dialog only collects the choice; the matching API call is made here so
  /// the sheet stays free of data-layer concerns. Either route ends with a
  /// forced guardian-list reload so the card shows the new PIN.
  Future<void> _onChangePin(StudentGuardian guardian) async {
    if (!mounted || !_hasGuardianContext(guardian)) return;

    final choice = await ChangeGuardianPinDialog.show(context);
    if (!mounted || choice == null) return;

    final guardianCode = guardian.guardianCode.trim();
    final studentCode = widget.studentCode ?? '';

    if (_isMutating) return;
    setState(() => _isMutating = true);
    try {
      final result = switch (choice.mode) {
        ChangeGuardianPinMode.manual => await _guardianCubit.changePin(
          guardianCode: guardianCode,
          pin: choice.pin ?? '',
          studentCode: studentCode,
        ),
        ChangeGuardianPinMode.regenerate => await _guardianCubit.generatePin(
          guardianCode: guardianCode,
          studentCode: studentCode,
        ),
      };
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: result.message,
        isSuccess: true,
      );
      // Force a network reload: the repository already dropped the guardian
      // cache, and `force` skips it on the way out too, so the list re-renders
      // with the new PIN rather than a stale one.
      await _reload(force: true);
    } catch (e) {
      if (!mounted) return;
      CoreUtils.showTopSnackBar(
        context: context,
        message: ApiErrorHandler.extractErrorMessage(e),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isMutating = false);
      }
    }
  }

  /// Opens the admin-only action panel for a guardian card. Edit and Delete
  /// reuse the exact handlers behind the card's inline buttons.
  Future<void> _onGuardianOptions(StudentGuardian guardian) {
    return GuardianActionPanel.show(
      context,
      onEdit: _isMutating ? null : () => _onEditParent(guardian),
      onDelete: _isMutating ? null : () => _onDeleteParent(guardian),
      onResendInvite: () => _onResendInvite(guardian),
      onChangePin: () => _onChangePin(guardian),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<RoleCubit>();
    final canStudentWrite =
        ModuleAccess.mayWrite(role, AppAccessModules.student) && !role.isParent;
    // Three-dot options are admin-only (organization admin, school admin,
    // director…). `isTrueAdmin` is the ADMIN persona bucket — it excludes the
    // STAFF/teacher persona that `isAdmin` also covers. Guarded on
    // `isPersonaResolved` because `RoleState.role` defaults to `admin` before
    // `/users/details` resolves, which would otherwise flash the menu for a
    // non-admin.
    final canUseGuardianActions =
        role.isPersonaResolved && role.isTrueAdmin && canStudentWrite;

    return CustomRefreshIndicator(
      onRefresh: () => _reload(force: true),
      child: SingleChildScrollView(
        controller: widget.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          // Space between the tab bar and the heading/+ row.
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.none,
            AppSpacing.md,
            AppSpacing.none,
            AppSpacing.md,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.none,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      StudentStrings.parentsGuardians,
                      style: AppTextStyles.value.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    if (canStudentWrite)
                      GradientAddButton(
                        onTap: _onAddParent,
                        wantedButtonSize: 40,
                        iconSize: 22,
                        borderRadius: 10,
                      )
                    else
                      const SizedBox.shrink(),
                  ],
                ),
              ),
              AppSpacing.gapVMd,
              BlocBuilder<StudentGuardianCubit, StudentGuardianState>(
                bloc: _guardianCubit,
                builder: (context, state) {
                  if (state.isLoading && state.guardians.isEmpty) {
                    return const StudentDetailCardsShimmer();
                  }

                  if (state.errorMessage != null && state.guardians.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: Text(
                        StudentStrings.failedToLoadParents,
                        style: AppTextStyles.value.copyWith(
                          fontSize: 14,
                          color: AppColors.errorColor,
                        ),
                      ),
                    );
                  }

                  final data = state.guardians;
                  if (data.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        StudentStrings.noParentsAddedYet,
                        style: AppTextStyles.value.copyWith(fontSize: 14),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      for (int i = 0; i < data.length; i++) ...[
                        _FamilyCard(
                          name: data[i].fullName,
                          relation: data[i].relationToStudent,
                          email: data[i].email,
                          phone: _formatPhoneNumber(data[i].mobile),
                          pin: _extractGuardianClockPin(data[i]),
                          photoUrl: data[i].profilePhotoUrl,
                          photoAssetCode: data[i].profilePhotoAssetCode,
                          isLoading: _isMutating,
                          showActionButtons: canStudentWrite,
                          onEdit: () => _onEditParent(data[i]),
                          onDelete: () => _onDeleteParent(data[i]),
                          onOptions: canUseGuardianActions
                              ? () => _onGuardianOptions(data[i])
                              : null,
                        ),
                        if (i != data.length - 1) AppSpacing.gapVSm,
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FamilyCard extends StatelessWidget {
  const _FamilyCard({
    required this.name,
    required this.relation,
    required this.email,
    required this.phone,
    required this.pin,
    required this.onEdit,
    required this.onDelete,
    required this.isLoading,
    this.showActionButtons = true,
    this.onOptions,
    this.photoUrl,
    this.photoAssetCode,
  });

  final String name;
  final String relation;
  final String email;
  final String phone;
  final String pin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isLoading;
  final bool showActionButtons;

  /// Opens the guardian action panel. Null hides the three-dot button entirely
  /// (non-admin personas).
  final VoidCallback? onOptions;
  final String? photoUrl;
  final String? photoAssetCode;

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final isTablet = responsive.isTabletCompact;

    return IntrinsicHeight(
      child: Container(
        width: double.infinity,
        // Match the Health tab cards: themeColor outline, square top-left.
        decoration: const BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(AppRadius.sm),
            bottomLeft: Radius.circular(AppRadius.sm),
            bottomRight: Radius.circular(AppRadius.sm),
          ),
          border: Border.fromBorderSide(
            BorderSide(
              color: AppColors.themeColor,
              width: AppDimensions.hairline,
            ),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              height: 60,
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? AppSpacing.xl : AppSpacing.md,
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  DocumentImageWidget(
                    fileUuid: '',
                    imageUrl: (photoUrl ?? '').trim().isNotEmpty
                        ? photoUrl!.trim()
                        : null,
                    mediaAssetCode: (photoAssetCode ?? '').trim().isNotEmpty
                        ? photoAssetCode!.trim()
                        : null,
                    name: name,
                    size: 45,
                  ),
                  SizedBox(width: isTablet ? AppSpacing.md : 9),
                  Expanded(
                    child: Text(
                      name,
                      style: AppTextStyles.value.copyWith(
                        fontSize: isTablet ? 16 : 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onOptions != null)
                    IconButton(
                      onPressed: isLoading ? null : onOptions,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 32,
                        height: 32,
                      ),
                      splashRadius: 20,
                      tooltip: StudentStrings.options,
                      icon: const Icon(
                        Icons.more_vert,
                        size: AppDimensions.iconSm,
                        color: AppColors.primaryColor,
                      ),
                    ),
                ],
              ),
            ),
            Divider(
              height: 1,
              thickness: AppDimensions.hairline,
              indent: AppSpacing.md,
              endIndent: AppSpacing.md,
              color: AppColors.dividerColor,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.none,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(StudentStrings.relation, style: AppTextStyles.label),
                      Text(relation, style: AppTextStyles.value),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(StudentStrings.emailId, style: AppTextStyles.label),
                      Text(email, style: AppTextStyles.value),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        StudentStrings.phoneNumber,
                        style: AppTextStyles.label,
                      ),
                      Text(phone, style: AppTextStyles.value),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        StudentStrings.signInPin,
                        style: AppTextStyles.label,
                      ),
                      Text(pin, style: AppTextStyles.value),
                    ],
                  ),
                  AppSpacing.gapVLg,
                  if (showActionButtons)
                    CustomButtonLayout(
                      confirmButtonLabel: StudentStrings.edit,
                      cancelButtonLabel: StudentStrings.delete,
                      onPressedConfirm: isLoading ? null : onEdit,
                      onPressedCancel: isLoading ? null : onDelete,
                      isForm: false,
                      isLoading: isLoading,
                    ),
                  if (showActionButtons) AppSpacing.gapVSm,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
