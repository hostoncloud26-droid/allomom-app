import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:allomom/services/cycle_predictor.dart';
import 'package:allomom/features/auth/register_flow/register_flow_page.dart';

class RegisterCyclePredictionPage extends StatelessWidget {
  final String userName;
  final String status;
  final DateTime lmpDate;
  final int averageCycleLength;
  final String phone;
  final String countryCode;
  final String selectedRole;
  final String? partnerName;
  final String? partnerPhone;
  final bool registerPregnancyForPartner;

  const RegisterCyclePredictionPage({
    super.key,
    required this.userName,
    required this.status,
    required this.lmpDate,
    this.averageCycleLength = 28,
    this.phone = '',
    this.countryCode = '+91',
    this.selectedRole = 'Mom',
    this.partnerName,
    this.partnerPhone,
    this.registerPregnancyForPartner = false,
  });

  @override
  Widget build(BuildContext context) {
    return RegisterFlowPage(
      initialStep: RegisterStep.cyclePrediction,
      userName: userName,
      status: status,
      lmpDate: lmpDate,
      phone: phone,
      countryCode: countryCode,
      selectedRole: selectedRole,
      partnerName: partnerName,
      partnerPhone: partnerPhone,
      registerPregnancyForPartner: registerPregnancyForPartner,
    );
  }
}

class RegisterCyclePredictionStepView extends StatefulWidget {
  final DateTime lmpDate;
  final int cycleLength;
  final String narrationKey;
  final ValueChanged<String> onHintSelected;
  final VoidCallback onNext;
  final ValueChanged<int>? onCycleLengthChanged;

  const RegisterCyclePredictionStepView({
    super.key,
    required this.lmpDate,
    this.cycleLength = 28,
    required this.narrationKey,
    required this.onHintSelected,
    required this.onNext,
    this.onCycleLengthChanged,
  });

  @override
  State<RegisterCyclePredictionStepView> createState() =>
      _RegisterCyclePredictionStepViewState();
}

class _RegisterCyclePredictionStepViewState
    extends State<RegisterCyclePredictionStepView> {
  static final _longFmt = DateFormat('MMMM d, yyyy');
  late int _cycleLength;

  @override
  void initState() {
    super.initState();
    _cycleLength = widget.cycleLength.clamp(21, 35);
  }

  @override
  void didUpdateWidget(covariant RegisterCyclePredictionStepView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.cycleLength != widget.cycleLength) {
      setState(() {
        _cycleLength = widget.cycleLength.clamp(21, 35);
      });
    }
  }

  void _updateCycleLength(int length) {
    final clamped = length.clamp(21, 35);
    if (_cycleLength == clamped) return;
    HapticFeedback.selectionClick();
    setState(() => _cycleLength = clamped);
    widget.onCycleLengthChanged?.call(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final prediction = predictCycle(
      lastPeriodStart: widget.lmpDate,
      cycleLength: _cycleLength,
    );
    final nextPeriod = _longFmt.format(prediction.nextPeriodStart);
    final daysAway = prediction.daysUntilNextPeriod;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PREDICTED NEXT PERIOD',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF8E95A5),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Main Date Card with Row layout (Date on left, Cycle Length on right)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFF0F3), Color(0xFFFFE2E8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xFFFFCAD6),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFFF4E6A,
                          ).withValues(alpha: 0.09),
                          blurRadius: 16,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left Column: Date & Days Badge
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFFFF4E6A,
                                          ).withValues(alpha: 0.12),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.calendar_today_rounded,
                                      size: 14,
                                      color: Color(0xFFFF4E6A),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      nextPeriod,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.outfit(
                                        fontSize: 18.5,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1E2024),
                                        height: 1.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF4E6A),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFFF4E6A,
                                      ).withValues(alpha: 0.25),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.access_time_rounded,
                                      size: 13,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      daysAway > 0
                                          ? '$daysAway Days to go'
                                          : 'Due today',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 10),

                        // Right Container: Distinct Box with Cycle Length & Stepper
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: const Color(0xFFFFD2DC),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Cycle Length',
                                style: GoogleFonts.poppins(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$_cycleLength Days',
                                style: GoogleFonts.poppins(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFFF4E6A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Minus Button
                                  InkWell(
                                    onTap: _cycleLength > 21
                                        ? () => _updateCycleLength(
                                            _cycleLength - 1,
                                          )
                                        : null,
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: _cycleLength > 21
                                            ? const Color(0xFFFFF0F3)
                                            : const Color(0xFFF3F4F6),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: _cycleLength > 21
                                              ? const Color(0xFFFFD2DC)
                                              : const Color(0xFFE5E7EB),
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.remove_rounded,
                                        size: 16,
                                        color: _cycleLength > 21
                                            ? const Color(0xFFFF4E6A)
                                            : const Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Plus Button
                                  InkWell(
                                    onTap: _cycleLength < 35
                                        ? () => _updateCycleLength(
                                            _cycleLength + 1,
                                          )
                                        : null,
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: _cycleLength < 35
                                            ? const Color(0xFFFFF0F3)
                                            : const Color(0xFFF3F4F6),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: _cycleLength < 35
                                              ? const Color(0xFFFFD2DC)
                                              : const Color(0xFFE5E7EB),
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.add_rounded,
                                        size: 16,
                                        color: _cycleLength < 35
                                            ? const Color(0xFFFF4E6A)
                                            : const Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // ─── NEXT BUTTON ───
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: widget.onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5277),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    'Confirm & Next',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
