import 'dart:math' as math;
import 'dart:typed_data';

import 'page_turn_constants.dart';

/// The lamp the page's shadow and shading come from, for one frame of the
/// turn: a light along the hinge, [height] page lengths above it and [width]
/// page lengths wide across it, over the page whose strips end at [y] and [z]
/// (the painter's `stripEnds`).
///
/// Everything is in the side view, looking along the hinge: y runs along the
/// stack away from the hinge and z up toward the viewer, in page lengths. The
/// page never reaches the lamp: it is at most a page length high, and the lamp
/// is higher, as PageTurnStyle.lampDistanceFromPage must be more than 1.
class PageTurnLamp {
  /// Creates the lamp for the page whose strips end at [y] and [z], at least
  /// PageTurnConstants.leastLampWidth wide: a [width] of 0 (no blur) gives a
  /// sharp shadow.
  PageTurnLamp({
    required this.y,
    required this.z,
    required this.height,
    required double width,
  }) : width = math.max(width, PageTurnConstants.leastLampWidth),
       _spans = Float64List(3 * (y.length - 1)),
       _cuts = Float64List(2 * (y.length - 1));

  /// The strips' ends along the stack, in page lengths from the hinge.
  final Float64List y;

  /// The strips' ends' heights, in page lengths.
  final Float64List z;

  /// The lamp's height over the hinge, in page lengths.
  final double height;

  /// The lamp's width across the hinge, in page lengths.
  final double width;

  // Working space for [hidden]: the parts of the lamp the strips hide (from,
  // to, weight), and their ends.
  final Float64List _spans, _cuts;

  /// How much of the lamp the page hides from the point ([qy], [qz]): 0 in
  /// full light, toward 1 deep in the page's shadow.
  ///
  /// Seen from the point, a strip covers part of the lamp: its ends projected
  /// from the point up to the lamp's height, keeping only its part above the
  /// point (by more than PageTurnConstants.shadowTouchTolerance), which is all
  /// that can be in the way. Each hidden part counts
  /// 1 / (1 + shadowFade·d), with d how far the strip is from the point, the
  /// nearest strip counting where several hide the same part, so shadows do
  /// not add up; the share is taken over the lamp's width.
  ///
  /// Strips [skipFrom] to [skipTo] are left out: for a point on the page, the
  /// two strips meeting at it, which cannot hide the lamp from it, and their
  /// neighbours. The strips meet at slight corners where curved paper does not,
  /// so where the paper bends sharply a neighbour can rise into the lamp's view
  /// and darken the point, a shadow the curved paper does not cast. Given
  /// [among], only its first [amongCount] strips are tested: those that can
  /// reach the point.
  double hidden(
    double qy,
    double qz, {
    int skipFrom = 0,
    int skipTo = -1,
    Int32List? among,
    int amongCount = 0,
  }) {
    final half = width / 2, rise = height - qz;
    final low = qz + PageTurnConstants.shadowTouchTolerance;
    final tested = among == null ? y.length - 1 : amongCount;
    var count = 0;
    for (var k = 0; k < tested; k++) {
      final j = among == null ? k : among[k];
      // A strip wholly below the point cannot be in the way.
      if ((j >= skipFrom && j <= skipTo) || math.max(z[j], z[j + 1]) <= low) {
        continue;
      }
      // The strip's part above the point, as shares of the way along it.
      final (from, to) = _partAbove(z[j] - low, z[j + 1] - low);
      if (!(to > from)) continue;
      final dy = y[j + 1] - y[j], dz = z[j + 1] - z[j];
      final y0 = y[j] + from * dy, z0 = z[j] + from * dz;
      final y1 = y[j] + to * dy, z1 = z[j] + to * dz;
      // Where the lines from the point through the part's ends reach the
      // lamp's height, across the hinge from under it.
      final x0 = qy + (y0 - qy) * rise / (z0 - qz);
      final x1 = qy + (y1 - qy) * rise / (z1 - qz);
      if (math.max(x0, x1) <= -half || math.min(x0, x1) >= half) continue;
      final awayY = (y0 + y1) / 2 - qy, awayZ = (z0 + z1) / 2 - qz;
      final away = math.sqrt(awayY * awayY + awayZ * awayZ);
      _spans[3 * count] = _cuts[2 * count] = math.max(math.min(x0, x1), -half);
      _spans[3 * count + 1] = _cuts[2 * count + 1] = math.min(
        math.max(x0, x1),
        half,
      );
      _spans[3 * count + 2] = 1 / (1 + PageTurnConstants.shadowFade * away);
      count++;
    }

    // Between each two ends of the hidden parts, in order, the nearest strip
    // hiding the lamp there counts.
    final cutCount = 2 * count;
    _sortFirst(_cuts, cutCount);
    var sum = 0.0;
    for (var c = 0; c + 1 < cutCount; c++) {
      final middle = (_cuts[c] + _cuts[c + 1]) / 2;
      var nearest = 0.0;
      for (var k = 0; k < count; k++) {
        if (_spans[3 * k] <= middle && middle <= _spans[3 * k + 1]) {
          nearest = math.max(nearest, _spans[3 * k + 2]);
        }
      }
      sum += nearest * (_cuts[c + 1] - _cuts[c]);
    }
    // Each part of the lamp counts once, at most 1, so the share is at most
    // 1; the cap holds it there against rounding.
    return math.min(1.0, sum / width);
  }

  /// How much of the lamp the page hides from points along a surface through
  /// the hinge, [points] + 1 of them from the hinge to [reach] page lengths
  /// out along the direction ([ey], [ez]): the stack's top runs along (1, 0),
  /// the surface the page lands on along the completion angle. ([ny], [nz]) is
  /// the surface's normal on the side the paper is on. Only the points [seen]
  /// lets through, those the camera sees, are worked out; the rest are 0.
  ///
  /// A strip can only hide the lamp from points within its reach along the
  /// surface: between where the lines from either side of the lamp through
  /// its ends meet the surface, for its part on the paper's side (off the
  /// surface by more than PageTurnConstants.shadowTouchTolerance). Where such a
  /// line does not meet the surface, its reach is taken as all of it: that can
  /// only add strips to test, never leave one out, so the result is the same.
  /// The points are taken in order, keeping the strips whose reach they are
  /// in, and each is tested against those only.
  Float64List alongSurface({
    required double ey,
    required double ez,
    required double ny,
    required double nz,
    required double reach,
    required int points,
    required bool Function(int point) seen,
  }) {
    final strips = y.length - 1, half = width / 2;
    final reachFrom = Float64List(strips), reachTo = Float64List(strips);
    final reaching = <int>[];
    for (var j = 0; j < strips; j++) {
      final (from, to) = _partAbove(
        ny * y[j] + nz * z[j] - PageTurnConstants.shadowTouchTolerance,
        ny * y[j + 1] + nz * z[j + 1] - PageTurnConstants.shadowTouchTolerance,
      );
      if (!(to > from)) continue;
      var near = double.infinity, far = double.negativeInfinity;
      for (var end = 0; end < 2; end++) {
        final share = end == 0 ? from : to;
        for (var side = 0; side < 2; side++) {
          final x = side == 0 ? -half : half;
          // The line from the lamp at x through the strip at this share,
          // P − L = (dy, dz), meets the surface s·(ey, ez) at
          // s = (L × (P − L)) / (e × (P − L)), beyond the strip if the
          // share of the way past the lamp, (L × e) / (e × (P − L)), is at
          // least 1.
          final dy = y[j] + share * (y[j + 1] - y[j]) - x;
          final dz = z[j] + share * (z[j + 1] - z[j]) - height;
          final across = ey * dz - ez * dy;
          final meets = (x * dz - height * dy) / across;
          final past = (x * ez - height * ey) / across;
          final reaches = past >= 1 && meets.isFinite;
          near = reaches ? math.min(near, meets) : double.negativeInfinity;
          far = reaches ? math.max(far, meets) : double.infinity;
        }
      }
      reachFrom[j] = near;
      reachTo[j] = far;
      reaching.add(j);
    }
    reaching.sort((p, q) => reachFrom[p].compareTo(reachFrom[q]));

    final out = Float64List(points + 1), active = Int32List(strips);
    var activeCount = 0, next = 0;
    for (var point = 0; point <= points; point++) {
      final s = point / points * reach;
      while (next < reaching.length && reachFrom[reaching[next]] <= s) {
        active[activeCount++] = reaching[next++];
      }
      var kept = 0;
      for (var k = 0; k < activeCount; k++) {
        if (reachTo[active[k]] >= s) active[kept++] = active[k];
      }
      activeCount = kept;
      if (activeCount > 0 && seen(point)) {
        out[point] = hidden(
          s * ey,
          s * ez,
          among: active,
          amongCount: activeCount,
        );
      }
    }
    return out;
  }

  /// How much light a surface at ([qy], [qz]) facing ([nx], [nz]) gets from
  /// the lamp's middle, as a share of what flat paper at the same place gets:
  /// from 0 (turned away) to 1.
  double facing(double qy, double qz, double nx, double nz) {
    final rise = height - qz;
    return ((nz * rise - nx * qy) / rise).clamp(0.0, 1.0);
  }

  /// Sorts the first [count] numbers of [list] in place, smallest first, by
  /// insertion: sorting a view of the list instead allocates on every frame.
  static void _sortFirst(Float64List list, int count) {
    for (var a = 1; a < count; a++) {
      final value = list[a];
      var b = a - 1;
      while (b >= 0 && list[b] > value) {
        list[b + 1] = list[b];
        b--;
      }
      list[b + 1] = value;
    }
  }

  /// The part of a strip above a level, as shares of the way along it, from
  /// its ends' heights over that level [over0] and [over1]: empty (to not
  /// above from) if neither is above it. Marked `vm:prefer-inline`, which
  /// encourages inlining to reduce the allocation of the pair it returns for
  /// each strip.
  @pragma('vm:prefer-inline')
  static (double, double) _partAbove(double over0, double over1) {
    final crossing = over0 / (over0 - over1);
    return (over0 > 0 ? 0.0 : crossing, over1 > 0 ? 1.0 : crossing);
  }
}
