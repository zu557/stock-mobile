import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Pill drag handle shown at the top of every sheet.
class AppSheetHandle extends StatelessWidget {
  const AppSheetHandle({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.sm),
      child: Center(
        child: Container(
          width: AppSizes.dragHandleWidth,
          height: AppSizes.dragHandleHeight,
          decoration: BoxDecoration(
            color: context.colors.onSurfaceVariant.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
      ),
    ),
  );
}

/// The frosted-glass container behind every sheet.
///
/// Rounded top corners, a blurred, translucent surface (via [BackdropFilter]),
/// the drag handle, and keyboard avoidance: the whole sheet is lifted by
/// `viewInsets.bottom`, so content shrinks instead of overflowing.
class AppSheetSurface extends StatelessWidget {
  const AppSheetSurface({
    super.key,
    required this.child,
    this.showHandle = true,
    this.expandChild = false,
  });

  final Widget child;
  final bool showHandle;

  /// Fill the available height (draggable sheets) instead of shrink-wrapping.
  final bool expandChild;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(AppRadius.sheet),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        // A Material (not a ColoredBox) so ink splashes of children paint
        // above the sheet colour instead of being hidden beneath it.
        child: Material(
          color: context.colors.surfaceContainerLow.withValues(alpha: 0.92),
          child: Padding(
            padding: EdgeInsets.only(bottom: inset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (showHandle) const AppSheetHandle(),
                if (expandChild)
                  Expanded(child: child)
                else
                  Flexible(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Standard sheet layout: optional title, scrolling body, pinned footer.
///
/// The body scrolls inside a [Flexible], so tall forms and the on-screen
/// keyboard never cause an overflow, and the [footer] (usually the primary
/// button) stays visible. Bottom padding respects
/// `MediaQuery.paddingOf(context).bottom` (home indicator / gesture bar).
class AppSheetContent extends StatelessWidget {
  const AppSheetContent({
    super.key,
    required this.child,
    this.title,
    this.footer,
    this.scrollable = true,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
  });

  final Widget child;
  final String? title;

  /// Pinned below the body (for example a full-width [AppButton]).
  final Widget? footer;

  /// Wrap [child] in a scroll view. Set false when [child] is itself a
  /// scrollable (`ListView(shrinkWrap: true)`), which must then apply its own
  /// padding.
  final bool scrollable;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xs,
              AppSpacing.xl,
              AppSpacing.md,
            ),
            child: Semantics(
              header: true,
              child: Text(
                title!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.text.titleLarge,
              ),
            ),
          ),
        Flexible(
          child: scrollable
              ? SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: padding,
                  child: child,
                )
              : child,
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xl,
            footer == null ? 0 : AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.lg + safeBottom,
          ),
          child: footer,
        ),
      ],
    );
  }
}

/// Shows a modal bottom sheet using [showModalBottomSheet].
///
/// * `isScrollControlled: true` so the sheet can grow and rise above the
///   keyboard; capped at [AppSizes.sheetMaxWidth] on tablets.
/// * Edge-to-edge: the sheet runs under the system bars; only the top safe
///   area is respected here, the bottom one is handled by [AppSheetContent].
/// * Frosted-glass surface with blur behind the sheet, drag handle, and a
///   smooth emphasized slide-up.
/// * Uses the root navigator by default so the sheet covers the bottom
///   navigation bar rather than sitting above only the tab body.
///
/// Note: Flutter only blurs what is *behind the sheet surface*; the scrim above
/// the sheet is a plain dimmed barrier.
Future<T?> showAppModalSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool enableDrag = true,
  bool useRootNavigator = true,
}) {
  final scheme = Theme.of(context).colorScheme;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: useRootNavigator,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    elevation: 0,
    barrierColor: scheme.scrim.withValues(alpha: 0.4),
    constraints: const BoxConstraints(maxWidth: AppSizes.sheetMaxWidth),
    sheetAnimationStyle: AnimationStyle(
      duration: AppMotion.sheetEnter,
      reverseDuration: AppMotion.sheetExit,
      curve: Easing.emphasizedDecelerate,
      reverseCurve: Easing.emphasizedAccelerate,
    ),
    builder: (sheetContext) => AppSheetSurface(child: builder(sheetContext)),
  );
}

/// Modal sheet the user can drag between [minSize] and [maxSize] (fractions of
/// the screen height) with a long scrolling list.
///
/// [builder] receives the [ScrollController] that **must** be attached to the
/// primary scrollable (for example `ListView(controller: controller)`) so
/// dragging the list resizes the sheet. Add
/// `MediaQuery.paddingOf(context).bottom` to the list's bottom padding.
Future<T?> showAppDraggableSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext context, ScrollController controller)
  builder,
  double initialSize = 0.6,
  double minSize = 0.4,
  double maxSize = 0.95,
  bool useRootNavigator = true,
}) {
  final scheme = Theme.of(context).colorScheme;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    useRootNavigator: useRootNavigator,
    showDragHandle: false,
    backgroundColor: Colors.transparent,
    elevation: 0,
    barrierColor: scheme.scrim.withValues(alpha: 0.4),
    constraints: const BoxConstraints(maxWidth: AppSizes.sheetMaxWidth),
    sheetAnimationStyle: AnimationStyle(
      duration: AppMotion.sheetEnter,
      reverseDuration: AppMotion.sheetExit,
      curve: Easing.emphasizedDecelerate,
      reverseCurve: Easing.emphasizedAccelerate,
    ),
    builder: (sheetContext) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: initialSize,
      minChildSize: minSize,
      maxChildSize: maxSize,
      builder: (context, controller) => AppSheetSurface(
        expandChild: true,
        child: builder(context, controller),
      ),
    ),
  );
}

/// Persistent (non-modal) sheet attached to the nearest [Scaffold]. The page
/// behind stays interactive. [context] must sit below a [Scaffold].
PersistentBottomSheetController showAppPersistentSheet({
  required BuildContext context,
  required WidgetBuilder builder,
  bool enableDrag = true,
}) => Scaffold.of(context).showBottomSheet(
  (sheetContext) => AppSheetSurface(child: builder(sheetContext)),
  backgroundColor: Colors.transparent,
  elevation: 0,
  enableDrag: enableDrag,
  constraints: const BoxConstraints(maxWidth: AppSizes.sheetMaxWidth),
);

/// A docked bottom bar for pinned actions (checkout summary, bulk actions).
///
/// Use as `Scaffold.bottomNavigationBar` or inside a `Stack`. Renders edge to
/// edge, extends under the home indicator, and pads its content by the bottom
/// safe area.
class AppBottomShell extends StatelessWidget {
  const AppBottomShell({
    super.key,
    required this.child,
    this.showHandle = false,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.md,
      AppSpacing.lg,
      AppSpacing.md,
    ),
  });

  final Widget child;
  final bool showHandle;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: safeBottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showHandle) const AppSheetHandle(),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );
  }
}
