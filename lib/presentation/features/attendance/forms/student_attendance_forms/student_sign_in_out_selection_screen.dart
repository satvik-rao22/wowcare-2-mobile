import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/presentation/features/kiosk/utils/kiosk_access_control.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/common/widgets/custom_confirm_button.dart';

class StudentSignInOutSelectionScreen extends StatelessWidget {
  static const String routeName = '/student-sign-in-out-selection';

  const StudentSignInOutSelectionScreen({
    required this.signedInCodes,
    required this.signedOutCodes,
    this.guardianCode,
    this.pin,
    super.key,
  });

  final List<String> signedInCodes;
  final List<String> signedOutCodes;
  final String? guardianCode;
  final String? pin;

  Future<bool> _isKioskMode() async {
    try {
      return await serviceLocator<KioskAccessControl>().isKioskModeActive();
    } catch (e) {
      try {
        return await KioskAccessControl(serviceLocator()).isKioskModeActive();
      } catch (_) {
        return false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isKioskMode(),
      builder: (context, snapshot) {
        final isKiosk = snapshot.data ?? false;
        return StaffFormLayout(
          title: 'Sign In / Sign Out',
          isKiosk: isKiosk,
          bottomBar: const SizedBox.shrink(),
          child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select an action for your children attendance today.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            CustomConfirmButton(
              label: 'Sign In',
              onPressed: () async {
                // Check if we're in kiosk mode
                bool isKiosk = false;
                try {
                  isKiosk = await serviceLocator<KioskAccessControl>().isKioskModeActive();
                } catch (e) {
                  // Fallback: try to create on demand
                  try {
                    isKiosk = await KioskAccessControl(
                      serviceLocator(),
                    ).isKioskModeActive();
                  } catch (e2) {
                    AppLogger.d('[Attendance] Not in kiosk mode, using normal flow');
                  }
                }

                // Route based on mode
                if (isKiosk) {
                  AppLogger.d(
                    '[KIOSK] Routing to kiosk student-sign-in: guardianCode=$guardianCode, pin=${pin?.isNotEmpty ?? false}',
                  );
                  context.go(
                    '/kiosk/student-sign-in',
                    extra: <String, dynamic>{
                      'students': signedOutCodes.map((code) => {'studentCode': code}).toList(),
                      'isKiosk': true,
                      'guardianCode': guardianCode,
                      'pin': pin,
                    },
                  );
                } else {
                  AppLogger.d('[Attendance] Routing to dashboard student-selection-sign-in-form');
                  context.go(
                    '/dashboard/student-selection-sign-in-form',
                    extra: <String, dynamic>{
                      'allowedStudentCodes': signedOutCodes,
                    },
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            CustomConfirmButton(
              label: 'Sign Out',
              onPressed: () async {
                // Check if we're in kiosk mode
                bool isKiosk = false;
                try {
                  isKiosk = await serviceLocator<KioskAccessControl>().isKioskModeActive();
                } catch (e) {
                  // Fallback: try to create on demand
                  try {
                    isKiosk = await KioskAccessControl(
                      serviceLocator(),
                    ).isKioskModeActive();
                  } catch (e2) {
                    AppLogger.d('[Attendance] Not in kiosk mode, using normal flow');
                  }
                }

                // Route based on mode
                if (isKiosk) {
                  AppLogger.d(
                    '[KIOSK] Routing to kiosk student-sign-out: guardianCode=$guardianCode, pin=${pin?.isNotEmpty ?? false}',
                  );
                  context.go(
                    '/kiosk/student-sign-out',
                    extra: <String, dynamic>{
                      'students': signedInCodes.map((code) => {'studentCode': code}).toList(),
                      'isKiosk': true,
                      'guardianCode': guardianCode,
                      'pin': pin,
                    },
                  );
                } else {
                  AppLogger.d('[Attendance] Routing to dashboard student-selection-sign-out-form');
                  context.go(
                    '/dashboard/student-selection-sign-out-form',
                    extra: <String, dynamic>{
                      'allowedStudentCodes': signedInCodes,
                    },
                  );
                }
              },
            ),
          ],
        ),
      ),
        );
      },
    );
  }
}
