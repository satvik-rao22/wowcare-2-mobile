import 'package:equatable/equatable.dart';
import 'package:wowcare/domain/features/newsletter/entities/paginated_newsletters_entity.dart';

import 'newsletter_model.dart';

class PaginatedNewslettersResponseModel extends Equatable {
  const PaginatedNewslettersResponseModel({
    required this.items,
    required this.page,
    required this.size,
    required this.totalPages,
    required this.totalElements,
    required this.hasMore,
  });

  final List<NewsletterModel> items;
  final int page;
  final int size;
  final int totalPages;
  final int totalElements;
  final bool hasMore;

  factory PaginatedNewslettersResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final content = data['content'] as List<dynamic>? ?? const [];
    final pageNumber = data['number'] as int? ?? 0;
    final pageSize = data['size'] as int? ?? content.length;
    final totalPages = data['totalPages'] as int? ?? 0;
    final totalElements = data['totalElements'] as int? ?? content.length;

    final items = content
        .whereType<Map>()
        .map((e) => NewsletterModel.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);

    final hasMore = pageNumber + 1 < totalPages;

    return PaginatedNewslettersResponseModel(
      items: items,
      page: pageNumber,
      size: pageSize,
      totalPages: totalPages,
      totalElements: totalElements,
      hasMore: hasMore,
    );
  }

  PaginatedNewslettersEntity toEntity() {
    return PaginatedNewslettersEntity(
      items: items.map((e) => e.toEntity()).toList(growable: false),
      page: page,
      size: size,
      totalPages: totalPages,
      totalElements: totalElements,
      hasMore: hasMore,
    );
  }

  @override
  List<Object?> get props => [items, page, size, totalPages, totalElements, hasMore];
}

