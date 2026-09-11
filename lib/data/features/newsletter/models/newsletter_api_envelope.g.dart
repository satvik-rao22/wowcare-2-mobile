// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'newsletter_api_envelope.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NewsletterApiEnvelope _$NewsletterApiEnvelopeFromJson(
        Map<String, dynamic> json) =>
    NewsletterApiEnvelope(
      success: json['success'] as bool? ?? false,
      message: jsonTrimmedStringOrNull(json['message']),
      data: json['data'],
    );
