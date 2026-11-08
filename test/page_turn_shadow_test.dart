import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:page_turn_animation/page_turn_animation.dart';
import 'package:page_turn_animation/src/page_turn_constants.dart';
import 'package:page_turn_animation/src/page_turn_painter.dart';
import 'package:page_turn_animation/src/page_turn_shadow.dart';

/// A lamp [height] page lengths over the hinge and [width] wide, over the
/// page's [strips] at turn progress [t].
PageTurnLamp lampOver(
  double t, {
  double completionAngle = PageTurnInputs.standardCompletionAngle,
  double fingerStart = PageTurnInputs.standardFingerStart,
  int strips = 100,
  double height = 2,
  double width = 0.05,
}) {
  final (:y, :z, directions: _) = PageTurnPainter.stripEnds(
    t: t,
    curlIntensity: 1,
    completionAngle: completionAngle,
    fingerStart: fingerStart,
    strips: strips,
  );
  return PageTurnLamp(y: y, z: z, height: height, width: width);
}

/// A lamp 2 page lengths over the hinge and [width] wide, over a flat plank
/// from 0.2 to 0.8 along the stack, [height] above it, in 60 strips.
PageTurnLamp lampOverPlank(double height, {double width = 0.05}) =>
    PageTurnLamp(
      y: Float64List.fromList([for (var k = 0; k <= 60; k++) 0.2 + k / 100]),
      z: Float64List.fromList([for (var k = 0; k <= 60; k++) height]),
      height: 2,
      width: width,
    );

/// A canvas that notes what is drawn on it: each drawing's name and paint.
class _NotingCanvas implements Canvas {
  final calls = <({Symbol name, Paint paint})>[];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls.add((
      name: invocation.memberName,
      paint: invocation.positionalArguments.last as Paint,
    ));
    return null;
  }
}

void main() {
  test('a flat page hides nothing, and flat paper gets all the light', () {
    final lamp = lampOver(0);
    for (var k = 0; k <= 100; k++) {
      expect(lamp.hidden(k / 100, 0), 0, reason: 'stack at ${k / 100}');
      expect(
        lamp.hidden(lamp.y[k], lamp.z[k], skipFrom: k - 2, skipTo: k + 1),
        0,
        reason: 'page at strip end $k',
      );
      expect(lamp.facing(k / 50 - 1, 0, 0, 1), 1, reason: '${k / 50 - 1}');
    }
  });

  test('paper just above a point hides nearly all of the lamp from it, and '
      'the closer it is, the darker the shadow', () {
    var darker = 2.0;
    for (final height in const [0.01, 0.1, 0.3]) {
      final hidden = lampOverPlank(height).hidden(0.5, 0);
      expect(
        hidden,
        closeTo(1 / (1 + PageTurnConstants.shadowFade * height), 0.01),
        reason: 'height $height',
      );
      expect(hidden, lessThan(darker), reason: 'height $height');
      darker = hidden;
    }
  });

  test('the soft edge widens with the paper\'s height, as wide as the lamp '
      'seen from there', () {
    // Past the plank's far end, the shadow fades over the stretch where the
    // lamp is partly hidden: W·h / (H − h) for a lamp W wide at height H and
    // paper at height h. Between 95% and 5% of the full shadow is 90% of it.
    const width = 0.05;
    for (final height in const [0.1, 0.3]) {
      final lamp = lampOverPlank(height, width: width);
      final full = lamp.hidden(0.5, 0);
      double? from, to;
      for (var y = 0.8; y < 1.2 && to == null; y += 1e-5) {
        final hidden = lamp.hidden(y, 0);
        if (from == null && hidden < 0.95 * full) from = y;
        if (hidden < 0.05 * full) to = y;
      }
      final expected = 0.9 * width * height / (2 - height);
      expect(to! - from!, closeTo(expected, 0.1 * expected), reason: '$height');
    }
  });

  test('working out only the strips that can reach a point gives what testing '
      'every strip gives', () {
    for (final completionAngle in const [360.0, 225.0, 180.0]) {
      final angle = completionAngle * math.pi / 180;
      final cos = math.cos(angle), sin = math.sin(angle);
      for (final fingerStart in const [0.0, 0.3]) {
        // A lamp only just above the page, where some lines from it miss the
        // surface past the hinge, and a higher one.
        for (final height in const [1.2, 2.0]) {
          for (var k = 1; k < 20; k++) {
            final t = k / 20;
            final lamp = lampOver(
              t,
              completionAngle: completionAngle,
              fingerStart: fingerStart,
              height: height,
            );
            final reason =
                'angle $completionAngle finger $fingerStart lamp $height t $t';
            final stack = lamp.alongSurface(
              ey: 1,
              ez: 0,
              ny: 0,
              nz: 1,
              reach: 1,
              points: 400,
              seen: (_) => true,
            );
            // The surface past the hinge, at the angles where the painter
            // draws it: seen beside the stack.
            final landing = lamp.alongSurface(
              ey: cos,
              ez: sin,
              ny: sin,
              nz: -cos,
              reach: 1,
              points: 400,
              seen: (_) => true,
            );
            for (var j = 0; j <= 400; j++) {
              final s = j / 400;
              expect(
                stack[j],
                closeTo(lamp.hidden(s, 0), 1e-12),
                reason: '$reason stack $s',
              );
              if (completionAngle < 270) {
                expect(
                  landing[j],
                  closeTo(lamp.hidden(s * cos, s * sin), 1e-12),
                  reason: '$reason landing $s',
                );
              }
            }
          }
        }
      }
    }
  });

  test(
    'curved paper is shaded smoothly, without steps from strip to strip',
    () async {
      // The page rolling over the hinge in a 360° turn, much of it curved, in
      // plain white so only its shading and shadow change across it. It is
      // drawn in memory onto a transparent canvas wide enough for the page's
      // place and the hinge's far side, and one row of pixels across it is
      // read; nothing is saved.
      const page = Size(800, 300);
      final white = ui.PictureRecorder();
      Canvas(white).drawRect(
        const Rect.fromLTWH(0, 0, 160, 60),
        Paint()..color = Colors.white,
      );
      final plain = await white.endRecording().toImage(160, 60);
      final recorder = ui.PictureRecorder();
      PageTurnPainter(
        image: plain,
        progress: 0.57,
        direction: PageTurnDirection.forward,
        edge: PageTurnEdge.left,
        style: const PageTurnStyle(segments: 100),
      ).paint(Canvas(recorder)..translate(page.width, 0), page);
      final drawn = await recorder.endRecording().toImage(
        2 * page.width.toInt(),
        page.height.toInt(),
      );
      final pixels = (await drawn.toByteData())!;
      final row = page.height.toInt() ~/ 2, width = drawn.width;
      bool opaque(int x) => pixels.getUint8(4 * (row * width + x) + 3) == 255;
      double brightness(int x) {
        final at = 4 * (row * width + x);
        return (pixels.getUint8(at) +
                pixels.getUint8(at + 1) +
                pixels.getUint8(at + 2)) /
            3;
      }

      // A strip-to-strip step is a change from one pixel to the next that is
      // 2.5 or more (of 255) away from the slope over the three pixels on
      // either side; shading worked out once for each strip makes one at each
      // strip's edge. Where the page is drawn in full, there is none.
      final steps = <int>[];
      for (var x = 3; x + 4 < width; x++) {
        var drawnInFull = true;
        for (var j = x - 3; j <= x + 4; j++) {
          drawnInFull = drawnInFull && opaque(j);
        }
        if (!drawnInFull) continue;
        final slope =
            (brightness(x) -
                brightness(x - 3) +
                brightness(x + 4) -
                brightness(x + 1)) /
            6;
        final change = brightness(x + 1) - brightness(x);
        if ((change - slope).abs() >= 2.5) steps.add(x);
      }
      expect(steps, isEmpty);
      plain.dispose();
      drawn.dispose();
    },
  );

  test('at an opacity of 0 nothing but the page is drawn', () async {
    final recorder = ui.PictureRecorder();
    Canvas(
      recorder,
    ).drawRect(const Rect.fromLTWH(0, 0, 10, 10), Paint()..color = Colors.blue);
    final image = await recorder.endRecording().toImage(10, 10);
    PageTurnPainter painter(double opacity) => PageTurnPainter(
      image: image,
      progress: 0.3,
      direction: PageTurnDirection.forward,
      edge: PageTurnEdge.left,
      style: PageTurnStyle(shadowOpacity: opacity, segments: 100),
    );

    // Only the strips: slices of the image and the plain reverse, none drawn
    // with a gradient.
    final without = _NotingCanvas();
    painter(0).paint(without, const Size(300, 200));
    expect(without.calls, isNotEmpty);
    expect(
      without.calls.map((call) => call.name).toSet(),
      everyElement(anyOf(#drawImageRect, #drawRect)),
    );
    expect(without.calls.where((call) => call.paint.shader != null), isEmpty);

    // With shadows: the same strips, and the shadows drawn with gradients.
    final withShadows = _NotingCanvas();
    painter(0.9).paint(withShadows, const Size(300, 200));
    expect(
      withShadows.calls.where((call) => call.paint.shader == null),
      hasLength(without.calls.length),
    );
    expect(
      withShadows.calls.where((call) => call.paint.shader != null),
      isNotEmpty,
    );
    image.dispose();
  });
}
