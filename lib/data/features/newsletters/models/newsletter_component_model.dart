import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/newsletters/entities/newsletter_component_entity.dart';

class NewsletterComponentModel extends Equatable {
  const NewsletterComponentModel({
    required this.id,
    required this.type,
    required this.data,
    required this.order,
  });

  final int? id;
  final String type;
  final Map<String, dynamic> data;
  final int? order;

  factory NewsletterComponentModel.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return NewsletterComponentModel(
      id: json['id'] as int?,
      type: (json['type'] ?? json['componentType'] ?? '').toString().trim(),
      data: rawData is Map<String, dynamic>
          ? rawData
          : rawData is Map
              ? Map<String, dynamic>.from(rawData)
              : <String, dynamic>{},
      order: json['order'] as int? ?? json['sortOrder'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'type': type, 'data': data, 'order': order};
  }

  NewsletterComponentEntity toEntity() {
    return NewsletterComponentEntity(id: id, type: type, data: data, order: order);
  }

  @override
  List<Object?> get props => [id, type, data, order];
}

