import 'package:equatable/equatable.dart';

/// One line of text found in a photo, with where it sits in the image.
/// Coordinates are image pixels, with the origin at the top left.
class OcrLine extends Equatable {
  const OcrLine({
    required this.text,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final String text;
  final double left;
  final double top;
  final double right;
  final double bottom;

  double get height => bottom - top;
  double get centerY => (top + bottom) / 2;

  @override
  List<Object?> get props => [text, left, top, right, bottom];
}
