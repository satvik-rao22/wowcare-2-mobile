/// Who is looking. Role carries no colour and changes no material: an Admin,
/// Staff and Guardian screen for the same feature look the same, and only what
/// they may see and do differs.
///
/// Mirrors the existing `RoleCubit`: `isAdmin` there is true for staff as
/// well, and `isTrueAdmin` is the admin-only check. Here the three are kept
/// distinct and screens ask the question they mean.
enum Persona {
  admin,
  staff,
  guardian;

  /// Admin and Staff share the five-slot bar and the More page.
  bool get isSchoolSide => this != Persona.guardian;
}
