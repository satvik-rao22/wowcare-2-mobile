import 'package:flutter/material.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/core/theme/app_icon.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_fonts.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/core/theme/app_radius.dart';
import 'package:wowcare/core/theme/app_dimensions.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/presentation/features/students/module_access.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/presentation/features/students/model/student_sibling_info.dart';
import 'package:wowcare/presentation/features/students/student_strings.dart';

import 'package:wowcare/shared/common/widgets/delete_confirmation_bottom_sheet.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/skeu_press.dart';

class StudentCard extends StatefulWidget {
  const StudentCard({
    super.key,
    required this.studentCode,
    required this.name,
    this.profileImage,
    this.profilePhotoAssetCode,
    required this.classroom,
    required this.tags,
    required this.sibling,
    required this.schedule,
    this.scheduleByDay = const <String, String>{},
    required this.birthDate,
    required this.movementDate,
    required this.status,
    required this.isActive,
    this.onPrimaryAction,
    this.onDeleteAction,
    this.onEdit,
    this.isSelected = false,
    this.onSelected,
    this.isNapping = false,
    this.initiallyExpanded = false,
  });

  final String studentCode;
  final String name;
  final String? profileImage;
  final String? profilePhotoAssetCode;
  final String classroom;
  final List<String> tags;
  final StudentSiblingInfo sibling;
  final List<String> schedule;
  final Map<String, String> scheduleByDay;
  final String birthDate;
  final String movementDate;
  final String status;
  final bool isActive;
  final VoidCallback? onPrimaryAction;
  final VoidCallback? onDeleteAction;
  final VoidCallback? onEdit;
  final bool isSelected;
  final ValueChanged<bool?>? onSelected;

  /// From nap-start API (current classroom roster); shown on avatar like classroom list.
  final bool isNapping;

  /// Opens the card pre-expanded — used when a notification deep-link targets
  /// this student so the details are visible without a manual tap.
  final bool initiallyExpanded;

  @override
  State<StudentCard> createState() => _StudentCardState();
}

class _StudentCardState extends State<StudentCard> {
  late bool isExpanded = widget.initiallyExpanded;

  /// Shared across all StudentCard instances — every card in a list shares
  /// the same school, so we only hit `/regular-schedule` once per app load.
  static List<String>? _cachedSchoolDayShortLabels;
  static Future<List<String>>? _inFlightLoad;

  static const Map<String, String> _enumToShort = <String, String>{
    'MONDAY': 'Mon',
    'TUESDAY': 'Tue',
    'WEDNESDAY': 'Wed',
    'THURSDAY': 'Thu',
    'FRIDAY': 'Fri',
    'SATURDAY': 'Sat',
    'SUNDAY': 'Sun',
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

  List<String> _schoolOpenShortDays = const <String>[];

  @override
  void initState() {
    super.initState();
    final cached = _cachedSchoolDayShortLabels;
    if (cached != null) {
      _schoolOpenShortDays = cached;
    } else {
      _loadSchoolOpenDays();
    }
  }

  Future<void> _loadSchoolOpenDays() async {
    try {
      final future = _inFlightLoad ??= _fetchSchoolOpenDays();
      final result = await future;
      if (!mounted) return;
      setState(() => _schoolOpenShortDays = result);
    } catch (_) {
      // Leave fallback in place if the API fails.
    }
  }

  static Future<List<String>> _fetchSchoolOpenDays() async {
    final storage = serviceLocator<StorageService>();
    final schoolCode = (await storage.getString(StorageKeys.schoolCode) ?? '')
        .trim();
    if (schoolCode.isEmpty) return const <String>[];
    final repo = serviceLocator<StaffRepository>();
    final days = await repo.getSchoolRegularSchedules(schoolCode: schoolCode);
    final open = <String>{for (final d in days) d.dayOfWeek.toUpperCase()};
    final ordered = _weekOrder
        .where(open.contains)
        .map((k) => _enumToShort[k]!)
        .toList(growable: false);
    _cachedSchoolDayShortLabels = ordered;
    return ordered;
  }

  String _formatDate(String raw) {
    if (raw.isEmpty) return '-';

    try {
      // Try ISO and similar formats
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) {
        return DateFormat('MMM dd, yyyy').format(parsed);
      }
    } catch (_) {
      // ignore and fall through
    }

    // Fallback: return original string if parsing fails
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final role = context.watch<RoleCubit>();
    // Staff persona (teachers/floaters) can't deactivate/reactivate or edit a
    // student from the card — those actions are admin-only.
    final canStudentWrite =
        ModuleAccess.mayWrite(role, AppAccessModules.student) && !role.isStaff;
    final responsive = ResponsiveHelper(context);
    final isTablet = responsive.isTabletCompact;
    final tags = widget.tags;
    // Upcoming students get the same actions as active ones (Deactivate + Edit),
    // not the inactive set (Reactivate + Delete + Edit).
    final bool showActiveActions =
        widget.isActive || widget.status.trim().toUpperCase() == 'UPCOMING';
    String _toEnumDay(String shortDay) {
      switch (shortDay) {
        case 'Mon':
          return 'MONDAY';
        case 'Tue':
          return 'TUESDAY';
        case 'Wed':
          return 'WEDNESDAY';
        case 'Thu':
          return 'THURSDAY';
        case 'Fri':
          return 'FRIDAY';
        case 'Sat':
          return 'SATURDAY';
        case 'Sun':
          return 'SUNDAY';
        default:
          return shortDay.toUpperCase();
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return IntrinsicHeight(
          child: Container(
            width: constraints.maxWidth,
            height: isExpanded ? null : 64.0,
            decoration: BoxDecoration(
              color: AppColors.whiteColor,
              borderRadius: AppRadius.allMd,
              border: Border.all(
                color: AppColors.cardBorderColor,
                width: AppDimensions.hairline,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: AppColors.transparentColor,
              child: InkWell(
                onTap: () {
                  setState(() {
                    isExpanded = !isExpanded;
                  });
                },
                child: Column(
                  children: [
                    Container(
                      height: 60,
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? AppSpacing.xl : AppSpacing.md,
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (!isExpanded)
                            CustomCheckbox(
                              value: widget.isSelected,
                              onChanged: widget.onSelected ?? (_) {},
                              scale: 1.2,
                              borderColor: null,
                              label: null,
                            ),
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              DocumentImageWidget(
                                fileUuid: widget.studentCode,
                                imageUrl: widget.profileImage,
                                mediaAssetCode: widget.profilePhotoAssetCode,
                                name: widget.name,
                                size: 45,
                                studentCode: widget.studentCode,
                                studentEnrollmentStatus: widget.status,
                                disableProfileLookupFallback: true,
                              ),
                              if (widget.isNapping)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Tooltip(
                                    message: StudentStrings
                                        .studentIsCurrentlyNapping,
                                    child: AppArtwork(
                                      MediaRes.napIcon.isNotEmpty
                                          ? MediaRes.napIcon
                                          : MediaRes.sleepIcon,
                                      height: 18,
                                      width: 18,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(width: isTablet ? AppSpacing.md : 9),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    widget.name,
                                    style: TextStyle(
                                      fontFamily: AppFonts.body,
                                      fontSize: isTablet ? 16 : 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.primaryColor,
                                      height: 19 / 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                AppSpacing.gapHXs,
                                Flexible(
                                  child: Text(
                                    widget.classroom,
                                    style: TextStyle(
                                      fontFamily: AppFonts.body,
                                      fontSize: isTablet ? 16 : 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.primaryColor,
                                      height: 19 / 14,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isExpanded) ...[
                      const Divider(
                        height: 1,
                        thickness: AppDimensions.hairline,
                        indent: AppSpacing.md,
                        endIndent: AppSpacing.md,
                        color: AppColors.attendanceCardDividerColor,
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.md,
                          AppSpacing.md,
                          AppSpacing.md,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  StudentStrings.tags,
                                  style: AppTextStyles.label,
                                ),
                                AppSpacing.gapHXs,
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Wrap(
                                      spacing: AppSpacing.xxs,
                                      runSpacing: AppSpacing.xxs,
                                      children: [
                                        if (tags.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.s10,
                                              vertical: AppSpacing.xxs,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  AppColors.staffBadgeActiveBg,
                                              borderRadius: AppRadius.allSm,
                                            ),
                                            child: Text(
                                              tags[0],
                                              style: const TextStyle(
                                                fontFamily: AppFonts.body,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                                color: AppColors
                                                    .staffBadgeActiveText,
                                              ),
                                            ),
                                          ),
                                        if (tags.length > 1)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: AppSpacing.s10,
                                              vertical: AppSpacing.xxs,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors
                                                  .classroomStaffTabColor,
                                              borderRadius: AppRadius.allSm,
                                            ),
                                            child: Text(
                                              tags[1],
                                              style: const TextStyle(
                                                fontFamily: AppFonts.body,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                                color: AppColors
                                                    .staffBadgeActiveText,
                                              ),
                                            ),
                                          ),
                                        if (tags.length > 2)
                                          Tooltip(
                                            message: tags.skip(2).join(', '),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: AppSpacing.s10,
                                                    vertical: AppSpacing.xxs,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors
                                                    .classroomNotesTabColor,
                                                borderRadius: AppRadius.allSm,
                                              ),
                                              child: Text(
                                                '+${tags.length - 2}',
                                                style: const TextStyle(
                                                  fontFamily: AppFonts.body,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w400,
                                                  color:
                                                      AppColors.secondaryColor,
                                                  height: 15 / 12,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.s10),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    StudentStrings.schedule,
                                    style: AppTextStyles.label,
                                  ),
                                  AppSpacing.gapVXxs,
                                  Wrap(
                                    spacing: AppSpacing.xxs,
                                    runSpacing: AppSpacing.xxs,
                                    alignment: WrapAlignment.start,
                                    children: [
                                      ...(() {
                                        // Days the school is open, sourced
                                        // from the regular-schedule API.
                                        // Render a chip for every open day so
                                        // Sat/Sun show up too — even if the
                                        // student has no schedule for them.
                                        if (_schoolOpenShortDays.isNotEmpty) {
                                          return _schoolOpenShortDays;
                                        }
                                        return const <String>[
                                          'Mon',
                                          'Tue',
                                          'Wed',
                                          'Thu',
                                          'Fri',
                                        ];
                                      })().map((day) {
                                        final enumDay = _toEnumDay(day);
                                        final scheduleText =
                                            widget.scheduleByDay[enumDay];
                                        final hasDayInList = widget.schedule
                                            .any(
                                              (d) =>
                                                  d.trim().toLowerCase() ==
                                                  day.toLowerCase(),
                                            );
                                        final hasDayInMap =
                                            scheduleText != null &&
                                            scheduleText.trim().isNotEmpty;
                                        final isActive =
                                            hasDayInList || hasDayInMap;
                                        final dayChip = Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.s10,
                                            vertical: AppSpacing.xxs,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isActive
                                                ? AppColors.staffBadgeActiveBg
                                                : AppColors
                                                      .staffBadgeInactiveBg,
                                            borderRadius: AppRadius.allSm,
                                          ),
                                          child: Text(
                                            day,
                                            style: TextStyle(
                                              fontFamily: AppFonts.body,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                              color: isActive
                                                  ? AppColors
                                                        .staffBadgeActiveText
                                                  : AppColors
                                                        .staffBadgeInactiveText,
                                            ),
                                          ),
                                        );
                                        if (!isActive) {
                                          return Opacity(
                                            opacity: 0.4,
                                            child: dayChip,
                                          );
                                        }
                                        final tooltipText =
                                            (scheduleText != null &&
                                                scheduleText.trim().isNotEmpty)
                                            ? '$day\n$scheduleText'
                                            : '$day: Scheduled';
                                        return Tooltip(
                                          message: tooltipText,
                                          triggerMode:
                                              TooltipTriggerMode.longPress,
                                          showDuration: const Duration(
                                            seconds: 3,
                                          ),
                                          preferBelow: true,
                                          child: dayChip,
                                        );
                                      }),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.s10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  StudentStrings.birthDate,
                                  style: AppTextStyles.label,
                                ),
                                Text(
                                  _formatDate(widget.birthDate),
                                  style: AppTextStyles.value,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.s10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  StudentStrings.movementDate,
                                  style: AppTextStyles.label,
                                ),
                                Text(
                                  _formatDate(widget.movementDate),
                                  style: AppTextStyles.value,
                                ),
                              ],
                            ),
                            if (canStudentWrite) ...[
                              AppSpacing.gapVLg,
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: AppSpacing.xxxl,
                                      child: OutlinedButton(
                                        onPressed: () {
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor:
                                                AppColors.transparentColor,
                                            builder: (ctx) {
                                              return DeleteConfirmationBottomSheet(
                                                name: widget.name,
                                                type: showActiveActions
                                                    ? 'student_deactivate'
                                                    : 'student_reactivate',
                                                onDelete: () {
                                                  widget.onPrimaryAction
                                                      ?.call();
                                                  return Future.value();
                                                },
                                                onCancel: () {
                                                  Navigator.of(ctx).pop();
                                                },
                                              );
                                            },
                                          );
                                        },
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                            color: AppColors
                                                .attendanceActionAccentColor,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: AppRadius.allSm,
                                          ),
                                          padding: EdgeInsets.zero,
                                        ),
                                        child: Text(
                                          showActiveActions
                                              ? StudentStrings.deactivate
                                              : StudentStrings.reactivate,
                                          style: const TextStyle(
                                            fontFamily: AppFonts.body,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors
                                                .attendanceActionAccentColor,
                                            height: 16 / 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (!showActiveActions) ...[
                                    AppSpacing.gapHMd,
                                    Expanded(
                                      child: SizedBox(
                                        height: AppSpacing.xxxl,
                                        child: OutlinedButton(
                                          onPressed: () {
                                            showModalBottomSheet(
                                              context: context,
                                              isScrollControlled: true,
                                              backgroundColor:
                                                  AppColors.transparentColor,
                                              builder: (ctx) {
                                                return DeleteConfirmationBottomSheet(
                                                  name: widget.name,
                                                  type: 'student_delete',
                                                  onDelete: () {
                                                    widget.onDeleteAction
                                                        ?.call();
                                                    return Future.value();
                                                  },
                                                  onCancel: () {
                                                    Navigator.of(ctx).pop();
                                                  },
                                                );
                                              },
                                            );
                                          },
                                          style: OutlinedButton.styleFrom(
                                            side: const BorderSide(
                                              color: AppColors
                                                  .attendanceActionAccentColor,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: AppRadius.allSm,
                                            ),
                                            padding: EdgeInsets.zero,
                                          ),
                                          child: const Text(
                                            StudentStrings.delete,
                                            style: TextStyle(
                                              fontFamily: AppFonts.body,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors
                                                  .attendanceActionAccentColor,
                                              height: 16 / 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                  AppSpacing.gapHMd,
                                  Expanded(
                                    child: SkeuKeyBox(
                                      variant: KeyVariant.primary,
                                      radius: AppRadius.sm,
                                      height: 40,
                                      child: TextButton(
                                        onPressed: widget.onEdit,
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                        ),
                                        child: const Text(
                                          StudentStrings.edit,
                                          style: TextStyle(
                                            fontFamily: AppFonts.body,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.whiteColor,
                                            height: 16 / 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
