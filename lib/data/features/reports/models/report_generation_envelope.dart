import 'package:json_annotation/json_annotation.dart';

part 'report_generation_envelope.g.dart';

/// The `{success, message, data, error}` wrapper the generate endpoint puts
/// around every report payload.
///
/// Modelled separately (§8) because it is a genuinely different wire shape
/// from the report itself: [ReportResponseModel] describes the report, this
/// describes the transport around it.
///
/// [success], [message] and [error] are deliberately `Object?` rather than
/// `bool?`/`String?`. The failure branch interpolates them into an error
/// message without casting, so a backend that sends `success: "false"` or a
/// non-string message must still produce a [FormatException] naming the
/// problem — not a [TypeError] from a failed cast during decoding.
@JsonSerializable(createToJson: false)
class ReportGenerationEnvelope {
  const ReportGenerationEnvelope({
    this.success,
    this.message,
    this.error,
    this.data,
  });

  factory ReportGenerationEnvelope.fromJson(Map<String, dynamic> json) =>
      _$ReportGenerationEnvelopeFromJson(json);

  final Object? success;
  final Object? message;
  final Object? error;

  /// The report payload. A `Map` is the right type here: this is the data
  /// layer, and the map is handed straight to [ReportResponseModel] rather
  /// than travelling any further inward (§8).
  final Map<String, dynamic>? data;

  /// Throws when the backend explicitly reported failure.
  ///
  /// Only a real `false` counts — anything else falls through to normal
  /// parsing, which is what the hand-written parser did.
  void throwIfFailed() {
    final result = success;
    if (result is bool && !result) {
      throw FormatException(
        'Report generation failed: ${message ?? error ?? 'unknown error'}',
      );
    }
  }
}
