/// How a tapped newsletter attachment should be opened.
enum NewsletterAttachmentOpenMode {
  /// Images render in the in-app preview overlay.
  imagePreview,

  /// Everything else is handed to the OS.
  ///
  /// Never an in-app WebView. A WebView renders only what a browser engine
  /// natively displays, so a spreadsheet, .docx, .pptx or .zip — and on Android
  /// a .pdf — paints an empty white page, and does so *successfully*, giving the
  /// caller no failure to react to. The OS hands the file to a real handler
  /// (Excel, Drive, Files, or the browser's downloader) instead.
  externalApp,

  /// The URL is missing, unparseable, or carries a scheme an attachment has no
  /// business using. The caller tells the user rather than launching it.
  refused,
}

/// Decides how [url] should open, from the attachment's own type.
///
/// Pure, so the routing rule that fixes the .xlsx blank screen is testable
/// without a plugin: the branch a document takes is decided here, not inside the
/// `launchUrl` call.
///
/// [isImage] comes from `NewsletterAttachment.isImage` (a MIME-type check).
/// Images deliberately skip the scheme allowlist below — they always have, and
/// the preview overlay's `Image.network` fails safely on its own.
NewsletterAttachmentOpenMode resolveNewsletterAttachmentOpenMode({
  required bool isImage,
  required String url,
}) {
  if (isImage) return NewsletterAttachmentOpenMode.imagePreview;

  final Uri? uri = Uri.tryParse(url.trim());
  if (uri == null) return NewsletterAttachmentOpenMode.refused;

  // Scheme allowlist. Attachments are CDN files, so http/https is the entire
  // legitimate set; anything else (file:, javascript:, a custom app scheme) is
  // refused rather than launched.
  //
  // Stricter than the body-hyperlink normaliser on purpose: that one accepts
  // mailto:/tel:/sms: because a newsletter's prose legitimately links to them.
  // An attachment never does.
  final String scheme = uri.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') {
    return NewsletterAttachmentOpenMode.refused;
  }

  return NewsletterAttachmentOpenMode.externalApp;
}
