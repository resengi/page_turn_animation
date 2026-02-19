import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:page_turn_animation/page_turn_animation.dart';

void main() {
  group('PageTurnStyle', () {
    group('constructor', () {
      test('creates instance with default values', () {
        const style = PageTurnStyle();

        expect(style.backgroundColor, Colors.white);
        expect(style.shadowColor, Colors.black);
        expect(style.shadowOpacity, 0.9);
        expect(style.shadowBlurRadius, 20.0);
        expect(style.segments, 100);
        expect(style.curlIntensity, 1.0);
      });

      test('creates instance with custom values', () {
        const style = PageTurnStyle(
          backgroundColor: Colors.grey,
          shadowColor: Colors.blue,
          shadowOpacity: 0.5,
          shadowBlurRadius: 15.0,
          segments: 50,
          curlIntensity: 1.5,
        );

        expect(style.backgroundColor, Colors.grey);
        expect(style.shadowColor, Colors.blue);
        expect(style.shadowOpacity, 0.5);
        expect(style.shadowBlurRadius, 15.0);
        expect(style.segments, 50);
        expect(style.curlIntensity, 1.5);
      });

      test('throws assertion error for invalid shadowOpacity (negative)', () {
        expect(
          () => PageTurnStyle(shadowOpacity: -0.1),
          throwsA(isA<AssertionError>()),
        );
      });

      test(
        'throws assertion error for invalid shadowOpacity (greater than 1)',
        () {
          expect(
            () => PageTurnStyle(shadowOpacity: 1.1),
            throwsA(isA<AssertionError>()),
          );
        },
      );

      test('throws assertion error for negative shadowBlurRadius', () {
        expect(
          () => PageTurnStyle(shadowBlurRadius: -1.0),
          throwsA(isA<AssertionError>()),
        );
      });

      test('throws assertion error for zero segments', () {
        expect(
          () => PageTurnStyle(segments: 0),
          throwsA(isA<AssertionError>()),
        );
      });

      test('throws assertion error for negative segments', () {
        expect(
          () => PageTurnStyle(segments: -1),
          throwsA(isA<AssertionError>()),
        );
      });

      test('throws assertion error for zero curlIntensity', () {
        expect(
          () => PageTurnStyle(curlIntensity: 0.0),
          throwsA(isA<AssertionError>()),
        );
      });

      test('throws assertion error for negative curlIntensity', () {
        expect(
          () => PageTurnStyle(curlIntensity: -1.0),
          throwsA(isA<AssertionError>()),
        );
      });

      test('accepts boundary values', () {
        // Should not throw
        const style1 = PageTurnStyle(shadowOpacity: 0.0);
        expect(style1.shadowOpacity, 0.0);

        const style2 = PageTurnStyle(shadowOpacity: 1.0);
        expect(style2.shadowOpacity, 1.0);

        const style3 = PageTurnStyle(shadowBlurRadius: 0.0);
        expect(style3.shadowBlurRadius, 0.0);

        const style4 = PageTurnStyle(segments: 1);
        expect(style4.segments, 1);

        const style5 = PageTurnStyle(curlIntensity: 0.01);
        expect(style5.curlIntensity, 0.01);
      });
    });

    group('defaults', () {
      test('returns a valid default style', () {
        const defaults = PageTurnStyle.defaults;

        expect(defaults.backgroundColor, Colors.white);
        expect(defaults.shadowColor, Colors.black);
        expect(defaults.shadowOpacity, 0.9);
        expect(defaults.shadowBlurRadius, 20.0);
        expect(defaults.segments, 100);
        expect(defaults.curlIntensity, 1.0);
      });

      test('defaults equals default constructor', () {
        const defaults = PageTurnStyle.defaults;
        const constructed = PageTurnStyle();

        expect(defaults, equals(constructed));
      });
    });

    group('copyWith', () {
      test('returns identical copy when no parameters provided', () {
        const original = PageTurnStyle(
          backgroundColor: Colors.red,
          shadowColor: Colors.blue,
          shadowOpacity: 0.5,
          shadowBlurRadius: 10.0,
          segments: 50,
          curlIntensity: 2.0,
        );

        final copy = original.copyWith();

        expect(copy, equals(original));
      });

      test('copies with new backgroundColor', () {
        const original = PageTurnStyle();
        final copy = original.copyWith(backgroundColor: Colors.red);

        expect(copy.backgroundColor, Colors.red);
        expect(copy.shadowColor, original.shadowColor);
        expect(copy.shadowOpacity, original.shadowOpacity);
        expect(copy.shadowBlurRadius, original.shadowBlurRadius);
        expect(copy.segments, original.segments);
        expect(copy.curlIntensity, original.curlIntensity);
      });

      test('copies with new shadowColor', () {
        const original = PageTurnStyle();
        final copy = original.copyWith(shadowColor: Colors.blue);

        expect(copy.shadowColor, Colors.blue);
        expect(copy.backgroundColor, original.backgroundColor);
      });

      test('copies with new shadowOpacity', () {
        const original = PageTurnStyle();
        final copy = original.copyWith(shadowOpacity: 0.3);

        expect(copy.shadowOpacity, 0.3);
      });

      test('copies with new shadowBlurRadius', () {
        const original = PageTurnStyle();
        final copy = original.copyWith(shadowBlurRadius: 30.0);

        expect(copy.shadowBlurRadius, 30.0);
      });

      test('copies with new segments', () {
        const original = PageTurnStyle();
        final copy = original.copyWith(segments: 200);

        expect(copy.segments, 200);
      });

      test('copies with new curlIntensity', () {
        const original = PageTurnStyle();
        final copy = original.copyWith(curlIntensity: 0.5);

        expect(copy.curlIntensity, 0.5);
      });

      test('copies with multiple new values', () {
        const original = PageTurnStyle();
        final copy = original.copyWith(
          backgroundColor: Colors.green,
          shadowOpacity: 0.7,
          segments: 75,
        );

        expect(copy.backgroundColor, Colors.green);
        expect(copy.shadowOpacity, 0.7);
        expect(copy.segments, 75);
        expect(copy.shadowColor, original.shadowColor);
        expect(copy.shadowBlurRadius, original.shadowBlurRadius);
        expect(copy.curlIntensity, original.curlIntensity);
      });
    });

    group('equality', () {
      test('equal styles are equal', () {
        const style1 = PageTurnStyle(
          backgroundColor: Colors.red,
          shadowOpacity: 0.5,
        );
        const style2 = PageTurnStyle(
          backgroundColor: Colors.red,
          shadowOpacity: 0.5,
        );

        expect(style1, equals(style2));
        expect(style1.hashCode, equals(style2.hashCode));
      });

      test('different styles are not equal', () {
        const style1 = PageTurnStyle(backgroundColor: Colors.red);
        const style2 = PageTurnStyle(backgroundColor: Colors.blue);

        expect(style1, isNot(equals(style2)));
      });

      test('identical style is equal to itself', () {
        const style = PageTurnStyle();

        expect(style, equals(style));
      });
    });

    group('toString', () {
      test('returns readable string representation', () {
        const style = PageTurnStyle();
        final string = style.toString();

        expect(string, contains('PageTurnStyle'));
        expect(string, contains('backgroundColor'));
        expect(string, contains('shadowColor'));
        expect(string, contains('shadowOpacity'));
        expect(string, contains('shadowBlurRadius'));
        expect(string, contains('segments'));
        expect(string, contains('curlIntensity'));
      });
    });
  });
}
