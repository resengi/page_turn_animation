import 'package:flutter_test/flutter_test.dart';
import 'package:page_turn_animation/page_turn_animation.dart';

const _notFinite = [double.nan, double.infinity, double.negativeInfinity];

void main() {
  test('the standard turn is the greatest completion angle, 360, with the '
      'least finger start, 0', () {
    expect(PageTurnInputs.standardCompletionAngle, 360);
    expect(PageTurnInputs.minCompletionAngle, 180);
    expect(
      PageTurnInputs.maxCompletionAngle,
      PageTurnInputs.standardCompletionAngle,
    );
    expect(PageTurnInputs.standardFingerStart, 0);
    expect(PageTurnInputs.minFingerStart, PageTurnInputs.standardFingerStart);
    expect(PageTurnInputs.maxFingerStart, 0.9);
  });

  test('accepts completion angles from 180 to 360 inclusive and no others', () {
    for (final angle in const [180.0, 180.5, 225.0, 270.0, 359.9, 360.0]) {
      expect(
        PageTurnInputs.isValidCompletionAngle(angle),
        isTrue,
        reason: '$angle',
      );
    }
    for (final angle in const [179.99, 360.01, 0.0, -360.0, ..._notFinite]) {
      expect(
        PageTurnInputs.isValidCompletionAngle(angle),
        isFalse,
        reason: '$angle',
      );
    }
  });

  test('accepts finger starts from 0 to 0.9 inclusive and no others', () {
    for (final fingerStart in const [0.0, -0.0, 0.001, 0.4, 0.9]) {
      expect(
        PageTurnInputs.isValidFingerStart(fingerStart),
        isTrue,
        reason: '$fingerStart',
      );
    }
    for (final fingerStart in const [
      -1e-9,
      -0.1,
      0.90001,
      1.0,
      ..._notFinite,
    ]) {
      expect(
        PageTurnInputs.isValidFingerStart(fingerStart),
        isFalse,
        reason: '$fingerStart',
      );
    }
  });

  test('validate passes accepted inputs and throws an ArgumentError naming the '
      'completion angle, or else the finger start, where one is not '
      'accepted', () {
    for (final (completionAngle, fingerStart) in const [
      (PageTurnInputs.minCompletionAngle, PageTurnInputs.minFingerStart),
      (PageTurnInputs.maxCompletionAngle, PageTurnInputs.maxFingerStart),
    ]) {
      PageTurnInputs.validate(
        completionAngle: completionAngle,
        fingerStart: fingerStart,
      );
    }
    for (final (completionAngle, fingerStart, name) in const [
      (179.0, 0.0, 'completionAngle'),
      (double.nan, 0.0, 'completionAngle'),
      (179.0, 1.0, 'completionAngle'),
      (360.0, 0.95, 'fingerStart'),
      (180.0, double.infinity, 'fingerStart'),
    ]) {
      expect(
        () => PageTurnInputs.validate(
          completionAngle: completionAngle,
          fingerStart: fingerStart,
        ),
        throwsA(isA<ArgumentError>().having((e) => e.name, 'name', name)),
        reason: '$completionAngle, $fingerStart',
      );
    }
  });
}
