import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/staff/view/edit_profile_details_screen.dart';
import 'package:wowcare/presentation/features/staff/view/edit_schedule_screen.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/shared/common/widgets/custom_shimmer_loader.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_profile_cubit.dart';
import 'package:wowcare/domain/features/staff/entities/staff_profile.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/string_utils.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/classroom/usecases/get_classroom_by_code_usecase.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';

class StaffProfileTab extends StatefulWidget {
  const StaffProfileTab({
    super.key,
    required this.staffCode,
    this.classroomNames,
    this.classroomNameByCode,
    this.onProfileSummaryChanged,
  });

  final String staffCode;

  /// Optional cached classroom display names (from StaffScreen).
  final List<String>? classroomNames;

  /// Optional mapping from classroom code -> display name (from StaffScreen).
  final Map<String, String>? classroomNameByCode;

  /// Optional callback so parent (StaffProfileScreen) can update
  /// the header card when core profile info changes.
  final void Function(String name, String classroom, String designation)?
  onProfileSummaryChanged;

  @override
  State<StaffProfileTab> createState() => _StaffProfileTabState();
}

class _StaffProfileTabState extends State<StaffProfileTab> {
  late final StaffProfileCubit _profileCubit;
  final Map<String, String> _resolvedClassroomNameByCode = {};
  final Set<String> _classroomFetchInFlight = <String>{};

  /// Days the school is open, sourced from the regular-schedule API. We
  /// always render every open day so Sat/Sun appear even when the staff
  /// has no work/break entries for those days.
  List<String> _schoolOpenDays = const <String>[];

  static const List<String> _weekOrder = [
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY',
  ];

  @override
  void initState() {
    super.initState();
    _profileCubit = serviceLocator<StaffProfileCubit>()
      ..loadInitial(widget.staffCode);
    _loadSchoolOpenDays();
  }

  @override
  void dispose() {
    _profileCubit.close();
    super.dispose();
  }

  Future<void> _loadSchoolOpenDays() async {
    try {
      final storage = serviceLocator<StorageService>();
      final schoolCode = (await storage.getString(StorageKeys.schoolCode) ?? '')
          .trim();
      if (schoolCode.isEmpty) return;
      final repo = serviceLocator<StaffRepository>();
      final days = await repo.getSchoolRegularSchedules(schoolCode: schoolCode);
      final open = <String>{for (final d in days) d.dayOfWeek.toUpperCase()};
      final ordered = _weekOrder.where(open.contains).toList(growable: false);
      if (!mounted) return;
      setState(() => _schoolOpenDays = ordered);
    } catch (_) {
      // Leave _schoolOpenDays empty — UI falls back to Mon-Fri.
    }
  }

  static const List<String> _fallbackDays = [
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

  /// US ZIP+4: inserts hyphen after 5 digits when 9+ digits (e.g. 030601234 → 03060-1234).
  String _formatZipCodeDisplay(String? zip) {
    if (zip == null || zip.trim().isEmpty) return '';
    final digits = zip.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 9) {
      return '${digits.substring(0, 5)}-${digits.substring(5, 9)}';
    }
    if (digits.length == 5) {
      return digits;
    }
    return zip.trim();
  }

  /// Address line for display with formatted ZIP (hyphen for ZIP+4).
  String _formatAddressForDisplay(StaffProfileAddress address) {
    final zip = _formatZipCodeDisplay(address.zipCode);
    final parts = <String>[];
    if (address.street.isNotEmpty) parts.add(address.street);
    if (address.line2.isNotEmpty) parts.add(address.line2);
    if (address.city.isNotEmpty) parts.add(address.city);
    if (address.state.isNotEmpty) parts.add(address.state);
    if (zip.isNotEmpty) parts.add(zip);
    if (address.country.isNotEmpty) parts.add(address.country);
    return parts.isEmpty ? '' : parts.join(', ');
  }

  String _formatPhoneNumber(String? number) {
    if (number == null || number.isEmpty) return '-';
    final digits = number.replaceAll(RegExp(r'\D'), '');
    // Prefer US-style formatting when we can derive a 10-digit local number.
    // Supports:
    // - "9876543212"
    // - "+1 9876543212"
    // - "1-987-654-3212"
    String local10 = digits;
    if (digits.length == 11 && digits.startsWith('1')) {
      local10 = digits.substring(1);
    } else if (digits.length > 11) {
      // If backend sends E.164 with country code, keep last 10 digits as a best-effort.
      local10 = digits.substring(digits.length - 10);
    }

    if (local10.length != 10) return number;
    return '(${local10.substring(0, 3)}) ${local10.substring(3, 6)}-${local10.substring(6, 10)}';
  }

  String _displayClassroomName(String code) {
    final trimmed = code.trim();
    if (trimmed.isEmpty) return '-';

    final cachedFromParent = widget.classroomNameByCode?[trimmed]?.trim();
    if (cachedFromParent != null && cachedFromParent.isNotEmpty) {
      return cachedFromParent;
    }

    final local = _resolvedClassroomNameByCode[trimmed]?.trim();
    if (local != null && local.isNotEmpty) {
      return local;
    }

    if (!_classroomFetchInFlight.contains(trimmed)) {
      _classroomFetchInFlight.add(trimmed);
      // ignore: discarded_futures
      _fetchClassroomNameByCode(trimmed);
    }

    return trimmed;
  }

  Future<void> _fetchClassroomNameByCode(String code) async {
    try {
      final details = await serviceLocator<GetClassroomByCodeUseCase>()(
        code: code,
      );
      if (!mounted) return;
      final name = details.name.trim();
      if (name.isNotEmpty) {
        setState(() {
          _resolvedClassroomNameByCode[code] = name;
        });
      }
    } catch (_) {
      // Keep showing code when lookup fails.
    } finally {
      _classroomFetchInFlight.remove(code);
    }
  }

  String _getStatusLabel(String? status) {
    if (status == null || status.isEmpty) return '-';
    final normalized = status.trim().toUpperCase();
    if (normalized == 'ACTIVE' || normalized == 'A') return 'Active';
    if (normalized == 'INACTIVE' || normalized == 'I') return 'Inactive';
    if (normalized == 'UPCOMING' || normalized == 'U') return 'Upcoming';
    if (normalized == 'ARCHIVE' || normalized == 'ARCHIVED') return 'Archived';
    if (normalized == 'WAITLIST') return 'Waitlist';
    return _formatEnumLabel(normalized);
  }

  Color _getStatusColor(String? status) {
    if (status == null || status.isEmpty) return Colors.grey;
    final upperStatus = status.trim().toUpperCase();
    if (upperStatus == 'ACTIVE' || upperStatus == 'A') {
      return const Color.fromRGBO(56, 200, 32, 1);
    }
    if (upperStatus == 'INACTIVE' || upperStatus == 'I') {
      return const Color.fromRGBO(250, 65, 65, 1);
    }
    if (upperStatus == 'UPCOMING' || upperStatus == 'U') {
      return const Color.fromRGBO(221, 164, 55, 1);
    }
    if (upperStatus == 'ARCHIVE' || upperStatus == 'ARCHIVED') {
      return const Color.fromRGBO(117, 117, 117, 1);
    }
    return const Color.fromARGB(255, 238, 223, 8);
  }

  Color _getStatusBgColor(String? status) {
    if (status == null || status.isEmpty) return Colors.grey.withOpacity(0.1);
    final upperStatus = status.trim().toUpperCase();
    if (upperStatus == 'ACTIVE' || upperStatus == 'A') {
      return const Color.fromRGBO(56, 200, 32, 0.1);
    }
    if (upperStatus == 'INACTIVE' || upperStatus == 'I') {
      return const Color.fromRGBO(250, 65, 65, 0.1);
    }
    if (upperStatus == 'UPCOMING' || upperStatus == 'U') {
      return const Color.fromRGBO(221, 164, 55, 0.16);
    }
    if (upperStatus == 'ARCHIVE' || upperStatus == 'ARCHIVED') {
      return const Color.fromRGBO(117, 117, 117, 0.14);
    }
    return const Color.fromARGB(255, 242, 238, 176);
  }

  /// Formats enum-style strings from the API into human readable labels.
  /// Examples:
  /// - "ASSOCIATE_TEACHER" -> "Associate Teacher"
  /// - "FULL_TIME" -> "Full-Time"
  /// - "PART_TIME" -> "Part-Time"
  String _formatEnumLabel(String? value) {
    if (value == null || value.trim().isEmpty) return '-';
    final upper = value.trim().toUpperCase();

    // Special cases for job type
    if (upper == 'FULL_TIME') return 'Full-Time';
    if (upper == 'PART_TIME') return 'Part-Time';

    // Generic: split on underscores/spaces and title‑case each part.
    final parts = upper.split(RegExp(r'[_\s]+'));
    final words = parts
        .map((part) {
          if (part.isEmpty) return '';
          final lower = part.toLowerCase();
          return lower[0].toUpperCase() + lower.substring(1);
        })
        .where((w) => w.isNotEmpty);
    return words.join(' ');
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
              return const SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                physics: AlwaysScrollableScrollPhysics(),
                child: StaffProfileInfoShimmer(),
              );
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

            final addressDisplay = _formatAddressForDisplay(profile.address);

            // Notify parent about updated summary info (name, classroom, role)
            // so the header card stays in sync with this tab.
            if (widget.onProfileSummaryChanged != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                final displayName = profile.fullName.isEmpty
                    ? '-'
                    : profile.fullName;
                final primaryClassroomName =
                    profile.primaryClassroomCode.isEmpty
                    ? '-'
                    : _displayClassroomName(profile.primaryClassroomCode);
                final designation = _formatEnumLabel(profile.designation);
                widget.onProfileSummaryChanged!(
                  displayName,
                  primaryClassroomName,
                  designation,
                );
              });
            }

            // Build work and break times maps
            final workTimes = <String, String>{};
            final breakTimes = <String, String>{};
            final availableDays = <String>{};

            for (final schedule in profile.workSchedules) {
              final day = schedule.dayOfWeek.toUpperCase();
              availableDays.add(day);
              workTimes[day] = schedule.formattedTime;
            }

            for (final schedule in profile.breakSchedules) {
              final day = schedule.dayOfWeek.toUpperCase();
              // Treat break schedules as "available" too so day chip doesn't look disabled.
              availableDays.add(day);
              breakTimes[day] = schedule.formattedTime;
            }

            return CustomRefreshIndicator(
              onRefresh: () async {
                await _profileCubit.refresh(widget.staffCode);
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 16,
                ),
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
                              final allowedClassroomNames = profile
                                  .allowedClassroomCodes
                                  .map(_displayClassroomName)
                                  .toList();
                              final primaryClassroomName =
                                  profile.primaryClassroomCode.isEmpty
                                  ? null
                                  : _displayClassroomName(
                                      profile.primaryClassroomCode,
                                    );

                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EditProfileDetailsScreen(
                                        staffCode: profile.staffCode,
                                        initialFirstName: profile.firstName,
                                        initialLastName: profile.lastName,
                                        initialStatus: _getStatusLabel(
                                          profile.status,
                                        ),
                                        initialDesignation: profile.designation,
                                        initialAllowedClassrooms:
                                            allowedClassroomNames,
                                        initialPrimaryClassroom:
                                            primaryClassroomName,
                                        initialBirthDate:
                                            profile.birthDate.isEmpty
                                            ? null
                                            : DateTime.tryParse(
                                                profile.birthDate,
                                              ),
                                        initialJobTag: profile.jobTag,
                                        initialEmail: profile.email,
                                        initialPhoneNumber: profile.phoneNumber,
                                        initialStreet: profile.address.street,
                                        initialCity: profile.address.city,
                                        initialState: profile.address.state,
                                        initialCountry: profile.address.country,
                                        initialZipCode: profile.address.zipCode,
                                        initialClassroomNames:
                                            widget.classroomNames,
                                        initialClassroomCodeByName:
                                            widget.classroomNameByCode == null
                                            ? null
                                            : {
                                                for (final entry
                                                    in widget
                                                        .classroomNameByCode!
                                                        .entries)
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
                      _Field(
                        label: 'Name',
                        value: profile.fullName.isEmpty
                            ? '-'
                            : profile.fullName,
                      ),
                      const SizedBox(height: 16),
                      _Field(
                        label: 'Status',
                        value: null,
                        trailing: _buildStatusChip(profile.status),
                      ),
                      const SizedBox(height: 12),
                      _Field(
                        label: 'Designation',
                        value: _formatEnumLabel(profile.designation),
                      ),
                      const SizedBox(height: 16),
                      _Field(
                        label: 'Role',
                        value: profile.staffType.trim().isEmpty
                            ? '-'
                            : StringUtils.staffTypeToDisplayRole(
                                profile.staffType,
                              ),
                      ),
                      const SizedBox(height: 16),
                      _Field(
                        label: 'Email',
                        value: profile.email.isEmpty ? '-' : profile.email,
                      ),
                      const SizedBox(height: 16),
                      _Field(
                        label: 'Clock In-Out PIN',
                        value: profile.clockPin.isEmpty
                            ? '-'
                            : profile.clockPin,
                      ),
                      const SizedBox(height: 16),
                      _Field(
                        label: 'Phone Number',
                        value: _formatPhoneNumber(profile.phoneNumber),
                      ),
                      const SizedBox(height: 16),
                      _Field(
                        label: 'Address',
                        value: addressDisplay.isEmpty ? '-' : addressDisplay,
                      ),
                      const SizedBox(height: 16),
                      _Field(
                        label: 'Birth Date',
                        value: _formatDate(profile.birthDate),
                      ),
                      const SizedBox(height: 16),
                      _Field(
                        label: 'Job Tag',
                        value: _formatEnumLabel(profile.jobTag),
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
                                    final code =
                                        profile.allowedClassroomCodes[index];
                                    final name = _displayClassroomName(code);
                                    return _Chip(
                                      label: name,
                                      labelColor: const Color.fromRGBO(
                                        27,
                                        35,
                                        126,
                                        1,
                                      ),
                                      color:
                                          chipColors[index % chipColors.length],
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
                                label: _displayClassroomName(
                                  profile.primaryClassroomCode,
                                ),
                                labelColor: const Color.fromRGBO(
                                  27,
                                  35,
                                  126,
                                  1,
                                ),
                                color: chipColors.first,
                              ),
                      ),
                      // Schedule section – layout aligned with student profile schedule card
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          final schedules = <ScheduleEntry>[];
                          for (final workSchedule in profile.workSchedules) {
                            schedules.add(
                              ScheduleEntry(
                                day: workSchedule.dayOfWeek.toLowerCase(),
                                startTime:
                                    workSchedule.workStartTime.formattedTime,
                                endTime: workSchedule.workEndTime.formattedTime,
                                isBreakTime: false,
                              ),
                            );
                          }
                          for (final breakSchedule in profile.breakSchedules) {
                            schedules.add(
                              ScheduleEntry(
                                day: breakSchedule.dayOfWeek.toLowerCase(),
                                startTime:
                                    breakSchedule.breakStartTime.formattedTime,
                                endTime:
                                    breakSchedule.breakEndTime.formattedTime,
                                isBreakTime: true,
                              ),
                            );
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Schedule',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xff573353),
                                  ),
                                ),
                                const Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: Color(0x99573353),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children:
                                        (_schoolOpenDays.isNotEmpty
                                                ? _schoolOpenDays
                                                : _fallbackDays)
                                            .map((day) {
                                              // Map internal enum-style day to display name (Monday, etc.)
                                              String displayDay;
                                              switch (day) {
                                                case 'MONDAY':
                                                  displayDay = 'Monday';
                                                  break;
                                                case 'TUESDAY':
                                                  displayDay = 'Tuesday';
                                                  break;
                                                case 'WEDNESDAY':
                                                  displayDay = 'Wednesday';
                                                  break;
                                                case 'THURSDAY':
                                                  displayDay = 'Thursday';
                                                  break;
                                                case 'FRIDAY':
                                                  displayDay = 'Friday';
                                                  break;
                                                case 'SATURDAY':
                                                  displayDay = 'Saturday';
                                                  break;
                                                case 'SUNDAY':
                                                  displayDay = 'Sunday';
                                                  break;
                                                default:
                                                  displayDay = day
                                                      .toLowerCase();
                                                  displayDay =
                                                      displayDay[0]
                                                          .toUpperCase() +
                                                      displayDay.substring(1);
                                                  break;
                                              }

                                              final isAvailable = availableDays
                                                  .contains(day);
                                              final String? workLabel =
                                                  isAvailable
                                                  ? workTimes[day]
                                                  : null;
                                              final String? breakLabel =
                                                  isAvailable
                                                  ? breakTimes[day]
                                                  : null;

                                              return Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  _ScheduleChip(
                                                    width: 130,
                                                    label: displayDay,
                                                    labelColor: isAvailable
                                                        ? const Color.fromRGBO(
                                                            27,
                                                            35,
                                                            126,
                                                            1,
                                                          )
                                                        : Colors.grey.shade700,
                                                    color: isAvailable
                                                        ? const Color(
                                                            0x4DB1AFE9,
                                                          )
                                                        : const Color(
                                                            0xFFF3F4FB,
                                                          ),
                                                  ),
                                                  if (workLabel != null &&
                                                      workLabel
                                                          .trim()
                                                          .isNotEmpty) ...[
                                                    const SizedBox(height: 6),
                                                    _ScheduleChip(
                                                      width: 130,
                                                      label: workLabel,
                                                      labelColor:
                                                          const Color.fromRGBO(
                                                            27,
                                                            35,
                                                            126,
                                                            1,
                                                          ),
                                                      color: Colors.transparent,
                                                      isTimeChip: true,
                                                    ),
                                                  ],
                                                  if (breakLabel != null &&
                                                      breakLabel
                                                          .trim()
                                                          .isNotEmpty) ...[
                                                    const SizedBox(height: 6),
                                                    _ScheduleChip(
                                                      width: 130,
                                                      label: '$breakLabel',
                                                      labelColor:
                                                          const Color.fromRGBO(
                                                            27,
                                                            35,
                                                            126,
                                                            1,
                                                          ),
                                                      color: Colors.transparent,
                                                      isTimeChip: true,
                                                    ),
                                                  ],
                                                ],
                                              );
                                            })
                                            .toList(),
                                  ),
                                ),
                              ],
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
    final normalized = (status ?? '').trim().toUpperCase();
    final label = _getStatusLabel(status);
    final labelColor = _getStatusColor(status);
    final bgColor = _getStatusBgColor(status);
    final icon = (normalized == 'ACTIVE' || normalized == 'A')
        ? SvgPicture.asset(MediaRes.checkMarkIcon, height: 18)
        : null;

    return _Chip(
      label: label,
      labelColor: labelColor,
      color: bgColor,
      icon: icon,
    );
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

class _ScheduleChip extends StatelessWidget {
  const _ScheduleChip({
    required this.label,
    required this.labelColor,
    required this.color,
    required this.width,
    this.isTimeChip = false,
  });

  final String label;
  final Color labelColor;
  final Color color;
  final double width;
  final bool isTimeChip;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: isTimeChip
            ? Border.all(color: const Color(0x4DB1AFE9), width: 1.5)
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: isTimeChip ? 2 : 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4B5B7A),
        ),
      ),
    );
  }
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
  const _Chip({
    required this.label,
    required this.labelColor,
    required this.color,
    this.icon,
  });
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
          if (icon != null) ...[icon!, const SizedBox(width: 6)],
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
