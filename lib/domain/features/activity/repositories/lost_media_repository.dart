import 'package:wowcare/domain/features/activity/entities/recovered_media.dart';

/// Claims camera captures that were completed but never delivered, because the
/// OS destroyed the host activity while the camera app was in the foreground.
///
/// Exists so the presentation layer never touches the picker plugin directly
/// (Mandate 5): the platform call lives in the data layer behind this contract.
abstract class LostMediaRepository {
  /// Claims and CLEARS any pending capture.
  ///
  /// Destructive by nature — the platform hands each cached result back exactly
  /// once, so two callers racing this would see one of them get
  /// [RecoveredMedia.none]. Call it from a single place per screen.
  ///
  /// Returns [RecoveredMedia.none] when there is nothing pending, which is the
  /// normal outcome on every run and the only outcome on iOS. Never throws:
  /// a platform failure is reported through
  /// [RecoveredMedia.errorMessage] so that recovery — a best-effort
  /// nicety — can never itself break the screen that asked for it.
  Future<RecoveredMedia> retrieveLostMedia();
}
