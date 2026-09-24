import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/config/colors.dart';
import 'package:allomom/config/spacings.dart';
import 'package:allomom/services/sq_lite/services/family_db_service.dart';
import 'package:allomom/controllers/family_controller.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/features/people/widgets/add_family_member_sheet.dart';
import 'package:allomom/controllers/connection_controller.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/features/background_audio/widgets/baby_narration.dart';

class PeoplePage extends StatefulWidget {
  const PeoplePage({super.key});

  @override
  State<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends State<PeoplePage> {
  int _selectedTab = 0; // 0: Family, 1: Community

  AppPalette get _p => context.palette;

  /// Deep badge/avatar letter colours, lifted a little so they read on the
  /// dark tints.
  Color _onTint(Color c) =>
      _p.isDark ? Color.lerp(c, Colors.white, 0.35)! : c;
  final TextEditingController _searchController = TextEditingController();

  Map<String, dynamic>? _familyData;
  List<dynamic> _apiFamilyMembers = [];
  bool _isLoadingFamily = true;

  @override
  void initState() {
    super.initState();
    _loadFamilyData();
  }

  /// Loads the family and its members from the local Drift database.
  Future<void> _loadFamilyData() async {
    await _loadFamilyDataInner();
    if (mounted) _speakForTab();
  }

  Future<void> _loadFamilyDataInner() async {
    setState(() {
      _isLoadingFamily = true;
    });
    try {
      final userId = MainController.instance.userId;
      final family = userId.isEmpty
          ? null
          : await FamilyDbService.instance.getMyFamily(userId);

      if (family == null) {
        if (!mounted) return;
        setState(() {
          _familyData = null;
          _apiFamilyMembers = [];
          _isLoadingFamily = false;
        });
        return;
      }

      final members = await FamilyDbService.instance.getFamilyMembers(
        family.id,
      );
      if (!mounted) return;
      setState(() {
        _familyData = {
          'id': family.id,
          'name': family.name ?? 'My Family',
          'code': family.code ?? '',
          'profileImage': family.profileImage,
          'bannerImage': family.bannerImage,
        };
        _apiFamilyMembers = members
            .map(
              (m) => {
                'userid': m.userId,
                'id': m.userId,
                'name': m.name,
                'phone': m.phone ?? '',
                'relation': m.relation,
                'image': m.image,
              },
            )
            .toList();
        _isLoadingFamily = false;
      });
    } catch (e) {
      debugPrint('Error loading family from local database: $e');
      if (mounted) {
        setState(() {
          _isLoadingFamily = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _p.scaffoldSoft,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            _buildTabSwitcher(),
            mediumSpacingBox(),
            Expanded(
              child: _selectedTab == 0
                  ? _buildFamilyTab()
                  : _buildCommunityTab(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TAB SWITCHER (Family / Community) ─────────────────────
  Widget _buildTabSwitcher() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _p.pick(Colors.grey.withValues(alpha: 0.08), _p.surface),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(child: _buildTabButton(title: 'Family', index: 0)),
            Expanded(child: _buildTabButton(title: 'Community', index: 1)),
          ],
        ),
      ),
    );
  }

  /// The line for whichever tab is showing.
  ///
  /// Called from the load and the tab switch, never from `build` — `playByKey`
  /// writes to observables, and doing that mid-build marks other widgets dirty
  /// in the same frame.
  void _speakForTab() {
    if (_selectedTab == 1) {
      // Offline, the honest line comes first: the lists below are stale or
      // empty, and telling her what the tab is for would be no help.
      speak(
        ConnectionController.instance.isInternetAvailable
            ? NarrationKeys.pgCommunityOpen
            : NarrationKeys.pgCommunityOffline,
      );
      return;
    }
    if (_isLoadingFamily) return;
    speak(
      _familyData == null
          ? NarrationKeys.pgFamilyEmpty
          : NarrationKeys.pgFamilyOpen,
    );
  }

  Widget _buildTabButton({required String title, required int index}) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
        _speakForTab();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? _p.pick(Colors.white, const Color(0xFF3A3A40))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _p.pick(Colors.black.withValues(alpha: 0.04), _p.shadow),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? primaryColor : _p.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // ─── FAMILY TAB ────────────────────────────────────────────────────────────
  // ===========================================================================
  Widget _buildFamilyTab() {
    if (_isLoadingFamily) {
      return const Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFamilyData,
      color: primaryColor,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        children: [
          if (_familyData == null) ...[
            _buildNoFamilyCard(),
          ] else ...[
            _buildFamilyBannerCard(),
            mediumSpacingBox(),
            _buildFamilyActionButtons(),
            largeSpacingBox(),
            _buildFamilyMembersHeader(),
            mediumSpacingBox(),
            if (_apiFamilyMembers.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No family members added yet.\nTap "Add member" above to invite!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _p.textMuted,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              )
            else
              for (int i = 0; i < _apiFamilyMembers.length; i++) ...[
                _buildDismissibleMemberItem(_apiFamilyMembers[i], i),
                if (i < _apiFamilyMembers.length - 1) mediumSpacingBox(),
              ],
          ],
        ],
      ),
    );
  }

  /// The viewer's partner, in the words the Family Setup screen uses: a dad is
  /// asked about Mommy, a mom about Daddy.
  String get _partnerWord =>
      MainController.instance.gender.trim().toLowerCase() == 'male'
      ? 'Mommy'
      : 'Daddy';

  static const _setupPink = Color(0xFFFF5277);

  /// No household yet — laid out like Family Setup: the baby asks the
  /// question, and the card below offers the two ways in.
  Widget _buildNoFamilyCard() {
    final isDad = _partnerWord == 'Mommy';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BabyHeroBanner(
          margin: EdgeInsets.zero,
          height: 230,
          speechText: isDad
              ? 'Welcome Daddy! 🌟\nDo you already have a Family Code?'
              : 'Welcome Mommy! 🌟\nDo you already have a Family Code?',
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
          decoration: BoxDecoration(
            color: _p.card,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: _p.pick(Colors.black12, _p.shadow),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FAMILY GROUP',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _p.pick(const Color(0xFF8E95A5), _p.textMuted),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Connect with $_partnerWord',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'A 6-character family code lets you link directly with '
                '$_partnerWord to access shared vitals, timeline, and '
                'pregnancy records.',
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  color: _p.pick(const Color(0xFF6B7280), _p.textSecondary),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 26),

              // Option A: join the family the partner already made.
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _showJoinFamilyDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _setupPink,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.vpn_key_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'I have a Family Code',
                        style: GoogleFonts.poppins(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Option B: no code — start the family here.
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _showCreateFamilyDialog,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _p.border, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.family_restroom_rounded,
                        color: _p.pick(const Color(0xFF4B5563), _p.textSecondary),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'No code? Create a family',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: _p.pick(
                              const Color(0xFF4B5563),
                              _p.textSecondary,
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
      ],
    );
  }

  Widget _buildFamilyBannerCard() {
    final familyName = _familyData?['name'] ?? "My Family";
    final familyCode = _familyData?['code']?.toString() ?? "";
    final membersCount = _apiFamilyMembers.length;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _p.tint(const Color(0xFF70B29F), const Color(0xFFEAF8F5)),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          // Illustration graphic area
          SizedBox(
            height: 140,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _FamilyTreeIllustrationPainter()),
                ),
                Positioned(
                  left: 20,
                  bottom: -15,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _p.pick(const Color(0xFFFCE7F0), const Color(0xFF3A2327)),
                      border: Border.all(color: _p.card, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: _p.pick(Colors.black.withValues(alpha: 0.08), _p.shadow),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text('👨‍👩‍👦', style: TextStyle(fontSize: 38)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Title & member count & family code
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                Text(
                  familyName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _p.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _p.tint(const Color(0xFF15803D), const Color(0xFFDCFCE7)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$membersCount ${membersCount == 1 ? "member" : "members"}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _onTint(const Color(0xFF15803D)),
                        ),
                      ),
                    ),
                    if (familyCode.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: familyCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Family Code $familyCode copied to clipboard!',
                              ),
                              backgroundColor: const Color(0xFF10B981),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _p.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Code: $familyCode',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.copy_rounded,
                                size: 13,
                                color: primaryColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDismissibleMemberItem(dynamic member, int index) {
    if (member is! Map) return const SizedBox.shrink();
    final name = (member['name'] ?? 'Family Member').toString();
    final phone = (member['phone'] ?? '').toString();
    final relation = (member['relation'] ?? 'Member').toString();
    final userId = (member['userid'] ?? member['id'])?.toString();

    Color badgeBg = const Color(0xFFEFF6FF);
    Color badgeText = const Color(0xFF3B82F6);
    Color avatarBg = const Color(0xFFDBEAFE);
    Color avatarLetterColor = const Color(0xFF1E40AF);

    final relLower = relation.toLowerCase();
    if (relLower.contains('mother') || relLower.contains('wife')) {
      badgeBg = const Color(0xFFFCE7F0);
      badgeText = primaryColor;
      avatarBg = const Color(0xFFFFE4E6);
      avatarLetterColor = const Color(0xFFE11D48);
    } else if (relLower.contains('father') || relLower.contains('husband')) {
      badgeBg = const Color(0xFFEFF6FF);
      badgeText = const Color(0xFF3B82F6);
      avatarBg = const Color(0xFFDBEAFE);
      avatarLetterColor = const Color(0xFF1E40AF);
    } else if (relLower.contains('child')) {
      badgeBg = const Color(0xFFDCFCE7);
      badgeText = const Color(0xFF15803D);
      avatarBg = const Color(0xFFD1FAE5);
      avatarLetterColor = const Color(0xFF059669);
    } else if (relLower.contains('caregiver')) {
      badgeBg = const Color(0xFFF3E8FF);
      badgeText = const Color(0xFF7C3AED);
      avatarBg = const Color(0xFFEDE9FE);
      avatarLetterColor = const Color(0xFF6D28D9);
    } else {
      badgeBg = const Color(0xFFFEF3C7);
      badgeText = const Color(0xFFD97706);
      avatarBg = const Color(0xFFFEF9C3);
      avatarLetterColor = const Color(0xFFCA8A04);
    }

    final avatarLetter = name.isNotEmpty ? name[0].toUpperCase() : 'M';

    return Dismissible(
      key: ValueKey('fam_member_${userId}_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: const Color(0xFFFF4E6A),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Remove',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (userId == null) return false;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Remove Member?'),
            content: Text(
              'Are you sure you want to remove $name from your family?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4E6A),
                ),
                child: const Text(
                  'Remove',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
        if (confirm == true) {
          final familyId = _familyData?['id']?.toString() ?? '';
          if (userId.isEmpty || familyId.isEmpty) {
            return false;
          }
          try {
            await FamilyDbService.instance.removeFamilyMember(
              familyId: familyId,
              userId: userId,
            );
            _loadFamilyData();
            return true;
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Failed to remove: $e')));
            }
          }
        }
        return false;
      },
      child: _buildFamilyMemberCard(
        name: name,
        phone: phone,
        badgeText: relation,
        badgeBg: badgeBg,
        badgeTextColor: badgeText,
        avatarLetter: avatarLetter,
        avatarBg: avatarBg,
        avatarLetterColor: avatarLetterColor,
      ),
    );
  }

  void _showJoinFamilyDialog() {
    speak(NarrationKeys.pgFamilyJoin, force: true);
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Join Family',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the 6-character family code provided by your partner.',
              style: TextStyle(fontSize: 13, color: _p.textMuted),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: codeCtrl,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. A1B2C3',
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = codeCtrl.text.trim().toUpperCase();
              if (code.length != 6) return;
              Navigator.pop(ctx);

              // Server-side: the family behind the code was created on the
              // partner's phone, so a lookup against this device's tables
              // could only ever find one this user already knew about.
              final error = await FamilyController.instance.joinByCode(code);
              if (!mounted) return;
              if (error == null) {
                speak(NarrationKeys.pgFamilyJoined, force: true);
                _loadFamilyData();
                return;
              }
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(error)));
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Join', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCreateFamilyDialog() {
    speak(NarrationKeys.pgFamilyCreate, force: true);
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Create Family',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter a name for your family group.',
              style: TextStyle(fontSize: 13, color: _p.textMuted),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                hintText: "e.g. Anand's Family",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              Navigator.pop(ctx);
              final userId = MainController.instance.userId;
              if (userId.isEmpty) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sign in before creating a family'),
                    ),
                  );
                }
                return;
              }
              try {
                await FamilyDbService.instance.createFamily(
                  creatorUserId: userId,
                  name: name.isNotEmpty ? name : null,
                );
                speak(NarrationKeys.pgFamilyCreated, force: true);
                _loadFamilyData();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to create family: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyActionButtons() {
    return Row(
      children: [
        // Add member button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showAddMemberBottomSheet(context),
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
            label: const Text(
              'Add member',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Share QR button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showShareQrModal(context),
            icon: Icon(Icons.qr_code_2_rounded, size: 20, color: primaryColor),
            label: Text(
              'Share QR',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: _p.card,
              side: BorderSide(color: _p.pick(Colors.grey.shade200, _p.border)),
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFamilyMembersHeader() {
    return Row(
      children: [
        Icon(Icons.people_outline_rounded, size: 20, color: primaryColor),
        const SizedBox(width: 8),
        Text(
          'Family members',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _p.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildFamilyMemberCard({
    required String name,
    required String phone,
    required String badgeText,
    required Color badgeBg,
    required Color badgeTextColor,
    required String avatarLetter,
    required Color avatarBg,
    required Color avatarLetterColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _p.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _p.pick(Colors.black.withValues(alpha: 0.02), _p.shadow),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Monogram Avatar with online dot
          Stack(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _p.tint(avatarLetterColor, avatarBg),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    avatarLetter,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _onTint(avatarLetterColor),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF22C55E),
                    border: Border.all(color: _p.card, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // Name, Phone & Badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _p.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: 13,
                      color: _p.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      phone,
                      style: TextStyle(fontSize: 12, color: _p.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _p.tint(badgeTextColor, badgeBg),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: _onTint(badgeTextColor),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Chat Action Button
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withValues(alpha: 0.08),
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              color: primaryColor,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  // ─── ADD MEMBER BOTTOM SHEET ────────────────────────────────
  void _showAddMemberBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return AddFamilyMemberSheet(
          familyID: _familyData?['id']?.toString(),
          onMemberAdded: _loadFamilyData,
        );
      },
    );
  }

  // ─── SHARE QR MODAL ─────────────────────────────────────────
  void _showShareQrModal(BuildContext context) {
    speak(NarrationKeys.pgFamilyCode, force: true);
    final code = _familyData?['code']?.toString() ?? 'ALLOMOM';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ctx.palette.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ctx.palette.pick(Colors.grey.shade300, ctx.palette.divider),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Family Invite Code',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _p.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Share this 6-character code with your partner to join your family',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: _p.textMuted),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ctx.palette.inputFill,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: ctx.palette.border),
              ),
              child: Icon(
                Icons.qr_code_2_rounded,
                size: 160,
                color: _p.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Family Code $code copied to clipboard!'),
                    backgroundColor: const Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: ctx.palette.tint(primaryColor, const Color(0xFFFFF0F4)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.copy_rounded,
                      size: 16,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'INVITE CODE: $code',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // ─── COMMUNITY TAB ─────────────────────────────────────────────────────────
  // ===========================================================================
  Widget _buildCommunityTab() {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      children: [
        _buildFeaturedCommunitiesHeader(),
        mediumSpacingBox(),
        _buildFeaturedCommunitiesGrid(),
        largeSpacingBox(),
        _buildMyCommunitiesHeader(),
        mediumSpacingBox(),
        _buildCommunitySearchBar(),
        mediumSpacingBox(),
        // The disclaimer belongs with the first list of other mothers' posts,
        // not buried in a settings screen.
        _buildCommunityListItem(
          avatarLetter: 'P',
          avatarBg: const Color(0xFFFCE7F0),
          avatarTextColor: primaryColor,
          title: 'Penmai 2026',
        ),
        mediumSpacingBox(),
        _buildCommunityListItem(
          avatarLetter: 'K',
          avatarBg: const Color(0xFFDCFCE7),
          avatarTextColor: const Color(0xFF15803D),
          title: 'Kallur PHC mothers',
        ),
        mediumSpacingBox(),
        _buildCommunityListItem(
          avatarLetter: 'AS',
          avatarBg: const Color(0xFFDBEAFE),
          avatarTextColor: const Color(0xFF1E40AF),
          title: 'ASHA support circle',
        ),
      ],
    );
  }

  Widget _buildFeaturedCommunitiesHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Featured Communities',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _p.textPrimary,
          ),
        ),
        Text(
          'Explore More',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedCommunitiesGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildFeaturedCommunityCard(
            monogram: 'AK',
            monogramBg: const Color(0xFFFCE7F0),
            monogramTextColor: primaryColor,
            title: 'AlloKonnect',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildFeaturedCommunityCard(
            monogram: 'BA',
            monogramBg: const Color(0xFFEFF6FF),
            monogramTextColor: const Color(0xFF1D4ED8),
            title: 'Build with AI',
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedCommunityCard({
    required String monogram,
    required Color monogramBg,
    required Color monogramTextColor,
    required String title,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _p.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _p.pick(Colors.black.withValues(alpha: 0.02), _p.shadow),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _p.tint(monogramTextColor, monogramBg),
            ),
            child: Center(
              child: Text(
                monogram,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _onTint(monogramTextColor),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _p.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Join',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyCommunitiesHeader() {
    return Text(
      'My Communities',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: _p.textPrimary,
      ),
    );
  }

  Widget _buildCommunitySearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _p.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _p.pick(Colors.black.withValues(alpha: 0.02), _p.shadow),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: _p.textPrimary),
        decoration: InputDecoration(
          icon: Icon(Icons.search_rounded, color: _p.textMuted, size: 20),
          hintText: 'Search a community...',
          hintStyle: TextStyle(fontSize: 13, color: _p.textMuted),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCommunityListItem({
    required String avatarLetter,
    required Color avatarBg,
    required Color avatarTextColor,
    required String title,
  }) {
    return GestureDetector(
      // Opening a community is the moment for the disclaimer: what she is
      // about to read is other mothers talking, not medical advice.
      onTap: () => speak(NarrationKeys.pgCommunityDisclaimer),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _p.card,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: _p.pick(Colors.black.withValues(alpha: 0.02), _p.shadow),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _p.tint(avatarTextColor, avatarBg),
              ),
              child: Center(
                child: Text(
                  avatarLetter,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _onTint(avatarTextColor),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _p.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _p.tint(const Color(0xFF15803D), const Color(0xFFDCFCE7)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, size: 12, color: _onTint(const Color(0xFF15803D))),
                        const SizedBox(width: 4),
                        Text(
                          'Joined',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: _onTint(const Color(0xFF15803D)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withValues(alpha: 0.08),
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                color: primaryColor,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter for the Family Banner illustration background
class _FamilyTreeIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintTree = Paint()
      ..color = const Color(0xFF70B29F).withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final paintStem = Paint()
      ..color = const Color(0xFF70B29F).withValues(alpha: 0.4)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    // Draw fence line
    canvas.drawLine(Offset(0, h * 0.7), Offset(w, h * 0.7), paintStem);
    for (double x = 40; x < w; x += 30) {
      canvas.drawLine(Offset(x, h * 0.7), Offset(x, h * 0.8), paintStem);
    }

    // Draw stylized tree tops on sides
    canvas.drawOval(Rect.fromLTWH(w * 0.05, 20, 60, 40), paintTree);
    canvas.drawOval(Rect.fromLTWH(w * 0.12, 35, 55, 45), paintTree);

    canvas.drawOval(Rect.fromLTWH(w * 0.75, 25, 60, 40), paintTree);
    canvas.drawOval(Rect.fromLTWH(w * 0.82, 30, 50, 45), paintTree);

    // Clouds
    final paintCloud = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    canvas.drawOval(Rect.fromLTWH(w * 0.2, 10, 50, 20), paintCloud);
    canvas.drawOval(Rect.fromLTWH(w * 0.65, 12, 45, 18), paintCloud);

    // Simple stylized family silhouettes in the middle
    final paintRed = Paint()..color = const Color(0xFFE14B60);
    final paintNavy = Paint()..color = const Color(0xFF334155);

    // Person 1 (Mother)
    canvas.drawCircle(Offset(w * 0.45, h * 0.4), 10, paintNavy);
    final path1 = Path()
      ..moveTo(w * 0.45, h * 0.48)
      ..lineTo(w * 0.41, h * 0.7)
      ..lineTo(w * 0.49, h * 0.7)
      ..close();
    canvas.drawPath(path1, paintRed);

    // Person 2 (Father)
    canvas.drawCircle(Offset(w * 0.53, h * 0.38), 11, paintNavy);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.505, h * 0.47, 15, 25),
        const Radius.circular(4),
      ),
      paintNavy,
    );

    // Child
    canvas.drawCircle(Offset(w * 0.61, h * 0.5), 7, paintNavy);
    final pathChild = Path()
      ..moveTo(w * 0.61, h * 0.55)
      ..lineTo(w * 0.58, h * 0.7)
      ..lineTo(w * 0.64, h * 0.7)
      ..close();
    canvas.drawPath(pathChild, paintRed);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
