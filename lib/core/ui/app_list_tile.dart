import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_badge.dart';
import 'app_haptics.dart';

/// Standard / actionable list row.
///
/// * Bold `titleMedium` title, muted `bodyMedium` subtitle (both set by the
///   theme's `ListTileThemeData`), each ellipsized.
/// * 16/8 content padding and a 12dp shape so the ink splash is clipped.
/// * Trailing slot composes, in order: [badge], [trailing], chevron. They sit
///   in a shrink-wrapped row, so they can't push the title off-screen.
/// * Tappable only when [onTap] or [onLongPress] is set.
class AppListTile extends StatelessWidget {
  const AppListTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.badge,
    this.showChevron = false,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.selected = false,
    this.dense = false,
    this.subtitleMaxLines = 2,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;

  /// Status pill shown before [trailing].
  final AppBadge? badge;

  /// Adds a trailing chevron (navigation affordance).
  final bool showChevron;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enabled;
  final bool selected;

  /// Tighter vertical padding for dense lists.
  final bool dense;
  final int subtitleMaxLines;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final trailingItems = <Widget>[
      ?badge,
      ?trailing,
      if (showChevron)
        Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
    ];

    return ListTile(
      enabled: enabled,
      selected: selected,
      selectedTileColor: scheme.primaryContainer.withValues(alpha: 0.4),
      selectedColor: scheme.onPrimaryContainer,
      onTap: onTap,
      onLongPress: onLongPress,
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: dense ? AppSpacing.xs : AppSpacing.sm,
      ),
      minVerticalPadding: dense ? AppSpacing.xs : AppSpacing.sm,
      leading: leading,
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              maxLines: subtitleMaxLines,
              overflow: TextOverflow.ellipsis,
            ),
      isThreeLine: subtitle != null && subtitleMaxLines > 1,
      trailing: trailingItems.isEmpty ? null : _Trailing(items: trailingItems),
    );
  }
}

class _Trailing extends StatelessWidget {
  const _Trailing({required this.items});
  final List<Widget> items;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) children.add(const SizedBox(width: AppSpacing.sm));
      children.add(items[i]);
    }
    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }
}

/// A tile with a trailing [Switch]. Tapping anywhere on the row toggles it.
class AppSwitchTile extends StatelessWidget {
  const AppSwitchTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final bool value;

  /// Null disables the tile.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    value: value,
    onChanged: onChanged == null
        ? null
        : (next) {
            AppHaptics.selection();
            onChanged!(next);
          },
    secondary: leading,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.xs,
    ),
    title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
    subtitle: subtitle == null
        ? null
        : Text(subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis),
  );
}
