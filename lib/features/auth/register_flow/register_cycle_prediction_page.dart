import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:allomom/features/auth/register_flow/kids_details_page.dart';
import 'package:allomom/features/auth/register_flow/register_partner_details_page.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/services/cycle_predictor.dart';
import 'package:allomom/repositories/pregnancy_state.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/features/background_audio/widgets/baby_narration.dart';

const _accent = Color(0xFFFF4E6A);
const _ink = Color(0xFF1E2024);
const _muted = Color(0xFF8E95A5);

/// Shown instead of the due-date screen when the mother is **not** pregnant.
///
/// "Pre Pregnancy" and "New Mom" have no EDD, so their LMP is used to predict
/// the next period (and, for someone planning a baby, the fertile window).
/// She can correct her cycle length here, which is what the prediction keys
/// off.
class RegisterCyclePredictionPage extends StatefulWidget {
  const RegisterCyclePredictionPage({
    super.key,
    required this.userName,
    required this.status,
    required this.lmpDate,
    this.phone = '',
    this.countryCode = '+91',
    this.selectedRole = 'Mom',
    this.partnerName,
    this.partnerPhone,
  });

  final String userName;

  /// 'Pre Pregnancy' or 'New Mom'.
  final String status;

  final DateTime lmpDate;
  final String phone;
  final String countryCode;
  final String selectedRole;
  final String? partnerName;
  final String? partnerPhone;

  @override
  State<RegisterCyclePredictionPage> createState() =>
      _RegisterCyclePredictionPageState();
}

class _RegisterCyclePredictionPageState
    extends State<RegisterCyclePredictionPage> {
  static final _longFmt = DateFormat('MMMM d, yyyy');

  final int _cycleLength = defaultCycleLength;

  /// The line on the baby head card.
  final String _narrationKey = NarrationKeys.preCycleLength;

  bool get _isNewMom => isNewMomRegistrationLabel(widget.status);

  CyclePrediction get _prediction =>
      predictCycle(lastPeriodStart: widget.lmpDate, cycleLength: _cycleLength);

  void _next() {
    speak(NarrationKeys.preCycleSaved, force: true);

    // Not pregnant either way, so no EDD is carried forward.
    final page = _isNewMom
        ? KidsDetailsPage(
            userName: widget.userName,
            status: widget.status,
            eddDate: null,
            lmpDate: widget.lmpDate,
            averageCycleLength: _cycleLength,
            phone: widget.phone,
            countryCode: widget.countryCode,
            selectedRole: widget.selectedRole,
            partnerName: widget.partnerName,
            partnerPhone: widget.partnerPhone,
          )
        : RegisterPartnerDetailsPage(
            userName: widget.userName,
            status: widget.status,
            eddDate: null,
            lmpDate: widget.lmpDate,
            averageCycleLength: _cycleLength,
            phone: widget.phone,
            countryCode: widget.countryCode,
            selectedRole: widget.selectedRole,
          );

    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final prediction = _prediction;
    final nextPeriod = _longFmt.format(prediction.nextPeriodStart);
    final daysAway = prediction.daysUntilNextPeriod;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F7),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Fills the viewport so the Spacer can push the card to the
            // bottom, and scrolls instead of overflowing when the content or
            // an open keyboard needs more room than the screen has.
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                children: [
                  // ─── TOP APP BAR ───
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => narratedPop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.chevron_left_rounded,
                              color: _ink,
                              size: 24,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Your Cycle',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: _ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: BabyHeroBanner(
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      expand: true,
                      narrationKey: _narrationKey,
                      speechText: _isNewMom
                          ? 'Let me help you track your cycle again, Amma 🌸'
                          : "Let's find your best days, Amma! 🌸✨",
                    ),
                  ),

                  // ─── BOTTOM CYCLE CARD ───
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(
                      24,
                      22,
                      24,
                      22 + MediaQuery.paddingOf(context).bottom,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 20,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NEXT EXPECTED PERIOD',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _muted,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 12),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFF0F3), Color(0xFFFFE4E8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: const Color(0xFFFFD1DC),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 10,
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.water_drop_rounded,
                                    color: _accent,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  nextPeriod,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    fontSize: 21,
                                    fontWeight: FontWeight.bold,
                                    color: _ink,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _accent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    daysAway == 0
                                        ? 'Expected today'
                                        : '$daysAway day${daysAway == 1 ? '' : 's'} to go',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: _next,
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
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
