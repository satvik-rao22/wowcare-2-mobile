import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../res/colors.dart';
import '../app/providers/nav_bar_providers.dart';

extension ContextExtentions on BuildContext {
  ThemeData get theme => Theme.of(this);

  MediaQueryData get mediaQuery => MediaQuery.of(this);

  Size get size => mediaQuery.size;

  double get width => size.width;
  double get height => size.height;

  double get navBarHeight => watch<NavBarHeightProvider>().height;

  // UserProviders get userProviders => read<UserProviders>();

  // SecurityUser? get currentUser => userProviders.user;

  // EmployeeProviders get employeeProviders => read<EmployeeProviders>();

  // Employee? get currentEmployee => employeeProviders.employee;

  // StaffProviders get staffProviders => read<StaffProviders>();

  // Staff? get currentStaff => staffProviders.staff;

  // GuardianProvider get guardianProvider => read<GuardianProvider>();

  // GuardianEntity? get currentGuardian => guardianProvider.guardian;

  // ProfilePhotoProvider get profilePhotoProvider => read<ProfilePhotoProvider>();

  // Uint8List? get currentStaffProfilePhoto => profilePhotoProvider.profilePhoto;

  // bool get isPersonnel => currentUser!.refTable == 'Staff';

  // bool get isStaff =>
  //     isPersonnel &&
  //     (currentStaff!.designation != 'Admin' &&
  //         currentStaff!.designation != 'Director' &&
  //         currentStaff!.designation != 'Kiosk');

  // bool get isAdmin => isPersonnel && currentStaff!.designation == 'Admin';

  // bool get isDirector => isPersonnel && currentStaff!.designation == 'Director';

  // bool get isAdminOrDirector => isAdmin || isDirector;

  // bool get isKiosk => isPersonnel && currentStaff!.designation == 'Kiosk';

  // bool get isGuardian => currentUser!.refTable == 'Guardian';

  // TabNavigator get tabNavigator => read<TabNavigator>();

  // void pop() => tabNavigator.pop();

  // void push(Widget page) => tabNavigator.push(TabItem(child: page));

  Future<T?> showBottomSheet<T>({
    required Widget child,
    bool isDismissible = true,
    bool enableDrag = true,
    Color? backgroundColor,
    double? height,
    BoxConstraints? constraints,
    ShapeBorder? shape,
  }) {
    return showModalBottomSheet<T>(
      context: this,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      showDragHandle: true,
      backgroundColor: backgroundColor ?? AppColors.cardColor,
      isScrollControlled: true,
      constraints: constraints,
      shape:
          shape ??
          const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
      builder: (context) => Container(
        padding: EdgeInsets.only(bottom: context.mediaQuery.viewInsets.bottom),
        constraints: BoxConstraints(maxHeight: height ?? context.height * 0.9),
        child: child,
      ),
    );
  }
}
