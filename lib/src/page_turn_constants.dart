/// The tuned numbers in the page turn's math, each with what it controls.
///
/// The formulas they appear in are in `PageTurnPainter.stripEnds` (the turn
/// and its perspective) and `fingerModifier` (the finger start). Numbers that
/// are part of a formula's definition rather than tuned (π, the coefficients
/// of smootherstep and its integral, the tail touching down as a parabola and
/// ending straight) stay in the formulas.
///
/// The finger start's numbers work together so the page moves on screen
/// without bursts, the pressed spot only moves toward the hinge, the free
/// edge only slides in while it is on the desk and the tail is straight when
/// the free edge lifts. Changing one can break these, so they are tuned as a
/// set: each set is scored by how far the worst of these motion checks goes
/// past a target, over completion angles from 180° to 360°, curl intensities
/// from 0.25 to 4 and finger starts from 0.05 to 0.9. The checks, which the
/// finger motion tests run: in a timed turn, the fastest any point moves and
/// the sharpest change of its pace, each against the standard turn; in a
/// drag, the pressed spot moving back out and how far the page moves per
/// pixel; and the tail's bend when the free edge lifts.
abstract final class PageTurnConstants {
  // Perspective.

  /// The camera's height over the page, in page lengths: a point at height z
  /// is drawn D / (D − z) times its size.
  static const double cameraDistance = 4;

  /// Where along the page the camera is, as a share of its length from the
  /// hinge: over its centre.
  static const double cameraAlong = 0.5;

  // The standard turn: ψ(s) = θ·ρ + R·(1 − (1 − sᵃ)ᵇ) − C·s^[countercurlPower].

  /// How slowly the hinge side starts to turn: ρ = 1 − (1 − t^p)^(q^w) with
  /// p this and q [hingeSooner].
  static const double hingePace = 2.5;

  /// How much sooner the hinge side lands per half turn the completion angle
  /// is short of a full turn: ρ's outer exponent q^w is 1 at 360° (landing at
  /// the end) and this at 180° (landing sooner, at rest).
  static const double hingeSooner = 4;

  /// How early the roll forms: R = m(2π·k·t^p, θ·(1 − ρ)) with p this.
  static const double rollPace = 0.7;

  /// How quickly the roll tightens with the curl intensity i:
  /// k = c·√i / (1 + c·√i) with c this, from a straight page (k near 0) to a
  /// full turn of roll (k near 1).
  static const double rollTightening = 2;

  /// The curl intensity's square root past which the countercurl grows no
  /// more: C = π·w·m(√i, c)·ρ·(1 − t) with c this, so it levels off past a
  /// curl intensity of this squared.
  static const double countercurlCap = 3;

  /// How the countercurl gathers toward the free edge: it bends the page as
  /// s to this power.
  static const double countercurlPower = 4;

  /// Where the roll bends at the start of the turn: a = b₀^(1 − t) with b₀
  /// this, gathered at the free edge.
  static const double bendAtStart = 4;

  /// Where the roll bends at the end of the turn: b = b₁^t with b₁ this,
  /// gathered toward the hinge.
  static const double bendAtEnd = 6;

  /// How closely the smooth minimum follows the smaller of its two values:
  /// m(p, q) = (p^−n + q^−n)^(−1/n) with n this.
  static const double smoothMinSharpness = 8;

  // The finger start: limits.

  /// The least finger start the finger modifier works from: nearer the free
  /// edge the lift-off time and the lead are lost to rounding, and the page
  /// there is the standard turn to within 1e-10 page lengths.
  static const double leastFingerStart = 1e-6;

  /// The finger start from which the finger leads the turn: the lead
  /// λ = smootherstep(f / this) falls to 0 toward the free edge, where the
  /// rotation follows the turn's own pace and every ramp is done at once.
  static const double leadFrom = 0.15;

  // The finger start: when the page lifts off.

  /// The lift-off time's scale:
  /// t_L = this·f² / (f² + [liftOffKnee])·(1 − f)^[liftOffNearHinge].
  static const double liftOffScale = 0.296;

  /// The finger start (squared) around which the lift-off time grows from 0.
  static const double liftOffKnee = 0.03;

  /// How much sooner the page lifts off as the finger nears the hinge, where
  /// the push moves the page less.
  static const double liftOffNearHinge = 0.662;

  /// The handover, as a share of the lift-off time: the push slows to a stop
  /// and the rotation picks up over t_L ± this·t_L.
  static const double handover = 0.257;

  // The finger start: the push's shape, on the forming clock g (0 to 1).

  /// Where the arch's top is, as a share of the way from the hinge to the
  /// finger.
  static const double archTopAt = 0.74;

  /// The arch's top at full rise, as a share of the way from the hinge to the
  /// finger: this·s_f·smootherstep(f / [archFullFrom])·g^[archLateness].
  static const double archHeight = 0.5;

  /// The finger start from which the arch reaches its full height; nearer
  /// the free edge it is lower.
  static const double archFullFrom = 0.3;

  /// How late the arch rises: its top grows as g to this power, staying low
  /// and rising quickly at the end of the push.
  static const double archLateness = 5.498;

  /// The arch's mean slope at which it counts as tall (its tallness a is the
  /// mean slope over this), for the shape of its rise.
  static const double archTallSlope = 0.73;

  /// The rise's power while the arch is low: n = this − [archPowerDrop]·a, in
  /// the rise's slope (ε + wⁿ)(1 − w^K).
  static const double archPowerLow = 3;

  /// How much the rise's power falls as the arch grows tall.
  static const double archPowerDrop = 1.5;

  /// The rise's even part while the arch is low:
  /// ε = this + [archBulgeGrowth]·a².
  static const double archBulgeLow = 0.05;

  /// How much the rise's even part grows as the arch grows tall.
  static const double archBulgeGrowth = 0.25;

  /// How sharply the rise rounds over the top while the arch is low:
  /// K = this + [archRoundingGrowth]·a.
  static const double archRoundingLow = 2;

  /// How much more sharply the rise rounds over the top once the arch is
  /// tall.
  static const double archRoundingGrowth = 3;

  /// The share of the far side, from the arch's top to the finger, over which
  /// it turns from level to the tail's slope.
  static const double farSideTurn = 0.6;

  /// The share of the tail, from the finger, off the desk at the start of the
  /// push.
  static const double tailLiftedAtStart = 0.3;

  /// When the tail has been drawn out to the free edge, on the forming clock;
  /// it then straightens.
  static const double tailReachAt = 0.8;

  /// How gently the tail stops being drawn out at [tailReachAt].
  static const double tailReachEase = 0.1;

  /// When the tail is straight, on the forming clock: before the rotation
  /// lifts the free edge.
  static const double tailStraightBy = 0.868;

  // The finger start: the rotation about the hinge, on its share P (0 to 1).

  /// How gently the rotation starts: P's own pace is
  /// 1 − (1 − x^this)^([swingSpread]·[hingeSooner]^w).
  static const double swingEase = 2.262;

  /// How the rotation's pace spreads over the turn, with the completion
  /// angle's [hingeSooner]^w: quick late toward 360°, evenly eased toward
  /// 180°.
  static const double swingSpread = 0.966;

  /// The share of the rotation (times the lead) by which the arch has
  /// opened.
  static const double archOpenBy = 0.73;

  /// The share of the rotation (times the lead) by which the rise by the
  /// hinge has settled; later than the arch opens, so no point turns back.
  static const double hingeRiseSettledBy = 0.955;

  /// The share of the rotation (over the lead) before the turn's own curl
  /// starts to come in, at completion angles of 270° and below.
  static const double curlDelay = 0.119;

  /// How far short of a full turn, in half turns, the completion angle is
  /// from which the curl's delay is full (half a turn short: 270°); toward
  /// 360° the curl comes in with the rotation.
  static const double curlDelayFullFrom = 0.5;

  /// The share of the rotation (over the lead) over which the turn's own curl
  /// comes in at 360°.
  static const double curlRamp = 0.726;

  /// How much longer the curl takes to come in per half turn the completion
  /// angle is short of a full turn.
  static const double curlRampPerShortfall = 0.267;

  // The drag.

  /// The stretch at the start of a drag, in page lengths of the finger's
  /// travel, over which PageTurnDragProgress spreads the page's lift: the page
  /// rises toward the camera before the pressed spot moves across the screen,
  /// so the turn rises evenly over this stretch instead of on the first pixel,
  /// and keeps the pressed spot under the finger from there on.
  static const double dragLiftSpread = 0.03;

  // Shadows: from a lamp along the hinge, PageTurnStyle.lampDistanceFromPage
  // page lengths above it.

  /// How much darker paper turned edge-on to the lamp is drawn than flat
  /// paper, as a share of the style's shadow opacity: the light in the room
  /// keeps it from going as dark as the page's shadow.
  static const double shadingStrength = 0.6;

  /// How much lighter the page's shadow is per page length between the paper
  /// casting it and where it falls: a part of the lamp hidden by paper d page
  /// lengths away darkens by 1 / (1 + this·d) of the shadow's opacity.
  static const double shadowFade = 1.5;

  /// How wide the shadow's soft edge is for paper a page length from where it
  /// falls, in blur radii. It sets the lamp's width across the hinge.
  static const double softEdgePerBlurRadius = 2;

  /// The least darkness, as a share of full opacity, a shadow or shading is
  /// drawn at: lighter than half a step of 8-bit colour, which rounds to
  /// nothing, it is left out and not drawn.
  static const double leastShadowDarkness = 1 / 512;

  /// The least width of the lamp across the hinge, in page lengths: a blur
  /// radius of 0 gives a lamp this narrow, a point for any purpose, so the
  /// shadow's edge is sharp. The share of the lamp the page hides is measured
  /// over its width, which this keeps from being 0.
  static const double leastLampWidth = 1e-9;

  /// How far along each surface from the hinge the page's shadow falls, in
  /// page lengths: over the page's own place on the stack, and as far beyond
  /// the hinge on the surface the page lands on.
  static const double shadowReach = 1;

  /// The logical pixels between the points along a surface where the page's
  /// shadow is worked out; it is drawn as a gradient through them.
  static const double shadowSampleSpacing = 1;

  /// How far above a point, in page lengths, paper must be to hide any of the
  /// lamp from it; paper nearer than this lies on it. The page always passes
  /// through the hinge, where it meets the surfaces exactly: there the line
  /// from a point through the paper to the lamp has no direction, which this
  /// leaves out. It is far below a pixel.
  static const double shadowTouchTolerance = 1e-9;
}
