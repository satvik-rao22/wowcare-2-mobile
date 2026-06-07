import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/domain/features/kiosk/entities/kiosk_pin_result_entity.dart';
import 'package:wowcare/presentation/features/kiosk/cubit/kiosk_dashboard_cubit.dart';
import 'package:wowcare/presentation/features/kiosk/utils/kiosk_access_control.dart';

/// Kiosk dashboard screen - full-screen tablet UI for school entrance kiosk.
/// Displays live QR code and PIN entry pad for attendance marking.
class KioskDashboardScreen extends StatefulWidget {
  const KioskDashboardScreen({super.key});

  static const String routeName = '/kiosk';

  @override
  State<KioskDashboardScreen> createState() => _KioskDashboardScreenState();
}

class _KioskDashboardScreenState extends State<KioskDashboardScreen> {
  String pin = '';
  final int maxPinLength = 4;

  @override
  void initState() {
    super.initState();
    // Trigger QR code load from the cubit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(context.read<KioskDashboardCubit>().loadQrCode());
    });
  }

  void addDigit(String digit) {
    if (pin.length < maxPinLength) {
      setState(() {
        pin += digit;
      });
    }
  }

  void removeDigit() {
    if (pin.isNotEmpty) {
      setState(() {
        pin = pin.substring(0, pin.length - 1);
      });
    }
  }

  bool isIpad() {
    return Platform.isIOS && (MediaQuery.of(context).size.shortestSide >= 600);
  }

  bool isAndroid() {
    return Platform.isAndroid;
  }

  void _validateKioskPin() {
    if (pin.length != maxPinLength) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Please enter a ${maxPinLength}-digit PIN',
        isError: true,
      );
      return;
    }

    // Call cubit to submit PIN via API
    unawaited(context.read<KioskDashboardCubit>().submitPin(pin));
  }

  void _resetPin() {
    setState(() {
      pin = '';
    });
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
          _resetPin();
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
                      // Deactivate kiosk mode before navigating
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
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
        child: isTablet
            ? _buildTabletLayoutAlwaysVisible(state)
            : _buildPhoneLayoutAlwaysVisible(state),
      ),
    );
  }

  // Phone layout — QR on top (with loading/error), PIN pad always visible below
  Widget _buildPhoneLayoutAlwaysVisible(KioskDashboardState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // QR Section (top)
        _buildQrSection(state),
        const SizedBox(height: 30),

        // PIN Entry Section (always visible)
        const Text(
          'Enter your Sign-In/out PIN',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 20),
        _buildPinDots(),
        const SizedBox(height: 30),
        _buildKeypad(),
        const SizedBox(height: 30),
        _buildActionButtons(state),
      ],
    );
  }

  // Tablet layout — QR on left, PIN pad on right, always visible
  Widget _buildTabletLayoutAlwaysVisible(KioskDashboardState state) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left side — QR Code section
        Expanded(flex: 1, child: _buildQrSection(state)),

        // Right side — PIN entry (always visible)
        Expanded(
          flex: 1,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Enter your Sign-In/out PIN',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              _buildPinDots(),
              const SizedBox(height: 30),
              _buildKeypad(),
              const SizedBox(height: 30),
              _buildActionButtons(state),
            ],
          ),
        ),
      ],
    );
  }

  // QR Section — shows loading/error states, or QR when loaded
  Widget _buildQrSection(KioskDashboardState state) {
    if (state is KioskDashboardLoading) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text('Loading QR Code...', style: TextStyle(fontSize: 16)),
          const SizedBox(height: 40),
        ],
      );
    }

    if (state is KioskDashboardError) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            height: 250,
            width: 250,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(12),
            child: _buildQrUnavailable('QR not generated'),
          ),
          const SizedBox(height: 20),
          Text(
            state.message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 40),
        ],
      );
    }

    if (state is KioskDashboardQrLoaded) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            state.schoolName,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'Scan the QR Code',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 20),
          Container(
            height: 250,
            width: 250,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(12),
            child: _buildQrImage(state.qrCode.qrPayload),
          ),
        ],
      );
    }

    // PinValidating state: Keep QR visible while validating PIN
    if (state is KioskDashboardPinValidating) {
      if (state.qrCode != null && state.schoolName != null) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              state.schoolName!,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Scan the QR Code',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            Container(
              height: 250,
              width: 250,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              child: _buildQrImage(state.qrCode!.qrPayload),
            ),
          ],
        );
      }
      return const SizedBox.shrink();
    }

    return const SizedBox.shrink();
  }

  Widget _buildQrImage(String qrPayload) {
    try {
      // Validate payload is not empty
      if (qrPayload.trim().isEmpty) {
        AppLogger.d('[Kiosk] QR payload is empty');
        return _buildQrUnavailable('QR Code data is empty');
      }

      AppLogger.d(
        '[Kiosk] Rendering QR code from payload: ${qrPayload.length} chars',
      );

      // Use qr_flutter to generate QR code from the payload string
      return QrImageView(
        data: qrPayload,
        version: QrVersions.auto,
        size: 220,
        gapless: false,
        errorCorrectionLevel: QrErrorCorrectLevel.H,
        errorStateBuilder: (context, error) {
          AppLogger.d('[Kiosk] QR generation failed: $error');
          return _buildQrUnavailable('Failed to generate QR');
        },
      );
    } catch (e) {
      AppLogger.d('[Kiosk] Unexpected QR error: $e');
      return _buildQrUnavailable('Failed to load QR code');
    }
  }

  Widget _buildQrUnavailable(String reason) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            reason,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          IconButton(
            onPressed: () {
              // ignore: unawaited_futures
              context.read<KioskDashboardCubit>().loadQrCode();
            },
            icon: const Icon(Icons.refresh, size: 32, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPinDots() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 10,
      children: List.generate(
        maxPinLength,
        (index) => Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index < pin.length ? Colors.blue[400] : Colors.grey[300],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildKeypadButton('1'),
              _buildKeypadButton('2'),
              _buildKeypadButton('3'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildKeypadButton('4'),
              _buildKeypadButton('5'),
              _buildKeypadButton('6'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildKeypadButton('7'),
              _buildKeypadButton('8'),
              _buildKeypadButton('9'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 90),
              _buildKeypadButton('0'),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 70,
                height: 50,
                child: ElevatedButton(
                  onPressed: removeDigit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Icon(Icons.backspace_outlined, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(String number) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      width: 70,
      height: 50,
      child: ElevatedButton(
        onPressed: () => addDigit(number),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[200],
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: Center(
          child: Text(
            number,
            style: const TextStyle(fontSize: 20),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(KioskDashboardState state) {
    final isValidating = state is KioskDashboardPinValidating;

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: AppColors.buildSecondaryGradient(),
            ),
            padding: const EdgeInsets.all(1),
            child: TextButton(
              onPressed: isValidating ? null : () {
                _resetPin();
                CoreUtils.showTopSnackBar(
                  context: context,
                  message: 'PIN entry cancelled',
                  isWarning: true,
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: ShaderMask(
                shaderCallback: (Rect bounds) =>
                    AppColors.buildSecondaryGradient().createShader(bounds),
                blendMode: BlendMode.srcIn,
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 16 * (-3 / 100),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: AppColors.buildSecondaryGradient(),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: isValidating ? null : () {
                _validateKioskPin();
              },
              child: isValidating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Next',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 16 * (-3 / 100),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  void _handlePinSuccess(BuildContext context, KioskPinResultEntity result) {
    final currentPin = pin; // Save pin before reset

    AppLogger.d(
      '[Kiosk] PIN verification success: persona=${result.persona}, '
      'isStaff=${result.isStaff}, isGuardian=${result.isGuardian}, pin=$currentPin (length=${currentPin.length})',
    );

    if (result.isStaff) {
      AppLogger.d('[Kiosk] Routing to staff attendance flow');
      _routeStaffAttendance(context, result, currentPin);
    } else if (result.isGuardian) {
      AppLogger.d('[Kiosk] Routing to guardian/student attendance flow');
      _routeGuardianStudentAttendance(context, result, currentPin);
    }

    _resetPin();
  }

  void _routeStaffAttendance(
    BuildContext context,
    KioskPinResultEntity result,
    String currentPin,
  ) {
    final staffCode = result.staffCode ?? '';

    AppLogger.d('[KIOSK] Persona=STAFF, StaffCode=$staffCode');

    if (staffCode.isEmpty) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Staff code not found',
        isError: true,
      );
      return;
    }

    AppLogger.d(
      '[KIOSK] Persona=STAFF, StaffCode=$staffCode, StaffName=${result.staffName}, Routing to /dashboard/staff-sign-in-form, PinIncluded=${currentPin.isNotEmpty}',
    );

    GoRouter.of(context).go(
      '/dashboard/staff-sign-in-form',
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
    final guardianName = result.guardianName ?? 'Guardian';

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

    // Route based on sign-in/out status
    if (signedIn.isNotEmpty && signedOut.isNotEmpty) {
      // Mixed status — show sign-in/out selection
      AppLogger.d(
        '[KIOSK] Persona=GUARDIAN, NavigatingTo=/kiosk/student-sign-in-out, guardianCode=$guardianCode, pin=${currentPin.isNotEmpty}',
      );
      GoRouter.of(context).go(
        '/kiosk/staff-sign-out-form',
        extra: {
          'isKiosk': true,
          'guardianCode': guardianCode,
          'guardianName': guardianName,
          'signedInStudents': signedIn
              .map(
                (s) => {
                  'studentCode': s.studentCode,
                  'fullName': s.fullName,
                  'classroomCode': s.classroomCode,
                  'classroomName': s.classroomName,
                  'status': s.status,
                },
              )
              .toList(),
          'signedOutStudents': signedOut
              .map(
                (s) => {
                  'studentCode': s.studentCode,
                  'fullName': s.fullName,
                  'classroomCode': s.classroomCode,
                  'classroomName': s.classroomName,
                  'status': s.status,
                },
              )
              .toList(),
          'pin': currentPin,
        },
      );
    } else if (signedOut.isNotEmpty) {
      // Only signed-out students — go to sign-in
      AppLogger.d(
        '[Kiosk] CallingStudentSignInApi=true, route=/kiosk/student-sign-in, currentPin=$currentPin (length=${currentPin.length})',
      );
      GoRouter.of(context).go(
        '/kiosk/student-sign-in',
        extra: {
          'isKiosk': true,
          'guardianCode': guardianCode,
          'guardianName': guardianName,
          'students': signedOut
              .map(
                (s) => {
                  'studentCode': s.studentCode,
                  'fullName': s.fullName,
                  'classroomCode': s.classroomCode,
                  'classroomName': s.classroomName,
                },
              )
              .toList(),
          'pin': currentPin,
        },
      );
    } else if (signedIn.isNotEmpty) {
      // Only signed-in students — go to sign-out
      AppLogger.d(
        '[Kiosk] CallingStudentSignOutApi=true, route=/kiosk/student-sign-out',
      );
      GoRouter.of(context).go(
        '/kiosk/student-sign-out',
        extra: {
          'isKiosk': true,
          'guardianCode': guardianCode,
          'guardianName': guardianName,
          'students': signedIn
              .map(
                (s) => {
                  'studentCode': s.studentCode,
                  'fullName': s.fullName,
                  'classroomCode': s.classroomCode,
                  'classroomName': s.classroomName,
                },
              )
              .toList(),
          'pin': currentPin,
        },
      );
    }
  }
}
