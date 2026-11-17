class OnboardingSlide {
  const OnboardingSlide({
    required this.title,
    required this.description,
    required this.image,
  });

  final String title;
  final String description;
  final String image;
}

const onboardingSlides = [
  OnboardingSlide(
    title: 'Add expenses your way',
    description:
        'Scan a receipt and SpendWise IQ reads the vendor, date, and total. '
        'Or type it in yourself. Either way, you check it before it\'s saved.',
    image: 'assets/illustrations/onboarding_scan.png',
  ),
  OnboardingSlide(
    title: 'See where your money goes',
    description:
        'Spending by category and a clear summary of your month, '
        'all in one place.',
    image: 'assets/illustrations/onboarding_track.png',
  ),
  OnboardingSlide(
    title: 'Private by design',
    description:
        'Everything stays on your phone and works offline. '
        'Lock the app with your fingerprint or face, and export a monthly '
        'PDF or CSV.',
    image: 'assets/illustrations/onboarding_private.webp',
  ),
];
