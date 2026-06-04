import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/core/util/core_utils.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/presentation/features/kiosk/cubit/kiosk_attendance_cubit_v2.dart';

/// REFACTORED Kiosk Staff Sign-In Screen using Pure Bloc Architecture.
///
/// Architecture:
/// - Pure BlocListener/BlocBuilder (no Provider package)
/// - Receives cubit from parent via context.read (from BlocProvider)
/// - Reacts to state changes immutably
/// - No manual state management
/// - No repeated API calls
///
/// Does NOT:
/// - Use Provider package
/// - Create duplicate Cubits
/// - Manage Cubit lifecycle
/// - Call context.watch from Provider
///
/// Uses:
/// - BlocListener for side effects (navigation, snackbars)
/// - BlocBuilder for UI rendering (optional, for loading states)
/// - context.read<Cubit>() to trigger actions (SAFE when Cubit is provided by parent)
class KioskStaffSignScreenV2 extends StatefulWidget {
  const KioskStaffSignScreenV2({super.key});

  @override
  State<KioskStaffSignScreenV2> createState() => _KioskStaffSignScreenV2State();
}

class _KioskStaffSignScreenV2State extends State<KioskStaffSignScreenV2> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final state = GoRouterState.of(context);
    final extras = state.extra as Map<String, dynamic>? ?? {};

    final staffCode = extras['staffCode'] as String? ?? '';
    final staffName = extras['staffName'] as String? ?? 'Unknown Staff';
    final classroomName = extras['classroomName'] as String? ?? 'No Classroom';
    final currentStatus = extras['staffStatus'] as String? ?? 'SIGNED_OUT';
    final designation = extras['designation'] as String? ?? 'Staff';

    // Debug: Log entry to staff sign screen
    AppLogger.d(
      '[Kiosk] KioskStaffSignScreenV2 built: staffCode=$staffCode, '
      'route=/kiosk/staff-sign, CubitAccessible=checking',
    );

    // Verify cubit is accessible in context
    try {
      // ignore: unused_local_variable
      final _ = context.read<KioskAttendanceCubitV2>();
      AppLogger.d('[Kiosk] KioskAttendanceCubitV2 accessible: CubitAccessible=true');
    } catch (e) {
      AppLogger.e('[Kiosk] KioskAttendanceCubitV2 NOT accessible: Error=$e');
    }

    if (staffCode.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sign In/Out')),
        body: const Center(child: Text('No staff data provided')),
      );
    }

    final isSignedIn = currentStatus.toUpperCase() == 'SIGNED_IN';
    final actionText = isSignedIn ? 'Sign Out' : 'Sign In';
    final actionSubtext = isSignedIn
        ? 'Mark yourself as signed out'
        : 'Mark yourself as signed in';

    // Use BlocBuilder with builder to get a new BuildContext that has access to the BlocProvider
    // This solves the ProviderNotFoundException issue with GoRouter nested routes
    return BlocBuilder<KioskAttendanceCubitV2, KioskAttendanceStateV2>(
      builder: (newContext, state) {
        AppLogger.d(
          '[Kiosk] BlocBuilder state: ${state.runtimeType}',
        );

        // Handle state changes
        if (state is KioskAttendanceSuccessV2) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleSuccess(newContext, state);
          });
        } else if (state is KioskAttendanceErrorV2) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleError(newContext, state);
          });
        }

        return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primaryColor),
            onPressed: _isSubmitting
                ? null
                : () {
                    context.read<KioskAttendanceCubitV2>().reset();
                    GoRouter.of(context).go('/kiosk');
                  },
          ),
          title: const Text(
            'Staff Sign In/Out',
            style: TextStyle(
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Divider(height: 1, thickness: 1, color: AppColors.themeColor),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: AppColors.buildScaffoldGradient(),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Staff card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Staff Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildInfoRow('Name', staffName),
                        const SizedBox(height: 16),
                        _buildInfoRow('Staff Code', staffCode),
                        const SizedBox(height: 16),
                        _buildInfoRow('Designation', designation),
                        const SizedBox(height: 16),
                        _buildInfoRow('Classroom', classroomName),
                        const SizedBox(height: 16),
                        _buildStatusRow(
                          'Current Status',
                          isSignedIn ? 'SIGNED IN' : 'SIGNED OUT',
                          isSignedIn,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Action section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        actionText,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        actionSubtext,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Action buttons
                  Row(
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
                            onPressed: _isSubmitting
                                ? null
                                : () {
                                    context.read<KioskAttendanceCubitV2>().reset();
                                    GoRouter.of(context).go('/kiosk');
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
                                  AppColors.buildSecondaryGradient()
                                      .createShader(bounds),
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
                            onPressed: _isSubmitting
                                ? null
                                : () => _handleSignConfirmation(
                                      context,
                                      staffCode,
                                      isSignedIn,
                                    ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    actionText,
                                    style: const TextStyle(
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
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      },
    );
  }

  void _handleSignConfirmation(
    BuildContext context,
    String staffCode,
    bool isCurrentlySignedIn,
  ) async {
    setState(() => _isSubmitting = true);

    try {
      AppLogger.d(
        '[Kiosk] Sign confirmation triggered: staffCode=$staffCode, '
        'action=${isCurrentlySignedIn ? 'SIGN_OUT' : 'SIGN_IN'}',
      );

      // Get cubit from context (provided by parent BlocProvider)
      final cubit = context.read<KioskAttendanceCubitV2>();

      if (isCurrentlySignedIn) {
        await cubit.signOutStaff(staffCode: staffCode);
      } else {
        await cubit.signInStaff(staffCode: staffCode);
      }

      // BlocListener will handle the result
    } catch (e) {
      if (!mounted) return;

      AppLogger.e('[Kiosk] Sign confirmation error: $e');
      CoreUtils.showTopSnackBar(
        context: context,
        message: 'Error: $e',
        isError: true,
      );

      setState(() => _isSubmitting = false);
    }
  }

  void _handleSuccess(
    BuildContext context,
    KioskAttendanceSuccessV2 state,
  ) {
    AppLogger.d(
      '[Kiosk] Success: action=${state.action}, status=${state.status}',
    );

    CoreUtils.showTopSnackBar(
      context: context,
      message: state.message,
      isSuccess: true,
    );

    // Navigate back after delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        context.read<KioskAttendanceCubitV2>().reset();
        GoRouter.of(context).go('/kiosk');
      }
    });

    setState(() => _isSubmitting = false);
  }

  void _handleError(
    BuildContext context,
    KioskAttendanceErrorV2 state,
  ) {
    AppLogger.e('[Kiosk] Error: ${state.message}');

    CoreUtils.showTopSnackBar(
      context: context,
      message: state.message,
      isError: true,
    );

    setState(() => _isSubmitting = false);
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(String label, String status, bool isSignedIn) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSignedIn
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSignedIn ? Colors.green : Colors.orange,
            ),
          ),
        ),
      ],
    );
  }
}
