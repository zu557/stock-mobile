import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child, {ThemeData? theme, double width = 400}) =>
    MaterialApp(
      theme: theme ?? AppTheme.light(),
      home: Scaffold(
        body: Center(
          child: SizedBox(width: width, child: child),
        ),
      ),
    );

void main() {
  group('AppTheme', () {
    for (final theme in [AppTheme.light(), AppTheme.dark()]) {
      final name = theme.brightness.name;

      test('$name: text uses scheme colours, never raw black/white', () {
        final scheme = theme.colorScheme;
        final styles = [
          theme.textTheme.headlineMedium,
          theme.textTheme.titleLarge,
          theme.textTheme.bodyLarge,
          theme.textTheme.bodyMedium,
          theme.textTheme.labelSmall,
        ];
        for (final style in styles) {
          expect(style!.color, isNot(Colors.black));
          expect(style.color, isNot(Colors.white));
        }
        expect(theme.textTheme.bodyLarge!.color, scheme.onSurface);
        expect(theme.textTheme.bodyMedium!.color, scheme.onSurface);
      });

      test('$name: line heights stay within 1.2-1.4', () {
        final t = theme.textTheme;
        for (final style in [
          t.headlineMedium,
          t.titleLarge,
          t.titleMedium,
          t.bodyLarge,
          t.bodyMedium,
          t.labelSmall,
        ]) {
          expect(style!.height, inInclusiveRange(1.2, 1.4));
        }
      });
    }
  });

  group('AppButton', () {
    testWidgets('meets the 48dp minimum height for every variant', (
      tester,
    ) async {
      for (final variant in AppButtonVariant.values) {
        await tester.pumpWidget(
          _app(AppButton(label: 'Save', variant: variant, onPressed: () {})),
        );
        expect(
          tester.getSize(find.byType(AppButton)).height,
          greaterThanOrEqualTo(48),
          reason: variant.name,
        );
      }
    });

    testWidgets('loading does not change size and blocks taps', (tester) async {
      var taps = 0;
      Widget build(bool loading) => _app(
        Align(
          alignment: Alignment.centerLeft,
          child: AppButton(
            label: 'Sign in',
            icon: Icons.login,
            isLoading: loading,
            onPressed: () => taps++,
          ),
        ),
      );

      await tester.pumpWidget(build(false));
      final idle = tester.getSize(find.byType(AppButton));

      await tester.pumpWidget(build(true));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.getSize(find.byType(AppButton)), idle);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.byType(AppButton));
      expect(taps, 0);
    });

    testWidgets('null onPressed disables the button', (tester) async {
      await tester.pumpWidget(
        _app(const AppButton(label: 'Save', onPressed: null)),
      );
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('tap fires light haptic feedback and the callback', (
      tester,
    ) async {
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            calls.add(call.arguments as String);
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      var pressed = false;
      await tester.pumpWidget(
        _app(AppButton(label: 'Go', onPressed: () => pressed = true)),
      );
      await tester.tap(find.byType(AppButton));

      expect(pressed, isTrue);
      expect(calls, ['HapticFeedbackType.lightImpact']);
    });

    testWidgets('long label ellipsizes without overflow in a narrow slot', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(
          AppButton(
            label: 'A very long button label that cannot possibly fit',
            icon: Icons.add,
            expand: true,
            onPressed: () {},
          ),
          width: 140,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('AppIconButton', () {
    testWidgets('is at least 48x48 and exposes its tooltip', (tester) async {
      await tester.pumpWidget(
        _app(
          AppIconButton(icon: Icons.edit, tooltip: 'Edit', onPressed: () {}),
        ),
      );
      final size = tester.getSize(find.byType(IconButton));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
      expect(find.byTooltip('Edit'), findsOneWidget);
    });
  });

  group('AppTextField', () {
    testWidgets('showing a validation error does not change the field height', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        _app(
          Form(
            key: formKey,
            child: AppTextField(
              label: 'Email',
              validator: (v) => (v ?? '').isEmpty ? 'Required' : null,
            ),
          ),
        ),
      );
      final before = tester.getSize(find.byType(AppTextField));

      formKey.currentState!.validate();
      await tester.pump();

      expect(find.text('Required'), findsOneWidget);
      expect(tester.getSize(find.byType(AppTextField)), before);
    });

    testWidgets('password field toggles visibility', (tester) async {
      await tester.pumpWidget(_app(const AppPasswordField()));
      EditableText editable() =>
          tester.widget<EditableText>(find.byType(EditableText));

      expect(editable().obscureText, isTrue);
      await tester.tap(find.byTooltip('Show password'));
      await tester.pump();
      expect(editable().obscureText, isFalse);
      expect(find.byTooltip('Hide password'), findsOneWidget);
    });
  });

  group('AppListTile', () {
    testWidgets('ellipsizes long text and composes trailing slot', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        _app(
          AppListTile(
            title: 'An extremely long product name ' * 6,
            subtitle: 'An equally long subtitle describing the product ' * 6,
            leading: const Icon(Icons.inventory_2_outlined),
            badge: const AppBadge('Inactive', tone: AppBadgeTone.error),
            showChevron: true,
            onTap: () => tapped = true,
          ),
          width: 300,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Inactive'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

      await tester.tap(find.byType(AppListTile));
      expect(tapped, isTrue);
    });

    testWidgets('switch tile toggles from a tap on the row', (tester) async {
      var value = false;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) => AppSwitchTile(
              title: 'Notifications',
              value: value,
              onChanged: (next) => setState(() => value = next),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Notifications'));
      await tester.pump();
      expect(value, isTrue);
    });
  });

  group('Bottom sheets', () {
    testWidgets('modal sheet shows handle, blur and survives the keyboard', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: AppButton(
                  label: 'Open',
                  onPressed: () => showAppModalSheet<void>(
                    context: context,
                    builder: (_) => AppSheetContent(
                      title: 'New product',
                      footer: AppButton(
                        label: 'Save',
                        expand: true,
                        onPressed: () {},
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < 12; i++)
                            AppTextField(label: 'Field $i'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('New product'), findsOneWidget);
      expect(find.byType(AppSheetHandle), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      // Simulate a 300dp keyboard: content must shrink, not overflow, and the
      // pinned footer must remain on screen.
      tester.view.viewInsets = const FakeViewPadding(bottom: 600);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final saveBottom = tester.getBottomLeft(find.text('Save')).dy;
      expect(saveBottom, lessThanOrEqualTo(800 - 300));
    });

    testWidgets('bottom shell pads by the bottom safe area', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 2;
      tester.view.padding = const FakeViewPadding(bottom: 68);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: SizedBox.expand(),
            bottomNavigationBar: AppBottomShell(child: Text('Total')),
          ),
        ),
      );

      // 800dp tall; shell content ends 34dp (home indicator) + 12dp padding
      // above the bottom edge.
      final bottom = tester.getBottomLeft(find.text('Total')).dy;
      expect(bottom, lessThanOrEqualTo(800 - 34 - 12 + 1));
    });
  });
}
