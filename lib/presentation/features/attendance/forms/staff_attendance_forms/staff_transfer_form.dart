import 'dart:convert';

import 'package:flutter/material.dart';
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
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/core/util/staff_code_resolver.dart';
import 'staff_entity.dart';

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
  String? selectedClassroom;
  String currentClassroom = 'Classroom A';
  List<String> availableClassrooms = ['Classroom B', 'Classroom C', 'Classroom D'];
  List<StaffEntity> _selectedStaff = [];
  bool _isSubmitting = false;
  bool? _isStaffAdminPersona;

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
    _loadPersonaFlags();
  }

  Future<void> _loadPersonaFlags() async {
    final isAdmin = await _resolveIsStaffAdminPersona();
    if (!mounted) return;
    setState(() {
      _isStaffAdminPersona = isAdmin;
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
    if (selectedClassroom == null) {
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
    if (_selectedStaff.isEmpty || selectedClassroom == null) {
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

    // TODO: Map selectedClassroom display label to a real classroom code.
    const toClassroomCode = '';

    final toClassroomCodeByStaffCode = <String, String>{
      for (final code in staffCodes) code: toClassroomCode,
    };

    final transferredAt = DateTime.now().toUtc();

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
      final response = await client.post<dynamic>(
        endpoint,
        data: payload,
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
        Navigator.pop(context);
      }
    } catch (_) {
      if (!mounted) return;
      CoreUtils.showTopSnackBarFromSnackBar(
        context: context,
        snackBar: 
        const SnackBar(
          content: Text('Failed to transfer staff. Please try again.'),
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
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppText.label('Current Classroom'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(8),
                                color: const Color.fromRGBO(
                                    177, 175, 233, 0.1),
                              ),
                              child: AppText.value(
                                currentClassroom,
                                style: TextStyle(
                                  color: AppColors.primaryColor
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          ),
                        ],
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 0,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                          color: const Color.fromRGBO(177, 175, 233, 0.1),
                        ),
                        child: DropdownButton<String>(
                          value: selectedClassroom,
                          hint: const Text('Select classroom'),
                          style: TextStyle(
                            color: AppColors.primaryColor
                                .withValues(alpha: 0.5),
                            fontSize: 15,
                          ),
                          isExpanded: true,
                          icon: SvgPicture.asset(MediaRes.arrow_drop_down),
                          underline: Container(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedClassroom = newValue!;
                            });
                          },
                          items:
                              availableClassrooms.map((String classroom) {
                            return DropdownMenuItem<String>(
                              value: classroom,
                              child: Text(classroom),
                            );
                          }).toList(),
                        ),
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

