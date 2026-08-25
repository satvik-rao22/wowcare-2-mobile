import 'package:equatable/equatable.dart';

class NewsletterComponentEntity extends Equatable {
  const NewsletterComponentEntity({
    required this.id,
    required this.type,
    required this.data,
    required this.order,
  });

  final int? id;
  final String type;
  final Map<String, dynamic> data;
  final int? order;

  @override
  List<Object?> get props => [id, type, data, order];
}
