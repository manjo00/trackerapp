import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/features/workout/domain/smart_order.dart';

/// The smart order: where each exercise goes in today's workout, worked out
/// from the order the last few workouts of the same plan were really done in.
/// Every expected order here was worked out by hand from the rules in
/// docs/superpowers/specs/2026-11-01-gym-smart-order-design.md.
void main() {
  // No muscle tags: no families and no helper rule, so these tests see the
  // waiting list on its own.
  const Map<String, String> untagged = {};

  List<String> order(
    List<String> planned, {
    Map<String, String> muscles = untagged,
    List<List<String>> recent = const [],
  }) =>
      smartOrder(planned: planned, muscles: muscles, recent: recent).order;

  group('the waiting list', () {
    test('the first workout keeps the plan order', () {
      expect(order(['A', 'B', 'C', 'D']), ['A', 'B', 'C', 'D']);
    });

    test('exercises that missed the early slots go first, the latest first',
        () {
      // Six exercises, so the early slots are the first two. Last time A and
      // B had them; C to F waited one workout, and F was done last.
      expect(
        order(['A', 'B', 'C', 'D', 'E', 'F'], recent: [
          ['A', 'B', 'C', 'D', 'E', 'F'],
        ]),
        ['F', 'E', 'D', 'C', 'B', 'A'],
      );
    });

    test('a skipped exercise counts as later than last', () {
      // C was skipped last time; of the five done, A and B were early.
      expect(
        order(['A', 'B', 'C', 'D', 'E', 'F'], recent: [
          ['A', 'B', 'D', 'E', 'F'],
        ]),
        ['C', 'F', 'E', 'D', 'B', 'A'],
      );
    });

    test('a longer wait beats being late last time', () {
      // E and F missed the early slots in both workouts, A and B only in the
      // newest one, even though A and B came later in it.
      expect(
        order(['A', 'B', 'C', 'D', 'E', 'F'], recent: [
          ['C', 'D', 'E', 'F', 'A', 'B'],
          ['A', 'B', 'C', 'D', 'E', 'F'],
        ]),
        ['F', 'E', 'B', 'A', 'D', 'C'],
      );
    });

    test('only the last three workouts count', () {
      // X and Y missed the early slots in all three recent workouts. Counting
      // the fourth would give Y the longer wait; within three it's a tie, and
      // X was later last time.
      expect(
        order(['P', 'Q', 'R', 'X', 'Y', 'Z'], recent: [
          ['P', 'Q', 'R', 'Z', 'Y', 'X'],
          ['R', 'Z', 'P', 'Q', 'Y', 'X'],
          ['P', 'R', 'Q', 'Z', 'X', 'Y'],
          ['X', 'P', 'Q', 'R', 'Z', 'Y'],
        ]),
        ['X', 'Y', 'Z', 'R', 'Q', 'P'],
      );
    });

    test('every exercise gets an early slot in any three workouts in a row',
        () {
      const List<String> planned = [
        'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', //
      ];
      final List<List<String>> done = []; // newest first
      final List<Set<String>> early = [];
      for (int i = 0; i < 9; i++) {
        final List<String> today = order(planned, recent: done.take(3).toList());
        early.add(today.take(3).toSet());
        done.insert(0, today);
      }
      for (int w = 0; w + 2 < early.length; w++) {
        expect({...early[w], ...early[w + 1], ...early[w + 2]},
            containsAll(planned),
            reason: 'workouts ${w + 1} to ${w + 3}');
      }
    });
  });

  group('the rules', () {
    test('triceps come after every chest and shoulder exercise', () {
      expect(
        order(['Pushdown', 'Bench', 'Shoulder press'], muscles: {
          'Pushdown': 'Triceps',
          'Bench': 'Chest',
          'Shoulder press': 'Shoulders',
        }),
        ['Bench', 'Shoulder press', 'Pushdown'],
      );
    });

    test('biceps and forearms come after every back exercise', () {
      expect(
        order(['Curl', 'Wrist curl', 'Row'], muscles: {
          'Curl': 'Biceps',
          'Wrist curl': 'Forearms',
          'Row': 'Back',
        }),
        ['Row', 'Curl', 'Wrist curl'],
      );
    });

    test('core comes after the leg and back exercises', () {
      expect(
        order(['Crunch', 'Leg press', 'Row'], muscles: {
          'Crunch': 'Core',
          'Leg press': 'Legs',
          'Row': 'Back',
        }),
        ['Leg press', 'Row', 'Crunch'],
      );
    });

    test('two exercises of the same family are kept apart', () {
      expect(
        order(['Bench', 'Fly', 'Pulldown', 'Row'], muscles: {
          'Bench': 'Chest',
          'Fly': 'Chest',
          'Pulldown': 'Back',
          'Row': 'Back',
        }),
        ['Bench', 'Pulldown', 'Fly', 'Row'],
      );
    });

    test('when apart is impossible: fewest neighbours, then closest to the list',
        () {
      // Three chest exercises and one row can't all be kept apart.
      expect(
        order(['Bench', 'Fly', 'Incline', 'Row'], muscles: {
          'Bench': 'Chest',
          'Fly': 'Chest',
          'Incline': 'Chest',
          'Row': 'Back',
        }),
        ['Bench', 'Fly', 'Row', 'Incline'],
      );
    });

    test('a list longer than 16 still keeps the helper rule', () {
      final List<String> planned = [
        for (int i = 0; i < 9; i++) 'Pushdown $i',
        for (int i = 0; i < 9; i++) 'Press $i',
      ];
      final Map<String, String> muscles = {
        for (int i = 0; i < 9; i++) 'Pushdown $i': 'Triceps',
        for (int i = 0; i < 9; i++) 'Press $i': 'Chest',
      };
      final List<String> today = order(planned, muscles: muscles);
      expect(today.toSet(), planned.toSet());
      expect(today, hasLength(18));
      final int lastPress = today.lastIndexWhere((n) => n.startsWith('Press'));
      final int firstPushdown =
          today.indexWhere((n) => n.startsWith('Pushdown'));
      expect(firstPushdown, greaterThan(lastPress));
    });
  });

  group("Ahmed's full-body list", () {
    // His saved list plus a leg curl, each with its main muscle.
    const List<String> planned = [
      'Techno Pectoral', 'Shoulder Press', 'Incline Chest Press',
      'Overhead Tricep Extension', 'Leg Press', 'Leg Extension',
      'Lat Pulldown', 'Technogym Upper Back Row',
      'Technogym Biceb Curl Machine', 'Preacher Curl', 'Leg Curl', //
    ];
    const Map<String, String> muscles = {
      'Techno Pectoral': 'Chest',
      'Shoulder Press': 'Shoulders',
      'Incline Chest Press': 'Chest',
      'Overhead Tricep Extension': 'Triceps',
      'Leg Press': 'Legs',
      'Leg Extension': 'Legs',
      'Lat Pulldown': 'Back',
      'Technogym Upper Back Row': 'Back',
      'Technogym Biceb Curl Machine': 'Biceps',
      'Preacher Curl': 'Biceps',
      'Leg Curl': 'Legs',
    };
    // Worked out by hand, not with the code's own muscle mapping.
    const Map<String, String> family = {
      'Techno Pectoral': 'push',
      'Shoulder Press': 'push',
      'Incline Chest Press': 'push',
      'Overhead Tricep Extension': 'push',
      'Leg Press': 'legs',
      'Leg Extension': 'legs',
      'Leg Curl': 'legs',
      'Lat Pulldown': 'pull',
      'Technogym Upper Back Row': 'pull',
      'Technogym Biceb Curl Machine': 'pull',
      'Preacher Curl': 'pull',
    };
    const List<String> arms = [
      'Overhead Tricep Extension',
      'Technogym Biceb Curl Machine',
      'Preacher Curl',
    ];

    void expectRulesKept(List<String> today) {
      expect(today.toSet(), planned.toSet());
      for (int i = 1; i < today.length; i++) {
        expect(family[today[i]], isNot(family[today[i - 1]]),
            reason: '${today[i - 1]} then ${today[i]} in $today');
      }
      int at(String name) => today.indexOf(name);
      for (final String big in [
        'Techno Pectoral',
        'Shoulder Press',
        'Incline Chest Press',
      ]) {
        expect(at('Overhead Tricep Extension'), greaterThan(at(big)),
            reason: '$today');
      }
      for (final String big in ['Lat Pulldown', 'Technogym Upper Back Row']) {
        expect(at('Technogym Biceb Curl Machine'), greaterThan(at(big)),
            reason: '$today');
        expect(at('Preacher Curl'), greaterThan(at(big)), reason: '$today');
      }
    }

    test('push, pull and legs take turns, arms after their big lifts', () {
      final List<List<String>> done = [];
      for (int i = 0; i < 9; i++) {
        final List<String> today =
            order(planned, muscles: muscles, recent: done.take(3).toList());
        expectRulesKept(today);
        done.insert(0, today);
      }
    });

    test('each non-arm exercise gets an early slot in any three in a row', () {
      final List<List<String>> done = [];
      final List<Set<String>> early = [];
      for (int i = 0; i < 9; i++) {
        final List<String> today =
            order(planned, muscles: muscles, recent: done.take(3).toList());
        early.add(today.take(4).toSet()); // 11 exercises: 4 early slots
        done.insert(0, today);
      }
      final List<String> nonArms =
          planned.where((n) => !arms.contains(n)).toList();
      for (int w = 0; w + 2 < early.length; w++) {
        expect({...early[w], ...early[w + 1], ...early[w + 2]},
            containsAll(nonArms),
            reason: 'workouts ${w + 1} to ${w + 3}: $early');
      }
    });
  });

  group('the reason line', () {
    test('names the exercises that are early today but were not last time',
        () {
      expect(
        smartOrder(planned: ['A', 'B', 'C', 'D', 'E', 'F'], muscles: untagged,
            recent: [
              ['A', 'B', 'C', 'D', 'E', 'F'],
            ]).movedUp,
        ['F', 'E'],
      );
    });

    test('names at most two', () {
      // Nine exercises: three early slots (I, H, G), all new to them.
      expect(
        smartOrder(
            planned: ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I'],
            muscles: untagged,
            recent: [
              ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I'],
            ]).movedUp,
        ['I', 'H'],
      );
    });

    test('leaves out an exercise that was early last time too', () {
      // One early slot. The row goes first again: the curl must follow it and
      // can't sit next to it, and the bench can't come first either way.
      final SmartOrderResult result = smartOrder(
        planned: ['Curl', 'Row', 'Bench'],
        muscles: {'Curl': 'Biceps', 'Row': 'Back', 'Bench': 'Chest'},
        recent: [
          ['Row', 'Curl', 'Bench'],
        ],
      );
      expect(result.order, ['Row', 'Bench', 'Curl']);
      expect(result.movedUp, isEmpty);
    });

    test('names nothing on the first workout', () {
      expect(
        smartOrder(planned: ['A', 'B', 'C'], muscles: untagged, recent: const [])
            .movedUp,
        isEmpty,
      );
    });
  });
}
