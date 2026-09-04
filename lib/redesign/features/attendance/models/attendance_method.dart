/// How a sign in or a sign out was recorded.
///
/// One of the module's free wins: the API returns it on every row and no
/// screen has ever drawn it. These are the four codes it sends.
enum AttendanceMethod {
  gps,
  pin,
  qr,
  app;

  String get label => switch (this) {
    AttendanceMethod.gps => 'GPS',
    AttendanceMethod.pin => 'PIN',
    AttendanceMethod.qr => 'QR',
    AttendanceMethod.app => 'App',
  };

  /// How the record sheet says it: "By Dana Whitfield on the kiosk pad."
  String get onThe => switch (this) {
    AttendanceMethod.gps => 'phone, in range',
    AttendanceMethod.pin => 'kiosk pad',
    AttendanceMethod.qr => 'kiosk QR reader',
    AttendanceMethod.app => 'app',
  };
}
