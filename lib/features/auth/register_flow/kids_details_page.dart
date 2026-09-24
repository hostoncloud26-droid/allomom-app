import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:allomom/config/app_theme.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/controllers/pregnancy_controller.dart';
import 'package:allomom/features/background_audio/data/narration_flow.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/features/background_audio/widgets/baby_narration.dart';
import 'package:allomom/features/baby/baby_form_sheet.dart';
import 'package:allomom/features/baby/baby_options.dart';
import 'package:allomom/features/main_layout.dart';
import 'package:allomom/repositories/baby_repository.dart';
import 'package:allomom/repositories/pregnancy_state.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sync/sync_codec.dart';

class KidsDetailsPage extends StatefulWidget {
  final String userName;
  final String status;

  /// Null when the mother is not pregnant — there is no due date to carry.
  final DateTime? eddDate;
  final DateTime? lmpDate;
  final int? averageCycleLength;
  final String? partnerName;
  final String? partnerPhone;
  final String phone;
  final String countryCode;
  final String selectedRole;
  final String? familyCode;
  final bool registerPregnancyForPartner;

  const KidsDetailsPage({
    super.key,
    required this.userName,
    required this.status,
    required this.eddDate,
    this.lmpDate,
    this.averageCycleLength,
    this.partnerName,
    this.partnerPhone,
    this.phone = '',
    this.countryCode = '+91',
    this.selectedRole = 'Mom',
    this.familyCode,
    this.registerPregnancyForPartner = false,
  });

  @override
  State<KidsDetailsPage> createState() => _KidsDetailsPageState();
}

class _KidsDetailsPageState extends State<KidsDetailsPage> {
  AppPalette get _p => context.palette;

  static const _pink = Color(0xFFFF4E6A);

  /// The children already on the account.
  ///
  /// Read back from the local database rather than kept as a private list of
  /// what was typed: each child is created for real the moment the sheet is
  /// saved, so this is the same record the rest of the app will show — name,
  /// date of birth, and the vaccination and milestone schedule seeded behind
  /// it.
  List<Baby> _children = const [];

  late final NarrationFlow _flow = NarrationFlowKeys.of(widget.status);

  static final _dateFmt = DateFormat('dd MMM yyyy');

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    unawaited(_prepare());
  }

  /// Settles the health record and reads back any children already recorded.
  ///
  /// A child hangs off a pregnancy, which hangs off the health record, so
  /// resolving it up front means the first "Add Child" is one round trip
  /// rather than two.
  Future<void> _prepare() async {
    await MainController.instance.ensureHealthRecord();
    await _loadChildren();
  }

  Future<void> _loadChildren() async {
    final babies = await BabyRepository.instance.getBabies();
    if (!mounted) return;
    setState(() => _children = babies);
  }

  /// Opens the add-a-child sheet, which creates the child on save.
  ///
  /// The sheet is the same one the Babies screen uses, so a child added during
  /// registration and one added later are the same record built the same way:
  /// the server settles the health record, resolves (or creates) the pregnancy
  /// the child hangs off, and seeds their immunisation schedule and milestone
  /// checklist from the date of birth.
  Future<void> _openAddChildSheet() async {
    final babyId = await showBabyFormSheet(context, title: 'Add your child');
    if (babyId == null || !mounted) return;

    await _loadChildren();
    await MainController.instance.refreshKidsFromBirthRecords();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Child added — vaccination and milestone schedule created.',
        ),
        backgroundColor: _pink,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Removes a child, and the schedules seeded for them, from the account.
  Future<void> _removeChild(Baby child) async {
    setState(
      () => _children = _children.where((b) => b.id != child.id).toList(),
    );
    try {
      await BabyRepository.instance.deleteBaby(child.id);
      await MainController.instance.refreshKidsFromBirthRecords();
    } catch (e) {
      debugPrint('Could not remove child ${child.name}: $e');
    }
    await _loadChildren();
  }

  /// Completes registration.
  ///
  /// The account already exists — it was created the moment the OTP was
  /// verified — so this is a PATCH of the profile plus the records the flow
  /// collected, not a signup. The children are already in: each was created as
  /// its sheet was saved. `is_registered` flips last, once everything else is
  /// there: a run that dies halfway leaves the flag false, so the next sign-in
  /// resumes the flow rather than landing on a half-built home screen.
  Future<void> _finishSetup() async {
    setState(() => _isLoading = true);

    try {
      final isDad = widget.selectedRole.trim().toLowerCase() == 'dad';
      final main = MainController.instance;

      // Partner details are deliberately not persisted: allomom-api-new has no
      // column for them, and a local-only copy would never reach her other
      // devices.
      await main.saveRegistration(
        name: widget.userName,
        gender: isDad ? 'male' : 'female',
        markRegistered: false,
      );

      // A pregnancy, when there is one. The server seeds the ANC, vaccination
      // and report schedules off this LMP.
      final isPregnant =
          pregnancyStatusForRegistration(
            widget.status,
            isDad: isDad,
            registeringForPartner: widget.registerPregnancyForPartner,
          ) ==
          pregnantStatus;

      if (isPregnant && widget.lmpDate != null) {
        await PregnancyController.instance.createPregnancy(
          lmpDate: widget.lmpDate!,
          eddDate: widget.eddDate,
        );
      } else if (widget.lmpDate != null) {
        // Not pregnant, but the LMP still anchors her cycle predictions.
        await main.updateHealthData({
          'lmp_date': SyncCodec.isoUtc(widget.lmpDate!),
        });
      }

      // Only now is the profile genuinely complete.
      await main.completeRegistration();

      if (!mounted) return;
      // Plays across the jump to the home screen, which then greets her.
      speak(_flow.setupDone, force: true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Welcome, ${widget.userName}! Your family profile is complete.',
          ),
          backgroundColor: _pink,
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainLayout()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not finish setting up: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _p.pick(const Color(0xFFFAF6F7), _p.scaffoldSoft),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ─── TOP APP BAR ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => narratedPop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _p.card,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _p.pick(Colors.black12, _p.shadow),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
                        size: 24,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Children Details',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ─── BABY SPEECH AVATAR ───
            BabyHeroBanner(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              narrationKey: NarrationKeys.onbAlmostDone,
              speechText: 'Tell me about my brothers & sisters! 🎈',
              onSpeakerTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Playing siblings joy note...'),
                    duration: Duration(milliseconds: 1000),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // ─── BOTTOM CARD CONTAINER ───
            //
            // A column rather than a scroll view: the children take whatever
            // room there is and "Complete Setup" stays on the bottom edge,
            // where the thumb already is, instead of riding up under the list.
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  24,
                  24,
                  24,
                  16 + MediaQuery.paddingOf(context).bottom,
                ),
                decoration: BoxDecoration(
                  color: _p.card,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: _p.pick(Colors.black12, _p.shadow),
                      blurRadius: 20,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _children.isEmpty
                          ? _emptyState()
                          : _childrenList(),
                    ),
                    const SizedBox(height: 12),

                    // ─── FINISH BUTTON ───
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _finishSetup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5277),
                          disabledBackgroundColor: _p.pick(const Color(0xFFFFC9D4), const Color(0xFF7A3A48)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Complete Setup',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
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
    );
  }

  /// Nothing added yet: the one thing there is to do, in the middle of the
  /// space it would otherwise leave empty.
  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _p.tint(const Color(0xFFFF4E6A), const Color(0xFFFFF0F4)),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.child_care_rounded, size: 34, color: _pink),
          ),
          const SizedBox(height: 16),
          Text(
            'No child added',
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Add your little ones and we'll set up their\n"
            'vaccines and milestones.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              height: 1.5,
              color: _p.pick(const Color(0xFF8E95A5), _p.textMuted),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _openAddChildSheet,
            icon: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
            label: Text(
              'Add Child',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _pink,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _childrenList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ADDED CHILDREN',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: _p.pick(const Color(0xFF8E95A5), _p.textMuted),
                letterSpacing: 0.8,
              ),
            ),
            GestureDetector(
              onTap: _openAddChildSheet,
              child: Row(
                children: [
                  const Icon(
                    Icons.add_circle_outline_rounded,
                    size: 16,
                    color: _pink,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Add Child',
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: _pink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: _children.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (_, index) => _childCard(_children[index], index),
          ),
        ),
      ],
    );
  }

  Widget _childCard(Baby child, int index) {
    final name = child.name.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _p.inputFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _p.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _p.tint(const Color(0xFFFF4E6A), const Color(0xFFFFD8E0)),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.face_rounded, color: _pink, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isEmpty ? 'Child ${index + 1}' : name,
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
                  ),
                ),
                Text(
                  '${_dateFmt.format(child.deliveryDate)}  ·  '
                  '${babyAgeLabel(child.deliveryDate)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: _p.pick(const Color(0xFF6B7280), _p.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _removeChild(child),
            child: Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: _p.pick(const Color(0xFF9CA3AF), _p.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
