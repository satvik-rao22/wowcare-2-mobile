import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/skeu/skeu.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/domain/features/classroom/repositories/classroom_repository.dart';
import 'package:wowcare/core/util/cache_manager.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/presentation/features/students/view/student_screen.dart';

class ClassroomOverviewScreen extends StatefulWidget {
  const ClassroomOverviewScreen({super.key, this.initialStudentFilter});
  static const routeName = '/classroom-overview-screen';
  final String? initialStudentFilter;

  @override
  State<ClassroomOverviewScreen> createState() =>
      _ClassroomOverviewScreenState();
}

class _ClassroomOverviewScreenState extends State<ClassroomOverviewScreen> {
  late final CacheManager _cacheManager;
  String? _selectedClassroomCode;

  int _enrolledCount = 0;
  int _activeCount = 0;
  int _upcomingCount = 0;

  bool _loadedFromCacheOnce = false;

  @override
  void initState() {
    super.initState();
    _cacheManager = CacheManager(serviceLocator());
    if (widget.initialStudentFilter != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go(
            StudentScreen.routeName,
            extra: {'filter': widget.initialStudentFilter},
          );
        }
      });
    }
  }

  String _enrolledCountCacheKey(String classroomCode) {
    return CacheManager.buildCacheKey(
      feature: 'classroom',
      resource: 'enrolled_count',
      identifier: classroomCode.trim(),
    );
  }

  Future<void> _hydrateEnrolledCountFromCache(String classroomCode) async {
    final key = _enrolledCountCacheKey(classroomCode);
    final cached = await _cacheManager.loadCache(key);
    if (cached == null || !mounted) return;

    final data = cached['data'];
    if (data is! Map) return;
    final map = Map<String, dynamic>.from(data);

    setState(() {
      _enrolledCount =
          (map['enrolledCount'] as num?)?.toInt() ?? _enrolledCount;
      _activeCount = (map['activeCount'] as num?)?.toInt() ?? _activeCount;
      _upcomingCount =
          (map['upcomingCount'] as num?)?.toInt() ?? _upcomingCount;
      _loadedFromCacheOnce = true;
    });
  }

  Future<void> _fetchAndCacheEnrolledCount(String classroomCode) async {
    final code = classroomCode.trim();
    if (code.isEmpty) return;

    final body = await serviceLocator<ClassroomRepository>()
        .getStudentClassroomEnrolledCount(classroomCode: code);
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected enrolled-count API response format');
    }
    final data = body['data'];
    if (data is! Map) {
      throw Exception('Unexpected enrolled-count API data format');
    }

    final dataMap = Map<String, dynamic>.from(data);
    final active = (dataMap['activeCount'] as num?)?.toInt() ?? 0;
    final upcoming = (dataMap['upcomingCount'] as num?)?.toInt() ?? 0;
    final enrolled = (dataMap['enrolledCount'] as num?)?.toInt() ?? 0;

    await _cacheManager.saveCache(_enrolledCountCacheKey(code), {
      'data': {
        'activeCount': active,
        'upcomingCount': upcoming,
        'enrolledCount': enrolled,
      },
    });

    if (!mounted) return;
    setState(() {
      _activeCount = active;
      _upcomingCount = upcoming;
      _enrolledCount = enrolled;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ClassroomCubit>(
      create: (_) =>
          serviceLocator<ClassroomCubit>()
            ..loadActiveClassrooms(applyAttendanceStaffScope: true),
      child: BlocBuilder<ClassroomCubit, ClassroomState>(
        builder: (context, state) {
          final totalClassrooms = state.classrooms.length;
          final firstCode = state.classrooms.isNotEmpty
              ? state.classrooms.first.code.trim()
              : '';
          final effectiveCode = (_selectedClassroomCode ?? '').trim().isNotEmpty
              ? _selectedClassroomCode!.trim()
              : firstCode;

          if (effectiveCode.isNotEmpty &&
              effectiveCode != _selectedClassroomCode) {
            _selectedClassroomCode = effectiveCode;
            // No loader: show cached values immediately if available, then refresh.
            if (!_loadedFromCacheOnce) {
              _hydrateEnrolledCountFromCache(effectiveCode);
            }
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              try {
                await _fetchAndCacheEnrolledCount(effectiveCode);
              } catch (_) {
                // Keep cached/last values; no blocking UI.
              }
            });
          }

          return GlobalScaffold(
            hasBackButton: false,
            bodyPadding: EdgeInsets.zero,
            body: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _EnrollmentOverviewCard(
                            totalClassrooms: totalClassrooms,
                            enrolledCount: _enrolledCount,
                            activeCount: _activeCount,
                            upcomingCount: _upcomingCount,
                          ),
                          const SizedBox(height: 16),
                          const _RatioMonitoringPlaceholder(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _EnrollmentOverviewCard extends StatelessWidget {
  const _EnrollmentOverviewCard({
    required this.totalClassrooms,
    required this.enrolledCount,
    required this.activeCount,
    required this.upcomingCount,
  });

  final int totalClassrooms;
  final int enrolledCount;
  final int activeCount;
  final int upcomingCount;

  @override
  Widget build(BuildContext context) {
    return SkeuPanel(
      radius: SkeuRadius.xxl,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),

      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: _HeaderStat(value: '', label: 'Total\nClassrooms'),
              ),
              Expanded(
                child: _HeaderStat(
                  value: '$totalClassrooms',
                  label: 'Total\nClassrooms',
                ),
              ),
              const Expanded(
                child: _HeaderStat(value: '0', label: 'Total\nCapacity'),
              ),
              const Expanded(
                child: _HeaderStat(value: '0%', label: 'Full time\nEquivalent'),
              ),
            ],
          ),
          Divider(color: AppColors.primaryColor.withValues(alpha: 0.15)),
          const SizedBox(height: 12),
          _SectionRow(
            title: 'Enrolled Students',
            value: '$enrolledCount',
            leftLabel: 'Active ($activeCount)',
            leftColor: AppColors.lightBlueProgressBar,
            rightLabel: 'Upcoming ($upcomingCount)',
            rightColor: AppColors.mustardProgressBar,
            leftValue: activeCount.toDouble(),
            rightValue: upcomingCount.toDouble(),
            onTitleTap: () {
              context.go(StudentScreen.routeName);
            },
            onLeftTap: () {
              context.go(StudentScreen.routeName, extra: {'filter': 'ACTIVE'});
            },
            onRightTap: () {
              context.go(
                StudentScreen.routeName,
                extra: {'filter': 'UPCOMING'},
              );
            },
          ),
          const SizedBox(height: 16),
          _SectionRow(
            title: 'Expected Students',
            value: '0',
            leftLabel: 'Present (0)',
            leftColor: AppColors.lightGreenProgressBar,
            rightLabel: 'Absent (0)',
            rightColor: AppColors.redProgressBar,
          ),
          const SizedBox(height: 16),
          _SectionRow(
            title: 'Expected Staff',
            value: '0',
            leftLabel: 'Present (0)',
            leftColor: AppColors.lightGreenProgressBar,
            rightLabel: 'Absent (0)',
            rightColor: AppColors.redProgressBar,
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.themeColor,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Manrope',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.w600,
            fontFamily: 'Manrope',
          ),
        ),
      ],
    );
  }
}

class _SectionRow extends StatelessWidget {
  const _SectionRow({
    required this.title,
    required this.value,
    required this.leftLabel,
    required this.leftColor,
    required this.rightLabel,
    required this.rightColor,
    this.leftValue = 0,
    this.rightValue = 0,
    this.onTitleTap,
    this.onLeftTap,
    this.onRightTap,
  });

  final String title;
  final String value;
  final String leftLabel;
  final Color leftColor;
  final String rightLabel;
  final Color rightColor;
  final double leftValue;
  final double rightValue;
  final VoidCallback? onTitleTap;
  final VoidCallback? onLeftTap;
  final VoidCallback? onRightTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        onTitleTap != null
            ? GestureDetector(
                onTap: onTitleTap,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Manrope',
                      ),
                    ),
                    Text(
                      value,
                      style: const TextStyle(
                        color: AppColors.themeColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Manrope',
                      ),
                    ),
                  ],
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Manrope',
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.themeColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Manrope',
                    ),
                  ),
                ],
              ),
        const SizedBox(height: 16),
        SkeuWell(
          height: 24,
          radius: 10,
          gradient: SkeuSurfaces.sunken,
          insets: SkeuElevation.wellSm,
          child: Row(
            children: [
              Expanded(
                flex: (leftValue <= 0 && rightValue <= 0)
                    ? 1
                    : (leftValue * 100).round().clamp(1, 1000000),
                child: ColoredBox(color: leftColor),
              ),
              Expanded(
                flex: (leftValue <= 0 && rightValue <= 0)
                    ? 1
                    : (rightValue * 100).round().clamp(1, 1000000),
                child: ColoredBox(color: rightColor),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: onLeftTap != null
                  ? GestureDetector(
                      onTap: onLeftTap,
                      child: _LegendDot(color: leftColor, label: leftLabel),
                    )
                  : _LegendDot(color: leftColor, label: leftLabel),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: onRightTap != null
                  ? GestureDetector(
                      onTap: onRightTap,
                      child: _LegendDot(color: rightColor, label: rightLabel),
                    )
                  : _LegendDot(color: rightColor, label: rightLabel),
            ),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.primaryColor.withValues(alpha: 0.8),
              fontSize: 13,
              fontFamily: 'Manrope',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _RatioMonitoringPlaceholder extends StatelessWidget {
  const _RatioMonitoringPlaceholder();

  @override
  Widget build(BuildContext context) {
    return SkeuPanel(
      radius: SkeuRadius.xxl,
      padding: const EdgeInsets.all(8),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 4, 4, 8),
            child: Text(
              'Ratio Monitoring',
              style: TextStyle(
                color: AppColors.primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                fontFamily: 'Manrope',
              ),
            ),
          ),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(1.1),
              2: FlexColumnWidth(1),
              3: FlexColumnWidth(1),
            },
            children: [_ratioHeaderRow(), _ratioEmptyRow()],
          ),
        ],
      ),
    );
  }

  TableRow _ratioHeaderRow() {
    return const TableRow(
      children: [
        _RatioHeaderCell(
          mainText: 'Classroom',
          subText: '',
          backgroundColor: Color.fromRGBO(249, 245, 250, 1),
        ),
        _RatioHeaderCell(
          mainText: 'Students',
          subText: 'Present',
          backgroundColor: Color.fromRGBO(234, 240, 253, 1),
        ),
        _RatioHeaderCell(
          mainText: 'Staff',
          subText: 'Present',
          backgroundColor: Color.fromRGBO(234, 251, 255, 1),
        ),
        _RatioHeaderCell(
          mainText: 'Ratio',
          subText: 'Current',
          backgroundColor: Color.fromRGBO(255, 245, 234, 1),
        ),
      ],
    );
  }

  TableRow _ratioEmptyRow() {
    const cellHeight = 50.0;
    return const TableRow(
      children: [
        SizedBox(height: cellHeight),
        SizedBox(height: cellHeight),
        SizedBox(height: cellHeight),
        SizedBox(height: cellHeight),
      ],
    );
  }
}

class _RatioHeaderCell extends StatelessWidget {
  const _RatioHeaderCell({
    required this.mainText,
    required this.subText,
    required this.backgroundColor,
  });

  final String mainText;
  final String subText;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      color: backgroundColor,
      child: Column(
        children: [
          const Expanded(child: SizedBox()),
          if (subText.isNotEmpty) ...[
            Text(
              mainText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color.fromRGBO(10, 28, 93, 1),
                fontFamily: 'Manrope',
              ),
            ),
            const SizedBox(height: 20),
            Text(
              subText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
                fontFamily: 'Manrope',
              ),
            ),
          ] else
            Text(
              mainText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
                fontFamily: 'Manrope',
              ),
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
