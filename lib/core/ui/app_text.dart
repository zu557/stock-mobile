import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The five text roles the app uses. Each maps to one `TextTheme` token.
enum AppTextVariant {
  /// `headlineMedium`: screen / hero headings.
  headline,

  /// `titleLarge`: section and sheet titles.
  title,

  /// `bodyLarge`: primary reading text.
  body,

  /// `bodyMedium` in `onSurfaceVariant`: supporting copy.
  secondary,

  /// `labelSmall` in `onSurfaceVariant`: captions and metadata.
  caption,
}

/// Themed text with safe overflow behaviour.
///
/// Colours come from the [ColorScheme] (never raw black/white). Headings and
/// captions are line-limited by default and ellipsize; body text is unbounded.
/// Pass [maxLines] to override.
class AppText extends StatelessWidget {
  const AppText(
    this.data, {
    super.key,
    this.variant = AppTextVariant.body,
    this.maxLines,
    this.textAlign,
    this.color,
  });

  final String data;
  final AppTextVariant variant;
  final int? maxLines;
  final TextAlign? textAlign;

  /// Optional colour override; prefer a scheme colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final scheme = context.colors;
    final (TextStyle? style, int? defaultLines) = switch (variant) {
      AppTextVariant.headline => (text.headlineMedium, 2),
      AppTextVariant.title => (text.titleLarge, 2),
      AppTextVariant.body => (text.bodyLarge, null),
      AppTextVariant.secondary => (
        text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        3,
      ),
      AppTextVariant.caption => (
        text.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
        1,
      ),
    };
    return Text(
      data,
      maxLines: maxLines ?? defaultLines,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
      style: color == null ? style : style?.copyWith(color: color),
    );
  }
}
