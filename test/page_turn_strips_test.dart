import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:page_turn_animation/page_turn_animation.dart';
import 'package:page_turn_animation/src/page_turn_painter.dart';

({List<double> y, List<double> z}) strips(
  double t, {
  double curlIntensity = 1,
  double completionAngle = PageTurnInputs.standardCompletionAngle,
  int count = 400,
}) {
  final (:y, :z, directions: _) = PageTurnPainter.stripEnds(
    t: t,
    curlIntensity: curlIntensity,
    completionAngle: completionAngle,
    fingerStart: PageTurnInputs.standardFingerStart,
    strips: count,
  );
  return (y: y, z: z);
}

const completionAngles = [180.0, 225.0, 270.0, 315.0, 360.0];

/// Whether the stretch from (y0, z0) to (y1, z1) crosses the one from
/// (y2, z2) to (y3, z3) between their ends.
bool crosses(
  double y0,
  double z0,
  double y1,
  double z1,
  double y2,
  double z2,
  double y3,
  double z3,
) {
  final d = (y1 - y0) * (z3 - z2) - (z1 - z0) * (y3 - y2);
  if (d.abs() < 1e-14) return false;
  final u = ((y2 - y0) * (z3 - z2) - (z2 - z0) * (y3 - y2)) / d;
  final v = ((y2 - y0) * (z1 - z0) - (z2 - z0) * (y1 - y0)) / d;
  return u > 0 && u < 1 && v > 0 && v < 1;
}

void main() {
  test('every strip is one strip-length long and meets the next, so the '
      'page keeps its length', () {
    for (final completionAngle in const [180.0, 360.0]) {
      for (final curlIntensity in const [0.001, 0.25, 1.0, 4.0, 100000.0]) {
        for (var t = 0.0; t <= 1; t += 0.05) {
          final (:y, :z) = strips(
            t,
            curlIntensity: curlIntensity,
            completionAngle: completionAngle,
            count: 300,
          );
          expect(y.first, 0);
          expect(z.first, 0);
          for (var i = 0; i < 300; i++) {
            final length = math.sqrt(
              math.pow(y[i + 1] - y[i], 2) + math.pow(z[i + 1] - z[i], 2),
            );
            expect(
              length,
              closeTo(1 / 300, 1e-12),
              reason: 't $t curl $curlIntensity angle $completionAngle',
            );
          }
        }
      }
    }
  });

  test('the page starts flat on the stack and ends flat on the surface at '
      'the completion angle', () {
    for (final completionAngle in completionAngles) {
      final angle = completionAngle * math.pi / 180;
      for (final curlIntensity in const [
        0.001,
        0.05,
        0.25,
        1.0,
        4.0,
        20.0,
        100000.0,
      ]) {
        final start = strips(0, curlIntensity: curlIntensity);
        final end = strips(
          1,
          curlIntensity: curlIntensity,
          completionAngle: completionAngle,
        );
        final reason = 'curl $curlIntensity angle $completionAngle';
        for (var i = 0; i <= 400; i++) {
          expect(start.y[i], closeTo(i / 400, 1e-12), reason: reason);
          expect(start.z[i], 0, reason: reason);
          expect(
            end.y[i],
            closeTo(i / 400 * math.cos(angle), 1e-12),
            reason: reason,
          );
          expect(
            end.z[i],
            closeTo(i / 400 * math.sin(angle), 1e-12),
            reason: reason,
          );
        }
      }
    }
  });

  test('the page never crosses itself and never passes through the stack or '
      'the surface at the completion angle', () {
    const count = 120;
    for (final completionAngle in completionAngles) {
      final angle = completionAngle * math.pi / 180;
      final surfaceY = 3 * math.cos(angle), surfaceZ = 3 * math.sin(angle);
      for (final curlIntensity in const [0.05, 0.25, 1.0, 4.0, 20.0]) {
        for (var k = 1; k < 100; k++) {
          final t = k / 100;
          final (:y, :z) = strips(
            t,
            curlIntensity: curlIntensity,
            completionAngle: completionAngle,
            count: count,
          );
          final reason = 't $t curl $curlIntensity angle $completionAngle';
          for (var a = 0; a < count; a++) {
            for (var b = a + 2; b < count; b++) {
              expect(
                crosses(
                  y[a],
                  z[a],
                  y[a + 1],
                  z[a + 1],
                  y[b],
                  z[b],
                  y[b + 1],
                  z[b + 1],
                ),
                isFalse,
                reason: reason,
              );
            }
            // Through the stack: from one side of the original page to the
            // other, between the hinge and the free edge's starting place.
            final z0 = z[a], z1 = z[a + 1];
            if (z0 * z1 < 0) {
              final across = y[a] + (y[a + 1] - y[a]) * z0 / (z0 - z1);
              expect(across > 0 && across < 1, isFalse, reason: reason);
            }
            // Through the surface, out from the hinge; at 360 the surface is
            // the back of the stack.
            if (a > 0 && completionAngle < 360) {
              expect(
                crosses(
                  y[a],
                  z[a],
                  y[a + 1],
                  z[a + 1],
                  0,
                  0,
                  surfaceY,
                  surfaceZ,
                ),
                isFalse,
                reason: reason,
              );
            }
          }
        }
      }
    }
  });

  test('the free edge only moves on around the hinge toward its resting '
      'place, never back and never past it', () {
    for (final completionAngle in completionAngles) {
      final angle = completionAngle * math.pi / 180;
      for (final curlIntensity in const [0.05, 0.25, 1.0, 4.0, 20.0]) {
        var last = 0.0;
        for (var k = 1; k <= 200; k++) {
          final t = k / 200;
          final (:y, :z) = strips(
            t,
            curlIntensity: curlIntensity,
            completionAngle: completionAngle,
            count: 150,
          );
          // The edge's angle around the hinge from the flat page, followed
          // continuously through the turn.
          var around = math.atan2(z.last, y.last);
          while (around < last - math.pi) {
            around += 2 * math.pi;
          }
          while (around > last + math.pi) {
            around -= 2 * math.pi;
          }
          final reason = 't $t curl $curlIntensity angle $completionAngle';
          expect(around, greaterThanOrEqualTo(last - 1e-9), reason: reason);
          expect(around, lessThanOrEqualTo(angle + 1e-9), reason: reason);
          last = around;
        }
      }
    }
  });

  test('short of a full turn, the page lands on the surface from the hinge '
      'out, the free edge last', () {
    const count = 150;
    for (final completionAngle in const [180.0, 225.0, 270.0]) {
      final angle = completionAngle * math.pi / 180;
      final cos = math.cos(angle), sin = math.sin(angle);
      for (final curlIntensity in const [0.25, 1.0, 8.0]) {
        // When the page, from the hinge to each third of its length, first
        // lies within a hundredth of its length of the surface.
        final landed = <double?>[null, null, null];
        for (var k = 0; k <= 1000; k++) {
          final t = k / 1000;
          final (:y, :z) = strips(
            t,
            curlIntensity: curlIntensity,
            completionAngle: completionAngle,
            count: count,
          );
          // How many strip ends from the hinge out lie on the surface: off its
          // line by under a hundredth, and not behind the hinge.
          var onSurface = 0;
          bool onTheSurface(int i) =>
              (y[i] * sin - z[i] * cos).abs() < 0.01 &&
              y[i] * cos + z[i] * sin > -0.01;
          while (onSurface < count && onTheSurface(onSurface + 1)) {
            onSurface++;
          }
          for (var third = 0; third < 3; third++) {
            if (landed[third] == null && onSurface >= (third + 1) * 50) {
              landed[third] = t;
            }
          }
        }
        final reason = 'curl $curlIntensity angle $completionAngle: $landed';
        expect(landed[0]!, lessThan(landed[1]!), reason: reason);
        expect(landed[1]!, lessThan(landed[2]!), reason: reason);
      }
    }
  });

  // The approved turn, pinned so any change to its formulas is noticed: the
  // page's points at s = 0.25, 0.5, 0.75 and 1, as stripEnds gives them at
  // 2000 strips, to six decimals.
  test('matches the turn', () {
    const reference = [
      (
        t: 0.2,
        curlIntensity: 1.0,
        completionAngle: 360.0,
        points: [
          (0.248206, 0.029826),
          (0.491694, 0.084599),
          (0.700275, 0.217581),
          (0.793504, 0.444666),
        ],
      ),
      (
        t: 0.45,
        curlIntensity: 1.0,
        completionAngle: 360.0,
        points: [
          (0.147144, 0.201138),
          (0.170167, 0.443617),
          (-0.003624, 0.610469),
          (-0.251448, 0.619090),
        ],
      ),
      (
        t: 0.6,
        curlIntensity: 1.0,
        completionAngle: 360.0,
        points: [
          (-0.105267, 0.220558),
          (-0.339425, 0.242902),
          (-0.476069, 0.042503),
          (-0.499349, -0.206026),
        ],
      ),
      (
        t: 0.8,
        curlIntensity: 1.0,
        completionAngle: 360.0,
        points: [
          (-0.101814, -0.204715),
          (0.072849, -0.369771),
          (0.318939, -0.408615),
          (0.568773, -0.417609),
        ],
      ),
      (
        t: 0.3,
        curlIntensity: 0.25,
        completionAngle: 360.0,
        points: [
          (0.236795, 0.080061),
          (0.456496, 0.197477),
          (0.606813, 0.393320),
          (0.630659, 0.639695),
        ],
      ),
      (
        t: 0.7,
        curlIntensity: 4.0,
        completionAngle: 360.0,
        points: [
          (-0.231369, 0.006731),
          (-0.252654, -0.220952),
          (-0.048354, -0.356449),
          (0.194110, -0.417039),
        ],
      ),
      (
        t: 0.5,
        curlIntensity: 12.0,
        completionAngle: 360.0,
        points: [
          (0.071484, 0.236725),
          (-0.061186, 0.430314),
          (-0.283846, 0.357072),
          (-0.374513, 0.126461),
        ],
      ),
      (
        t: 0.95,
        curlIntensity: 1.0,
        completionAngle: 360.0,
        points: [
          (0.224301, -0.102272),
          (0.473189, -0.122741),
          (0.723179, -0.124440),
          (0.973179, -0.124461),
        ],
      ),
      (
        t: 0.5,
        curlIntensity: 1.0,
        completionAngle: 180.0,
        points: [
          (-0.049281, 0.244598),
          (-0.181234, 0.454166),
          (-0.389769, 0.590099),
          (-0.597540, 0.726050),
        ],
      ),
      (
        t: 0.6,
        curlIntensity: 4.0,
        completionAngle: 180.0,
        points: [
          (-0.178453, 0.174439),
          (-0.395220, 0.297691),
          (-0.618406, 0.409105),
          (-0.719691, 0.621592),
        ],
      ),
      (
        t: 0.9,
        curlIntensity: 1.0,
        completionAngle: 180.0,
        points: [
          (-0.249995, 0.001493),
          (-0.499982, 0.003739),
          (-0.749583, 0.016677),
          (-0.994564, 0.064077),
        ],
      ),
      (
        t: 0.8,
        curlIntensity: 1.0,
        completionAngle: 225.0,
        points: [
          (-0.216922, -0.123498),
          (-0.411561, -0.280203),
          (-0.603042, -0.440847),
          (-0.818821, -0.565353),
        ],
      ),
      (
        t: 0.7,
        curlIntensity: 8.0,
        completionAngle: 270.0,
        points: [
          (-0.241733, -0.044814),
          (-0.399845, -0.232996),
          (-0.474996, -0.471219),
          (-0.595395, -0.687072),
        ],
      ),
      (
        t: 0.4,
        curlIntensity: 0.25,
        completionAngle: 315.0,
        points: [
          (0.171892, 0.181247),
          (0.280024, 0.403982),
          (0.245477, 0.646966),
          (0.085587, 0.837261),
        ],
      ),
    ];
    const count = 2000;
    for (final r in reference) {
      final (:y, :z) = strips(
        r.t,
        curlIntensity: r.curlIntensity,
        completionAngle: r.completionAngle,
        count: count,
      );
      for (var k = 0; k < 4; k++) {
        final i = (k + 1) * count ~/ 4;
        expect(y[i], closeTo(r.points[k].$1, 1e-5), reason: '$r');
        expect(z[i], closeTo(r.points[k].$2, 1e-5), reason: '$r');
      }
    }
  });

  // The approved turn from a finger start, pinned so any change to its
  // formulas is noticed: the page's points at s = 0.25, 0.5, 0.75 and 1, while
  // the finger pushes the page and as it turns, as stripEnds gives them at
  // 2000 strips, to six decimals.
  test('matches the turn from a finger start', () {
    const reference = [
      (
        t: 0.06,
        curlIntensity: 1.0,
        completionAngle: 360.0,
        fingerStart: 0.3,
        points: [
          (0.250000, 0.000278),
          (0.499999, 0.000954),
          (0.749997, 0.000192),
          (0.999997, 0.000000),
        ],
      ),
      (
        t: 0.15,
        curlIntensity: 1.0,
        completionAngle: 360.0,
        fingerStart: 0.3,
        points: [
          (0.245367, 0.045388),
          (0.473722, 0.145028),
          (0.712690, 0.079264),
          (0.949724, -0.000014),
        ],
      ),
      (
        t: 0.4,
        curlIntensity: 1.0,
        completionAngle: 360.0,
        fingerStart: 0.3,
        points: [
          (0.154829, 0.192148),
          (0.204507, 0.427302),
          (0.423922, 0.338519),
          (0.631346, 0.198966),
        ],
      ),
      (
        t: 0.1,
        curlIntensity: 1.0,
        completionAngle: 360.0,
        fingerStart: 0.6,
        points: [
          (0.249083, 0.018931),
          (0.498605, 0.011235),
          (0.748425, 0.001999),
          (0.998410, 0.000000),
        ],
      ),
      (
        t: 0.3,
        curlIntensity: 1.0,
        completionAngle: 360.0,
        fingerStart: 0.6,
        points: [
          (0.134900, 0.194002),
          (0.371321, 0.189863),
          (0.617155, 0.144416),
          (0.862996, 0.099003),
        ],
      ),
      (
        t: 0.2,
        curlIntensity: 1.0,
        completionAngle: 180.0,
        fingerStart: 0.3,
        points: [
          (0.206048, 0.136017),
          (0.328073, 0.343973),
          (0.513030, 0.195701),
          (0.671886, 0.002661),
        ],
      ),
      (
        t: 0.5,
        curlIntensity: 1.0,
        completionAngle: 180.0,
        fingerStart: 0.6,
        points: [
          (-0.068681, 0.234765),
          (-0.047405, 0.481911),
          (-0.030171, 0.731265),
          (-0.016200, 0.980835),
        ],
      ),
      (
        t: 0.3,
        curlIntensity: 4.0,
        completionAngle: 225.0,
        fingerStart: 0.9,
        points: [
          (0.188116, 0.130408),
          (0.420551, 0.222462),
          (0.652986, 0.314516),
          (0.885421, 0.406570),
        ],
      ),
    ];
    const count = 2000;
    for (final r in reference) {
      final (:y, :z, directions: _) = PageTurnPainter.stripEnds(
        t: r.t,
        curlIntensity: r.curlIntensity,
        completionAngle: r.completionAngle,
        fingerStart: r.fingerStart,
        strips: count,
      );
      for (var k = 0; k < 4; k++) {
        final i = (k + 1) * count ~/ 4;
        expect(y[i], closeTo(r.points[k].$1, 1e-5), reason: '$r');
        expect(z[i], closeTo(r.points[k].$2, 1e-5), reason: '$r');
      }
    }
  });
}
