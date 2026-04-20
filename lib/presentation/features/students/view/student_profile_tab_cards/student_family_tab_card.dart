import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/student/module_access.dart';
import 'package:wowcare/shared/common/app/providers/role_provider.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/debug_defaults.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/data/features/student/repositories/student_repository_impl.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/gradient_add_button.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
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

  late Future<List<Map<String, dynamic>>> _guardiansFuture;
  bool _isMutating = false;

  String _extractGuardianClockPin(Map<String, dynamic> guardian) {
    final raw = (guardian['clockPin'] ??
            guardian['clockInPin'] ??
            guardian['clockinPin'] ??
            '')
        .toString()
        .trim();
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
    final fromStorage =
        (await storage.getString(StorageKeys.schoolCode) ?? '').trim();
    if (fromStorage.isNotEmpty) return fromStorage;

    // Final fallback (should never hit because StorageService also defaults).
    return DebugDefaults.schoolCode;
  }

  @override
  void initState() {
    super.initState();
    _guardiansFuture = _loadGuardians();
  }

  Future<List<Map<String, dynamic>>> _loadGuardians({bool forceRefresh = false}) async {
    final studentCode = widget.studentCode ?? '';
    if (studentCode.isEmpty) {
      return const <Map<String, dynamic>>[];
    }

    // Use repository, which already applies caching via CacheManager.
    final repo = serviceLocator<StudentRepository>();
    if (repo is! StudentRepositoryImpl) {
      // Fallback: no data if repository implementation is not available.
      return const <Map<String, dynamic>>[];
    }

    final models = await repo.getStudentGuardians(
      studentCode: studentCode,
      forceRefresh: forceRefresh,
    );
    return models.map((e) => e.toJson()).toList(growable: false);
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

    final repo = serviceLocator<StudentRepository>();
    if (repo is StudentRepositoryImpl) {
      final existing = await repo.getStudentGuardians(studentCode: studentCode);
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
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddStudentStep2Screen(
          studentCode: studentCode,
          schoolCode: schoolCode,
          createGuardianDirectly: true,
        ),
      ),
    );

    if (!mounted || result != true) return;

    setState(() {
      _guardiansFuture = _loadGuardians();
    });
    await widget.onRefresh?.call();
  }

  Future<void> _onEditParent(Map<String, dynamic> guardian) async {
    final studentCode = widget.studentCode ?? '';
    final schoolCode = widget.schoolCode ?? '';
    final guardianCode = (guardian['guardianCode'] ?? guardian['code'] ?? '')
        .toString()
        .trim();
    if (studentCode.isEmpty || schoolCode.isEmpty || guardianCode.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Guardian details are not loaded yet. Please try again.',
        isError: true,
      );
      return;
    }

    final rawRelation = (guardian['relationToStudent'] ?? '').toString().trim();
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
    final isKnownRelation = normalizedRelation != null &&
        relationOptions.contains(normalizedRelation);

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddStudentStep2Screen(
          studentCode: studentCode,
          schoolCode: schoolCode,
          createGuardianDirectly: true,
          editGuardianCode: guardianCode,
          initialUserCode: (guardian['userCode'] ?? '').toString().trim(),
          initialFirstName: (guardian['firstName'] ?? '').toString(),
          initialLastName: (guardian['lastName'] ?? '').toString(),
          initialEmail: (guardian['email'] ?? '').toString(),
          initialPhoneNumber: (guardian['mobile'] ?? '').toString(),
          initialRelation: isKnownRelation ? normalizedRelation : 'Other',
          initialRelationOther:
              isKnownRelation ? null : (rawRelation.isEmpty ? null : rawRelation),
          initialIsEmergencyContact: (guardian['primaryContact'] as bool?) ?? true,
          initialIsChildCustody: (guardian['legalCustody'] as bool?) ?? true,
        ),
      ),
    );

    if (!mounted || result != true) return;
    setState(() {
      _guardiansFuture = _loadGuardians();
    });
    await widget.onRefresh?.call();
  }

  Future<void> _onDeleteParent(Map<String, dynamic> guardian) async {
    final studentCode = widget.studentCode ?? '';
    final guardianCode = (guardian['guardianCode'] ?? guardian['code'] ?? '')
        .toString()
        .trim();
    final guardianName =
        '${guardian['firstName'] ?? ''} ${guardian['lastName'] ?? ''}'.trim();

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
      backgroundColor: Colors.transparent,
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
              final repo = serviceLocator<StudentRepository>();
              final message = await repo.deleteGuardian(
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
              setState(() {
                _guardiansFuture = _loadGuardians();
              });
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
    final role = context.watch<RoleProvider>();
    final canStudentWrite =
        ModuleAccess.mayWrite(role, AppAccessModules.student);

    return CustomRefreshIndicator(
      onRefresh: () async {
        setState(() {
          _guardiansFuture = _loadGuardians(forceRefresh: true);
        });
        await widget.onRefresh?.call();
      },
      child: SingleChildScrollView(
        controller: widget.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
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
                      Opacity(
                        opacity: 0.45,
                        child: GradientAddButton(
                          onTap: () =>
                              ModuleAccess.showWriteRestricted(context),
                          wantedButtonSize: 40,
                          iconSize: 22,
                          borderRadius: 10,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _guardiansFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: PrimaryCircularLoader(
                        size: 28,
                        strokeWidth: 2.5,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        'Failed to load parents',
                        style: AppTextStyles.value.copyWith(
                          fontSize: 14,
                          color: Colors.redAccent,
                        ),
                      ),
                    );
                  }

                  final data = snapshot.data ?? const [];
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
                          name:
                              '${data[i]['firstName'] ?? ''} ${data[i]['lastName'] ?? ''}'
                                  .trim(),
                          relation:
                              (data[i]['relationToStudent'] ?? '').toString(),
                          email: (data[i]['email'] ?? '').toString(),
                          phone: _formatPhoneNumber((data[i]['mobile'] ?? '').toString()),
                          pin: _extractGuardianClockPin(data[i]),
                          isLoading: _isMutating,
                          showActionButtons: canStudentWrite,
                          onEdit: () => _onEditParent(data[i]),
                          onDelete: () => _onDeleteParent(data[i]),
                        ),
                        if (i != data.length - 1)
                          const SizedBox(height: 12),
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return IntrinsicHeight(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorderColor, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Container(
              height: 60,
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 24 : 16,
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  DocumentImageWidget(
                    fileUuid: '',
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
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.primaryColor.withOpacity(0.5),
                          fontSize: 14,
                          letterSpacing: 14 * (-3 / 100),
                        ),
                      ),
                      Text(
                        relation,
                        style: AppTextStyles.value.copyWith(
                          fontSize: 15,
                        ),
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
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.primaryColor.withOpacity(0.5),
                          fontSize: 14,
                          letterSpacing: 14 * (-3 / 100),
                        ),
                      ),
                      Text(
                        email,
                        style: AppTextStyles.value.copyWith(
                          fontSize: 15,
                        ),
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
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.primaryColor.withOpacity(0.5),
                          fontSize: 14,
                          letterSpacing: 14 * (-3 / 100),
                        ),
                      ),
                      Text(
                        phone,
                        style: AppTextStyles.value.copyWith(
                          fontSize: 15,
                        ),
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
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.primaryColor.withOpacity(0.5),
                          fontSize: 14,
                          letterSpacing: 14 * (-3 / 100),
                        ),
                      ),
                      Text(
                        pin,
                        style: AppTextStyles.value.copyWith(
                          fontSize: 15,
                        ),
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