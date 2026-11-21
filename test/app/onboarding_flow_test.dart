import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fakes.dart';
import '../support/pump_app.dart';

void main() {
  late FakeOnboardingRepository onboarding;

  setUp(() => onboarding = FakeOnboardingRepository());

  testWidgets('a fresh install shows the welcome screen first', (tester) async {
    await pumpRouterApp(tester, onboarding: onboarding);

    expect(find.text('Welcome to SpendWise IQ'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('Let\'s add your first expense'), findsNothing);
  });

  testWidgets('walks through onboarding and lands on Home', (tester) async {
    await pumpRouterApp(tester, onboarding: onboarding);

    await tapText(tester, 'Get started');
    expect(find.text('Add expenses your way'), findsOneWidget);

    await tapText(tester, 'Next');
    expect(find.text('See where your money goes'), findsOneWidget);

    await tapText(tester, 'Next');
    expect(find.text('Private by design'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);

    await tapText(tester, 'Get started');
    expect(find.text('Let\'s add your first expense'), findsOneWidget);
    expect(onboarding.isCompleted, isTrue);
  });

  testWidgets('Skip finishes onboarding right away', (tester) async {
    await pumpRouterApp(tester, onboarding: onboarding);

    await tapText(tester, 'Get started');
    await tapText(tester, 'Skip');

    expect(find.text('Let\'s add your first expense'), findsOneWidget);
    expect(onboarding.isCompleted, isTrue);
  });

  testWidgets('the back button returns to the previous slide', (tester) async {
    await pumpRouterApp(tester, onboarding: onboarding);

    await tapText(tester, 'Get started');
    expect(find.byTooltip('Back'), findsNothing);

    await tapText(tester, 'Next');
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Add expenses your way'), findsOneWidget);
  });

  testWidgets('never shows the welcome screen again once completed', (
    tester,
  ) async {
    await pumpRouterApp(
      tester,
      onboarding: FakeOnboardingRepository(completed: true),
      startOnHome: true,
    );

    expect(find.text('Welcome to SpendWise IQ'), findsNothing);
    expect(find.text('Let\'s add your first expense'), findsOneWidget);
  });

  Future<void> toLastSlide(WidgetTester tester) async {
    await tapText(tester, 'Get started');
    await tapText(tester, 'Next');
    await tapText(tester, 'Next');
  }

  testWidgets('the last screen asks for an optional first name', (
    tester,
  ) async {
    await pumpRouterApp(tester, onboarding: onboarding);
    await toLastSlide(tester);

    expect(find.text('Your first name (optional)'), findsOneWidget);
    expect(find.textContaining('It stays on your phone'), findsOneWidget);
  });

  testWidgets('a name typed there greets the user on Home', (tester) async {
    final profile = FakeProfileRepository();
    await pumpRouterApp(tester, onboarding: onboarding, profile: profile);
    await toLastSlide(tester);

    await tester.enterText(find.byType(TextField), 'Maja');
    await tapText(tester, 'Get started');

    expect(profile.stored, 'Maja');
    expect(find.textContaining(', Maja'), findsOneWidget);
  });

  testWidgets('no name is fine, and the greeting has none', (tester) async {
    final profile = FakeProfileRepository();
    await pumpRouterApp(tester, onboarding: onboarding, profile: profile);
    await toLastSlide(tester);

    await tapText(tester, 'Get started');

    expect(profile.stored, isEmpty);
    expect(find.textContaining('Good '), findsOneWidget);
    // No name after the greeting.
    expect(
      find.byWidgetPredicate(
        (w) => w is Text && RegExp(r'^Good w+, ').hasMatch(w.data ?? ''),
      ),
      findsNothing,
    );
  });

  testWidgets('the name field leaves room on a short phone with the keyboard', (
    tester,
  ) async {
    await pumpRouterApp(
      tester,
      onboarding: onboarding,
      screenSize: const Size(360, 560),
    );
    await toLastSlide(tester);

    await tester.showKeyboard(find.byType(TextField));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
