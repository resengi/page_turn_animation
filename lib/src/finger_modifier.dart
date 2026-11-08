import 'dart:math' as math;

import 'page_turn_constants.dart';
import 'page_turn_hinge.dart';

/// The finger modifier: how a turn started with the finger at [fingerStart]
/// changes the turn at progress [t] (0 to 1) with the completion [angle] θ in
/// radians. The tuned numbers it uses are in [PageTurnConstants], named below
/// without the class name.
///
/// [fingerStart] f is the finger's place on the page as a share of its length
/// from the free edge, above 0, so the finger is at paper position s_f = 1 − f
/// (s runs from 0 at the hinge to 1 at the free edge). The turn's direction is
/// θ·ρ(t) + shape(s, t), its hinge side's turn and the roll and countercurl
/// beyond it (the painter's `stripEnds`). The finger start changes three
/// things about it:
///
/// ```
/// ψ(s) = θ·ρ(τ) + v·shape(s, τ) + arch(s)
/// ```
///
/// the turn runs on its own `clock` τ, only `curlShare` v of its shape
/// applies, and `arch` adds the finger's arch. It is skipped at the standard
/// finger start (0), where τ = t, v = 1 and there is no arch; toward f = 0 it
/// nears that.
///
/// First the finger pushes the page toward the hinge and an arch forms behind
/// it while the free edge stays on the desk: forming, on its own clock g from
/// 0 to 1. Then the page lifts off and turns: on the clock x from 0 to 1.
/// Both come from t. The page lifts off at
///
/// ```
/// t_L = liftOffScale·f² / (f² + liftOffKnee)·(1 − f)^liftOffNearHinge
/// ```
///
/// within the first fifth of the turn: latest for a finger start near 0.4 and
/// earlier toward the free edge and the hinge, where forming moves the page
/// less. x is how far t is past it, eased in over the handover,
/// t_L ± handover·t_L, and forming runs on what is left:
///
/// ```
/// x = past(t − t_L, handover·t_L) / (1 − t_L)    g = (t − x·(1 − t_L)) / t_L
/// ```
///
/// So the finger's push slows to a stop as the page's rotation picks up, and
/// nothing changes speed at once. past(u, e) is 0 up to u = −e and u from
/// u = e, rising with smootherstep's slope between.
///
/// While forming the page is given by its height above the desk along the
/// paper, z(s), with the free edge at height 0, and ψ = asin(z'). It has
/// three parts:
///
/// - From the hinge to the arch's top, archTopAt of the way to the finger,
///   z' ∝ (ε + wⁿ)(1 − w^K) (w the share of the way to the top), with the
///   arch's mean slope. With a the arch's tallness, its mean slope over
///   archTallSlope, n = archPowerLow − archPowerDrop·a,
///   ε = archBulgeLow + archBulgeGrowth·a² and
///   K = archRoundingLow + archRoundingGrowth·a: a bulge just behind the top
///   while the arch is low, an even climb from along the stack, rounding over
///   the top, once it is tall.
/// - From the top to the finger, a quick turn from level to S, the tail's
///   slope at the finger, over the first farSideTurn of the way
///   (z' = −S·q(2 − q)), then straight at S into the tail, so there is no
///   bend at the finger.
/// - From the finger to the free edge (v = (s − s_f)/f), z = h·(1 − v/c)₊^m:
///   the tail leaves the desk at v = c and lies flat beyond it. c moves out
///   from tailLiftedAtStart to the edge by g = tailReachAt (eased by
///   tailReachEase) with the tail touching down smoothly (m = 2), and then m
///   eases to 1, a straight tail, by g = tailStraightBy. So the tail starts
///   mostly on the desk, curving up to the finger, is drawn in and unfurls,
///   and is straight with only the edge on the desk just before lift-off.
///
/// The arch's top rises to archHeight·s_f·smootherstep(f/archFullFrom)·
/// g^archLateness, smaller as the finger nears the hinge and less near the
/// free edge, and the finger's height h is what lets the far side run
/// straight into the tail: top − h = (1 − farSideTurn/3)·S·(1 − archTopAt)·s_f
/// with S = h·m/(c·f). The top stays low and rises late, so while the tail
/// straightens and the finger rises the arch takes up paper fast enough that
/// the finger's place on the page only moves toward the hinge and the free
/// edge only slides in; and the tail is straight before the rotation lifts
/// the free edge off the desk.
///
/// After lift-off, with F the forming shape, h₀ = F(0) its direction at the
/// hinge and C = F − h₀ its shape from there, C⁺ = max(0, C) where it stands
/// above the hinge's direction, and q = hingeSooner:
///
/// ```
/// P = λ·(1 − (1 − x^swingEase)^(swingSpread·q^w)) + (1 − λ)·ρ(x)
/// θ·ρ(τ) = h₀ + (θ − h₀)·P
/// arch(s) = (1 − u)·(C − C⁺) + (1 − u_h)·C⁺
/// u = smootherstep(P / (archOpenBy·λ))
/// u_h = smootherstep(P / (hingeRiseSettledBy·λ))
/// v = smootherstep((P/λ − curlDelay·min(1, w/curlDelayFullFrom)²)
///                  / (curlRamp + curlRampPerShortfall·w))
/// λ = smootherstep(f / leadFrom)    w = (2π − θ) / π
/// ```
///
/// P is how far the whole page has rotated about the hinge, from 0 at
/// lift-off to 1. It starts at rest and, like the turn's own hinge side, runs
/// slow early and quick late toward 360°, where the end of the turn is behind
/// the stack, and evenly eased toward 180°. The arch opens (u), the rise by
/// the hinge settles more slowly (u_h), so no point turns back further than
/// the turn itself turns it, and the turn's own curl comes in (v), all as P
/// goes, so they move with the rotation instead of each at its own pace. Once
/// v is 1 the page is the turn at τ, and at the end the turn itself. Near the
/// free edge (λ toward 0) the rotation follows the turn's own pace and every
/// ramp is done at once, so the page is the turn.
///
/// x, g and ρ(τ) run from 0 to 1; they are clamped to that, so rounding
/// cannot carry them past their ends. A finger start under leastFingerStart
/// is taken as that.
({double clock, double curlShare, double Function(double s) arch})
fingerModifier({
  required double t,
  required double fingerStart,
  required double angle,
}) {
  final f = math.max(fingerStart, PageTurnConstants.leastFingerStart);
  final shortOfFullTurn = (2 * math.pi - angle) / math.pi;
  final liftOff =
      PageTurnConstants.liftOffScale *
      f *
      f /
      (f * f + PageTurnConstants.liftOffKnee) *
      math.pow(1 - f, PageTurnConstants.liftOffNearHinge);
  final turning = _past(t - liftOff, PageTurnConstants.handover * liftOff);
  final x = math.min(1.0, turning / (1 - liftOff));
  final forming = _forming(((t - turning) / liftOff).clamp(0.0, 1.0), f);
  final hinge = forming(0);

  final lead = _smootherstep(f / PageTurnConstants.leadFrom);
  final rotated =
      lead *
          (1 -
              math.pow(
                1 - math.pow(x, PageTurnConstants.swingEase),
                PageTurnConstants.swingSpread *
                    math.pow(PageTurnConstants.hingeSooner, shortOfFullTurn),
              )) +
      (1 - lead) * hingeTurned(x, shortOfFullTurn);
  final hingeTurn = hinge + (angle - hinge) * rotated;
  // The turn's progress at which its hinge side has turned that far.
  final clock = progressAtHingeTurned(
    math.min(1.0, hingeTurn / angle),
    shortOfFullTurn,
  );
  final opened = _smootherstep(rotated / (PageTurnConstants.archOpenBy * lead));
  final settled = _smootherstep(
    rotated / (PageTurnConstants.hingeRiseSettledBy * lead),
  );
  final curlStart =
      PageTurnConstants.curlDelay *
      math.pow(
        math.min(1.0, shortOfFullTurn / PageTurnConstants.curlDelayFullFrom),
        2,
      );
  final curlShare = _smootherstep(
    (rotated / lead - curlStart) /
        (PageTurnConstants.curlRamp +
            PageTurnConstants.curlRampPerShortfall * shortOfFullTurn),
  );

  double arch(double s) {
    final shape = forming(s) - hinge;
    final above = math.max(0.0, shape);
    return (1 - opened) * (shape - above) + (1 - settled) * above;
  }

  return (clock: clock, curlShare: curlShare, arch: arch);
}

/// The page's direction ψ(s) while forming, at the forming clock [g] for the
/// finger start [f].
double Function(double s) _forming(double g, double f) {
  final fingerAt = 1 - f;
  final rising = PageTurnConstants.archTopAt * fingerAt;
  final falling = (1 - PageTurnConstants.archTopAt) * fingerAt;
  final reach = g / PageTurnConstants.tailReachAt;
  final top =
      PageTurnConstants.archHeight *
      fingerAt *
      _smootherstep(f / PageTurnConstants.archFullFrom) *
      math.pow(g, PageTurnConstants.archLateness);
  // Where the tail leaves the desk (its share of the tail from the finger),
  // and how it touches down: smoothly (2) until it is straight (1).
  final touchDown =
      PageTurnConstants.tailLiftedAtStart +
      (1 - PageTurnConstants.tailLiftedAtStart) *
          (reach - _past(reach - 1, PageTurnConstants.tailReachEase));
  final bend =
      2 -
      _smootherstep(
        (g - PageTurnConstants.tailReachAt) /
            (PageTurnConstants.tailStraightBy - PageTurnConstants.tailReachAt),
      );
  final finger =
      top /
      (1 +
          bend *
              falling *
              (1 - PageTurnConstants.farSideTurn / 3) /
              (touchDown * f));
  final tailSlope = finger * bend / (touchDown * f);

  final mean = top / rising;
  final tall = mean / PageTurnConstants.archTallSlope;
  final n =
      PageTurnConstants.archPowerLow - PageTurnConstants.archPowerDrop * tall;
  final e =
      PageTurnConstants.archBulgeLow +
      PageTurnConstants.archBulgeGrowth * tall * tall;
  final k =
      PageTurnConstants.archRoundingLow +
      PageTurnConstants.archRoundingGrowth * tall;
  final spread = e * k / (k + 1) + 1 / (n + 1) - 1 / (n + k + 1);

  double rise(double s) {
    final w = s / rising;
    return mean * (e + math.pow(w, n)) * (1 - math.pow(w, k)) / spread;
  }

  double fall(double s) {
    final q = math.min(
      1.0,
      (s - rising) / (PageTurnConstants.farSideTurn * falling),
    );
    return -tailSlope * q * (2 - q);
  }

  double tail(double s) =>
      -tailSlope *
      math.pow(math.max(0.0, 1 - (s - fingerAt) / (touchDown * f)), bend - 1);

  return (s) => math.asin(
    s < rising
        ? rise(s)
        : s < fingerAt
        ? fall(s)
        : tail(s),
  );
}

/// smootherstep(x): 0 up to x = 0, 1 from x = 1, and 6x⁵ − 15x⁴ + 10x³
/// between, at rest at both ends.
double _smootherstep(double x) {
  final c = x.clamp(0.0, 1.0);
  return c * c * c * (c * (6 * c - 15) + 10);
}

/// How far [u] is past 0, eased over u ∈ [−[ease], [ease]]: 0 up to −ease,
/// u from ease, and between them rising with smootherstep's slope (its
/// integral), so it starts and ends without a change of speed.
double _past(double u, double ease) {
  final r = (u + ease) / (2 * ease);
  final c = r.clamp(0.0, 1.0);
  return 2 *
      ease *
      (c * c * c * c * (c * (c - 3) + 2.5) + math.max(0.0, r - 1));
}
