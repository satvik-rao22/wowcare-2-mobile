import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/newsletter/entities/newsletter_component_entity.dart';

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
    Map<String, dynamic> data = rawData is Map<String, dynamic>
        ? rawData
        : rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : <String, dynamic>{};

    if (data.isEmpty) {
      final contentJson = json['contentJson'];
      if (contentJson is String && contentJson.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(contentJson);
          if (decoded is Map) {
            data = Map<String, dynamic>.from(decoded);
          }
        } catch (_) {}
      }
    }

    return NewsletterComponentModel(
      id: json['id'] as int?,
      type: (json['type'] ?? json['componentType'] ?? '').toString().trim(),
      data: data,
      order: json['order'] as int? ?? json['sortOrder'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'type': type, 'data': data, 'order': order};
  }

  NewsletterComponentEntity toEntity() {
    return NewsletterComponentEntity(
      id: id,
      type: type,
      data: data,
      order: order,
    );
  }

  @override
  List<Object?> get props => [id, type, data, order];
}
