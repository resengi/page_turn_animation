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
/// // A book read left to right (hinge on the left, the page turning over to
/// // the left)
/// PageTurnAnimation(
///   image: capturedImage,
///   animation: controller,
///   direction: PageTurnDirection.forward,
///   edge: PageTurnEdge.left,
/// )
///
/// // A wall calendar (hinge at the top, the page turning up and over)
/// PageTurnAnimation(
///   image: capturedImage,
///   animation: controller,
///   direction: PageTurnDirection.forward,
///   edge: PageTurnEdge.top,
/// )
/// ```
enum PageTurnEdge {
  /// Hinge at top edge. Page curls over the top.
  ///
  /// This is the default behavior, similar to a top-bound notepad or a wall
  /// calendar.
  top,

  /// Hinge at bottom edge. Page curls over the bottom.
  ///
  /// Similar to a bottom-bound pad.
  bottom,

  /// Hinge at left edge. Page curls over the left side.
  ///
  /// Similar to a book read left to right, the standard Western book: its
  /// right-hand page turns over its left edge, the spine.
  left,

  /// Hinge at right edge. Page curls over the right side.
  ///
  /// Similar to a book read right to left, such as manga.
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

  /// The alignment of the middle of the edge the page turns over.
  ///
  /// Not used by the page turn: its shadows come from a lamp over the hinge
  /// (`PageTurnStyle.lampDistanceFromPage`).
  @Deprecated(
    'Not used by the page turn: its shadows come from a lamp over the hinge '
    '(PageTurnStyle.lampDistanceFromPage).',
  )
  Alignment get shadowGradientBegin => switch (this) {
    PageTurnEdge.top => Alignment.topCenter,
    PageTurnEdge.bottom => Alignment.bottomCenter,
    PageTurnEdge.left => Alignment.centerLeft,
    PageTurnEdge.right => Alignment.centerRight,
  };

  /// The alignment of the middle of the edge opposite the one the page turns
  /// over.
  ///
  /// Not used by the page turn: its shadows come from a lamp over the hinge
  /// (`PageTurnStyle.lampDistanceFromPage`).
  @Deprecated(
    'Not used by the page turn: its shadows come from a lamp over the hinge '
    '(PageTurnStyle.lampDistanceFromPage).',
  )
  Alignment get shadowGradientEnd => switch (this) {
    PageTurnEdge.top => Alignment.bottomCenter,
    PageTurnEdge.bottom => Alignment.topCenter,
    PageTurnEdge.left => Alignment.centerRight,
    PageTurnEdge.right => Alignment.centerLeft,
  };
}
