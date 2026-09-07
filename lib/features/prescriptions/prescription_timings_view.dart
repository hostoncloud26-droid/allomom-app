import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:allomom/models/prescription_timing.dart';
import 'package:drift/drift.dart' as drift;
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/services/prescription_db_service.dart';
import 'package:allomom/features/prescriptions/my_prescription_list.dart';
import 'package:allomom/features/prescriptions/my_prescription_add.dart';
import 'package:allomom/features/prescriptions/prescription_reminder_page.dart';
import 'package:allomom/repositories/user_session_manager.dart';

class PrescriptionTimingsView extends StatefulWidget {
  final String? userId;
  final bool showAppBar;

  const PrescriptionTimingsView({
    super.key,
    this.userId,
    this.showAppBar = false,
  });

  @override
  State<PrescriptionTimingsView> createState() => _PrescriptionTimingsViewState();
}

class _PrescriptionTimingsViewState extends State<PrescriptionTimingsView> {
  static const int _dateItemCount = 30;
  final ScrollController _dateScrollController = ScrollController();

  late DateTime _dateStart;
  DateTime _selectedDate = DateTime.now();
  List<TimingWithMedicationResponse> _timings = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dateStart = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 14));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate();
    });

    _loadTimings();
  }

  @override
  void dispose() {
    _dateScrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedDate() {
    final index = _selectedDate.difference(_dateStart).inDays.clamp(0, _dateItemCount - 1);
    const itemWidth = 66.0;
    final targetOffset = (index * itemWidth) - 100.0;
    if (_dateScrollController.hasClients) {
      _dateScrollController.animateTo(
        targetOffset.clamp(0.0, _dateScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  /// Loads the doses logged for [_selectedDate] from the local Drift database.
  Future<void> _loadTimings() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final startOfDay =
          DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      final endOfDay = DateTime(
          _selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);
      final targetUserId = widget.userId ?? UserSessionManager.instance.userId;

      final details = await PrescriptionDbService.instance.getTimingsInRange(
        from: startOfDay,
        to: endOfDay,
        userId: targetUserId.isEmpty ? null : targetUserId,
      );

      final mapped = details
          .map((d) => TimingWithMedicationResponse(
                id: d.id,
                medicineId: d.medicine?.id ?? '',
                medicineName: d.medicineName,
                dosage: d.dosage,
                mealInstruction: d.notes,
                instructions: d.notes,
                dateTime: d.dateTime,
                status: d.status,
                isTaken: d.isTaken,
                prescriptionId: d.prescription?.id,
              ))
          .toList()
        ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

      if (mounted) {
        setState(() {
          _timings = mapped;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading medicine timings from local database: $e');
      if (mounted) {
        setState(() {
          _timings = [];
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleTaken(TimingWithMedicationResponse timing) async {
    final newStatus = timing.taken ? 'pending' : 'taken';
    setState(() {
      final idx = _timings.indexWhere((t) => t.id == timing.id);
      if (idx != -1) {
        _timings[idx] = TimingWithMedicationResponse(
          id: timing.id,
          medicineId: timing.medicineId,
          medicineName: timing.medicineName,
          type: timing.type,
          dosage: timing.dosage,
          instructions: timing.instructions,
          dateTime: timing.dateTime,
          status: newStatus,
          doctorName: timing.doctorName,
          prescriptionId: timing.prescriptionId,
          mealInstruction: timing.mealInstruction,
          isTaken: newStatus == 'taken',
        );
      }
    });

    try {
      if (newStatus == 'taken') {
        await PrescriptionDbService.instance.markTimingTaken(timing.id);
      } else {
        await PrescriptionDbService.instance.logMedicineTiming(
          PrescriptionMedicineTimingsCompanion(
            id: drift.Value(timing.id),
            status: const drift.Value('pending'),
            medicineTakenTime: const drift.Value(null),
            timingDateTime: drift.Value(timing.dateTime),
            prescriptionMedicineId: drift.Value(
              timing.medicineId.isEmpty ? null : timing.medicineId,
            ),
            synced: const drift.Value(0),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating medicine timing ${timing.id}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = _timings.length;
    final takenCount = _timings.where((t) => t.taken).length;
    final progress = totalCount > 0 ? (takenCount / totalCount) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFC),
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: const Color(0xFFFBFBFC),
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2D3142), size: 20),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              title: Text(
                'Prescription Timings',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E2024),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.list_alt_rounded, color: Color(0xFFFF3B5C)),
                  tooltip: 'All Prescriptions',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyPrescriptionList()),
                    );
                  },
                ),
              ],
            )
          : null,
      body: RefreshIndicator(
        color: const Color(0xFFFF3B5C),
        onRefresh: _loadTimings,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Action Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Medication Timeline',
                          style: GoogleFonts.manrope(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E2024),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          DateFormat('EEEE, d MMMM').format(_selectedDate),
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF8E95A5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFECEF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.list_alt_rounded, color: Color(0xFFFF3B5C), size: 18),
                        ),
                        tooltip: 'All Prescriptions',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MyPrescriptionList()),
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFECEF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_rounded, color: Color(0xFFFF3B5C), size: 18),
                        ),
                        tooltip: 'Add Prescription',
                        onPressed: () async {
                          final res = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MyPrescriptionAdd()),
                          );
                          if (res == true) _loadTimings();
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Date Strip Selector
              _buildDateStrip(),
              const SizedBox(height: 20),

              // Adherence Summary Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFF0F1F5), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 52,
                          height: 52,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 5.5,
                            backgroundColor: const Color(0xFFF1F5F9),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF3B5C)),
                          ),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E2024),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            totalCount == 0
                                ? 'No Doses Scheduled'
                                : takenCount == totalCount
                                    ? 'All doses taken today! 🌟'
                                    : '$takenCount of $totalCount doses taken',
                            style: GoogleFonts.manrope(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E2024),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            totalCount == 0
                                ? 'Tap + to add new prescription medications'
                                : '${totalCount - takenCount} doses remaining for today',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Time-Slotted Medicine List
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: Color(0xFFFF3B5C)),
                  ),
                )
              else if (_timings.isEmpty)
                _buildEmptyDayState()
              else ...[
                _buildTimeSlotSection('Morning', const Color(0xFFFF9800), Icons.wb_sunny_rounded, 6, 12),
                _buildTimeSlotSection('Afternoon', const Color(0xFF10B981), Icons.lunch_dining_rounded, 12, 17),
                _buildTimeSlotSection('Evening', const Color(0xFFF59E0B), Icons.dinner_dining_rounded, 17, 20),
                _buildTimeSlotSection('Night', const Color(0xFF8B5CF6), Icons.bedtime_rounded, 20, 24),
              ],
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateStrip() {
    return SizedBox(
      height: 74,
      child: ListView.builder(
        controller: _dateScrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _dateItemCount,
        itemBuilder: (context, index) {
          final date = _dateStart.add(Duration(days: index));
          final isSelected = date.day == _selectedDate.day &&
              date.month == _selectedDate.month &&
              date.year == _selectedDate.year;
          final isToday = date.day == DateTime.now().day &&
              date.month == DateTime.now().month &&
              date.year == DateTime.now().year;

          return GestureDetector(
            onTap: () {
              setState(() => _selectedDate = date);
              _loadTimings();
            },
            child: Container(
              width: 58,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFF3B5C) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFF3B5C)
                      : isToday
                          ? const Color(0xFFFF3B5C).withValues(alpha: 0.4)
                          : const Color(0xFFE2E8F0),
                  width: isToday ? 1.5 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFF3B5C).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(date).toUpperCase(),
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: GoogleFonts.manrope(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : const Color(0xFF1E2024),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeSlotSection(String title, Color color, IconData icon, int startH, int endH) {
    final slotTimings = _timings.where((t) {
      final h = t.dateTime.hour;
      return h >= startH && h < endH;
    }).toList();

    if (slotTimings.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E2024),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...slotTimings.map((timing) => _buildDoseTile(timing, color)),
        ],
      ),
    );
  }

  Widget _buildDoseTile(TimingWithMedicationResponse timing, Color slotColor) {
    final isTaken = timing.taken;
    final timeStr = DateFormat('hh:mm a').format(timing.dateTime);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PrescriptionReminderPage(
              timingId: timing.id,
              medicineName: timing.medicineName,
            ),
          ),
        ).then((_) => _loadTimings());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isTaken ? const Color(0xFFE2E8F0) : slotColor.withValues(alpha: 0.3),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Custom checkbox
            GestureDetector(
              onTap: () => _toggleTaken(timing),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isTaken ? const Color(0xFF10B981) : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isTaken ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                    width: 2,
                  ),
                ),
                child: isTaken
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                    : null,
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    timing.medicineName,
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isTaken ? const Color(0xFF94A3B8) : const Color(0xFF1E2024),
                      decoration: isTaken ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text.rich(
                    TextSpan(
                      text: timing.dosage ?? '1 Tablet',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                      children: [
                        if (timing.mealInstruction != null && timing.mealInstruction!.isNotEmpty) ...[
                          TextSpan(
                            text: ' • ',
                            style: GoogleFonts.manrope(color: const Color(0xFFCBD5E1)),
                          ),
                          TextSpan(
                            text: timing.mealInstruction!,
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFF3B5C),
                            ),
                          ),
                        ],
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Time badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                timeStr,
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDayState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF0F1F5)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFFFECEF),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.event_available_rounded, color: Color(0xFFFF3B5C), size: 28),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No Medication Scheduled',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E2024),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'You are all clear for this day!',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
