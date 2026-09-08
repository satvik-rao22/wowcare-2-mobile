import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import 'package:wowcare/core/util/server_time_service.dart';
import 'package:wowcare/presentation/features/activities/view_model/activity_editor_cubit.dart';
import 'package:wowcare/shared/common/widgets/gradient_time_picker_field.dart';

class TimeWidget extends StatefulWidget {
  const TimeWidget({
    super.key,
    this.isEditable = true,
    this.initialTime,
    this.prefilledTime,
    this.isRequired = false,
    this.label = 'Time',
    this.doNotShowTime = false,
    this.onTimeChanged,
  });

  final bool isEditable;
  final String? prefilledTime;
  final String label;
  final TimeOfDay? initialTime; // Optional initial time
  final bool isRequired;
  final bool doNotShowTime;
  final ValueChanged<TimeOfDay>? onTimeChanged;

  @override
  State<TimeWidget> createState() => _TimeWidgetState();
}

class _TimeWidgetState extends State<TimeWidget> {
  late TimeOfDay _selectedTime;

  /// True once the user has picked a DIFFERENT time via the picker UI (as
  /// opposed to the live school-now default). Freezes [_selectedTime] and
  /// stops [_liveNowTimer] the moment it's set — a manual choice must never
  /// get silently overwritten by the live-now tracking below.
  bool _userPickedManually = false;

  /// Keeps [_selectedTime] tracking live school "now" (minute-aligned, no
  /// network calls — reuses the already-synced [ServerTimeService] offset)
  /// for as long as the user hasn't manually touched the field.
  ///
  /// Without this, [_selectedTime] is a snapshot frozen at whenever this
  /// widget happened to initialize. [SchoolZoneDateTime.resolvePickedInstantUtc]
  /// only returns full second-precision "now" at submit time when the
  /// picked value STILL equals school-now at that moment — if the user
  /// spends any time filling in the rest of the form (which is the common
  /// case) without ever touching the time field, that frozen snapshot goes
  /// stale and the resolver wrongly treats it as a deliberately-picked
  /// instant, truncating seconds to 0 even though the user never touched
  /// the time field. Keeping the value live for as long as it's untouched
  /// guarantees the "did the user actually pick a time" check stays correct
  /// no matter how long the form stays open before Save is pressed.
  Timer? _liveNowTimer;

  @override
  void initState() {
    super.initState();
    final hasPreset =
        _parseTimeOfDay(widget.prefilledTime) != null ||
        widget.initialTime != null;
    if (hasPreset) {
      _selectedTime =
          _parseTimeOfDay(widget.prefilledTime) ?? widget.initialTime!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onTimeChanged?.call(_selectedTime);
      });
    } else {
      final tz = SchoolTimezoneResolver.lastKnownTimeZone.trim();
      if (tz.isNotEmpty &&
          tz.toUpperCase() !=
              SchoolTimezoneResolver.fallbackTimeZone.toUpperCase()) {
        _selectedTime = SchoolZoneDateTime.schoolCalendarDateAndTimeNow(tz).$2;
      } else {
        _selectedTime = ServerTimeService.instance.timeOfDayNow();
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onTimeChanged?.call(_selectedTime);
      });
      _scheduleNextLiveNowTick();
    }
    _setSchoolDefaultTimeIfNeeded();
  }

  @override
  void dispose() {
    _liveNowTimer?.cancel();
    super.dispose();
  }

  TimeOfDay _currentSchoolNow() {
    final tz = SchoolTimezoneResolver.lastKnownTimeZone.trim();
    return SchoolZoneDateTime.schoolCalendarDateAndTimeNow(
      tz.isNotEmpty ? tz : SchoolTimezoneResolver.fallbackTimeZone,
    ).$2;
  }

  /// Fires shortly after the next real minute boundary, refreshes
  /// [_selectedTime] to school-now, then reschedules — keeping the field
  /// aligned to the wall clock instead of drifting on a fixed-period timer.
  void _scheduleNextLiveNowTick() {
    _liveNowTimer?.cancel();
    final nowUtc = ServerTimeService.instance.nowUtc();
    final msIntoMinute = nowUtc.second * 1000 + nowUtc.millisecond;
    // +500ms safety margin past the boundary so the tick lands just after
    // the minute actually rolls over, never just before.
    final msUntilNextTick = (60000 - msIntoMinute) + 500;
    _liveNowTimer = Timer(Duration(milliseconds: msUntilNextTick), () {
      if (!mounted || _userPickedManually) return;
      final now = _currentSchoolNow();
      if (now != _selectedTime) {
        setState(() => _selectedTime = now);
        widget.onTimeChanged?.call(_selectedTime);
      }
      _scheduleNextLiveNowTick();
    });
  }

  Future<void> _setSchoolDefaultTimeIfNeeded() async {
    if (widget.prefilledTime != null && widget.prefilledTime!.trim().isNotEmpty)
      return;
    if (widget.initialTime != null) return;
    final schoolTimeZone = await context
        .read<ActivityEditorCubit>()
        .resolveSchoolTimezone();
    final schoolNow = SchoolZoneDateTime.schoolCalendarDateAndTimeNow(
      schoolTimeZone,
    ).$2;
    if (!mounted || _userPickedManually) return;
    setState(() {
      _selectedTime = schoolNow;
    });
    widget.onTimeChanged?.call(_selectedTime);
    // The timezone may have just resolved for the first time (was UTC
    // fallback at initState) — realign the live-now tick to the now-correct
    // wall clock rather than waiting on the fallback-zone-based schedule.
    _scheduleNextLiveNowTick();
  }

  TimeOfDay? _parseTimeOfDay(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return null;
    final cleaned = timeStr.trim().replaceAll(' ', '').toUpperCase();
    final regex = RegExp(
      r'^(\d{1,2}):?(\d{2})\s*(AM|PM)?$',
      caseSensitive: false,
    );
    final match = regex.firstMatch(cleaned);
    if (match != null) {
      int hour = int.parse(match.group(1)!);
      int minute = int.parse(match.group(2)!);
      final period = match.group(3);

      if (period != null) {
        if (hour == 12)
          hour = period == 'AM' ? 0 : 12;
        else if (period == 'PM')
          hour += 12;
      }
      return TimeOfDay(hour: hour, minute: minute);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Visuals now come from the shared GradientTimePickerField; this widget
    // keeps owning the state/behavior (school-timezone default, prefill
    // parsing, onTimeChanged emission, editable/disabled gating).
    return GradientTimePickerField(
      label: widget.label,
      isRequired: widget.isRequired,
      enabled: widget.isEditable,
      time: widget.doNotShowTime ? null : _selectedTime,
      onTimeSelected: (picked) {
        if (picked == _selectedTime) return;
        _liveNowTimer?.cancel();
        setState(() {
          _userPickedManually = true;
          _selectedTime = picked;
        });
        widget.onTimeChanged?.call(_selectedTime);
      },
    );
  }
}
