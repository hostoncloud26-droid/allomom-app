class SleepResponseMapModel {
	final DateTime sleepTime;
	final DateTime awakeTime;
	final int totalSleepDuration;
	final int deepSleepDuration;
	final int lightSleepDuration;
	final int remSleepDuration;
	final int awakeDuration;

	SleepResponseMapModel({
		required this.sleepTime,
		required this.awakeTime,
		required this.totalSleepDuration,
		required this.deepSleepDuration,
		required this.lightSleepDuration,
		required this.remSleepDuration,
		required this.awakeDuration,
	});

	factory SleepResponseMapModel.fromJson(Map<String, dynamic> json) {

		return SleepResponseMapModel(
			sleepTime: DateTime.parse(json['sleep_time'] as String? ?? ''),
			awakeTime: DateTime.parse(json['awake_time'] as String? ?? ''),
			totalSleepDuration: (json['total_sleep_duration'] as num?)?.toInt() ?? 0,
			deepSleepDuration: (json['deep_sleep_duration'] as num?)?.toInt() ?? 0,
			lightSleepDuration: (json['light_sleep_duration'] as num?)?.toInt() ?? 0,
			remSleepDuration: (json['rem_sleep_duration'] as num?)?.toInt() ?? 0,
			awakeDuration: (json['awake_duration'] as num?)?.toInt() ?? 0,
		);
	}

	Map<String, dynamic> toJson() {
		return {
			'sleep_time': sleepTime.toIso8601String(),
			'awake_time': awakeTime.toIso8601String(),
			'total_sleep_duration': totalSleepDuration,
			'deep_sleep_duration': deepSleepDuration,
			'light_sleep_duration': lightSleepDuration,
			'rem_sleep_duration': remSleepDuration,
			'awake_duration': awakeDuration,
		};
	}
}
