import 'package:equatable/equatable.dart';

class NewsletterRecipientEntity extends Equatable {
  const NewsletterRecipientEntity({
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

  @override
  List<Object?> get props => [id, code, userCode, userName, status];
}
