import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/features/habits/domain/adhkar_progress.dart';
import 'package:life_tracker/features/habits/domain/dhikr.dart';

const List<Dhikr> _list = [
  Dhikr(id: 'a', title: 'A', times: 1, text: 'a'),
  Dhikr(id: 'b', title: 'B', times: 3, text: 'b'),
  Dhikr(id: 'c', title: 'C', times: 2, text: 'c'),
];

void main() {
  test('a fresh list has nothing counted and starts at the first du\'a', () {
    final AdhkarProgress p = AdhkarProgress.empty(_list);
    expect(p.countOf(0), 0);
    expect(p.finished, 0);
    expect(p.complete, isFalse);
    expect(p.firstOpen, 0);
  });

  test('a tap counts one, and a du\'a finishes at its count', () {
    AdhkarProgress p = AdhkarProgress.empty(_list).tapped(1);
    expect(p.countOf(1), 1);
    expect(p.isFinished(1), isFalse);
    p = p.tapped(1).tapped(1);
    expect(p.countOf(1), 3);
    expect(p.isFinished(1), isTrue);
    expect(p.finished, 1);
  });

  test('taps past the count are ignored', () {
    final AdhkarProgress p =
        AdhkarProgress.empty(_list).tapped(0).tapped(0).tapped(0);
    expect(p.countOf(0), 1);
  });

  test('taking a tap back never goes below 0, and reopens a finished du\'a',
      () {
    AdhkarProgress p = AdhkarProgress.empty(_list).untapped(2);
    expect(p.countOf(2), 0);
    p = p.tapped(2).tapped(2);
    expect(p.isFinished(2), isTrue);
    p = p.untapped(2);
    expect(p.countOf(2), 1);
    expect(p.finished, 0);
  });

  test('the next open du\'a skips finished ones and wraps around', () {
    final AdhkarProgress p = AdhkarProgress.empty(_list).tapped(0);
    expect(p.firstOpen, 1);
    expect(p.nextOpen(after: 1), 2);
    expect(p.nextOpen(after: 2), 1);
  });

  test('all done is complete and has no open du\'a', () {
    final AdhkarProgress p = AdhkarProgress.empty(_list).allDone();
    expect(p.finished, 3);
    expect(p.complete, isTrue);
    expect(p.firstOpen, isNull);
    expect(p.nextOpen(after: 0), isNull);
  });

  test('saved counts come back; unknown ids are dropped, counts kept in range',
      () {
    final AdhkarProgress p = AdhkarProgress.empty(_list).tapped(1).tapped(1);
    expect(p.toJson(), {'b': 2});
    final AdhkarProgress back =
        AdhkarProgress.fromJson(_list, {'b': 2, 'gone': 5, 'c': 9, 'a': -4});
    expect(back.countOf(0), 0);
    expect(back.countOf(1), 2);
    expect(back.countOf(2), 2);
  });

  test('the real lists: 21 du\'as in the morning, 19 at night', () {
    expect(AdhkarProgress.empty(AdhkarList.morning.items).allDone().finished,
        21);
    expect(AdhkarProgress.empty(AdhkarList.night.items).allDone().finished, 19);
  });
}
