import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/features/tasks/domain/reminder_leads.dart';

/// A task's reminders are minutes before its due time, stored as text
/// ("1440,180,30"): any of the three standard ones (1 day, 3 hours, 5 minutes)
/// plus one custom amount (Ahmed, 2026-11-02).
void main() {
  group('splitLeadTimes', () {
    test('separates the standard reminders from the custom amount', () {
      final split = splitLeadTimes(<int>[1440, 30, 5]);
      expect(split.presets, <int>{1440, 5});
      expect(split.custom, 30);
    });

    test('has no custom amount when every reminder is standard', () {
      expect(splitLeadTimes(<int>[180]).custom, isNull);
      expect(splitLeadTimes(<int>[]).presets, isEmpty);
    });
  });

  group('leadTimesCsv', () {
    test('stores the standard reminders in display order, then the custom one',
        () {
      expect(leadTimesCsv(<int>{5, 1440}, 30), '1440,5,30');
    });

    test('is null when no reminder is chosen', () {
      expect(leadTimesCsv(<int>{}, null), isNull);
    });

    test('stores a custom amount equal to a standard one only once', () {
      expect(leadTimesCsv(<int>{5}, 5), '5');
      expect(leadTimesCsv(<int>{}, 180), '180');
    });

    test('reads back what it stored', () {
      final String csv = leadTimesCsv(<int>{180}, 90)!;
      final split = splitLeadTimes(csv.split(',').map(int.parse).toList());
      expect(split.presets, <int>{180});
      expect(split.custom, 90);
    });
  });

  group('wording', () {
    test('a chip uses the largest unit that fits exactly', () {
      expect(leadChipLabel(1440), '1 day');
      expect(leadChipLabel(2880), '2 days');
      expect(leadChipLabel(180), '3 h');
      expect(leadChipLabel(90), '90 min');
      expect(leadChipLabel(5), '5 min');
    });

    test('a notification never rounds the amount', () {
      // The old wording said "in 1 hour" for 90 minutes and "in 1 day" for 36
      // hours, which a custom amount would hit.
      expect(leadAmount(90), '90 minutes');
      expect(leadAmount(2160), '36 hours');
      expect(leadAmount(120), '2 hours');
      expect(leadAmount(1440), '1 day');
      expect(leadAmount(1), '1 minute');
    });
  });
}
