import 'package:flutter/material.dart';

/// A mixin to prevent the "Defunct Element" assertion error.
///
/// It overrides [setState] to automatically check if the widget is still
/// in the tree before attempting to trigger a rebuild.
mixin SafeStateMixin<T extends StatefulWidget> on State<T> {
  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  /// An explicitly named version for use in async blocks for better readability.
  /// Usage: `await someLongTask(); safeSetState(() => data = result);`
  void safeSetState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }
}
