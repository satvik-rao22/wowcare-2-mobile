import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/staff/view/edit_profile_details_screen.dart';
import 'package:wowcare/presentation/features/staff/view/edit_schedule_screen.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_profile_cubit.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/api_error_handler.dart';

class StaffProfileTab extends StatefulWidget {
  const StaffProfileTab({
    super.key,
    required this.staffCode,
    this.classroomNames,
    this.classroomNameByCode,
  });

  final String staffCode;
  /// Optional cached classroom display names (from StaffScreen).
  final List<String>? classroomNames;
  /// Optional mapping from classroom code -> display name (from StaffScreen).
  final Map<String, String>? classroomNameByCode;

  @override
  State<StaffProfileTab> createState() => _StaffProfileTabState();
}

class _StaffProfileTabState extends State<StaffProfileTab> {
  late final StaffProfileCubit _profileCubit;

  @override
  void initState() {
    super.initState();
    _profileCubit = serviceLocator<StaffProfileCubit>()
      ..loadInitial(widget.staffCode);
  }

  @override
  void dispose() {
    _profileCubit.close();
    super.dispose();
  }

  static const List<String> _allDays = [
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
  ];

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatPhoneNumber(String? number) {
    if (number == null || number.isEmpty) return '-';
    final digits = number.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) return number;
    return '(${digits.substring(0, 3)}) ${digits.substring(3, 6)}-${digits.substring(6, 10)}';
  }

  String _getStatusLabel(String? status) {
    if (status == null || status.isEmpty) return '-';
    if (status.toUpperCase() == 'ACTIVE' || status == 'A') return 'Active';
    if (status.toUpperCase() == 'INACTIVE' || status == 'I') return 'Inactive';
    return status;
  }

  Color _getStatusColor(String? status) {
    if (status == null || status.isEmpty) return Colors.grey;
    final upperStatus = status.toUpperCase();
    if (upperStatus == 'ACTIVE' || status == 'A') {
      return const Color.fromRGBO(56, 200, 32, 1);
    }
    if (upperStatus == 'INACTIVE' || status == 'I') {
      return const Color.fromRGBO(250, 65, 65, 1);
    }
    return const Color.fromARGB(255, 238, 223, 8);
  }

  Color _getStatusBgColor(String? status) {
    if (status == null || status.isEmpty) return Colors.grey.withOpacity(0.1);
    final upperStatus = status.toUpperCase();
    if (upperStatus == 'ACTIVE' || status == 'A') {
      return const Color.fromRGBO(56, 200, 32, 0.1);
    }
    if (upperStatus == 'INACTIVE' || status == 'I') {
      return const Color.fromRGBO(250, 65, 65, 0.1);
    }
    return const Color.fromARGB(255, 242, 238, 176);
  }

  @override
  Widget build(BuildContext context) {
    final chipColors = <Color>[
      const Color.fromRGBO(177, 175, 233, 0.3),
      const Color.fromRGBO(203, 246, 255, 0.4),
      const Color.fromRGBO(217, 255, 203, 0.4),
    ];

    return BlocProvider<StaffProfileCubit>.value(
      value: _profileCubit,
      child: BlocListener<StaffProfileCubit, StaffProfileState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            CoreUtils.showTopSnackBar(
              context: context,
              message: ApiErrorHandler.extractErrorMessage(state.errorMessage),
              isError: true,
            );
          }
        },
        child: BlocBuilder<StaffProfileCubit, StaffProfileState>(
          builder: (context, state) {
            if (state.isLoading && state.profile == null) {
              return const Center(child: PrimaryCircularLoader());
            }

            final profile = state.profile;
            if (profile == null) {
              return Center(
                child: Text(
                  state.errorMessage ?? 'Failed to load profile',
                  style: const TextStyle(color: Colors.redAccent),
                ),
              );
            }

            // Build work and break times maps
            final workTimes = <String, String>{};
            final breakTimes = <String, String>{};
            final availableDays = <String>{};

            for (final schedule in profile.workSchedules) {
              final day = schedule.dayOfWeek;
              availableDays.add(day);
              workTimes[day] = schedule.formattedTime;
            }

            for (final schedule in profile.breakSchedules) {
              final day = schedule.dayOfWeek;
              breakTimes[day] = schedule.formattedTime;
            }

            return CustomRefreshIndicator(
              onRefresh: () async {
                await _profileCubit.refresh(widget.staffCode);
              },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.themeColor),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(12),
            bottom: Radius.circular(16),
          ),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Profile Information',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    // Map allowed/primary classroom codes to display names using cached metadata.
                    final codeToName = widget.classroomNameByCode ?? const {};
                    final allowedClassroomNames = profile.allowedClassroomCodes
                        .map((code) => codeToName[code] ?? code)
                        .toList();
                    final primaryClassroomName = profile.primaryClassroomCode.isEmpty
                        ? null
                        : (codeToName[profile.primaryClassroomCode] ??
                            profile.primaryClassroomCode);

                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProfileDetailsScreen(
                          staffCode: profile.staffCode,
                          initialFirstName: profile.firstName,
                          initialLastName: profile.lastName,
                          initialStatus: _getStatusLabel(profile.status),
                          initialDesignation: profile.designation,
                          initialAllowedClassrooms: allowedClassroomNames,
                          initialPrimaryClassroom: primaryClassroomName,
                          initialBirthDate: profile.birthDate.isEmpty
                              ? null
                              : DateTime.tryParse(profile.birthDate),
                          initialJobTag: profile.jobTag,
                          initialEmail: profile.email,
                          initialPhoneNumber: profile.phoneNumber,
                          initialStreet: profile.address.street,
                          initialCity: profile.address.city,
                          initialState: profile.address.state,
                          initialCountry: profile.address.country,
                          initialZipCode: profile.address.zipCode,
                          initialClassroomNames: widget.classroomNames,
                          initialClassroomCodeByName: widget.classroomNameByCode == null
                              ? null
                              : {
                                  for (final entry
                                      in widget.classroomNameByCode!.entries)
                                    entry.value: entry.key,
                                },
                        ),
                      ),
                    );

                    // If profile was updated, refresh from API.
                    if (result == true) {
                      await _profileCubit.refresh(widget.staffCode);
                    }
                  },
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
            _Field(label: 'Name', value: profile.fullName.isEmpty ? '-' : profile.fullName),
            const SizedBox(height: 16),
            _Field(
              label: 'Status',
              value: null,
              trailing: _buildStatusChip(profile.status),
            ),
            const SizedBox(height: 12),
            _Field(label: 'Designation', value: profile.designation.isEmpty ? '-' : profile.designation),
            const SizedBox(height: 16),
            _Field(label: 'Email', value: profile.email.isEmpty ? '-' : profile.email),
            const SizedBox(height: 16),
            _Field(
                label: 'Clock In-Out PIN',
                value: profile.clockPin.isEmpty ? '-' : profile.clockPin),
            const SizedBox(height: 16),
            _Field(
              label: 'Phone Number',
              value: _formatPhoneNumber(profile.phoneNumber),
            ),
            const SizedBox(height: 16),
            _Field(
              label: 'Address',
              value: profile.address.formattedAddress.isEmpty ? '-' : profile.address.formattedAddress,
            ),
            const SizedBox(height: 16),
            _Field(
              label: 'Birth Date',
              value: _formatDate(profile.birthDate),
            ),
            const SizedBox(height: 16),
            _Field(
              label: 'Job Tag',
              value: profile.jobTag.isEmpty ? '-' : profile.jobTag,
            ),
            const SizedBox(height: 16),
            _Field(
              label: 'Allowed Classrooms',
              value: null,
              trailing: profile.allowedClassroomCodes.isEmpty
                  ? const Text(
                      '-',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 15,
                        color: Color(0xff573353),
                        fontWeight: FontWeight.w400,
                      ),
                    )
                  : Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: List.generate(
                        profile.allowedClassroomCodes.length,
                        (index) {
                          final code = profile.allowedClassroomCodes[index];
                          final name =
                              widget.classroomNameByCode?[code] ?? code;
                          return _Chip(
                            label: name,
                            labelColor: const Color.fromRGBO(27, 35, 126, 1),
                            color: chipColors[index % chipColors.length],
                          );
                        },
                      ),
                    ),
            ),
            const SizedBox(height: 12),
            _Field(
              label: 'Primary Classroom',
              value: null,
              trailing: profile.primaryClassroomCode.isEmpty
                  ? const Text(
                      '-',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 15,
                        color: Color(0xff573353),
                        fontWeight: FontWeight.w400,
                      ),
                    )
                  : _Chip(
                      label: widget.classroomNameByCode?[
                              profile.primaryClassroomCode] ??
                          profile.primaryClassroomCode,
                      labelColor: const Color.fromRGBO(27, 35, 126, 1),
                      color: chipColors.first,
                    ),
            ),
          // Availability + surrounding area navigates to EditScheduleScreen
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              // Convert profile schedules to ScheduleEntry format for EditScheduleScreen
              final schedules = <ScheduleEntry>[];
              for (final workSchedule in profile.workSchedules) {
                schedules.add(ScheduleEntry(
                  day: workSchedule.dayOfWeek.toLowerCase(),
                  startTime: workSchedule.workStartTime.formattedTime,
                  endTime: workSchedule.workEndTime.formattedTime,
                  isBreakTime: false,
                ));
              }
              for (final breakSchedule in profile.breakSchedules) {
                schedules.add(ScheduleEntry(
                  day: breakSchedule.dayOfWeek.toLowerCase(),
                  startTime: breakSchedule.breakStartTime.formattedTime,
                  endTime: breakSchedule.breakEndTime.formattedTime,
                  isBreakTime: true,
                ));
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditScheduleScreen(
                    staffCode: widget.staffCode,
                    initialSchedules: schedules,
                  ),
                ),
              ).then((updated) async {
                if (updated == true) {
                  await _profileCubit.refresh(widget.staffCode);
                }
              });
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Availability with edit icon on the right, chips below
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Availability',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xff573353),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        final schedules = <ScheduleEntry>[];
                        for (final workSchedule in profile.workSchedules) {
                          schedules.add(ScheduleEntry(
                            day: workSchedule.dayOfWeek.toLowerCase(),
                            startTime: workSchedule.workStartTime.formattedTime,
                            endTime: workSchedule.workEndTime.formattedTime,
                            isBreakTime: false,
                          ));
                        }
                        for (final breakSchedule in profile.breakSchedules) {
                          schedules.add(ScheduleEntry(
                            day: breakSchedule.dayOfWeek.toLowerCase(),
                            startTime: breakSchedule.breakStartTime.formattedTime,
                            endTime: breakSchedule.breakEndTime.formattedTime,
                            isBreakTime: true,
                          ));
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditScheduleScreen(
                              staffCode: widget.staffCode,
                              initialSchedules: schedules,
                            ),
                          ),
                        ).then((updated) async {
                          if (updated == true) {
                            await _profileCubit.refresh(widget.staffCode);
                          }
                        });
                      },
                      child: const Icon(
                        Icons.edit,
                        size: 16,
                        color: Color(0x99573353),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _allDays.map((day) {
                          final isAvailable = availableDays.contains(day);
                          final displayDay = day.substring(0, 1) + day.substring(1).toLowerCase();
                          return Opacity(
                            opacity: isAvailable ? 1 : 0.4,
                            child: _Chip(
                              label: displayDay,
                              labelColor: isAvailable
                                  ? const Color.fromRGBO(27, 35, 126, 1)
                                  : Colors.grey[700]!,
                              color: isAvailable
                                  ? const Color.fromRGBO(203, 246, 255, 0.4)
                                  : const Color(0xFFF3F4FB),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _Field(
                  label: 'Work Time',
                  value: null,
                  trailing: Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _allDays.map((day) {
                            final isAvailable = availableDays.contains(day);
                            final String value = workTimes[day] ?? '-';
                            return Opacity(
                              opacity: isAvailable ? 1 : 0.4,
                              child: _TimeChip(label: value),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _Field(
                  label: 'Break Time',
                  value: null,
                  trailing: Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _allDays.map((day) {
                            final isAvailable = availableDays.contains(day);
                            final String value = breakTimes[day] ?? '-';
                            return Opacity(
                              opacity: isAvailable ? 1 : 0.4,
                              child: _TimeChip(label: value),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ],
        ),
      ),
      ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusChip(String? status) {
    final label = _getStatusLabel(status);
    final labelColor = _getStatusColor(status);
    final bgColor = _getStatusBgColor(status);
    final icon = (status?.toUpperCase() == 'ACTIVE' || status == 'A')
        ? SvgPicture.asset(MediaRes.checkMarkIcon, height: 18)
        : null;

    return _Chip(label: label, labelColor: labelColor, color: bgColor, icon: icon);
  }
}

class ScheduleEntry {
  ScheduleEntry({
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.isBreakTime,
  });

  final String day; // e.g. 'monday'
  final String startTime; // e.g. '09:00 AM'
  final String endTime; // e.g. '05:00 PM'
  final bool isBreakTime;
}

class _Field extends StatelessWidget {
  const _Field({required this.label, this.value, this.trailing});
  final String label;
  final String? value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xff573353),
          ),
        ),
        const SizedBox(height: 6),
        if (trailing == null)
          Text(
            value ?? '-',
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 15,
              color: Color(0xff573353),
              fontWeight: FontWeight.w400,
            ),
          )
        else
          trailing!,
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.labelColor, required this.color, this.icon});
  final String label;
  final Color labelColor;
  final Color color;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            icon!,
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4FB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF4B5B7A),
        ),
      ),
    );
  }
}


