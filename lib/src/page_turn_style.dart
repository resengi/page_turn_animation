import 'package:flutter/material.dart';

/// Configuration class for customizing the visual appearance of the page turn animation.
///
/// Use this class to customize the page's reverse color, how tightly it rolls,
/// the animation's detail level, and its shadows: the page's shadow and its
/// shading, as from a lamp over the hinge.
///
/// Example:
/// ```dart
/// PageTurnAnimation(
///   image: capturedImage,
///   animation: animationController,
///   direction: PageTurnDirection.forward,
///   style: PageTurnStyle(
///     backgroundColor: Colors.grey[100]!,
///     shadowColor: Colors.black,
///     shadowOpacity: 0.8,
///   ),
/// )
/// ```
@immutable
class PageTurnStyle {
  /// Creates a page turn style configuration.
  ///
  /// All parameters have sensible defaults and are optional.
  const PageTurnStyle({
    this.backgroundColor = Colors.white,
    this.shadowColor = Colors.black,
    this.shadowOpacity = 0.9,
    this.shadowBlurRadius = 20.0,
    this.lampDistanceFromPage = 2.0,
    this.segments = 100,
    this.curlIntensity = 1.0,
  }) : assert(
         shadowOpacity >= 0.0 && shadowOpacity <= 1.0,
         'shadowOpacity must be between 0.0 and 1.0',
       ),
       assert(shadowBlurRadius >= 0.0, 'shadowBlurRadius must be non-negative'),
       assert(
         lampDistanceFromPage > 1.0 && lampDistanceFromPage < double.infinity,
         'lampDistanceFromPage must be more than 1 and finite',
       ),
       assert(segments > 0, 'segments must be positive'),
       assert(
         curlIntensity > 0.0 && curlIntensity < double.infinity,
         'curlIntensity must be positive and finite',
       );

  /// The color of the turning page's back, seen wherever the back faces the
  /// viewer, when there is no back image (`PageTurnAnimation.backImage`).
  ///
  /// Defaults to [Colors.white].
  final Color backgroundColor;

  /// The color of the page's shadow and shading.
  ///
  /// Defaults to [Colors.black].
  final Color shadowColor;

  /// How dark the page's shadow is right where the paper casting it touches,
  /// from 0.0 (no shadows or shading) to 1.0 (fully opaque).
  ///
  /// Defaults to 0.9.
  final double shadowOpacity;

  /// How soft the page's shadow is, in logical pixels: its soft edge is twice
  /// this wide for paper a page length from where the shadow falls, sharper
  /// for paper closer to it. Nothing is blurred; the soft edge comes from the
  /// lamp's width, which this sets.
  ///
  /// Defaults to 20.0.
  final double shadowBlurRadius;

  /// How far the lamp is above the hinge, in page lengths (the page's length
  /// from the hinge to its free edge). It must be more than 1, above the
  /// highest the page reaches, and finite. A nearer lamp throws the page's
  /// shadow further out.
  ///
  /// Defaults to 2.0.
  final double lampDistanceFromPage;

  /// The number of segments used to render the page curl effect.
  ///
  /// Higher values create a smoother curl but may impact performance.
  /// Lower values are more performant but may appear jagged. A page is cut
  /// into no more than one segment per logical pixel of its length, and at
  /// least one.
  /// Defaults to 100, which provides a good balance.
  final int segments;

  /// How tightly the page rolls as it turns.
  ///
  /// Values greater than 1.0 roll the page more tightly, carrying its free
  /// edge closer past the hinge; values less than 1.0 roll it more gently,
  /// toward a page that turns over almost flat. Must be positive and finite.
  /// Defaults to 1.0.
  final double curlIntensity;

  /// Creates a copy of this style with the given fields replaced.
  ///
  /// Example:
  /// ```dart
  /// final customStyle = PageTurnStyle.defaults.copyWith(
  ///   shadowOpacity: 0.5,
  ///   segments: 50,
  /// );
  /// ```
  PageTurnStyle copyWith({
    Color? backgroundColor,
    Color? shadowColor,
    double? shadowOpacity,
    double? shadowBlurRadius,
    double? lampDistanceFromPage,
    int? segments,
    double? curlIntensity,
  }) {
    return PageTurnStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      shadowColor: shadowColor ?? this.shadowColor,
      shadowOpacity: shadowOpacity ?? this.shadowOpacity,
      shadowBlurRadius: shadowBlurRadius ?? this.shadowBlurRadius,
      lampDistanceFromPage: lampDistanceFromPage ?? this.lampDistanceFromPage,
      segments: segments ?? this.segments,
      curlIntensity: curlIntensity ?? this.curlIntensity,
    );
  }

  /// Default style configuration.
  ///
  /// Provides a clean, professional look suitable for most use cases.
  static const PageTurnStyle defaults = PageTurnStyle();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PageTurnStyle &&
        other.backgroundColor == backgroundColor &&
        other.shadowColor == shadowColor &&
        other.shadowOpacity == shadowOpacity &&
        other.shadowBlurRadius == shadowBlurRadius &&
        other.lampDistanceFromPage == lampDistanceFromPage &&
        other.segments == segments &&
        other.curlIntensity == curlIntensity;
  }

  @override
  int get hashCode {
    return Object.hash(
      backgroundColor,
      shadowColor,
      shadowOpacity,
      shadowBlurRadius,
      lampDistanceFromPage,
      segments,
      curlIntensity,
    );
  }

  @override
  String toString() {
    return 'PageTurnStyle('
        'backgroundColor: $backgroundColor, '
        'shadowColor: $shadowColor, '
        'shadowOpacity: $shadowOpacity, '
        'shadowBlurRadius: $shadowBlurRadius, '
        'lampDistanceFromPage: $lampDistanceFromPage, '
        'segments: $segments, '
        'curlIntensity: $curlIntensity)';
  }
}
