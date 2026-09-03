import 'package:wowcare/redesign/core/session/session_cubit.dart';

/// The fixture session: nothing is remembered between launches, so every run
/// starts at Sign In, which is the flow the reviewer is here to see.
class PreviewSessionSource implements SessionSource {
  const PreviewSessionSource();

  @override
  Future<SessionState?> restore() async => null;

  @override
  Future<void> clear() async {}
}
