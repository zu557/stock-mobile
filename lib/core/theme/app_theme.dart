import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_semantic_colors.dart';
import 'app_tokens.dart';

export 'app_semantic_colors.dart';
export 'app_tokens.dart';

/// Builds the app's Material 3 [ThemeData] (light and dark).
///
/// Every component theme is derived from the [ColorScheme]; no widget should
/// need a hard-coded colour. Component widgets in `core/ui` rely on these
/// themes, and plain Material widgets (`ListTile`, `TextField`, `FilledButton`,
/// `Card`, dialogs, sheets) pick up the same look automatically.
abstract final class AppTheme {
  static const Color seed = Color(0xFF087E70);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final text = _textTheme(base.textTheme);
    final isDark = brightness == Brightness.dark;

    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    );
    const buttonMinSize = Size(64, AppSizes.minTouchTarget);
    final buttonText = text.labelLarge;
    final disabledFg = scheme.onSurface.withValues(alpha: 0.38);
    final disabledBg = scheme.onSurface.withValues(alpha: 0.12);

    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide(color: color, width: width),
    );

    final idleBorder = scheme.outline.withValues(alpha: 0.6);

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      textTheme: text,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      splashColor: scheme.primary.withValues(alpha: 0.10),
      highlightColor: scheme.primary.withValues(alpha: 0.05),
      dividerColor: scheme.outlineVariant,
      extensions: <ThemeExtension<dynamic>>[
        isDark
            ? const AppSemanticColors.dark()
            : const AppSemanticColors.light(),
      ],

      // ---- Buttons -------------------------------------------------------
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonMinSize,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          shape: controlShape,
          textStyle: buttonText,
          disabledBackgroundColor: disabledBg,
          disabledForegroundColor: disabledFg,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style:
            OutlinedButton.styleFrom(
              minimumSize: buttonMinSize,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.md,
              ),
              shape: controlShape,
              textStyle: buttonText,
              disabledForegroundColor: disabledFg,
            ).copyWith(
              side: WidgetStateProperty.resolveWith(
                (states) => BorderSide(
                  color: states.contains(WidgetState.disabled)
                      ? disabledBg
                      : states.contains(WidgetState.focused)
                      ? scheme.primary
                      : scheme.outline,
                  width: 1.5,
                ),
              ),
            ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: buttonMinSize,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: controlShape,
          textStyle: buttonText,
          disabledForegroundColor: disabledFg,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size.square(AppSizes.minTouchTarget),
          padding: const EdgeInsets.all(AppSpacing.md),
          shape: controlShape,
          disabledForegroundColor: disabledFg,
        ),
      ),

      // ---- Inputs --------------------------------------------------------
      inputDecorationTheme: InputDecorationThemeData(
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: 14,
        ),
        border: border(idleBorder, 1),
        enabledBorder: border(idleBorder, 1),
        disabledBorder: border(idleBorder.withValues(alpha: 0.3), 1),
        focusedBorder: border(scheme.primary, 1.5),
        errorBorder: border(scheme.error, 1),
        focusedErrorBorder: border(scheme.error, 1.5),
        labelStyle: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith(
          (states) => (text.bodyLarge ?? const TextStyle()).copyWith(
            color: states.contains(WidgetState.error)
                ? scheme.error
                : states.contains(WidgetState.focused)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
        hintStyle: text.bodyLarge?.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
        helperStyle: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        errorStyle: text.bodySmall?.copyWith(color: scheme.error),
        helperMaxLines: 2,
        errorMaxLines: 2,
        prefixIconColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.error)
              ? scheme.error
              : states.contains(WidgetState.focused)
              ? scheme.primary
              : scheme.onSurfaceVariant,
        ),
        suffixIconColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.error)
              ? scheme.error
              : scheme.onSurfaceVariant,
        ),
      ),

      // ---- List tiles ----------------------------------------------------
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        minVerticalPadding: AppSpacing.sm,
        horizontalTitleGap: AppSpacing.lg,
        shape: controlShape,
        iconColor: scheme.onSurfaceVariant,
        titleTextStyle: text.titleMedium?.copyWith(color: scheme.onSurface),
        subtitleTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        leadingAndTrailingTextStyle: text.labelMedium?.copyWith(
          color: scheme.onSurfaceVariant,
        ),
      ),

      // ---- Surfaces ------------------------------------------------------
      appBarTheme: AppBarThemeData(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sheet),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleSize: const Size(
          AppSizes.dragHandleWidth,
          AppSizes.dragHandleHeight,
        ),
        dragHandleColor: scheme.onSurfaceVariant.withValues(alpha: 0.4),
        clipBehavior: Clip.antiAlias,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: controlShape,
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),
    );
  }

  /// Strict type scale. Line heights stay within 1.2-1.4 so glyphs never clip,
  /// and colours come from the scheme (never raw black/white).
  static TextTheme _textTheme(TextTheme base) {
    TextStyle? s(
      TextStyle? style, {
      FontWeight? weight,
      required double height,
      double? spacing,
    }) => style?.copyWith(
      fontWeight: weight,
      height: height,
      letterSpacing: spacing,
    );

    return base.copyWith(
      headlineLarge: s(
        base.headlineLarge,
        weight: FontWeight.w700,
        height: 1.2,
        spacing: -0.3,
      ),
      headlineMedium: s(
        base.headlineMedium,
        weight: FontWeight.w700,
        height: 1.25,
        spacing: -0.2,
      ),
      headlineSmall: s(
        base.headlineSmall,
        weight: FontWeight.w700,
        height: 1.3,
        spacing: -0.1,
      ),
      titleLarge: s(
        base.titleLarge,
        weight: FontWeight.w600,
        height: 1.27,
        spacing: 0,
      ),
      titleMedium: s(
        base.titleMedium,
        weight: FontWeight.w600,
        height: 1.4,
        spacing: 0.1,
      ),
      titleSmall: s(
        base.titleSmall,
        weight: FontWeight.w600,
        height: 1.35,
        spacing: 0.1,
      ),
      bodyLarge: s(
        base.bodyLarge,
        weight: FontWeight.w400,
        height: 1.4,
        spacing: 0.15,
      ),
      bodyMedium: s(
        base.bodyMedium,
        weight: FontWeight.w400,
        height: 1.4,
        spacing: 0.2,
      ),
      bodySmall: s(
        base.bodySmall,
        weight: FontWeight.w400,
        height: 1.35,
        spacing: 0.3,
      ),
      labelLarge: s(
        base.labelLarge,
        weight: FontWeight.w600,
        height: 1.3,
        spacing: 0.1,
      ),
      labelMedium: s(
        base.labelMedium,
        weight: FontWeight.w600,
        height: 1.3,
        spacing: 0.4,
      ),
      labelSmall: s(
        base.labelSmall,
        weight: FontWeight.w600,
        height: 1.3,
        spacing: 0.5,
      ),
    );
  }
}

/// Short accessors for theme data, so widgets stay readable.
extension AppThemeContext on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;

  /// Success / warning colours. Falls back to light values if the extension is
  /// missing (for example in a bare `MaterialApp` in a test).
  AppSemanticColors get semantic =>
      Theme.of(this).extension<AppSemanticColors>() ??
      const AppSemanticColors.light();
}
