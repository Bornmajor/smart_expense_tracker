import 'package:flutter/material.dart';

class OnboardingSlide {
  const OnboardingSlide({
    required this.title,
    required this.description,
    required this.image,
    required this.lightTint,
    required this.darkTint,
  });

  final String title;
  final String description;
  final String image;

  /// Top color of the slide's background gradient, which fades into the page.
  final Color lightTint;
  final Color darkTint;

  Color tint(Brightness brightness) =>
      brightness == Brightness.dark ? darkTint : lightTint;
}

const onboardingSlides = [
  OnboardingSlide(
    title: 'Add expenses your way',
    description:
        'Scan a receipt and SpendWise IQ reads the vendor, date, and total. '
        'Or type it in yourself. Either way, you check it before it\'s saved.',
    image: 'assets/illustrations/onboarding_scan.png',
    // Peach
    lightTint: Color(0xFFFFD7BF),
    darkTint: Color(0xFF4A3024),
  ),
  OnboardingSlide(
    title: 'See where your money goes',
    description:
        'Spending by category and a clear summary of your month, '
        'all in one place.',
    image: 'assets/illustrations/onboarding_track.png',
    // Mint
    lightTint: Color(0xFFC6EDDD),
    darkTint: Color(0xFF1F4137),
  ),
  OnboardingSlide(
    title: 'Private by design',
    description:
        'Everything stays on your phone and works offline. '
        'Lock the app with your fingerprint or face, and export a monthly '
        'PDF or CSV.',
    image: 'assets/illustrations/onboarding_private.webp',
    // Lavender
    lightTint: Color(0xFFD9D3FA),
    darkTint: Color(0xFF2E2B52),
  ),
];
