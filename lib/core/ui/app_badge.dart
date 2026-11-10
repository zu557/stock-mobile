import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Colour intent of an [AppBadge].
enum AppBadgeTone { neutral, primary, success, warning, error }

/// Small pill label for status ("Inactive", "Low stock", "3 new").
///
/// Colours come from the theme, so it stays legible in dark mode.
class AppBadge extends StatelessWidget {
  const AppBadge(this.label, {super.key, this.tone = AppBadgeTone.neutral});

  final String label;
  final AppBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final semantic = context.semantic;
    final (Color bg, Color fg) = switch (tone) {
      AppBadgeTone.neutral => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
      AppBadgeTone.primary => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      AppBadgeTone.success => (
        semantic.successContainer,
        semantic.onSuccessContainer,
      ),
      AppBadgeTone.warning => (
        semantic.warningContainer,
        semantic.onWarningContainer,
      ),
      AppBadgeTone.error => (scheme.errorContainer, scheme.onErrorContainer),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.labelSmall?.copyWith(color: fg),
        ),
      ),
    );
  }
}
