import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/app/app_router.dart';
import 'package:smart_expense_tracker/core/theme/app_theme.dart';
import 'package:smart_expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:smart_expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:smart_expense_tracker/features/onboarding/domain/repositories/onboarding_repository.dart';

import '../support/fakes.dart';

void main() {
  late FakeOnboardingRepository onboarding;

  Future<void> pumpApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<OnboardingRepository>.value(value: onboarding),
          RepositoryProvider<ExpenseRepository>.value(
            value: FakeExpenseRepository(),
          ),
          RepositoryProvider<CategoryRepository>.value(
            value: FakeCategoryRepository(),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: createRouter(onboarding: onboarding),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  setUp(() => onboarding = FakeOnboardingRepository());

  testWidgets('a fresh install shows the welcome screen first', (tester) async {
    await pumpApp(tester);

    expect(find.text('Welcome to SpendWise IQ'), findsOneWidget);
    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('Add your first expense'), findsNothing);
  });

  testWidgets('walks through onboarding and lands on the expense list', (
    tester,
  ) async {
    await pumpApp(tester);

    await tap(tester, 'Get started');
    expect(find.text('Add expenses your way'), findsOneWidget);

    await tap(tester, 'Next');
    expect(find.text('See where your money goes'), findsOneWidget);

    await tap(tester, 'Next');
    expect(find.text('Private by design'), findsOneWidget);
    expect(find.text('Skip'), findsNothing);

    await tap(tester, 'Get started');
    expect(find.text('Add your first expense'), findsOneWidget);
    expect(onboarding.isCompleted, isTrue);
  });

  testWidgets('Skip finishes onboarding right away', (tester) async {
    await pumpApp(tester);

    await tap(tester, 'Get started');
    await tap(tester, 'Skip');

    expect(find.text('Add your first expense'), findsOneWidget);
    expect(onboarding.isCompleted, isTrue);
  });

  testWidgets('the back button returns to the previous slide', (tester) async {
    await pumpApp(tester);

    await tap(tester, 'Get started');
    expect(find.byTooltip('Back'), findsNothing);

    await tap(tester, 'Next');
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Add expenses your way'), findsOneWidget);
  });

  testWidgets('skips the welcome screen once onboarding is completed', (
    tester,
  ) async {
    onboarding = FakeOnboardingRepository(completed: true);

    await pumpApp(tester);

    expect(find.text('Welcome to SpendWise IQ'), findsNothing);
    expect(find.text('Add your first expense'), findsOneWidget);
  });
}
