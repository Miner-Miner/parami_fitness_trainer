import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parami_fitness_trainer/src/app.dart';
import 'package:parami_fitness_trainer/src/core/api_client.dart';
import 'package:parami_fitness_trainer/src/screens/home_shell.dart';
import 'package:parami_fitness_trainer/src/core/session_store.dart';
import 'package:parami_fitness_trainer/src/theme/app_theme.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('login picker switches all three themes without clearing input', (
    tester,
  ) async {
    final store = SessionStore();
    await tester.pumpWidget(TrainerApp(sessionStore: store));
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'trainer');
    for (final theme in [
      TrainerTheme.gold,
      TrainerTheme.roseGold,
      TrainerTheme.monochrome,
    ]) {
      await tester.ensureVisible(find.text('Theme'));
      await tester.tap(find.text('Theme'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(theme.label));
      await tester.pumpAndSettle();
      expect(store.theme, theme);
      final context = tester.element(find.byType(TextFormField).first);
      expect(Theme.of(context).colorScheme.primary, theme.accent);
      expect(AppPalette.of(context).mist, theme.background);
      expect(find.text('trainer'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      await tester.ensureVisible(find.byTooltip('Switch to dark mode'));
      await tester.tap(find.byTooltip('Switch to dark mode'));
      await tester.pumpAndSettle();
      expect(Theme.of(context).brightness, Brightness.dark);
      expect(AppPalette.of(context).card.computeLuminance(), lessThan(0.1));
      expect(find.text('trainer'), findsOneWidget);
      expect(store.theme, theme);
      await tester.tap(find.byTooltip('Switch to light mode'));
      await tester.pumpAndSettle();
      expect(Theme.of(context).brightness, Brightness.light);

      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'navigation styles switch while keeping the selected profile page',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = SessionStore();
      await store.save(
        const TrainerSession(
          baseUrl: 'https://example.com',
          database: 'test',
          sessionId: 'test',
          userId: 1,
          name: 'Trainer',
          login: 'trainer',
          memberId: 'T1',
        ),
      );
      await tester.pumpWidget(TrainerApp(sessionStore: store));
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);
      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      final profileState = tester.state(find.byType(ProfileScreen));
      for (final theme in [
        TrainerTheme.gold,
        TrainerTheme.roseGold,
        TrainerTheme.monochrome,
      ]) {
        await tester.tap(find.text('Theme'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(theme.label));
        await tester.pumpAndSettle();
        expect(find.text('Your profile'), findsOneWidget);
        final profileContext = tester.element(find.text('Your profile'));
        final activeTheme = Theme.of(profileContext);
        expect(activeTheme.appBarTheme.backgroundColor, theme.accent);
        expect(activeTheme.textTheme.titleLarge?.color, theme.accent);
        final header = tester.widget<Text>(find.text('Your profile'));
        expect(header.style?.color, Colors.white);
        final headerContainer = tester
            .widgetList<Container>(
              find.ancestor(
                of: find.text('Your profile'),
                matching: find.byType(Container),
              ),
            )
            .firstWhere(
              (container) =>
                  container.decoration is BoxDecoration &&
                  (container.decoration as BoxDecoration).gradient != null,
            );
        expect(
          ((headerContainer.decoration as BoxDecoration).gradient
                  as LinearGradient)
              .colors
              .last,
          theme.accent,
        );

        expect(tester.state(find.byType(ProfileScreen)), same(profileState));
        expect(
          find.byType(NavigationBar),
          theme == TrainerTheme.monochrome ? findsOneWidget : findsNothing,
        );
        expect(
          find.byType(NavigationRail),
          theme == TrainerTheme.gold ? findsOneWidget : findsNothing,
        );
        if (theme == TrainerTheme.roseGold) {
          await tester.tap(find.byTooltip('Open navigation menu'));
          await tester.pumpAndSettle();
          expect(find.text('Trainer workspace'), findsOneWidget);
          await tester.tap(find.widgetWithText(ListTile, 'Profile'));
          await tester.pumpAndSettle();
        }
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('profile hides account IDs in every theme and mode', (
    tester,
  ) async {
    for (final theme in TrainerTheme.values) {
      for (final dark in [false, true]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildAppTheme(theme, dark: dark),
            home: Scaffold(
              body: ProfileScreen(
                api: _ProfileApi(),
                sessionStore: SessionStore(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Profile details'), findsOneWidget);
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Member ID'), findsNothing);
        expect(find.text('User ID'), findsNothing);
        expect(find.text('PRIVATE-MEMBER-ID'), findsNothing);
        expect(find.text('123456789'), findsNothing);
        expect(tester.takeException(), isNull);
      }
    }
  });

  test('theme survives sign-out and restoration', () async {
    final store = SessionStore();
    await store.save(
      const TrainerSession(
        baseUrl: 'https://example.com',
        database: 'test',
        sessionId: 'test',
        userId: 1,
        name: 'Trainer',
        login: 'trainer',
        memberId: 'T1',
      ),
    );
    await store.setTheme(TrainerTheme.roseGold);
    await store.setDarkMode(true);
    await store.signOut();
    final restored = SessionStore();
    await restored.restore();
    expect(restored.theme, TrainerTheme.roseGold);
    expect(restored.session, isNull);
    expect(restored.isDark, isTrue);
  });
}

class _ProfileApi extends ApiClient {
  _ProfileApi()
    : super(
        const TrainerSession(
          baseUrl: 'https://example.com',
          database: 'test',
          sessionId: 'test',
          userId: 123456789,
          name: 'Trainer',
          login: 'trainer@example.com',
          memberId: 'PRIVATE-MEMBER-ID',
        ),
      );
  @override
  Future<Map<String, dynamic>> profile() async => {
    'name': 'Trainer',
    'email': 'trainer@example.com',
    'member_id': 'PRIVATE-MEMBER-ID',
    'user_id': 123456789,
  };
}
