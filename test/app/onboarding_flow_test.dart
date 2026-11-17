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
    expect(find.text('Add your first expense'), findsNothing);
  });

  testWidgets('walks through onboarding and lands on the expense list', (
    tester,
  ) async {
    await pumpRouterApp(tester, onboarding: onboarding);

    await tapText(tester, 'Get started');
    expect(find.text('Add expenses your way'), findsOneWidget);

    await tapText(tester, 'Next');
    expect(find.text('See where your money goes'), findsOneWidget);

    await tapText(tester, 'Next');
    expect(find.text('Private by design'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);

    await tapText(tester, 'Get started');
    expect(find.text('Add your first expense'), findsOneWidget);
    expect(onboarding.isCompleted, isTrue);
  });

  testWidgets('Skip finishes onboarding right away', (tester) async {
    await pumpRouterApp(tester, onboarding: onboarding);

    await tapText(tester, 'Get started');
    await tapText(tester, 'Skip');

    expect(find.text('Add your first expense'), findsOneWidget);
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
    );

    expect(find.text('Welcome to SpendWise IQ'), findsNothing);
    expect(find.text('Add your first expense'), findsOneWidget);
  });
}
