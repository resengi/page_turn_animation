import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'page_turn_direction.dart';
import 'page_turn_edge.dart';
import 'page_turn_inputs.dart';
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
/// // A book read left to right (curls over its left edge, the spine)
/// PageTurnAnimation(
///   image: image,
///   animation: controller,
///   direction: PageTurnDirection.forward,
///   edge: PageTurnEdge.left,
/// )
///
/// // A wall calendar (curls up over the top edge)
/// PageTurnAnimation(
///   image: image,
///   animation: controller,
///   direction: PageTurnDirection.forward,
///   edge: PageTurnEdge.top,
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
  /// The [completionAngle] and [fingerStart] parameters default to the
  /// standard turn's and must be in the ranges [PageTurnInputs] gives:
  /// otherwise building the widget throws an [ArgumentError]
  /// ([PageTurnInputs.validate]).
  ///
  /// The [backImage] parameter is optional: without it the page's back is
  /// the plain [PageTurnStyle.backgroundColor].
  ///
  /// The [style] parameter allows customization of the visual appearance
  /// and defaults to [PageTurnStyle.defaults].
  const PageTurnAnimation({
    required this.image,
    required this.animation,
    required this.direction,
    this.edge = PageTurnEdge.top,
    this.backImage,
    this.completionAngle = PageTurnInputs.standardCompletionAngle,
    this.fingerStart = PageTurnInputs.standardFingerStart,
    this.style = const PageTurnStyle(),
    super.key,
  });

  /// The captured image to animate with the page turn effect.
  ///
  /// This should typically be captured from a widget using [RenderRepaintBoundary.toImage].
  /// For best results, capture at a high pixel ratio (e.g., 3.0).
  final ui.Image image;

  /// {@template page_turn_animation.backImage}
  /// The image on the back of the page, seen wherever the page's back faces
  /// the viewer as it turns. It is stretched over the page like the front
  /// image and reads correctly once the page has turned 180°, lying beside
  /// the stack: in a book, for instance, the back of a right-hand page is the
  /// next left-hand page. In either [direction], it is the back of the page
  /// that turns.
  ///
  /// When null, the back is the plain [PageTurnStyle.backgroundColor].
  /// {@endtemplate}
  final ui.Image? backImage;

  /// The animation that drives the page turn effect.
  ///
  /// Progress should go from 0.0 to 1.0. For a forward turn:
  /// - At 0.0: The page lies flat
  /// - At 1.0: The page has turned over the hinge and lies on the surface at
  ///   the [completionAngle]: out of sight behind the stack at 360, flat
  ///   beside it at 180
  ///
  /// A backward turn shows the same turn from its end back to its start.
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

  /// {@template page_turn_animation.completionAngle}
  /// The angle, in degrees, of the surface the turned page lies down on,
  /// measured around the hinge from the page's place on the stack, from
  /// [PageTurnInputs.minCompletionAngle] (180) to
  /// [PageTurnInputs.maxCompletionAngle] (360) inclusive:
  /// - 180: flat on the desk beside the stack
  /// - 225: a surface sloping down at 45 degrees on the far side
  /// - 270: straight down past the hinge
  /// - 360: flat on the back of the stack
  ///
  /// The page goes over the hinge and lies down onto that surface. Short of
  /// 360, the part nearest the hinge lands first and the far part of the page
  /// curls back the other way and lands last, the more so the smaller the
  /// angle and the higher the style's curl intensity.
  ///
  /// The standard page turn is the page turned from its free edge onto the
  /// back of the stack: a completion angle of 360 with a [fingerStart] of 0,
  /// the defaults.
  ///
  /// Defaults to [PageTurnInputs.standardCompletionAngle] (360).
  /// {@endtemplate}
  final double completionAngle;

  /// {@template page_turn_animation.fingerStart}
  /// The finger start: a place on the page, as a share of its length from the
  /// free edge: [PageTurnInputs.minFingerStart] (0) is the free edge, up to
  /// [PageTurnInputs.maxFingerStart] (0.9) near the hinge.
  ///
  /// At 0 the page is turned from its free edge. From further in, the finger
  /// first pushes the page toward the hinge: an arch rises behind the finger
  /// while the free edge slides in along the stack, until the part between the
  /// finger and the edge is straight with only the edge on the stack. Then the
  /// page lifts off and turns over the hinge as the arch opens, takes on the
  /// turn's curl and ends as the turn from the free edge does. The page lifts
  /// off within the first fifth of the turn; the nearer the finger is to the
  /// hinge, the smaller the arch, and toward 0 the push fades out.
  ///
  /// Defaults to [PageTurnInputs.standardFingerStart] (0).
  /// {@endtemplate}
  final double fingerStart;

  /// Visual styling configuration for the animation.
  ///
  /// Use this to customize the page's reverse color, how tightly it rolls,
  /// rendering quality, and the shadows from the lamp over the hinge.
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
            backImage: backImage,
            progress: animation.value,
            direction: direction,
            edge: edge,
            completionAngle: completionAngle,
            fingerStart: fingerStart,
            style: style,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}
