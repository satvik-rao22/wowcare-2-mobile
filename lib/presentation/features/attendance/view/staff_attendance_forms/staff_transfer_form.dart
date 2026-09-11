import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/presentation/features/attendance/widgets/attendance_remove_tile.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/domain/features/attendance/entities/staff_transfer_request.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_forms/view_model/staff_transfer_submit_cubit.dart';
import 'package:wowcare/core/utils/api_error_handler.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/school_zone_datetime.dart';
import 'package:wowcare/core/utils/server_time_service.dart';
import 'package:wowcare/core/utils/staff_code_resolver.dart';
import 'package:wowcare/presentation/features/attendance/view_model/attendance_persona_resolver.dart';
import 'package:wowcare/presentation/features/classroom/view_model/classroom_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/gradient_time_picker_field.dart';
import '../../model/staff_entity.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_tabbed_view.dart';
import 'package:wowcare/presentation/features/attendance/view_model/attendance_redirect.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';

class StaffTransferForm extends StatefulWidget {
  const StaffTransferForm({
    super.key,
    this.staff,
    this.staffList,
    this.popOnSuccess = false,
  });

  final StaffEntity? staff;
  final List<StaffEntity>? staffList;

  /// When true, pops back to the caller after a successful submission instead
  /// of redirecting to the Attendance daily tab. Set by callers that live
  /// outside the Attendance tab (e.g. the Staff attendance profile) so the
  /// user stays on the screen they started from.
  final bool popOnSuccess;

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

  /// Owns the transfer submit call (View -> Cubit -> UseCase -> Repository).
  /// Eagerly resolved so [dispose] can always close it.
  final StaffTransferSubmitCubit _submitCubit =
      serviceLocator<StaffTransferSubmitCubit>();
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
  // by today's transfer-form-list lookup (see
  // [_hydrateSelfStaffClassroomDataIfNeeded]), which is the actually-dynamic
  // source of truth. Re-hydrated after every successful transfer so this
  // never goes stale.
  String? _currentClassroomCode;

  // Gates the "Transfer to Classroom" dropdown: it stays disabled (showing a
  // loading hint) until the staff's current classroom has actually been
  // resolved (see [_hydrateSelfStaffClassroomDataIfNeeded]). Showing the
  // dropdown before that finishes let the staff's real current classroom
  // appear as a selectable option for a moment — most visible on entry
  // points (e.g. the My Day card's "Transfer" button) that don't seed
  // [StaffEntity.classroomCode] up front, so this stayed false noticeably
  // longer than on entry points that do.
  bool _currentClassroomResolved = false;
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
    // Bulk transfers (multiple staff picked at once) don't run per-staff
    // hydration below — [build] falls back to the first selected staff's own
    // (already-known) classroomCode synchronously — so there's nothing to
    // wait on.
    _currentClassroomResolved = _selectedStaff.length != 1;
    _classroomCubit = serviceLocator<ClassroomCubit>()
      ..loadActiveClassrooms(
        onlyTypeClassroom: false,
        applyAttendanceStaffScope: true,
      );
    _loadPersonaFlags();
  }

  @override
  void dispose() {
    _submitCubit.close();
    _classroomCubit.close();
    super.dispose();
  }

  Future<void> _loadPersonaFlags() async {
    String? schoolIana;
    try {
      schoolIana = await _submitCubit.resolveFreshSchoolTimeZone();
    } catch (e) {
      AppLogger.d('StaffTransferForm: resolveFreshSchoolTimeZone failed: $e');
    }

    final isAdmin = await _resolveIsStaffAdminPersona();
    final currentStaffCode = await _submitCubit.resolveCurrentStaffCode();
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
  /// successful transfer so the dropdown's exclusion filter never goes
  /// stale (this is what prevents "transfer to same classroom").
  ///
  /// `StaffProfile.primaryClassroomCode` looked like the right source but
  /// is actually a STATIC default assignment that does NOT change when a
  /// staff member is transferred — using it showed the staff's permanent
  /// "home" classroom instead of where they currently are. The real source
  /// of truth is today's "Transfer form list" (`getStaffTransferFormList`,
  /// the same endpoint the staff-selection transfer form uses to build its
  /// candidate list): the backend keeps ONE attendance record per staff per
  /// day, and that record's `classroomCode` is kept in sync with every
  /// transfer applied so far today. It's trusted directly, with no extra
  /// gating — `classroomName` on the same record is NOT used for matching
  /// or exclusion since the API can leave it null; a classroom's name is
  /// only ever resolved from the classroom directory, by code, wherever a
  /// name is actually needed. Falls back to the (static) profile field only
  /// when today's list has no record for this staff at all.
  Future<void> _hydrateSelfStaffClassroomDataIfNeeded({
    required bool isAdmin,
  }) async {
    // Run for all roles (including admins) when a single staff member is
    // selected. Admins can be assigned to a classroom too — skipping them
    // caused the dropdown's exclusion filter to be skipped for every
    // admin-initiated transfer.
    if (_selectedStaff.length != 1) return;
    final selected = _selectedStaff.first;
    final selectedStaffCode = (selected.staffCode ?? '').trim();
    if (selectedStaffCode.isEmpty) {
      if (mounted) setState(() => _currentClassroomResolved = true);
      return;
    }

    // Seed from the entity immediately so the exclusion filter isn't empty
    // while the network round-trip below is in flight.
    final existingCode = (selected.classroomCode ?? '').trim();
    if (existingCode.isNotEmpty && (_currentClassroomCode ?? '').isEmpty) {
      if (!mounted) return;
      setState(() => _currentClassroomCode = existingCode);
    }

    String fmt(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    var resolved = '';
    try {
      final today = fmt(ServerTimeService.instance.now());
      // Deliberately no `search:` here. That query param is a free-text NAME
      // search everywhere else it's used in this app (it's fed by a search
      // box, never a staff code) — passing a staff code through it matches
      // nothing server-side, so the list always comes back empty and this
      // silently falls through to the static profile fallback below, which
      // is exactly the "stuck on the very first classroom" symptom. Fetch a
      // roster-sized page instead and match the staff code client-side, the
      // same way [StaffSelectionTransferForm] loads its full staff list.
      final page = await _submitCubit.fetchTransferFormList(
        fromAbsenceDate: today,
        toAbsenceDate: today,
        page: 0,
        size: 1000,
      );

      for (final item in page.items) {
        if (item.staffCode.trim() == selectedStaffCode) {
          resolved = item.classroomCode.trim();
          break;
        }
      }
    } catch (_) {
      // Fall through to the static profile fallback below.
    }

    if (resolved.isEmpty) {
      // Last resort only — this is the staff's static default classroom,
      // not necessarily where they currently are.
      try {
        final profile = await _submitCubit.fetchStaffProfile(
          staffCode: selectedStaffCode,
          forEditStaff: true,
        );
        resolved = profile.primaryClassroomCode.trim();
      } catch (_) {
        // Keep whatever was already seeded from the entity above.
      }
    }

    if (!mounted) return;
    setState(() {
      _currentClassroomResolved = true;
      if (resolved.isNotEmpty) {
        _currentClassroomCode = resolved;
        // If the dropdown selection now matches the freshly-resolved current
        // classroom (e.g. the user picked a target before this async
        // resolution caught up), it's no longer a valid transfer target —
        // clear it rather than leaving a stale, now-invalid selection.
        if (_selectedToClassroomCode == resolved) {
          _selectedToClassroomCode = null;
        }
      }
    });
  }

  Future<bool> _resolveIsStaffAdminPersona() =>
      resolveIsStaffAdminPersonaForView(context, mounted: mounted);

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

    final schoolTimeZone = await _submitCubit.resolveFreshSchoolTimeZone();
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

    // transferReason defaults to the generic placeholder the payload carried.
    final request = StaffTransferRequest(
      staffCode: staffCode,
      staffCodes: staffCodes,
      toClassroomCode: toClassroomCode,
      toClassroomCodeByStaffCode: toClassroomCodeByStaffCode,
      timeZone: schoolTimeZone,
      transferredAt: transferredAt.toUtc().toIso8601String(),
    );

    try {
      final result = await _submitCubit.submit(request: request);
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
        if (widget.popOnSuccess || !isStaffAdmin) {
          // Teacher/staff persona, or a caller that owns its own screen:
          // no forced navigation — stay on whatever screen this action was
          // started from.
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
          // Both the current-classroom lookup and the classroom directory
          // must be in before the dropdown is allowed to show anything —
          // otherwise it can briefly list the staff's own current classroom
          // as a selectable destination.
          final isTransferOptionsReady =
              _currentClassroomResolved && !classroomState.isLoading;
          final transferOptions = isTransferOptionsReady
              ? classroomState.classrooms
                    .where((c) => c.name.trim().isNotEmpty)
                    .where((c) => c.code.trim() != currentClassroomCode)
                    .map((c) => c.name)
                    .toList(growable: false)
              : const <String>[];
          _hasTransferTargets = isTransferOptionsReady && transferOptions.isNotEmpty;
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
                      itemBuilder: (context, index) => AttendanceRemoveTile(
                        name: _selectedStaff[index].name,
                        photoUuid: _selectedStaff[index].photoUuid ?? '',
                        staffCode: _selectedStaff[index].staffCode,
                        canRemove: _selectedStaff.length > 1,
                        onRemove: () => _removeStaff(_selectedStaff[index]),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  // Date + Time (50/50 split) - match StudentTransferForm alignment
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppText.label('Date'),
                            const SizedBox(height: AppSpacing.xs),
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
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppText.label('Time'),
                            const SizedBox(height: AppSpacing.xs),
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
                  const SizedBox(height: AppSpacing.lg),
                  const AppText.label('Transfer to Classroom'),
                  const SizedBox(height: AppSpacing.xs),
                  CustomDropdown(
                    hintText: !isTransferOptionsReady
                        ? 'Loading classrooms...'
                        : (_hasTransferTargets
                              ? 'Select classroom'
                              : 'No classroom available'),
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
