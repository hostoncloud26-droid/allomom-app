import 'package:intl/intl.dart';
import 'package:allomom/models/vitals_stream_model.dart';

class DailyHrvStats {
  final DateTime date;
  final double min;
  final double max;
  final double avg;

  DailyHrvStats({
    required this.date,
    required this.min,
    required this.max,
    required this.avg,
  });

  static List<DailyHrvStats> fromHistory(List<VitalsStreamResponse> history) {
    if (history.isEmpty) return [];

    final Map<String, List<double>> grouped = {};
    for (var item in history) {
      final dateKey = DateFormat('yyyy-MM-dd').format(item.createdAt);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(item.value);
    }

    final List<DailyHrvStats> stats = [];
    grouped.forEach((dateKey, values) {
      if (values.isNotEmpty) {
        final date = DateTime.parse(dateKey);
        double min = values.first;
        double max = values.first;
        double sum = 0;
        for (var v in values) {
          if (v < min) min = v;
          if (v > max) max = v;
          sum += v;
        }
        stats.add(
          DailyHrvStats(
            date: date,
            min: min,
            max: max,
            avg: sum / values.length,
          ),
        );
      }
    });

    stats.sort((a, b) => a.date.compareTo(b.date));
    return stats;
  }
}
