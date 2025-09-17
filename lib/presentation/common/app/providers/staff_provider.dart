
import 'package:flutter/material.dart';
import 'package:wowcare/features/user/data/model/StaffModel.dart';

class StaffProviders extends ChangeNotifier{

  StaffModel? _staff;

    StaffModel? get staff => _staff;


  void initStaff(StaffModel staff){
    if(_staff != staff) _staff = staff;
  }

  set employee(StaffModel? staff){
    if(_staff != staff) {
      _staff = staff;

      Future.delayed(Duration.zero, notifyListeners);
    }
  }

}
