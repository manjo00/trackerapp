import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/features/habits/domain/adhkar_lists.dart';
import 'package:life_tracker/features/habits/domain/adhkar_progress.dart';
import 'package:life_tracker/features/habits/domain/dhikr.dart';

/// FNV-1a (32-bit) over every du'a of both lists. A tripwire: the text can't
/// change without someone meaning to. tool/adhkar/build_adhkar_lists.py
/// prints the same number for the lists it writes.
String _fingerprint() {
  final StringBuffer all = StringBuffer();
  for (final (String name, List<Dhikr> list) in [
    ('morning', kMorningAdhkar),
    ('night', kNightAdhkar),
  ]) {
    for (final Dhikr d in list) {
      all.write('$name|${d.id}|${d.title}|${d.times}|${d.text}\n');
    }
  }
  int h = 0x811c9dc5;
  for (final int byte in utf8.encode(all.toString())) {
    h = ((h ^ byte) * 0x01000193) & 0xFFFFFFFF;
  }
  return h.toRadixString(16).padLeft(8, '0');
}

int _taps(List<Dhikr> list) => list.fold(0, (int sum, Dhikr d) => sum + d.times);

void main() {
  test("morning is the post's 21 du'as, 337 taps in all", () {
    expect(kMorningAdhkar, hasLength(21));
    expect(_taps(kMorningAdhkar), 337);
  });

  test("night is the post's evening list, 19 du'as, 236 taps in all", () {
    expect(kNightAdhkar, hasLength(19));
    expect(_taps(kNightAdhkar), 236);
  });

  test('ids are unique in each list, and every du\'a is said at least once',
      () {
    for (final List<Dhikr> list in [kMorningAdhkar, kNightAdhkar]) {
      expect(list.map((Dhikr d) => d.id).toSet(), hasLength(list.length));
      expect(list.every((Dhikr d) => d.times >= 1 && d.text.isNotEmpty),
          isTrue);
    }
  });

  test('the morning-only and evening-only du\'as are where the post puts them',
      () {
    final List<String> m = kMorningAdhkar.map((Dhikr d) => d.id).toList();
    final List<String> n = kNightAdhkar.map((Dhikr d) => d.id).toList();
    expect(m.first, 'kursi');
    expect(n.first, 'kursi');
    expect(m, containsAll(<String>['adada', 'ilman', 'istighfar']));
    expect(n, isNot(contains('istighfar')));
    expect(n, contains('kalimat'));
    expect(m, isNot(contains('kalimat')));
    expect(m.last, 'tahlil100');
    expect(n.last, 'tahlil100');
  });

  test('the du\'a text is exactly what Ahmed checked', () {
    // The same text as the looks page Ahmed checked against his post
    // (https://claude.ai/artifact/4vn3JS5yYEQv9ed3SjrHM4, 2026-11-13).
    expect(_fingerprint(), 'ff410dd2');
  });

  test('a du\'a habit finds its list by its autoSource', () {
    expect(AdhkarList.fromSource('adhkar:morning'), AdhkarList.morning);
    expect(AdhkarList.fromSource('adhkar:night')!.items, same(kNightAdhkar));
    expect(AdhkarList.morning.items, same(kMorningAdhkar));
    expect(AdhkarList.fromSource('workout'), isNull);
    expect(AdhkarList.fromSource(null), isNull);
  });
}
