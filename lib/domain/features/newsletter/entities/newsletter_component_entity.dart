import 'package:equatable/equatable.dart';

/// One media candidate found inside a newsletter component body.
///
/// Replaces the raw `Map<String, dynamic>` this entity used to carry (§8: no
/// maps in `lib/domain`). Every alias resolution that used to happen by
/// digging through that map at read time now happens once, in the data layer,
/// when the model is mapped to this entity.
class NewsletterComponentMedia extends Equatable {
  const NewsletterComponentMedia({
    this.type = '',
    this.imageUrl = '',
    this.assetCode = '',
    this.mimeType = '',
    this.fileName = '',
  });

  /// Upper-cased part type (`'IMAGE'`, `'TEXT'`, …). Empty for the flat
  /// legacy shape, which has no type of its own.
  final String type;

  final String imageUrl;
  final String assetCode;

  /// Empty when the payload carried neither `mimeType` nor `contentType`.
  /// [resolveThumbnailMimeType] treats empty and null identically, which is
  /// what the previous `?.toString() ?? …` chain produced.
  final String mimeType;

  final String fileName;

  bool get isImage => type == 'IMAGE';

  bool get hasSource => imageUrl.isNotEmpty || assetCode.isNotEmpty;

  @override
  List<Object?> get props => [type, imageUrl, assetCode, mimeType, fileName];
}

/// A component's body: its `parts` list, plus the flat legacy shape older
/// payloads put directly on the body instead of in `parts`.
class NewsletterComponentBody extends Equatable {
  const NewsletterComponentBody({
    this.parts = const <NewsletterComponentMedia>[],
    this.flat = const NewsletterComponentMedia(),
  });

  final List<NewsletterComponentMedia> parts;

  /// The body's own image fields, for payloads predating `parts`.
  final NewsletterComponentMedia flat;

  @override
  List<Object?> get props => [parts, flat];
}

class NewsletterComponentEntity extends Equatable {
  const NewsletterComponentEntity({
    required this.id,
    required this.type,
    required this.body,
    required this.order,
    this.contentJson = '',
  });

  final int? id;
  final String type;

  /// The typed media inside this component, for thumbnail selection.
  final NewsletterComponentBody body;

  final int? order;

  /// The component body as a raw JSON STRING, or '' when it was empty.
  ///
  /// [body] is a lossy view — it keeps only what thumbnail selection needs, so
  /// a TEXT part's prose is not in it. `newsletter_content_parser` needs the
  /// whole body and takes it as a JSON string by design, so the string is
  /// carried alongside rather than reconstructed from [body], which would
  /// silently drop text.
  ///
  /// A String, not a `Map<String, dynamic>` — §8 bans the map from `lib/domain`
  /// and this keeps the round trip lossless without reintroducing one.
  final String contentJson;

  @override
  List<Object?> get props => [id, type, body, order, contentJson];
}
