import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import 'package:wowcare/core/util/server_time_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/core/util/staff_code_resolver.dart';
import 'package:wowcare/domain/features/classroom/entities/classroom.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/gradient_time_picker_field.dart';
import 'staff_entity.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_tabbed_view.dart';
import 'package:wowcare/presentation/features/attendance/util/attendance_redirect.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';

class StaffTransferForm extends StatefulWidget {
  const StaffTransferForm({super.key, this.staff, this.staffList});

  final StaffEntity? staff;
  final List<StaffEntity>? staffList;

  static const String routeName = '/staff-transfer-form';

  @override
  State<StaffTransferForm> createState() => _StaffTransferFormState();
}

class _StaffTransferFormState extends State<StaffTransferForm> {
  DateTime _selectedTransferDate = ServerTimeService.instance.now();
  TimeOfDay _selectedTransferTime = ServerTimeService.instance.timeOfDayNow();
  String? _schoolIana;
  String? _selectedToClassroomCode;
  final Map<String, String> _classroomNameToCode = <String, String>{};
  List<StaffEntity> _selectedStaff = [];
  bool _isSubmitting = false;
  bool? _isStaffAdminPersona;
  String? _currentStaffCode; // Current user's staff code

  /// True when this form targets the logged-in user's own attendance record
  /// (My Attendance) rather than another staff member's. Self attendance can
  /// never have its date/time edited, even by an admin persona — only
  /// admin-managed OTHER-staff attendance allows picking a date/time.
  bool get _isSelfTarget {
    final code = _currentStaffCode;
    if (code == null || code.isEmpty) return false;
    return _selectedStaff.length == 1 &&
        (_selectedStaff.first.staffCode ?? '').trim() == code;
  }

  // The staff member's latest/current classroom code. Seeded from the
  // entity (transfer-list API) for an instant first paint, then overridden
  // by the staff's attendance/transfer history (the `isLastSequenceEntry`
  // record — see [_hydrateSelfStaffClassroomDataIfNeeded]), which is the
  // actually-dynamic source of truth. Re-hydrated after every successful
  // transfer so this never goes stale.
  String? _currentClassroomCode;
  bool _hasTransferTargets = true;
  late final ClassroomCubit _classroomCubit;

  @override
  void initState() {
    super.initState();
    if (widget.staffList != null && widget.staffList!.isNotEmpty) {
      _selectedStaff = List<StaffEntity>.from(widget.staffList!);
    } else if (widget.staff != null) {
      _selectedStaff = <StaffEntity>[widget.staff!];
    } else {
      _selectedStaff = <StaffEntity>[
        StaffEntity(id: 1, name: 'Staff Member', primaryRoomId: 1),
      ];
    }
    _classroomCubit = serviceLocator<ClassroomCubit>()
      ..loadActiveClassrooms(
        onlyTypeClassroom: false,
        applyAttendanceStaffScope: true,
      );
    _loadPersonaFlags();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadPersonaFlags() async {
    String? schoolIana;
    try {
      schoolIana = await SchoolTimezoneResolver.resolveForCurrentSchool(
        storage: serviceLocator<StorageService>(),
        apiClient: serviceLocator<ApiClient>(),
      );
    } catch (_) {}

    final isAdmin = await _resolveIsStaffAdminPersona();
    final currentStaffCode =
        (await serviceLocator<StorageService>().getString(
                  StorageKeys.staffCode,
                ) ??
                '')
            .trim();
    if (!mounted) return;
    setState(() {
      _schoolIana = schoolIana;
      _isStaffAdminPersona = isAdmin;
      _currentStaffCode = currentStaffCode.isNotEmpty ? currentStaffCode : null;
      final now = ServerTimeService.instance.now();
      _selectedTransferDate = now;
      _selectedTransferTime = TimeOfDay(hour: now.hour, minute: now.minute);
    });
    await _hydrateSelfStaffClassroomDataIfNeeded(isAdmin: isAdmin);
  }

  /// Resolves the staff member's LATEST current classroom and stores it in
  /// [_currentClassroomCode]. Called on load and again after every
  /// successful transfer so the displayed "Current Classroom" — and the
  /// dropdown's exclusion filter — never goes stale.
  ///
  /// `StaffProfile.primaryClassroomCode` looked like the right source but
  /// is actually a STATIC default assignment that does NOT change when a
  /// staff member is transferred — using it showed the staff's permanent
  /// "home" classroom instead of where they currently are. The real source
  /// of truth is the staff's attendance/transfer history: the daily
  /// attendance API record where `isLastSequenceEntry == true` is the
  /// backend's own marker for "this is the staff's current placement."
  /// Only falls back to the (static) profile field if that history can't
  /// be resolved at all.
  Future<void> _hydrateSelfStaffClassroomDataIfNeeded({
    required bool isAdmin,
  }) async {
    // Run for all roles (including admins) when a single staff member is
    // selected. Admins can be assigned to a classroom too — skipping them
    // caused 'N/A' in the Current Classroom field for every admin-initiated
    // transfer.
    if (_selectedStaff.length != 1) return;
    final selected = _selectedStaff.first;
    final selectedStaffCode = (selected.staffCode ?? '').trim();
    if (selectedStaffCode.isEmpty) return;

    // Seed from the entity immediately so the field isn't blank while the
    // network round-trip below is in flight.
    final existingCode = (selected.classroomCode ?? '').trim();
    if (existingCode.isNotEmpty && (_currentClassroomCode ?? '').isEmpty) {
      if (!mounted) return;
      setState(() => _currentClassroomCode = existingCode);
    }

    String fmt(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    var resolved = '';
    try {
      final now = ServerTimeService.instance.now();
      final attendanceRepo = serviceLocator<AttendanceRepository>();
      final dailyPage = await attendanceRepo.getStaffAttendanceDaily(
        // A wide lookback, not just "today" — the most recent transfer may
        // have happened on an earlier date with no attendance event today.
        fromAttendanceDate: fmt(now.subtract(const Duration(days: 365))),
        toAttendanceDate: fmt(now),
        search: selectedStaffCode,
        page: 0,
        size: 100,
      );

      final staffItems = dailyPage.items
          .where((i) => i.staffCode.trim() == selectedStaffCode)
          .toList();

      if (staffItems.isNotEmpty) {
        final latest = staffItems.firstWhere(
          (i) => i.isLastSequenceEntry == true,
          orElse: () {
            staffItems.sort(
              (a, b) =>
                  (b.sequenceNumber ?? 0).compareTo(a.sequenceNumber ?? 0),
            );
            return staffItems.first;
          },
        );
        final toCode = (latest.toClassroomCode ?? '').trim();
        resolved = (latest.isTransfer == true && toCode.isNotEmpty)
            ? toCode
            : latest.classroomCode.trim();
      }
    } catch (_) {
      // Fall through to the static profile fallback below.
    }

    if (resolved.isEmpty) {
      // Last resort only — this is the staff's static default classroom,
      // not necessarily where they currently are.
      try {
        final repo = serviceLocator<StaffRepository>();
        final profile = await repo.getStaffProfile(
          staffCode: selectedStaffCode,
          forEditStaff: true,
        );
        resolved = profile.primaryClassroomCode.trim();
      } catch (_) {
        // Keep whatever was already seeded from the entity above.
      }
    }

    if (resolved.isEmpty || !mounted) return;
    setState(() {
      _currentClassroomCode = resolved;
      // If the dropdown selection now matches the freshly-resolved current
      // classroom (e.g. the user picked a target before this async
      // resolution caught up), it's no longer a valid transfer target —
      // clear it rather than leaving a stale, now-invalid selection.
      if (_selectedToClassroomCode == resolved) {
        _selectedToClassroomCode = null;
      }
    });
  }

  Future<bool> _resolveIsStaffAdminPersona() async {
    // RoleCubit's active persona is the canonical, persona-switch-aware
    // signal — staffType/roles in storage can lag a beat after a persona
    // switch and misresolve a staff/teacher persona as admin (see
    // AttendancePopup._loadStaffPersonaFlags for the same fix).
    if (mounted) {
      return !context.read<RoleCubit>().isStaff;
    }

    final storage = serviceLocator<StorageService>();
    final staffType = (await storage.getString(StorageKeys.staffType) ?? '')
        .trim()
        .toUpperCase();

    if (staffType == 'SCHOOL_ADMIN' || staffType == 'ORGANIZATION_ADMIN') {
      return true;
    }

    final rolesJson = await storage.getString(StorageKeys.roles);
    if (rolesJson == null || rolesJson.trim().isEmpty) return false;

    try {
      final List<dynamic> roles = jsonDecode(rolesJson) as List<dynamic>;
      return roles.any((r) {
        if (r is! Map<String, dynamic>) return false;
        final roleCode = (r['role'] ?? '').toString().toUpperCase();
        return roleCode == 'SCHOOL_ADMIN' || roleCode == 'ORGANIZATION_ADMIN';
      });
    } catch (_) {
      return false;
    }
  }

  /// Resolves the human-readable name of the staff member's LATEST current
  /// classroom for display.
  ///
  /// Resolution order:
  ///   1. [_currentClassroomCode] — the hydrated/authoritative code (from
  ///      the staff profile, or the entity seed while that's loading). This
  ///      always wins when present, since it reflects the most recent
  ///      transfer.
  ///   2. [staff.classroomCode]/[staff.classroomName] — entity-level
  ///      fallback when nothing has been hydrated yet.
  ///   3. Raw code — shown while the classrooms list is still loading.
  ///   4. 'N/A' — only when nothing is known at all.
  String _resolveCurrentClassroomDisplay(
    StaffEntity? staff,
    List<Classroom> classrooms,
  ) {
    final hydratedCode = (_currentClassroomCode ?? '').trim();
    final entityCode = (staff?.classroomCode ?? '').trim();
    final apiName = (staff?.classroomName ?? '').trim();

    // The hydrated/profile code is authoritative; only fall back to the
    // entity's code while nothing has been hydrated yet.
    final code = hydratedCode.isNotEmpty ? hydratedCode : entityCode;
    if (code.isEmpty) {
      return apiName.isNotEmpty ? apiName : 'N/A';
    }

    // Only trust the entity's display name when it actually matches the
    // classroom we're showing — otherwise it's a stale name for a
    // classroom the staff has since been transferred out of.
    final apiNameLooksLikeCode =
        apiName.isNotEmpty && (apiName == code || apiName.startsWith('CLS_'));
    if (code == entityCode && apiName.isNotEmpty && !apiNameLooksLikeCode) {
      return apiName;
    }

    for (final c in classrooms) {
      if (c.code.trim() == code) {
        final n = c.name.trim();
        return n.isNotEmpty ? n : code;
      }
    }
    // Classrooms list may still be loading — show the raw code as a
    // fallback so the field is never blank/N/A while waiting.
    return code;
  }

  void _handleSubmit() {
    if (!_hasTransferTargets) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: const SnackBar(
          content: Text('No other classroom available for transfer.'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }
    if (_selectedToClassroomCode == null || _selectedToClassroomCode!.isEmpty) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: const SnackBar(
          content: Text('Please select a classroom to transfer to'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    _submitTransfer();
  }

  Future<String> _resolveStaffCode() => resolveStaffCodeForLoggedInUser();

  Future<void> _submitTransfer() async {
    if (_isSubmitting) return;
    if (_selectedStaff.isEmpty ||
        _selectedToClassroomCode == null ||
        _selectedToClassroomCode!.isEmpty) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: const SnackBar(
          content: Text('No staff/classroom selected to transfer'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final staffCode = await _resolveStaffCode();
    if (!mounted) return;
    if (staffCode.isEmpty) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: const SnackBar(
          content: Text('Unable to resolve staffCode. Please re-login.'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
      return;
    }

    final targetStaffCodes = _selectedStaff
        .map((s) => (s.staffCode ?? '').trim())
        .where((c) => c.isNotEmpty)
        .toList();
    if (targetStaffCodes.isEmpty) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: const SnackBar(
          content: Text('Target staff code is missing. Please refresh list.'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
      return;
    }

    final isStaffAdmin =
        _isStaffAdminPersona ?? await _resolveIsStaffAdminPersona();
    if (!isStaffAdmin &&
        (targetStaffCodes.length != 1 || targetStaffCodes.first != staffCode)) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: const SnackBar(
          content: Text('Teachers can only transfer themselves.'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
      return;
    }
    final staffCodes = targetStaffCodes;

    final toClassroomCode = _selectedToClassroomCode!.trim();

    final toClassroomCodeByStaffCode = <String, String>{
      for (final code in staffCodes) code: toClassroomCode,
    };

    final schoolTimeZone = await SchoolTimezoneResolver.resolveForCurrentSchool(
      storage: serviceLocator<StorageService>(),
      apiClient: serviceLocator<ApiClient>(),
    );
    final schoolToday = SchoolZoneDateTime.schoolCalendarTodayOnly(
      schoolTimeZone,
    );

    // An admin acting on their OWN record (My Attendance/My Day, or a bulk
    // form where they only selected themselves) must not be able to pick a
    // date/time either — only admin-managed OTHER-staff transfers allow it.
    final bool isSelfTarget =
        targetStaffCodes.length == 1 && targetStaffCodes.first == staffCode;

    final DateTime transferredAt;
    if (isStaffAdmin && !isSelfTarget) {
      final pickedDay = DateTime(
        _selectedTransferDate.year,
        _selectedTransferDate.month,
        _selectedTransferDate.day,
      );
      final safeDay = pickedDay.isAfter(schoolToday) ? schoolToday : pickedDay;
      transferredAt = SchoolZoneDateTime.resolvePickedInstantUtc(
        schoolTimeZone,
        selectedDate: safeDay,
        selectedTime: _selectedTransferTime,
      );
    } else {
      transferredAt = SchoolZoneDateTime.utcNowInSchool(schoolTimeZone);
    }

    final payload = <String, dynamic>{
      'staffCode': staffCode,
      'staffCodes': staffCodes,
      'toClassroomCode': toClassroomCode,
      'toClassroomCodeByStaffCode': toClassroomCodeByStaffCode,
      'transferReason': 'Transferred via mobile app',
      'timeZone': schoolTimeZone,
      'transferredAt': transferredAt.toUtc().toIso8601String(),
    };

    try {
      final result = await serviceLocator<AttendanceRepository>()
          .submitStaffTransfer(payload: payload);
      final success = result.success;
      final message = result.message;

      if (!mounted) return;

      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: SnackBar(
          content: Text(message),
          backgroundColor: success
              ? AppColors.successColor
              : AppColors.errorColor,
        ),
      );

      if (success) {
        // Read the staff's post-transfer classroom straight from the
        // backend response when it's echoed back (never inferred from a
        // static field). `primaryClassroomCode` is deliberately NOT used
        // here — it's the staff's static default classroom and doesn't
        // change on transfer. Falls back to the submitted target, which we
        // know is correct immediately after a successful transfer.
        final responseClassroomCode = (result.currentClassroomCode ?? '')
            .trim();
        setState(() {
          _currentClassroomCode = responseClassroomCode.isNotEmpty
              ? responseClassroomCode
              : toClassroomCode;
        });
        // Re-hydrate from the attendance/transfer history too, so the form
        // (and any other open instance) is fully in sync rather than
        // relying solely on the single transfer response or on navigating
        // away.
        await _hydrateSelfStaffClassroomDataIfNeeded(isAdmin: isStaffAdmin);
        if (!mounted) return;
        if (!isStaffAdmin) {
          // Teacher/staff persona: no forced navigation — stay on
          // whatever screen this action was started from.
          Navigator.of(context).pop();
        } else {
          redirectToAttendanceDaily(
            context,
            StaffAttendanceTabbedView.routeName,
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      final errorMessage = ApiErrorHandler.extractErrorMessage(e);
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _removeStaff(StaffEntity staff) {
    setState(() {
      _selectedStaff.remove(staff);
      if (_selectedStaff.isEmpty) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ClassroomCubit>.value(
      value: _classroomCubit,
      child: BlocBuilder<ClassroomCubit, ClassroomState>(
        builder: (context, classroomState) {
          if (_classroomNameToCode.isEmpty &&
              classroomState.classrooms.isNotEmpty) {
            for (final c in classroomState.classrooms) {
              _classroomNameToCode[c.name] = c.code;
            }
          }
          final currentClassroom = _resolveCurrentClassroomDisplay(
            _selectedStaff.isNotEmpty ? _selectedStaff.first : null,
            classroomState.classrooms,
          );
          // Code to exclude from the "Transfer to Classroom" dropdown: the
          // staff's LATEST current classroom. Falls back to the first
          // selected staff's own code for a bulk transfer (multiple staff
          // picked at once), where per-staff hydration isn't run.
          final currentClassroomCode =
              (_currentClassroomCode ?? '').trim().isNotEmpty
              ? _currentClassroomCode!.trim()
              : ((_selectedStaff.isNotEmpty
                        ? (_selectedStaff.first.classroomCode ?? '')
                        : '')
                    .trim());
          final transferOptions = classroomState.classrooms
              .where((c) => c.name.trim().isNotEmpty)
              .where((c) => c.code.trim() != currentClassroomCode)
              .map((c) => c.name)
              .toList(growable: false);
          _hasTransferTargets = transferOptions.isNotEmpty;
          String? selectedToClassroomName;
          for (final entry in _classroomNameToCode.entries) {
            if (entry.value == _selectedToClassroomCode) {
              selectedToClassroomName = entry.key;
              break;
            }
          }
          return StaffFormLayout(
            title: 'Transfer',
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_selectedStaff.isNotEmpty)
                    GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 3.5,
                          ),
                      itemCount: _selectedStaff.length,
                      itemBuilder: (context, index) => RemoveStaffTile(
                        staff: _selectedStaff[index],
                        canRemove: _selectedStaff.length > 1,
                        onRemove: () => _removeStaff(_selectedStaff[index]),
                      ),
                    ),
                  const SizedBox(height: 20),
                  // Date + Time (50/50 split) - match StudentTransferForm alignment
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppText.label('Date'),
                            const SizedBox(height: 8),
                            CustomDateTimeField(
                              hasLabel: false,
                              isRangePicker: false,
                              isTime: false,
                              fetchInitialTime: false,
                              initialDate: _selectedTransferDate,
                              isDisabled:
                                  _isStaffAdminPersona != true || _isSelfTarget,
                              onDateSelected: (date) {
                                setState(() {
                                  final iana = _schoolIana;
                                  final today = iana != null && iana.isNotEmpty
                                      ? SchoolZoneDateTime.schoolCalendarTodayOnly(
                                          iana,
                                        )
                                      : DateTime(
                                          ServerTimeService.instance.now().year,
                                          ServerTimeService.instance
                                              .now()
                                              .month,
                                          ServerTimeService.instance.now().day,
                                        );
                                  final picked = DateTime(
                                    date.year,
                                    date.month,
                                    date.day,
                                  );
                                  _selectedTransferDate = picked.isAfter(today)
                                      ? today
                                      : date;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppText.label('Time'),
                            const SizedBox(height: 8),
                            IgnorePointer(
                              ignoring:
                                  _isStaffAdminPersona != true || _isSelfTarget,
                              child: GradientTimePickerField(
                                time: _selectedTransferTime,
                                onTimeSelected: (t) {
                                  setState(() {
                                    _selectedTransferTime = t;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Current classroom + Transfer to classroom (50/50 split) - match StudentTransferForm alignment
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppText.label('Current Classroom'),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                                color: const Color.fromRGBO(177, 175, 233, 0.1),
                              ),
                              child: AppText.value(
                                currentClassroom,
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.primaryColor.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppText.label('Transfer to Classroom'),
                            const SizedBox(height: 8),
                            CustomDropdown(
                              hintText: _hasTransferTargets
                                  ? 'Select classroom'
                                  : 'No classroom available',
                              items: transferOptions,
                              selectedItem: selectedToClassroomName,
                              isEnabled: _hasTransferTargets,
                              onSelect: (value) {
                                setState(() {
                                  _selectedToClassroomCode = value == null
                                      ? null
                                      : _classroomNameToCode[value];
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
            bottomBar: CustomButtonLayout(
              confirmButtonLabel: 'Submit',
              onPressedConfirm: _isSubmitting ? null : _handleSubmit,
              showCancelButton: false,
            ),
          );
        },
      ),
    );
  }
}

class RemoveStaffTile extends StatelessWidget {
  final StaffEntity staff;
  final bool canRemove;
  final VoidCallback onRemove;

  const RemoveStaffTile({
    super.key,
    required this.staff,
    required this.canRemove,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.themeColor),
        borderRadius: BorderRadius.circular(10),
        color: const Color.fromRGBO(249, 245, 250, 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                DocumentImageWidget(
                  fileUuid: staff.photoUuid ?? '',
                  name: staff.name,
                  size: 30,
                  fontSize: 12,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    staff.name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (canRemove)
            GestureDetector(
              onTap: onRemove,
              child: SvgPicture.asset(MediaRes.delete_icon),
            ),
        ],
      ),
    );
  }
}
