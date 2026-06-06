import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_sign_in_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_sign_out_form.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/student_sign_in_out_selection_screen.dart';

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

  /// Handle successful sign-in/sign-out completion
  void _handleSuccess(String message) {
    if (!mounted) return;

    AppLogger.d('[Kiosk] Sign-in/out completed: $message');

    CoreUtils.showTopSnackBar(
      context: context,
      message: message.isNotEmpty ? message : 'Attendance recorded successfully',
      isError: false,
    );

    // Return to kiosk dashboard after brief delay to show success message
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        AppLogger.d('[Kiosk] Returning to kiosk dashboard after success');
        context.go('/kiosk');
      }
    });
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
    return StudentSignInOutSelectionScreen(
      signedInCodes: widget.signedInCodes,
      signedOutCodes: widget.signedOutCodes,
      guardianCode: widget.guardianCode,
      pin: widget.pin,
    );
  }

  /// Sign-in screen: Show when all eligible students are signed out
  /// Allows selecting which students to sign in
  Widget _buildSignInScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In Students'),
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: Column(
        children: [
          const Divider(height: 1),
          Expanded(
            child: StudentSignInForm(
              // Pass empty list - form will load students from API based on codes
              students: const [],
              // On success, show message and return to kiosk
              refreshCallback: () => _handleSuccess('Students signed in successfully'),
              popOnSuccess: false,
              isKiosk: true,
              guardianCode: widget.guardianCode,
              pin: widget.pin,
            ),
          ),
        ],
      ),
    );
  }

  /// Sign-out screen: Show when all eligible students are signed in
  /// Allows selecting which students to sign out
  Widget _buildSignOutScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Out Students'),
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: Column(
        children: [
          const Divider(height: 1),
          Expanded(
            child: StudentSignOutForm(
              // Pass empty list - form will load students from API based on codes
              students: const [],
              // On success, show message and return to kiosk
              refreshCallback: () => _handleSuccess('Students signed out successfully'),
              popOnSuccess: false,
              isKiosk: true,
              guardianCode: widget.guardianCode,
              pin: widget.pin,
            ),
          ),
        ],
      ),
    );
  }
}
