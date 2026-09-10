import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/presentation/features/students/module_access.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_dimensions.dart';
import 'package:wowcare/core/theme/app_radius.dart';
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/domain/features/student/entities/student_important_dates.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_important_dates_usecase.dart';
import 'package:wowcare/presentation/features/students/view/edit_student_important_dates_screen.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/presentation/features/students/student_strings.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/skeu_press.dart';

class StudentImportantDatesTab extends StatefulWidget {
  const StudentImportantDatesTab({
    required this.scrollController,
    required this.name,
    required this.classroom,
    this.studentCode,
    super.key,
  });

  final ScrollController scrollController;
  final String name;
  final String classroom;
  final String? studentCode;

  @override
  State<StudentImportantDatesTab> createState() =>
      _StudentImportantDatesTabState();
}

class _StudentImportantDatesTabState extends State<StudentImportantDatesTab> {
  final DateFormat _displayFormatter = DateFormat('MMM dd, yyyy');

  bool _isLoading = true;
  String? _errorMessage;
  StudentImportantDates? _dates;

  @override
  void initState() {
    super.initState();
    _loadDates();
  }

  Future<void> _loadDates() async {
    final studentCode = widget.studentCode ?? '';
    if (studentCode.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = StudentStrings.studentCodeIsRequired;
        _dates = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final useCase = serviceLocator<GetStudentImportantDatesUseCase>();
      final result = await useCase(studentCode: studentCode);

      if (!mounted) return;

      result.fold(
        (failure) {
          setState(() {
            _isLoading = false;
            _errorMessage =
                failure.message ?? StudentStrings.failedToLoadImportantDates;
            _dates = null;
          });
        },
        (dates) {
          setState(() {
            _isLoading = false;
            _errorMessage = null;
            _dates = dates;
          });
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = StudentStrings.failedToLoadImportantDates;
        _dates = null;
      });
    }
  }

  String _format(DateTime? date) {
    if (date == null) return '-';
    return _displayFormatter.format(date);
  }

  Future<void> _openEdit(BuildContext context) async {
    final role = context.read<RoleCubit>();
    if (!ModuleAccess.mayWrite(role, AppAccessModules.student) ||
        role.isStaff) {
      ModuleAccess.showWriteRestricted(context);
      return;
    }
    final studentCode = widget.studentCode ?? '';
    if (studentCode.isEmpty) return;

    final result = await context.push<bool>(
      EditStudentImportantDatesScreen.routeName,
      extra: <String, dynamic>{
        'studentCode': studentCode,
        'initialEnrollDate': _dates?.enrollDate,
        'initialSchoolStartDate': _dates?.schoolStartDate,
      },
    );

    if (result == true && mounted) {
      await _loadDates();
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<RoleCubit>();
    final canStudentWrite =
        ModuleAccess.mayWrite(role, AppAccessModules.student) &&
        !role.isStaff &&
        !role.isParent;
    final studentCode = widget.studentCode ?? '';
    if (studentCode.isEmpty) {
      return Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(color: AppColors.pageBackgroundColor),
          ),
          MediaQuery.removePadding(
            context: context,
            removeLeft: true,
            removeRight: true,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  StudentStrings.studentCodeIsRequiredToLoadImportantDates,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.primaryColor.withValues(alpha: 0.7),
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final entries = <MapEntry<String, String>>[
      MapEntry(StudentStrings.enrollDate, _format(_dates?.enrollDate)),
      MapEntry(
        StudentStrings.schoolStartDate,
        _format(_dates?.schoolStartDate),
      ),
      MapEntry(
        StudentStrings.currentClassroomStartDate,
        _format(_dates?.currentClassroomStartDate),
      ),
      MapEntry(
        StudentStrings.upcomingMovingDate,
        _format(_dates?.upcomingMoveDate),
      ),
      MapEntry(
        StudentStrings.schoolLeavingDate,
        _format(_dates?.schoolLeavingDate),
      ),
    ];

    return Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(color: AppColors.pageBackgroundColor),
        ),
        MediaQuery.removePadding(
          context: context,
          removeLeft: true,
          removeRight: true,
          child: CustomRefreshIndicator(
            onRefresh: _loadDates,
            child: SingleChildScrollView(
              controller: widget.scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.none,
                  vertical: AppSpacing.md,
                ),
                padding: const EdgeInsets.all(AppSpacing.xs),
                // Match the Family/Pickup cards: themeColor outline, square top-left.
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          StudentStrings.importantDates,
                          style: AppTextStyles.title,
                        ),
                        if (canStudentWrite)
                          GestureDetector(
                            onTap: () => _openEdit(context),
                            child: SkeuKeyBox(
                              variant: KeyVariant.primary,
                              radius: AppRadius.sm,
                              width: 38,
                              height: 38,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.edit,
                                size: 22,
                                color: AppColors.whiteColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                    AppSpacing.gapVMd,
                    if (_isLoading)
                      const StudentImportantDatesShimmer()
                    else if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppColors.errorColor,
                            fontSize: 14,
                          ),
                        ),
                      )
                    else
                      ...List.generate(entries.length * 2 - 1, (i) {
                        if (i.isOdd) return AppSpacing.gapVMd;
                        final idx = i ~/ 2;
                        final e = entries[idx];
                        return _DateRow(label: e.key, text: e.value);
                      }),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.label, required this.text});
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final displayText =
        (text.trim().isEmpty || text.trim().toLowerCase() == 'no cda')
        ? '-'
        : text;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: AppTextStyles.value.copyWith(
              color: AppColors.primaryColor.withValues(alpha: 0.5),
              fontSize: 14,
              letterSpacing: 14 * (-3 / 100),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        AppSpacing.gapHSm,
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  displayText,
                  textAlign: TextAlign.end,
                  style: AppTextStyles.value.copyWith(fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
