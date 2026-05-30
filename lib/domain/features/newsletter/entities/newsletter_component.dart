enum NewsletterPartType { text, image }

class NewsletterContentPart {
  const NewsletterContentPart({
    required this.type,
    this.text = '',
    this.imageUrl = '',
    this.assetUrl = '',
    this.alt = '',
    this.assetCode = '',
  });

  const NewsletterContentPart.text({required this.text})
      : type = NewsletterPartType.text,
        imageUrl = '',
        assetUrl = '',
        alt = '',
        assetCode = '';

  const NewsletterContentPart.image({
    this.imageUrl = '',
    this.assetUrl = '',
    this.alt = '',
    this.assetCode = '',
  })  : type = NewsletterPartType.image,
        text = '';

  final NewsletterPartType type;
  final String text;

  /// Legacy / alternate URL fields from contentJson.
  final String imageUrl;

  /// Processed delivery URL from API (`assetUrl`), same as newsletter attachments.
  final String assetUrl;
  final String alt;
  final String assetCode;

  bool get hasText => text.trim().isNotEmpty;
  bool get hasImage =>
      assetUrl.trim().isNotEmpty ||
      imageUrl.trim().isNotEmpty ||
      assetCode.trim().isNotEmpty ||
      _storagePathMayContainAssetCode(imageUrl);

  static bool _storagePathMayContainAssetCode(String path) {
    final text = path.trim();
    return text.startsWith('raw/') && text.contains('/assets/AST_');
  }

  /// Best URL to display when available (matches attachment `resolvedUrl`).
  String get resolvedImageUrl {
    final delivery = assetUrl.trim();
    if (delivery.isNotEmpty) return delivery;
    final legacy = imageUrl.trim();
    if (legacy.startsWith('http://') || legacy.startsWith('https://')) {
      return legacy;
    }
    return '';
  }
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
