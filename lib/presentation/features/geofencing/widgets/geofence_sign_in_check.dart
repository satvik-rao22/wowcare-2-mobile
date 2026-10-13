import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/constants/app_strings.dart';
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/permission_manager.dart';
import 'package:wowcare/presentation/features/geofencing/view_model/geofence_cubit.dart';

/// Runs when the user taps a self sign-in/out button. The button is always
/// enabled; this decides on tap:
///
/// 1. Location permission — asks, or shows Settings steps if it's blocked.
/// 2. Takes a fresh GPS fix and checks the user is inside the school area.
/// 3. Explains in one short message if they can't continue.
///
/// Returns true only when the caller should continue to the sign-in form.
/// [action] fills the messages, e.g. 'sign in', 'sign out'.
Future<bool> confirmAtSchool(
  BuildContext context, {
  required bool forParent,
  String action = 'sign in',
}) async {
  // A second tap while the first check runs would stack dialogs.
  if (_checking) return false;
  _checking = true;
  try {
    final allowed = await PermissionManager.ensure(
      context,
      AppPermission.location,
      reason: 'to check that you are at school',
    );
    if (!allowed || !context.mounted) return false;

    final cubit = context.read<GeofenceCubit>();
    final result = await _whileShowingProgress(
      context,
      cubit.checkAtSchoolNow(forParent: forParent),
    );
    if (!context.mounted) return false;

    final message = atSchoolMessage(result, action);
    if (message != null) {
      CoreUtils.showTopSnackBar(
        context: context,
        message: message,
        isWarning: true,
      );
    }
    return result == AtSchoolCheck.atSchool;
  } finally {
    _checking = false;
  }
}

/// For the "Location permission required. Tap to enable." link: asks for
/// permission (or shows Settings steps), then restarts location checks.
Future<void> enableGeofenceLocation(BuildContext context) async {
  final allowed = await PermissionManager.ensure(
    context,
    AppPermission.location,
    reason: 'to check that you are at school',
  );
  if (allowed && context.mounted) {
    await context.read<GeofenceCubit>().retryPermission();
  }
}

bool _checking = false;

/// The one-line message for [result]; null when the user may continue.
@visibleForTesting
String? atSchoolMessage(AtSchoolCheck result, String action) {
  switch (result) {
    case AtSchoolCheck.atSchool:
      return null;
    case AtSchoolCheck.notAtSchool:
      return 'You are not at school. Move closer to the school to $action.';
    case AtSchoolCheck.gpsOff:
      return 'Your phone\'s Location is off. Turn it on and try again.';
    case AtSchoolCheck.noPermission:
      return 'Allow location access to $action.';
    case AtSchoolCheck.gpsSignInOff:
      return AppStrings.geofenceDisabledByAdmin;
    case AtSchoolCheck.locationUnavailable:
      return 'We couldn\'t find your location. Please try again.';
    case AtSchoolCheck.fakeLocation:
      return 'Your location looks fake. Turn off any fake GPS app and try '
          'again.';
    case AtSchoolCheck.notReady:
      return 'We couldn\'t load the school\'s location. Please try again.';
  }
}

/// Shows a small "Checking your location..." dialog until [task] finishes.
/// Removes exactly its own route, so a sheet opened meanwhile isn't closed.
Future<T> _whileShowingProgress<T>(BuildContext context, Future<T> task) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final route = DialogRoute<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(canPop: false, child: _CheckingDialog()),
  );
  navigator.push(route);
  try {
    return await task;
  } finally {
    if (route.isActive) navigator.removeRoute(route);
  }
}

class _CheckingDialog extends StatelessWidget {
  const _CheckingDialog();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        child: const Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: AppSpacing.md),
              Text(AppStrings.geofenceChecking, style: AppTextStyles.body),
            ],
          ),
        ),
      ),
    );
  }
}
