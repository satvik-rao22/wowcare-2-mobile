/// Every asset path the redesign uses.
///
/// The design draws its glyphs as inline Lucide outlines rather than assets, so
/// most icons are painted, not loaded. What lives here is the handful of real
/// files: the brand marks, and the four SVGs the repo did not already carry.
///
/// A screen never writes an asset path inline.
abstract final class AppAssets {
  static const String _icons = 'assets/icons';
  static const String _vectors = 'assets/vectors';
  static const String _lottie = 'assets/lottie';

  // --- Brand ----------------------------------------------------------------

  /// The full ChildcareWow wordmark, for the sign-in screen.
  static const String wordmark = '$_vectors/ChildcareWow.svg';

  /// The mark on its own, for the header bar and the kiosk.
  static const String logoMark = '$_icons/logo-mark.svg';

  // --- Added for the redesign ----------------------------------------------

  /// The house hamburger. Replaces production's three-dot kebab everywhere.
  static const String moreMenu = '$_icons/more-menu.svg';

  /// The upload affordance on a dashed drop well.
  static const String uploadCloud = '$_icons/upload-cloud-icon.svg';

  /// The QR panel on the kiosk sign-in screen.
  static const String kioskQr = '$_icons/kiosk-qr.svg';

  // --- Motion ---------------------------------------------------------------

  static const String loadingLottie = '$_lottie/loading.json';
}
