enum UserPersona {
  parent,
  admin,
  staff;

  bool get isParent => this == UserPersona.parent;
  bool get isAdmin => this == UserPersona.admin;
  bool get isStaff => this == UserPersona.staff;

  String get label {
    return switch (this) {
      UserPersona.parent => 'Parent',
      UserPersona.admin => 'Admin',
      UserPersona.staff => 'Staff',
    };
  }
}
