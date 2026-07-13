import 'package:url_launcher/url_launcher.dart';

/// Opens a newsletter HTML hyperlink in the device browser (or appropriate app).
Future<bool> openNewsletterHyperlink(String? rawUrl) async {
  final String? normalized = _normalizeHyperlinkUrl(rawUrl);
  if (normalized == null) return false;

  final Uri? uri = Uri.tryParse(normalized);
  if (uri == null) return false;

  final LaunchMode mode = _launchModeForUri(uri);
  if (await canLaunchUrl(uri)) {
    return launchUrl(uri, mode: mode);
  }

  return launchUrl(uri, mode: LaunchMode.platformDefault);
}

LaunchMode _launchModeForUri(Uri uri) {
  final String scheme = uri.scheme.toLowerCase();
  if (scheme == 'http' || scheme == 'https') {
    return LaunchMode.externalApplication;
  }
  return LaunchMode.platformDefault;
}

String? _normalizeHyperlinkUrl(String? rawUrl) {
  final String url = (rawUrl ?? '').trim();
  if (url.isEmpty) return null;

  final String lower = url.toLowerCase();
  if (lower.startsWith('mailto:') ||
      lower.startsWith('tel:') ||
      lower.startsWith('sms:')) {
    return url;
  }
  if (lower.startsWith('http://') || lower.startsWith('https://')) {
    return url;
  }
  if (url.startsWith('//')) {
    return 'https:$url';
  }
  return 'https://$url';
}
