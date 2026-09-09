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
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/presentation/features/students/view_model/student_pickup_cubit.dart';
import 'package:wowcare/presentation/features/students/student_strings.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/common/widgets/gradient_add_button.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/presentation/features/students/view/add_pickup_screen.dart';
import 'package:wowcare/shared/common/widgets/delete_confirmation_bottom_sheet.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

class StudentPickupTabCard extends StatefulWidget {
  const StudentPickupTabCard({
    required this.scrollController,
    required this.name,
    required this.classroom,
    this.studentCode,
    this.onRefresh,
    super.key,
  });

  final ScrollController scrollController;
  final String name;
  final String classroom;
  final String? studentCode;
  final Future<void> Function()? onRefresh;

  @override
  State<StudentPickupTabCard> createState() => _StudentPickupTabCardState();
}

class _StudentPickupTabCardState extends State<StudentPickupTabCard> {
  static const int _maxPickupsPerStudent = 4;

  bool _isMutating = false;

  /// The cubit OWNS the pickup list (single source of truth); the card renders
  /// `state.pickups` via BlocBuilder. One instance per card so the single-flight
  /// delete guard spans taps (serviceLocator registers a factory).
  final StudentPickupCubit _pickupCubit = serviceLocator<StudentPickupCubit>();

  @override
  void initState() {
    super.initState();
    _pickupCubit.load(widget.studentCode ?? '');
  }

  @override
  void dispose() {
    _pickupCubit.close();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    await _pickupCubit.load(widget.studentCode ?? '', forceRefresh: true);
    await widget.onRefresh?.call();
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<RoleCubit>();
    final canStudentWrite =
        ModuleAccess.mayWrite(role, AppAccessModules.student) && !role.isParent;

    return CustomRefreshIndicator(
      onRefresh: _handleRefresh,
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
                      StudentStrings.pickupDetails,
                      style: AppTextStyles.value.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    if (canStudentWrite)
                      GradientAddButton(
                        onTap: () async {
                          final code = widget.studentCode ?? '';
                          if (code.isEmpty) return;
                          final current = _pickupCubit.state.pickups;
                          if (current.length >= _maxPickupsPerStudent) {
                            if (!mounted) return;
                            CoreUtils.showTopSnackBar(
                              context: context,
                              message:
                                  'You can add up to $_maxPickupsPerStudent pickup contacts per student.',
                              isError: true,
                            );
                            return;
                          }
                          final result = await context.push<bool>(
                            AddPickupScreen.routeName,
                            extra: <String, dynamic>{'studentCode': code},
                          );
                          if (result == true && mounted) {
                            await _handleRefresh();
                          }
                        },
                        wantedButtonSize: 40,
                        iconSize: 22,
                        borderRadius: AppRadius.r10,
                      )
                    else
                      const SizedBox.shrink(),
                  ],
                ),
              ),
              AppSpacing.gapVMd,
              BlocBuilder<StudentPickupCubit, StudentPickupState>(
                bloc: _pickupCubit,
                builder: (context, state) {
                  if (state.isLoading && state.pickups.isEmpty) {
                    return const StudentDetailCardsShimmer();
                  }

                  if (state.errorMessage != null && state.pickups.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: Text(
                        StudentStrings.failedToLoadPickups,
                        style: AppTextStyles.value.copyWith(
                          fontSize: 14,
                          color: AppColors.errorColor,
                        ),
                      ),
                    );
                  }

                  final pickups = state.pickups;
                  if (pickups.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Text(
                        StudentStrings.noPickupsFound,
                        style: AppTextStyles.value.copyWith(fontSize: 14),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      for (int i = 0; i < pickups.length; i++) ...[
                        _PickupCard(
                          pickupCubit: _pickupCubit,
                          studentCode: widget.studentCode ?? '',
                          pickupCode: pickups[i].code ?? '',
                          clockPin: pickups[i].clockPin ?? '',
                          pickupType: pickups[i].pickupType ?? '',
                          name: pickups[i].fullName.isNotEmpty
                              ? pickups[i].fullName
                              : '-',
                          relation: _effectiveRelation(
                            pickups[i].relation,
                            pickups[i].relationshipDescription,
                          ),
                          email: _valueOrDash(pickups[i].email),
                          rawEmail: pickups[i].email,
                          phoneNumber: _formatPhoneNumber(
                            pickups[i].phoneNumber,
                          ),
                          rawRelation: pickups[i].relation,
                          rawRelationshipDescription:
                              pickups[i].relationshipDescription,
                          rawPhoneNumber: pickups[i].phoneNumber,
                          firstName: pickups[i].firstName,
                          lastName: pickups[i].lastName,
                          photoUrl: pickups[i].profilePhotoUrl,
                          photoAssetCode: pickups[i].profilePhotoAssetCode,
                          onRefresh: _handleRefresh,
                          isLoading: _isMutating,
                          onSetLoading: (v) => setState(() => _isMutating = v),
                          showActionButtons: canStudentWrite,
                        ),
                        if (i != pickups.length - 1) AppSpacing.gapVSm,
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

String _valueOrDash(String? v) {
  if (v == null) return '-';
  final t = v.trim();
  return t.isEmpty ? '-' : t;
}

String _formatPhoneNumber(String? raw) {
  final digits = (raw ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.length == 10) {
    return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6)}';
  }
  return _valueOrDash(raw);
}

/// Resolves the relation value to actually show/prefill: for a real
/// predefined relation this is just its title-cased form, but 'OTHER' on
/// its own is meaningless to a user - the specific relation they typed
/// (e.g. "Family Friend") lives in [relationshipDescription] instead. Used
/// both for the card's displayed relation text and (via [_onEdit] below)
/// as what seeds RelationSelector when reopening this pickup to edit it -
/// without this, both showed the literal word "Other" instead of what the
/// user actually specified.
String _effectiveRelation(String relation, String? relationshipDescription) {
  final r = relation.trim();
  if (r.toUpperCase() == 'OTHER') {
    final description = (relationshipDescription ?? '').trim();
    if (description.isNotEmpty) return description;
  }
  return _formatRelation(r);
}

String _formatRelation(String relation) {
  final r = relation.trim();
  if (r.isEmpty) return '-';
  final upper = r.toUpperCase();
  switch (upper) {
    case 'FATHER':
      return 'Father';
    case 'MOTHER':
      return 'Mother';
    case 'GUARDIAN':
      return 'Guardian';
    default:
      // Title-case fallback
      return upper.substring(0, 1) + upper.substring(1).toLowerCase();
  }
}

class _PickupCard extends StatefulWidget {
  const _PickupCard({
    required this.pickupCubit,
    required this.studentCode,
    required this.pickupCode,
    required this.clockPin,
    required this.pickupType,
    required this.firstName,
    required this.lastName,
    required this.rawPhoneNumber,
    required this.rawRelation,
    required this.isLoading,
    required this.onSetLoading,
    required this.name,
    this.relation,
    this.email,
    this.rawEmail,
    this.phoneNumber,
    this.rawRelationshipDescription,
    this.onRefresh,
    this.showActionButtons = true,
    this.photoUrl,
    this.photoAssetCode,
  });
  final StudentPickupCubit pickupCubit;
  final String studentCode;
  final String pickupCode;
  final String clockPin;
  final String pickupType;
  final String firstName;
  final String lastName;
  final String rawPhoneNumber;
  final String rawRelation;
  final String? rawRelationshipDescription;
  final bool isLoading;
  final ValueChanged<bool> onSetLoading;
  final String name;
  final String? relation;
  final String? email;
  final String? rawEmail;
  final String? phoneNumber;
  final String? photoUrl;
  final String? photoAssetCode;

  /// Called after edit or delete so parent can refresh pickups list and profile cache.
  final Future<void> Function()? onRefresh;
  final bool showActionButtons;

  @override
  State<_PickupCard> createState() => _PickupCardState();
}

class _PickupCardState extends State<_PickupCard> {
  String _formatPickupType(String raw) {
    final t = raw.trim().toUpperCase();
    if (t == 'CARPOOL') return 'Carpool';
    if (t == 'CAREGIVER') return 'Caregiver';
    if (t.isEmpty) return '-';
    return t.substring(0, 1) + t.substring(1).toLowerCase();
  }

  Future<void> _onEdit() async {
    final result = await context.push<bool>(
      AddPickupScreen.routeName,
      extra: <String, dynamic>{
        'studentCode': widget.studentCode,
        'pickupCode': widget.pickupCode.trim().isEmpty
            ? null
            : widget.pickupCode,
        'initialFirstName': widget.firstName,
        'initialLastName': widget.lastName,
        'initialEmail': widget.rawEmail,
        'initialPhoneNumber': widget.rawPhoneNumber,
        // Seeds RelationSelector.initialRelation - for relation: 'OTHER'
        // this must be the actual typed-in relation (relationshipDescription),
        // not the literal word "OTHER", or the Specify-Relation field on
        // reopening this pickup to edit it shows "Other" instead of what
        // was originally entered (e.g. "Family Friend").
        'initialRelation': _effectiveRelation(
          widget.rawRelation,
          widget.rawRelationshipDescription,
        ),
        'initialClockPin': widget.clockPin,
      },
    );
    if (result == true) {
      await widget.onRefresh?.call();
    }
  }

  Future<void> _onDelete() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparentColor,
      builder: (sheetContext) {
        return DeleteConfirmationBottomSheet(
          name: widget.name,
          type: 'pickup',
          isLoading: widget.isLoading,
          onCancel: () => Navigator.of(sheetContext).pop(),
          onDelete: () async {
            if (widget.isLoading) return;
            if (widget.pickupCode.trim().isEmpty ||
                widget.studentCode.trim().isEmpty) {
              Navigator.of(sheetContext).pop();
              return;
            }
            widget.onSetLoading(true);
            try {
              final message = await widget.pickupCubit.delete(
                code: widget.pickupCode,
                studentCode: widget.studentCode,
              );
              if (!mounted) return;
              Navigator.of(sheetContext).pop();
              CoreUtils.showTopSnackBar(
                context: context,
                message: message,
                isSuccess: true,
              );
              await widget.onRefresh?.call();
            } catch (e) {
              if (!mounted) return;
              Navigator.of(sheetContext).pop();
              CoreUtils.showTopSnackBar(
                context: context,
                message: ApiErrorHandler.extractErrorMessage(e),
                isError: true,
              );
            } finally {
              widget.onSetLoading(false);
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final isTablet = responsive.isTabletCompact;
    final isCarpool = widget.pickupType.trim().toUpperCase() == 'CARPOOL';

    return LayoutBuilder(
      builder: (context, constraints) {
        return IntrinsicHeight(
          child: Container(
            width: constraints.maxWidth,
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
                  padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      DocumentImageWidget(
                        fileUuid: '',
                        imageUrl: (widget.photoUrl ?? '').trim().isNotEmpty
                            ? widget.photoUrl!.trim()
                            : null,
                        mediaAssetCode:
                            (widget.photoAssetCode ?? '').trim().isNotEmpty
                            ? widget.photoAssetCode!.trim()
                            : null,
                        name: widget.name,
                        size: 50,
                      ),
                      SizedBox(width: isTablet ? 16 : 9),
                      Expanded(
                        child: Text(
                          widget.name,
                          style: AppTextStyles.value.copyWith(
                            fontSize: isTablet ? 16 : 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 16,
                  endIndent: 16,
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
                          Text(
                            StudentStrings.type,
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.primaryColor.withValues(
                                alpha: 0.5,
                              ),
                              fontSize: 14,
                              letterSpacing: 14 * (-3 / 100),
                            ),
                          ),
                          Text(
                            _formatPickupType(widget.pickupType),
                            style: AppTextStyles.value.copyWith(fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            StudentStrings.relation,
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.primaryColor.withValues(
                                alpha: 0.5,
                              ),
                              fontSize: 14,
                              letterSpacing: 14 * (-3 / 100),
                            ),
                          ),
                          Text(
                            widget.relation ?? '-',
                            style: AppTextStyles.value.copyWith(fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            StudentStrings.emailId,
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.primaryColor.withValues(
                                alpha: 0.5,
                              ),
                              fontSize: 14,
                              letterSpacing: 14 * (-3 / 100),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              (widget.email != null &&
                                      widget.email!.isNotEmpty &&
                                      widget.email != '-')
                                  ? widget.email!
                                  : '-',
                              style: AppTextStyles.value.copyWith(fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            StudentStrings.phoneNumber,
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.primaryColor.withValues(
                                alpha: 0.5,
                              ),
                              fontSize: 14,
                              letterSpacing: 14 * (-3 / 100),
                            ),
                          ),
                          Text(
                            widget.phoneNumber ?? '-',
                            style: AppTextStyles.value.copyWith(fontSize: 15),
                          ),
                        ],
                      ),
                      AppSpacing.gapVLg,
                      if (widget.showActionButtons) ...[
                        if (isCarpool)
                          CustomButtonLayout(
                            confirmButtonLabel: StudentStrings.delete,
                            onPressedConfirm: widget.isLoading
                                ? null
                                : _onDelete,
                            showCancelButton: false,
                            isForm: false,
                            isLoading: widget.isLoading,
                          )
                        else
                          CustomButtonLayout(
                            confirmButtonLabel: StudentStrings.edit,
                            cancelButtonLabel: StudentStrings.delete,
                            onPressedConfirm: widget.isLoading ? null : _onEdit,
                            onPressedCancel: widget.isLoading
                                ? null
                                : _onDelete,
                            isForm: false,
                            isLoading: widget.isLoading,
                          ),
                        AppSpacing.gapVSm,
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
