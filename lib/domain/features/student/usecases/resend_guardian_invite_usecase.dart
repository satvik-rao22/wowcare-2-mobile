import 'package:wowcare/core/observability/app_events.dart';

import '../repositories/student_repository.dart';

/// Re-sends the app invitation email to a single guardian.
class ResendGuardianInviteUseCase {
  ResendGuardianInviteUseCase(this._repository);

  final StudentRepository _repository;

  /// Returns the server's message so the caller can surface it verbatim.
  Future<String> call({
    required String invitedEmail,
    required String userCode,
    required String organizationCode,
    required String schoolCode,
  }) {
    return AppEvents.track(
      AppEvent.guardianInviteResend,
      () => _repository.resendGuardianInvite(
        invitedEmail: invitedEmail,
        userCode: userCode,
        organizationCode: organizationCode,
        schoolCode: schoolCode,
      ),
    );
  }
}
