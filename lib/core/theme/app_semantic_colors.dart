import 'package:flutter/material.dart';

/// Status colours that [ColorScheme] does not provide (success / warning).
///
/// Registered on [ThemeData.extensions] by `AppTheme`, so they follow
/// light/dark mode. Read them with `context.semantic`.
@immutable
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
  });

  const AppSemanticColors.light()
    : success = const Color(0xFF2E7D32),
      successContainer = const Color(0xFFC8E6C9),
      onSuccessContainer = const Color(0xFF0B3D12),
      warning = const Color(0xFFB26A00),
      warningContainer = const Color(0xFFFFE0B2),
      onWarningContainer = const Color(0xFF4A2800);

  const AppSemanticColors.dark()
    : success = const Color(0xFF81C784),
      successContainer = const Color(0xFF1B4D20),
      onSuccessContainer = const Color(0xFFC8E6C9),
      warning = const Color(0xFFFFB74D),
      warningContainer = const Color(0xFF5C3A00),
      onWarningContainer = const Color(0xFFFFE0B2);

  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? warningContainer,
    Color? onWarningContainer,
  }) => AppSemanticColors(
    success: success ?? this.success,
    successContainer: successContainer ?? this.successContainer,
    onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
    warning: warning ?? this.warning,
    warningContainer: warningContainer ?? this.warningContainer,
    onWarningContainer: onWarningContainer ?? this.onWarningContainer,
  );

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(
        successContainer,
        other.successContainer,
        t,
      )!,
      onSuccessContainer: Color.lerp(
        onSuccessContainer,
        other.onSuccessContainer,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(
        warningContainer,
        other.warningContainer,
        t,
      )!,
      onWarningContainer: Color.lerp(
        onWarningContainer,
        other.onWarningContainer,
        t,
      )!,
    );
  }
}
