class StepHourlyDataModel {
	final int hour;
	final int steps;
	final int calorie;
	final int distance;

	StepHourlyDataModel({
		required this.hour,
		required this.steps,
		required this.calorie,
		required this.distance,
	});

	factory StepHourlyDataModel.fromJson(Map<String, dynamic> json) {
		return StepHourlyDataModel(
			hour: (json['hour'] as num?)?.toInt() ?? 0,
			steps: (json['steps'] as num?)?.toInt() ?? 0,
			calorie: (json['calorie'] as num?)?.toInt() ?? 0,
			distance: (json['distance'] as num?)?.toInt() ?? 0,
		);
	}

	Map<String, dynamic> toJson() {
		return {
			'hour': hour,
			'steps': steps,
			'calorie': calorie,
			'distance': distance,
		};
	}
}

class StepsResponseMapModel {
	final int distance;
	final int calories;
	final int steps;
	final List<StepHourlyDataModel> hourlyData;

	StepsResponseMapModel({
		required this.distance,
		required this.calories,
		required this.steps,
		required this.hourlyData,
	});

	factory StepsResponseMapModel.fromJson(Map<String, dynamic> json) {
		final rawHourly = json['hourly_data'] as List<dynamic>? ?? const [];
		return StepsResponseMapModel(
			distance: (json['distance'] as num?)?.toInt() ?? 0,
			calories: (json['calories'] as num?)?.toInt() ?? 0,
			steps: (json['steps'] as num?)?.toInt() ?? 0,
			hourlyData: rawHourly
					.whereType<Map>()
					.map((e) => StepHourlyDataModel.fromJson(Map<String, dynamic>.from(e)))
					.toList(),
		);
	}

	double get distanceKm => distance / 1000.0;

	int get peakHour {
		if (hourlyData.isEmpty) return 0;
		var peak = hourlyData.first;
		for (final item in hourlyData) {
			if (item.steps > peak.steps) {
				peak = item;
			}
		}
		return peak.hour;
	}

	Map<String, dynamic> toJson() {
		return {
			'distance': distance,
			'calories': calories,
			'steps': steps,
			'hourly_data': hourlyData.map((e) => e.toJson()).toList(),
		};
	}
}
