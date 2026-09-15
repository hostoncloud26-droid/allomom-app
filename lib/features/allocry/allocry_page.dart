import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/features/allocry/controller/cry_controller.dart';
import 'package:allomom/features/allocry/data/cry_data.dart';
import 'package:allomom/features/allocry/data/cry_record.dart';
import 'package:allomom/features/allocry/screens/cry_history_page.dart';
import 'package:allomom/features/allocry/screens/cry_listening_page.dart';
import 'package:allomom/features/allocry/screens/cry_result_page.dart';
import 'package:allomom/features/allocry/screens/cry_type_detail_page.dart';

/// AlloCry's home: listen to the baby, and learn what each cry means.
///
/// The recent list is the `cry` vitals stream, so it is the same data the rest
/// of AlloMom's health history is built from — there is no separate store to
/// fall out of step with it.
class AlloCryPage extends StatefulWidget {
  const AlloCryPage({super.key});

  @override
  State<AlloCryPage> createState() => _AlloCryPageState();
}

class _AlloCryPageState extends State<AlloCryPage>
    with SingleTickerProviderStateMixin {
  static const Color _pink = Color(0xFFFF4E6A);

  final CryController _controller = CryController.instance;

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    // Loading the 15MB graph up front means the mic button responds instantly
    // when she taps it, rather than stalling on a crying baby.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.loadModel();
      _controller.refreshHistory();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    // She has left AlloCry: give back the 15MB of interpreter memory rather
    // than holding it for a feature that is no longer on screen.
    _controller.releaseModel();
    super.dispose();
  }

  /// Asks for the microphone, then opens the listening screen.
  Future<void> _startListening() async {
    final status = await Permission.microphone.request();
    if (!mounted) return;

    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _pink,
          content: const Text(
            'AlloCry needs microphone access to listen to your baby.',
          ),
          action: status.isPermanentlyDenied
              ? SnackBarAction(
                  label: 'Settings',
                  textColor: Colors.white,
                  onPressed: openAppSettings,
                )
              : null,
        ),
      );
      return;
    }

    await Get.to(() => const CryListeningPage());
    await _controller.refreshHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: GetBuilder<HealthVitalsController>(
          init: HealthVitalsController.instance,
          builder: (_) {
            final records = _controller.history();
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: BabyHeroBanner(
                      speechText: records.isEmpty
                          ? "I'm listening,\nAmma. ❤️"
                          : 'Last time I was\n${records.first.type.heading.toLowerCase()}.',
                      bubblePosition: SpeechBubblePosition.right,
                      height: 270,
                    ),
                  ),
                  const SizedBox(height: 26),
                  _buildTitle(),
                  const SizedBox(height: 22),
                  _buildMicButton(),
                  const SizedBox(height: 14),
                  _buildOfflineNote(),
                  const SizedBox(height: 28),
                  _buildRecentChecks(records),
                  const SizedBox(height: 18),
                  _buildCryTypesSection(),
                  const SizedBox(height: 36),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              elevation: 1,
              shadowColor: Colors.black.withValues(alpha: 0.1),
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(10),
            ),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: _pink),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              children: [
                Text(
                  'AlloCry',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: _pink,
                  ),
                ),
                Text(
                  "Understand your baby's cry",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF8C93A3),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Cry history',
            onPressed: () async {
              await Get.to(() => const CryHistoryPage());
              await _controller.refreshHistory();
            },
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              elevation: 1,
              shadowColor: Colors.black.withValues(alpha: 0.1),
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(10),
            ),
            icon: const Icon(Icons.history_rounded, size: 20, color: _pink),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          'Understand the cry',
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E2229),
          ),
        ),
        const SizedBox(height: 6),
        Obx(() {
          final loading =
              _controller.state.value == CryListeningState.loadingModel;
          final failed = _controller.modelError.value.isNotEmpty;
          return Text(
            failed
                ? _controller.modelError.value
                : loading
                    ? 'Preparing the listening model…'
                    : 'Tap the mic to listen to your baby',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              color: failed ? _pink : const Color(0xFF8B92A2),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildMicButton() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final glowOpacity = 0.14 + (_pulseController.value * 0.1);

        return GestureDetector(
          onTap: _startListening,
          child: Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _pink.withValues(alpha: glowOpacity),
              boxShadow: [
                BoxShadow(
                  color: _pink.withValues(alpha: 0.22),
                  blurRadius: 28,
                  spreadRadius: 4 + (_pulseController.value * 4),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _pink.withValues(alpha: 0.25),
                ),
                child: Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFF627C), Color(0xFFFF3B5C)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF3B5C).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.mic_rounded,
                        color: Colors.white, size: 36),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOfflineNote() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.offline_bolt_rounded, size: 14, color: Color(0xFF10B981)),
        const SizedBox(width: 6),
        Text(
          'Works offline · nothing leaves your phone',
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            color: const Color(0xFF10B981),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentChecks(List<CryRecord> records) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF6F7),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFFE3E8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time_rounded, size: 16, color: _pink),
                const SizedBox(width: 8),
                Text(
                  'Recent checks',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2C2F38),
                  ),
                ),
                const Spacer(),
                if (records.length > 3)
                  GestureDetector(
                    onTap: () async {
                      await Get.to(() => const CryHistoryPage());
                      await _controller.refreshHistory();
                    },
                    child: Text(
                      'See all',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _pink,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (records.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'No readings yet. Tap the mic while your baby is crying and '
                  'AlloCry will tell you what it hears.',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    height: 1.55,
                    color: const Color(0xFF8C93A3),
                  ),
                ),
              )
            else
              ...records.take(3).map(_buildCheckItem),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckItem(CryRecord record) {
    final type = record.type;

    return GestureDetector(
      onTap: () async {
        await Get.to(() => CryResultPage(record: record));
        await _controller.refreshHistory();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: type.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(type.icon, color: type.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type.heading,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E2229),
                    ),
                  ),
                  Text(
                    _relativeTime(record.recordedAt),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF9EA3B0),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: type.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                record.confidenceBand,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: type.color,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFCBD0DC), size: 20),
          ],
        ),
      ),
    );
  }

  String _relativeTime(DateTime date) {
    final now = DateTime.now();
    final day = DateTime(date.year, date.month, date.day);
    final today = DateTime(now.year, now.month, now.day);
    final difference = today.difference(day).inDays;
    final time = DateFormat('h:mm a').format(date);

    if (difference == 0) return 'Today, $time';
    if (difference == 1) return 'Yesterday, $time';
    return '${DateFormat('d MMM').format(date)}, $time';
  }

  Widget _buildCryTypesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_rounded, size: 16, color: _pink),
              const SizedBox(width: 8),
              Text(
                'Why do babies cry?',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C2F38),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.86,
            ),
            itemCount: CryTypes.gridOrder.length,
            itemBuilder: (context, index) {
              final type = CryTypes.all[CryTypes.gridOrder[index]]!;
              return _buildCryTypeCard(type);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCryTypeCard(CryType type) {
    return GestureDetector(
      onTap: () => Get.to(() => CryTypeDetailPage(type: type)),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEEF0F4)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: Image.asset(
                  type.image,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      Text(type.emoji, style: const TextStyle(fontSize: 34)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              type.heading,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E2229),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              type.shortDescription,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                height: 1.4,
                color: const Color(0xFF9EA3B0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
