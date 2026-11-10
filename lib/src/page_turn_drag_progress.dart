import 'dart:math' as math;

import 'page_turn_constants.dart';
import 'page_turn_inputs.dart';
import 'page_turn_painter.dart';
import 'page_turn_style.dart';

/// Turns a drag on a page into a forward turn's progress, so the spot the
/// finger pressed stays under the finger along the turn.
///
/// The finger presses the page at its finger start: [fingerStart] of the
/// page's length in from the free edge, so 1 − [fingerStart] page lengths from
/// the hinge (the free edge itself at the standard finger start). The app
/// measures the drag as the finger's travel toward the hinge since it began,
/// in logical pixels, and sets the turn's progress from it on each move, for
/// example
/// `controller.value = drag.progressFor(travel, current: controller.value)`.
/// When the finger lifts, the app decides how the turn ends, for example with
/// `controller.animateTo(1)` or `controller.animateBack(0)`. The turn must be
/// drawn with the same page length, style, completion angle and finger start
/// as the drag, and with no curve on the progress.
///
/// 1. Until the pressed spot reaches the hinge, over 1 − [fingerStart] page
///    lengths of travel, the progress is the one at which [PageTurnAnimation]
///    draws that spot that far in from where it started, found by a search that
///    stops once the spot is within a tenth of a logical pixel of the finger,
///    or after a fixed number of steps, so that it always ends. Over the first
///    3% of a page of travel the lift, which raises the page toward the camera
///    before the spot moves across the screen, is spread out instead of
///    happening on the first pixel. Across the turn, the page is drawn wider
///    the higher it rises, so a spot away from its middle moves a little
///    outward.
/// 2. Past the hinge, the rest of the turn starts at the rate the turn reached
///    the hinge at and speeds up to finish over the next page length of
///    travel. Where that rate would finish it sooner, as for a spot pressed
///    near the hinge, it keeps that rate to the end. Further travel leaves the
///    turn complete.
class PageTurnDragProgress {
  /// Creates the drag progress for a page [pageLength] logical pixels long
  /// along the turn, turned with [style], [completionAngle] and [fingerStart].
  ///
  /// Throws an [ArgumentError] if [pageLength] is not positive and finite, or
  /// if [completionAngle] or [fingerStart] is not accepted
  /// ([PageTurnInputs.validate]).
  PageTurnDragProgress({
    required this.pageLength,
    this.style = const PageTurnStyle(),
    this.completionAngle = PageTurnInputs.standardCompletionAngle,
    this.fingerStart = PageTurnInputs.standardFingerStart,
  }) {
    if (!(pageLength > 0 && pageLength.isFinite)) {
      throw ArgumentError.value(
        pageLength,
        'pageLength',
        'must be positive and finite',
      );
    }
    PageTurnInputs.validate(
      completionAngle: completionAngle,
      fingerStart: fingerStart,
    );
    hingeProgress = _findHinge();
    _spreadEnd = _progressAt(
      _spotStart - PageTurnConstants.dragLiftSpread,
      from: 0,
    );
    _arrivalRate = _rateAtHinge();
  }

  /// The page's length along the turn, in logical pixels.
  final double pageLength;

  /// The style the page is turned with.
  final PageTurnStyle style;

  /// {@macro page_turn_animation.completionAngle}
  final double completionAngle;

  /// {@macro page_turn_animation.fingerStart}
  final double fingerStart;

  /// The progress at which the pressed spot is seen at the hinge: the progress
  /// for 1 − [fingerStart] page lengths of travel. 1 if the spot never reaches
  /// the hinge.
  late final double hingeProgress;

  /// Where the pressed spot is before the turn, in page lengths from the
  /// hinge.
  double get _spotStart => 1 - fingerStart;

  /// The progress at the end of the lift's spread
  /// ([PageTurnConstants.dragLiftSpread]), from which the pressed spot follows
  /// the finger.
  late final double _spreadEnd;

  /// How much progress one page length of travel gives as the pressed spot
  /// reaches the hinge.
  late final double _arrivalRate;

  /// The search for the hinge steps through the turn a thirty-second of its
  /// progress at a time, to the first step at which the pressed spot is past
  /// the hinge, and narrows down between it and the step before. It finds the
  /// first crossing as long as the spot, once past the hinge, stays past it
  /// for more than a step.
  static const double _hingeSearchStep = 1 / 32;

  /// The most steps one search for a progress takes, so that it always ends.
  /// The drag tests check that the searches they run still find the progress
  /// to within a tenth of a logical pixel.
  static const int _maxSteps = 60;

  /// The progress for a finger that has travelled [travel] logical pixels
  /// toward the hinge since the drag began, with the turn now at [current].
  ///
  /// The search for the progress starts at [current], so it is found soonest
  /// when [current] is the progress of the last move; from any [current] the
  /// search ends once the pressed spot is under the finger to within a tenth
  /// of a logical pixel, or after its fixed number of steps.
  double progressFor(double travel, {double current = 0}) {
    final along = travel / pageLength;
    if (!(along > 0)) return 0;
    if (along >= _spotStart) {
      // Over a page length of travel, or over as much as the arrival rate
      // takes to finish the turn if that is less.
      final rest = 1 - hingeProgress;
      final over = rest < _arrivalRate ? rest / _arrivalRate : 1.0;
      final past = over > 0 ? math.min(1.0, (along - _spotStart) / over) : 1.0;
      final gain = math.min(_arrivalRate, rest);
      return hingeProgress + gain * past + (rest - gain) * past * past;
    }
    const spread = PageTurnConstants.dragLiftSpread;
    if (along <= spread) return along / spread * _spreadEnd;
    return _progressAt(_spotStart - along, from: current);
  }

  /// Where the pressed spot is seen at progress [t], in page lengths from the
  /// hinge.
  double _spotAt(double t) => PageTurnPainter.paperAlong(
    progress: t,
    paperPosition: _spotStart,
    pageLength: pageLength,
    style: style,
    completionAngle: completionAngle,
    fingerStart: fingerStart,
  );

  /// The progress at which the pressed spot is seen at [x] page lengths from
  /// the hinge, to within a tenth of a logical pixel.
  ///
  /// It lies between [lo], where the spot is seen at [loAlong] (beyond [x]),
  /// and [hi], where it is seen at [hiAlong] (short of [x]): by default the
  /// start of the turn, where the flat page's spot is seen where it lies, and
  /// the hinge. The search starts [from] a progress and steps along the line
  /// through the last two progress values tried, the first line through
  /// [from] and the end on the other side of [x]. Each value tried narrows
  /// the ends; a step that would leave them halves them instead.
  double _progressAt(
    double x, {
    required double from,
    double lo = 0,
    double? loAlong,
    double? hi,
    double hiAlong = 0,
  }) {
    final close = 0.1 / pageLength;
    var low = lo, high = hi ?? hingeProgress;
    var t = from.clamp(low, high);
    var miss = _spotAt(t) - x;
    var lastT = miss > 0 ? high : low;
    var lastMiss = (miss > 0 ? hiAlong : loAlong ?? _spotStart) - x;
    for (var i = 0; i < _maxSteps && miss.abs() > close; i++) {
      if (miss > 0) {
        low = t;
      } else {
        high = t;
      }
      var next = t - miss * (t - lastT) / (miss - lastMiss);
      if (!(next > low && next < high)) next = (low + high) / 2;
      lastT = t;
      lastMiss = miss;
      t = next;
      miss = _spotAt(t) - x;
    }
    return t;
  }

  /// The progress at which the pressed spot is seen at the hinge, found
  /// between the last step of the search at which it is short of the hinge
  /// and the first at which it is not.
  double _findHinge() {
    var lo = 0.0, loAlong = _spotStart;
    var hi = _hingeSearchStep;
    while (true) {
      final hiAlong = _spotAt(hi);
      if (hiAlong <= 0) {
        return _progressAt(
          0,
          from: hi,
          lo: lo,
          loAlong: loAlong,
          hi: hi,
          hiAlong: hiAlong,
        );
      }
      if (hi >= 1) return 1;
      lo = hi;
      loAlong = hiAlong;
      hi = math.min(1.0, hi + _hingeSearchStep);
    }
  }

  /// How much progress one page length of travel gives as the pressed spot
  /// reaches the hinge: one over how fast the spot moves there, from where it
  /// is seen a ten-thousandth of the progress before and after.
  ///
  /// 0 if the spot never reaches the hinge, so the rest of the turn takes no
  /// travel; infinite if it reaches it without moving toward it, so the turn
  /// finishes at once past it.
  double _rateAtHinge() {
    if (hingeProgress >= 1) return 0;
    const step = 1e-4;
    final before = math.max(0.0, hingeProgress - step);
    final after = math.min(1.0, hingeProgress + step);
    final speed = (_spotAt(before) - _spotAt(after)) / (after - before);
    return speed > 0 ? 1 / speed : double.infinity;
  }
}
