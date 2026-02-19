import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:page_turn_animation/page_turn_animation.dart';

void main() {
  group('PageTurnEdge', () {
    group('enum values', () {
      test('has top value', () {
        expect(PageTurnEdge.top, isNotNull);
      });

      test('has bottom value', () {
        expect(PageTurnEdge.bottom, isNotNull);
      });

      test('has left value', () {
        expect(PageTurnEdge.left, isNotNull);
      });

      test('has right value', () {
        expect(PageTurnEdge.right, isNotNull);
      });

      test('all values are distinct', () {
        const values = PageTurnEdge.values;
        expect(values.length, 4);
        expect(values.toSet().length, 4);
      });
    });

    group('isVerticalAxis', () {
      test('top returns true', () {
        expect(PageTurnEdge.top.isVerticalAxis, isTrue);
      });

      test('bottom returns true', () {
        expect(PageTurnEdge.bottom.isVerticalAxis, isTrue);
      });

      test('left returns false', () {
        expect(PageTurnEdge.left.isVerticalAxis, isFalse);
      });

      test('right returns false', () {
        expect(PageTurnEdge.right.isVerticalAxis, isFalse);
      });
    });

    group('requiresCoordinateFlip', () {
      test('top returns false', () {
        expect(PageTurnEdge.top.requiresCoordinateFlip, isFalse);
      });

      test('bottom returns true', () {
        expect(PageTurnEdge.bottom.requiresCoordinateFlip, isTrue);
      });

      test('left returns false', () {
        expect(PageTurnEdge.left.requiresCoordinateFlip, isFalse);
      });

      test('right returns true', () {
        expect(PageTurnEdge.right.requiresCoordinateFlip, isTrue);
      });
    });

    group('shadowGradientBegin', () {
      test('top returns topCenter', () {
        expect(PageTurnEdge.top.shadowGradientBegin, Alignment.topCenter);
      });

      test('bottom returns bottomCenter', () {
        expect(PageTurnEdge.bottom.shadowGradientBegin, Alignment.bottomCenter);
      });

      test('left returns centerLeft', () {
        expect(PageTurnEdge.left.shadowGradientBegin, Alignment.centerLeft);
      });

      test('right returns centerRight', () {
        expect(PageTurnEdge.right.shadowGradientBegin, Alignment.centerRight);
      });
    });

    group('shadowGradientEnd', () {
      test('top returns bottomCenter', () {
        expect(PageTurnEdge.top.shadowGradientEnd, Alignment.bottomCenter);
      });

      test('bottom returns topCenter', () {
        expect(PageTurnEdge.bottom.shadowGradientEnd, Alignment.topCenter);
      });

      test('left returns centerRight', () {
        expect(PageTurnEdge.left.shadowGradientEnd, Alignment.centerRight);
      });

      test('right returns centerLeft', () {
        expect(PageTurnEdge.right.shadowGradientEnd, Alignment.centerLeft);
      });
    });

    group('shadow gradient consistency', () {
      test('begin and end are opposites for all edges', () {
        for (final edge in PageTurnEdge.values) {
          final begin = edge.shadowGradientBegin;
          final end = edge.shadowGradientEnd;

          // Verify they are on opposite sides
          expect(
            begin.x + end.x,
            0.0,
            reason: '$edge: x coordinates should be opposite',
          );
          expect(
            begin.y + end.y,
            0.0,
            reason: '$edge: y coordinates should be opposite',
          );
        }
      });

      test('vertical axis edges have vertical gradients', () {
        expect(PageTurnEdge.top.shadowGradientBegin.x, 0.0);
        expect(PageTurnEdge.top.shadowGradientEnd.x, 0.0);
        expect(PageTurnEdge.bottom.shadowGradientBegin.x, 0.0);
        expect(PageTurnEdge.bottom.shadowGradientEnd.x, 0.0);
      });

      test('horizontal axis edges have horizontal gradients', () {
        expect(PageTurnEdge.left.shadowGradientBegin.y, 0.0);
        expect(PageTurnEdge.left.shadowGradientEnd.y, 0.0);
        expect(PageTurnEdge.right.shadowGradientBegin.y, 0.0);
        expect(PageTurnEdge.right.shadowGradientEnd.y, 0.0);
      });
    });
  });
}
