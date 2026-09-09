import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:wowcare/data/features/newsletter/models/newsletter_json.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter_recipient_entity.dart';

part 'newsletter_recipient_model.g.dart';

/// One recipient of a student-scoped newsletter.
@JsonSerializable()
class NewsletterRecipientModel extends Equatable {
  const NewsletterRecipientModel({
    required this.id,
    required this.code,
    required this.userCode,
    required this.userName,
    required this.status,
  });

  factory NewsletterRecipientModel.fromJson(Map<String, dynamic> json) =>
      _$NewsletterRecipientModelFromJson(json);

  final int? id;

  @JsonKey(fromJson: jsonTrimmedString)
  final String code;

  @JsonKey(fromJson: jsonTrimmedString)
  final String userCode;

  @JsonKey(fromJson: jsonTrimmedString)
  final String userName;

  @JsonKey(fromJson: jsonTrimmedString)
  final String status;

  Map<String, dynamic> toJson() => _$NewsletterRecipientModelToJson(this);

  NewsletterRecipientEntity toEntity() {
    return NewsletterRecipientEntity(
      id: id,
      code: code,
      userCode: userCode,
      userName: userName,
      status: status,
    );
  }

  @override
  List<Object?> get props => [id, code, userCode, userName, status];
}
