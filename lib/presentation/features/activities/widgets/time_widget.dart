import 'package:flutter/material.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
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

  @override
  void initState() {
    super.initState();
    final hasPreset = _parseTimeOfDay(widget.prefilledTime) != null ||
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
          tz.toUpperCase() != SchoolTimezoneResolver.fallbackTimeZone.toUpperCase()) {
        _selectedTime =
            SchoolZoneDateTime.schoolCalendarDateAndTimeNow(tz).$2;
      } else {
        _selectedTime = TimeOfDay.now();
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onTimeChanged?.call(_selectedTime);
      });
    }
    _setSchoolDefaultTimeIfNeeded();
  }

  Future<void> _setSchoolDefaultTimeIfNeeded() async {
    if (widget.prefilledTime != null && widget.prefilledTime!.trim().isNotEmpty) return;
    if (widget.initialTime != null) return;
    final schoolTimeZone = await SchoolTimezoneResolver.resolveForCurrentSchool(
      storage: serviceLocator<StorageService>(),
      apiClient: serviceLocator<ApiClient>(),
    );
    final schoolNow = SchoolZoneDateTime.schoolCalendarDateAndTimeNow(schoolTimeZone).$2;
    if (!mounted) return;
    setState(() {
      _selectedTime = schoolNow;
    });
    widget.onTimeChanged?.call(_selectedTime);
  }

  TimeOfDay? _parseTimeOfDay(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return null;
    final cleaned = timeStr.trim().replaceAll(' ', '').toUpperCase();
    final regex = RegExp(r'^(\d{1,2}):?(\d{2})\s*(AM|PM)?$', caseSensitive: false);
    final match = regex.firstMatch(cleaned);
    if (match != null) {
      int hour = int.parse(match.group(1)!);
      int minute = int.parse(match.group(2)!);
      final period = match.group(3);

      if (period != null) {
        if (hour == 12) hour = period == 'AM' ? 0 : 12;
        else if (period == 'PM') hour += 12;
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
        setState(() {
          _selectedTime = picked;
        });
        widget.onTimeChanged?.call(_selectedTime);
      },
    );
  }
}