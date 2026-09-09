import 'package:json_annotation/json_annotation.dart';
import 'package:wowcare/data/features/newsletter/models/newsletter_json.dart';

part 'newsletter_api_envelope.g.dart';

/// The `{success, message, data}` wrapper every newsletter endpoint returns.
///
/// §8: *"Datasources call `Model.fromJson(response)` and return the model.
/// They do not read keys off a map."* Before this, each datasource method
/// re-implemented the same three checks inline — is the body a map, is
/// `success` true, what is `message` — which is exactly the map-reading the
/// mandate is trying to remove from datasources.
///
/// [data] stays `Object?` deliberately: one endpoint puts a page object there
/// and another puts a single newsletter, so the envelope does not know its own
/// payload type. The typed models take it from here.
@JsonSerializable(createToJson: false)
class NewsletterApiEnvelope {
  const NewsletterApiEnvelope({
    required this.success,
    required this.message,
    required this.data,
  });

  factory NewsletterApiEnvelope.fromJson(Map<String, dynamic> json) =>
      _$NewsletterApiEnvelopeFromJson(json);

  /// Reads a raw response body, which Dio types as `dynamic`.
  ///
  /// Returns null when the body is not a JSON object at all — the caller
  /// raises the same "invalid response" error it always did.
  static NewsletterApiEnvelope? tryFrom(Object? body) {
    if (body is Map<String, dynamic>) return NewsletterApiEnvelope.fromJson(body);
    if (body is Map) {
      return NewsletterApiEnvelope.fromJson(Map<String, dynamic>.from(body));
    }
    return null;
  }

  @JsonKey(defaultValue: false)
  final bool success;

  @JsonKey(fromJson: jsonTrimmedStringOrNull)
  final String? message;

  final Object? data;

  /// The payload as a JSON object, or null when it is absent or not an object.
  Map<String, dynamic>? get dataAsMap {
    final Object? payload = data;
    if (payload is Map<String, dynamic>) return payload;
    if (payload is Map) return Map<String, dynamic>.from(payload);
    return null;
  }
}
