import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// A simple custom painter that renders a [ui.Image] to fill the available space.
///
/// This is useful during page turn animation sequences when you need to display
/// a captured image as a static layer beneath or above the animating page.
///
/// Example usage in an animation stack:
/// ```dart
/// Stack(
///   children: [
///     // Static background layer
///     CustomPaint(
///       painter: StaticImagePainter(image: backgroundImage),
///       size: Size.infinite,
///     ),
///     // Animated page turn layer
///     PageTurnAnimation(
///       image: foregroundImage,
///       animation: controller,
///       direction: PageTurnDirection.forward,
///     ),
///   ],
/// )
/// ```
class StaticImagePainter extends CustomPainter {
  /// Creates a static image painter.
  ///
  /// The [image] parameter is the [ui.Image] to render.
  StaticImagePainter({required this.image});

  /// The image to render.
  ///
  /// This image will be scaled to fill the entire paint area.
  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    // Validate inputs
    if (size.width <= 0 ||
        size.height <= 0 ||
        image.width <= 0 ||
        image.height <= 0) {
      return;
    }

    final paint = Paint()
      ..isAntiAlias = true
      ..filterQuality = FilterQuality.medium;

    final src = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);

    canvas.drawImageRect(image, src, dst, paint);
  }

  @override
  bool shouldRepaint(StaticImagePainter oldDelegate) {
    return oldDelegate.image != image;
  }
}
