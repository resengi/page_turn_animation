import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:page_turn_animation/page_turn_animation.dart';
import 'package:page_turn_animation/src/page_turn_painter.dart';

// Helper to create a test image
Future<ui.Image> createTestImage({
  int width = 100,
  int height = 100,
  Color color = Colors.blue,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint()..color = color;
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    paint,
  );
  final picture = recorder.endRecording();
  return picture.toImage(width, height);
}

void main() {
  group('PageTurnPainter', () {
    late ui.Image testImage;

    setUpAll(() async {
      testImage = await createTestImage();
    });

    tearDownAll(() {
      testImage.dispose();
    });

    group('shouldRepaint', () {
      test('returns true when progress changes', () {
        final painter1 = PageTurnPainter(
          image: testImage,
          progress: 0.0,
          direction: PageTurnDirection.forward,
          edge: PageTurnEdge.top,
          style: const PageTurnStyle(),
        );

        final painter2 = PageTurnPainter(
          image: testImage,
          progress: 0.5,
          direction: PageTurnDirection.forward,
          edge: PageTurnEdge.top,
          style: const PageTurnStyle(),
        );

        expect(painter1.shouldRepaint(painter2), isTrue);
      });

      test('returns true when direction changes', () {
        final painter1 = PageTurnPainter(
          image: testImage,
          progress: 0.5,
          direction: PageTurnDirection.forward,
          edge: PageTurnEdge.top,
          style: const PageTurnStyle(),
        );

        final painter2 = PageTurnPainter(
          image: testImage,
          progress: 0.5,
          direction: PageTurnDirection.backward,
          edge: PageTurnEdge.top,
          style: const PageTurnStyle(),
        );

        expect(painter1.shouldRepaint(painter2), isTrue);
      });

      test('returns true when edge changes', () {
        final painter1 = PageTurnPainter(
          image: testImage,
          progress: 0.5,
          direction: PageTurnDirection.forward,
          edge: PageTurnEdge.top,
          style: const PageTurnStyle(),
        );

        final painter2 = PageTurnPainter(
          image: testImage,
          progress: 0.5,
          direction: PageTurnDirection.forward,
          edge: PageTurnEdge.bottom,
          style: const PageTurnStyle(),
        );

        expect(painter1.shouldRepaint(painter2), isTrue);
      });

      test('returns true when style changes', () {
        final painter1 = PageTurnPainter(
          image: testImage,
          progress: 0.5,
          direction: PageTurnDirection.forward,
          edge: PageTurnEdge.top,
          style: const PageTurnStyle(shadowOpacity: 0.5),
        );

        final painter2 = PageTurnPainter(
          image: testImage,
          progress: 0.5,
          direction: PageTurnDirection.forward,
          edge: PageTurnEdge.top,
          style: const PageTurnStyle(shadowOpacity: 0.9),
        );

        expect(painter1.shouldRepaint(painter2), isTrue);
      });

      test('returns true when completionAngle changes', () {
        final painter1 = PageTurnPainter(
          image: testImage,
          progress: 0.5,
          direction: PageTurnDirection.forward,
          edge: PageTurnEdge.top,
          style: const PageTurnStyle(),
        );

        final painter2 = PageTurnPainter(
          image: testImage,
          progress: 0.5,
          direction: PageTurnDirection.forward,
          edge: PageTurnEdge.top,
          style: const PageTurnStyle(),
          completionAngle: 225,
        );

        expect(painter1.shouldRepaint(painter2), isTrue);
      });

      test('returns true when fingerStart changes', () {
        final painter1 = PageTurnPainter(
          image: testImage,
          progress: 0.5,
          direction: PageTurnDirection.forward,
          edge: PageTurnEdge.top,
          style: const PageTurnStyle(),
        );

        final painter2 = PageTurnPainter(
          image: testImage,
          progress: 0.5,
          direction: PageTurnDirection.forward,
          edge: PageTurnEdge.top,
          style: const PageTurnStyle(),
          fingerStart: 0.4,
        );

        expect(painter1.shouldRepaint(painter2), isTrue);
      });

      test('returns true when backImage changes', () {
        final painter1 = PageTurnPainter(
          image: testImage,
          progress: 0.5,
          direction: PageTurnDirection.forward,
          edge: PageTurnEdge.top,
          style: const PageTurnStyle(),
        );

        final painter2 = PageTurnPainter(
          image: testImage,
          progress: 0.5,
          direction: PageTurnDirection.forward,
          edge: PageTurnEdge.top,
          style: const PageTurnStyle(),
          backImage: testImage,
        );

        expect(painter1.shouldRepaint(painter2), isTrue);
      });

      test('returns false when all properties are the same', () {
        final painter1 = PageTurnPainter(
          image: testImage,
          progress: 0.5,
          direction: PageTurnDirection.forward,
          edge: PageTurnEdge.top,
          style: const PageTurnStyle(),
        );

        final painter2 = PageTurnPainter(
          image: testImage,
          progress: 0.5,
          direction: PageTurnDirection.forward,
          edge: PageTurnEdge.top,
          style: const PageTurnStyle(),
        );

        expect(painter1.shouldRepaint(painter2), isFalse);
      });
    });

    group('paint', () {
      test('handles zero size gracefully', () {
        final painter = PageTurnPainter(
          image: testImage,
          progress: 0.5,
          direction: PageTurnDirection.forward,
          edge: PageTurnEdge.top,
          style: const PageTurnStyle(),
        );

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);

        // Should not throw
        expect(() => painter.paint(canvas, Size.zero), returnsNormally);
      });

      test('handles negative size gracefully', () {
        final painter = PageTurnPainter(
          image: testImage,
          progress: 0.5,
          direction: PageTurnDirection.forward,
          edge: PageTurnEdge.top,
          style: const PageTurnStyle(),
        );

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);

        // Should not throw
        expect(
          () => painter.paint(canvas, const Size(-100, -100)),
          returnsNormally,
        );
      });

      test('handles progress at 0.0', () {
        final painter = PageTurnPainter(
          image: testImage,
          progress: 0.0,
          direction: PageTurnDirection.forward,
          edge: PageTurnEdge.top,
          style: const PageTurnStyle(),
        );

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);

        expect(
          () => painter.paint(canvas, const Size(200, 300)),
          returnsNormally,
        );
      });

      test('handles progress at 1.0', () {
        final painter = PageTurnPainter(
          image: testImage,
          progress: 1.0,
          direction: PageTurnDirection.forward,
          edge: PageTurnEdge.top,
          style: const PageTurnStyle(),
        );

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);

        expect(
          () => painter.paint(canvas, const Size(200, 300)),
          returnsNormally,
        );
      });

      test('handles progress values outside 0-1 range (clamped)', () {
        final painter1 = PageTurnPainter(
          image: testImage,
          progress: -0.5,
          direction: PageTurnDirection.forward,
          edge: PageTurnEdge.top,
          style: const PageTurnStyle(),
        );

        final painter2 = PageTurnPainter(
          image: testImage,
          progress: 1.5,
          direction: PageTurnDirection.forward,
          edge: PageTurnEdge.top,
          style: const PageTurnStyle(),
        );

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);

        expect(
          () => painter1.paint(canvas, const Size(200, 300)),
          returnsNormally,
        );

        expect(
          () => painter2.paint(canvas, const Size(200, 300)),
          returnsNormally,
        );
      });

      test('paints with forward direction', () {
        final painter = PageTurnPainter(
          image: testImage,
          progress: 0.5,
          direction: PageTurnDirection.forward,
          edge: PageTurnEdge.top,
          style: const PageTurnStyle(),
        );

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);

        expect(
          () => painter.paint(canvas, const Size(200, 300)),
          returnsNormally,
        );
      });

      test('paints with backward direction', () {
        final painter = PageTurnPainter(
          image: testImage,
          progress: 0.5,
          direction: PageTurnDirection.backward,
          edge: PageTurnEdge.top,
          style: const PageTurnStyle(),
        );

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);

        expect(
          () => painter.paint(canvas, const Size(200, 300)),
          returnsNormally,
        );
      });

      test('respects custom style', () {
        final painter = PageTurnPainter(
          image: testImage,
          progress: 0.5,
          direction: PageTurnDirection.forward,
          edge: PageTurnEdge.top,
          style: const PageTurnStyle(
            shadowOpacity: 0.3,
            segments: 50,
            curlIntensity: 2.0,
          ),
        );

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);

        expect(
          () => painter.paint(canvas, const Size(200, 300)),
          returnsNormally,
        );
      });

      test('handles very small segment count', () {
        final painter = PageTurnPainter(
          image: testImage,
          progress: 0.5,
          direction: PageTurnDirection.forward,
          edge: PageTurnEdge.top,
          style: const PageTurnStyle(segments: 1),
        );

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);

        expect(
          () => painter.paint(canvas, const Size(200, 300)),
          returnsNormally,
        );
      });

      test('handles large segment count', () {
        final painter = PageTurnPainter(
          image: testImage,
          progress: 0.5,
          direction: PageTurnDirection.forward,
          edge: PageTurnEdge.top,
          style: const PageTurnStyle(segments: 500),
        );

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);

        expect(
          () => painter.paint(canvas, const Size(200, 300)),
          returnsNormally,
        );
      });
    });

    group('hidden paper', () {
      const page = Size(300, 200);

      /// The strips a forward turn at [progress] draws over a left hinge, with
      /// [curlIntensity] and [completionAngle], in 150 strips and without
      /// shadows, in the order it draws them (a [_StripCanvas]).
      List<({Rect rect, bool front})> drawn(
        double progress, {
        double curlIntensity = 1,
        double completionAngle = PageTurnInputs.standardCompletionAngle,
      }) {
        final canvas = _StripCanvas();
        PageTurnPainter(
          image: testImage,
          progress: progress,
          direction: PageTurnDirection.forward,
          edge: PageTurnEdge.left,
          style: PageTurnStyle(
            shadowOpacity: 0,
            segments: 150,
            curlIntensity: curlIntensity,
          ),
          completionAngle: completionAngle,
        ).paint(canvas, page);
        expect(canvas.other, isEmpty);
        return canvas.strips;
      }

      /// How much of the page's length, in logical pixels, the [strips] are
      /// drawn over, counting where they overlap once.
      double drawnLength(List<({Rect rect, bool front})> strips) {
        final spans = [for (final s in strips) (s.rect.left, s.rect.right)]
          ..sort((a, b) => a.$1.compareTo(b.$1));
        var length = 0.0, reached = double.negativeInfinity;
        for (final (start, end) in spans) {
          length += math.max(0.0, end - math.max(start, reached));
          reached = math.max(reached, end);
        }
        return length;
      }

      test('at the start of the turn, the page lies flat over itself, '
          'showing its front', () {
        final strips = drawn(0)
          ..sort((a, b) => a.rect.left.compareTo(b.rect.left));
        expect(strips, hasLength(150));
        for (var k = 0; k < 150; k++) {
          expect(strips[k].front, isTrue, reason: 'strip $k');
          expect(strips[k].rect.left, closeTo(2.0 * k, 1e-9), reason: '$k');
          expect(strips[k].rect.width, closeTo(2, 1e-9), reason: 'strip $k');
        }
      });

      test('at the end of the turn nothing is drawn, at any curl '
          'intensity', () {
        // The page lies on the back of the stack, where the original page lay;
        // its computed height there is just below the original page's level,
        // so none of it is seen.
        for (final curlIntensity in const [0.25, 1.0, 4.0]) {
          expect(
            drawn(1, curlIntensity: curlIntensity),
            isEmpty,
            reason: 'curl $curlIntensity',
          );
        }
      });

      test('at the end of a 180° turn the page lies flat beside the stack, '
          'showing its reverse, at any curl intensity', () {
        for (final curlIntensity in const [0.25, 1.0, 4.0]) {
          final strips = drawn(
            1,
            curlIntensity: curlIntensity,
            completionAngle: 180,
          )..sort((a, b) => a.rect.left.compareTo(b.rect.left));
          expect(strips, hasLength(150));
          for (var k = 0; k < 150; k++) {
            final reason = 'curl $curlIntensity strip $k';
            expect(strips[k].front, isFalse, reason: reason);
            expect(
              strips[k].rect.left,
              closeTo(-300 + 2.0 * k, 1e-6),
              reason: reason,
            );
            expect(strips[k].rect.width, closeTo(2, 1e-6), reason: reason);
          }
        }
      });

      test('what is drawn of the page changes smoothly through the turn, at '
          'any curl intensity', () {
        // From one step of progress to the next (0.002), how much of the
        // page's length is drawn changes by less than 6 of its 300 logical
        // pixels, and at most 6 strips are shown or hidden: no more paper than
        // that is hidden or shown all at once.
        for (final curlIntensity in const [0.25, 1.0, 4.0]) {
          var previous = drawn(0, curlIntensity: curlIntensity);
          for (var i = 1; i <= 500; i++) {
            final progress = i / 500;
            final current = drawn(progress, curlIntensity: curlIntensity);
            final reason = 'curl $curlIntensity progress $progress';
            expect(
              (drawnLength(current) - drawnLength(previous)).abs(),
              lessThan(6),
              reason: reason,
            );
            expect(
              (current.length - previous.length).abs(),
              lessThanOrEqualTo(6),
              reason: reason,
            );
            previous = current;
          }
        }
      });

      test('as the page comes down the back of the stack, only its rounded '
          'top over the hinge is seen, showing its reverse', () {
        // The page has rolled over the hinge: its top, beyond the hinge, shows
        // the page's plain reverse, and the rest hangs down the back of the
        // stack under the original page, where none of it is drawn. Wherever
        // the page is drawn, the strip drawn last there shows the reverse.
        for (final progress in const [0.65, 0.75, 0.8]) {
          final strips = drawn(progress);
          expect(strips, isNotEmpty, reason: 'progress $progress');
          for (final strip in strips) {
            expect(
              strip.rect.right,
              lessThanOrEqualTo(1e-9),
              reason: 'progress $progress',
            );
          }
          for (var x = -300.0; x < 0; x += 0.25) {
            final top = strips.lastWhere(
              (s) => s.rect.left <= x && x <= s.rect.right,
              orElse: () => (rect: Rect.zero, front: false),
            );
            expect(top.front, isFalse, reason: 'progress $progress x $x');
          }
        }
      });
    });

    group('back of the page', () {
      const page = Size(300, 200);
      late ui.Image frontImage, backImage;

      setUpAll(() async {
        // Neither square nor the same size, so each image's slices are its
        // own, along the page and across it.
        frontImage = await createTestImage(width: 80, height: 50);
        backImage = await createTestImage(
          width: 60,
          height: 90,
          color: Colors.red,
        );
      });

      tearDownAll(() {
        frontImage.dispose();
        backImage.dispose();
      });

      /// What the painter draws for a turn with [backImage] or without one,
      /// in the order it draws it (a [_CallCanvas]).
      List<Invocation> drawn({
        required PageTurnEdge edge,
        required double progress,
        PageTurnDirection direction = PageTurnDirection.forward,
        double completionAngle = PageTurnInputs.standardCompletionAngle,
        double shadowOpacity = 0.9,
        ui.Image? backImage,
      }) {
        final canvas = _CallCanvas();
        PageTurnPainter(
          image: frontImage,
          backImage: backImage,
          progress: progress,
          direction: direction,
          edge: edge,
          style: PageTurnStyle(shadowOpacity: shadowOpacity, segments: 150),
          completionAngle: completionAngle,
        ).paint(canvas, page);
        return canvas.calls;
      }

      /// Expects the 150 strips [calls] draws to lay [image] flat over the
      /// page's place from [start] along the canvas, the right way round:
      /// along the page, the strips cover the page's length and their slices
      /// the image's, with the image's start at the place's start, not
      /// mirrored; across, each covers the page's width with the image's.
      void expectLaidFlat(
        List<Invocation> calls,
        ui.Image image, {
        required PageTurnEdge edge,
        required double start,
        required String reason,
      }) {
        expect(calls, hasLength(150), reason: reason);
        final vertical = edge.isVerticalAxis;
        final pageLength = vertical ? page.height : page.width;
        final pageWidth = vertical ? page.width : page.height;
        final imageLength = (vertical ? image.height : image.width).toDouble();
        final imageWidth = (vertical ? image.width : image.height).toDouble();
        var covered = 0.0, first = double.infinity;
        for (final call in calls) {
          expect(call.memberName, #drawImageRect, reason: reason);
          final [drawnImage, src as Rect, dst as Rect, _] =
              call.positionalArguments;
          expect(drawnImage, same(image), reason: reason);
          final (srcAlong, srcAcross) = vertical
              ? ((src.top, src.height), (src.left, src.width))
              : ((src.left, src.width), (src.top, src.height));
          final (dstAlong, dstAcross) = vertical
              ? ((dst.top, dst.height), (dst.left, dst.width))
              : ((dst.left, dst.width), (dst.top, dst.height));
          expect(
            srcAlong.$1 / imageLength,
            closeTo((dstAlong.$1 - start) / pageLength, 1e-6),
            reason: reason,
          );
          expect(
            srcAlong.$2 / imageLength,
            closeTo(dstAlong.$2 / pageLength, 1e-6),
            reason: reason,
          );
          expect(srcAcross, (0.0, imageWidth), reason: reason);
          expect(dstAcross.$1, closeTo(0, 1e-6), reason: reason);
          expect(dstAcross.$2, closeTo(pageWidth, 1e-6), reason: reason);
          covered += dstAlong.$2;
          first = math.min(first, dstAlong.$1);
        }
        expect(first, closeTo(start, 1e-6), reason: reason);
        expect(covered, closeTo(pageLength, 1e-6), reason: reason);
      }

      test('each strip that shows the plain reverse without a back image '
          'shows its slice of the back image with one, in the same place, '
          'and everything else is drawn the same', () {
        for (final edge in PageTurnEdge.values) {
          for (final completionAngle in const [360.0, 180.0]) {
            for (final progress in const [0.3, 0.5, 0.75]) {
              final reason =
                  '${edge.name} angle $completionAngle progress $progress';
              final plain = drawn(
                edge: edge,
                progress: progress,
                completionAngle: completionAngle,
              );
              final backed = drawn(
                edge: edge,
                progress: progress,
                completionAngle: completionAngle,
                backImage: backImage,
              );
              expect(backed, hasLength(plain.length), reason: reason);
              var backs = 0;
              for (var k = 0; k < plain.length; k++) {
                final was = plain[k].positionalArguments;
                final now = backed[k].positionalArguments;
                // A rect filled without a gradient is a strip's plain reverse;
                // with one, it is the shadow on a strip.
                if (plain[k].memberName == #drawRect &&
                    (was[1] as Paint).shader == null) {
                  expect(backed[k].memberName, #drawImageRect, reason: reason);
                  expect(now[0], same(backImage), reason: reason);
                  expect(now[2], was[0], reason: reason);
                  backs++;
                  continue;
                }
                expect(
                  backed[k].memberName,
                  plain[k].memberName,
                  reason: reason,
                );
                if (plain[k].memberName == #drawImageRect) {
                  expect(now[0], same(frontImage), reason: reason);
                  expect(now.sublist(1, 3), was.sublist(1, 3), reason: reason);
                } else if (plain[k].memberName == #drawRect) {
                  expect(now[0], was[0], reason: reason);
                }
              }
              expect(backs, greaterThan(0), reason: reason);
            }
          }
        }
      });

      test('at the start of the turn, the front image lies over the stack '
          'the right way round, on every edge and in either direction', () {
        // A backward turn ends where a forward turn starts.
        const starts = [
          (PageTurnDirection.forward, 0.0),
          (PageTurnDirection.backward, 1.0),
        ];
        for (final edge in PageTurnEdge.values) {
          for (final (direction, progress) in starts) {
            expectLaidFlat(
              drawn(
                edge: edge,
                progress: progress,
                direction: direction,
                shadowOpacity: 0,
                backImage: backImage,
              ),
              frontImage,
              edge: edge,
              start: 0,
              reason: '${edge.name} ${direction.name}',
            );
          }
        }
      });

      test('at the end of a 180° turn, the back image lies beside the stack '
          'the right way round, on every edge and in either direction', () {
        // A backward turn starts where a forward turn ends.
        const ends = [
          (PageTurnDirection.forward, 1.0),
          (PageTurnDirection.backward, 0.0),
        ];
        for (final edge in PageTurnEdge.values) {
          final pageLength = edge.isVerticalAxis ? page.height : page.width;
          for (final (direction, progress) in ends) {
            expectLaidFlat(
              drawn(
                edge: edge,
                progress: progress,
                direction: direction,
                completionAngle: 180,
                shadowOpacity: 0,
                backImage: backImage,
              ),
              backImage,
              edge: edge,
              start: edge.requiresCoordinateFlip ? pageLength : -pageLength,
              reason: '${edge.name} ${direction.name}',
            );
          }
        }
      });
    });

    group('edge support', () {
      for (final edge in PageTurnEdge.values) {
        group('${edge.name} edge', () {
          test('paints at progress 0.0', () {
            final painter = PageTurnPainter(
              image: testImage,
              progress: 0.0,
              direction: PageTurnDirection.forward,
              edge: edge,
              style: const PageTurnStyle(),
            );

            final recorder = ui.PictureRecorder();
            final canvas = Canvas(recorder);

            expect(
              () => painter.paint(canvas, const Size(200, 300)),
              returnsNormally,
            );
          });

          test('paints at progress 0.5', () {
            final painter = PageTurnPainter(
              image: testImage,
              progress: 0.5,
              direction: PageTurnDirection.forward,
              edge: edge,
              style: const PageTurnStyle(),
            );

            final recorder = ui.PictureRecorder();
            final canvas = Canvas(recorder);

            expect(
              () => painter.paint(canvas, const Size(200, 300)),
              returnsNormally,
            );
          });

          test('paints at progress 1.0', () {
            final painter = PageTurnPainter(
              image: testImage,
              progress: 1.0,
              direction: PageTurnDirection.forward,
              edge: edge,
              style: const PageTurnStyle(),
            );

            final recorder = ui.PictureRecorder();
            final canvas = Canvas(recorder);

            expect(
              () => painter.paint(canvas, const Size(200, 300)),
              returnsNormally,
            );
          });

          test('paints with forward direction', () {
            final painter = PageTurnPainter(
              image: testImage,
              progress: 0.5,
              direction: PageTurnDirection.forward,
              edge: edge,
              style: const PageTurnStyle(),
            );

            final recorder = ui.PictureRecorder();
            final canvas = Canvas(recorder);

            expect(
              () => painter.paint(canvas, const Size(200, 300)),
              returnsNormally,
            );
          });

          test('paints with backward direction', () {
            final painter = PageTurnPainter(
              image: testImage,
              progress: 0.5,
              direction: PageTurnDirection.backward,
              edge: edge,
              style: const PageTurnStyle(),
            );

            final recorder = ui.PictureRecorder();
            final canvas = Canvas(recorder);

            expect(
              () => painter.paint(canvas, const Size(200, 300)),
              returnsNormally,
            );
          });

          test('paints with custom style', () {
            final painter = PageTurnPainter(
              image: testImage,
              progress: 0.5,
              direction: PageTurnDirection.forward,
              edge: edge,
              style: const PageTurnStyle(
                shadowOpacity: 0.5,
                segments: 50,
                curlIntensity: 1.5,
              ),
            );

            final recorder = ui.PictureRecorder();
            final canvas = Canvas(recorder);

            expect(
              () => painter.paint(canvas, const Size(200, 300)),
              returnsNormally,
            );
          });

          test('handles zero size', () {
            final painter = PageTurnPainter(
              image: testImage,
              progress: 0.5,
              direction: PageTurnDirection.forward,
              edge: edge,
              style: const PageTurnStyle(),
            );

            final recorder = ui.PictureRecorder();
            final canvas = Canvas(recorder);

            expect(() => painter.paint(canvas, Size.zero), returnsNormally);
          });

          test('handles wide aspect ratio', () {
            final painter = PageTurnPainter(
              image: testImage,
              progress: 0.5,
              direction: PageTurnDirection.forward,
              edge: edge,
              style: const PageTurnStyle(),
            );

            final recorder = ui.PictureRecorder();
            final canvas = Canvas(recorder);

            expect(
              () => painter.paint(canvas, const Size(500, 100)),
              returnsNormally,
            );
          });

          test('handles tall aspect ratio', () {
            final painter = PageTurnPainter(
              image: testImage,
              progress: 0.5,
              direction: PageTurnDirection.forward,
              edge: edge,
              style: const PageTurnStyle(),
            );

            final recorder = ui.PictureRecorder();
            final canvas = Canvas(recorder);

            expect(
              () => painter.paint(canvas, const Size(100, 500)),
              returnsNormally,
            );
          });
        });
      }

      test('all eight combinations work', () {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        const size = Size(200, 300);

        for (final edge in PageTurnEdge.values) {
          for (final direction in PageTurnDirection.values) {
            final painter = PageTurnPainter(
              image: testImage,
              progress: 0.5,
              direction: direction,
              edge: edge,
              style: const PageTurnStyle(),
            );

            expect(
              () => painter.paint(canvas, size),
              returnsNormally,
              reason: 'Failed for edge: $edge, direction: $direction',
            );
          }
        }
      });
    });
  });

  group('StaticImagePainter', () {
    late ui.Image testImage;

    setUpAll(() async {
      testImage = await createTestImage();
    });

    tearDownAll(() {
      testImage.dispose();
    });

    test('creates instance with image', () {
      final painter = StaticImagePainter(image: testImage);
      expect(painter.image, equals(testImage));
    });

    group('shouldRepaint', () {
      test('returns false for same image', () {
        final painter1 = StaticImagePainter(image: testImage);
        final painter2 = StaticImagePainter(image: testImage);

        expect(painter1.shouldRepaint(painter2), isFalse);
      });

      test('returns true for different image', () async {
        final otherImage = await createTestImage(color: Colors.red);
        final painter1 = StaticImagePainter(image: testImage);
        final painter2 = StaticImagePainter(image: otherImage);

        expect(painter1.shouldRepaint(painter2), isTrue);

        otherImage.dispose();
      });
    });

    group('paint', () {
      test('handles zero size gracefully', () {
        final painter = StaticImagePainter(image: testImage);
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);

        expect(() => painter.paint(canvas, Size.zero), returnsNormally);
      });

      test('handles negative size gracefully', () {
        final painter = StaticImagePainter(image: testImage);
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);

        expect(
          () => painter.paint(canvas, const Size(-100, -100)),
          returnsNormally,
        );
      });

      test('paints successfully with valid size', () {
        final painter = StaticImagePainter(image: testImage);
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);

        expect(
          () => painter.paint(canvas, const Size(200, 300)),
          returnsNormally,
        );
      });

      test('paints with different aspect ratios', () {
        final painter = StaticImagePainter(image: testImage);
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);

        // Wide
        expect(
          () => painter.paint(canvas, const Size(500, 100)),
          returnsNormally,
        );

        // Tall
        expect(
          () => painter.paint(canvas, const Size(100, 500)),
          returnsNormally,
        );

        // Square
        expect(
          () => painter.paint(canvas, const Size(200, 200)),
          returnsNormally,
        );
      });
    });
  });
}

/// A canvas that notes everything drawn on it, in order.
class _CallCanvas implements Canvas {
  final calls = <Invocation>[];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls.add(invocation);
    return null;
  }
}

/// A canvas that notes what the painter draws: each strip, in the order it is
/// drawn, with where it is drawn and whether it shows the page's front (a
/// slice of the image) or its plain reverse (a filled rect); anything else it
/// draws, by name.
class _StripCanvas implements Canvas {
  final strips = <({Rect rect, bool front})>[];
  final other = <Symbol>[];

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final arguments = invocation.positionalArguments;
    switch (invocation.memberName) {
      case #drawImageRect:
        strips.add((rect: arguments[2] as Rect, front: true));
      case #drawRect:
        strips.add((rect: arguments[0] as Rect, front: false));
      default:
        other.add(invocation.memberName);
    }
    return null;
  }
}
