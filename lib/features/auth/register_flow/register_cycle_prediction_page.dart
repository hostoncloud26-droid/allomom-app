import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:allomom/features/auth/register_flow/kids_details_page.dart';
import 'package:allomom/features/auth/register_flow/register_partner_details_page.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/services/cycle_predictor.dart';

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
  static final _shortFmt = DateFormat('d MMM');

  int _cycleLength = defaultCycleLength;

  bool get _isNewMom => widget.status.toLowerCase().contains('new');

  CyclePrediction get _prediction =>
      predictCycle(lastPeriodStart: widget.lmpDate, cycleLength: _cycleLength);

  void _next() {
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
                          onTap: () => Navigator.maybePop(context),
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

                  BabyHeroBanner(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    speechText: _isNewMom
                        ? 'Let me help you track your cycle again, Amma 🌸'
                        : "Let's find your best days, Amma! 🌸✨",
                    onSpeakerTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Playing cycle summary...'),
                          duration: Duration(milliseconds: 1000),
                        ),
                      );
                    },
                  ),

                  const Spacer(),

                  // ─── BOTTOM CYCLE CARD ───
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 22,
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
                          const SizedBox(height: 16),

                          // ─── CYCLE LENGTH ───
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Average cycle length',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _ink,
                                      ),
                                    ),
                                    Text(
                                      'Adjust if your cycle is longer or shorter',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: _muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _StepButton(
                                icon: Icons.remove_rounded,
                                enabled: _cycleLength > minCycleLength,
                                onTap: () => setState(() => _cycleLength--),
                              ),
                              SizedBox(
                                width: 54,
                                child: Text(
                                  '$_cycleLength',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: _accent,
                                  ),
                                ),
                              ),
                              _StepButton(
                                icon: Icons.add_rounded,
                                enabled: _cycleLength < maxCycleLength,
                                onTap: () => setState(() => _cycleLength++),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // ─── FERTILE WINDOW (planning only) ───
                          if (!_isNewMom)
                            _InfoTile(
                              icon: Icons.favorite_rounded,
                              iconColor: const Color(0xFF8B5CF6),
                              background: const Color(0xFFF3E8FF),
                              title: 'Fertile window',
                              value:
                                  '${_shortFmt.format(prediction.fertileWindowStart)} '
                                  '– ${_shortFmt.format(prediction.fertileWindowEnd)}',
                              note:
                                  'Ovulation around '
                                  '${_shortFmt.format(prediction.ovulationDate)} — '
                                  'your most likely days to conceive.',
                            )
                          else
                            _InfoTile(
                              icon: Icons.info_outline_rounded,
                              iconColor: const Color(0xFF3898EC),
                              background: const Color(0xFFEDF6FF),
                              title: 'Cycles after delivery',
                              value: 'Often irregular at first',
                              note:
                                  'Breastfeeding can delay your periods. We will '
                                  'refine this prediction as you log each cycle.',
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

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled
          ? _accent.withValues(alpha: 0.12)
          : const Color(0xFFF1F5F9),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 20,
            color: enabled ? _accent : const Color(0xFFCBD5E1),
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.iconColor,
    required this.background,
    required this.title,
    required this.value,
    required this.note,
  });

  final IconData icon;
  final Color iconColor;
  final Color background;
  final String title;
  final String value;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _muted,
                    letterSpacing: 0.4,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  note,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF6B707B),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
