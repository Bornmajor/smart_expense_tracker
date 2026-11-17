import 'package:flutter/material.dart';

import '../../core/theme/theme_x.dart';

/// The SpendWise IQ logo: a receipt inside a scan frame.
/// Uses the theme's primary colors, so it stays visible in light and dark mode.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'SpendWise IQ logo',
      child: CustomPaint(
        size: Size.square(size),
        painter: _LogoPainter(
          background: context.scheme.primary,
          foreground: context.scheme.onPrimary,
        ),
      ),
    );
  }
}

/// Draws the logo on a 120 x 120 grid, scaled to the widget size.
class _LogoPainter extends CustomPainter {
  _LogoPainter({required this.background, required this.foreground});

  final Color background;
  final Color foreground;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 120;
    Offset p(double x, double y) => Offset(x * s, y * s);

    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(28 * s)),
      Paint()..color = background,
    );

    final corner = Radius.circular(8 * s);
    final frame = Path()
      ..moveTo(20 * s, 38 * s)
      ..lineTo(20 * s, 28 * s)
      ..arcToPoint(p(28, 20), radius: corner)
      ..lineTo(38 * s, 20 * s)
      ..moveTo(82 * s, 20 * s)
      ..lineTo(92 * s, 20 * s)
      ..arcToPoint(p(100, 28), radius: corner)
      ..lineTo(100 * s, 38 * s)
      ..moveTo(100 * s, 82 * s)
      ..lineTo(100 * s, 92 * s)
      ..arcToPoint(p(92, 100), radius: corner)
      ..lineTo(82 * s, 100 * s)
      ..moveTo(38 * s, 100 * s)
      ..lineTo(28 * s, 100 * s)
      ..arcToPoint(p(20, 92), radius: corner)
      ..lineTo(20 * s, 82 * s);
    canvas.drawPath(
      frame,
      Paint()
        ..color = foreground
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5 * s
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final receipt = Path()
      ..moveTo(42 * s, 34 * s)
      ..lineTo(78 * s, 34 * s)
      ..lineTo(78 * s, 86 * s)
      ..lineTo(72 * s, 81 * s)
      ..lineTo(66 * s, 86 * s)
      ..lineTo(60 * s, 81 * s)
      ..lineTo(54 * s, 86 * s)
      ..lineTo(48 * s, 81 * s)
      ..lineTo(42 * s, 86 * s)
      ..close();
    canvas.drawPath(receipt, Paint()..color = foreground);

    final line = Paint()..color = background;
    for (final (y, width) in [(43.0, 22.0), (52.0, 22.0), (61.0, 13.0)]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(49 * s, y * s, width * s, 3.5 * s),
          Radius.circular(1.75 * s),
        ),
        line,
      );
    }
  }

  @override
  bool shouldRepaint(_LogoPainter old) =>
      old.background != background || old.foreground != foreground;
}
