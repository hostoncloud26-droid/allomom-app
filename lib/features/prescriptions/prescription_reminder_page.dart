import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:allomom/services/api/prescription_api.dart';

class PrescriptionReminderPage extends StatefulWidget {
  final String timingId;
  final String? medicineName;

  const PrescriptionReminderPage({
    super.key,
    required this.timingId,
    this.medicineName,
  });

  @override
  State<PrescriptionReminderPage> createState() => _PrescriptionReminderPageState();
}

class _PrescriptionReminderPageState extends State<PrescriptionReminderPage> {
  Map<String, dynamic>? _timingData;
  bool _isLoading = true;

  double _sliderValue = 2.0; // Defaults to index 2 (10 minutes)
  final List<Map<String, dynamic>> _snoozeIntervals = [
    {"label": "1 min", "minutes": 1},
    {"label": "5 min", "minutes": 5},
    {"label": "10 min", "minutes": 10},
    {"label": "15 min", "minutes": 15},
    {"label": "30 min", "minutes": 30},
    {"label": "1 hr", "minutes": 60},
  ];

  @override
  void initState() {
    super.initState();
    _loadTimingDetails();
  }

  Future<void> _loadTimingDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await PrescriptionApi.getMedicationTimingDetails(widget.timingId);
      if (response.success && response.item != null) {
        setState(() {
          _timingData = Map<String, dynamic>.from(response.item as Map);
          _isLoading = false;
        });
      } else {
        setState(() {
          _timingData = {
            'medicine_name': widget.medicineName ?? 'Prescribed Medication',
            'dosage': '1 dose',
            'status': 'pending',
            'date_time': DateTime.now().toIso8601String(),
          };
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() {
        _timingData = {
          'medicine_name': widget.medicineName ?? 'Prescribed Medication',
          'dosage': '1 dose',
          'status': 'pending',
          'date_time': DateTime.now().toIso8601String(),
        };
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsTaken() async {
    try {
      await PrescriptionApi.markMedicationTimingTaken(widget.timingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medication marked as taken! 🎉'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {
          _timingData?['status'] = 'taken';
        });
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) Navigator.of(context).maybePop(true);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _snooze() async {
    final int index = _sliderValue.round();
    final int minutes = _snoozeIntervals[index]["minutes"];
    final String label = _snoozeIntervals[index]["label"];

    try {
      await PrescriptionApi.snoozeMedicationTiming(widget.timingId, minutes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reminder snoozed for $label'),
            backgroundColor: const Color(0xFF3898EC),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).maybePop(false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFFBFBFC),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF3B5C)),
        ),
      );
    }

    final medicineName = _timingData?['medicine_name'] ?? _timingData?['medicine']?['name'] ?? widget.medicineName ?? 'Medication';
    final dosage = _timingData?['dosage'] ?? _timingData?['medicine']?['dosage'] ?? '1 Tablet';
    final meal = _timingData?['meal_instruction'] ?? _timingData?['medicine']?['meal_instruction'] ?? 'After meal';
    final instructions = _timingData?['instructions'] ?? _timingData?['medicine']?['instructions'];
    final isTaken = _timingData?['status']?.toString().toLowerCase() == 'taken';

    String formattedTime = 'Today';
    if (_timingData?['date_time'] != null) {
      try {
        final dt = DateTime.parse(_timingData!['date_time'].toString());
        formattedTime = DateFormat('hh:mm a').format(dt);
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBFBFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF2D3142), size: 24),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Medication Reminder',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E2024),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // Medicine icon halo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isTaken ? const Color(0xFFE6F9F0) : const Color(0xFFFFECEF),
                  boxShadow: [
                    BoxShadow(
                      color: isTaken
                          ? const Color(0xFF10B981).withValues(alpha: 0.2)
                          : const Color(0xFFFF3B5C).withValues(alpha: 0.2),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    isTaken ? Icons.check_circle_rounded : Icons.medication_rounded,
                    size: 48,
                    color: isTaken ? const Color(0xFF10B981) : const Color(0xFFFF3B5C),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                medicineName,
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E2024),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$dosage • $meal',
                textAlign: TextAlign.center,
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Scheduled for $formattedTime',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF475569),
                  ),
                ),
              ),

              if (instructions != null && instructions.toString().isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  instructions.toString(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],

              const Spacer(),

              if (!isTaken) ...[
                // Snooze Section
                Text(
                  'Snooze: ${_snoozeIntervals[_sliderValue.round()]["label"]}',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 6),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: const Color(0xFF3898EC),
                    inactiveTrackColor: const Color(0xFFE2E8F0),
                    thumbColor: const Color(0xFF3898EC),
                    overlayColor: const Color(0xFF3898EC).withValues(alpha: 0.15),
                  ),
                  child: Slider(
                    value: _sliderValue,
                    min: 0,
                    max: (_snoozeIntervals.length - 1).toDouble(),
                    divisions: _snoozeIntervals.length - 1,
                    onChanged: (v) => setState(() => _sliderValue = v),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: OutlinedButton(
                          onPressed: _snooze,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Text(
                            'Snooze',
                            style: GoogleFonts.manrope(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _markAsTaken,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF3B5C),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Take Dose',
                                style: GoogleFonts.manrope(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F9F0),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      'Dose completed for today! 👍',
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
