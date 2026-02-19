import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'page_turn_direction.dart';
import 'page_turn_edge.dart';
import 'page_turn_style.dart';

/// Custom painter that renders the page turn/curl animation effect.
///
/// This painter creates a realistic page curl effect by:
/// 1. Dividing the image into segments (horizontal or vertical based on edge)
/// 2. Applying perspective transformation to each segment
/// 3. Drawing shadows to enhance the 3D effect
///
/// This class is used internally by [PageTurnAnimation] but is exposed
/// for advanced use cases where direct painter access is needed.
class PageTurnPainter extends CustomPainter {
  /// Creates a page turn painter.
  ///
  /// All parameters are required:
  /// - [image]: The captured UI image to animate
  /// - [progress]: Animation progress from 0.0 to 1.0
  /// - [direction]: Whether the page turns forward or backward
  /// - [edge]: Which edge the page curls over
  /// - [style]: Visual styling configuration
  PageTurnPainter({
    required this.image,
    required this.progress,
    required this.direction,
    required this.edge,
    required this.style,
  });

  /// The image to render with the page turn effect.
  final ui.Image image;

  /// The current animation progress from 0.0 (start) to 1.0 (complete).
  final double progress;

  /// The direction of the page turn animation.
  final PageTurnDirection direction;

  /// The edge where the page turn hinge is located.
  final PageTurnEdge edge;

  /// Visual styling configuration for the animation.
  final PageTurnStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    // Validate inputs
    if (size.width <= 0 ||
        size.height <= 0 ||
        image.width <= 0 ||
        image.height <= 0) {
      return;
    }

    // Determine primary/secondary dimensions based on edge
    final bool isVerticalAxis = edge.isVerticalAxis;
    final bool flipOrigin = edge.requiresCoordinateFlip;

    final double primarySize = isVerticalAxis ? size.height : size.width;
    final double secondarySize = isVerticalAxis ? size.width : size.height;
    final double imagePrimarySize = isVerticalAxis
        ? image.height.toDouble()
        : image.width.toDouble();
    final double imageSecondarySize = isVerticalAxis
        ? image.width.toDouble()
        : image.height.toDouble();

    double utilizedProgress = progress.clamp(0.0, 1.0);

    // If flipping forward then use the reverse of the progress to
    // reverse the animation direction.
    if (direction == PageTurnDirection.forward) {
      utilizedProgress = 1 - utilizedProgress;
    }

    final visiblePrimary = primarySize * utilizedProgress;

    // Early return if nothing to draw
    if (visiblePrimary <= 0) {
      return;
    }

    // Calculate curl radius based on progress and intensity
    final baseCurlRadius =
        primarySize * math.sin((1 - utilizedProgress) * math.pi) / 5;
    final curlRadius = baseCurlRadius * style.curlIntensity;

    canvas.save();

    final segments = style.segments;
    final segmentSize = visiblePrimary / segments;

    // Calculate page edge position from the last segment for shadow placement
    final lastSegmentP = (segments - 1) * segmentSize;
    final lastSegmentNextP = visiblePrimary;
    final lastSegmentProgress = math.min(
      1.0,
      utilizedProgress * visiblePrimary / (lastSegmentNextP + 1),
    );
    final lastAngle = (1 - lastSegmentProgress) * math.pi;
    final lastBendP = lastSegmentP - curlRadius * (1 - math.cos(lastAngle));
    final perspectiveMultiplier =
        math.pow(20, math.pow(1 - utilizedProgress, 4.1)) as double;
    final lastDestSize =
        (lastSegmentNextP - lastSegmentP) * perspectiveMultiplier;

    // Calculate actual page edge position based on edge type
    final double pageEdgePosition;
    if (flipOrigin) {
      pageEdgePosition = primarySize - (lastBendP + lastDestSize);
    } else {
      pageEdgePosition = lastBendP + lastDestSize;
    }

    // Draw shadow FIRST (beneath the page)
    _drawPageShadow(canvas, size, utilizedProgress, pageEdgePosition);

    // Draw each segment with perspective transformation
    for (int i = 0; i < segments; i++) {
      final p = i * segmentSize;
      final nextP = math.min((i + 1) * segmentSize, visiblePrimary);

      // Skip if segment has no size
      if (nextP <= p) continue;

      // Calculate uncurl progress for this segment
      final segmentProgress = math.min(
        1.0,
        utilizedProgress * visiblePrimary / (nextP + 1),
      );

      if (segmentProgress > 0) {
        // Calculate position on the uncurl
        final angle = (1 - segmentProgress) * math.pi;
        final bendP = p - curlRadius * (1 - math.cos(angle));

        // Source rectangle calculation
        final double srcPrimary;
        final double srcPrimarySize;

        if (flipOrigin) {
          // Show far end of image (bottom or right portion)
          srcPrimary = imagePrimarySize * (1 - nextP / primarySize);
          srcPrimarySize = ((nextP - p) / primarySize) * imagePrimarySize;
        } else {
          // Show near end of image (top or left portion)
          srcPrimary = (p / primarySize) * imagePrimarySize;
          srcPrimarySize = ((nextP - p) / primarySize) * imagePrimarySize;
        }

        // Validate source dimensions
        if (srcPrimarySize <= 0 ||
            srcPrimary < 0 ||
            srcPrimary + srcPrimarySize > imagePrimarySize) {
          continue;
        }

        final src = _buildRect(
          primaryPos: srcPrimary,
          secondaryPos: 0,
          primarySize: srcPrimarySize,
          secondarySize: imageSecondarySize,
          isVerticalAxis: isVerticalAxis,
        );

        // Destination with perspective
        final double destPrimary;
        if (flipOrigin) {
          destPrimary =
              primarySize - bendP - (nextP - p) * perspectiveMultiplier;
        } else {
          destPrimary = bendP;
        }

        final perspectiveSecondary =
            1 + math.sin(math.pi * segmentProgress) / 10;
        final destSecondarySize = secondarySize * perspectiveSecondary;
        final destSecondaryOffset = (secondarySize - destSecondarySize) / 2;
        final destPrimarySize = (nextP - p) * perspectiveMultiplier;

        // Validate destination dimensions
        if (destSecondarySize <= 0 || destPrimarySize <= 0) {
          continue;
        }

        final dst = _buildRect(
          primaryPos: destPrimary,
          secondaryPos: destSecondaryOffset,
          primarySize: destPrimarySize,
          secondarySize: destSecondarySize,
          isVerticalAxis: isVerticalAxis,
        );

        final paint = Paint()
          ..isAntiAlias = true
          ..filterQuality = FilterQuality.medium;

        try {
          canvas.drawImageRect(image, src, dst, paint);
        } catch (e) {
          // Skip this segment if drawing fails
          continue;
        }
      }
    }

    canvas.restore();
  }

  /// Builds a rect with primary/secondary dimensions mapped to the appropriate axis.
  Rect _buildRect({
    required double primaryPos,
    required double secondaryPos,
    required double primarySize,
    required double secondarySize,
    required bool isVerticalAxis,
  }) {
    return isVerticalAxis
        ? Rect.fromLTWH(secondaryPos, primaryPos, secondarySize, primarySize)
        : Rect.fromLTWH(primaryPos, secondaryPos, primarySize, secondarySize);
  }

  /// Draws the shadow effect beneath the curling page.
  void _drawPageShadow(
    Canvas canvas,
    Size size,
    double progress,
    double pageEdgePosition,
  ) {
    final isVerticalAxis = edge.isVerticalAxis;
    final flipOrigin = edge.requiresCoordinateFlip;
    final primarySize = isVerticalAxis ? size.height : size.width;
    final secondarySize = isVerticalAxis ? size.width : size.height;

    // Calculate shadow dimensions
    final double shadowPrimarySize;
    if (flipOrigin) {
      shadowPrimarySize = pageEdgePosition;
    } else {
      shadowPrimarySize = primarySize - pageEdgePosition;
    }

    if (shadowPrimarySize <= 0) {
      return;
    }

    // Calculate shadow rect
    final Rect shadowRect;
    if (flipOrigin) {
      shadowRect = _buildRect(
        primaryPos: 0,
        secondaryPos: 0,
        primarySize: pageEdgePosition,
        secondarySize: secondarySize,
        isVerticalAxis: isVerticalAxis,
      );
    } else {
      shadowRect = _buildRect(
        primaryPos: pageEdgePosition,
        secondaryPos: 0,
        primarySize: primarySize - pageEdgePosition,
        secondarySize: secondarySize,
        isVerticalAxis: isVerticalAxis,
      );
    }

    // Create gradient shadow
    final effectiveOpacity = style.shadowOpacity * progress;
    final shadowPaint = Paint()
      ..shader = LinearGradient(
        begin: edge.shadowGradientBegin,
        end: edge.shadowGradientEnd,
        colors: [
          style.shadowColor.withValues(alpha: effectiveOpacity * 1.0),
          style.shadowColor.withValues(alpha: effectiveOpacity * 0.55),
          style.shadowColor.withValues(alpha: effectiveOpacity * 0.22),
        ],
        stops: const [0, 0.4, 1.0],
      ).createShader(shadowRect)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, style.shadowBlurRadius);

    canvas.drawRect(shadowRect, shadowPaint);

    // Edge shadow for crisp page edge
    final edgeShadowPaint = Paint()
      ..color = style.shadowColor.withValues(alpha: effectiveOpacity * 0.33)
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        style.shadowBlurRadius / 2,
      )
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final edgePath = Path();
    if (isVerticalAxis) {
      edgePath.moveTo(0, pageEdgePosition);
      edgePath.lineTo(size.width, pageEdgePosition);
    } else {
      edgePath.moveTo(pageEdgePosition, 0);
      edgePath.lineTo(pageEdgePosition, size.height);
    }

    canvas.drawPath(edgePath, edgeShadowPaint);
  }

  @override
  bool shouldRepaint(PageTurnPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.direction != direction ||
        oldDelegate.edge != edge ||
        oldDelegate.image != image ||
        oldDelegate.style != style;
  }
}
