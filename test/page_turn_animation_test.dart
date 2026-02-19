import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:page_turn_animation/page_turn_animation.dart';

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
