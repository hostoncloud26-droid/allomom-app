# Vital keys

Every `key` Allomom writes to the vitals stream, with its `unit`, what goes in
`value`, and the fields in `data`. Food, water, sleep, workout and BMI follow
alloconnect's shapes, defined in `lib/models/vital_shapes.dart`. The writers
live in `lib/controllers/health_vital_controller.dart` and `lib/allowear/`.

## Food & lifestyle

| key | unit | value | data |
|---|---|---|---|
| `food` (meals: breakfast, lunch, dinner, snacks) | `kcal` | kcal | `type` = `meal_type` = the meal name, `details`, `total_calorie_intake` (the day's total, including this row) |
| `food` (drinks) | `kcal` | kcal | `type` = `tea` / `coffee` / `beverages`, `meal_type` = `beverages`, `details`, `total_calorie_intake` |
| `water` | `ml` | ml (1 glass = 250 ml; a correction is written as -250) | `type: water`, `details` |
| `sleep_data` | `minutes` | total minutes asleep | `source`, `sleep_time`, `awake_time`, `total_sleep_duration`. Rows from the device also have `deep_sleep_duration`, `light_sleep_duration`, `rem_sleep_duration`, `awake_duration` |
| `workout` | `kcal` | kcal burned | `workout_type` (`Pelvic Exercise` for pelvic-floor sessions), `duration` (minutes), `details` |
| `steps` | `steps` | step count | `source` (`manual` / `device_health`), `distance` (km), `calories`, `steps`. Device rows also have `active_time`, `hourly_data` |

## Body

| key | unit | value | data |
|---|---|---|---|
| `height` | `cm` | cm | — |
| `weight` | `kg` | kg | `weight`, `height`, `bmi` |
| `bmi` | `kg/m²` | BMI, rounded to 1 decimal | `height`, `weight` |

## Clinical / wearable

| key | unit | value | data |
|---|---|---|---|
| `heart_rate` | `bpm` | bpm | `heartRate`, optional `state` |
| `blood_pressure` | `mmHg` | systolic | `systolic`, `diastolic`, optional `pulse` |
| `blood_oxygen` | `%` | SpO₂ | `spo2` |
| `hrv` | `ms` | ms | `hrv` |
| `stress` | `level` | stress score | — |
| `temperature` | `°C` | °C | device tag |
| `hemoglobin` | `g/dL` | g/dL | `hemoglobin` |
| `glucose` | `mg/dL` | mg/dL | `glucose`, `mealPhase` (`fasting` if not given) |
| `battery` | `%` | ring battery level | `source: allowear`, `device_type`, `mac` |

## Pregnancy / baby

| key | unit | value | data |
|---|---|---|---|
| `kick_count` | `kicks` | kick count | `count`, `durationMinutes`, `time` |
| `feeding` | set by the caller | amount | `count`, `amount`, `type` (`Breastfeeding` if not given), `side`, `leftMinutes`, `rightMinutes`, `amountMl` |
| `cry` | `cry` | the cry type as a number code | the cry type's name, confidence, recording file name |

## Notes

- For reading meals, the app also accepts alloconnect's older `break_fast`,
  `lunch` and `dinner` keys.
- Don't write Allomom's old keys (`breakfast`, `snacks`, `drinks`, `sleep`,
  `exercise`).
