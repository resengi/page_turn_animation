import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:page_turn_animation/page_turn_animation.dart';
import 'package:page_turn_animation/src/page_turn_painter.dart';

void main() {
  late ui.Image image;

  setUpAll(() async {
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawRect(
      const Rect.fromLTWH(0, 0, 300, 400),
      Paint()..color = Colors.blue,
    );
    image = await recorder.endRecording().toImage(300, 400);
  });

  tearDownAll(() => image.dispose());

  /// Whether the painter draws anything of a 300 by 400 page hinged at the
  /// top, at [progress] of a turn in [direction] with the turn's completion
  /// angle, finger start and segments.
  bool draws(
    double progress,
    PageTurnDirection direction,
    (double, double, int) turn,
  ) {
    final (completionAngle, fingerStart, segments) = turn;
    final canvas = TestRecordingCanvas();
    PageTurnPainter(
      image: image,
      progress: progress,
      direction: direction,
      edge: PageTurnEdge.top,
      completionAngle: completionAngle,
      fingerStart: fingerStart,
      style: PageTurnStyle(segments: segments),
    ).paint(canvas, const Size(300, 400));
    return canvas.invocations.isNotEmpty;
  }

  /// Progress through a turn, every two-hundredth from 0 to 1.
  final steps = [for (var k = 0; k <= 200; k++) k / 200];

  test('a turn whose page lands behind the stack shows the page at every '
      'progress but its end, and a backward one at every progress but its '
      'start', () {
    // Each turn differs from the one before in one of its inputs. The page
    // goes out of sight within a ten-thousandth of the turn of progress 1, so
    // a thousandth short of it the page is in sight.
    const turns = [
      (360.0, 0.0, 100),
      (360.0, 0.5, 100),
      (360.0, 0.5, 5),
      (300.0, 0.5, 5),
      (270.0, 0.0, 100),
    ];
    for (final turn in turns) {
      for (final progress in [...steps.where((p) => p < 1), 1 - 1e-3]) {
        expect(
          draws(progress, PageTurnDirection.forward, turn),
          isTrue,
          reason: 'forward $turn at $progress',
        );
        expect(
          draws(1 - progress, PageTurnDirection.backward, turn),
          isTrue,
          reason: 'backward $turn at ${1 - progress}',
        );
      }
      expect(draws(1, PageTurnDirection.forward, turn), isFalse);
      expect(draws(0, PageTurnDirection.backward, turn), isFalse);
    }
  });

  test('a turn whose page lands in sight shows the page at every progress', () {
    for (final completionAngle in [180.0, 225.0, 262.0]) {
      final turn = (completionAngle, 0.0, 100);
      for (final progress in steps) {
        expect(
          draws(progress, PageTurnDirection.forward, turn),
          isTrue,
          reason: 'forward $turn at $progress',
        );
        expect(
          draws(progress, PageTurnDirection.backward, turn),
          isTrue,
          reason: 'backward $turn at $progress',
        );
      }
    }
  });

  test('turns with different settings painted in turn each end as their own '
      'page goes out of sight', () {
    // Ten finger starts, each going out of sight at its own progress, painted
    // in turn twice over.
    final turns = [for (var k = 0; k < 10; k++) (360.0, k / 10 * 0.9, 100)];
    for (var round = 0; round < 2; round++) {
      for (final turn in turns) {
        expect(
          draws(1 - 1e-3, PageTurnDirection.forward, turn),
          isTrue,
          reason: 'round $round, $turn',
        );
        expect(
          draws(1, PageTurnDirection.forward, turn),
          isFalse,
          reason: 'round $round, $turn',
        );
      }
    }
  });
}
