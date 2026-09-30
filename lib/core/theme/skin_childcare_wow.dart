part of 'app_theme_config.dart';

/// The base skin: the ChildcareWow flat skeuomorphic design language.
///
/// Every other skin inherits these values and overrides only what differs.
/// A role whose value is another role's name (`iconDefault = textPrimary`)
/// is an alias and follows whichever skin is active.
abstract final class ChildcareWowSkin {
  // Brand
  /// Primary keys, the active nav slot, links.
  static const Color brand = BrandRamps.pink600;
  static const Color brandLight = BrandRamps.pink500;

  /// Pressed states, and text on a brand tint.
  static const Color brandDark = BrandRamps.pink700;

  /// Ink on [brand].
  static const Color onBrand = textOnDark;
  static const Color brandSecondary = BrandRamps.navy;
  static const Color brandAccent = BrandRamps.pink500;

  /// The one recommended action. Never doubles as a warning.
  static const Color actionRecommended = brand;

  /// Highlight and attention, never a status.
  static const Color actionHighlight = BrandRamps.sun400;

  /// The wash under badges and pills.
  static const Color brandSoft = BrandRamps.pinkTint;

  /// The quiet action: a secondary key, a body link.
  static const Color actionSecondary = BrandRamps.teal600;

  // Text
  static const Color textPrimary = BrandRamps.ink;
  static const Color textSecondary = BrandRamps.inkSoft;
  static const Color textMuted = BrandRamps.inkFaint;

  /// Ink on a dark or saturated surface.
  static const Color textOnDark = BrandRamps.warmWhite;
  static const Color textLink = BrandRamps.teal700;

  // Glyphs
  static const Color iconDefault = textPrimary;
  static const Color iconMuted = textMuted;
  static const Color iconOnBrand = textOnDark;
  static const Color iconAction = actionRecommended;

  // Surfaces
  /// The scaffold: the warm tray everything sits on.
  static const Color surfacePage = BrandRamps.tray;

  /// A card, sheet or dialog raised off the tray.
  static const Color surfaceCard = BrandRamps.card;
  static const Color surfaceRaised = surfaceCard;

  /// A nested row, a chip strip, a sheet ground: one step below a card.
  static const Color surfaceSunken = BrandRamps.sub;

  /// Read-only fields and inert tiles.
  static const Color surfaceMuted = BrandRamps.wellAlt;

  /// Anything you type into: the well.
  static const Color surfaceField = BrandRamps.well;

  /// The bottom-sheet grabber and inset dividers.
  static const Color sheetGrabber = BrandRamps.wellDeep;

  /// A selected row, tile or chip.
  static const Color surfaceSelected = BrandRamps.pinkTint;

  /// The navy rail, an inverse banner.
  static const Color surfaceInverse = BrandRamps.navy;
  static const Color scrim = BrandRamps.navy;

  // Borders and dividers
  /// The 1px rule round a card and between rows.
  static const Color borderHairline = BrandRamps.inkHairline;
  static const Color border = BrandRamps.inkEdge;

  /// A text field or bordered chip at rest.
  static const Color borderField = BrandRamps.inkEdgeField;

  /// A focused field, anything that must read as an edge.
  static const Color borderStrong = BrandRamps.inkEdgeStrong;
  static const Color focusRing = brand;
  static const Color divider = BrandRamps.inkEdge;

  // Material. Depth comes from these, never from a gradient.
  /// Base tint of every drop shadow; `AppElevation` applies the alpha.
  static const Color shadowAmbient = BrandRamps.shadowWarm;

  /// Base tint of every inset shadow: wells, troughs, recessed keys.
  static const Color shadowInset = BrandRamps.ink;

  /// The lit top edge of a light raised surface.
  static const Color bevelLit = BrandRamps.white;

  /// The lit top edge of a dark raised surface.
  static const Color bevelGloss = BrandRamps.warmWhite;

  /// The solid under-edge of a card-faced key.
  static const Color rimNeutral = BrandRamps.neutralRim;

  /// The solid under-edge of the recommended (pink) key.
  static const Color rimAction = BrandRamps.pinkRim;
  static const Color rimSecondary = BrandRamps.tealRim;
  static const Color rimDestructive = BrandRamps.danger600;
  static const Color rimImpact = BrandRamps.navy900;

  // Status. *Soft is the tint; *Strong is ink that sits on the tint.
  static const Color statusSuccess = BrandRamps.green600;
  static const Color statusSuccessSoft = BrandRamps.greenTint;
  static const Color statusWarning = BrandRamps.sun400;
  static const Color statusWarningSoft = BrandRamps.sunTint;
  static const Color statusError = BrandRamps.danger500;
  static const Color statusErrorSoft = BrandRamps.dangerTint;

  /// Destructive accents and required-field marks.
  static const Color statusErrorStrong = BrandRamps.danger600;
  static const Color statusInfo = BrandRamps.teal500;
  static const Color statusInfoSoft = BrandRamps.tealTint;
  static const Color statusSuccessStrong = BrandRamps.green700;
  static const Color statusWarningStrong = BrandRamps.sun600;

  // Domain coding: teal is anything about a child, sun is anything about a
  // member of staff. Not decoration and not status.
  static const Color domainStudent = BrandRamps.teal600;
  static const Color domainStudentSoft = BrandRamps.tealTint;
  static const Color domainStudentInk = BrandRamps.teal700;
  static const Color domainStaff = BrandRamps.sun400;
  static const Color domainStaffSoft = BrandRamps.sunTint;
  static const Color domainStaffInk = BrandRamps.sunText;

  // Categorical series for charts, legends and chips. No status meaning.
  static const Color dataTeal = BrandRamps.teal500;
  static const Color dataTealSoft = BrandRamps.teal200;
  static const Color dataPink = BrandRamps.pink500;
  static const Color dataPinkSoft = BrandRamps.pink200;
  static const Color dataSun = BrandRamps.sun400;
  static const Color dataSunSoft = BrandRamps.sun200;
  static const Color dataGreen = BrandRamps.green500;
  static const Color dataGreenSoft = BrandRamps.green200;
  static const Color dataPurple = BrandRamps.purple400;
  static const Color dataPurpleSoft = BrandRamps.purple200;
  static const Color dataOrange = BrandRamps.orange400;
  static const Color dataOrangeSoft = BrandRamps.orange200;

  // Over media: chrome on a photo or video, where the L4 ramp is not legible.
  static const Color onMediaHint = BrandRamps.mediaHint;
  static const Color onMediaTrack = BrandRamps.mediaTrack;
  static const Color mediaScrim = BrandRamps.mediaScrim;
}
