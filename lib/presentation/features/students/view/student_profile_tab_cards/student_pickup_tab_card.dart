import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/student/module_access.dart';
import 'package:wowcare/shared/common/app/providers/role_provider.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/data/features/student/models/student_pickup_models.dart';
import 'package:wowcare/data/features/student/repositories/student_repository_impl.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/shared/common/widgets/gradient_add_button.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/presentation/features/students/view/add_pickup_screen.dart';
import 'package:wowcare/shared/common/widgets/delete_confirmation_bottom_sheet.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import '../../../../../shared/common/widgets/profile_show_widget.dart';

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
  State<StudentPickupTabCard> createState() =>
      _StudentPickupTabCardState();
}

class _StudentPickupTabCardState extends State<StudentPickupTabCard> {
  static const int _maxPickupsPerStudent = 4;

  late Future<List<StudentPickupModel>> _pickupsFuture;
  bool _isMutating = false;

  @override
  void initState() {
    super.initState();
    _pickupsFuture = _buildPickupsFuture();
  }

  Future<List<StudentPickupModel>> _buildPickupsFuture({bool forceRefresh = false}) {
    final code = widget.studentCode;
    if (code == null || code.isEmpty) {
      return Future.value(const <StudentPickupModel>[]);
    }
    final repo = serviceLocator<StudentRepository>() as StudentRepositoryImpl;
    return repo.getStudentPickups(studentCode: code, forceRefresh: forceRefresh);
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _pickupsFuture = _buildPickupsFuture(forceRefresh: true);
    });
    await widget.onRefresh?.call();
    try {
      await _pickupsFuture;
    } catch (_) {
      // swallow; UI handles errors
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<RoleProvider>();
    final canStudentWrite =
        ModuleAccess.mayWrite(role, StudentAccessModules.student);

    return CustomRefreshIndicator(
      onRefresh: _handleRefresh,
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
                      'Pickup details',
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
                          final repo =
                              serviceLocator<StudentRepository>() as StudentRepositoryImpl;
                          final current =
                              await repo.getStudentPickups(studentCode: code);
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
                          final result = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AddPickupScreen(studentCode: code),
                            ),
                          );
                          if (result == true && mounted) {
                            await _handleRefresh();
                          }
                        },
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
              FutureBuilder<List<StudentPickupModel>>(
                future: _pickupsFuture,
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
                        'Failed to load pickups',
                        style: AppTextStyles.value.copyWith(
                          fontSize: 14,
                          color: Colors.redAccent,
                        ),
                      ),
                    );
                  }

                  final pickups = snapshot.data ?? const <StudentPickupModel>[];
                  if (pickups.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'No pickups found',
                        style: AppTextStyles.value.copyWith(fontSize: 14),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      for (int i = 0; i < pickups.length; i++) ...[
                        _PickupCard(
                          studentCode: widget.studentCode ?? '',
                          pickupCode: pickups[i].code ?? '',
                          clockPin: pickups[i].clockPin ?? '',
                          pickupType: pickups[i].pickupType ?? '',
                          name: pickups[i].fullName.isNotEmpty
                              ? pickups[i].fullName
                              : '-',
                          relation: _formatRelation(pickups[i].relation),
                          email: _valueOrDash(pickups[i].email),
                          rawEmail: pickups[i].email,
                          phoneNumber: _formatPhoneNumber(pickups[i].phoneNumber),
                          rawRelation: pickups[i].relation,
                          rawPhoneNumber: pickups[i].phoneNumber,
                          firstName: pickups[i].firstName,
                          lastName: pickups[i].lastName,
                          onRefresh: _handleRefresh,
                          isLoading: _isMutating,
                          onSetLoading: (v) => setState(() => _isMutating = v),
                          showActionButtons: canStudentWrite,
                        ),
                        if (i != pickups.length - 1)
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
    this.onRefresh,
    this.showActionButtons = true,
  });
  final String studentCode;
  final String pickupCode;
  final String clockPin;
  final String pickupType;
  final String firstName;
  final String lastName;
  final String rawPhoneNumber;
  final String rawRelation;
  final bool isLoading;
  final ValueChanged<bool> onSetLoading;
  final String name;
  final String? relation;
  final String? email;
  final String? rawEmail;
  final String? phoneNumber;
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
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddPickupScreen(
          studentCode: widget.studentCode,
          pickupCode:
              widget.pickupCode.trim().isEmpty ? null : widget.pickupCode,
          initialFirstName: widget.firstName,
          initialLastName: widget.lastName,
          initialEmail: widget.rawEmail,
          initialPhoneNumber: widget.rawPhoneNumber,
          initialRelation: widget.rawRelation,
          initialClockPin: widget.clockPin,
        ),
      ),
    );
    if (result == true) {
      await widget.onRefresh?.call();
    }
  }

  Future<void> _onDelete() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
              final repo = serviceLocator<StudentRepository>() as StudentRepositoryImpl;
              final message = await repo.deletePickup(
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isCarpool = widget.pickupType.trim().toUpperCase() == 'CARPOOL';

    return LayoutBuilder(
      builder: (context, constraints) {
        return IntrinsicHeight(
          child: Container(
            width: constraints.maxWidth,
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
                  padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      DocumentImageWidget(
                        fileUuid: '',
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
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Type',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.primaryColor.withOpacity(0.5),
                              fontSize: 14,
                              letterSpacing: 14 * (-3 / 100),
                            ),
                          ),
                          Text(
                            _formatPickupType(widget.pickupType),
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
                            'Relation',
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.primaryColor.withOpacity(0.5),
                              fontSize: 14,
                              letterSpacing: 14 * (-3 / 100),
                            ),
                          ),
                          Text(
                            widget.relation ?? '-',
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
                          Flexible(
                            child: Text(
                              (widget.email != null &&
                                      widget.email!.isNotEmpty &&
                                      widget.email != '-')
                                  ? widget.email!
                                  : '-',
                              style: AppTextStyles.value.copyWith(
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
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
                            widget.phoneNumber ?? '-',
                            style: AppTextStyles.value.copyWith(
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (widget.showActionButtons) ...[
                        if (isCarpool)
                          CustomButtonLayout(
                            confirmButtonLabel: 'Delete',
                            onPressedConfirm: widget.isLoading ? null : _onDelete,
                            showCancelButton: false,
                            isForm: false,
                            isLoading: widget.isLoading,
                          )
                        else
                          CustomButtonLayout(
                            confirmButtonLabel: 'Edit',
                            cancelButtonLabel: 'Delete',
                            onPressedConfirm: widget.isLoading ? null : _onEdit,
                            onPressedCancel: widget.isLoading ? null : _onDelete,
                            isForm: false,
                            isLoading: widget.isLoading,
                          ),
                        const SizedBox(height: 12),
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
















