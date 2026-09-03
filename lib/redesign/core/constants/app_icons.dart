import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Every glyph the design draws, named by the job it does.
///
/// The design's glyphs are Lucide outlines, so this maps each one onto the
/// Lucide font the app already ships. The stroke weight is fixed by the font
/// rather than the design's 2.1, and that is accepted. A screen names a glyph
/// from here; it never reaches for `LucideIcons` directly, so a swap is one
/// line.
abstract final class AppIcons {
  // --- Header bar -----------------------------------------------------------

  /// The house hamburger, which opens More.
  static const IconData menu = LucideIcons.menu;
  static const IconData scanQr = LucideIcons.scanLine;
  static const IconData bell = LucideIcons.bell;
  static const IconData search = LucideIcons.search;
  static const IconData filter = LucideIcons.slidersHorizontal;
  static const IconData plus = LucideIcons.plus;
  static const IconData moreHorizontal = LucideIcons.ellipsis;

  // --- Direction ------------------------------------------------------------

  static const IconData chevronLeft = LucideIcons.chevronLeft;
  static const IconData chevronRight = LucideIcons.chevronRight;
  static const IconData chevronDown = LucideIcons.chevronDown;
  static const IconData chevronUp = LucideIcons.chevronUp;
  static const IconData arrowLeft = LucideIcons.arrowLeft;
  static const IconData arrowRight = LucideIcons.arrowRight;
  static const IconData transfer = LucideIcons.arrowRightLeft;

  // --- Marks ----------------------------------------------------------------

  static const IconData close = LucideIcons.x;
  static const IconData check = LucideIcons.check;
  static const IconData checkCircle = LucideIcons.circleCheck;
  static const IconData eye = LucideIcons.eye;
  static const IconData eyeOff = LucideIcons.eyeOff;
  static const IconData info = LucideIcons.info;
  static const IconData alertTriangle = LucideIcons.triangleAlert;
  static const IconData alertCircle = LucideIcons.circleAlert;
  static const IconData refresh = LucideIcons.refreshCw;
  static const IconData wifiOff = LucideIcons.wifiOff;

  // --- Fields ---------------------------------------------------------------

  static const IconData mail = LucideIcons.mail;
  static const IconData lock = LucideIcons.lock;
  static const IconData user = LucideIcons.user;
  static const IconData users = LucideIcons.users;
  static const IconData calendar = LucideIcons.calendar;
  static const IconData clock = LucideIcons.clock;
  static const IconData mapPin = LucideIcons.mapPin;
  static const IconData phone = LucideIcons.phone;
  static const IconData camera = LucideIcons.camera;
  static const IconData image = LucideIcons.image;
  static const IconData paperclip = LucideIcons.paperclip;
  static const IconData send = LucideIcons.send;

  // --- Verbs ----------------------------------------------------------------

  static const IconData edit = LucideIcons.pencil;
  static const IconData trash = LucideIcons.trash2;
  static const IconData logOut = LucideIcons.logOut;
  static const IconData settings = LucideIcons.settings;
  static const IconData download = LucideIcons.download;
  static const IconData upload = LucideIcons.upload;
  static const IconData fileText = LucideIcons.fileText;
  static const IconData receipt = LucideIcons.receipt;
  static const IconData key = LucideIcons.keyRound;
  static const IconData backspace = LucideIcons.delete;

  // --- The five nav slots, and the modules behind More ----------------------

  static const IconData dashboard = LucideIcons.house;
  static const IconData attendance = LucideIcons.clipboardCheck;
  static const IconData classrooms = LucideIcons.doorOpen;
  static const IconData activities = LucideIcons.sparkles;
  static const IconData messages = LucideIcons.messageCircle;
  static const IconData billing = LucideIcons.creditCard;
  static const IconData students = LucideIcons.graduationCap;
  static const IconData staff = LucideIcons.usersRound;
  static const IconData profile = LucideIcons.circleUser;
  static const IconData movements = LucideIcons.arrowRightLeft;
  static const IconData scheduling = LucideIcons.calendarDays;
  static const IconData newsletter = LucideIcons.newspaper;
  static const IconData reports = LucideIcons.chartBar;
  static const IconData tasks = LucideIcons.listChecks;
  static const IconData events = LucideIcons.calendarCheck;
  static const IconData school = LucideIcons.school;
  static const IconData building = LucideIcons.building2;
}
