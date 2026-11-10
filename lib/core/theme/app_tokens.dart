/// Design tokens shared by the theme and the UI component library.
///
/// Keep raw numbers out of widgets: reference these instead so spacing, radii
/// and motion stay consistent and can be tuned in one place.
library;

/// 4dp-based spacing scale.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Corner radii. Interactive controls use [md] (12dp) or larger.
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double sheet = 28;
  static const double pill = 999;
}

/// Sizing constants.
abstract final class AppSizes {
  /// Minimum touch target (Material and Apple HIG both land near 44-48dp).
  static const double minTouchTarget = 48;
  static const double icon = 20;
  static const double spinnerStroke = 2.5;
  static const double dragHandleWidth = 36;
  static const double dragHandleHeight = 4;
  static const double sheetMaxWidth = 640;
}

/// Animation timings and curves.
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration sheetEnter = Duration(milliseconds: 350);
  static const Duration sheetExit = Duration(milliseconds: 250);
}
