import 'dart:async';
import 'package:wowcare/core/util/app_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_profile.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/student_attendance_profile_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_card_header.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/dashboard_error_chip.dart';
import 'package:wowcare/shared/common/app/cubit/parent_child_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';

class StudentAttendanceCard extends StatefulWidget {
  const StudentAttendanceCard({super.key});

  @override
  State<StudentAttendanceCard> createState() => _StudentAttendanceCardState();
}

class _StudentAttendanceCardState extends State<StudentAttendanceCard>
    with AutomaticKeepAliveClientMixin {
  bool _minimized = false;
  late DateTime _fromDate;
  late DateTime _toDate;
  String _selectedChildCode = '';

  @override
  void initState() {
    super.initState();
    final now = AppTime.now();
    _fromDate = DateTime(now.year, now.month, 1);
    _toDate = now;
  }

  void _onDateRangeSelected(DateTime start, DateTime? end) {
    setState(() {
      _fromDate = start;
      if (end != null) {
        _toDate = end;
      }
    });
    unawaited(_loadAttendanceData(context, forceRefresh: true));
  }

  Future<void> _loadAttendanceData(
    BuildContext context, {
    bool forceRefresh = false,
  }) async {
    final parentChildProvider = Provider.of<ParentChildCubit>(
      context,
      listen: false,
    );
    final selectedChild = parentChildProvider.selectedChild;
    if (selectedChild != null) {
      await context.read<StudentAttendanceProfileCubit>().loadAttendanceProfile(
        studentCode: selectedChild.code,
        fromDate: _fromDate,
        toDate: _toDate,
        forceRefresh: forceRefresh,
      );
    }
  }

  void _openStudentAttendanceProfile(BuildContext context) {
    final selectedChild = context.read<ParentChildCubit>().state.selectedChild;
    if (selectedChild == null) return;

    unawaited(
      context.push(
        StudentAttendanceProfile.routeName,
        extra: <String, dynamic>{
          'studentCode': selectedChild.code,
          'studentId': 0,
          'studentName': selectedChild.name,
          'studentPhotoUuid': null,
          'roomName':
              (selectedChild.primaryClassroomName ?? selectedChild.classroom)
                  .trim()
                  .isNotEmpty
              ? (selectedChild.primaryClassroomName ?? selectedChild.classroom)
              : '—',
          'isSignedIn': false,
          'syncWithParentChildSelection': true,
        },
      ),
    );
  }

  Widget _buildSelectedChildName() {
    return BlocBuilder<ParentChildCubit, ParentChildState>(
      builder: (context, state) {
        final selectedChild = state.selectedChild;
        if (selectedChild == null) {
          return Text(
            'No Child Selected',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.primaryColor,
            ),
          );
        }

        final children = state.children;
        if (children.length <= 1) {
          return Padding(
            padding: const EdgeInsets.only(left: 25),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    DocumentImageWidget(
                      fileUuid: '',
                      name: selectedChild.name,
                      size: 30,
                      fontSize: 12,
                      disableProfileLookupFallback: true,
                      disableAttendanceStatusLookup: true,
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    selectedChild.name,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(left: 25),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<ParentChildRef>(
              // Fill the fixed-width parent so the internal [item, arrow] Row
              // is bounded and the Flexible name ellipsizes instead of
              // overflowing (was ~1.7px over on long names).
              isExpanded: true,
              value: children.any((c) => c.code == selectedChild.code)
                  ? selectedChild
                  : null,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.primaryColor,
              ),
              borderRadius: BorderRadius.circular(12),
              dropdownColor: Colors.white,
              onChanged: (next) {
                if (next == null) return;
                context.read<ParentChildCubit>().selectByCode(next.code);
              },
              selectedItemBuilder: (context) {
                return children
                    .map((child) {
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            children: [
                              DocumentImageWidget(
                                fileUuid: '',
                                name: child.name,
                                size: 30,
                                fontSize: 12,
                                disableProfileLookupFallback: true,
                                disableAttendanceStatusLookup: true,
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              child.name.length > 8
                                  ? '${child.name.substring(0, 8)}...'
                                  : child.name,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      );
                    })
                    .toList(growable: false);
              },
              items: children
                  .map(
                    (child) => DropdownMenuItem<ParentChildRef>(
                      value: child,
                      child: Row(
                        children: [
                          DocumentImageWidget(
                            fileUuid: '',
                            name: child.name,
                            size: 26,
                            fontSize: 11,
                            disableProfileLookupFallback: true,
                            disableAttendanceStatusLookup: true,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              child.name,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem({
    required String icon,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SvgPicture.asset(icon, height: 30),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyLarge,
            ),
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 50, minHeight: 50),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: valueColor, width: 1.5),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(StudentAttendanceProfileState state) {
    if (state.isLoading) {
      return const StudentAttendanceCardShimmer();
    }

    // On error, fall through to the normal stats layout below — it renders
    // default/empty values (e.g. "0 Hrs 0 Mins") instead of an error banner.

    // final attendedHoursDisplay = state.totalAttendedTime.isNotEmpty
    //     ? state.totalAttendedTime
    //     : '0h 0m';

    final attendedTime = state.totalAttendedTime.isNotEmpty
        ? state.totalAttendedTime
        : '0 Hrs 0 Mins';

    final hourMatch = RegExp(r'(\d+)\s*Hrs').firstMatch(attendedTime);
    final minuteMatch = RegExp(r'(\d+)\s*Mins').firstMatch(attendedTime);

    final hours = hourMatch?.group(1) ?? '0';
    final minutes = minuteMatch?.group(1) ?? '0';
    return Column(
      children: [
        _buildStatItem(
          icon: MediaRes.calenderClockIcon,
          label: 'Attended Days',
          value: '${state.attendedDays}',
          valueColor: const Color(0xFF4CAF50),
        ),
        const SizedBox(height: 16),
        // _buildStatItem(
        //   icon: MediaRes.timerIcon,
        //   label: 'Attended Hours',
        //   value: attendedHoursDisplay,
        //   valueColor: const Color(0xFF4285F4),
        // ),
        _buildAttendanceHoursItem(
          icon: MediaRes.timerIcon,
          label: 'Attended Hours',
          hours: hours,
          minutes: minutes,
          valueColor: const Color(0xFF4285F4),
        ),
        const SizedBox(height: 16),
        _buildStatItem(
          icon: MediaRes.calenderClockIcon,
          label: 'Absent Days',
          value: '${state.absentDays}',
          valueColor: Colors.red,
        ),
      ],
    );
  }

  Widget _buildAttendanceHoursItem({
    required String icon,
    required String label,
    required String hours,
    required String minutes,
    required Color valueColor,
  }) {
    Widget buildCircle(String value) {
      return Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: valueColor, width: 1.5),
        ),
        child: Center(
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SvgPicture.asset(icon, height: 30),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyLarge,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              children: [
                buildCircle('${hours}H'),
                const SizedBox(width: 8),
                buildCircle('${minutes}M'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final parentChildProvider = Provider.of<ParentChildCubit>(context);
    final selectedChild = parentChildProvider.selectedChild;
    final nextCode = (selectedChild?.code ?? '').trim();
    if (nextCode != _selectedChildCode) {
      _selectedChildCode = nextCode;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(_loadAttendanceData(context));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isError = context
        .watch<StudentAttendanceProfileCubit>()
        .state
        .isError;
    return DashboardCardErrorOverlay(
      show: isError,
      onRetry: () => _loadAttendanceData(context, forceRefresh: true),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: AppColors.primaryColor.withValues(alpha: 0.2),
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.primaryColor.withValues(alpha: 0.1),
          highlightColor: AppColors.primaryColor.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DashboardCardHeader(
                  title: 'Attendance',
                  minimized: _minimized,
                  onToggle: () => setState(() => _minimized = !_minimized),
                  showRedirect: true,
                  onRedirect: () => _openStudentAttendanceProfile(context),
                  trailing: Expanded(child: _buildSelectedChildName()),
                ),
                if (!_minimized) ...[
                  const SizedBox(height: 16),
                  CustomDateTimeField(
                    hasLabel: false,
                    isRangePicker: true,
                    initialDate: _fromDate,
                    label: 'Date Range',
                    onRangeSelected: _onDateRangeSelected,
                  ),
                  const SizedBox(height: 20),
                  BlocBuilder<
                    StudentAttendanceProfileCubit,
                    StudentAttendanceProfileState
                  >(
                    buildWhen: (prev, curr) =>
                        prev.status != curr.status ||
                        prev.attendedDays != curr.attendedDays ||
                        prev.absentDays != curr.absentDays ||
                        prev.attendedHours != curr.attendedHours ||
                        prev.attendedMinutes != curr.attendedMinutes,
                    builder: (context, state) {
                      return _buildStats(state);
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
