import 'package:aksharamala/src/curriculum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double _ratio(Color a, Color b) {
  final x = a.computeLuminance();
  final y = b.computeLuminance();
  final hi = x > y ? x : y;
  final lo = x > y ? y : x;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  test('white card text meets 4.5:1 on both gradient stops of every world', () {
    final weak = <String>[];
    for (final world in curriculum) {
      for (final entry in {'cardStart': world.cardStart, 'cardEnd': world.cardEnd}.entries) {
        final ratio = _ratio(Colors.white, entry.value);
        if (ratio < 4.5) weak.add('${world.id} ${entry.key} ${ratio.toStringAsFixed(2)}:1');
      }
    }
    expect(weak, isEmpty, reason: weak.join('\n'));
  });
}
