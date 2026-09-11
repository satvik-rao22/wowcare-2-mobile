import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_fonts.dart';
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/core/theme/app_radius.dart';
import 'package:wowcare/core/theme/app_dimensions.dart';
import 'package:wowcare/domain/features/student/entities/student_regular_schedule_input.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:wowcare/shared/common/widgets/custom_navigation_bar.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/presentation/features/students/module_access.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/data/features/student/models/student_models.dart';
import 'package:wowcare/presentation/features/students/view_model/student_profile_cubit.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/shared/common/widgets/custom_refresh_indicator.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/shared/constants/location_constants.dart';
import 'package:wowcare/presentation/features/students/model/student_sibling_info.dart';
import 'package:wowcare/presentation/features/students/student_strings.dart';

import 'package:wowcare/shared/common/widgets/profile_info_card.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/presentation/features/students/view/edit_student_profile_details_screen.dart';
import 'package:wowcare/presentation/features/students/view/add_student_step3_screen.dart';
import 'package:wowcare/presentation/features/students/view/student_tags_edit_sheet.dart';

class StudentAboutTabCard extends StatefulWidget {
  const StudentAboutTabCard({
    required this.scrollController,
    required this.name,
    required this.classroom,
    required this.tags,
    required this.schedule,
    required this.sibling,
    this.onRefresh,
    this.studentProfile,
    this.studentCode,
    super.key,
  });

  final ScrollController scrollController;
  final String name;
  final String classroom;
  final List<String> tags;
  final List<String> schedule;
  final StudentSiblingInfo sibling;
  final Future<void> Function()? onRefresh;
  final StudentProfileModel? studentProfile;
  final String? studentCode;

  @override
  State<StudentAboutTabCard> createState() => _StudentAboutTabCardState();
}

class _StudentAboutTabCardState extends State<StudentAboutTabCard> {
  /// Full day labels for days the school is open, sourced from the
  /// regular-schedule API. Empty until the API loads — UI falls back to
  /// Mon-Fri in the meantime.
  List<String> _schoolOpenDayLabels = const <String>[];

  /// Routes the regular-schedule write through the MVVM cubit → use case →
  /// repository. Closed in [dispose].
  final StudentProfileCubit _profileCubit =
      serviceLocator<StudentProfileCubit>();

  static const Map<String, String> _enumToLabel = <String, String>{
    'MONDAY': 'Monday',
    'TUESDAY': 'Tuesday',
    'WEDNESDAY': 'Wednesday',
    'THURSDAY': 'Thursday',
    'FRIDAY': 'Friday',
    'SATURDAY': 'Saturday',
    'SUNDAY': 'Sunday',
  };

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
    _loadSchoolOpenDays();
  }

  @override
  void dispose() {
    _profileCubit.close();
    super.dispose();
  }

  Future<void> _loadSchoolOpenDays() async {
    try {
      final profileSchoolCode = widget.studentProfile?.schoolCode.trim();
      String schoolCode = profileSchoolCode ?? '';
      if (schoolCode.isEmpty) {
        final storage = serviceLocator<StorageService>();
        schoolCode = (await storage.getString(StorageKeys.schoolCode) ?? '')
            .trim();
      }
      if (schoolCode.isEmpty) return;
      final repo = serviceLocator<StaffRepository>();
      final days = await repo.getSchoolRegularSchedules(schoolCode: schoolCode);
      final open = <String>{for (final d in days) d.dayOfWeek.toUpperCase()};
      final ordered = _weekOrder
          .where(open.contains)
          .map((k) => _enumToLabel[k]!)
          .toList(growable: false);
      if (!mounted) return;
      setState(() => _schoolOpenDayLabels = ordered);
    } catch (_) {
      // Leave _schoolOpenDayLabels empty — fallback path covers display.
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  /// Birth date with the calculated age appended, e.g.
  /// "Jun 04, 2024 (2 yrs)" or "Jun 04, 2026 (1 wk)" for infants.
  String _formatDobWithAge(String? dob) {
    final formatted = _formatDate(dob);
    if (dob == null || dob.trim().isEmpty) return formatted;
    try {
      final age = _ageLabel(DateTime.parse(dob));
      return age.isEmpty ? formatted : '$formatted  ($age)';
    } catch (_) {
      return formatted;
    }
  }

  /// Human age relative to today — years/months for older children, weeks/days
  /// for infants. Empty for a future date of birth.
  String _ageLabel(DateTime dob) {
    final now = AppTime.now();
    if (dob.isAfter(now)) return '';

    int years = now.year - dob.year;
    int months = now.month - dob.month;
    if (now.day < dob.day) months -= 1;
    if (months < 0) {
      years -= 1;
      months += 12;
    }

    String plural(int n, String unit) => '$n $unit${n == 1 ? '' : 's'}';

    if (years >= 1) {
      return months > 0
          ? '${plural(years, 'yr')} ${plural(months, 'mo')}'
          : plural(years, 'yr');
    }
    if (months >= 1) return plural(months, 'mo');

    final days = now.difference(dob).inDays;
    if (days >= 7) return plural(days ~/ 7, 'wk');
    return plural(days, 'day');
  }

  String _getValueOrDash(String? value) {
    if (value == null || value.isEmpty) return '-';
    return value;
  }

  /// FTE for display: the API value (0–1 fraction) multiplied by 100 (front end
  /// only) and shown as a percentage, with a trailing `.0` dropped.
  /// Null/blank/non-numeric → '-'.
  String _fteDisplay() {
    final raw = (widget.studentProfile?.fte ?? '').trim();
    if (raw.isEmpty) return '-';
    final value = double.tryParse(raw);
    if (value == null) return '-';
    final scaled = value * 100;
    final number = scaled == scaled.roundToDouble()
        ? scaled.toStringAsFixed(0)
        : scaled.toString();
    return '$number%';
  }

  String? _prettyGender(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    switch (raw.trim().toUpperCase()) {
      case 'MALE':
        return 'Male';
      case 'FEMALE':
        return 'Female';
      case 'OTHER':
      case 'NON_BINARY':
      case 'NONBINARY':
      case 'PREFER_NOT_TO_SAY':
        return 'Other';
      default:
        return raw;
    }
  }

  String _formatAddress(Map<String, dynamic> address) {
    final parts = <String>[];
    if (address['street'] != null && address['street'].toString().isNotEmpty) {
      parts.add(address['street'].toString());
    }
    if (address['city'] != null && address['city'].toString().isNotEmpty) {
      parts.add(address['city'].toString());
    }
    if (address['state'] != null && address['state'].toString().isNotEmpty) {
      final rawState = address['state'].toString().trim();
      String stateLabel = rawState;
      for (final state in US_STATES) {
        if (state.name.toLowerCase() == rawState.toLowerCase() ||
            state.abbreviation.toLowerCase() == rawState.toLowerCase()) {
          stateLabel = state.name;
          break;
        }
      }
      parts.add(stateLabel);
    }
    if (address['country'] != null &&
        address['country'].toString().isNotEmpty) {
      final rawCountry = address['country'].toString().trim();
      String countryLabel = rawCountry;
      for (final country in COUNTRY_LIST) {
        if (country.name.toLowerCase() == rawCountry.toLowerCase() ||
            country.code.toLowerCase() == rawCountry.toLowerCase()) {
          countryLabel = country.name;
          break;
        }
      }
      parts.add(countryLabel);
    }
    // API sometimes returns postalCode; older UI used zipCode.
    final zipRaw =
        (address['zipCode'] ?? address['postalCode'])?.toString() ?? '';
    final zipDigits = zipRaw.replaceAll(RegExp(r'\D'), '');
    if (zipDigits.isNotEmpty) {
      // Format ZIP+4: 9 digits -> #####-####
      if (zipDigits.length == 9) {
        parts.add('${zipDigits.substring(0, 5)}-${zipDigits.substring(5)}');
      } else {
        parts.add(zipRaw);
      }
    }
    return parts.isEmpty ? '-' : parts.join(', ');
  }

  bool _hasTags() {
    return widget.tags.isNotEmpty;
  }

  List<String> _getTagsList() {
    return widget.tags;
  }

  Widget _buildUpcomingMove() {
    final upcomingMoveDate =
        widget.studentProfile?.importantDates?.upcomingMoveDate;

    // Show only the date (e.g. "8 June, 2026"), not classroom names.
    String value = '-';
    if (upcomingMoveDate != null && upcomingMoveDate.trim().isNotEmpty) {
      try {
        value = DateFormat(
          'd MMMM, yyyy',
        ).format(DateTime.parse(upcomingMoveDate));
      } catch (_) {
        value = '-';
      }
    }

    return ProfileField(label: StudentStrings.upcomingMove, value: value);
  }

  /// Staff-only tags editor (bottom sheet). Staff can't open the full profile
  /// editor, but may manage tags from here.
  void _openTagsEditSheet() {
    final code = (widget.studentCode ?? widget.studentProfile?.code ?? '')
        .trim();
    if (code.isEmpty) return;
    showStudentTagsEditSheet(
      context: context,
      studentCode: code,
      schoolCode: widget.studentProfile?.schoolCode,
      initialTagNames: widget.tags,
      onSaved: () async {
        await widget.onRefresh?.call();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<RoleCubit>();
    final canStudentWrite =
        ModuleAccess.mayWrite(role, AppAccessModules.student) && !role.isParent;
    final canTagsWrite =
        ModuleAccess.mayWrite(role, AppAccessModules.studentTags) &&
        !role.isParent;
    // Staff persona (teachers/floaters) may edit only tags here — not the full
    // profile or schedule. Admins keep full profile edit.
    final isStaffPersona = role.isStaff;
    final canEditProfile = canStudentWrite && !isStaffPersona;
    // The edit pencil opens the full profile editor for admins (STUDENT write)
    // or the tags-only sheet for staff (STUDENT_TAGS write).
    final canEdit =
        widget.studentProfile != null &&
        (canEditProfile || (isStaffPersona && canTagsWrite));

    return CustomRefreshIndicator(
      onRefresh: () async {
        await widget.onRefresh?.call();
      },
      child: ProfileInfoCard(
        title: StudentStrings.profileInformation,
        // Full width, flush below the tab bar; bottom pads only by the nav's
        // visible height (above the safe area) so the box's bottom border sits
        // right on the bottom nav with no extra gap.
        outerPadding: EdgeInsets.only(
          bottom:
              (CustomNavigationBar.navBarHeight -
                      MediaQuery.of(context).viewPadding.bottom)
                  .clamp(0.0, double.infinity),
        ),
        // Square top so the card reads as one continuous surface with the tabs
        // (rounded top would bump/overlap the tab borders).
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.lg),
        ),
        scrollController: widget.scrollController,
        onEdit: canEdit
            ? (isStaffPersona
                  ? _openTagsEditSheet
                  : () async {
                      final profile = widget.studentProfile!;

                      // Map status from API format (ACTIVE) to display format (Active)
                      String statusDisplay = 'Active';
                      final upperStatus = profile.status.toUpperCase();
                      if (upperStatus == 'ACTIVE' || profile.status == 'A') {
                        statusDisplay = 'Active';
                      } else if (upperStatus == 'INACTIVE' ||
                          profile.status == 'I') {
                        statusDisplay = 'Inactive';
                      } else if (profile.status == 'Upcoming') {
                        statusDisplay = 'Upcoming';
                      } else if (upperStatus == 'WAITLIST') {
                        statusDisplay = 'Waitlist';
                      } else if (upperStatus == 'GRADUATED') {
                        statusDisplay = 'Graduated';
                      }

                      // Parse birth date
                      DateTime? birthDate;
                      if (profile.dob != null && profile.dob!.isNotEmpty) {
                        try {
                          birthDate = DateTime.parse(profile.dob!);
                        } catch (e) {
                          birthDate = null;
                        }
                      }

                      // Extract address fields
                      final address = profile.address;
                      final street = address?['street']?.toString() ?? '';
                      final city = address?['city']?.toString() ?? '';
                      final state = address?['state']?.toString() ?? '';
                      final country = address?['country']?.toString() ?? '';
                      final zipCode =
                          address?['zipCode']?.toString() ??
                          address?['postalCode']?.toString() ??
                          '';

                      // Extract tags (API-backed, passed from parent as display names)
                      final tags = widget.tags.isNotEmpty
                          ? List<String>.from(widget.tags)
                          : const <String>[];

                      // Extract siblings as codes for edit screen (API returns list of objects).
                      final siblings = <String>[];
                      if (profile.siblings.isNotEmpty) {
                        for (final s in profile.siblings) {
                          if (s is Map<String, dynamic>) {
                            final code = (s['code'] ?? '').toString().trim();
                            if (code.isNotEmpty) {
                              siblings.add(code);
                            }
                          }
                        }
                      }

                      // Extract legal custodians using same display logic as guardian names API.
                      final legalCustodians = <String>[];
                      if (profile.legalCustodians.isNotEmpty) {
                        for (final custodian in profile.legalCustodians) {
                          if (custodian is String) {
                            if (custodian.trim().isNotEmpty) {
                              legalCustodians.add(custodian.trim());
                            }
                          } else if (custodian is Map<String, dynamic>) {
                            final first = (custodian['firstName'] ?? '')
                                .toString()
                                .trim();
                            final last = (custodian['lastName'] ?? '')
                                .toString()
                                .trim();
                            final email = (custodian['email'] ?? '')
                                .toString()
                                .trim();
                            final code = (custodian['code'] ?? '')
                                .toString()
                                .trim();

                            String display;
                            if (first.isEmpty && last.isEmpty) {
                              display = email.isNotEmpty ? email : code;
                            } else {
                              display = '$first $last'.trim();
                            }

                            if (display.isNotEmpty) {
                              legalCustodians.add(display);
                            }
                          }
                        }
                      }

                      final edited = await context.push(
                        EditStudentProfileDetailsScreen.routeName,
                        extra: <String, dynamic>{
                          'studentCode': profile.code,
                          'initialFirstName': profile.firstName,
                          'initialLastName': profile.lastName,
                          'initialStatus': statusDisplay,
                          'initialGender': profile.gender,
                          'initialClassroom': profile.classroom ?? '',
                          'initialBirthDate': birthDate,
                          'initialNotes': profile.notes ?? '',
                          'initialStreet': street,
                          'initialCity': city,
                          'initialState': state,
                          'initialCountry': country,
                          'initialZipCode': zipCode,
                          'initialTags': tags,
                          'initialSiblings': siblings,
                          'initialLegalCustodians': legalCustodians,
                          'initialSubsidy': profile.subsidy,
                        },
                      );
                      // If profile was updated, refresh from API.
                      if (edited == true) {
                        await widget.onRefresh?.call();
                      }
                    })
            : null,
        children: [
          ProfileField(
            label: StudentStrings.name,
            value: _getValueOrDash(widget.name),
          ),

          ProfileField(
            label: StudentStrings.status,
            valueWidget: _buildStatusChip(widget.studentProfile?.status ?? 'A'),
          ),

          ProfileField(
            label: StudentStrings.classroom,
            value: _getValueOrDash(
              widget.studentProfile?.classroom ?? widget.classroom,
            ),
          ),

          ProfileField(
            label: StudentStrings.tags,
            valueWidget: _hasTags()
                ? _tags(tags: _getTagsList())
                : const Text(
                    '-',
                    style: TextStyle(
                      fontFamily: Fonts.manrope,
                      fontSize: 15,
                      color: AppColors.primaryColor,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
          ),

          ProfileField(
            label: StudentStrings.gender,
            value: _getValueOrDash(
              _prettyGender(widget.studentProfile?.gender),
            ),
          ),

          ProfileField(
            label: StudentStrings.birthDate,
            value: _formatDobWithAge(widget.studentProfile?.dob),
          ),

          ProfileField(
            label: StudentStrings.notes,
            value: _getValueOrDash(widget.studentProfile?.notes),
          ),

          ProfileField(
            label: StudentStrings.childCustody,
            value: (() {
              final custodians = widget.studentProfile?.legalCustodians ?? [];
              final names = <String>[];
              for (final c in custodians) {
                if (c is String) {
                  if (c.trim().isNotEmpty) names.add(c.trim());
                } else if (c is Map<String, dynamic>) {
                  final first = (c['firstName'] ?? '').toString().trim();
                  final last = (c['lastName'] ?? '').toString().trim();
                  final name = ('$first $last').trim();
                  if (name.isNotEmpty) {
                    names.add(name);
                  } else {
                    final email = (c['email'] ?? '').toString().trim();
                    if (email.isNotEmpty) names.add(email);
                  }
                }
              }
              if (names.isEmpty) return StudentStrings.childCustodyNotSelected;
              return names.join(', ');
            })(),
          ),

          ProfileField(
            label: StudentStrings.stateSubsidy,
            value: widget.studentProfile != null
                ? (widget.studentProfile!.subsidy
                      ? StudentStrings.yes
                      : StudentStrings.no)
                : '-',
          ),

          ProfileField(
            label: StudentStrings.fullTimeEquivalentFte,
            value: _fteDisplay(),
          ),

          Builder(
            builder: (context) {
              final names = widget.sibling.names;

              if (names.isEmpty) {
                return ProfileField(
                  label: StudentStrings.sibling,
                  value: StudentStrings.noSiblings,
                );
              }

              final label = names.length == 1 ? 'Sibling' : 'Siblings';
              return ProfileField(
                label: label,
                valueWidget: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(names.length, (index) {
                    final name = names[index];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: Row(
                        children: [
                          DocumentImageWidget(
                            fileUuid: '',
                            name: name,
                            size: 45,
                          ),
                          AppSpacing.gapHSm,
                          Text(
                            name,
                            style: const TextStyle(
                              fontFamily: Fonts.manrope,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryColor,
                              letterSpacing: -0.03 * 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              );
            },
          ),

          ProfileField(
            label: StudentStrings.address,
            value: widget.studentProfile?.address != null
                ? _formatAddress(widget.studentProfile!.address!)
                : '-',
          ),

          if (canEditProfile)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () async {
                final profile = widget.studentProfile;
                if (profile == null) return;

                // Build initial schedule map from existing regularSchedules if available.
                Map<String, Map<String, TimeOfDay>>? initialSchedule;
                try {
                  final Map<String, Map<String, TimeOfDay>> temp = {};

                  String _dayOfWeekToFullName(String day) {
                    switch (day.toUpperCase()) {
                      case 'MONDAY':
                        return 'Monday';
                      case 'TUESDAY':
                        return 'Tuesday';
                      case 'WEDNESDAY':
                        return 'Wednesday';
                      case 'THURSDAY':
                        return 'Thursday';
                      case 'FRIDAY':
                        return 'Friday';
                      case 'SATURDAY':
                        return 'Saturday';
                      case 'SUNDAY':
                        return 'Sunday';
                      default:
                        return day;
                    }
                  }

                  TimeOfDay? _parseLocalTime(dynamic value) {
                    if (value == null) return null;
                    if (value is String) {
                      final parts = value.split(':');
                      if (parts.length >= 2) {
                        final hour = int.tryParse(parts[0]) ?? 0;
                        final minute = int.tryParse(parts[1]) ?? 0;
                        return TimeOfDay(hour: hour, minute: minute);
                      }
                      return null;
                    }
                    if (value is Map) {
                      final hour = int.tryParse(
                        value['hour']?.toString() ?? '',
                      );
                      final minute = int.tryParse(
                        value['minute']?.toString() ?? '',
                      );
                      if (hour != null && minute != null) {
                        return TimeOfDay(hour: hour, minute: minute);
                      }
                    }
                    return null;
                  }

                  for (final raw in profile.regularSchedules) {
                    if (raw is! Map<String, dynamic>) continue;
                    final dayOfWeekRaw = (raw['dayOfWeek'] ?? '').toString();
                    if (dayOfWeekRaw.isEmpty) continue;

                    final fullDay = _dayOfWeekToFullName(dayOfWeekRaw);
                    final start = _parseLocalTime(raw['startTime']);
                    final end = _parseLocalTime(raw['endTime']);

                    if (start == null || end == null) continue;

                    temp[fullDay] = {'start': start, 'end': end};
                  }

                  if (temp.isNotEmpty) {
                    initialSchedule = temp;
                  }
                } catch (_) {
                  initialSchedule = null;
                }

                final result = await context
                    .push<Map<String, Map<String, TimeOfDay>>>(
                      AddStudentStep3Screen.routeName,
                      extra: <String, dynamic>{
                        'title': 'Edit Schedule',
                        'primaryButtonLabel': 'Save',
                        'showSkip': false,
                        'initialSchedule': initialSchedule,
                      },
                    );

                if (result == null || result.isEmpty) return;

                try {
                  final List<StudentRegularScheduleInput> payloadSchedule = [];

                  String _formatLocalTime(TimeOfDay time) {
                    final h = time.hour.toString().padLeft(2, '0');
                    final m = time.minute.toString().padLeft(2, '0');
                    return '$h:$m:00';
                  }

                  for (final entry in result.entries) {
                    final dayName = entry.key.toString();
                    final timesMap = Map<String, TimeOfDay>.from(entry.value);
                    final start = timesMap['start'];
                    final end = timesMap['end'];

                    if (start == null || end == null) {
                      continue;
                    }

                    final startMinutes = start.hour * 60 + start.minute;
                    final endMinutes = end.hour * 60 + end.minute;
                    final midMinutes = ((startMinutes + endMinutes) / 2)
                        .floor();
                    final halfDay = TimeOfDay(
                      hour: (midMinutes ~/ 60) % 24,
                      minute: midMinutes % 60,
                    );

                    payloadSchedule.add(
                      StudentRegularScheduleInput(
                        dayOfWeek: dayName.toUpperCase(), // e.g. MONDAY
                        startTime: _formatLocalTime(start),
                        halfDay: _formatLocalTime(halfDay),
                        endTime: _formatLocalTime(end),
                      ),
                    );
                  }

                  if (payloadSchedule.isEmpty) return;

                  await _profileCubit.updateRegularSchedules(
                    schoolCode: profile.schoolCode,
                    studentCode: profile.code,
                    schedule: payloadSchedule,
                  );

                  await widget.onRefresh?.call();

                  CoreUtils.showTopSnackBar(
                    context: context,
                    message: StudentStrings.scheduleUpdatedSuccessfully,
                    isSuccess: true,
                  );
                } catch (e) {
                  final message = ApiErrorHandler.extractErrorMessage(e);
                  CoreUtils.showTopSnackBar(
                    context: context,
                    message: message,
                    isError: true,
                  );
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        StudentStrings.schedule,
                        style: TextStyle(
                          fontFamily: Fonts.manrope,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const Icon(
                        Icons.edit,
                        size: AppDimensions.iconXs,
                        color: AppColors.billingTextMuted,
                      ),
                    ],
                  ),
                  AppSpacing.gapVXs,
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children:
                              (_schoolOpenDayLabels.isNotEmpty
                                      ? _schoolOpenDayLabels
                                      : const <String>[
                                          'Monday',
                                          'Tuesday',
                                          'Wednesday',
                                          'Thursday',
                                          'Friday',
                                        ])
                                  .map((fullDay) {
                                    // Build a lookup of time ranges from regularSchedules.
                                    String? _findTimeRangeForDay(
                                      String dayLabel,
                                    ) {
                                      final profile = widget.studentProfile;
                                      final schedules =
                                          profile?.regularSchedules ?? [];
                                      if (schedules.isEmpty) return null;

                                      String _fullToEnum(String full) {
                                        switch (full) {
                                          case 'Monday':
                                            return 'MONDAY';
                                          case 'Tuesday':
                                            return 'TUESDAY';
                                          case 'Wednesday':
                                            return 'WEDNESDAY';
                                          case 'Thursday':
                                            return 'THURSDAY';
                                          case 'Friday':
                                            return 'FRIDAY';
                                          case 'Saturday':
                                            return 'SATURDAY';
                                          case 'Sunday':
                                            return 'SUNDAY';
                                          default:
                                            return full.toUpperCase();
                                        }
                                      }

                                      TimeOfDay? _parseLocalTime(
                                        dynamic value,
                                      ) {
                                        if (value == null) return null;
                                        if (value is String) {
                                          final parts = value.split(':');
                                          if (parts.length >= 2) {
                                            final hour =
                                                int.tryParse(parts[0]) ?? 0;
                                            final minute =
                                                int.tryParse(parts[1]) ?? 0;
                                            return TimeOfDay(
                                              hour: hour,
                                              minute: minute,
                                            );
                                          }
                                          return null;
                                        }
                                        if (value is Map) {
                                          final hour = int.tryParse(
                                            value['hour']?.toString() ?? '',
                                          );
                                          final minute = int.tryParse(
                                            value['minute']?.toString() ?? '',
                                          );
                                          if (hour != null && minute != null) {
                                            return TimeOfDay(
                                              hour: hour,
                                              minute: minute,
                                            );
                                          }
                                        }
                                        return null;
                                      }

                                      String _formatTimeOfDay(TimeOfDay time) {
                                        final now = AppTime.now();
                                        final dt = DateTime(
                                          now.year,
                                          now.month,
                                          now.day,
                                          time.hour,
                                          time.minute,
                                        );
                                        return DateFormat('h:mm a').format(dt);
                                      }

                                      final targetEnum = _fullToEnum(dayLabel);
                                      for (final raw in schedules) {
                                        if (raw is! Map<String, dynamic>)
                                          continue;
                                        final dow = (raw['dayOfWeek'] ?? '')
                                            .toString()
                                            .toUpperCase();
                                        if (dow != targetEnum) continue;

                                        final start = _parseLocalTime(
                                          raw['startTime'],
                                        );
                                        final end = _parseLocalTime(
                                          raw['endTime'],
                                        );
                                        if (start == null || end == null)
                                          continue;

                                        return '${_formatTimeOfDay(start)}–${_formatTimeOfDay(end)}';
                                      }
                                      return null;
                                    }

                                    final timeText = _findTimeRangeForDay(
                                      fullDay,
                                    );
                                    final isAvailable = timeText != null;

                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _ScheduleChip(
                                          width: 110,
                                          label: fullDay,
                                          labelColor: isAvailable
                                              ? AppColors.secondaryColor
                                              : AppColors
                                                    .attendanceSearchHintColor,
                                          color: isAvailable
                                              ? AppColors.staffBadgeActiveBg
                                              : AppColors.staffBadgeInactiveBg,
                                        ),
                                        if (isAvailable) ...[
                                          const SizedBox(height: AppSpacing.s6),
                                          _ScheduleChip(
                                            width: 110,
                                            label: timeText,
                                            labelColor:
                                                AppColors.secondaryColor,
                                            color: AppColors.transparentColor,
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

          _buildUpcomingMove(),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final upperStatus = status.toUpperCase();
    final isActive = upperStatus == 'ACTIVE' || upperStatus == 'A';
    final isInactive = upperStatus == 'INACTIVE' || upperStatus == 'I';
    final isUpcoming = upperStatus == 'UPCOMING';
    final isWaitlist = upperStatus == 'WAITLIST';
    final isGraduated = upperStatus == 'GRADUATED';

    final String label;
    final Color labelColor;
    final Color bgColor;
    if (isActive) {
      label = 'Active';
      labelColor = AppColors.studentStatusActiveColor;
      bgColor = AppColors.studentStatusActiveBg;
    } else if (isUpcoming) {
      label = 'Upcoming';
      labelColor = AppColors.studentStatusUpcomingColor;
      bgColor = AppColors.studentStatusUpcomingBg;
    } else if (isWaitlist) {
      label = 'Waitlist';
      labelColor = AppColors.secondaryColor;
      bgColor = AppColors.staffBadgeActiveBg;
    } else if (isGraduated) {
      label = 'Graduated';
      labelColor = AppColors.secondaryColor;
      bgColor = AppColors.staffBadgeActiveBg;
    } else if (isInactive) {
      label = 'Inactive';
      labelColor = AppColors.studentStatusInactiveColor;
      bgColor = AppColors.studentStatusInactiveBg;
    } else {
      label = status.isEmpty ? '-' : status;
      labelColor = AppColors.studentStatusInactiveColor;
      bgColor = AppColors.studentStatusInactiveBg;
    }

    final icon = isActive
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

class _tags extends StatelessWidget {
  const _tags({required this.tags});
  final List<String> tags;

  static const List<Color> _chipColors = [
    AppColors.staffBadgeActiveBg,
    AppColors.classroomStaffTabColor,
    AppColors.classroomNotesTabColor,
  ];

  @override
  Widget build(BuildContext context) {
    final tagList = tags;
    return Wrap(
      spacing: AppSpacing.s6,
      runSpacing: AppSpacing.s6,
      children: List.generate(tagList.length, (index) {
        return _ProfileTagChip(
          label: tagList[index],
          color: _chipColors[index % _chipColors.length],
        );
      }),
    );
  }
}

class _ProfileTagChip extends StatelessWidget {
  const _ProfileTagChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s10,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(color: color, borderRadius: AppRadius.allSm),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: Fonts.manrope,
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: AppColors.secondaryColor,
        ),
      ),
    );
  }
}

class _ScheduleChip extends StatelessWidget {
  const _ScheduleChip({
    required this.label,
    required this.labelColor,
    required this.color,
    required this.width,
    this.isTimeChip = false, // now required
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s10,
        vertical: AppSpacing.s6,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.allSm,
        border: isTimeChip
            ? Border.all(
                color: AppColors.staffBadgeActiveBg,
                width: AppDimensions.borderThin,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: isTimeChip ? 2 : 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: Fonts.manrope,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isTimeChip ? AppColors.staffBadgeActiveText : labelColor,
        ),
      ),
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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s10,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(color: color, borderRadius: AppRadius.allSm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: AppSpacing.s6)],
          Text(
            label,
            style: TextStyle(
              fontFamily: Fonts.manrope,
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
