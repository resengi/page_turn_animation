/// A Flutter package that provides a realistic page turn/curl animation effect.
///
/// This package allows you to create smooth, 3D page turn animations for
/// transitioning between content, similar to turning pages in a physical book.
///
/// ## Getting Started
///
/// Add the package to your `pubspec.yaml`:
///
/// ```yaml
/// dependencies:
///   page_turn_animation: ^0.1.0
/// ```
///
/// ## Basic Usage
///
/// ```dart
/// import 'package:page_turn_animation/page_turn_animation.dart';
///
/// // Use PageTurnAnimation with a captured image and animation controller
/// PageTurnAnimation(
///   image: capturedImage,
///   animation: animationController,
///   direction: PageTurnDirection.forward,
/// )
/// ```
///
/// ## Edge Selection
///
/// Control which edge the page curls over:
///
/// ```dart
/// // Book-like page turn (curls over right edge)
/// PageTurnAnimation(
///   image: capturedImage,
///   animation: animationController,
///   direction: PageTurnDirection.forward,
///   edge: PageTurnEdge.right,
/// )
/// ```
///
/// ## Key Components
///
/// - [PageTurnAnimation]: The main widget that displays the page turn effect
/// - [PageTurnEdge]: Enum for selecting which edge the page curls over
/// - [PageTurnDirection]: Enum for forward/backward animation direction
/// - [PageTurnStyle]: Configuration class for visual customization
/// - [StaticImagePainter]: Helper for displaying static captured images
///
/// See the README for comprehensive usage examples and best practices.
library;

export 'src/page_turn_animation_widget.dart';
export 'src/page_turn_direction.dart';
export 'src/page_turn_edge.dart';
export 'src/page_turn_style.dart';
export 'src/static_image_painter.dart';
