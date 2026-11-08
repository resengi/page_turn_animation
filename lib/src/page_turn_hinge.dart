import 'dart:math' as math;

import 'page_turn_constants.dart';

/// How far the turn's hinge side has turned onto the surface at turn progress
/// [t], as a share of the completion angle: ρ = 1 − (1 − t^p)^(q^w) with
/// p = [PageTurnConstants.hingePace], q = [PageTurnConstants.hingeSooner] and
/// w = [shortOfFullTurn], how far the completion angle is short of a full
/// turn in half turns.
double hingeTurned(double t, double shortOfFullTurn) =>
    (1 -
            math.pow(
              1 - math.pow(t, PageTurnConstants.hingePace),
              math.pow(PageTurnConstants.hingeSooner, shortOfFullTurn),
            ))
        .toDouble();

/// The turn progress at which the hinge side has turned [share] (0 to 1) of
/// the way ([hingeTurned]): τ = (1 − (1 − ρ)^(q^−w))^(1/p).
double progressAtHingeTurned(double share, double shortOfFullTurn) => math
    .pow(
      1 -
          math.pow(
            1 - share,
            math.pow(PageTurnConstants.hingeSooner, -shortOfFullTurn),
          ),
      1 / PageTurnConstants.hingePace,
    )
    .toDouble();
