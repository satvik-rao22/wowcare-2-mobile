import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/students/module_access.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/student/entities/student_guardian.dart';
import 'package:wowcare/presentation/features/students/cubit/student_guardian_cubit.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/gradient_add_button.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/presentation/features/students/view/add_student_step2_screen.dart';
import 'package:wowcare/shared/common/widgets/delete_confirmation_bottom_sheet.dart';
import '../../../../../shared/common/widgets/profile_show_widget.dart';

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
        message: 'Student details not loaded yet. Please try again.',
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
        message: 'Guardian details are not loaded yet. Please try again.',
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
        message: 'Guardian details are not loaded yet. Please try again.',
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
          name: guardianName.isEmpty ? 'this guardian' : guardianName,
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

  @override
  Widget build(BuildContext context) {
    final role = context.watch<RoleCubit>();
    final canStudentWrite =
        ModuleAccess.mayWrite(role, AppAccessModules.student) && !role.isParent;

    return CustomRefreshIndicator(
      onRefresh: () => _reload(force: true),
      child: SingleChildScrollView(
        controller: widget.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          // Space between the tab bar and the heading/+ row.
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 16),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Parents & guardians',
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
              const SizedBox(height: 16),
              BlocBuilder<StudentGuardianCubit, StudentGuardianState>(
                bloc: _guardianCubit,
                builder: (context, state) {
                  if (state.isLoading && state.guardians.isEmpty) {
                    return const StudentDetailCardsShimmer();
                  }

                  if (state.errorMessage != null && state.guardians.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        'Failed to load parents',
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
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'No parents added yet',
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
                        ),
                        if (i != data.length - 1) const SizedBox(height: 12),
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
  final String? photoUrl;
  final String? photoAssetCode;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return IntrinsicHeight(
      child: Container(
        width: double.infinity,
        // Match the Health tab cards: themeColor outline, square top-left.
        decoration: const BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(8),
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
          border: Border.fromBorderSide(
            BorderSide(color: AppColors.themeColor, width: 1),
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
                    imageUrl: (photoUrl ?? '').trim().isNotEmpty
                        ? photoUrl!.trim()
                        : null,
                    mediaAssetCode: (photoAssetCode ?? '').trim().isNotEmpty
                        ? photoAssetCode!.trim()
                        : null,
                    name: name,
                    size: 45,
                  ),
                  SizedBox(width: isTablet ? 16 : 9),
                  Flexible(
                    child: Text(
                      name,
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Relation',
                        style: AppTextStyles.label,
                      ),
                      Text(
                        relation,
                        style: AppTextStyles.value,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Email ID',
                        style: AppTextStyles.label,
                      ),
                      Text(
                        email,
                        style: AppTextStyles.value,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Phone Number',
                        style: AppTextStyles.label,
                      ),
                      Text(
                        phone,
                        style: AppTextStyles.value,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Sign-in Pin',
                        style: AppTextStyles.label,
                      ),
                      Text(
                        pin,
                        style: AppTextStyles.value,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (showActionButtons)
                    CustomButtonLayout(
                      confirmButtonLabel: 'Edit',
                      cancelButtonLabel: 'Delete',
                      onPressedConfirm: isLoading ? null : onEdit,
                      onPressedCancel: isLoading ? null : onDelete,
                      isForm: false,
                      isLoading: isLoading,
                    ),
                  if (showActionButtons) const SizedBox(height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
