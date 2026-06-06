import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/domain/features/kiosk/entities/kiosk_pin_result_entity.dart';
import 'package:wowcare/presentation/features/kiosk/cubit/kiosk_dashboard_cubit.dart';
import 'package:wowcare/presentation/features/kiosk/widgets/kiosk_qr_section_widget.dart';
import 'package:wowcare/presentation/features/kiosk/widgets/kiosk_pin_pad_widget.dart';
import 'package:wowcare/presentation/features/kiosk/utils/kiosk_access_control.dart';
import 'package:wowcare/app/di/di.dart';

/// OPTIMIZED: Kiosk dashboard screen with isolated rendering.
///
/// PERFORMANCE IMPROVEMENTS:
/// 1. QR code rendering isolated in KioskQrSectionWidget with RepaintBoundary
/// 2. PIN pad state isolated in KioskPinPadWidget with local state
/// 3. Prevents cascade rebuilds when PIN changes
/// 4. Fixes gralloc4 GPU warnings from excessive re-renders
class KioskDashboardScreen extends StatefulWidget {
  const KioskDashboardScreen({super.key});

  static const String routeName = '/kiosk';

  @override
  State<KioskDashboardScreen> createState() => _KioskDashboardScreenState();
}

class _KioskDashboardScreenState extends State<KioskDashboardScreen> {
  final int maxPinLength = 4;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(context.read<KioskDashboardCubit>().loadQrCode());
    });
  }

  bool isIpad() {
    return Platform.isIOS && (MediaQuery.of(context).size.shortestSide >= 600);
  }

  void _onPinSubmit(String pin) {
    AppLogger.d('[Kiosk] PIN submitted: length=${pin.length}');
    unawaited(context.read<KioskDashboardCubit>().submitPin(pin));
  }

  @override
  Widget build(BuildContext context) {
    final bool isTablet = isIpad();
    return _buildScaffold(isTablet);
  }

  Widget _buildScaffold(bool isTablet) {
    return BlocListener<KioskDashboardCubit, KioskDashboardState>(
      listener: (context, state) {
        if (state is KioskDashboardPinSuccess) {
          _handlePinSuccess(context, state.pinResult);
        } else if (state is KioskDashboardError) {
          CoreUtils.showTopSnackBar(
            context: context,
            message: state.message,
            isError: true,
          );
        }
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight + 1),
          child: Container(
            color: Colors.white,
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 16.0),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage: AssetImage(
                        'assets/images/WowCarePNG.png',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'WOWW Kiosk',
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.exit_to_app,
                      color: AppColors.primaryColor,
                    ),
                    onPressed: () async {
                      AppLogger.d('[Kiosk] Logout button pressed');
                      await serviceLocator<KioskAccessControl>()
                          .deactivateKioskMode();
                      if (mounted) {
                        GoRouter.of(context).go('/sign-in');
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomSheet: Container(color: AppColors.themeColor, height: 1),
        body: BlocBuilder<KioskDashboardCubit, KioskDashboardState>(
          builder: (context, state) {
            return Container(
              decoration: BoxDecoration(
                gradient: AppColors.buildScaffoldGradient(),
              ),
              child: _buildContent(context, state, isTablet),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    KioskDashboardState state,
    bool isTablet,
  ) {
    if (isTablet) {
      return _buildTabletLayout(state);
    } else {
      return _buildPhoneLayout(state);
    }
  }

  /// Phone layout: QR on top, PIN pad below (full screen each)
  Widget _buildPhoneLayout(KioskDashboardState state) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.45,
            child: KioskQrSectionWidget(
              state: state,
              schoolName: _getSchoolName(state),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,
            child: KioskPinPadWidget(
              onPinSubmit: _onPinSubmit,
              maxPinLength: maxPinLength,
            ),
          ),
        ],
      ),
    );
  }

  /// Tablet layout: QR on left, PIN pad on right (50/50 split)
  Widget _buildTabletLayout(KioskDashboardState state) {
    return Row(
      children: [
        Expanded(
          child: KioskQrSectionWidget(
            state: state,
            schoolName: _getSchoolName(state),
          ),
        ),
        Expanded(
          child: KioskPinPadWidget(
            onPinSubmit: _onPinSubmit,
            maxPinLength: maxPinLength,
          ),
        ),
      ],
    );
  }

  String _getSchoolName(KioskDashboardState state) {
    if (state is KioskDashboardQrLoaded) {
      return state.schoolName;
    }
    if (state is KioskDashboardPinValidating && state.schoolName != null) {
      return state.schoolName!;
    }
    return '';
  }

  void _handlePinSuccess(BuildContext context, KioskPinResultEntity result) {
    AppLogger.d(
      '[Kiosk] PIN verification success: persona=${result.persona}, '
      'isStaff=${result.isStaff}, isGuardian=${result.isGuardian}',
    );

    if (result.isStaff) {
      AppLogger.d('[Kiosk] Routing to staff attendance flow');
      _routeStaffAttendance(context, result, '');
    } else if (result.isGuardian) {
      AppLogger.d('[Kiosk] Routing to guardian/student attendance flow');
      _routeGuardianStudentAttendance(context, result, '');
    }
  }

  void _routeStaffAttendance(
    BuildContext context,
    KioskPinResultEntity result,
    String currentPin,
  ) {
    final staffCode = result.staffCode ?? '';
    final status = (result.staffStatus ?? 'SIGNED_OUT').toUpperCase();

    AppLogger.d('[KIOSK] Persona=STAFF, StaffCode=$staffCode, Status=$status');

    if (staffCode.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Staff code not found',
        isError: true,
      );
      return;
    }

    final route = status == 'SIGNED_IN'
        ? '/dashboard/staff-sign-out-form'
        : '/dashboard/staff-sign-in-form';

    AppLogger.d(
      '[KIOSK] Persona=STAFF, StaffCode=$staffCode, Status=$status, Routing to $route',
    );

    GoRouter.of(context).go(
      route,
      extra: {
        'isKiosk': true,
        'staffCode': staffCode,
        'staffName': result.staffName ?? 'Unknown Staff',
        'classroomName': result.classroomName ?? 'No Classroom',
        'designation': result.designation ?? 'Staff',
        'pin': currentPin,
      },
    );
  }

  void _routeGuardianStudentAttendance(
    BuildContext context,
    KioskPinResultEntity result,
    String currentPin,
  ) {
    final signedIn = result.signedInStudents;
    final signedOut = result.signedOutStudents;
    final guardianCode = result.guardianCode ?? '';

    AppLogger.d(
      '[Kiosk] _routeGuardianStudentAttendance: guardianCode=$guardianCode, '
      'signedInStudents=${signedIn.length}, signedOutStudents=${signedOut.length}',
    );

    if (guardianCode.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Guardian code not found',
        isError: true,
      );
      return;
    }

    if (result.students.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'No students found',
        isError: true,
      );
      return;
    }

    // Determine which action to show based on student sign-in/out states
    String action = 'selection'; // Default: show selection screen
    if (signedIn.isNotEmpty && signedOut.isEmpty) {
      // Only signed-in students: can only sign out
      action = 'sign-out';
    } else if (signedOut.isNotEmpty && signedIn.isEmpty) {
      // Only signed-out students: can only sign in
      action = 'sign-in';
    }
    // else: Both signed-in and signed-out: show selection screen (action='selection')

    AppLogger.d(
      '[KIOSK] Persona=GUARDIAN, routing to unified page with action=$action',
    );

    // NEW: Navigate to unified kiosk page (stays within /kiosk context)
    GoRouter.of(context).go(
      '/kiosk/student-sign-in-and-sign-out',
      extra: {
        'isKiosk': true,
        'guardianCode': guardianCode,
        'pin': currentPin,
        'action': action,
        'signedInCodes': signedIn.map((s) => s.studentCode).toList(),
        'signedOutCodes': signedOut.map((s) => s.studentCode).toList(),
      },
    );
  }
}
