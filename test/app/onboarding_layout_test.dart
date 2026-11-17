import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/features/onboarding/presentation/onboarding_slides.dart';
import 'package:smart_expense_tracker/features/onboarding/presentation/widgets/onboarding_slide_view.dart';

import '../support/fakes.dart';
import '../support/pump_app.dart';

void main() {
  Future<void> openOnboarding(
    WidgetTester tester, {
    Size screenSize = const Size(800, 1600),
  }) async {
    await pumpRouterApp(
      tester,
      onboarding: FakeOnboardingRepository(),
      screenSize: screenSize,
    );
    await tapText(tester, 'Get started');
  }

  /// Top color of the gradient on the slide that is currently shown.
  Color gradientTopColor(WidgetTester tester) {
    final box = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(OnboardingSlideView),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final gradient = (box.decoration as BoxDecoration).gradient!;
    return (gradient as LinearGradient).colors.first;
  }

  group('slides', () {
    test('each slide has its own background tint', () {
      final light = onboardingSlides.map((s) => s.lightTint).toSet();
      final dark = onboardingSlides.map((s) => s.darkTint).toSet();

      expect(light, hasLength(onboardingSlides.length));
      expect(dark, hasLength(onboardingSlides.length));
    });

    test('uses the darker tint in dark mode', () {
      final slide = onboardingSlides.first;

      expect(slide.tint(Brightness.light), slide.lightTint);
      expect(slide.tint(Brightness.dark), slide.darkTint);
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

    testWidgets('the gradient changes with each slide', (tester) async {
      await openOnboarding(tester);

      for (var i = 0; i < onboardingSlides.length; i++) {
        expect(gradientTopColor(tester), onboardingSlides[i].lightTint);
        if (i < onboardingSlides.length - 1) await tapText(tester, 'Next');
      }
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

    testWidgets('the last slide has no Skip', (tester) async {
      await openOnboarding(tester);

      await tapText(tester, 'Next');
      await tapText(tester, 'Next');

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
