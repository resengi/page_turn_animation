import 'package:flutter_test/flutter_test.dart';
import 'package:page_turn_animation/page_turn_animation.dart';
import 'package:page_turn_animation/src/page_turn_constants.dart';
import 'package:page_turn_animation/src/page_turn_painter.dart';

void main() {
  const pageLength = 600.0;

  for (final (completionAngle, curlIntensity, fingerStart) in [
    for (final angle in [180.0, 270.0, 360.0])
      for (final curl in [0.25, 1.0, 4.0])
        for (final finger in [0.0, 0.3, 0.6, 0.9]) (angle, curl, finger),
  ]) {
    group('completion angle $completionAngle, curl intensity $curlIntensity, '
        'finger start $fingerStart', () {
      final style = PageTurnStyle(segments: 150, curlIntensity: curlIntensity);
      final drag = PageTurnDragProgress(
        pageLength: pageLength,
        style: style,
        completionAngle: completionAngle,
        fingerStart: fingerStart,
      );

      /// Where the pressed spot lies before the turn, in logical pixels from
      /// the hinge.
      final spotStart = (1 - fingerStart) * pageLength;

      /// Where the painter shows the pressed spot at progress [t], in logical
      /// pixels from the hinge.
      double spotAt(double t) =>
          PageTurnPainter.paperAlong(
            t: t,
            paperPosition: 1 - fingerStart,
            pageLength: pageLength,
            style: style,
            completionAngle: completionAngle,
            fingerStart: fingerStart,
          ) *
          pageLength;

      test('finds where the pressed spot first reaches the hinge', () {
        expect(spotAt(drag.hingeProgress).abs(), lessThanOrEqualTo(0.1));
        for (var t = 0.0; t < drag.hingeProgress - 1e-3; t += 1e-3) {
          expect(spotAt(t), greaterThan(0));
        }
      });

      test('keeps the pressed spot under the finger up to the hinge', () {
        var progress = 0.0;
        for (
          var travel = PageTurnConstants.dragLiftSpread * pageLength;
          travel < spotStart;
          travel += 1
        ) {
          progress = drag.progressFor(travel, current: progress);
          expect(spotAt(progress), closeTo(spotStart - travel, 0.1));
        }
      });

      test('finds the same progress from any current progress', () {
        for (
          var travel = PageTurnConstants.dragLiftSpread * pageLength;
          travel < spotStart;
          travel += 37
        ) {
          for (final current in [0.0, 0.5, 1.0]) {
            final progress = drag.progressFor(travel, current: current);
            expect(spotAt(progress), closeTo(spotStart - travel, 0.1));
          }
        }
      });

      test('spreads the lift over the start of the drag', () {
        const spread = PageTurnConstants.dragLiftSpread * pageLength;
        final atEnd = drag.progressFor(spread);
        expect(drag.progressFor(spread / 2), closeTo(atEnd / 2, 1e-12));
        expect(spotAt(atEnd), closeTo(spotStart - spread, 0.1));
      });

      test('rises from 0 to 1 by a page length past the hinge, never going '
          'back', () {
        expect(drag.progressFor(-10), 0);
        expect(drag.progressFor(0), 0);
        var progress = 0.0;
        for (var travel = 1.0; travel <= spotStart + pageLength; travel += 1) {
          final next = drag.progressFor(travel, current: progress);
          expect(next, greaterThanOrEqualTo(progress));
          progress = next;
        }
        expect(drag.progressFor(spotStart), drag.hingeProgress);
        expect(progress, closeTo(1, 1e-12));
        expect(drag.progressFor(spotStart + 2 * pageLength), closeTo(1, 1e-12));
      });

      test('goes on past the hinge at the rate it reached it', () {
        // The progress one page length of travel gives as the painter moves
        // the pressed spot into the hinge: finite, as the spot reaches the
        // hinge moving toward it at these settings.
        const dt = 1e-4;
        final arriving =
            2 *
            dt *
            pageLength /
            (spotAt(drag.hingeProgress - dt) - spotAt(drag.hingeProgress + dt));

        // The rate at the hinge from two steps either side of it: exact past
        // the hinge, where the progress is quadratic in the travel.
        const step = 0.01;
        double rate(double sign) {
          double gained(double along) =>
              (drag.progressFor(spotStart + sign * along * pageLength) -
                      drag.hingeProgress)
                  .abs();
          return (4 * gained(step) - gained(2 * step)) / (2 * step);
        }

        expect(rate(1), closeTo(arriving, 1e-3 * arriving));
        // Before the hinge the progress comes from the search, each to within
        // a tenth of a logical pixel: on this page that alone can move the
        // estimate by up to 6.7%, and the spot's speed changes a little over
        // the last two steps.
        expect(rate(-1), closeTo(arriving, 0.1 * arriving));
      });
    });
  }

  test('finds where the pressed spot first reaches the hinge across the '
      'completion angles, finger starts and curl intensities, where it stays '
      'past the hinge for at least two steps of the search', () {
    // The search steps through the turn a thirty-second of its progress at a
    // time; a fine scan finds the first crossing and how long the pressed spot
    // stays past the hinge. The drag progress relies on both across these
    // settings: the spot reaches the hinge (hingeProgress is 1 only where it
    // does not), and once past it stays past for more than a step of the
    // search.
    const pageLength = 600.0, scan = 1000, searchStep = 1 / 32;
    for (final completionAngle in const [
      180.0,
      210.0,
      240.0,
      270.0,
      300.0,
      330.0,
      360.0,
    ]) {
      for (final curlIntensity in const [0.01, 0.25, 1.0, 4.0, 100.0]) {
        for (final fingerStart in [for (var k = 0; k <= 9; k++) k / 10]) {
          final reason =
              'angle $completionAngle curl $curlIntensity finger $fingerStart';
          final style = PageTurnStyle(
            segments: 100,
            curlIntensity: curlIntensity,
          );
          double spotAt(double t) =>
              PageTurnPainter.paperAlong(
                t: t,
                paperPosition: 1 - fingerStart,
                pageLength: pageLength,
                style: style,
                completionAngle: completionAngle,
                fingerStart: fingerStart,
              ) *
              pageLength;
          final drag = PageTurnDragProgress(
            pageLength: pageLength,
            style: style,
            completionAngle: completionAngle,
            fingerStart: fingerStart,
          );
          double? first, leaves;
          for (var j = 1; j <= scan && leaves == null; j++) {
            final spot = spotAt(j / scan);
            if (first == null && spot <= 0) first = j / scan;
            if (first != null && spot > 0) leaves = j / scan;
          }
          expect(first, isNotNull, reason: reason);
          expect(
            drag.hingeProgress,
            inInclusiveRange(first! - 2 / scan, first),
            reason: reason,
          );
          expect(
            spotAt(drag.hingeProgress).abs(),
            lessThanOrEqualTo(0.1),
            reason: reason,
          );
          expect(
            (leaves ?? 1) - first,
            greaterThanOrEqualTo(2 * searchStep),
            reason: reason,
          );
        }
      }
    }
  });

  test('rejects a page length that is not positive and finite', () {
    for (final length in [0.0, -1.0, double.nan, double.infinity]) {
      expect(
        () => PageTurnDragProgress(pageLength: length),
        throwsArgumentError,
      );
    }
  });

  test('rejects a completion angle or finger start out of range', () {
    expect(
      () => PageTurnDragProgress(pageLength: pageLength, completionAngle: 90),
      throwsArgumentError,
    );
    expect(
      () => PageTurnDragProgress(pageLength: pageLength, fingerStart: 1),
      throwsArgumentError,
    );
  });
}
