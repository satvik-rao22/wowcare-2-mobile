enum NewsletterPartType { text, image }

class NewsletterContentPart {
  const NewsletterContentPart({
    required this.type,
    this.text = '',
    this.imageUrl = '',
    this.alt = '',
    this.assetCode = '',
  });

  const NewsletterContentPart.text({required this.text})
      : type = NewsletterPartType.text,
        imageUrl = '',
        alt = '',
        assetCode = '';

  const NewsletterContentPart.image({
    required this.imageUrl,
    this.alt = '',
    this.assetCode = '',
  })  : type = NewsletterPartType.image,
        text = '';

  final NewsletterPartType type;
  final String text;
  final String imageUrl;
  final String alt;
  final String assetCode;

  bool get hasText => text.trim().isNotEmpty;
  bool get hasImage =>
      imageUrl.trim().isNotEmpty || assetCode.trim().isNotEmpty;
}

class NewsletterComponent {
  const NewsletterComponent({
    required this.id,
    required this.componentType,
    required this.sortOrder,
    required this.parts,
  });

  final int id;
  final String componentType;
  final int sortOrder;
  final List<NewsletterContentPart> parts;

  String get normalizedType => componentType.trim().toUpperCase();
}
