import 'package:flutter/foundation.dart';

class GlobalStateResetter {
  static final List<VoidCallback> _resetCallbacks = [];

  static void register(VoidCallback callback) {
    if (!_resetCallbacks.contains(callback)) {
      _resetCallbacks.add(callback);
    }
  }

  /// Clears all registered states.
  static void resetAll() {
    for (final callback in _resetCallbacks) {
      try {
        callback();
      } catch (_) {
      }
    }
  }
}
