import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/core/util/api_error_handler.dart';
import 'package:wowcare/core/util/attendance_classroom_scope.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/core/util/staff_code_resolver.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/simple_time_picker_field.dart';
import 'staff_entity.dart';
import 'package:wowcare/presentation/features/attendance/view/staff_attendance_tabbed_view.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';

class StaffTransferForm extends StatefulWidget {
  const StaffTransferForm({
    super.key,
    this.staff,
    this.staffList,
  });

  final StaffEntity? staff;
  final List<StaffEntity>? staffList;

  static const String routeName = '/staff-transfer-form';

  @override
  State<StaffTransferForm> createState() => _StaffTransferFormState();
}

class _StaffTransferFormState extends State<StaffTransferForm> {
  DateTime _selectedTransferDate = DateTime.now();
  TimeOfDay _selectedTransferTime = TimeOfDay.now();
  String? _selectedToClassroomCode;
  final Map<String, String> _classroomNameToCode = <String, String>{};
  List<StaffEntity> _selectedStaff = [];
  bool _isSubmitting = false;
  bool? _isStaffAdminPersona;
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
        StaffEntity(
          id: 1,
          name: 'Staff Member',
          primaryRoomId: 1,
        ),
      ];
    }
    _classroomCubit = serviceLocator<ClassroomCubit>()
      ..loadActiveClassrooms(onlyTypeClassroom: false);
    _loadPersonaFlags();
  }

  @override
  void dispose() {
    _classroomCubit.close();
    super.dispose();
  }

  Future<void> _loadPersonaFlags() async {
    final isAdmin = await _resolveIsStaffAdminPersona();
    if (!mounted) return;
    setState(() {
      _isStaffAdminPersona = isAdmin;
      if (!isAdmin) {
        _selectedTransferDate = DateTime.now();
        _selectedTransferTime = TimeOfDay.now();
      }
    });
  }

  Future<bool> _resolveIsStaffAdminPersona() async {
    final storage = serviceLocator<StorageService>();
    final staffType =
        (await storage.getString(StorageKeys.staffType) ?? '').trim().toUpperCase();

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

  void _handleSubmit() {
    if (_selectedToClassroomCode == null || _selectedToClassroomCode!.isEmpty) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: 
        const SnackBar(
          content: Text('Please select a classroom to transfer to'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    _submitTransfer();
  }

  Future<String> _resolveStaffCode() =>
      resolveStaffCodeForLoggedInUser();

  Future<void> _submitTransfer() async {
    if (_isSubmitting) return;
    if (_selectedStaff.isEmpty ||
        _selectedToClassroomCode == null ||
        _selectedToClassroomCode!.isEmpty) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: 
        const SnackBar(
          content: Text('No staff/classroom selected to transfer'),
          backgroundColor: AppColors.warningColor,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final client = serviceLocator<ApiClient>().client;
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffAttendanceRecordsTransfer,
      ApiConstants.attendanceBaseUrl,
    );

    final staffCode = await _resolveStaffCode();
    if (!mounted) return;
    if (staffCode.isEmpty) {
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: 
        const SnackBar(
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
        snackBar: 
        const SnackBar(
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
        snackBar: 
        const SnackBar(
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

    final now = DateTime.now();
    final effectiveDate =
        (_isStaffAdminPersona ?? false) ? _selectedTransferDate : now;
    final today = DateTime(now.year, now.month, now.day);
    final pickedDay =
        DateTime(effectiveDate.year, effectiveDate.month, effectiveDate.day);
    final safeDate = pickedDay.isAfter(today) ? today : effectiveDate;
    final effectiveTime =
        (_isStaffAdminPersona ?? false) ? _selectedTransferTime : TimeOfDay.fromDateTime(now);
    final transferredAt = DateTime(
      safeDate.year,
      safeDate.month,
      safeDate.day,
      effectiveTime.hour,
      effectiveTime.minute,
    ).toUtc();

    final payload = <String, dynamic>{
      'staffCode': staffCode,
      'staffCodes': staffCodes,
      'toClassroomCode': toClassroomCode,
      'toClassroomCodeByStaffCode': toClassroomCodeByStaffCode,
      'transferReason': 'Transferred via mobile app',
      'timeZone': 'Asia/Kolkata',
      'transferredAt': transferredAt.toIso8601String(),
    };

    try {
      final body = Map<String, dynamic>.from(payload);
      await applyAllowedClassroomCodesToAttendanceBody(
        body,
        serviceLocator<StorageService>(),
      );
      final response = await client.post<dynamic>(
        endpoint,
        data: body,
      );

      final data = response.data;
      bool success = false;
      String message = 'Transferred successfully';

      if (data is Map<String, dynamic>) {
        success = data['success'] as bool? ?? false;
        if (data['message'] != null) {
          message = data['message'].toString();
        }
      }

      if (!mounted) return;

      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: 
        SnackBar(
          content: Text(message),
          backgroundColor:
              success ? AppColors.successColor : AppColors.errorColor,
        ),
      );

      if (success) {
        if (isStaffAdmin) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => const StaffAttendanceTabbedView(),
            ),
            (route) => false,
          );
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (!mounted) return;
      final errorMessage = ApiErrorHandler.extractErrorMessage(e);
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: 
        SnackBar(
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

  @override
  Widget build(BuildContext context) {
    final currentClassroom =
        (_selectedStaff.isNotEmpty ? _selectedStaff.first.classroomName : null) ??
            'N/A';
    return BlocProvider<ClassroomCubit>.value(
      value: _classroomCubit,
      child: StaffFormLayout(
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
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 3.5,
                ),
                itemCount: _selectedStaff.length,
                itemBuilder: (context, index) =>
                    RemoveStaffTile(staff: _selectedStaff[index]),
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
                        isDisabled: _isStaffAdminPersona == false,
                        onDateSelected: (date) {
                          setState(() {
                            final now = DateTime.now();
                            final today = DateTime(now.year, now.month, now.day);
                            final picked =
                                DateTime(date.year, date.month, date.day);
                            _selectedTransferDate =
                                picked.isAfter(today) ? today : date;
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
                        ignoring: _isStaffAdminPersona == false,
                        child: SimpleTimePickerField(
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
                          style: TextStyle(
                            color:
                                AppColors.primaryColor.withValues(alpha: 0.5),
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
                      BlocBuilder<ClassroomCubit, ClassroomState>(
                        builder: (context, state) {
                          if (_classroomNameToCode.isEmpty &&
                              state.classrooms.isNotEmpty) {
                            for (final c in state.classrooms) {
                              _classroomNameToCode[c.name] = c.code;
                            }
                          }
                          final options = state.classrooms
                              .where((c) => c.name != currentClassroom)
                              .map((c) => c.name)
                              .toList();
                          String? selectedName;
                          for (final entry in _classroomNameToCode.entries) {
                            if (entry.value == _selectedToClassroomCode) {
                              selectedName = entry.key;
                              break;
                            }
                          }
                          return CustomDropdown(
                            hintText: 'Select classroom',
                            items: options,
                            selectedItem: selectedName,
                            onSelect: (value) {
                              setState(() {
                                _selectedToClassroomCode = value == null
                                    ? null
                                    : _classroomNameToCode[value];
                              });
                            },
                          );
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
    ));
  }

}

class RemoveStaffTile extends StatelessWidget {
  final StaffEntity staff;

  const RemoveStaffTile({
    super.key,
    required this.staff,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.themeColor,
        ),
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
                    staff.name.split(' ').first,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                    style: const TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

