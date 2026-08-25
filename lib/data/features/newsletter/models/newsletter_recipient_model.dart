import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter_recipient_entity.dart';

class NewsletterRecipientModel extends Equatable {
  const NewsletterRecipientModel({
    required this.id,
    required this.code,
    required this.userCode,
    required this.userName,
    required this.status,
  });

  final int? id;
  final String code;
  final String userCode;
  final String userName;
  final String status;

  factory NewsletterRecipientModel.fromJson(Map<String, dynamic> json) {
    return NewsletterRecipientModel(
      id: json['id'] as int?,
      code: (json['code'] ?? '').toString().trim(),
      userCode: (json['userCode'] ?? '').toString().trim(),
      userName: (json['userName'] ?? '').toString().trim(),
      status: (json['status'] ?? '').toString().trim(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'userCode': userCode,
      'userName': userName,
      'status': status,
    };
  }

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
