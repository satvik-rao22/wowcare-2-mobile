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

class _KioskDashboardScreenState extends State<KioskDashboardScreen>
    with WidgetsBindingObserver {
  final int maxPinLength = 4;
  String _currentPin = '';
  String _cachedSchoolName =
      'School'; // Cache to preserve school name during QR reload
  bool _isRefreshingQr = false; // Prevent duplicate refresh calls

  @override
  void initState() {
    super.initState();
    AppLogger.d('[KIOSK] Dashboard opened');
    // Add observer for app lifecycle
    WidgetsBinding.instance.addObserver(this);

    // Initial QR load on screen open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLogger.d('[KIOSK] Dashboard refresh requested (initState)');
      _loadQrCode();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh QR when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      AppLogger.d('[KIOSK] Dashboard resumed');
      _loadQrCode();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload QR whenever screen is re-entered (e.g., after PIN flow)
    AppLogger.d('[KIOSK] Dashboard resumed (didChangeDependencies)');
    // Use a small delay to avoid multiple rapid calls
    if (!_isRefreshingQr) {
      _isRefreshingQr = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppLogger.d('[KIOSK] Refreshing school info');
        _loadQrCode();
        _isRefreshingQr = false;
      });
    }
  }

  void _loadQrCode() {
    AppLogger.d('[KIOSK] Refreshing QR');
    unawaited(context.read<KioskDashboardCubit>().loadQrCode());
  }

  /// Refresh dashboard data (school info, QR, kiosk settings)
  Future<void> _refreshDashboard() async {
    AppLogger.d('[KIOSK] Refresh requested (pull-to-refresh)');
    await context.read<KioskDashboardCubit>().loadQrCode();
  }

  @override
  void dispose() {
    // Remove observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool isIpad() {
    return Platform.isIOS && (MediaQuery.of(context).size.shortestSide >= 600);
  }

  void _onPinSubmit(String pin) {
    AppLogger.d('[Kiosk] PIN submitted: length=${pin.length}');
    _currentPin = pin;
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
          child: Column(
            children: [
              Container(
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
                          'WowCare',
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      // IconButton(
                      //   icon: const Icon(
                      //     Icons.exit_to_app,
                      //     color: AppColors.primaryColor,
                      //   ),
                      //   onPressed: () async {
                      //     AppLogger.d('[Kiosk] Logout button pressed');
                      //     await serviceLocator<KioskAccessControl>()
                      //         .deactivateKioskMode();
                      //     if (mounted) {
                      //       GoRouter.of(context).go('/sign-in');
                      //     }
                      //   },
                      // ),
                    ],
                  ),
                ),
              ),
              Divider(height: 1, color: AppColors.themeColor),
            ],
          ),
        ),

        bottomSheet: Container(color: AppColors.themeColor, height: 1),
        body: RefreshIndicator(
          onRefresh: _refreshDashboard,
          child: BlocBuilder<KioskDashboardCubit, KioskDashboardState>(
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
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        KioskQrSectionWidget(state: state, schoolName: _getSchoolName(state)),
        const SizedBox(height: 8),
        KioskPinPadWidget(
          onPinSubmit: _onPinSubmit,
          maxPinLength: maxPinLength,
        ),
      ],
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
    // Always return school name, even during loading/error states
    // Cache the actual school name to preserve it during QR reloads

    if (state is KioskDashboardQrLoaded) {
      _cachedSchoolName = state.schoolName;
      AppLogger.d('[Kiosk] Cached school name: ${state.schoolName}');
      return state.schoolName;
    }

    if (state is KioskDashboardPinValidating && state.schoolName != null) {
      _cachedSchoolName = state.schoolName!;
      return state.schoolName!;
    }

    // During loading/error, use cached school name (NOT generic 'School')
    if (state is KioskDashboardLoading) {
      AppLogger.d(
        '[Kiosk] Loading state - using cached school name: $_cachedSchoolName',
      );
      return _cachedSchoolName; // Return CACHED value, not 'School'
    }

    if (state is KioskDashboardError) {
      AppLogger.d(
        '[Kiosk] Error state - using cached school name: $_cachedSchoolName',
      );
      return _cachedSchoolName; // Return CACHED value, not 'School'
    }

    return _cachedSchoolName;
  }

  void _handlePinSuccess(BuildContext context, KioskPinResultEntity result) {
    AppLogger.d(
      '[Kiosk] PIN verification success: persona=${result.persona.name}, '
      'isStaff=${result.isStaff}, isGuardian=${result.isGuardian}',
    );

    // KIOSK persona: session is invalid/expired, immediately logout and redirect
    if (result.persona == KioskPersona.kiosk) {
      AppLogger.w(
        '[Kiosk] KIOSK persona detected - clearing session and redirecting to sign-in',
      );
      unawaited(_handleKioskPersona(context));
      return;
    }

    // STAFF persona: route to staff attendance flow
    if (result.isStaff) {
      AppLogger.d('[Kiosk] Routing to staff attendance flow');
      _routeStaffAttendance(context, result, _currentPin);
      return;
    }

    // GUARDIAN persona: route to guardian/student attendance flow
    if (result.isGuardian) {
      AppLogger.d('[Kiosk] Routing to guardian/student attendance flow');
      _routeGuardianStudentAttendance(context, result, _currentPin);
      return;
    }

    // UNKNOWN persona: should not occur, but log and do nothing
    AppLogger.e('[Kiosk] Unknown persona detected: ${result.persona.name}');
    CoreUtils.showTopSnackBar(
      context: context,
      message: 'Invalid PIN response. Please try again.',
      isError: true,
    );
  }

  void _routeStaffAttendance(
    BuildContext context,
    KioskPinResultEntity result,
    String currentPin,
  ) {
    final staffCode = result.staffCode ?? '';
    final status = (result.staffStatus ?? 'SIGNED_OUT').toUpperCase();

    AppLogger.d('[KIOSK] Attendance action completed (Staff)');
    AppLogger.d('[KIOSK] Triggering dashboard refresh');

    if (staffCode.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Staff code not found',
        isError: true,
      );
      return;
    }

    final route = status == 'SIGNED_IN'
        ? '/kiosk/staff-sign-out'
        : '/kiosk/staff-sign-in';

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
    final guardianCode = result.guardianCode ?? '';

    // Validation
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

    // Count signed in and signed out for all students (including expected=false)
    int signedInCount = 0;
    int signedOutCount = 0;
    final signedInStudents = <String>[];
    final signedOutStudents = <String>[];

    for (final student in result.students) {
      final isSignedIn = student.status.toUpperCase() == 'SIGNED_IN';

      if (isSignedIn) {
        signedInCount++;
        signedInStudents.add(student.studentCode);
      } else {
        signedOutCount++;
        signedOutStudents.add(student.studentCode);
      }
    }

    AppLogger.d(
      '[KIOSK] Student Status Count: signedIn=$signedInCount, signedOut=$signedOutCount',
    );
    AppLogger.d('[KIOSK] Signed In Students: $signedInStudents');
    AppLogger.d('[KIOSK] Signed Out Students: $signedOutStudents');

    // DECISION 1: ALL STUDENTS ARE SIGNED IN
    if (signedInCount > 0 && signedOutCount == 0) {
      AppLogger.d(
        '[KIOSK] ✓ ALL STUDENTS SIGNED IN - NAVIGATE TO SIGN-OUT PAGE',
      );
      context.go(
        '/kiosk/student-sign-out',
        extra: {
          'isKiosk': true,
          'students': signedInStudents
              .map((code) => {'studentCode': code})
              .toList(),
          'guardianCode': guardianCode,
          'pin': currentPin,
        },
      );
      return;
    }

    // DECISION 2: ALL STUDENTS ARE SIGNED OUT
    if (signedOutCount > 0 && signedInCount == 0) {
      AppLogger.d(
        '[KIOSK] ✓ ALL STUDENTS SIGNED OUT - NAVIGATE TO SIGN-IN PAGE',
      );
      context.go(
        '/kiosk/student-sign-in-and-sign-out',
        extra: {
          'isKiosk': true,
          'guardianCode': guardianCode,
          'pin': currentPin,
          'action': 'sign-in',
          'signedInCodes': [],
          'signedOutCodes': signedOutStudents,
        },
      );
      return;
    }

    // DECISION 3: MIXED STATUS
    AppLogger.d('[KIOSK] ✓ MIXED STATUS - NAVIGATE TO SELECTION PAGE');
    context.go(
      '/kiosk/student-sign-in-and-sign-out',
      extra: {
        'isKiosk': true,
        'guardianCode': guardianCode,
        'pin': currentPin,
        'action': 'selection',
        'signedInCodes': signedInStudents,
        'signedOutCodes': signedOutStudents,
      },
    );
  }

  /// Handle KIOSK persona: immediately logout and redirect to sign-in
  Future<void> _handleKioskPersona(BuildContext context) async {
    try {
      AppLogger.d('[Kiosk] Clearing kiosk session for KIOSK persona');
      await serviceLocator<KioskAccessControl>().deactivateKioskMode();
    } catch (e) {
      AppLogger.w('[Kiosk] Error deactivating kiosk mode: $e');
    }

    if (mounted) {
      AppLogger.d('[Kiosk] Redirecting to /sign-in after KIOSK persona');
      GoRouter.of(context).go('/sign-in');
    }
  }
}
