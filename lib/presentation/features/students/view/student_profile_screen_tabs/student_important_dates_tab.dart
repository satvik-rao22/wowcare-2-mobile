import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/presentation/features/student/module_access.dart';
import 'package:wowcare/shared/common/app/providers/role_provider.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/domain/features/student/entities/student_important_dates.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_important_dates_usecase.dart';
import 'package:wowcare/presentation/features/students/view/edit_student_important_dates_screen.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';

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
        _errorMessage = 'Student code is required';
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
                failure.message ?? 'Failed to load important dates';
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
        _errorMessage = 'Failed to load important dates';
        _dates = null;
      });
    }
  }

  String _format(DateTime? date) {
    if (date == null) return '-';
    return _displayFormatter.format(date);
  }

  Future<void> _openEdit(BuildContext context) async {
    final role = context.read<RoleProvider>();
    if (!ModuleAccess.mayWrite(role, AppAccessModules.student)) {
      ModuleAccess.showWriteRestricted(context);
      return;
    }
    final studentCode = widget.studentCode ?? '';
    if (studentCode.isEmpty) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => EditStudentImportantDatesScreen(
          studentCode: studentCode,
          initialEnrollDate: _dates?.enrollDate,
          initialSchoolStartDate: _dates?.schoolStartDate,
        ),
      ),
    );

    if (result == true && mounted) {
      await _loadDates();
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<RoleProvider>();
    final canStudentWrite = ModuleAccess.mayWrite(role, AppAccessModules.student);
    final studentCode = widget.studentCode ?? '';
    if (studentCode.isEmpty) {
      return Stack(
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
          MediaQuery.removePadding(
            context: context,
            removeLeft: true,
            removeRight: true,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Student code is required to load important dates',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.primaryColor.withOpacity(0.7),
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
      MapEntry('Enroll Date', _format(_dates?.enrollDate)),
      MapEntry('School Start Date', _format(_dates?.schoolStartDate)),
      MapEntry('Current Classroom Start Date', _format(_dates?.currentClassroomStartDate)),
      MapEntry('Upcoming Moving Date', _format(_dates?.upcomingMoveDate)),
      MapEntry('School Leaving Date', _format(_dates?.schoolLeavingDate)),
    ];

    return Stack(
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
                margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.cardBorderColor, width: 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Important Dates',
                          style: AppTextStyles.title,
                        ),
                        if (canStudentWrite)
                          GestureDetector(
                            onTap: () => _openEdit(context),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                gradient: AppColors.buildPrimaryGradient(),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.edit,
                                size: 22,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: PrimaryCircularLoader(size: 32),
                        ),
                      )
                    else if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 14,
                          ),
                        ),
                      )
                    else
                      ...List.generate(entries.length * 2 - 1, (i) {
                        if (i.isOdd) return const SizedBox(height: 16);
                        final idx = i ~/ 2;
                        final e = entries[idx];
                        return _DateRow(
                          label: e.key,
                          text: e.value,
                        );
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
              color: AppColors.primaryColor.withOpacity(0.5),
              fontSize: 14,
              letterSpacing: 14 * (-3 / 100),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  displayText,
                  textAlign: TextAlign.end,
                  style: AppTextStyles.value.copyWith(
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
