import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/features/onboarding/presentation/onboarding_slides.dart';
import 'package:smart_expense_tracker/features/onboarding/presentation/widgets/onboarding_name_view.dart';
import 'package:smart_expense_tracker/features/onboarding/presentation/widgets/onboarding_slide_view.dart';

import '../support/fakes.dart';
import '../support/pump_app.dart';

void main() {
  const screen = Size(800, 1600);

  Future<void> openOnboarding(
    WidgetTester tester, {
    Size screenSize = screen,
  }) async {
    await pumpRouterApp(
      tester,
      onboarding: FakeOnboardingRepository(),
      screenSize: screenSize,
    );
    await tapText(tester, 'Get started');
  }

  /// The box that paints the background of the slide currently shown.
  Finder slideBackground() => find
      .descendant(
        of: find.byType(OnboardingSlideView),
        matching: find.byType(ColoredBox),
      )
      .first;

  group('slides', () {
    test('each slide has its own bright background color', () {
      final colors = onboardingSlides.map((s) => s.color).toSet();

      expect(colors, hasLength(onboardingSlides.length));
      expect(colors, isNot(contains(nameScreenColor)));
    });
  });

  group('colors', () {
    testWidgets('the background covers the whole screen, not just a section', (
      tester,
    ) async {
      await openOnboarding(tester);

      expect(tester.getSize(slideBackground()), screen);
      expect(
        tester.widget<ColoredBox>(slideBackground()).color,
        onboardingSlides.first.color,
      );
    });

    testWidgets('the whole screen changes color with each slide', (
      tester,
    ) async {
      await openOnboarding(tester);

      for (var i = 0; i < onboardingSlides.length; i++) {
        expect(
          tester.widget<ColoredBox>(slideBackground()).color,
          onboardingSlides[i].color,
        );
        expect(tester.getSize(slideBackground()), screen);
        if (i < onboardingSlides.length - 1) await tapText(tester, 'Next');
      }
    });

    testWidgets('the buttons are black on every slide', (tester) async {
      await openOnboarding(tester);

      for (var i = 0; i < onboardingSlides.length; i++) {
        final button = tester.widget<FilledButton>(find.byType(FilledButton));
        expect(button.style?.backgroundColor?.resolve({}), onboardingInk);
        if (i < onboardingSlides.length - 1) await tapText(tester, 'Next');
      }
    });
  });

  group('layout', () {
    testWidgets('the text area starts at the middle of the screen', (
      tester,
    ) async {
      await openOnboarding(tester);

      final titleTop = tester
          .getTopLeft(find.text(onboardingSlides.first.title))
          .dy;

      expect(titleTop, greaterThanOrEqualTo(800));
      expect(titleTop, lessThan(800 + 40));
    });

    testWidgets('Skip is a secondary button just below Next', (tester) async {
      await openOnboarding(tester);

      final next = find.widgetWithText(FilledButton, 'Next');
      final skip = find.widgetWithText(TextButton, 'Skip');

      expect(next, findsOneWidget);
      expect(skip, findsOneWidget);
      expect(
        tester.getTopLeft(skip).dy,
        greaterThan(tester.getBottomLeft(next).dy),
      );
    });

    testWidgets('the name screen has its own color and no Skip', (
      tester,
    ) async {
      await openOnboarding(tester);

      await tapText(tester, 'Next');
      await tapText(tester, 'Next');
      await tapText(tester, 'Next');

      expect(find.byType(OnboardingNameView), findsOneWidget);
      final box = find.descendant(
        of: find.byType(OnboardingNameView),
        matching: find.byType(ColoredBox),
      );
      expect(tester.widget<ColoredBox>(box.first).color, nameScreenColor);

      expect(find.text('Skip'), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Get started'), findsOneWidget);
    });

    testWidgets('the welcome screen fits a short phone', (tester) async {
      await pumpRouterApp(
        tester,
        onboarding: FakeOnboardingRepository(),
        screenSize: const Size(360, 600),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Get started'), findsOneWidget);
    });

    for (final size in const [Size(360, 640), Size(360, 800)]) {
      testWidgets('the text stays clear of the buttons on a $size phone', (
        tester,
      ) async {
        await openOnboarding(tester, screenSize: size);

        for (var i = 0; i < onboardingSlides.length; i++) {
          final descriptionBottom = tester
              .getBottomLeft(find.text(onboardingSlides[i].description))
              .dy;
          final nextTop = tester.getTopLeft(find.byType(FilledButton)).dy;

          expect(tester.takeException(), isNull);
          expect(descriptionBottom, lessThanOrEqualTo(nextTop));
          if (i < onboardingSlides.length - 1) await tapText(tester, 'Next');
        }
      });
    }
  });
}
