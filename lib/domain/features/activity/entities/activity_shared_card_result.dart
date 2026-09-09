import 'package:equatable/equatable.dart';

/// One created card from `POST /api/v2/shared-activities` (`data[]`).
///
/// The API returns other fields per card too, but only [cardCode] has ever
/// been read by a caller — this stays minimal rather than guessing at a
/// fuller shape nothing uses yet.
class ActivitySharedCardResult extends Equatable {
  const ActivitySharedCardResult({required this.cardCode});

  final String cardCode;

  factory ActivitySharedCardResult.fromJson(Map<String, dynamic> json) {
    return ActivitySharedCardResult(
      cardCode: (json['cardCode'] ?? '').toString().trim(),
    );
  }

  @override
  List<Object?> get props => [cardCode];
}
