import 'dart:io';

import 'package:flutter/material.dart';

/// Opens the receipt picture large, over whatever is on screen, so the user
/// can read it without leaving the form. Pinch to zoom, or double-tap to zoom
/// in and double-tap again to zoom back out.
Future<void> showReceiptViewer(BuildContext context, String photoPath) {
  return showDialog<void>(
    context: context,
    builder: (context) => _ReceiptViewer(photoPath: photoPath),
  );
}

class _ReceiptViewer extends StatefulWidget {
  const _ReceiptViewer({required this.photoPath});

  final String photoPath;

  @override
  State<_ReceiptViewer> createState() => _ReceiptViewerState();
}

class _ReceiptViewerState extends State<_ReceiptViewer> {
  /// How far a double-tap zooms in.
  static const _zoom = 3.0;

  final _controller = TransformationController();
  Offset _tap = Offset.zero;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _zoomedIn => _controller.value.getMaxScaleOnAxis() > 1.01;

  /// Zooms in around the spot that was tapped, or back out when already
  /// zoomed in.
  void _toggleZoom() {
    _controller.value = _zoomedIn
        ? Matrix4.identity()
        : (Matrix4.diagonal3Values(_zoom, _zoom, 1)..setTranslationRaw(
            -_tap.dx * (_zoom - 1),
            -_tap.dy * (_zoom - 1),
            0,
          ));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Stack(
        children: [
          GestureDetector(
            onDoubleTapDown: (details) => _tap = details.localPosition,
            onDoubleTap: _toggleZoom,
            child: InteractiveViewer(
              transformationController: _controller,
              maxScale: 8,
              child: Center(
                child: Image.file(
                  File(widget.photoPath),
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.broken_image_outlined, size: 48),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Close',
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
