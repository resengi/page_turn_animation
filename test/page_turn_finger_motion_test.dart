import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:page_turn_animation/src/page_turn_constants.dart';
import 'package:page_turn_animation/src/page_turn_painter.dart';

/// The example app's page: 968 by 464 logical pixels, drawn in 150 strips.
const pageLength = 968.0, pageWidth = 464.0, strips = 150;

/// A page's strip ends as the painter draws them, seen from its camera
/// ([PageTurnConstants.cameraDistance] page lengths up, over
/// [PageTurnConstants.cameraAlong] of the page): how far along from the hinge
/// and how far out from the page's middle, in logical pixels, and whether each
/// end is painted (an end of a strip that is not left out behind the original
/// page, by the painter's rule).
({List<double> along, List<double> out, List<bool> painted}) seen(
  double t,
  double angle,
  double curl,
  double fingerStart,
) {
  final (:y, :z, :directions) = PageTurnPainter.stripEnds(
    t: t,
    curlIntensity: curl,
    completionAngle: angle,
    fingerStart: fingerStart,
    strips: strips,
  );
  const camera = PageTurnConstants.cameraDistance;
  const over = PageTurnConstants.cameraAlong;
  final scale = [for (final h in z) camera / (camera - h)];
  final along = [
    for (var i = 0; i <= strips; i++)
      (over + (y[i] - over) * scale[i]) * pageLength,
  ];
  bool behind(int i) => z[i] <= 0 && along[i] > 0 && along[i] <= pageLength;
  final painted = List.filled(strips + 1, false);
  for (var i = 0; i < strips; i++) {
    if (!(directions[i] > math.pi && (behind(i) || behind(i + 1)))) {
      painted[i] = painted[i + 1] = true;
    }
  }
  return (
    along: along,
    out: [for (final s in scale) pageWidth / 2 * s],
    painted: painted,
  );
}

/// The farthest any painted point moves on screen from [a] to [b].
double moved(
  ({List<double> along, List<double> out, List<bool> painted}) a,
  ({List<double> along, List<double> out, List<bool> painted}) b,
) {
  var most = 0.0;
  for (var i = 0; i <= strips; i++) {
    if (a.painted[i] && b.painted[i]) {
      most = math.max(
        most,
        math.sqrt(
          math.pow(a.along[i] - b.along[i], 2) +
              math.pow(a.out[i] - b.out[i], 2),
        ),
      );
    }
  }
  return most;
}

/// In a 1 s turn at an even pace, 60 frames: the farthest any point moves in
/// one frame, and the largest change of that between neighbouring frames.
({double fastest, double change}) timed(
  double angle,
  double curl,
  double fingerStart,
) {
  var fastest = 0.0, change = 0.0;
  double? last;
  var previous = seen(0, angle, curl, fingerStart);
  for (var k = 1; k <= 60; k++) {
    final now = seen(k / 60, angle, curl, fingerStart);
    final d = moved(now, previous);
    fastest = math.max(fastest, d);
    if (last != null) change = math.max(change, (d - last).abs());
    last = d;
    previous = now;
  }
  return (fastest: fastest, change: change);
}

/// A drag that keeps the pressed spot under the finger, a pixel at a time
/// until the spot reaches the hinge: how far the spot moves back out, away
/// from the hinge, and the farthest any point moves per pixel of finger. The
/// first [PageTurnConstants.dragLiftSpread] of a page, which the drag spreads
/// out, is not followed pixel by pixel and is left out.
({double back, double perPixel}) dragged(
  double angle,
  double curl,
  double fingerStart,
) {
  const grid = 1500;
  final spot = 1 - fingerStart;
  double spotAt(double t) {
    final view = seen(t, angle, curl, fingerStart);
    final at = spot * strips, i = math.min(strips - 1, at.floor());
    return view.along[i] + (view.along[i + 1] - view.along[i]) * (at - i);
  }

  final along = [for (var j = 0; j <= grid; j++) spotAt(j / grid)];
  final start = along.first;
  const spread = PageTurnConstants.dragLiftSpread * pageLength;
  var back = 0.0, hinge = grid, spreadEnd = 0;
  while (spreadEnd < grid && along[spreadEnd] > start - spread) {
    spreadEnd++;
  }
  for (var j = 1; j <= grid; j++) {
    if (along[j] <= 0) {
      hinge = j;
      break;
    }
    if (j > spreadEnd) back += math.max(0, along[j] - along[j - 1]);
  }
  var j = 0, perPixel = 0.0;
  var previous = seen(0, angle, curl, fingerStart);
  for (var px = 1.0; start - px > 0; px++) {
    final target = start - px;
    while (j < hinge && along[j + 1] > target) {
      j++;
    }
    if (j >= hinge) break;
    final t = (j + (along[j] - target) / (along[j] - along[j + 1])) / grid;
    final now = seen(t, angle, curl, fingerStart);
    if (px > spread) perPixel = math.max(perPixel, moved(now, previous));
    previous = now;
  }
  return (back: back, perPixel: perPixel);
}

/// How far the free edge slides back out, away from the hinge, while it is on
/// the desk.
double edgeBack(double angle, double curl, double fingerStart) {
  var back = 0.0;
  double? last;
  for (var j = 0; j <= 800; j++) {
    final (:y, :z, directions: _) = PageTurnPainter.stripEnds(
      t: j / 800,
      curlIntensity: curl,
      completionAngle: angle,
      fingerStart: fingerStart,
      strips: strips,
    );
    if (z[strips] > 1e-3) break;
    final edge = y[strips] * pageLength;
    if (last != null) back += math.max(0, edge - last);
    last = edge;
  }
  return back;
}

/// How far, in degrees, the tail between the finger and the free edge is still
/// bent when the free edge first leaves the desk (half a logical pixel up):
/// the direction of its last strip less that of its first.
double tailBendAtLiftOff(double angle, double curl, double fingerStart) {
  const fine = 600;
  for (var j = 0; j <= 4000; j++) {
    final (:y, :z, :directions) = PageTurnPainter.stripEnds(
      t: j / 4000,
      curlIntensity: curl,
      completionAngle: angle,
      fingerStart: fingerStart,
      strips: fine,
    );
    if (z[fine] * pageLength > 0.5) {
      final first = ((1 - fingerStart) * fine).ceil();
      return (directions[fine - 1] - directions[first]) * 180 / math.pi;
    }
  }
  return 0;
}

void main() {
  for (final angle in [180.0, 270.0, 360.0]) {
    for (final curl in [0.25, 4.0]) {
      group('completion angle $angle, curl intensity $curl', () {
        final standardTurn = timed(angle, curl, 0);
        final standardDrag = dragged(angle, curl, 0);
        for (final fingerStart in [0.1, 0.3, 0.6, 0.9]) {
          test('finger start $fingerStart moves without bursts', () {
            final turn = timed(angle, curl, fingerStart);
            // On this grid the turn from a finger start moves at most 2.66
            // times as fast as the standard turn, and changes pace at most
            // 7.33 times as sharply; the bounds are these, with a little room.
            expect(turn.fastest, lessThan(2.7 * standardTurn.fastest));
            expect(turn.change, lessThan(7.5 * standardTurn.change));
          });

          test('finger start $fingerStart drags smoothly', () {
            final drag = dragged(angle, curl, fingerStart);
            expect(drag.back, lessThan(0.5));
            // As far per pixel as the standard turn's drag, scaled by how much
            // nearer the hinge the finger holds the page.
            expect(
              drag.perPixel,
              lessThan(2 * standardDrag.perPixel / (1 - fingerStart)),
            );
            expect(edgeBack(angle, curl, fingerStart), lessThan(0.5));
          });

          test(
            'finger start $fingerStart lifts off with the tail straight',
            () {
              expect(
                tailBendAtLiftOff(angle, curl, fingerStart).abs(),
                lessThan(1),
              );
            },
          );
        }
      });
    }
  }

  test('nears the standard turn as the finger start nears 0', () {
    for (final angle in [180.0, 270.0, 360.0]) {
      for (var j = 0; j <= 20; j++) {
        final t = j / 20;
        final standard = seen(t, angle, 1, 0);
        expect(moved(seen(t, angle, 1, 1e-3), standard), lessThan(0.5));
        expect(moved(seen(t, angle, 1, 1e-6), standard), lessThan(1e-6));
      }
    }
  });

  test('draws a finite page at every finger start', () {
    for (final angle in [180.0, 225.0, 270.0, 315.0, 360.0]) {
      for (final curl in [0.001, 1.0, 100000.0]) {
        for (final fingerStart in [
          for (var k = 1; k <= 90; k++) k / 100,
          1e-3,
          1e-9,
          1e-200,
          5e-324,
        ]) {
          for (var j = 0; j <= 40; j++) {
            final (:y, :z, :directions) = PageTurnPainter.stripEnds(
              t: j / 40,
              curlIntensity: curl,
              completionAngle: angle,
              fingerStart: fingerStart,
              strips: 50,
            );
            expect(
              [...y, ...z, ...directions].every((v) => v.isFinite),
              isTrue,
              reason:
                  '$angle°, curl $curl, finger start $fingerStart, '
                  't ${j / 40}',
            );
          }
        }
      }
    }
  });
}
