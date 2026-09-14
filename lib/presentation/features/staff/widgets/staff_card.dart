import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/presentation/features/staff/view_model/staff_schedule_cubit.dart';
import 'package:wowcare/presentation/features/staff/view_model/staff_cubit.dart';
import 'package:wowcare/presentation/features/students/module_access.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/delete_confirmation_bottom_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'package:wowcare/core/router/app_routes.dart' show StaffRoutes;
import 'package:wowcare/presentation/features/staff/model/staff_route_args.dart';

class StaffCard extends StatefulWidget {
  const StaffCard({
    super.key,
    required this.staffCode,
    required this.name,
    required this.classroom,
    this.avatarUrl,
    this.profilePhotoAssetCode,
    required this.allowedClassrooms,
    required this.schedule,
    required this.designation,
    this.email = '',
    required this.phoneNumber,
    required this.isActive,
    this.status,
    this.onPrimaryAction,
    this.onDeleteAction,
    this.onEdit,
    this.isSelected = false,
    this.onSelected,
    required this.availableClassrooms,
    required this.classroomCodeByName,
    this.workScheduleByDay = const <String, String>{},
    this.breakScheduleByDay = const <String, String>{},
    this.initiallyExpanded = false,
  });

  final String staffCode;
  final String name;
  final String classroom;
  final String? avatarUrl;
  final String? profilePhotoAssetCode;
  final List<String> allowedClassrooms;
  final List<String> schedule;
  final String designation;
  final String email;
  final String phoneNumber;
  final bool isActive;
  final String? status;
  final VoidCallback? onPrimaryAction;

  /// Permanently deletes the staff member. Only surfaced for deactivated staff.
  final VoidCallback? onDeleteAction;
  final VoidCallback? onEdit;
  final bool isSelected;
  final ValueChanged<bool?>? onSelected;
  final List<String> availableClassrooms;
  final Map<String, String> classroomCodeByName;

  /// Day-of-week (MONDAY, TUESDAY, ...) → "start - end" work time.
  final Map<String, String> workScheduleByDay;

  /// Day-of-week (MONDAY, TUESDAY, ...) → "start - end" break time.
  final Map<String, String> breakScheduleByDay;

  /// Opens the card pre-expanded — used when a notification deep-link targets
  /// this staff member.
  final bool initiallyExpanded;

  @override
  State<StaffCard> createState() => _StaffCardState();
}

class _StaffCardState extends State<StaffCard> {
  /// UI-only expand/collapse toggle. A [ValueNotifier] instead of `setState`
  /// so toggling only rebuilds the subtree that reads it, not the whole
  /// State object (Mandate 2 — see docs/eight-mandates §2.3).
  late final ValueNotifier<bool> _isExpanded = ValueNotifier<bool>(
    widget.initiallyExpanded,
  );

  @override
  void dispose() {
    _isExpanded.dispose();
    super.dispose();
  }

  /// Shared across all StaffCard instances — every card in a list is for the
  /// same school, so we only call `/regular-schedule` once per app load.
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

  static const Map<String, String> _shortToEnum = <String, String>{
    'Mon': 'MONDAY',
    'Tue': 'TUESDAY',
    'Wed': 'WEDNESDAY',
    'Thu': 'THURSDAY',
    'Fri': 'FRIDAY',
    'Sat': 'SATURDAY',
    'Sun': 'SUNDAY',
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
      // Static single-flight + cache: every visible card wants the same list,
      // so the first one issues the request and the rest await its future.
      final future = _inFlightLoad ??= _fetchSchoolOpenDays(
        context.read<StaffScheduleCubit>(),
      );
      final result = await future;
      if (!mounted) return;
      setState(() => _schoolOpenShortDays = result);
    } catch (_) {
      // Leave fallback in place if the API fails.
    }
  }

  static Future<List<String>> _fetchSchoolOpenDays(
    StaffScheduleCubit scheduleCubit,
  ) async {
    final days = await scheduleCubit.fetchActiveSchoolRegularSchedules();
    if (days == null) return const <String>[];
    final open = <String>{for (final d in days) d.dayOfWeek.toUpperCase()};
    final ordered = _weekOrder
        .where(open.contains)
        .map((k) => _enumToShort[k]!)
        .toList(growable: false);
    _cachedSchoolDayShortLabels = ordered;
    return ordered;
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
    final isTablet = ResponsiveHelper(context).isTabletCompact;
    final primaryClassroomName = widget.classroom.trim();
    final orderedAllowedClassrooms = <String>[
      if (primaryClassroomName.isNotEmpty) primaryClassroomName,
      ...widget.allowedClassrooms
          .map((name) => name.trim())
          .where(
            (name) =>
                name.isNotEmpty &&
                name.toLowerCase() != primaryClassroomName.toLowerCase(),
          ),
    ];

    return ValueListenableBuilder<bool>(
      valueListenable: _isExpanded,
      builder: (context, isExpanded, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return IntrinsicHeight(
              child: Container(
                width: constraints.maxWidth,
                height: isExpanded ? null : 64.0,
                decoration: BoxDecoration(
                  color: AppColors.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.cardBorderColor,
                    width: 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Material(
                  color: AppColors.transparentColor,
                  child: InkWell(
                    onTap: () {
                      _isExpanded.value = !_isExpanded.value;
                    },
                    child: Column(
                      children: [
                        Container(
                          height: 60,
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 24 : 16,
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
                              DocumentImageWidget(
                                fileUuid: widget.staffCode,
                                imageUrl: widget.avatarUrl,
                                mediaAssetCode: widget.profilePhotoAssetCode,
                                name: widget.name,
                                staffCode: widget.staffCode,
                                staffEmploymentStatus: widget.status,
                                disableProfileLookupFallback: true,
                                size: 50,
                              ),
                              SizedBox(width: isTablet ? 16 : 9),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        widget.name,
                                        style: AppTextStyles.value.copyWith(
                                          fontSize: isTablet ? 16 : 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        widget.classroom,
                                        style: AppTextStyles.value.copyWith(
                                          fontSize: isTablet ? 16 : 14,
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
                            thickness: 1,
                            indent: 16,
                            endIndent: 16,
                            color: AppColors.attendanceCardDividerColor,
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Allowed\nClassroom',
                                      style: AppTextStyles.label,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: Wrap(
                                          spacing: 4,
                                          runSpacing: 4,
                                          children: [
                                            if (orderedAllowedClassrooms
                                                .isNotEmpty)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppColors
                                                      .staffBadgeActiveBg,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  orderedAllowedClassrooms[0],
                                                  style: AppTextStyles
                                                      .sectionHeader
                                                      .copyWith(
                                                        color: AppColors
                                                            .staffBadgeActiveText,
                                                      ),
                                                ),
                                              ),
                                            if (orderedAllowedClassrooms
                                                    .length >
                                                1)
                                              Tooltip(
                                                message:
                                                    orderedAllowedClassrooms
                                                        .skip(1)
                                                        .join(', '),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0x66D9FFCB,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    '+${orderedAllowedClassrooms.length - 1}',
                                                    style: const TextStyle(
                                                      fontFamily: 'Inter',
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                      color: AppColors
                                                          .tagTextColor,
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
                                const SizedBox(height: 10),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Schedule',
                                        style: AppTextStyles.label,
                                      ),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 4,
                                        runSpacing: 4,
                                        alignment: WrapAlignment.start,
                                        children: [
                                          ...(() {
                                            // Days the school is open, sourced from
                                            // the regular-schedule API. Render a
                                            // chip for every open day so Sat/Sun
                                            // appear too — even if the staff has
                                            // no work/break entries for that day.
                                            if (_schoolOpenShortDays
                                                .isNotEmpty) {
                                              return _schoolOpenShortDays;
                                            }
                                            return const <String>[
                                              'Mon',
                                              'Tue',
                                              'Wed',
                                              'Thu',
                                              'Fri',
                                            ];
                                          })().map((shortDay) {
                                            final enumDay =
                                                _shortToEnum[shortDay] ??
                                                'FRIDAY';

                                            final work = widget
                                                .workScheduleByDay[enumDay];
                                            final brk = widget
                                                .breakScheduleByDay[enumDay];
                                            final hasWork =
                                                work != null &&
                                                work.trim().isNotEmpty;
                                            final hasBreak =
                                                brk != null &&
                                                brk.trim().isNotEmpty;
                                            final isActive =
                                                hasWork || hasBreak;

                                            final chip = Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: isActive
                                                    ? AppColors
                                                          .staffBadgeActiveBg
                                                    : AppColors
                                                          .staffBadgeInactiveBg,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                shortDay,
                                                style: AppTextStyles
                                                    .sectionHeader
                                                    .copyWith(
                                                      color: isActive
                                                          ? AppColors
                                                                .staffBadgeActiveText
                                                          : AppColors
                                                                .staffBadgeInactiveText,
                                                    ),
                                              ),
                                            );

                                            if (!isActive) {
                                              // Greyed-out, non-interactive for days without schedule.
                                              return Opacity(
                                                opacity: 0.4,
                                                child: chip,
                                              );
                                            }

                                            final tooltipLines = <String>[];
                                            if (hasWork) {
                                              tooltipLines.add('Work: $work');
                                            }
                                            if (hasBreak) {
                                              tooltipLines.add('Break: $brk');
                                            }
                                            final tooltipText =
                                                tooltipLines.isEmpty
                                                ? '$shortDay: Scheduled'
                                                : '$shortDay\n${tooltipLines.join('\n')}';

                                            return Tooltip(
                                              message: tooltipText,
                                              triggerMode:
                                                  TooltipTriggerMode.longPress,
                                              showDuration: const Duration(
                                                seconds: 3,
                                              ),
                                              preferBelow: true,
                                              child: chip,
                                            );
                                          }),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Designation',
                                      style: AppTextStyles.label,
                                    ),
                                    Flexible(
                                      child: Text(
                                        _formatEnumLabel(widget.designation),
                                        style: AppTextStyles.value,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Email',
                                      style: AppTextStyles.label,
                                    ),
                                    Flexible(
                                      child: Text(
                                        widget.email.isNotEmpty
                                            ? widget.email
                                            : '-',
                                        style: AppTextStyles.value,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Phone Number',
                                      style: AppTextStyles.label,
                                    ),
                                    Flexible(
                                      child: SelectableText(
                                        _formatUsPhone(widget.phoneNumber),
                                        contextMenuBuilder:
                                            (
                                              BuildContext context,
                                              dynamic editableState,
                                            ) {
                                              final List<ContextMenuButtonItem>
                                              items =
                                                  List<
                                                    ContextMenuButtonItem
                                                  >.from(
                                                    editableState
                                                        .contextMenuButtonItems,
                                                  );
                                              items.add(
                                                ContextMenuButtonItem(
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                    _callPhone(
                                                      widget.phoneNumber,
                                                    );
                                                  },
                                                  label: 'Call',
                                                ),
                                              );
                                              return AdaptiveTextSelectionToolbar.buttonItems(
                                                anchors: editableState
                                                    .contextMenuAnchors,
                                                buttonItems: items,
                                              );
                                            },
                                        style: AppTextStyles.value,
                                        textAlign: TextAlign.right,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Edit / Deactivate / Delete are all STAFF writes —
                                // hide the whole action row for view-only personas.
                                if (context.read<RoleCubit>().canWriteModule(
                                  AppAccessModules.staff,
                                ))
                                  Row(
                                    children: [
                                      Expanded(
                                        child: SizedBox(
                                          height: 40,
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
                                                    type: widget.isActive
                                                        ? 'staff_deactivate'
                                                        : 'staff_reactivate',
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
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              padding: EdgeInsets.zero,
                                            ),
                                            child: Text(
                                              widget.isActive
                                                  ? 'Deactivate'
                                                  : 'Reactivate',
                                              style: AppTextStyles.button(
                                                color: AppColors
                                                    .attendanceActionAccentColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Deactivated staff can be permanently deleted.
                                      if (!widget.isActive) ...[
                                        Expanded(
                                          child: SizedBox(
                                            height: 40,
                                            child: OutlinedButton(
                                              onPressed: () {
                                                showModalBottomSheet(
                                                  context: context,
                                                  isScrollControlled: true,
                                                  backgroundColor: AppColors
                                                      .transparentColor,
                                                  builder: (ctx) {
                                                    return DeleteConfirmationBottomSheet(
                                                      name: widget.name,
                                                      type: 'staff_delete',
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
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                padding: EdgeInsets.zero,
                                              ),
                                              child: Text(
                                                'Delete',
                                                style: AppTextStyles.button(
                                                  color: AppColors
                                                      .attendanceActionAccentColor,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                      ],
                                      Expanded(
                                        child: Container(
                                          height: 40,
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            gradient:
                                                AppColors.buildPrimaryGradient(),
                                          ),
                                          child: TextButton(
                                            onPressed: () {
                                              // Invoke external handler if provided
                                              widget.onEdit?.call();

                                              // Derive first/last name from full name
                                              final parts = widget.name
                                                  .trim()
                                                  .split(' ');
                                              final initialFirstName =
                                                  parts.isNotEmpty
                                                  ? parts.first
                                                  : '';
                                              final initialLastName =
                                                  parts.length > 1
                                                  ? parts.sublist(1).join(' ')
                                                  : '';

                                              // Map status from API format to UI format
                                              String? mappedStatus;
                                              if (widget.status != null) {
                                                final statusUpper = widget
                                                    .status!
                                                    .toUpperCase();
                                                if (statusUpper == 'ACTIVE') {
                                                  mappedStatus = 'Active';
                                                } else if (statusUpper ==
                                                    'INACTIVE') {
                                                  mappedStatus = 'Inactive';
                                                } else if (statusUpper ==
                                                    'UPCOMING') {
                                                  mappedStatus = 'Upcoming';
                                                } else {
                                                  mappedStatus = widget.status;
                                                }
                                              }

                                              context
                                                  .push<bool>(
                                                    StaffRoutes
                                                        .editProfileDetails,
                                                    extra: EditStaffProfileArgs(
                                                      staffCode:
                                                          widget.staffCode,
                                                      initialFirstName:
                                                          initialFirstName,
                                                      initialLastName:
                                                          initialLastName,
                                                      initialStatus:
                                                          mappedStatus,
                                                      initialDesignation:
                                                          widget.designation,
                                                      initialAllowedClassrooms:
                                                          widget
                                                              .allowedClassrooms,
                                                      initialPrimaryClassroom:
                                                          widget.classroom,
                                                      initialEmail:
                                                          widget.email,
                                                      initialPhoneNumber:
                                                          widget.phoneNumber,
                                                      initialClassroomNames: widget
                                                          .availableClassrooms,
                                                      initialClassroomCodeByName: {
                                                        for (final entry
                                                            in widget
                                                                .classroomCodeByName
                                                                .entries)
                                                          entry.value:
                                                              entry.key,
                                                      },
                                                    ),
                                                  )
                                                  .then((_) {
                                                    if (context.mounted) {
                                                      context
                                                          .read<StaffCubit>()
                                                          .refresh();
                                                    }
                                                  });
                                            },
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                            ),
                                            child: Text(
                                              'Edit',
                                              style: AppTextStyles.button(
                                                color: AppColors.cardColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
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
      },
    );
  }

  String _formatUsPhone(String input) {
    // Keep digits only
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 10) return input;
    final area = digits.substring(0, 3);
    final mid = digits.substring(3, 6);
    final last = digits.substring(6, 10);
    return '($area) $mid-$last';
  }

  Future<void> _callPhone(String phone) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri(scheme: 'tel', path: digits);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
