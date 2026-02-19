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
