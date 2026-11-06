import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The quest list shows a page of cards at a time. Turns pages until the card
/// with [key] is on screen; fails if it never appears.
Future<void> showQuest(WidgetTester tester, Key key) async {
  final card = find.byKey(key);
  final next = find.byKey(const Key('trail_next'));
  final prev = find.byKey(const Key('trail_prev'));
  // Back to the first page, then forward.
  for (var i = 0; i < 80 && prev.evaluate().isNotEmpty; i++) {
    await tester.tap(prev);
    await tester.pumpAndSettle();
  }
  for (var i = 0; i < 80; i++) {
    if (card.evaluate().isNotEmpty) return;
    if (next.evaluate().isEmpty) break;
    await tester.tap(next);
    await tester.pumpAndSettle();
  }
  expect(card, findsOneWidget, reason: 'quest card $key never came on screen');
}
