import 'package:flutter/material.dart';

import '../../../../domain/features/staff_classroom/entities/staff_model.dart';

class StaffProviders extends ChangeNotifier {
  StaffModel? _staff;

  StaffModel? get staff => _staff;

  void initStaff(StaffModel staff) {
    if (_staff != staff) _staff = staff;
  }

  set employee(StaffModel? staff) {
    if (_staff != staff) {
      _staff = staff;

      Future.delayed(Duration.zero, notifyListeners);
    }
  }
}
