import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';

/// Single repository contract for emoji reactions on messages, shared by
/// every messaging surface (Staff, Parent, Admin).
///
/// Implementations persist optimistically to the local cache before the
/// network call, and queue the operation for offline retry on failure.
abstract class ReactionRepository {
  /// Add (or replace) the current user's emoji reaction on a message.
  ///
  /// Offline behaviour: queued; optimistic local update.
  Future<Either<Failure, void>> addReaction({
    required String messageCode,
    required String emoji,
  });

  /// Remove the current user's reaction from a message.
  ///
  /// Offline behaviour: queued; optimistic local update.
  Future<Either<Failure, void>> removeReaction({
    required String messageCode,
    required String emoji,
  });
}
