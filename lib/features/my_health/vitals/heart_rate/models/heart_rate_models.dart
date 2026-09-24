import 'package:intl/intl.dart';
import 'package:allomom/models/vitals_stream_model.dart';

class DailyHeartRateStats {
  final DateTime date;
  final double min;
  final double max;
  final double avg;

  DailyHeartRateStats({
    required this.date,
    required this.min,
    required this.max,
    required this.avg,
  });

  static List<DailyHeartRateStats> fromHistory(
    List<VitalsStreamResponse> history,
  ) {
    if (history.isEmpty) return [];

    final Map<String, List<double>> grouped = {};
    for (var item in history) {
      final dateKey = DateFormat('yyyy-MM-dd').format(item.createdAt);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(item.value);
    }

    final List<DailyHeartRateStats> stats = [];
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
          DailyHeartRateStats(
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
