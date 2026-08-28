import 'package:flutter/foundation.dart';

void debugLog(String message) {
  if (kDebugMode) debugPrint(message);
}

/// Actionable errors that must stay visible outside debug builds.
void errorLog(String message) {
  debugPrint(message);
}
