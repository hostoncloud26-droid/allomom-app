import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:allomom/controllers/health_vital_controller.dart';

class VitalLogBottomSheet extends StatefulWidget {
  final String initialKey;
  final bool lockKey;

  const VitalLogBottomSheet({
    super.key,
    this.initialKey = 'blood_pressure',
    this.lockKey = false,
  });

  static Future<bool?> show(
    BuildContext context, {
    String? initialKey,
    bool lockKey = false,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VitalLogBottomSheet(
        initialKey: initialKey ?? 'blood_pressure',
        lockKey: lockKey,
      ),
    );
  }

  @override
  State<VitalLogBottomSheet> createState() => _VitalLogBottomSheetState();
}

class _VitalLogBottomSheetState extends State<VitalLogBottomSheet> {
  late String _currentKey;
  bool _isSaving = false;
  String _errorMessage = '';
  DateTime _selectedDate = DateTime.now();

  // Controllers for different fields
  final _primaryController = TextEditingController();
  final _secondaryController = TextEditingController();
  final _pulseController = TextEditingController();

  // Glucose state
  String _mealPhase = 'fasting';

  // Sleep state
  int _sleepHours = 7;
  int _sleepMinutes = 30;

  // Feeding state
  String _feedingType = 'Breastfeeding';

  @override
  void initState() {
    super.initState();
    _currentKey = widget.initialKey;
    _populateFields();
  }

  void _populateFields() {
    _primaryController.clear();
    _secondaryController.clear();
    _pulseController.clear();
    _errorMessage = '';

    final vitals = HealthVitalsController.instance;
    if (_currentKey == 'blood_pressure') {
      final parts = vitals.bloodPressureValue.split('/');
      _primaryController.text = (parts.isNotEmpty && parts[0] != '--' && parts[0].isNotEmpty) ? parts[0] : '120';
      _secondaryController.text = (parts.length > 1 && parts[1] != '--' && parts[1].isNotEmpty) ? parts[1] : '80';
      _pulseController.text = '72';
    } else if (_currentKey == 'hemoglobin') {
      _primaryController.text = vitals.hasHemoglobin ? vitals.hemoglobinValue.toStringAsFixed(1) : '12.0';
    } else if (_currentKey == 'glucose') {
      _primaryController.text = vitals.hasBloodGlucose ? vitals.bloodGlucoseValue.toInt().toString() : '95';
    } else if (_currentKey == 'heart_rate') {
      _primaryController.text = vitals.hasHeartRate ? vitals.heartRateValue.toString() : '75';
    } else if (_currentKey == 'steps') {
      _primaryController.text = vitals.hasSteps ? vitals.stepsValue.toString() : '5000';
    } else if (_currentKey == 'sleep') {
      _sleepHours = vitals.hasSleep ? vitals.sleepHoursValue.toInt() : 7;
      _sleepMinutes = vitals.hasSleep ? ((vitals.sleepHoursValue - _sleepHours) * 60).round() : 30;
    } else if (_currentKey == 'hrv') {
      _primaryController.text = vitals.hasHrv ? vitals.hrvValue.toString() : '48';
    } else if (_currentKey == 'blood_oxygen') {
      _primaryController.text = vitals.hasBloodOxygen ? vitals.bloodOxygenValue.toString() : '98';
    } else if (_currentKey == 'stress') {
      _primaryController.text = vitals.hasStress ? (vitals.stressVital?.value.toInt().toString() ?? '25') : '25';
    } else if (_currentKey == 'weight') {
      _primaryController.text = vitals.hasWeight ? vitals.weightValue.toStringAsFixed(1) : '60.0';
      _secondaryController.text = vitals.heightValue > 0 ? vitals.heightValue.toInt().toString() : '162';
    } else if (_currentKey == 'kick_count') {
      _primaryController.text = vitals.hasKickCount ? vitals.kickCountValue.toString() : '5';
    } else if (_currentKey == 'feeding') {
      _primaryController.text = vitals.hasFeeding ? (vitals.feedingValue > 0 ? vitals.feedingValue.toInt().toString() : '20') : '20';
      _feedingType = vitals.feedingType;
    }
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _secondaryController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _getVitalTitle(String key) {
    switch (key) {
      case 'blood_pressure': return 'Blood Pressure';
      case 'hemoglobin': return 'Hemoglobin';
      case 'glucose': return 'Blood Glucose';
      case 'heart_rate': return 'Heart Rate';
      case 'steps': return 'Steps';
      case 'sleep': return 'Sleep Duration';
      case 'hrv': return 'HRV';
      case 'blood_oxygen': return 'Blood Oxygen (SpO₂)';
      case 'stress': return 'Stress Load';
      case 'weight': return 'Weight & BMI';
      case 'kick_count': return 'Kick Counter';
      case 'feeding': return 'Feeding Tracker';
      default: return 'Health Reading';
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      if (!mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      setState(() {
        if (time != null) {
          _selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        } else {
          _selectedDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    final vitals = HealthVitalsController.instance;
    setState(() {
      _isSaving = true;
      _errorMessage = '';
    });

    try {
      if (_currentKey == 'blood_pressure') {
        final sys = int.tryParse(_primaryController.text.trim());
        final dia = int.tryParse(_secondaryController.text.trim());
        final pulse = int.tryParse(_pulseController.text.trim());
        if (sys == null || dia == null || sys <= 0 || dia <= 0) {
          throw Exception('Please enter valid Systolic and Diastolic numbers');
        }
        await vitals.addBloodPressureEntry(
          systolic: sys,
          diastolic: dia,
          pulse: pulse,
          createdAt: _selectedDate,
        );
      } else if (_currentKey == 'hemoglobin') {
        final hb = double.tryParse(_primaryController.text.trim());
        if (hb == null || hb <= 0 || hb > 25) {
          throw Exception('Please enter a realistic Hemoglobin value (e.g. 11.5)');
        }
        await vitals.addHemoglobinEntry(hemoglobinGdl: hb, createdAt: _selectedDate);
      } else if (_currentKey == 'glucose') {
        final g = double.tryParse(_primaryController.text.trim());
        if (g == null || g <= 0 || g > 600) {
          throw Exception('Please enter a valid Blood Glucose reading (e.g. 95)');
        }
        await vitals.addBloodGlucoseEntry(mgDl: g, mealPhase: _mealPhase, createdAt: _selectedDate);
      } else if (_currentKey == 'heart_rate') {
        final hr = int.tryParse(_primaryController.text.trim());
        if (hr == null || hr < 30 || hr > 220) {
          throw Exception('Please enter a valid Heart Rate between 30 and 220 bpm');
        }
        await vitals.addHeartRateEntry(bpm: hr, createdAt: _selectedDate);
      } else if (_currentKey == 'steps') {
        final steps = int.tryParse(_primaryController.text.trim());
        if (steps == null || steps < 0) {
          throw Exception('Please enter a valid step count');
        }
        await vitals.addStepsEntry(steps: steps, createdAt: _selectedDate);
      } else if (_currentKey == 'sleep') {
        final totalHours = _sleepHours + (_sleepMinutes / 60.0);
        if (totalHours <= 0) {
          throw Exception('Please select a valid sleep duration');
        }
        await vitals.addSleepEntry(hours: totalHours, createdAt: _selectedDate);
      } else if (_currentKey == 'hrv') {
        final hrv = int.tryParse(_primaryController.text.trim());
        if (hrv == null || hrv < 0 || hrv > 250) {
          throw Exception('Please enter a valid HRV reading (e.g. 48 ms)');
        }
        await vitals.addHrvEntry(hrvMs: hrv, createdAt: _selectedDate);
      } else if (_currentKey == 'blood_oxygen') {
        final spo2 = double.tryParse(_primaryController.text.trim());
        if (spo2 == null || spo2 < 50 || spo2 > 100) {
          throw Exception('Please enter a valid SpO2 percentage (e.g. 98%)');
        }
        await vitals.addBloodOxygenEntry(spo2Percent: spo2, createdAt: _selectedDate);
      } else if (_currentKey == 'stress') {
        final stress = int.tryParse(_primaryController.text.trim());
        if (stress == null || stress < 0 || stress > 100) {
          throw Exception('Please enter a stress score between 0 and 100');
        }
        await vitals.addStressEntry(stressScore: stress, createdAt: _selectedDate);
      } else if (_currentKey == 'weight') {
        final w = double.tryParse(_primaryController.text.trim());
        final h = double.tryParse(_secondaryController.text.trim());
        if (w == null || w < 20 || w > 300) {
          throw Exception('Please enter a valid weight (e.g. 62.5 kg)');
        }
        await vitals.addWeightEntry(weightKg: w, heightCm: h, createdAt: _selectedDate);
      } else if (_currentKey == 'kick_count') {
        final kicks = int.tryParse(_primaryController.text.trim());
        if (kicks == null || kicks < 0) {
          throw Exception('Please enter a valid kick count (e.g. 5)');
        }
        await vitals.addKickCountEntry(count: kicks, createdAt: _selectedDate);
      } else if (_currentKey == 'feeding') {
        final amount = double.tryParse(_primaryController.text.trim());
        if (amount == null || amount <= 0) {
          throw Exception('Please enter a valid feeding duration or amount');
        }
        await vitals.addFeedingEntry(
          value: amount,
          unit: _feedingType == 'Bottle' ? 'ml' : 'mins',
          feedingType: _feedingType,
          createdAt: _selectedDate,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text('${_getVitalTitle(_currentKey)} saved successfully'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final availableKeys = [
      {'key': 'blood_pressure', 'label': 'Blood Pressure', 'icon': Icons.favorite_rounded},
      {'key': 'hemoglobin', 'label': 'Hemoglobin', 'icon': Icons.water_drop_rounded},
      {'key': 'glucose', 'label': 'Glucose', 'icon': Icons.bloodtype_rounded},
      {'key': 'heart_rate', 'label': 'Heart Rate', 'icon': Icons.monitor_heart_rounded},
      {'key': 'steps', 'label': 'Steps', 'icon': Icons.directions_walk_rounded},
      {'key': 'sleep', 'label': 'Sleep', 'icon': Icons.bedtime_rounded},
      {'key': 'weight', 'label': 'Weight & BMI', 'icon': Icons.monitor_weight_rounded},
      {'key': 'blood_oxygen', 'label': 'SpO₂', 'icon': Icons.air_rounded},
      {'key': 'hrv', 'label': 'HRV', 'icon': Icons.grain_rounded},
      {'key': 'stress', 'label': 'Stress', 'icon': Icons.spa_rounded},
      {'key': 'kick_count', 'label': 'Kick Counter', 'icon': Icons.pets_rounded},
      {'key': 'feeding', 'label': 'Feeding', 'icon': Icons.local_drink_rounded},
    ];

    return Container(
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title and Date Selector Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Log ${_getVitalTitle(_currentKey)}',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E2024),
                    ),
                  ),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 13, color: Color(0xFF64748B)),
                          const SizedBox(width: 5),
                          Text(
                            DateFormat('dd MMM, hh:mm a').format(_selectedDate),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Category switch chips (if not locked)
              if (!widget.lockKey) ...[
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: availableKeys.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final item = availableKeys[i];
                      final isSelected = _currentKey == item['key'];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentKey = item['key'] as String;
                            _populateFields();
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFFF3B5C) : const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFFF3B5C) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item['icon'] as IconData,
                                size: 14,
                                color: isSelected ? Colors.white : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                item['label'] as String,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? Colors.white : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Dynamic Input Fields according to vital
              _buildInputsForVital(),

              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 22),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF3B5C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Save Reading',
                          style: GoogleFonts.manrope(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputsForVital() {
    switch (_currentKey) {
      case 'blood_pressure':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _primaryController,
                    label: 'Systolic',
                    suffix: 'mmHg',
                    hint: '120',
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildTextField(
                    controller: _secondaryController,
                    label: 'Diastolic',
                    suffix: 'mmHg',
                    hint: '80',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _pulseController,
              label: 'Pulse (optional)',
              suffix: 'bpm',
              hint: '72',
            ),
          ],
        );

      case 'hemoglobin':
        return _buildTextField(
          controller: _primaryController,
          label: 'Hemoglobin Level',
          suffix: 'g/dL',
          hint: '12.0',
          isDecimal: true,
        );

      case 'glucose':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              controller: _primaryController,
              label: 'Blood Glucose',
              suffix: 'mg/dL',
              hint: '95',
            ),
            const SizedBox(height: 14),
            const Text(
              'Meal Timing',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildMealTimingChip('fasting', 'Fasting'),
                const SizedBox(width: 8),
                _buildMealTimingChip('pre_meal', 'Pre-Meal'),
                const SizedBox(width: 8),
                _buildMealTimingChip('post_meal', 'Post-Meal'),
              ],
            ),
          ],
        );

      case 'heart_rate':
        return _buildTextField(
          controller: _primaryController,
          label: 'Heart Rate',
          suffix: 'bpm',
          hint: '75',
        );

      case 'steps':
        return _buildTextField(
          controller: _primaryController,
          label: 'Step Count',
          suffix: 'steps',
          hint: '5000',
        );

      case 'sleep':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sleep Duration',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$_sleepHours hours', style: const TextStyle(fontWeight: FontWeight.w700)),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _sleepHours = (_sleepHours - 1).clamp(0, 24)),
                              child: const Icon(Icons.remove_circle_outline_rounded, size: 22, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () => setState(() => _sleepHours = (_sleepHours + 1).clamp(0, 24)),
                              child: const Icon(Icons.add_circle_outline_rounded, size: 22, color: Color(0xFFFF3B5C)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('$_sleepMinutes mins', style: const TextStyle(fontWeight: FontWeight.w700)),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => setState(() => _sleepMinutes = (_sleepMinutes - 15).clamp(0, 45)),
                              child: const Icon(Icons.remove_circle_outline_rounded, size: 22, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () => setState(() => _sleepMinutes = (_sleepMinutes + 15).clamp(0, 45)),
                              child: const Icon(Icons.add_circle_outline_rounded, size: 22, color: Color(0xFFFF3B5C)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );

      case 'weight':
        return Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _primaryController,
                label: 'Weight',
                suffix: 'kg',
                hint: '60.0',
                isDecimal: true,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildTextField(
                controller: _secondaryController,
                label: 'Height (cm)',
                suffix: 'cm',
                hint: '162',
              ),
            ),
          ],
        );

      case 'blood_oxygen':
        return _buildTextField(
          controller: _primaryController,
          label: 'Blood Oxygen (SpO₂)',
          suffix: '%',
          hint: '98',
          isDecimal: true,
        );

      case 'hrv':
        return _buildTextField(
          controller: _primaryController,
          label: 'Heart Rate Variability',
          suffix: 'ms',
          hint: '48',
        );

      case 'stress':
        return _buildTextField(
          controller: _primaryController,
          label: 'Stress Score (0-100)',
          suffix: 'score',
          hint: '25',
        );

      case 'kick_count':
        return _buildTextField(
          controller: _primaryController,
          label: 'Kick Count (Movements felt)',
          suffix: 'kicks',
          hint: '5',
        );

      case 'feeding':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Feed Type',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildFeedTypeChip('Breastfeeding', 'Breast'),
                const SizedBox(width: 8),
                _buildFeedTypeChip('Bottle', 'Bottle'),
                const SizedBox(width: 8),
                _buildFeedTypeChip('Solids', 'Solids'),
              ],
            ),
            const SizedBox(height: 14),
            _buildTextField(
              controller: _primaryController,
              label: _feedingType == 'Bottle' ? 'Amount (ml)' : 'Duration (minutes)',
              suffix: _feedingType == 'Bottle' ? 'ml' : 'mins',
              hint: _feedingType == 'Bottle' ? '120' : '20',
            ),
          ],
        );

      default:
        return _buildTextField(
          controller: _primaryController,
          label: 'Value',
          suffix: '',
          hint: '0',
        );
    }
  }

  Widget _buildFeedTypeChip(String type, String label) {
    final isSelected = _feedingType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _feedingType = type;
          if (type == 'Bottle' && (_primaryController.text == '20' || _primaryController.text.isEmpty)) {
            _primaryController.text = '120';
          } else if (type == 'Breastfeeding' && (_primaryController.text == '120' || _primaryController.text.isEmpty)) {
            _primaryController.text = '20';
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF3B5C).withValues(alpha: 0.12) : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF3B5C) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? const Color(0xFFFF3B5C) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String suffix,
    required String hint,
    bool isDecimal = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1E2024)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFCBD5E1)),
            suffixText: suffix,
            suffixStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8)),
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFFF3B5C), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMealTimingChip(String phase, String label) {
    final isSelected = _mealPhase == phase;
    return GestureDetector(
      onTap: () => setState(() => _mealPhase = phase),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1).withValues(alpha: 0.12) : const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? const Color(0xFF6366F1) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
