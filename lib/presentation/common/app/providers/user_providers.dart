
import 'package:wowcare/src/auth/data/Models/user_model.dart';
import 'package:flutter/material.dart';

class UserProviders extends ChangeNotifier{

  SecurityUserModel? _user;

    SecurityUserModel? get user => _user;


  void initUser( SecurityUserModel user){
    if(_user != user) _user = user;
  }

  set user(SecurityUserModel? user){
    if(_user != user) {
      _user = user;

      Future.delayed(Duration.zero, notifyListeners);
    }
  }

}
