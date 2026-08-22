import 'package:flutter_test/flutter_test.dart';
import 'package:life_tracker/core/widget/widget_payload.dart';

void main() {
  group('argbToHex', () {
    test('formats a full ARGB int the way the native parser expects', () {
      expect(argbToHex(0xFF5FC6D8), '#FF5FC6D8');
    });

    test('pads short values to eight digits', () {
      expect(argbToHex(0x000000FF), '#000000FF');
    });
  });

  group('payloadChecksum', () {
    test('is stable for the same input', () {
      // The whole point: this value is written to preferences by one app launch
      // and compared by the next. If it were not reproducible, the "nothing
      // changed" skip would never fire.
      expect(payloadChecksum('{"a":1}'), payloadChecksum('{"a":1}'));
    });

    test('changes when the payload changes', () {
      expect(payloadChecksum('{"a":1}'), isNot(payloadChecksum('{"a":2}')));
    });

    test('notices a change late in a long payload', () {
      final String base = '{"tasks":[${List.filled(400, '"x"').join(',')}]}';
      final String tweaked = '${base.substring(0, base.length - 3)}y"]}';
      expect(payloadChecksum(base), isNot(payloadChecksum(tweaked)));
    });

    test('handles an empty payload', () {
      expect(payloadChecksum('').isNotEmpty, isTrue);
    });
  });
}
