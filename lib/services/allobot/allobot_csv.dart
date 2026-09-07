/// A minimal RFC 4180 CSV reader for the AlloBot seed sheets.
///
/// The seeds in `lib/seeds/` are Google-Sheets exports: answers are wrapped in
/// double quotes and routinely contain commas ("rich in iron, folate and
/// fiber"), embedded newlines and doubled quotes (`""`). Splitting on `,`
/// therefore shreds them, so this parses properly instead. Written by hand to
/// avoid pulling in a package for ~60 lines of scanning.
library;

/// Parses [source] into rows of fields.
///
/// Quoted fields may span newlines; `""` inside a quoted field is one literal
/// quote. `\r\n` and `\n` both end a record, and a trailing newline does not
/// produce an extra empty row.
List<List<String>> parseCsv(String source) {
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var inQuotes = false;
  var i = 0;

  // Tracks whether the current record has any content, so the newline that
  // terminates the file does not append a phantom `['']` row.
  var recordStarted = false;

  void endField() {
    row.add(field.toString());
    field.clear();
  }

  void endRecord() {
    endField();
    rows.add(row);
    row = <String>[];
    recordStarted = false;
  }

  while (i < source.length) {
    final char = source[i];

    if (inQuotes) {
      if (char == '"') {
        // A doubled quote is an escaped quote; a lone one closes the field.
        if (i + 1 < source.length && source[i + 1] == '"') {
          field.write('"');
          i += 2;
          continue;
        }
        inQuotes = false;
        i++;
        continue;
      }
      field.write(char);
      i++;
      continue;
    }

    switch (char) {
      case '"':
        inQuotes = true;
        recordStarted = true;
        i++;
      case ',':
        recordStarted = true;
        endField();
        i++;
      case '\r':
        // Swallow the CR of a CRLF pair; a bare CR also ends the record.
        if (recordStarted || field.isNotEmpty || row.isNotEmpty) endRecord();
        if (i + 1 < source.length && source[i + 1] == '\n') i++;
        i++;
      case '\n':
        if (recordStarted || field.isNotEmpty || row.isNotEmpty) endRecord();
        i++;
      default:
        recordStarted = true;
        field.write(char);
        i++;
    }
  }

  if (recordStarted || field.isNotEmpty || row.isNotEmpty) endRecord();
  return rows;
}
