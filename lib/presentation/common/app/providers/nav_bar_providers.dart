import 'package:flutter/material.dart';

class NavBarHeightProvider with ChangeNotifier {
  double _height = 0.0;

  double get height => _height;

  set height(double newHeight) {
    if (_height != newHeight) {
      _height = newHeight;
      notifyListeners();
    }
  }
}

