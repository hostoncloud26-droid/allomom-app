import 'dart:convert';

/// Conversions shared by every sync mapper.
///
/// The server speaks JSON with ISO-8601 timestamps and real arrays; sqlite has
/// neither, so arrays and objects are stored as JSON text and timestamps as
/// drift `DateTime`s. Keeping the conversions here means a screen never sees a
/// half-decoded row, and a malformed value from the wire degrades to null
/// instead of throwing mid-sync and stranding the rest of the batch.
class SyncCodec {
  const SyncCodec._();

  /// Parses an ISO-8601 string to local time. Returns null on anything unusable.
  ///
  /// A timestamp without an offset is UTC. The server keeps some columns as
  /// plain `DateTime` (`vitals_stream.createdAt` among them): it stores the
  /// UTC value [isoUtc] sent, minus the offset, and hands it back that way.
  /// Read as local time instead, every such row would come back shifted by
  /// the device's offset — a reading at noon in India returning as 6:30. A
  /// bare `YYYY-MM-DD` is a calendar day, not an instant, so it stays local.
  static DateTime? date(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    final text = raw.toString().trim();
    if (_dayOnly.hasMatch(text)) return DateTime.tryParse(text);
    final parsed = DateTime.tryParse(
      _hasOffset.hasMatch(text) ? text : '${text}Z',
    );
    return parsed?.toLocal();
  }

  static final RegExp _dayOnly = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  /// A trailing `Z` or `±hh:mm` / `±hhmm` offset.
  static final RegExp _hasOffset = RegExp(r'(Z|[+-]\d{2}:?\d{2})$', caseSensitive: false);

  /// Formats for the wire. Always UTC, so the server never has to guess at the
  /// device's offset.
  static String? isoUtc(DateTime? value) => value?.toUtc().toIso8601String();

  /// Formats as a bare `YYYY-MM-DD` for the server's `date` columns, which
  /// reject a full timestamp.
  static String? isoDate(DateTime? value) {
    if (value == null) return null;
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String? text(dynamic raw) => raw?.toString();

  static double? number(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString());
  }

  static int? integer(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    return int.tryParse(raw.toString());
  }

  static bool? boolean(dynamic raw) {
    if (raw == null) return null;
    if (raw is bool) return raw;
    final s = raw.toString().toLowerCase();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
    return null;
  }

  /// Server array/object -> JSON text for a sqlite TEXT column.
  static String? encodeJson(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) return raw.isEmpty ? null : raw;
    try {
      return jsonEncode(raw);
    } catch (_) {
      return null;
    }
  }

  /// sqlite TEXT column -> list, for the columns the server stores as arrays.
  static List<String> decodeStringList(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {
      // Fall through — a value written before this column was JSON.
    }
    return const [];
  }

  /// sqlite TEXT column -> map, for the columns the server stores as objects.
  static Map<String, dynamic> decodeMap(String? raw) {
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      // Fall through.
    }
    return const {};
  }
}
