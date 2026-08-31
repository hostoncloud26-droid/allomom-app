import 'package:flutter/material.dart';
import 'package:allomom/config/colors.dart';
import 'package:allomom/config/spacings.dart';

class PeoplePage extends StatefulWidget {
  const PeoplePage({super.key});

  @override
  State<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends State<PeoplePage> {
  int _selectedTab = 0; // 0: Family, 1: Community
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _familyMembers = [
    {
      'name': 'Lakshmi',
      'phone': '94872 43682',
      'relation': 'Myself',
      'badgeBg': const Color(0xFFFEF3C7),
      'badgeTextColor': const Color(0xFFD97706),
      'avatarLetter': 'L',
      'avatarBg': const Color(0xFFFCE7F0),
      'avatarLetterColor': primaryColor,
    },
    {
      'name': 'Ravi',
      'phone': '97874 64432',
      'relation': 'Anna · co-parent',
      'badgeBg': const Color(0xFFEFF6FF),
      'badgeTextColor': const Color(0xFF3B82F6),
      'avatarLetter': 'R',
      'avatarBg': const Color(0xFFE0E7FF),
      'avatarLetterColor': const Color(0xFF3730A3),
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFC),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            mediumSpacingBox(),
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

  // ─── HEADER ────────────────────────────────────────────────
  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 12),
      child: Text(
        'People',
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w800,
          color: textDark,
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
          color: Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildTabButton(
                title: 'Family',
                index: 0,
              ),
            ),
            Expanded(
              child: _buildTabButton(
                title: 'Community',
                index: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({required String title, required int index}) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
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
              color: isSelected ? primaryColor : Colors.grey.shade600,
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
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      children: [
        _buildFamilyBannerCard(),
        mediumSpacingBox(),
        _buildFamilyActionButtons(),
        largeSpacingBox(),
        _buildFamilyMembersHeader(),
        mediumSpacingBox(),
        for (int i = 0; i < _familyMembers.length; i++) ...[
          Dismissible(
            key: ValueKey('${_familyMembers[i]['name']}_${_familyMembers[i]['phone']}_$i'),
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
                    'Delete',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ],
              ),
            ),
            confirmDismiss: (direction) async {
              if (_familyMembers[i]['relation'] == 'Myself') {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text("Primary account (Myself) cannot be deleted."),
                    backgroundColor: const Color(0xFFFF4E6A),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
                return false;
              }
              return true;
            },
            onDismissed: (direction) {
              final removedMember = _familyMembers[i];
              final removedIndex = i;
              setState(() {
                _familyMembers.removeAt(i);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${removedMember['name']} removed from family'),
                  backgroundColor: const Color(0xFF1E2024),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  action: SnackBarAction(
                    label: 'UNDO',
                    textColor: const Color(0xFFFF3B5C),
                    onPressed: () {
                      setState(() {
                        _familyMembers.insert(removedIndex, removedMember);
                      });
                    },
                  ),
                ),
              );
            },
            child: _buildFamilyMemberCard(
              name: _familyMembers[i]['name'] ?? '',
              phone: _familyMembers[i]['phone'] ?? '',
              badgeText: _familyMembers[i]['relation'] ?? '',
              badgeBg: _familyMembers[i]['badgeBg'] ?? const Color(0xFFFEF3C7),
              badgeTextColor: _familyMembers[i]['badgeTextColor'] ?? const Color(0xFFD97706),
              avatarLetter: _familyMembers[i]['avatarLetter'] ?? 'M',
              avatarBg: _familyMembers[i]['avatarBg'] ?? const Color(0xFFFCE7F0),
              avatarLetterColor: _familyMembers[i]['avatarLetterColor'] ?? primaryColor,
            ),
          ),
          if (i < _familyMembers.length - 1) mediumSpacingBox(),
        ],
      ],
    );
  }

  Widget _buildFamilyBannerCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F5),
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
                // Background trees graphic
                Positioned.fill(
                  child: CustomPaint(
                    painter: _FamilyTreeIllustrationPainter(),
                  ),
                ),
                // Avatar with camera badge
                Positioned(
                  left: 20,
                  bottom: -15,
                  child: Stack(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFFCE7F0),
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('👩‍🦰', style: TextStyle(fontSize: 42)),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF00A896),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Title & member count
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              children: [
                const Text(
                  "Lakshmi's family",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_familyMembers.length + 1} members',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ),
              ],
            ),
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
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
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
              backgroundColor: Colors.white,
              side: BorderSide(color: Colors.grey.shade200),
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
        const Text(
          'Family members',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: textDark,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
                  color: avatarBg,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    avatarLetter,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: avatarLetterColor,
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
                    border: Border.all(color: Colors.white, width: 2),
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 13, color: textLight),
                    const SizedBox(width: 4),
                    Text(
                      phone,
                      style: const TextStyle(
                        fontSize: 12,
                        color: textLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: badgeTextColor,
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
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedRelation = 'Husband / Partner';

    final relations = [
      'Husband / Partner',
      'Mother',
      'Father',
      'Mother-in-law',
      'Father-in-law',
      'Sister',
      'Brother',
      'Caregiver / Other',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 28,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Header Row
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person_add_alt_1_rounded,
                            color: primaryColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add Family Member',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: textDark,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Add support to your pregnancy care circle',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded, color: textDark, size: 22),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 1. NAME FIELD
                    const Text(
                      'Full Name',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: TextField(
                        controller: nameController,
                        style: const TextStyle(fontSize: 14, color: textDark, fontWeight: FontWeight.w600),
                        decoration: const InputDecoration(
                          hintText: 'e.g. Ramesh Kumar',
                          hintStyle: TextStyle(fontSize: 13.5, color: textMuted),
                          prefixIcon: Icon(Icons.person_outline_rounded, color: textLight, size: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 2. RELATION TO MOTHER
                    const Text(
                      'Relation',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: relations.map((rel) {
                        final isSelected = selectedRelation == rel;
                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedRelation = rel;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFFFF0F4) : const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? primaryColor : const Color(0xFFE5E7EB),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected) ...[
                                  Icon(Icons.check_rounded, size: 14, color: primaryColor),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  rel,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? primaryColor : const Color(0xFF4B5563),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // 3. MOBILE NUMBER
                    const Text(
                      'Mobile Number',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(fontSize: 14, color: textDark, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: '98765 43210',
                          hintStyle: const TextStyle(fontSize: 13.5, color: textMuted),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 14, right: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.phone_outlined, color: textLight, size: 18),
                                const SizedBox(width: 6),
                                const Text(
                                  '+91',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: textDark,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 1,
                                  height: 18,
                                  color: const Color(0xFFD1D5DB),
                                ),
                              ],
                            ),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 4. SUBMIT BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          final name = nameController.text.trim();
                          final phone = phoneController.text.trim();

                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter member name'),
                                backgroundColor: Color(0xFFFF3B5C),
                              ),
                            );
                            return;
                          }
                          if (phone.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter mobile number'),
                                backgroundColor: Color(0xFFFF3B5C),
                              ),
                            );
                            return;
                          }

                          final colorThemes = [
                            {'bg': const Color(0xFFF3E8FF), 'text': const Color(0xFF7C3AED), 'badgeBg': const Color(0xFFEDE9FE), 'badgeText': const Color(0xFF6D28D9)},
                            {'bg': const Color(0xFFDCFCE7), 'text': const Color(0xFF15803D), 'badgeBg': const Color(0xFFD1FAE5), 'badgeText': const Color(0xFF059669)},
                            {'bg': const Color(0xFFFEF3C7), 'text': const Color(0xFFD97706), 'badgeBg': const Color(0xFFFEF9C3), 'badgeText': const Color(0xFFCA8A04)},
                            {'bg': const Color(0xFFDBEAFE), 'text': const Color(0xFF1E40AF), 'badgeBg': const Color(0xFFEFF6FF), 'badgeText': const Color(0xFF3B82F6)},
                          ];
                          final theme = colorThemes[_familyMembers.length % colorThemes.length];

                          setState(() {
                            _familyMembers.add({
                              'name': name,
                              'phone': phone.length == 10 ? '${phone.substring(0, 5)} ${phone.substring(5)}' : phone,
                              'relation': selectedRelation,
                              'badgeBg': theme['badgeBg'],
                              'badgeTextColor': theme['badgeText'],
                              'avatarLetter': name.isNotEmpty ? name[0].toUpperCase() : 'M',
                              'avatarBg': theme['bg'],
                              'avatarLetterColor': theme['text'],
                            });
                          });

                          Navigator.pop(ctx);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text('$name added as $selectedRelation')),
                                ],
                              ),
                              backgroundColor: const Color(0xFF10B981),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_add_alt_1_rounded, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Add Member',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
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
          },
        );
      },
    );
  }

  // ─── SHARE QR MODAL ─────────────────────────────────────────
  void _showShareQrModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Family Invite QR Code',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textDark,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Have your partner scan this to link accounts',
              style: TextStyle(
                fontSize: 12,
                color: textLight,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Icon(
                Icons.qr_code_2_rounded,
                size: 160,
                color: textDark,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.copy_rounded, size: 16, color: primaryColor),
                  const SizedBox(width: 8),
                  const Text(
                    'INVITE CODE: ALLOMOM-LAKSHMI-2026',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                    ),
                  ),
                ],
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
                child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700)),
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
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Featured Communities',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: textDark,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
              color: monogramBg,
            ),
            child: Center(
              child: Text(
                monogram,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: monogramTextColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textDark,
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
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyCommunitiesHeader() {
    return const Text(
      'My Communities',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: textDark,
      ),
    );
  }

  Widget _buildCommunitySearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: const InputDecoration(
          icon: Icon(Icons.search_rounded, color: textLight, size: 20),
          hintText: 'Search a community...',
          hintStyle: TextStyle(
            fontSize: 13,
            color: textMuted,
          ),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
              color: avatarBg,
            ),
            child: Center(
              child: Text(
                avatarLetter,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: avatarTextColor,
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
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, size: 12, color: Color(0xFF15803D)),
                      SizedBox(width: 4),
                      Text(
                        'Joined',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF15803D),
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
