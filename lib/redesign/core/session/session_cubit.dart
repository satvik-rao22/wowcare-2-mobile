import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/redesign/core/session/persona.dart';

part 'session_state.dart';

/// Who is signed in, where, and as whom.
///
/// The one piece of app-wide state every screen reads: the router's redirect
/// gates on [SessionStatus], the tab bar picks its five slots off [Persona],
/// and the More page hides what the persona cannot open.
///
/// Signing in is M01's job and switching persona is M13's; this cubit only
/// holds the result. Data reaches it through [SessionSource], which during the
/// UI phase returns fixtures and in the last phase wraps the real auth and role
/// layers. It never touches `serviceLocator`.
class SessionCubit extends Cubit<SessionState> {
  SessionCubit({required SessionSource source})
    : _source = source,
      super(const SessionState());

  final SessionSource _source;

  /// Restore whatever the last session left behind.
  Future<void> restore() async {
    final restored = await _source.restore();
    if (isClosed) return;
    emit(restored ?? const SessionState());
  }

  /// A successful sign in. The persona is whichever role the account
  /// holds first; [switchPersona] moves between the rest.
  void signedIn(SessionUser user) {
    emit(
      SessionState(
        status: SessionStatus.signedIn,
        user: user,
        persona: user.personas.first,
      ),
    );
  }

  /// A school or organization change re-scopes the same user.
  void changeScope({String? organizationName, String? schoolName}) {
    final user = state.user;
    if (user == null) return;
    emit(
      state.copyWith(
        user: user.copyWith(
          organizationName: organizationName,
          schoolName: schoolName,
        ),
      ),
    );
  }

  /// Flip between the roles this account holds at this school. Guarded so a
  /// persona the account does not have can never be selected.
  void switchPersona(Persona persona) {
    final user = state.user;
    if (user == null || !user.personas.contains(persona)) return;
    emit(state.copyWith(persona: persona));
  }

  /// The kiosk is a lockdown: no tab bar, no back, until an admin leaves it.
  void enterKiosk() => emit(state.copyWith(status: SessionStatus.kiosk));

  void leaveKiosk() => emit(state.copyWith(status: SessionStatus.signedIn));

  /// Leaving the app. Never called Sign Out, which is a student's day ending.
  Future<void> logout() async {
    await _source.clear();
    if (!isClosed) emit(const SessionState());
  }
}

/// Where the session comes from. Fixtures now, the real auth layer last.
abstract interface class SessionSource {
  Future<SessionState?> restore();
  Future<void> clear();
}
