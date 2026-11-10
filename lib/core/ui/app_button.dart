import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_haptics.dart';

/// Visual weight of an [AppButton].
enum AppButtonVariant {
  /// Filled, highest emphasis. One per screen region.
  primary,

  /// Outlined, medium emphasis.
  secondary,

  /// Text only, lowest emphasis.
  text,
}

/// Visual style of an [AppIconButton].
enum AppIconButtonVariant { standard, filled, tonal, outlined }

void _noop() {}

/// Wraps [onPressed] with light haptic feedback. Returns null when disabled.
VoidCallback? _withHaptics(VoidCallback? onPressed) {
  if (onPressed == null) return null;
  return () {
    AppHaptics.light();
    onPressed();
  };
}

/// Spinner that takes the colour of the button foreground it sits in.
class _InlineSpinner extends StatelessWidget {
  const _InlineSpinner();

  @override
  Widget build(BuildContext context) {
    final color =
        IconTheme.of(context).color ?? DefaultTextStyle.of(context).style.color;
    return SizedBox.square(
      dimension: AppSizes.icon,
      child: CircularProgressIndicator(
        strokeWidth: AppSizes.spinnerStroke,
        color: color,
      ),
    );
  }
}

/// Primary / secondary / text button with loading, disabled and haptic support.
///
/// * Minimum height 48dp, 12dp corners (from the theme).
/// * While [isLoading], the label stays laid out (just hidden) and the spinner
///   is overlaid, so the button never changes size.
/// * The icon-to-label gap is a fixed 8dp regardless of text scale.
/// * A loading button ignores taps but keeps its enabled colours.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.expand = false,
    this.destructive = false,
  });

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;

  /// Stretch to the full available width.
  final bool expand;

  /// Use error colours (delete, sign out, deactivate...).
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? effective = isLoading ? _noop : _withHaptics(onPressed);
    final style = destructive ? _destructiveStyle(context.colors) : null;
    final child = _content();

    final Widget button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
        onPressed: effective,
        style: style,
        child: child,
      ),
      AppButtonVariant.secondary => OutlinedButton(
        onPressed: effective,
        style: style,
        child: child,
      ),
      AppButtonVariant.text => TextButton(
        onPressed: effective,
        style: style,
        child: child,
      ),
    };
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _content() {
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: AppSizes.icon),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedOpacity(
          opacity: isLoading ? 0 : 1,
          duration: AppMotion.fast,
          child: row,
        ),
        if (isLoading) const _InlineSpinner(),
      ],
    );
  }

  ButtonStyle _destructiveStyle(ColorScheme scheme) {
    final disabledFg = scheme.onSurface.withValues(alpha: 0.38);
    final disabledBg = scheme.onSurface.withValues(alpha: 0.12);
    return switch (variant) {
      AppButtonVariant.primary => FilledButton.styleFrom(
        backgroundColor: scheme.error,
        foregroundColor: scheme.onError,
        disabledBackgroundColor: disabledBg,
        disabledForegroundColor: disabledFg,
      ),
      AppButtonVariant.secondary =>
        OutlinedButton.styleFrom(
          foregroundColor: scheme.error,
          disabledForegroundColor: disabledFg,
        ).copyWith(
          side: WidgetStateProperty.resolveWith(
            (states) => BorderSide(
              color: states.contains(WidgetState.disabled)
                  ? disabledBg
                  : scheme.error,
              width: 1.5,
            ),
          ),
        ),
      AppButtonVariant.text => TextButton.styleFrom(
        foregroundColor: scheme.error,
        disabledForegroundColor: disabledFg,
      ),
    };
  }
}

/// Icon-only button: 48x48dp target, tooltip (also the screen-reader label),
/// haptics and an inline loading state.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.variant = AppIconButtonVariant.standard,
    this.isLoading = false,
  });

  final IconData icon;

  /// Required: icon-only controls must be labelled for accessibility.
  final String tooltip;
  final VoidCallback? onPressed;
  final AppIconButtonVariant variant;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final VoidCallback? effective = isLoading ? _noop : _withHaptics(onPressed);
    final Widget glyph = isLoading ? const _InlineSpinner() : Icon(icon);

    return switch (variant) {
      AppIconButtonVariant.standard => IconButton(
        onPressed: effective,
        tooltip: tooltip,
        icon: glyph,
      ),
      AppIconButtonVariant.filled => IconButton.filled(
        onPressed: effective,
        tooltip: tooltip,
        icon: glyph,
      ),
      AppIconButtonVariant.tonal => IconButton.filledTonal(
        onPressed: effective,
        tooltip: tooltip,
        icon: glyph,
      ),
      AppIconButtonVariant.outlined => IconButton.outlined(
        onPressed: effective,
        tooltip: tooltip,
        icon: glyph,
      ),
    };
  }
}
