import 'package:flutter_test/flutter_test.dart';
import 'package:yoldashmoto/core/services.dart';

void main() {
  group('Broadcast matching (§12)', () {
    final all = [
      {'id': 'm1', 'online': true, 'blocked': false, 'distKm': 1.0, 'services': ['engine']},
      {'id': 'm2', 'online': false, 'blocked': false, 'distKm': 0.5, 'services': ['engine']},
      {'id': 'm3', 'online': true, 'blocked': false, 'distKm': 30.0, 'services': ['engine']},
      {'id': 'm4', 'online': true, 'blocked': false, 'distKm': 2.0, 'services': ['tire']},
    ];
    test('eligible: online + radius + problem match', () {
      final e = MatchingService.eligible(all, radiusKm: 10, problem: 'engine');
      expect(e.map((m) => m['id']), ['m1']);
    });
    test('widen once finds farther mechanic', () {
      final e = MatchingService.eligible(all, radiusKm: 35, problem: 'engine');
      expect(e.map((m) => m['id']), containsAll(['m1', 'm3']));
    });
    test('timeout constants', () {
      expect(MatchingService.searchTimeoutSec, 60);
      expect(MatchingService.widenKm, 10);
    });
  });
}
