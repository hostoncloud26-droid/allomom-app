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
  static DateTime? date(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    final parsed = DateTime.tryParse(raw.toString());
    return parsed?.toLocal();
  }

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
