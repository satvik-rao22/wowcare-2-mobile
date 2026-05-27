import 'dart:convert';

/// Extracts the `sub` claim from a JWT access token without verifying the
/// signature.  The result is the UUID that the backend uses as the identity
/// anchor (stored as `senderUserCode` in messaging responses).
String? extractJwtSub(String? token) {
  if (token == null || token.isEmpty) return null;
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;

    // Pad the Base64Url payload to a multiple of 4.
    var payload = parts[1];
    final rem = payload.length % 4;
    if (rem != 0) payload += '=' * (4 - rem);

    final decoded = utf8.decode(base64Url.decode(payload));
    final claims = jsonDecode(decoded) as Map<String, dynamic>;
    return (claims['sub'] as String?)?.trim();
  } catch (_) {
    return null;
  }
}
