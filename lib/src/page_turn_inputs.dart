/// The contract of the page turn's inputs: the completion angle and the
/// finger start, each with its standard value and the range it is accepted
/// in, and the check that rejects a value outside its range.
///
/// The standard page turn is the page turned from its free edge onto the back
/// of the stack: [standardCompletionAngle] with [standardFingerStart]. These
/// are the defaults of [PageTurnAnimation], whose painter checks both inputs
/// with [validate].
abstract final class PageTurnInputs {
  /// The completion angle of the standard turn, in degrees: the page lies
  /// down on the back of the stack. It is the greatest completion angle,
  /// [maxCompletionAngle].
  static const double standardCompletionAngle = 360.0;

  /// The least completion angle, in degrees: flat on the desk beside the
  /// stack.
  static const double minCompletionAngle = 180.0;

  /// The greatest completion angle, in degrees: the standard turn's,
  /// [standardCompletionAngle].
  static const double maxCompletionAngle = standardCompletionAngle;

  /// The finger start of the standard turn: the page is turned from its free
  /// edge. It is the least finger start, [minFingerStart].
  static const double standardFingerStart = 0.0;

  /// The least finger start: the standard turn's, [standardFingerStart].
  static const double minFingerStart = standardFingerStart;

  /// The greatest finger start: a tenth of the page's length short of the
  /// hinge.
  static const double maxFingerStart = 0.9;

  /// Whether [completionAngle] is accepted: from [minCompletionAngle] to
  /// [maxCompletionAngle] inclusive, and so finite.
  static bool isValidCompletionAngle(double completionAngle) =>
      completionAngle >= minCompletionAngle &&
      completionAngle <= maxCompletionAngle;

  /// Whether [fingerStart] is accepted: from [minFingerStart] to
  /// [maxFingerStart] inclusive, and so finite.
  static bool isValidFingerStart(double fingerStart) =>
      fingerStart >= minFingerStart && fingerStart <= maxFingerStart;

  /// Throws an [ArgumentError] naming `completionAngle` if [completionAngle]
  /// is not accepted ([isValidCompletionAngle]), or else one naming
  /// `fingerStart` if [fingerStart] is not ([isValidFingerStart]).
  static void validate({
    required double completionAngle,
    required double fingerStart,
  }) {
    if (!isValidCompletionAngle(completionAngle)) {
      throw ArgumentError.value(
        completionAngle,
        'completionAngle',
        'Must be finite and between $minCompletionAngle and '
            '$maxCompletionAngle degrees inclusive.',
      );
    }
    if (!isValidFingerStart(fingerStart)) {
      throw ArgumentError.value(
        fingerStart,
        'fingerStart',
        'Must be finite and between $minFingerStart and $maxFingerStart '
            'inclusive.',
      );
    }
  }
}
