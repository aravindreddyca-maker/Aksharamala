/// "Connect the dots" guides for letters that have no stroke template (Telugu,
/// Hindi, Tamil and the small letters): the glyph's mask is thinned to its
/// centre line, and dots are placed along it. Pure Dart.
library;

import 'glyph_mask.dart';
import 'stroke_template.dart';

/// Dots spaced about [spacing] (unit square) apart along the centre line of
/// the glyph in [mask]. Empty when the mask has no ink.
List<Pt> dotsFromMask(GlyphMask mask, {double spacing = 0.05}) {
  final n = mask.size;
  // One cell of empty border so thinning never reads outside the grid.
  final w = n + 2;
  final g = List<bool>.filled(w * w, false);
  for (var y = 0; y < n; y++) {
    for (var x = 0; x < n; x++) {
      if (mask.at(x, y)) g[(y + 1) * w + (x + 1)] = true;
    }
  }
  _thin(g, w);

  final centre = <Pt>[];
  for (var y = 1; y <= n; y++) {
    for (var x = 1; x <= n; x++) {
      if (g[y * w + x]) centre.add(Pt((x - 0.5) / n, (y - 0.5) / n));
    }
  }
  if (centre.isEmpty) return const [];

  // Walk the thin line from its top-left end so dots come out evenly spaced:
  // take the nearest unused point each time, keeping one dot per [spacing].
  final dots = <Pt>[];
  final used = List<bool>.filled(centre.length, false);
  var at = 0;
  used[at] = true;
  dots.add(centre[at]);
  var left = centre.length - 1;
  while (left > 0) {
    var best = -1;
    var bestD = double.infinity;
    for (var i = 0; i < centre.length; i++) {
      if (used[i]) continue;
      final d = centre[i].distanceTo(centre[at]);
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    if (best < 0) break;
    used[best] = true;
    left--;
    at = best;
    if (dots.every((p) => p.distanceTo(centre[at]) >= spacing)) {
      dots.add(centre[at]);
    }
  }
  return dots;
}

/// Zhang-Suen thinning, in place: leaves a one-cell-wide line.
void _thin(List<bool> g, int w) {
  bool at(int x, int y) => g[y * w + x];
  var changed = true;
  while (changed) {
    changed = false;
    for (var pass = 0; pass < 2; pass++) {
      final remove = <int>[];
      for (var y = 1; y < w - 1; y++) {
        for (var x = 1; x < w - 1; x++) {
          if (!at(x, y)) continue;
          final p2 = at(x, y - 1), p3 = at(x + 1, y - 1), p4 = at(x + 1, y);
          final p5 = at(x + 1, y + 1), p6 = at(x, y + 1);
          final p7 = at(x - 1, y + 1), p8 = at(x - 1, y), p9 = at(x - 1, y - 1);
          final ring = [p2, p3, p4, p5, p6, p7, p8, p9];
          final b = ring.where((v) => v).length;
          if (b < 2 || b > 6) continue;
          var a = 0;
          for (var i = 0; i < 8; i++) {
            if (!ring[i] && ring[(i + 1) % 8]) a++;
          }
          if (a != 1) continue;
          if (pass == 0) {
            if (p2 && p4 && p6) continue;
            if (p4 && p6 && p8) continue;
          } else {
            if (p2 && p4 && p8) continue;
            if (p2 && p6 && p8) continue;
          }
          remove.add(y * w + x);
        }
      }
      if (remove.isNotEmpty) changed = true;
      for (final i in remove) {
        g[i] = false;
      }
    }
  }
}
