import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'page_turn_direction.dart';
import 'page_turn_edge.dart';
import 'page_turn_painter.dart';
import 'page_turn_style.dart';

/// A widget that displays a realistic page turn animation effect on a captured image.
///
/// This widget creates a 3D page curl effect that simulates turning a physical page.
/// It requires a [ui.Image] (typically captured from a widget using [RenderRepaintBoundary])
/// and an [Animation] to drive the effect.
///
/// ## Basic Usage
///
/// ```dart
/// // In your animation setup:
/// late AnimationController _controller;
/// ui.Image? _capturedImage;
///
/// // Capture the widget to animate:
/// Future<void> captureWidget() async {
///   final boundary = _repaintKey.currentContext!.findRenderObject()
///       as RenderRepaintBoundary;
///   _capturedImage = await boundary.toImage(pixelRatio: 3.0);
/// }
///
/// // In your build method:
/// PageTurnAnimation(
///   image: _capturedImage!,
///   animation: _controller,
///   direction: PageTurnDirection.forward,
/// )
/// ```
///
/// ## Animation Stack Pattern
///
/// For smooth transitions, use a stack with the destination content beneath:
///
/// ```dart
/// Stack(
///   children: [
///     // Layer 1: The destination content (always visible)
///     Positioned.fill(child: destinationWidget),
///
///     // Layer 2: The page turn animation (animates away)
///     PageTurnAnimation(
///       image: currentPageImage,
///       animation: curvedAnimation,
///       direction: PageTurnDirection.forward,
///     ),
///   ],
/// )
/// ```
///
/// ## Edge Selection
///
/// Use the [edge] parameter to control which edge the page curls over:
///
/// ```dart
/// // Book-like page turn (curls over right edge)
/// PageTurnAnimation(
///   image: image,
///   animation: controller,
///   direction: PageTurnDirection.forward,
///   edge: PageTurnEdge.right,
/// )
///
/// // Calendar-like page turn (curls over bottom edge)
/// PageTurnAnimation(
///   image: image,
///   animation: controller,
///   direction: PageTurnDirection.forward,
///   edge: PageTurnEdge.bottom,
/// )
/// ```
///
/// ## Customization
///
/// Use [PageTurnStyle] to customize the visual appearance:
///
/// ```dart
/// PageTurnAnimation(
///   image: image,
///   animation: animation,
///   direction: PageTurnDirection.forward,
///   style: PageTurnStyle(
///     backgroundColor: Colors.grey[200]!,
///     shadowColor: Colors.black54,
///     shadowOpacity: 0.7,
///     shadowBlurRadius: 15.0,
///     segments: 80,
///     curlIntensity: 1.2,
///   ),
/// )
/// ```
///
/// See also:
///
/// * [PageTurnEdge] for edge selection options
/// * [PageTurnStyle] for customization options
/// * [PageTurnDirection] for animation direction options
/// * [StaticImagePainter] for rendering static captured images
class PageTurnAnimation extends StatelessWidget {
  /// Creates a page turn animation widget.
  ///
  /// The [image], [animation], and [direction] parameters are required.
  ///
  /// The [edge] parameter controls which edge the page curls over
  /// and defaults to [PageTurnEdge.top].
  ///
  /// The [style] parameter allows customization of the visual appearance
  /// and defaults to [PageTurnStyle.defaults].
  const PageTurnAnimation({
    required this.image,
    required this.animation,
    required this.direction,
    this.edge = PageTurnEdge.top,
    this.style = const PageTurnStyle(),
    super.key,
  });

  /// The captured image to animate with the page turn effect.
  ///
  /// This should typically be captured from a widget using [RenderRepaintBoundary.toImage].
  /// For best results, capture at a high pixel ratio (e.g., 3.0).
  final ui.Image image;

  /// The animation that drives the page turn effect.
  ///
  /// Progress should go from 0.0 to 1.0:
  /// - At 0.0: The page is fully visible (flat)
  /// - At 1.0: The page has fully turned away
  ///
  /// Consider using [CurvedAnimation] for more natural motion:
  /// ```dart
  /// final curvedAnimation = CurvedAnimation(
  ///   parent: controller,
  ///   curve: Curves.easeInOut,
  /// );
  /// ```
  final Animation<double> animation;

  /// The direction of the page turn animation.
  ///
  /// - [PageTurnDirection.forward]: Page curls away, revealing content beneath
  /// - [PageTurnDirection.backward]: Page curls into view, covering content beneath
  final PageTurnDirection direction;

  /// The edge where the page turn hinge is located.
  ///
  /// This determines which edge the page curls over:
  /// - [PageTurnEdge.top]: Page curls over the top (default)
  /// - [PageTurnEdge.bottom]: Page curls over the bottom
  /// - [PageTurnEdge.left]: Page curls over the left side
  /// - [PageTurnEdge.right]: Page curls over the right side
  ///
  /// Defaults to [PageTurnEdge.top].
  final PageTurnEdge edge;

  /// Visual styling configuration for the animation.
  ///
  /// Use this to customize colors, shadow effects, and rendering quality.
  /// Defaults to [PageTurnStyle.defaults].
  final PageTurnStyle style;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return CustomPaint(
          painter: PageTurnPainter(
            image: image,
            progress: animation.value,
            direction: direction,
            edge: edge,
            style: style,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}
