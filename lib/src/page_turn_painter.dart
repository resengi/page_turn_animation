import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'finger_modifier.dart';
import 'page_turn_constants.dart';
import 'page_turn_direction.dart';
import 'page_turn_edge.dart';
import 'page_turn_hinge.dart';
import 'page_turn_inputs.dart';
import 'page_turn_shadow.dart';
import 'page_turn_style.dart';

/// Custom painter that renders the page turn animation.
///
/// The page is drawn as strips across it ([stripEnds]):
/// 1. The hinge edge sets which way the page's length runs on screen, and a
///    backward turn is the forward turn run from its end back to its start.
/// 2. Each strip is seen in perspective from a camera over the page's centre:
///    a strip at height z is drawn D / (D − z) times its size, with D
///    [PageTurnConstants.cameraDistance].
/// 3. Strips are painted from the lowest to the highest, so paper behind other
///    paper is painted over by it. Paper behind the original page, where the
///    next page lies, is not painted: a strip that has turned more than half a
///    turn and that the original page hides from the camera at either end is
///    left out. Where the paper comes back on itself the strip shows the
///    page's back: its slice of [backImage], read the other way along the
///    page so the image is the right way round once the page has turned
///    180°, or without one the plain reverse ([PageTurnStyle.backgroundColor]).
///    Nothing is clipped.
/// 4. The shadows come from a lamp along the hinge,
///    [PageTurnStyle.lampDistanceFromPage] page lengths above it
///    ([PageTurnLamp]). The page's shadow falls on the stack's top over the
///    page's place, on the surface the page lands on beyond the hinge where it
///    is seen beside the stack, and on the page itself, as dark as the share
///    of the lamp the page hides; on the page it takes away only the light the
///    paper would have had. The paper is also shaded by how much less it faces
///    the lamp than flat paper. On the page both are worked out at each strip
///    end, where the paper faces between the directions of the two strips
///    meeting there, and blended across the strip, so they run smoothly over
///    curved paper. Both are drawn in [PageTurnStyle.shadowColor], together
///    never darker than [PageTurnStyle.shadowOpacity], and nothing is
///    blurred. At an opacity of 0 they are not worked out at all.
///
/// [PageTurnAnimation] paints with it and [PageTurnDragProgress] reads where
/// it draws the paper; it is not exported from the package's library.
class PageTurnPainter extends CustomPainter {
  /// Creates a page turn painter.
  ///
  /// The following parameters are required:
  /// - [image]: The captured UI image to animate
  /// - [progress]: Animation progress from 0.0 to 1.0
  /// - [direction]: Whether the page turns forward or backward
  /// - [edge]: Which edge the page curls over
  /// - [style]: Visual styling configuration
  ///
  /// [backImage] is optional: without it the page's back is the plain
  /// [PageTurnStyle.backgroundColor].
  ///
  /// [completionAngle] and [fingerStart] default to the standard turn's and
  /// must be in the ranges [PageTurnInputs] gives, or an [ArgumentError] is
  /// thrown ([PageTurnInputs.validate]).
  PageTurnPainter({
    required this.image,
    required this.progress,
    required this.direction,
    required this.edge,
    required this.style,
    this.backImage,
    this.completionAngle = PageTurnInputs.standardCompletionAngle,
    this.fingerStart = PageTurnInputs.standardFingerStart,
  }) {
    PageTurnInputs.validate(
      completionAngle: completionAngle,
      fingerStart: fingerStart,
    );
  }

  /// The image to render with the page turn effect.
  final ui.Image image;

  /// {@macro page_turn_animation.backImage}
  final ui.Image? backImage;

  /// The current animation progress from 0.0 (start) to 1.0 (complete).
  final double progress;

  /// The direction of the page turn animation.
  final PageTurnDirection direction;

  /// The edge where the page turn hinge is located.
  final PageTurnEdge edge;

  /// {@macro page_turn_animation.completionAngle}
  final double completionAngle;

  /// {@macro page_turn_animation.fingerStart}
  final double fingerStart;

  /// Visual styling configuration for the animation.
  final PageTurnStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 ||
        size.height <= 0 ||
        image.width <= 0 ||
        image.height <= 0) {
      return;
    }

    // Setup: the page's length runs away from the hinge, from the far side of
    // the canvas for the bottom and right edges; a backward turn is the
    // forward turn run from its end back to its start.
    final isVerticalAxis = edge.isVerticalAxis;
    final flipOrigin = edge.requiresCoordinateFlip;
    final pageLength = isVerticalAxis ? size.height : size.width;
    final pageWidth = isVerticalAxis ? size.width : size.height;
    // The images as they lie over the page. The front starts at the hinge
    // unless the page's length runs from the far side; the back runs the other
    // way, so it reads correctly once the page has turned 180°.
    final front = _laidOver(
      image,
      isVerticalAxis: isVerticalAxis,
      fromHinge: !flipOrigin,
    );
    final backImage = this.backImage;
    final back = backImage == null
        ? null
        : _laidOver(
            backImage,
            isVerticalAxis: isVerticalAxis,
            fromHinge: flipOrigin,
          );
    final clampedProgress = progress.clamp(0.0, 1.0);
    final t = direction == PageTurnDirection.forward
        ? clampedProgress
        : 1 - clampedProgress;

    final strips = _stripCount(style, pageLength);
    final (:y, :z, :directions) = stripEnds(
      t: t,
      curlIntensity: style.curlIntensity,
      completionAngle: completionAngle,
      fingerStart: fingerStart,
      strips: strips,
    );
    // Where the camera sees each strip end, once a frame: how much bigger than
    // its size, and how far along the page from the hinge, in page lengths.
    final seenScale = Float64List(strips + 1);
    final seenAlong = Float64List(strips + 1);
    for (var k = 0; k <= strips; k++) {
      seenScale[k] = _seenScale(z[k]);
      seenAlong[k] = _seenAlong(y[k], seenScale[k]);
    }

    // Paint order from height: the lowest strips first. Strips behind the
    // original page are left out.
    final order = [
      for (var i = 0; i < strips; i++)
        if (!(directions[i] > math.pi &&
            (_behindOriginalPage(seenAlong[i], z[i]) ||
                _behindOriginalPage(seenAlong[i + 1], z[i + 1]))))
          i,
    ]..sort((a, b) => (z[a] + z[a + 1]).compareTo(z[b] + z[b + 1]));

    // The shadows, from the lamp over the hinge: the lamp is as wide as makes
    // the shadow's soft edge PageTurnConstants.softEdgePerBlurRadius blur
    // radii wide for paper a page length from where it falls. The lamp, and
    // how much of it the page hides from the ends of the strips drawn, are
    // made when first used: with the shadows off, never.
    final opacity = style.shadowOpacity;
    final shadows = opacity > 0;
    late final lamp = PageTurnLamp(
      y: y,
      z: z,
      height: style.lampDistanceFromPage,
      width:
          PageTurnConstants.softEdgePerBlurRadius *
          style.shadowBlurRadius /
          pageLength *
          (style.lampDistanceFromPage - 1),
    );
    Offset at(double along, double across) => isVerticalAxis
        ? Offset(across, flipOrigin ? pageLength - along : along)
        : Offset(flipOrigin ? pageLength - along : along, across);
    // The shadow's colour at a darkness, which is never above the opacity;
    // the clamp holds it to an alpha's 0 to 1 against rounding.
    Color shadow(double darkness) =>
        style.shadowColor.withValues(alpha: darkness.clamp(0.0, 1.0));
    // How much of the lamp the page hides from the ends of the strips drawn.
    late final hiddenAt = Float64List(strips + 1);
    if (shadows) {
      _paintSurfaceShadow(
        canvas,
        lamp,
        seenAlong,
        order,
        pageLength,
        pageWidth,
        at,
        shadow,
      );
      final drawn = List.filled(strips, false);
      for (final i in order) {
        drawn[i] = true;
      }
      for (var i = 0; i <= strips; i++) {
        if ((i > 0 && drawn[i - 1]) || (i < strips && drawn[i])) {
          hiddenAt[i] = lamp.hidden(y[i], z[i], skipFrom: i - 2, skipTo: i + 1);
        }
      }
    }

    // Neighbouring strips share their ends exactly; without anti-aliasing they
    // meet without seams.
    final imagePaint = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.medium;
    final reversePaint = Paint()
      ..isAntiAlias = false
      ..color = style.backgroundColor;

    // How dark the page is at strip end k, seen on its front (side 1) or its
    // back (side −1): its shading, by how much less it faces the lamp than
    // flat paper, there facing between the directions of the two strips that
    // meet at it (or the one strip's, at the page's ends), and the page's
    // shadow on it, taking away only the light it would have had.
    double pageDarkness(int k, double side) {
      final psi = k == 0
          ? directions[0]
          : k == strips
          ? directions[strips - 1]
          : (directions[k - 1] + directions[k]) / 2;
      final lit = lamp.facing(
        y[k],
        z[k],
        -math.sin(psi) * side,
        math.cos(psi) * side,
      );
      return opacity *
          (PageTurnConstants.shadingStrength * (1 - lit) + hiddenAt[k] * lit);
    }

    for (final i in order) {
      // The strip's ends along the page from the hinge, and its width, seen
      // from the camera.
      final along0 = seenAlong[i] * pageLength;
      final along1 = seenAlong[i + 1] * pageLength;
      final width = pageWidth * (seenScale[i] + seenScale[i + 1]) / 2;
      final dst = _buildRect(
        primaryPos: flipOrigin
            ? pageLength - math.max(along0, along1)
            : math.min(along0, along1),
        secondaryPos: (pageWidth - width) / 2,
        primarySize: (along1 - along0).abs(),
        secondarySize: width,
        isVerticalAxis: isVerticalAxis,
      );

      // Where the paper comes back on itself its back shows, elsewhere its
      // front: the strip's slice of that side's image, or on a back without
      // one the plain reverse.
      final seenBack = along1 < along0;
      final laid = seenBack ? back : front;
      if (laid == null) {
        canvas.drawRect(dst, reversePaint);
      } else {
        final slice = laid.fromHinge ? i : strips - 1 - i;
        final src = _buildRect(
          primaryPos: slice * laid.length / strips,
          secondaryPos: 0,
          primarySize: laid.length / strips,
          secondarySize: laid.width,
          isVerticalAxis: isVerticalAxis,
        );
        canvas.drawImageRect(laid.image, src, dst, imagePaint);
      }

      // The page's shadow on the strip and its shading, from how dark the
      // page is at the strip's two ends, running from one to the other.
      if (shadows) {
        final side = seenBack ? -1.0 : 1.0;
        final dark0 = pageDarkness(i, side);
        final dark1 = pageDarkness(i + 1, side);
        if (dark0 > PageTurnConstants.leastShadowDarkness ||
            dark1 > PageTurnConstants.leastShadowDarkness) {
          canvas.drawRect(
            dst,
            Paint()
              ..isAntiAlias = false
              ..shader = ui.Gradient.linear(at(along0, 0), at(along1, 0), [
                shadow(dark0),
                shadow(dark1),
              ]),
          );
        }
      }
    }
  }

  /// Paints the page's shadow on the surfaces under the page, before the page
  /// ([paint] step 4): the stack's top, and beyond the hinge the surface the
  /// page lands on where it is seen beside the stack, each
  /// [PageTurnConstants.shadowReach] page lengths out from the hinge. The
  /// shadow is worked out at points [PageTurnConstants.shadowSampleSpacing]
  /// logical pixels apart, only where the camera sees the surface: not under
  /// the strips in [order], whose ends the camera sees [seenAlong] the page
  /// from the hinge, in page lengths. Each surface is filled as one shape with
  /// a gradient through the points.
  ///
  /// [at] places a point given along the page from the hinge and across it, in
  /// logical pixels; [shadow] is the shadow's colour at a darkness.
  void _paintSurfaceShadow(
    Canvas canvas,
    PageTurnLamp lamp,
    Float64List seenAlong,
    List<int> order,
    double pageLength,
    double pageWidth,
    Offset Function(double along, double across) at,
    Color Function(double darkness) shadow,
  ) {
    const reach = PageTurnConstants.shadowReach;
    final points = math.max(
      1,
      (reach * pageLength / PageTurnConstants.shadowSampleSpacing).ceil(),
    );
    final spacing = reach / points;

    // Where the page is seen over the surfaces, along it from the hinge in
    // page lengths: the stretches its strips cover, joined.
    final spans = [
      for (final i in order)
        (
          math.min(seenAlong[i], seenAlong[i + 1]),
          math.max(seenAlong[i], seenAlong[i + 1]),
        ),
    ]..sort((p, q) => p.$1.compareTo(q.$1));
    final covered = <(double, double)>[];
    for (final span in spans) {
      if (covered.isNotEmpty && span.$1 <= covered.last.$2) {
        covered.last = (covered.last.$1, math.max(covered.last.$2, span.$2));
      } else {
        covered.add(span);
      }
    }
    // Whether the camera sees the surface within a point's spacing of where
    // it is seen.
    bool inSight(double along) {
      for (var c = 0; c < covered.length; c++) {
        final (from, to) = covered[c];
        if (from <= along - spacing && along + spacing <= to) return false;
      }
      return true;
    }

    // A shape filled with a gradient through the points where there is
    // shadow and those either side of them, the points seen at [alongs].
    void fill(Path shape, Float64List alongs, Float64List darkness) {
      if (!darkness.any((d) => d > PageTurnConstants.leastShadowDarkness)) {
        return;
      }
      final last = alongs.length - 1;
      bool kept(int j) =>
          j == 0 ||
          j == last ||
          darkness[j - 1] > 0 ||
          darkness[j] > 0 ||
          darkness[j + 1] > 0;
      var count = 0;
      for (var j = 0; j <= last; j++) {
        if (kept(j)) count++;
      }
      final colors = <Color>[], stops = Float64List(count);
      var stop = 0;
      for (var j = 0; j <= last; j++) {
        if (kept(j)) {
          colors.add(shadow(darkness[j]));
          stops[stop++] = (alongs[j] - alongs[0]) / (alongs[last] - alongs[0]);
        }
      }
      canvas.drawPath(
        shape,
        Paint()
          ..shader = ui.Gradient.linear(
            at(alongs[0] * pageLength, 0),
            at(alongs[last] * pageLength, 0),
            colors,
            stops,
          ),
      );
    }

    // The stack's top, z = 0.
    final opacity = style.shadowOpacity;
    final stack = lamp.alongSurface(
      ey: 1,
      ez: 0,
      ny: 0,
      nz: 1,
      reach: reach,
      points: points,
      seen: (point) => inSight(point * spacing),
    );
    // The points' places along the page, and their darkness, worked out in
    // place over how much of the lamp is hidden from them.
    final stackAlongs = Float64List(points + 1);
    for (var j = 0; j <= points; j++) {
      stackAlongs[j] = j * spacing;
      stack[j] *= opacity;
    }
    fill(
      Path()..addPolygon([
        at(0, 0),
        at(reach * pageLength, 0),
        at(reach * pageLength, pageWidth),
        at(0, pageWidth),
      ], true),
      stackAlongs,
      stack,
    );

    // The surface the page lands on: a plane through the hinge at the
    // completion angle, seen beside the stack, where what is further out is
    // seen further from it, while D·cos θ < cameraAlong·sin θ (θ up to about
    // 263°; beyond that it is behind the stack).
    final angle = completionAngle * math.pi / 180;
    final cos = math.cos(angle), sin = math.sin(angle);
    if (!(PageTurnConstants.cameraDistance * cos <
        PageTurnConstants.cameraAlong * sin)) {
      return;
    }
    final alongs = Float64List(points + 1);
    for (var j = 0; j <= points; j++) {
      alongs[j] = _seenAlong(cos * j * spacing, _seenScale(sin * j * spacing));
    }
    final landing = lamp.alongSurface(
      ey: cos,
      ez: sin,
      ny: sin,
      nz: -cos,
      reach: reach,
      points: points,
      seen: (point) => inSight(alongs[point]),
    );
    // Their darkness, worked out in place as for the stack's top, and by how
    // much less the surface faces the lamp there than flat paper.
    for (var j = 0; j <= points; j++) {
      landing[j] *=
          opacity *
          lamp.facing(cos * j * spacing, sin * j * spacing, sin, -cos);
    }
    final farHalf = pageWidth / 2 * _seenScale(sin * reach);
    fill(
      Path()..addPolygon([
        at(0, 0),
        at(alongs[points] * pageLength, pageWidth / 2 - farHalf),
        at(alongs[points] * pageLength, pageWidth / 2 + farHalf),
        at(0, pageWidth),
      ], true),
      alongs,
      landing,
    );
  }

  /// Where the paper at [paperPosition] (0 at the hinge, 1 at the free edge)
  /// is seen at turn progress [t], in page lengths along the page from the
  /// hinge, as [paint] draws it on a page [pageLength] logical pixels long with
  /// [style], [completionAngle] and [fingerStart]: between the ends of its
  /// strip, as far along as it is along the strip, since the strip's slice of
  /// the image is stretched evenly over it.
  static double paperAlong({
    required double t,
    required double paperPosition,
    required double pageLength,
    required PageTurnStyle style,
    required double completionAngle,
    required double fingerStart,
  }) {
    final strips = _stripCount(style, pageLength);
    final (:y, :z, directions: _) = stripEnds(
      t: t,
      curlIntensity: style.curlIntensity,
      completionAngle: completionAngle,
      fingerStart: fingerStart,
      strips: strips,
    );
    final at = paperPosition * strips;
    final i = math.min(strips - 1, at.floor());
    final share = at - i;
    return _seenAlong(y[i], _seenScale(z[i])) * (1 - share) +
        _seenAlong(y[i + 1], _seenScale(z[i + 1])) * share;
  }

  /// How many strips a page [pageLength] logical pixels long is drawn in: one
  /// per segment of [style], but no more than one per logical pixel of its
  /// length, and at least one.
  static int _stripCount(PageTurnStyle style, double pageLength) =>
      math.max(1, math.min(style.segments, pageLength.floor()));

  /// How much bigger than its size the camera sees a point at height [z].
  static double _seenScale(double z) =>
      PageTurnConstants.cameraDistance / (PageTurnConstants.cameraDistance - z);

  /// Where the camera sees a point at [y] along the stack, drawn [scale]
  /// times its size, in page lengths along the page from the hinge: where the
  /// camera's line of sight to it crosses the level of the stack's top.
  static double _seenAlong(double y, double scale) =>
      PageTurnConstants.cameraAlong +
      (y - PageTurnConstants.cameraAlong) * scale;

  /// Whether the original page, the flat page from the hinge to the free edge
  /// where the page lay before the turn, hides the paper at height [z] that
  /// the camera sees [along] the page from the hinge, in page lengths: it is
  /// at or below the original page's level and the camera sees it within the
  /// original page, other than on the hinge line itself, which every turn
  /// passes through.
  ///
  /// Only paper that has turned more than half a turn is tested ([paint]):
  /// paper turned less cannot be behind the stack, as it lies on or above the
  /// desk. Its height is a sum of the strips' rises, so where it lies on the
  /// desk it can come out a little below the original page's level (with a
  /// finger start, 0.0004 page lengths at 100 strips), which this test would
  /// take for paper behind the page. Paper turned more than half a turn at the
  /// original page's level lies on the back of the stack: at the end of a 360°
  /// turn, the whole page.
  static bool _behindOriginalPage(double along, double z) =>
      z <= 0 && along > 0 && along <= 1;

  /// The ends of the page's [strips] strips at turn progress [t] (0: flat on
  /// the stack; 1: turned) with the style's [curlIntensity], the
  /// [completionAngle] in degrees and the [fingerStart], and each strip's
  /// direction.
  ///
  /// [y] runs along the stack away from the hinge and [z] up toward the
  /// viewer, both in page lengths: the flat page lies from y = 0 to y = 1. The
  /// strips are laid end to end, each along the page's direction ψ at its
  /// middle (its entry in [directions], in radians from the flat page), so the
  /// page keeps its length and neighbouring strips meet. At paper position s
  /// (0 at the hinge, 1 at the free edge) the direction is the turn's, changed
  /// by the [fingerModifier] (skipped at the standard finger start). The
  /// turn's direction, with its tuned numbers named as in [PageTurnConstants],
  /// is
  ///
  /// ```
  /// ψ(s) = θ·ρ + R·(1 − (1 − sᵃ)ᵇ) − C·s^countercurlPower
  /// ρ = 1 − (1 − t^hingePace)^(hingeSooner^w)
  ///                                 how far the hinge side has turned
  /// R = m(2π·k·t^rollPace, θ·(1 − ρ))
  ///                                 the roll, hinge side to free edge
  /// C = π·w·m(√i, countercurlCap)·ρ·(1 − t)
  ///                                 the countercurl, at the free edge
  /// k = c·√i / (1 + c·√i), c = rollTightening
  ///                                 how tight the roll gets
  /// a = bendAtStart^(1 − t), b = bendAtEnd^t
  ///                                 where along the page the roll bends
  /// w = (2π − θ) / π                how far the turn is short of a full turn
  /// m(p, q) = (p^−n + q^−n)^(−1/n), n = smoothMinSharpness
  ///                                 the smaller of p and q, without a corner
  /// ```
  ///
  /// with θ the completion angle in radians and i the curl intensity. The page
  /// curls up from its free edge, rolls over the hinge and lies down on the
  /// surface at the completion angle. The hinge side turns onto the surface,
  /// slowly at first: at 360° (w = 0) it lands at the end, and the smaller the
  /// angle (up to w = 1 at 180°), the sooner it lands. The roll forms early and
  /// as far as k lets it: k nears 0 (a straight page) as the curl intensity
  /// nears 0 and nears 1 as it grows, so a tighter curl carries the free edge
  /// closer past the hinge. m keeps the roll from turning paper past the
  /// surface, so the roll gives way as the hinge side lands. a and b move the
  /// bend along the page: gathered at the free edge at first (a = bendAtStart:
  /// the edge peels up), spread evenly mid-turn (an even roll over the top) and
  /// gathered toward the hinge at the end (b = bendAtEnd: at 360°, a rounded
  /// top with the rest hanging down the back). Short of a full turn, the
  /// countercurl bends the far part of the page back the other way, more the
  /// smaller the angle and the tighter the curl, up to a curl intensity of
  /// countercurlCap squared. It
  /// grows as the hinge side turns and is gone by the end, so the page goes
  /// down onto the surface from the hinge out and the free edge lands last.
  /// The page starts flat on the stack and ends flat on the surface: at 360°,
  /// on the back of the stack where the original page lay.
  ///
  /// With a finger start the turn runs on the modifier's clock τ in place of
  /// t, its roll and countercurl are taken at the modifier's curl share v, and
  /// the modifier's arch is added:
  ///
  /// ```
  /// ψ(s) = θ·ρ(τ) + v·(R·(1 − (1 − sᵃ)ᵇ) − C·s^countercurlPower) + arch(s)
  /// ```
  ///
  /// with ρ, R, C, a and b taken at τ. At the standard finger start, τ = t,
  /// v = 1 and there is no arch.
  @visibleForTesting
  static ({Float64List y, Float64List z, Float64List directions}) stripEnds({
    required double t,
    required double curlIntensity,
    required double completionAngle,
    required double fingerStart,
    required int strips,
  }) {
    const sharpness = PageTurnConstants.smoothMinSharpness;
    double smoothMin(num p, num q) => math
        .pow(math.pow(p, -sharpness) + math.pow(q, -sharpness), -1 / sharpness)
        .toDouble();

    final angle = completionAngle * math.pi / 180;
    final shortOfFullTurn = (2 * math.pi - angle) / math.pi;
    final finger = fingerStart == PageTurnInputs.standardFingerStart
        ? (clock: t, curlShare: 1.0, arch: _noArch)
        : fingerModifier(t: t, fingerStart: fingerStart, angle: angle);
    final clock = finger.clock;
    final rootCurl =
        PageTurnConstants.rollTightening * math.sqrt(curlIntensity);
    final tightness = rootCurl / (1 + rootCurl);
    final turned = hingeTurned(clock, shortOfFullTurn);
    final roll =
        finger.curlShare *
        smoothMin(
          2 * math.pi * tightness * math.pow(clock, PageTurnConstants.rollPace),
          angle * (1 - turned),
        );
    final countercurl =
        finger.curlShare *
        math.pi *
        shortOfFullTurn *
        smoothMin(math.sqrt(curlIntensity), PageTurnConstants.countercurlCap) *
        turned *
        (1 - clock);
    final a = math.pow(PageTurnConstants.bendAtStart, 1 - clock);
    final b = math.pow(PageTurnConstants.bendAtEnd, clock);
    double psi(double s) =>
        angle * turned +
        roll * (1 - math.pow(1 - math.pow(s, a), b)) -
        countercurl * math.pow(s, PageTurnConstants.countercurlPower) +
        finger.arch(s);

    final y = Float64List(strips + 1), z = Float64List(strips + 1);
    final directions = Float64List(strips);
    for (var i = 0; i < strips; i++) {
      final direction = directions[i] = psi((i + 0.5) / strips);
      y[i + 1] = y[i] + math.cos(direction) / strips;
      z[i + 1] = z[i] + math.sin(direction) / strips;
    }
    return (y: y, z: z, directions: directions);
  }

  /// No arch: the finger modifier's arch at the standard finger start.
  static double _noArch(double s) => 0;

  /// An image as it lies over the page, for its strips' slices: its length
  /// along the page and width across it, in pixels, and whether its start is
  /// at the hinge.
  static ({ui.Image image, double length, double width, bool fromHinge})
  _laidOver(
    ui.Image image, {
    required bool isVerticalAxis,
    required bool fromHinge,
  }) => (
    image: image,
    length: (isVerticalAxis ? image.height : image.width).toDouble(),
    width: (isVerticalAxis ? image.width : image.height).toDouble(),
    fromHinge: fromHinge,
  );

  /// Builds a rect with primary/secondary dimensions mapped to the appropriate axis.
  static Rect _buildRect({
    required double primaryPos,
    required double secondaryPos,
    required double primarySize,
    required double secondarySize,
    required bool isVerticalAxis,
  }) {
    return isVerticalAxis
        ? Rect.fromLTWH(secondaryPos, primaryPos, secondarySize, primarySize)
        : Rect.fromLTWH(primaryPos, secondaryPos, primarySize, secondarySize);
  }

  @override
  bool shouldRepaint(PageTurnPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.direction != direction ||
        oldDelegate.edge != edge ||
        oldDelegate.completionAngle != completionAngle ||
        oldDelegate.fingerStart != fingerStart ||
        oldDelegate.image != image ||
        oldDelegate.backImage != backImage ||
        oldDelegate.style != style;
  }
}
