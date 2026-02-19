import 'package:flutter/material.dart';

/// Configuration class for customizing the visual appearance of the page turn animation.
///
/// Use this class to customize colors, shadow effects, and animation detail level.
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
    this.segments = 100,
    this.curlIntensity = 1.0,
  }) : assert(
         shadowOpacity >= 0.0 && shadowOpacity <= 1.0,
         'shadowOpacity must be between 0.0 and 1.0',
       ),
       assert(shadowBlurRadius >= 0.0, 'shadowBlurRadius must be non-negative'),
       assert(segments > 0, 'segments must be positive'),
       assert(curlIntensity > 0.0, 'curlIntensity must be positive');

  /// The background color visible behind the page during animation.
  ///
  /// This color shows through during the page turn effect.
  /// Defaults to [Colors.white].
  final Color backgroundColor;

  /// The color used for the page shadow effect.
  ///
  /// This creates a shadow beneath the curling page edge.
  /// Defaults to [Colors.black].
  final Color shadowColor;

  /// The opacity of the shadow effect, from 0.0 (invisible) to 1.0 (fully opaque).
  ///
  /// Higher values create a more pronounced shadow effect.
  /// Defaults to 0.9.
  final double shadowOpacity;

  /// The blur radius for the shadow effect in logical pixels.
  ///
  /// Higher values create a softer, more diffuse shadow.
  /// Defaults to 20.0.
  final double shadowBlurRadius;

  /// The number of segments used to render the page curl effect.
  ///
  /// Higher values create a smoother curl but may impact performance.
  /// Lower values are more performant but may appear jagged.
  /// Defaults to 100, which provides a good balance.
  final int segments;

  /// Multiplier for the curl radius effect.
  ///
  /// Values greater than 1.0 create a more pronounced curl.
  /// Values less than 1.0 create a subtler curl effect.
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
    int? segments,
    double? curlIntensity,
  }) {
    return PageTurnStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      shadowColor: shadowColor ?? this.shadowColor,
      shadowOpacity: shadowOpacity ?? this.shadowOpacity,
      shadowBlurRadius: shadowBlurRadius ?? this.shadowBlurRadius,
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
        'segments: $segments, '
        'curlIntensity: $curlIntensity)';
  }
}
