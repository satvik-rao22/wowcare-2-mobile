import 'dart:typed_data';

/// Identifies a video container from its leading bytes.
///
/// ## Why this is hand-rolled rather than `package:mime`
///
/// `lookupMimeType` is not usable for this check, in two ways that were
/// measured rather than assumed:
///
/// * **It falls back to the file extension** when the magic bytes match
///   nothing. A text file named `clip.mp4` therefore sniffs as `video/mp4` —
///   which defeats the entire point of content-sniffing, since the extension is
///   attacker/user-controlled.
/// * **Its magic table does not cover our accepted set.** Forcing header-only
///   matching (by passing an extensionless path) returns `null` for QuickTime
///   `.mov` and misidentifies WebM as `audio/weba`, because EBML's magic number
///   is shared between the audio and video profiles.
///
/// So this reads the two container families the flow accepts directly.
abstract final class VideoContainerSniffer {
  /// Bytes needed: 12 for ISO-BMFF (size + `ftyp` + brand), and enough of an
  /// EBML header to reach its `DocType` string.
  static const int requiredBytes = 64;

  /// Returns one of `video/mp4`, `video/quicktime`, `video/webm`, or null when
  /// the bytes are not a recognised, accepted video container.
  ///
  /// Null is a rejection, not an "unknown, allow it": anything unrecognised is
  /// something the backend would refuse anyway.
  static String? sniff(Uint8List header) {
    final isoBmff = _sniffIsoBmff(header);
    if (isoBmff != null) return isoBmff;
    return _sniffEbml(header);
  }

  /// ISO base media file format — the family containing both MP4 and
  /// QuickTime. Layout: a 4-byte box size, then the literal `ftyp`, then a
  /// 4-byte major brand that separates the two.
  static String? _sniffIsoBmff(Uint8List h) {
    if (h.length < 12) return null;
    if (!_matchesAscii(h, 4, 'ftyp')) return null;

    final brand = String.fromCharCodes(h.sublist(8, 12));
    // QuickTime's brand is `qt  ` (trailing spaces). Everything else in this
    // family that a camera produces — isom, iso2, mp41, mp42, avc1, M4V , dash
    // — is served as video/mp4, which is what the backend accepts.
    if (brand.startsWith('qt')) return 'video/quicktime';
    return 'video/mp4';
  }

  /// EBML — the container family behind WebM and Matroska. The magic number is
  /// identical for both, and for the audio-only profiles, so the `DocType`
  /// string has to be read to tell them apart.
  static String? _sniffEbml(Uint8List h) {
    if (h.length < 4) return null;
    if (h[0] != 0x1A || h[1] != 0x45 || h[2] != 0xDF || h[3] != 0xA3) {
      return null;
    }
    // `DocType` appears as a plain ASCII value early in the header. Matroska
    // (.mkv) is deliberately NOT accepted — it is not in the backend's set.
    for (var i = 4; i + 4 <= h.length; i++) {
      if (_matchesAscii(h, i, 'webm')) return 'video/webm';
    }
    return null;
  }

  static bool _matchesAscii(Uint8List h, int offset, String literal) {
    if (offset + literal.length > h.length) return false;
    for (var i = 0; i < literal.length; i++) {
      if (h[offset + i] != literal.codeUnitAt(i)) return false;
    }
    return true;
  }
}
