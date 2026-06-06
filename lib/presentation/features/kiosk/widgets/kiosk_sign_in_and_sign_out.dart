import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_selection_sign_in_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_selection_sign_out_form.dart';

import '../../../../app/theme/colors.dart';

/// Unified kiosk page for guardian student sign-in/sign-out flows.
///
/// Consolidates multiple student attendance screens into a single kiosk page that:
/// 1. Shows selection screen if students have mixed sign-in/sign-out states
/// 2. Shows sign-in form if all students are signed out
/// 3. Shows sign-out form if all students are signed in
/// 4. Handles sibling selection and multi-student submission
/// 5. Returns to kiosk dashboard after successful completion
///
/// Reuses existing StudentSignInForm, StudentSignOutForm, and selection logic
/// without navigating outside the kiosk context (/kiosk/...).
class KioskStudentSignInAndSignOutPage extends StatefulWidget {
  /// Route name (used with /kiosk prefix: /kiosk/student-sign-in-and-sign-out)
  static const String routeName = 'student-sign-in-and-sign-out';
  static const String fullPath = '/kiosk/$routeName';

  const KioskStudentSignInAndSignOutPage({
    required this.signedInCodes,
    required this.signedOutCodes,
    required this.guardianCode,
    required this.pin,
    this.action = 'selection',
    super.key,
  });

  /// List of student codes already signed in
  final List<String> signedInCodes;

  /// List of student codes not yet signed in (signed out)
  final List<String> signedOutCodes;

  /// Guardian code from PIN verification
  final String guardianCode;

  /// PIN from kiosk entry
  final String pin;

  /// Initial action: 'selection', 'sign-in', or 'sign-out'
  /// Determines which screen to show first based on student states
  final String action;

  @override
  State<KioskStudentSignInAndSignOutPage> createState() =>
      _KioskStudentSignInAndSignOutPageState();
}

class _KioskStudentSignInAndSignOutPageState
    extends State<KioskStudentSignInAndSignOutPage> {
  late String _currentAction;

  @override
  void initState() {
    super.initState();
    _currentAction = widget.action;
    AppLogger.d(
      '[Kiosk] KioskStudentSignInAndSignOut.initState: '
      'action=$_currentAction, signedIn=${widget.signedInCodes.length}, '
      'signedOut=${widget.signedOutCodes.length}',
    );
  }

  /// Handle back navigation - always return to kiosk dashboard
  void _onPopInvokedWithResult(bool didPop, dynamic result) {
    if (didPop) return;
    AppLogger.d('[Kiosk] Back button pressed, returning to kiosk dashboard');
    context.go('/kiosk');
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: _onPopInvokedWithResult,
      canPop: false,
      child: _buildScreen(),
    );
  }

  /// Build the appropriate screen based on current action
  Widget _buildScreen() {
    AppLogger.d('[Kiosk] Building screen: action=$_currentAction');

    switch (_currentAction) {
      case 'sign-in':
        return _buildSignInScreen();
      case 'sign-out':
        return _buildSignOutScreen();
      case 'selection':
      default:
        return _buildSelectionScreen();
    }
  }

  /// Selection screen: Show when students have mixed sign-in/sign-out states
  /// Allows guardian to choose whether to sign in or sign out
  Widget _buildSelectionScreen() {
    return StaffFormLayout(
      title: 'Sign In / Sign Out',
      isKiosk: true,
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
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  AppLogger.d('[Kiosk] Sign In button tapped');
                  setState(() {
                    _currentAction = 'sign-in';
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppColors.primaryGradientColors,
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  AppLogger.d('[Kiosk] Sign Out button tapped');
                  setState(() {
                    _currentAction = 'sign-out';
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppColors.primaryGradientColors,
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'Sign Out',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sign-in screen: Show when all eligible students are signed out
  /// Routes to selection screen to allow selecting which students to sign in
  Widget _buildSignInScreen() {
    return StudentSelectionSignInForm(
      allowedStudentCodes: widget.signedOutCodes,
      isKiosk: true,
      guardianCode: widget.guardianCode,
      pin: widget.pin,
    );
  }

  /// Sign-out screen: Show when all eligible students are signed in
  /// Routes to selection screen to allow selecting which students to sign out
  Widget _buildSignOutScreen() {
    return StudentSelectionSignOutForm(
      allowedStudentCodes: widget.signedInCodes,
      isKiosk: true,
      guardianCode: widget.guardianCode,
      pin: widget.pin,
    );
  }
}
