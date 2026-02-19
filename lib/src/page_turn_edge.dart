import 'package:flutter/painting.dart';

/// The edge of the image where the page turn "hinge" is located.
///
/// This determines which edge the page curls over during the animation,
/// similar to where a physical book or notepad would be bound.
///
/// Combined with [PageTurnDirection], this gives full control over the animation:
///
/// | Edge | Direction | Visual Effect |
/// |------|-----------|---------------|
/// | [top] | forward | Page curls up and away over top edge |
/// | [top] | backward | Page curls down into view from top edge |
/// | [bottom] | forward | Page curls down and away over bottom edge |
/// | [bottom] | backward | Page curls up into view from bottom edge |
/// | [left] | forward | Page curls left and away over left edge |
/// | [left] | backward | Page curls right into view from left edge |
/// | [right] | forward | Page curls right and away over right edge |
/// | [right] | backward | Page curls left into view from right edge |
///
/// Example:
/// ```dart
/// // Book-like page turn (hinge on right, curls right and away)
/// PageTurnAnimation(
///   image: capturedImage,
///   animation: controller,
///   direction: PageTurnDirection.forward,
///   edge: PageTurnEdge.right,
/// )
///
/// // Calendar-like page turn (hinge on bottom, curls down and away)
/// PageTurnAnimation(
///   image: capturedImage,
///   animation: controller,
///   direction: PageTurnDirection.forward,
///   edge: PageTurnEdge.bottom,
/// )
/// ```
enum PageTurnEdge {
  /// Hinge at top edge. Page curls over the top.
  ///
  /// This is the default behavior, similar to a top-bound notepad.
  top,

  /// Hinge at bottom edge. Page curls over the bottom.
  ///
  /// Similar to a wall calendar or bottom-bound pad.
  bottom,

  /// Hinge at left edge. Page curls over the left side.
  ///
  /// Similar to a right-to-left book or manga.
  left,

  /// Hinge at right edge. Page curls over the right side.
  ///
  /// Similar to a standard Western book with left-to-right reading.
  right,
}

/// Extension providing helper properties for [PageTurnEdge].
///
/// These properties are used internally by the page turn painter
/// to determine coordinate mapping and rendering behavior.
extension PageTurnEdgeExtension on PageTurnEdge {
  /// Whether this edge uses a vertical animation axis.
  ///
  /// - `true` for [top] and [bottom]: segments are horizontal strips
  /// - `false` for [left] and [right]: segments are vertical strips
  bool get isVerticalAxis =>
      this == PageTurnEdge.top || this == PageTurnEdge.bottom;

  /// Whether coordinates need to be calculated from the far edge.
  ///
  /// - `true` for [bottom] and [right]: measure from bottom/right
  /// - `false` for [top] and [left]: measure from top/left
  bool get requiresCoordinateFlip =>
      this == PageTurnEdge.bottom || this == PageTurnEdge.right;

  /// The alignment where the shadow gradient begins (darkest point).
  ///
  /// This is at the page edge where the shadow originates.
  Alignment get shadowGradientBegin => switch (this) {
    PageTurnEdge.top => Alignment.topCenter,
    PageTurnEdge.bottom => Alignment.bottomCenter,
    PageTurnEdge.left => Alignment.centerLeft,
    PageTurnEdge.right => Alignment.centerRight,
  };

  /// The alignment where the shadow gradient ends (fades out).
  ///
  /// This is at the opposite edge from the page.
  Alignment get shadowGradientEnd => switch (this) {
    PageTurnEdge.top => Alignment.bottomCenter,
    PageTurnEdge.bottom => Alignment.topCenter,
    PageTurnEdge.left => Alignment.centerRight,
    PageTurnEdge.right => Alignment.centerLeft,
  };
}
