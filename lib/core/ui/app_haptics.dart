import 'package:flutter/services.dart';

/// Single place for haptic feedback so it can be tuned or disabled globally.
abstract final class AppHaptics {
  /// Subtle tap feedback used by buttons.
  static void light() => HapticFeedback.lightImpact();

  /// Feedback for toggles and selection changes.
  static void selection() => HapticFeedback.selectionClick();
}
