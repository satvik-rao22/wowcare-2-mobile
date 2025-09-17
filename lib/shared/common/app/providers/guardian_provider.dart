import 'package:flutter/material.dart';
import 'package:wowcare/features/guardian/data/model/guardianDataModel.dart';

class GuardianProvider extends ChangeNotifier {
  GuardianDataModel? _guardian;

  GuardianDataModel? get guardian => _guardian;

  void initGuardian(GuardianDataModel guardian) {
    if (_guardian != guardian) _guardian = guardian;
  }

  set guardian(GuardianDataModel? guardian) {
    if (_guardian != guardian) {
      _guardian = guardian;

      Future.delayed(Duration.zero, notifyListeners);
    }
  }
}

