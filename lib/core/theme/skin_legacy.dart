part of 'app_theme_config.dart';

/// The look the app shipped with before the brand skin: plum ink, indigo
/// action, white ground, Manrope. A full override of the base; nothing here
/// is inherited.
abstract final class LegacySkin {
  // Brand
  static const Color brand = LegacyHues.indigo;
  static const Color brandLight = LegacyHues.indigoLight;
  static const Color brandDark = LegacyHues.navy;
  static const Color brandSecondary = LegacyHues.navy;
  static const Color brandAccent = LegacyHues.violet;
  static const Color actionHighlight = LegacyHues.amber;
  static const Color brandSoft = LegacyHues.lavender;
  static const Color actionSecondary = LegacyHues.indigo;

  // Text
  static const Color textPrimary = LegacyHues.plum;
  static const Color textSecondary = LegacyHues.grey600;
  static const Color textMuted = LegacyHues.grey500;
  static const Color textOnDark = LegacyHues.white;
  static const Color textLink = LegacyHues.indigo;

  // Surfaces
  static const Color surfacePage = LegacyHues.white;
  static const Color surfaceCard = LegacyHues.white;
  static const Color surfaceSunken = LegacyHues.grey100;
  static const Color surfaceMuted = LegacyHues.grey100;
  static const Color surfaceField = LegacyHues.fieldTint;
  static const Color sheetGrabber = LegacyHues.grey300;
  static const Color surfaceSelected = LegacyHues.selectedTint;
  static const Color surfaceInverse = LegacyHues.navy;
  static const Color scrim = LegacyHues.black;

  // Borders and dividers
  static const Color borderHairline = LegacyHues.hairline;
  static const Color border = LegacyHues.grey300;
  static const Color borderField = LegacyHues.plumEdge;
  static const Color borderStrong = LegacyHues.grey400;
  static const Color divider = LegacyHues.grey400;

  // Material
  static const Color shadowAmbient = LegacyHues.black;
  static const Color shadowInset = LegacyHues.black;
  static const Color bevelLit = LegacyHues.white;
  static const Color bevelGloss = LegacyHues.white;
  static const Color rimNeutral = LegacyHues.grey300;
  static const Color rimAction = LegacyHues.navy;
  static const Color rimSecondary = LegacyHues.navy;
  static const Color rimDestructive = LegacyHues.red;
  static const Color rimImpact = LegacyHues.black;

  // Status
  static const Color statusSuccess = LegacyHues.green;
  static const Color statusSuccessSoft = LegacyHues.successSoft;
  static const Color statusWarning = LegacyHues.orange;
  static const Color statusWarningSoft = MaterialHues.orange50;
  static const Color statusError = LegacyHues.red;
  static const Color statusErrorSoft = MaterialHues.red50;
  static const Color statusErrorStrong = LegacyHues.errorStrong;
  static const Color statusInfo = LegacyHues.blue;
  static const Color statusInfoSoft = MaterialHues.blue50;
  static const Color statusSuccessStrong = LegacyHues.successStrong;
  static const Color statusWarningStrong = LegacyHues.warningStrong;

  // Domain coding
  static const Color domainStudent = LegacyHues.blue;
  static const Color domainStudentSoft = LegacyHues.grey100;
  static const Color domainStudentInk = LegacyHues.blue;
  static const Color domainStaff = LegacyHues.amber;
  static const Color domainStaffSoft = LegacyHues.grey100;
  static const Color domainStaffInk = LegacyHues.orange;

  // Categorical series
  static const Color dataTeal = LegacyHues.blue;
  static const Color dataTealSoft = LegacyHues.lavender;
  static const Color dataPink = LegacyHues.pink;
  static const Color dataPinkSoft = LegacyHues.pinkLight;
  static const Color dataSun = LegacyHues.amber;
  static const Color dataSunSoft = LegacyHues.grey200;
  static const Color dataGreen = LegacyHues.green;
  static const Color dataGreenSoft = LegacyHues.grey200;
  static const Color dataPurple = LegacyHues.violet;
  static const Color dataPurpleSoft = LegacyHues.lavender;
  static const Color dataOrange = LegacyHues.orange;
  static const Color dataOrangeSoft = LegacyHues.grey200;

  // Over media
  static const Color onMediaHint = LegacyHues.mediaHint;
  static const Color onMediaTrack = LegacyHues.mediaTrack;
  static const Color mediaScrim = LegacyHues.mediaScrim;
}
