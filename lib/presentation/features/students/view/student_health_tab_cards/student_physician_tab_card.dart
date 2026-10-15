import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/domain/features/student/entities/student_physician.dart';
import 'package:wowcare/presentation/features/students/view_model/student_physician_cubit.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/gradient_add_button.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/common/widgets/delete_confirmation_bottom_sheet.dart';
import 'package:wowcare/shared/common/widgets/profile_avatar.dart';
import 'package:wowcare/presentation/features/students/view/add_physician_screen.dart';

class StudentPhysicianTabCard extends StatefulWidget {
  const StudentPhysicianTabCard({
    required this.scrollController,
    required this.name,
    required this.classroom,
    this.studentCode,
    this.canEdit = false,
    super.key,
  });

  final ScrollController scrollController;
  final String name;
  final String classroom;
  final String? studentCode;

  /// Whether the current persona may edit health records (from student-settings).
  final bool canEdit;

  @override
  State<StudentPhysicianTabCard> createState() =>
      _StudentPhysicianTabCardState();
}

class _StudentPhysicianTabCardState extends State<StudentPhysicianTabCard> {
  late Future<List<StudentPhysician>> _physiciansFuture;

  /// One cubit instance for this card so its single-flight delete guard spans
  /// taps (serviceLocator registers it as a factory — a fresh call per tap
  /// would not dedupe).
  final StudentPhysicianCubit _physicianCubit =
      serviceLocator<StudentPhysicianCubit>();

  @override
  void initState() {
    super.initState();
    // Force-fresh on open, not just on pull-to-refresh — otherwise landing on
    // this tab can show up to 5-minute-old cached data.
    _physiciansFuture = _buildPhysiciansFuture(forceRefresh: true);
  }

  @override
  void dispose() {
    _physicianCubit.close();
    super.dispose();
  }

  Future<List<StudentPhysician>> _buildPhysiciansFuture({
    bool forceRefresh = false,
  }) {
    final code = widget.studentCode;
    if (code == null || code.isEmpty) {
      return Future.value(const <StudentPhysician>[]);
    }
    // Route the read through the cubit → use case → repository. The repository
    // still handles cache via CacheManager; first call may use cache, subsequent
    // ones will hit API when cache is invalidated after mutations.
    return _physicianCubit.fetchPhysicians(code, forceRefresh: forceRefresh);
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _physiciansFuture = _buildPhysiciansFuture(forceRefresh: true);
    });
    try {
      await _physiciansFuture;
    } catch (_) {
      // errors are surfaced in the UI via FutureBuilder
    }
  }

  Future<void> _onAddPhysician() async {
    final studentCode = widget.studentCode ?? '';
    if (studentCode.isEmpty) {
      return;
    }

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddPhysicianScreen(studentCode: studentCode),
      ),
    );

    if (!mounted || result != true) return;

    await _handleRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final canStudentWrite = widget.canEdit;

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
                      'Physicians',
                      style: AppTextStyles.value.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    if (canStudentWrite)
                      GradientAddButton(
                        onTap: _onAddPhysician,
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
              FutureBuilder<List<StudentPhysician>>(
                future: _physiciansFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const StudentDetailCardsShimmer();
                  }

                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        'Failed to load physicians',
                        style: AppTextStyles.value.copyWith(
                          fontSize: 14,
                          color: MaterialHues.redAccent,
                        ),
                      ),
                    );
                  }

                  final physicians =
                      snapshot.data ?? const <StudentPhysician>[];
                  if (physicians.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'No physicians added yet',
                        style: AppTextStyles.value.copyWith(fontSize: 14),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      for (int i = 0; i < physicians.length; i++) ...[
                        _PhysicianCard(
                          code: physicians[i].code,
                          studentCode: widget.studentCode ?? '',
                          firstName: physicians[i].firstName,
                          lastName: physicians[i].lastName,
                          name: physicians[i].fullName.isNotEmpty
                              ? physicians[i].fullName
                              : '-',
                          address: physicians[i].address,
                          email: physicians[i].email,
                          phoneNumber: physicians[i].phoneNumber,
                          specialty: physicians[i].specialty,
                          notes: physicians[i].notes,
                          onChanged: _handleRefresh,
                          showActionButtons: canStudentWrite,
                          physicianCubit: _physicianCubit,
                        ),
                        if (i != physicians.length - 1)
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

class _PhysicianCard extends StatelessWidget {
  const _PhysicianCard({
    required this.code,
    required this.studentCode,
    required this.firstName,
    required this.lastName,
    required this.name,
    required this.physicianCubit,
    this.address,
    this.phoneNumber,
    this.email,
    this.specialty,
    this.notes,
    this.onChanged,
    this.showActionButtons = true,
  });
  final StudentPhysicianCubit physicianCubit;
  final String code;
  final String studentCode;
  final String firstName;
  final String lastName;
  final String name;
  final String? address;
  final String? email;
  final String? specialty;
  final String? notes;
  final String? phoneNumber;
  final Future<void> Function()? onChanged;
  final bool showActionButtons;

  String _formatPhoneNumber(String? raw) {
    if (raw == null) return '-';
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '-';
    String local10 = digits;
    if (digits.length == 11 && digits.startsWith('1')) {
      local10 = digits.substring(1);
    } else if (digits.length > 11) {
      local10 = digits.substring(digits.length - 10);
    }
    if (local10.length != 10) return raw;
    return '(${local10.substring(0, 3)}) ${local10.substring(3, 6)}-${local10.substring(6, 10)}';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    return IntrinsicHeight(
      child: Container(
        width: double.infinity,
        // Match the Family/Pickup cards: themeColor outline, square top-left.
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
                  ProfileAvatar(name: name, size: 45),
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
                  if (phoneNumber != null &&
                      phoneNumber!.trim().isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phone Number',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.5,
                            ),
                            fontSize: 14,
                            letterSpacing: 14 * (-3 / 100),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _formatPhoneNumber(phoneNumber),
                            textAlign: TextAlign.right,
                            softWrap: true,
                            style: AppTextStyles.value.copyWith(fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (email != null && email!.trim().isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Email ID',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.5,
                            ),
                            fontSize: 14,
                            letterSpacing: 14 * (-3 / 100),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            email!,
                            textAlign: TextAlign.right,
                            softWrap: true,
                            style: AppTextStyles.value.copyWith(fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (address != null && address!.trim().isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Address',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.5,
                            ),
                            fontSize: 14,
                            letterSpacing: 14 * (-3 / 100),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            address!,
                            textAlign: TextAlign.right,
                            softWrap: true,
                            style: AppTextStyles.value.copyWith(fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (specialty != null && specialty!.trim().isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Specialty',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.5,
                            ),
                            fontSize: 14,
                            letterSpacing: 14 * (-3 / 100),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            specialty!,
                            textAlign: TextAlign.right,
                            softWrap: true,
                            style: AppTextStyles.value.copyWith(fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (notes != null && notes!.trim().isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notes',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.primaryColor.withValues(
                              alpha: 0.5,
                            ),
                            fontSize: 14,
                            letterSpacing: 14 * (-3 / 100),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            notes!,
                            textAlign: TextAlign.right,
                            style: AppTextStyles.value.copyWith(fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (showActionButtons) ...[
                    const SizedBox(height: 12),
                    CustomButtonLayout(
                      confirmButtonLabel: 'Edit',
                      cancelButtonLabel: 'Delete',
                      gradientCancelLabel: true,
                      onPressedConfirm: () async {
                        final result = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(
                            builder: (_) => AddPhysicianScreen(
                              studentCode: studentCode,
                              physicianCode: code,
                              isEdit: true,
                              initialFirstName: firstName,
                              initialLastName: lastName,
                              initialEmail: email,
                              initialPhoneNumber: phoneNumber,
                              initialAddress: address,
                              initialNotes: notes,
                            ),
                          ),
                        );

                        if (result == true && onChanged != null) {
                          await onChanged!();
                        }
                      },
                      onPressedCancel: () async {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (ctx) {
                            return DeleteConfirmationBottomSheet(
                              name: name,
                              type: 'physician',
                              onDelete: () async {
                                try {
                                  final message = await physicianCubit.delete(
                                    code: code,
                                    studentCode: studentCode,
                                  );
                                  Navigator.of(ctx).pop();
                                  if (onChanged != null) {
                                    await onChanged!();
                                  }
                                  CoreUtils.showTopSnackBar(
                                    context: context,
                                    message: message,
                                    isSuccess: true,
                                  );
                                } catch (e) {
                                  Navigator.of(ctx).pop();
                                  CoreUtils.showTopSnackBar(
                                    context: context,
                                    message:
                                        ApiErrorHandler.extractErrorMessage(e),
                                    isError: true,
                                  );
                                }
                              },
                              onCancel: () {
                                Navigator.of(ctx).pop();
                              },
                            );
                          },
                        );
                      },
                      isForm: false,
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
  }
}
