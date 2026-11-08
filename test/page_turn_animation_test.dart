import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
  group('PageTurnAnimation', () {
    late ui.Image testImage;

    setUpAll(() async {
      testImage = await createTestImage();
    });

    tearDownAll(() {
      testImage.dispose();
    });

    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageTurnAnimation(
              image: testImage,
              animation: const AlwaysStoppedAnimation(0.0),
              direction: PageTurnDirection.forward,
            ),
          ),
        ),
      );

      expect(find.byType(PageTurnAnimation), findsOneWidget);
    });

    testWidgets('renders with forward direction', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageTurnAnimation(
              image: testImage,
              animation: const AlwaysStoppedAnimation(0.5),
              direction: PageTurnDirection.forward,
            ),
          ),
        ),
      );

      expect(find.byType(PageTurnAnimation), findsOneWidget);
      // Verify CustomPaint is a descendant of PageTurnAnimation
      expect(
        find.descendant(
          of: find.byType(PageTurnAnimation),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders with backward direction', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageTurnAnimation(
              image: testImage,
              animation: const AlwaysStoppedAnimation(0.5),
              direction: PageTurnDirection.backward,
            ),
          ),
        ),
      );

      expect(find.byType(PageTurnAnimation), findsOneWidget);
    });

    testWidgets('renders at animation progress 0.0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageTurnAnimation(
              image: testImage,
              animation: const AlwaysStoppedAnimation(0.0),
              direction: PageTurnDirection.forward,
            ),
          ),
        ),
      );

      expect(find.byType(PageTurnAnimation), findsOneWidget);
    });

    testWidgets('renders at animation progress 0.5', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageTurnAnimation(
              image: testImage,
              animation: const AlwaysStoppedAnimation(0.5),
              direction: PageTurnDirection.forward,
            ),
          ),
        ),
      );

      expect(find.byType(PageTurnAnimation), findsOneWidget);
    });

    testWidgets('renders at animation progress 1.0', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageTurnAnimation(
              image: testImage,
              animation: const AlwaysStoppedAnimation(1.0),
              direction: PageTurnDirection.forward,
            ),
          ),
        ),
      );

      expect(find.byType(PageTurnAnimation), findsOneWidget);
    });

    testWidgets('accepts custom style', (tester) async {
      const customStyle = PageTurnStyle(
        backgroundColor: Colors.red,
        shadowOpacity: 0.5,
        segments: 50,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageTurnAnimation(
              image: testImage,
              animation: const AlwaysStoppedAnimation(0.5),
              direction: PageTurnDirection.forward,
              style: customStyle,
            ),
          ),
        ),
      );

      expect(find.byType(PageTurnAnimation), findsOneWidget);
    });

    testWidgets('uses default style when not specified', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageTurnAnimation(
              image: testImage,
              animation: const AlwaysStoppedAnimation(0.5),
              direction: PageTurnDirection.forward,
            ),
          ),
        ),
      );

      final widget = tester.widget<PageTurnAnimation>(
        find.byType(PageTurnAnimation),
      );

      expect(widget.style, equals(const PageTurnStyle()));
    });

    testWidgets('uses default edge (top) when not specified', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageTurnAnimation(
              image: testImage,
              animation: const AlwaysStoppedAnimation(0.5),
              direction: PageTurnDirection.forward,
            ),
          ),
        ),
      );

      final widget = tester.widget<PageTurnAnimation>(
        find.byType(PageTurnAnimation),
      );

      expect(widget.edge, equals(PageTurnEdge.top));
    });

    testWidgets('animates with AnimationController', (tester) async {
      late AnimationController controller;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return TickerProviderScope(
                  child: Builder(
                    builder: (context) {
                      controller = AnimationController(
                        vsync: TickerProviderScope.of(context),
                        duration: const Duration(milliseconds: 300),
                      );
                      return PageTurnAnimation(
                        image: testImage,
                        animation: controller,
                        direction: PageTurnDirection.forward,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(PageTurnAnimation), findsOneWidget);

      // Start animation
      controller.forward();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.byType(PageTurnAnimation), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 200));
      controller.dispose();
    });

    testWidgets('rebuilds when animation value changes', (tester) async {
      final controller = AnimationController(
        vsync: const TestVSync(),
        duration: const Duration(milliseconds: 300),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageTurnAnimation(
              image: testImage,
              animation: controller,
              direction: PageTurnDirection.forward,
            ),
          ),
        ),
      );

      // Animation at 0
      expect(
        find.descendant(
          of: find.byType(PageTurnAnimation),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );

      // Move animation forward
      controller.value = 0.5;
      await tester.pump();

      expect(
        find.descendant(
          of: find.byType(PageTurnAnimation),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );

      controller.dispose();
    });

    testWidgets('passes completionAngle and fingerStart to its painter', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageTurnAnimation(
              image: testImage,
              animation: const AlwaysStoppedAnimation(0.5),
              direction: PageTurnDirection.forward,
              completionAngle: 225,
              fingerStart: 0.4,
            ),
          ),
        ),
      );

      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(PageTurnAnimation),
          matching: find.byType(CustomPaint),
        ),
      );
      final painter = customPaint.painter! as PageTurnPainter;
      expect(painter.completionAngle, 225);
      expect(painter.fingerStart, 0.4);
    });

    testWidgets('passes its back image to its painter, and has none unless '
        'given one', (tester) async {
      Future<PageTurnPainter> painterFor(ui.Image? backImage) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PageTurnAnimation(
                image: testImage,
                backImage: backImage,
                animation: const AlwaysStoppedAnimation(0.5),
                direction: PageTurnDirection.forward,
              ),
            ),
          ),
        );
        final customPaint = tester.widget<CustomPaint>(
          find.descendant(
            of: find.byType(PageTurnAnimation),
            matching: find.byType(CustomPaint),
          ),
        );
        return customPaint.painter! as PageTurnPainter;
      }

      expect((await painterFor(testImage)).backImage, same(testImage));
      expect((await painterFor(null)).backImage, isNull);
    });

    testWidgets('defaults to completion angle 360 and finger start 0', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageTurnAnimation(
              image: testImage,
              animation: const AlwaysStoppedAnimation(0.5),
              direction: PageTurnDirection.forward,
            ),
          ),
        ),
      );

      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(PageTurnAnimation),
          matching: find.byType(CustomPaint),
        ),
      );
      final painter = customPaint.painter! as PageTurnPainter;
      expect(painter.completionAngle, 360);
      expect(painter.fingerStart, 0);
    });

    testWidgets('accepts completion angles and finger starts over the whole '
        'of the ranges PageTurnInputs gives, the bounds included', (
      tester,
    ) async {
      for (final (completionAngle, fingerStart) in const [
        (PageTurnInputs.minCompletionAngle, PageTurnInputs.minFingerStart),
        (PageTurnInputs.minCompletionAngle, PageTurnInputs.maxFingerStart),
        (PageTurnInputs.maxCompletionAngle, PageTurnInputs.minFingerStart),
        (PageTurnInputs.maxCompletionAngle, PageTurnInputs.maxFingerStart),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PageTurnAnimation(
                image: testImage,
                animation: const AlwaysStoppedAnimation(0.5),
                direction: PageTurnDirection.forward,
                completionAngle: completionAngle,
                fingerStart: fingerStart,
              ),
            ),
          ),
        );
        expect(
          tester.takeException(),
          isNull,
          reason: '$completionAngle, $fingerStart',
        );
      }
    });

    testWidgets('reports an ArgumentError naming completionAngle or '
        'fingerStart when it is out of range or not finite', (tester) async {
      const cases = [
        (completionAngle: 179.0, fingerStart: 0.0, name: 'completionAngle'),
        (completionAngle: 360.0001, fingerStart: 0.0, name: 'completionAngle'),
        (
          completionAngle: double.nan,
          fingerStart: 0.0,
          name: 'completionAngle',
        ),
        (completionAngle: 360.0, fingerStart: -0.001, name: 'fingerStart'),
        (completionAngle: 360.0, fingerStart: 0.95, name: 'fingerStart'),
        (
          completionAngle: 360.0,
          fingerStart: double.infinity,
          name: 'fingerStart',
        ),
      ];
      for (final c in cases) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PageTurnAnimation(
                image: testImage,
                animation: const AlwaysStoppedAnimation(0.5),
                direction: PageTurnDirection.forward,
                completionAngle: c.completionAngle,
                fingerStart: c.fingerStart,
              ),
            ),
          ),
        );

        expect(
          tester.takeException(),
          isA<ArgumentError>().having((e) => e.name, 'name', c.name),
          reason: '$c',
        );
      }
    });

    group('edge parameter', () {
      testWidgets('accepts top edge', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PageTurnAnimation(
                image: testImage,
                animation: const AlwaysStoppedAnimation(0.5),
                direction: PageTurnDirection.forward,
                edge: PageTurnEdge.top,
              ),
            ),
          ),
        );

        final widget = tester.widget<PageTurnAnimation>(
          find.byType(PageTurnAnimation),
        );

        expect(widget.edge, equals(PageTurnEdge.top));
      });

      testWidgets('accepts bottom edge', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PageTurnAnimation(
                image: testImage,
                animation: const AlwaysStoppedAnimation(0.5),
                direction: PageTurnDirection.forward,
                edge: PageTurnEdge.bottom,
              ),
            ),
          ),
        );

        final widget = tester.widget<PageTurnAnimation>(
          find.byType(PageTurnAnimation),
        );

        expect(widget.edge, equals(PageTurnEdge.bottom));
      });

      testWidgets('accepts left edge', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PageTurnAnimation(
                image: testImage,
                animation: const AlwaysStoppedAnimation(0.5),
                direction: PageTurnDirection.forward,
                edge: PageTurnEdge.left,
              ),
            ),
          ),
        );

        final widget = tester.widget<PageTurnAnimation>(
          find.byType(PageTurnAnimation),
        );

        expect(widget.edge, equals(PageTurnEdge.left));
      });

      testWidgets('accepts right edge', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: PageTurnAnimation(
                image: testImage,
                animation: const AlwaysStoppedAnimation(0.5),
                direction: PageTurnDirection.forward,
                edge: PageTurnEdge.right,
              ),
            ),
          ),
        );

        final widget = tester.widget<PageTurnAnimation>(
          find.byType(PageTurnAnimation),
        );

        expect(widget.edge, equals(PageTurnEdge.right));
      });

      testWidgets('renders all edge and direction combinations', (
        tester,
      ) async {
        for (final edge in PageTurnEdge.values) {
          for (final direction in PageTurnDirection.values) {
            await tester.pumpWidget(
              MaterialApp(
                home: Scaffold(
                  body: PageTurnAnimation(
                    image: testImage,
                    animation: const AlwaysStoppedAnimation(0.5),
                    direction: direction,
                    edge: edge,
                  ),
                ),
              ),
            );

            expect(
              find.byType(PageTurnAnimation),
              findsOneWidget,
              reason: 'Failed for edge: $edge, direction: $direction',
            );
          }
        }
      });
    });
  });

  group('PageTurnDirection', () {
    test('has forward value', () {
      expect(PageTurnDirection.forward, isNotNull);
    });

    test('has backward value', () {
      expect(PageTurnDirection.backward, isNotNull);
    });

    test('forward and backward are different', () {
      expect(PageTurnDirection.forward, isNot(PageTurnDirection.backward));
    });
  });
}

// Helper class for tests that need a TickerProvider
class TestVSync extends TickerProvider {
  const TestVSync();

  @override
  Ticker createTicker(TickerCallback onTick) {
    return Ticker(onTick);
  }
}

// Helper widget to provide a TickerProvider
class TickerProviderScope extends StatefulWidget {
  const TickerProviderScope({required this.child, super.key});

  final Widget child;

  static TickerProvider of(BuildContext context) {
    final state = context.findAncestorStateOfType<_TickerProviderScopeState>();
    return state!;
  }

  @override
  State<TickerProviderScope> createState() => _TickerProviderScopeState();
}

class _TickerProviderScopeState extends State<TickerProviderScope>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
