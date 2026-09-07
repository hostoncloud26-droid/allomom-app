import 'package:flutter_test/flutter_test.dart';

import 'package:allomom/services/allobot/allobot_csv.dart';

void main() {
  group('parseCsv', () {
    test('splits plain rows and fields', () {
      expect(
        parseCsv('a,b,c\n1,2,3'),
        [
          ['a', 'b', 'c'],
          ['1', '2', '3'],
        ],
      );
    });

    test('keeps commas inside quoted fields', () {
      // The failure this guards: seed answers routinely read "rich in iron,
      // folate and fiber", which a naive split turns into two columns and
      // shifts every later column by one.
      expect(
        parseCsv('key,"rich in iron, folate and fiber",next'),
        [
          ['key', 'rich in iron, folate and fiber', 'next'],
        ],
      );
    });

    test('keeps newlines inside quoted fields', () {
      expect(
        parseCsv('key,"line one\nline two"\nsecond,row'),
        [
          ['key', 'line one\nline two'],
          ['second', 'row'],
        ],
      );
    });

    test('unescapes doubled quotes', () {
      expect(
        parseCsv('key,"she said ""yes"" to me"'),
        [
          ['key', 'she said "yes" to me'],
        ],
      );
    });

    test('handles CRLF line endings', () {
      expect(
        parseCsv('a,b\r\n1,2\r\n'),
        [
          ['a', 'b'],
          ['1', '2'],
        ],
      );
    });

    test('does not emit a phantom row for a trailing newline', () {
      expect(parseCsv('a,b\n1,2\n').length, 2);
    });

    test('preserves empty trailing fields', () {
      expect(
        parseCsv('a,,c,'),
        [
          ['a', '', 'c', ''],
        ],
      );
    });

    test('returns nothing for empty input', () {
      expect(parseCsv(''), isEmpty);
    });
  });
}
