import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_expense_tracker/core/theme/app_theme.dart';
import 'package:smart_expense_tracker/features/onboarding/presentation/onboarding_slides.dart';
import 'package:smart_expense_tracker/features/onboarding/presentation/widgets/onboarding_slide_view.dart';

void main() {
  final slide = onboardingSlides.first;

  /// Shows the slide on a phone whose font size setting is [textScale].
  Future<void> pumpSlide(WidgetTester tester, double textScale) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearAllTestValues);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: OnboardingSlideView(slide: slide)),
      ),
    );
  }

  /// How many logical pixels 10 px of text becomes at the description.
  double descriptionScale(WidgetTester tester) {
    final context = tester.element(find.text(slide.description));
    return MediaQuery.textScalerOf(context).scale(10) / 10;
  }

  testWidgets('keeps the normal size at the default font setting', (
    tester,
  ) async {
    await pumpSlide(tester, 1.0);

    expect(descriptionScale(tester), 1.0);
  });

  testWidgets('limits how big the text gets on a large font setting', (
    tester,
  ) async {
    await pumpSlide(tester, 2.0);

    expect(descriptionScale(tester), OnboardingSlideView.maxTextScale);
    expect(tester.takeException(), isNull);
  });

  testWidgets('still grows a little, so it honors the setting', (tester) async {
    await pumpSlide(tester, 1.1);

    expect(descriptionScale(tester), closeTo(1.1, 0.001));
  });
}
