import 'package:flutter/widgets.dart';

/// 4-point grid. Use names, never raw numbers, in widgets.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Standard horizontal page padding.
  static const EdgeInsets screen = EdgeInsets.symmetric(horizontal: 20);

  /// Standard padding inside cards.
  static const EdgeInsets card = EdgeInsets.all(lg);
}

abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 14; // buttons, fields
  static const double lg = 20; // cards
  static const double xl = 28; // bottom sheets
  static const double pill = 999;

  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
}

/// `Gap(AppSpacing.md)` works in both Column and Row.
class Gap extends StatelessWidget {
  const Gap(this.size, {super.key});

  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(dimension: size);
}
