class NewsletterAttachment {
  const NewsletterAttachment({
    required this.id,
    required this.mediaCode,
    required this.fileName,
    required this.mimeType,
  });

  final int id;
  final String mediaCode;
  final String fileName;
  final String mimeType;

  bool get isImage {
    final mime = mimeType.toLowerCase();
    return mime.startsWith('image/');
  }
}
