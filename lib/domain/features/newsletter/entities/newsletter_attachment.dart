class NewsletterAttachment {
  const NewsletterAttachment({
    required this.id,
    required this.mediaCode,
    required this.fileName,
    required this.mimeType,
    this.assetUrl = '',
    this.sortOrder = 0,
  });

  final int id;
  final String mediaCode;
  final String fileName;
  final String mimeType;
  final String assetUrl;
  final int sortOrder;

  bool get isImage {
    final mime = mimeType.toLowerCase();
    return mime.startsWith('image/') || mime == 'image/*';
  }

  String get resolvedUrl => assetUrl.trim();
}
