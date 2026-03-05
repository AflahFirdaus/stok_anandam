import 'package:flutter/foundation.dart';

/// Centralized utility to reset all static/cached states across the app.
/// Pages should register their reset logic here.
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
        // Ignore errors in individual resets
      }
    }
    // We don't clear the list itself because we want these hooks 
    // to stay active for the entire app lifecycle
  }
}
