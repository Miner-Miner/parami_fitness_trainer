// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:parami_fitness_trainer/src/app.dart';
import 'package:parami_fitness_trainer/src/core/session_store.dart';

void main() {
  testWidgets('shows the trainer sign-in screen after the splash screen', (
    tester,
  ) async {
    await tester.pumpWidget(TrainerApp(sessionStore: SessionStore()));

    expect(find.text('PARAMI'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1600));
    expect(find.text('Trainer sign in'), findsOneWidget);
  });
}
