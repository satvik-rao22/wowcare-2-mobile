import 'dart:async';

import 'package:flutter/widgets.dart';

/// Single source for the debounced-search pattern previously hand-rolled in the
/// attendance absent views (Task 07 / Mandate 6). Mix into a [State], call
/// [debounceSearch] from the search listener, and [cancelSearchDebounce] in
/// `dispose`. The default 200ms delay matches the original call sites; override
/// [searchDebounceDelay] if a screen needs a different delay.
mixin DebouncedSearchMixin<T extends StatefulWidget> on State<T> {
  Timer? _searchDebounceTimer;

  /// Debounce delay. Defaults to the 200ms used by the original absent-view
  /// implementations; override per screen if a different delay is required.
  Duration get searchDebounceDelay => const Duration(milliseconds: 200);

  /// Cancels any pending run and schedules [action] after [searchDebounceDelay].
  /// [action] is skipped if the widget is no longer mounted when it fires.
  void debounceSearch(VoidCallback action) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(searchDebounceDelay, () {
      if (!mounted) return;
      action();
    });
  }

  /// Cancels any pending debounced run. Call from `dispose`.
  void cancelSearchDebounce() {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = null;
  }
}
