import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/staff/entities/staff_profile.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/presentation/features/classroom/cubit/classroom_cubit.dart';
import 'package:wowcare/presentation/features/staff/cubit/staff_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/custom_dropdown.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import '../../../../../domain/features/staff_scheduling/copy-shift/domain/copy_shift_params.dart';
import '../../cubit/copy-shift/copy_shift_cubit.dart';

class CopyShiftForm extends StatefulWidget {
  const CopyShiftForm({super.key});

  static const String routeName = '/copy-shift';

  @override
  State<CopyShiftForm> createState() => _CopyShiftFormState();
}

class _CopyShiftFormState extends State<CopyShiftForm> {
  bool _copyByStaff = false;

  String? _selectedStaffName;
  String? _selectedStaffCode;
  String? schoolCode;

  String? _selectedClassroomName;
  String? _selectedClassroomCode;

  List<String> _allowedClassroomCodes = [];
  List<AllowedClassroom> _allowedClassrooms = [];

  bool _isLoadingProfile = false;
  DateTime? _sourceWeekStart;
  DateTime? _targetWeekStart;
  DateTime? _untilDate;

  @override
  void initState() {
    super.initState();

    context.read<ClassroomCubit>().loadActiveClassrooms();

    context.read<StaffCubit>().loadInitial();
  }

  Future<void> _loadStaffProfile(String staffCode) async {
    setState(() => _isLoadingProfile = true);

    try {
      final profile = await serviceLocator<StaffRepository>().getStaffProfile(
        staffCode: staffCode,
        forEditStaff: true,
      );

      if (!mounted) return;

      setState(() {
        _allowedClassroomCodes = profile.allowedClassroomCodes;
        _allowedClassrooms = profile.allowedClassrooms;

        /// Auto select primary classroom
        if (profile.primaryClassroomCode.isNotEmpty) {
          _selectedClassroomCode = profile.primaryClassroomCode;

          final classroom = profile.allowedClassrooms.firstWhere(
            (e) => e.code == profile.primaryClassroomCode,
            orElse: () => AllowedClassroom(code: '', name: ''),
          );

          _selectedClassroomName = classroom.name;
        }

        _isLoadingProfile = false;
      });
    } catch (e) {
      setState(() => _isLoadingProfile = false);

      CoreUtils.logApiError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);

    return GlobalScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Copy Shift",
                style: TextStyle(
                  fontFamily: "Manrope",
                  fontSize: responsive.titleFontSize,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff573353),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Card(
              elevation: 0,
              color: AppColors.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  responsive.isTablet ? 40.0 : 24.0,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(responsive.isTablet ? 32.0 : 16.0),
                child: copyShift(context),
              ),
            ),
          ],
        ),
      ),
      showCustomNavigationBarButtons: true,
      onPressedConfirm: () async {
        /// STAFF MODE VALIDATION
        if (_copyByStaff && _selectedStaffCode == null) {
          CoreUtils.showTopSnackBar(
            context: context,
            message: 'Please select staff',
            isWarning: true,
          );
          return;
        }

        /// CLASSROOM MODE VALIDATION
        if (!_copyByStaff && _selectedClassroomCode == null) {
          CoreUtils.showTopSnackBar(
            context: context,
            message: 'Please select classroom',
            isWarning: true,
          );
          return;
        }

        /// DATE RANGE VALIDATION
        if (_sourceWeekStart == null || _targetWeekStart == null) {
          CoreUtils.showTopSnackBar(
            context: context,
            message: 'Please select date range',
            isWarning: true,
          );
          return;
        }

        try {
          await context.read<CopyShiftCubit>().copyShift(
            params: CopyShiftParams(
              schoolCode: StorageKeys.schoolCode,

              organizationCode: StorageKeys.organizationCode,

              /// IF STAFF MODE -> USE PRIMARY CLASSROOM
              classroomCode: _copyByStaff
                  ? _selectedClassroomCode ?? ''
                  : _selectedClassroomCode!,

              sourceWeekStart: DateFormat(
                'yyyy-MM-dd',
              ).format(_sourceWeekStart!),

              targetWeekStart: DateFormat(
                'yyyy-MM-dd',
              ).format(_targetWeekStart!),
            ),
          );

          if (!mounted) return;

          CoreUtils.showTopSnackBar(
            context: context,
            message: 'Shifts copied successfully',
            isSuccess: true,
          );

          Navigator.pop(context);
        } catch (e) {
          if (!mounted) return;

          CoreUtils.showTopSnackBar(
            context: context,
            message: e.toString(),
            isWarning: true,
          );
        }
      },
      onPressedCancel: () {
        Navigator.pop(context);
      },
    );
  }

  Widget copyShift(BuildContext context) {
    return BlocBuilder<ClassroomCubit, ClassroomState>(
      builder: (context, classroomState) {
        return BlocBuilder<StaffCubit, StaffState>(
          builder: (context, staffState) {
            final staffList = staffState.items
                .map((s) => {'code': s.code, 'name': s.name})
                .toList();

            final classroomList = _copyByStaff
                ? _allowedClassrooms
                      .map((c) => {'code': c.code, 'name': c.name})
                      .toList()
                : classroomState.classrooms
                      .map((c) => {'code': c.code, 'name': c.name})
                      .toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Copy shifts by
                RichText(
                  text: const TextSpan(
                    text: 'Copy shifts by ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                    children: [
                      TextSpan(
                        text: '*',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          _copyByStaff = false;

                          _selectedStaffName = null;
                          _selectedStaffCode = null;
                        });
                      },
                      child: Row(
                        children: [
                          Radio<bool>(
                            value: false,
                            groupValue: _copyByStaff,
                            activeColor: AppColors.themeColor,
                            onChanged: (value) {
                              setState(() {
                                _copyByStaff = false;
                              });
                            },
                          ),

                          const Text(
                            'Classroom',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 20),

                    InkWell(
                      onTap: () {
                        setState(() {
                          _copyByStaff = true;

                          _selectedClassroomName = null;
                          _selectedClassroomCode = null;
                        });
                      },
                      child: Row(
                        children: [
                          Radio<bool>(
                            value: true,
                            groupValue: _copyByStaff,
                            activeColor: AppColors.themeColor,
                            onChanged: (value) {
                              setState(() {
                                _copyByStaff = true;
                              });
                            },
                          ),

                          const Text(
                            'Staff',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                /// Staff Dropdown
                if (_copyByStaff)
                  CustomDropdown(
                    label: 'Staff',
                    hintText: staffState.isLoading
                        ? 'Loading staff...'
                        : 'Select Staff',
                    isRequired: true,
                    selectedItem: _selectedStaffName,
                    items: staffList
                        .map<String>((e) => e['name'] as String)
                        .toList(),
                    onSelect: (val) async {
                      final found = staffList.firstWhere(
                        (e) => e['name'] == val,
                        orElse: () => {},
                      );

                      if (found.isNotEmpty) {
                        setState(() {
                          _selectedStaffName = found['name'];
                          _selectedStaffCode = found['code'];
                        });

                        await _loadStaffProfile(found['code'] as String);
                      }
                    },
                  ),

                /// Classroom Dropdown
                if (!_copyByStaff)
                  CustomDropdown(
                    label: 'Classrooms',
                    hintText: classroomState.isLoading
                        ? 'Loading classrooms...'
                        : 'Select Classrooms',
                    isRequired: true,
                    selectedItem: _selectedClassroomName,
                    items: classroomList
                        .map<String>((e) => e['name'] as String)
                        .toList(),
                    onSelect: (val) {
                      final found = classroomList.firstWhere(
                        (e) => e['name'] == val,
                        orElse: () => {},
                      );

                      if (found.isNotEmpty) {
                        setState(() {
                          _selectedClassroomName = found['name'];
                          _selectedClassroomCode = found['code'];
                        });
                      }
                    },
                  ),

                /// Auto Selected Primary Classroom
                if (_copyByStaff && _selectedClassroomName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: CustomDropdown(
                      label: 'Primary Classroom',
                      hintText: _isLoadingProfile
                          ? 'Loading classroom...'
                          : 'Primary Classroom',
                      selectedItem: _selectedClassroomName,
                      items: classroomList
                          .map<String>((e) => e['name'] as String)
                          .toList(),
                      onSelect: (val) {},
                    ),
                  ),

                const SizedBox(height: 20),

                CustomDateTimeField(
                  label: 'Date Range',
                  isRangePicker: true,
                  isRequired: true,
                  fetchInitialTime: false,

                  onRangeSelected: (startDate, endDate) {
                    setState(() {
                      _sourceWeekStart = startDate;
                      _targetWeekStart = endDate;
                    });
                  },
                ),
                const SizedBox(height: 20),
                CustomDateTimeField(
                  label: 'Until Date',
                  // isRangePicker: true,
                  isRequired: true,
                  fetchInitialTime: false,
                  onDateSelected: (date) {
                    setState(() {
                      _untilDate = date;
                    });
                  },
                ),

                /// Buttons
                const SizedBox(height: 30),
              ],
            );
          },
        );
      },
    );
  }
}
