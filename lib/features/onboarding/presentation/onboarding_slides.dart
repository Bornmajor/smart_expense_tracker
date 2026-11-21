import 'package:flutter/material.dart';

/// Text, buttons and the progress bar on the onboarding screens are always
/// black, in light and dark mode, because the backgrounds are bright.
const onboardingInk = Color(0xFF0A0A0A);

class OnboardingSlide {
  const OnboardingSlide({
    required this.title,
    required this.description,
    required this.image,
    required this.color,
  });

  final String title;
  final String description;
  final String image;

  /// Fills the whole screen behind this slide.
  final Color color;
}

const onboardingSlides = [
  OnboardingSlide(
    title: 'Add expenses your way',
    description:
        'Scan a receipt or a PDF, type it in one line like "lunch 350 at Java", '
        'or paste an M-Pesa message. You always check it before it\'s saved.',
    image: 'assets/illustrations/onboarding_scan.png',
    color: Color(0xFFFFE14D), // Yellow
  ),
  OnboardingSlide(
    title: 'See where your money goes',
    description:
        'Your month at a glance: spending by category, your budgets, and what '
        'is safe to spend each day, with a heads-up when something looks off.',
    image: 'assets/illustrations/onboarding_track.png',
    color: Color(0xFFDCC4FB), // Lavender
  ),
  OnboardingSlide(
    title: 'Private by design',
    description:
        'Everything stays on your phone and works offline. Lock the app with '
        'your fingerprint or face, back it up to a file, and export a monthly '
        'PDF or CSV.',
    image: 'assets/illustrations/onboarding_private.webp',
    color: Color(0xFF8FEBBE), // Mint (13.7:1 contrast with black)
  ),
];

/// The fourth screen, where the user can give a first name. It is a form, so it
/// has a color of its own (black text on it is 12:1) and no big illustration.
const nameScreenColor = Color(0xFFFFC9A8); // Peach

/// How many screens the introduction has: the slides and the name screen.
final onboardingPageCount = onboardingSlides.length + 1;
