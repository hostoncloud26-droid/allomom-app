import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:allomom/config/app_theme.dart';
import 'package:allomom/controllers/main_controller.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  final TextEditingController _queryController = TextEditingController();
  final FocusNode _queryFocusNode = FocusNode();

  String? _selectedCategory;
  int? _selectedEmojiIndex;
  bool _isSubmitting = false;

  static const String _deleteAccountCategory = 'Request Account Deletion';

  final List<String> _categories = [
    'General Query',
    'Technical Issue',
    'Device & Sync (AlloWear)',
    'Medical & Pregnancy Advice',
    'Account & Profile',
    'Feedback & Suggestions',
    _deleteAccountCategory,
    'Other',
  ];

  final List<Map<String, dynamic>> _emojis = [
    {'emoji': '😃', 'label': 'Very Happy', 'value': 5},
    {'emoji': '🙂', 'label': 'Happy', 'value': 4},
    {'emoji': '😐', 'label': 'Neutral', 'value': 3},
    {'emoji': '🙁', 'label': 'Sad', 'value': 2},
    {'emoji': '😠', 'label': 'Angry', 'value': 1},
  ];

  @override
  void dispose() {
    _queryController.dispose();
    _queryFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submitHelpRequest() async {
    final queryText = _queryController.text.trim();

    if (queryText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please tell us what's going on."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select why you're reaching us."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final userSession = MainController.instance;
      final currentUser = userSession.currentUser;

      final data = <String, dynamic>{
        'query': queryText,
        'category': _selectedCategory,
        'sentiment': _selectedEmojiIndex != null
            ? _emojis[_selectedEmojiIndex!]['label']
            : null,
        'sentimentValue': _selectedEmojiIndex != null
            ? _emojis[_selectedEmojiIndex!]['value']
            : null,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'platform': Platform.isIOS ? 'ios' : (Platform.isAndroid ? 'android' : Platform.operatingSystem),
        'user': {
          'id': userSession.userId,
          'name': userSession.userName,
          'email': userSession.userEmail,
          'phone': userSession.userPhone,
          'countryCode': userSession.countryCode,
          'gender': userSession.gender,
          'city': userSession.city,
          'pincode': userSession.pincode,
          'addressLine1': userSession.addressLine1,
          'isPregnant': userSession.isPregnant,
          'healthDataId': userSession.healthDataId,
          if (currentUser?.dob != null) 'dob': currentUser?.dob?.toIso8601String(),
        },
      };

      await FirebaseFirestore.instance
          .collection('allomom')
          .doc('help')
          .collection('data')
          .add(data);

      if (!mounted) return;

      final isDeletionRequest = _selectedCategory == _deleteAccountCategory;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isDeletionRequest
              ? 'Your account deletion request has been received. It will be processed within 7 days.'
              : 'Your message has been sent. We will get back to you soon!'),
          backgroundColor: const Color(0xFF00897B),
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.palette.isDark;
    final bgColor = context.palette.background;
    final cardBgColor = isDark ? const Color(0xFF383838) : const Color(0xFFF3F4F6);
    final inputBorderColor = isDark ? const Color(0xFF6B7280) : const Color(0xFFD1D5DB);
    final textPrimary = context.palette.textPrimary;
    final textSecondary = context.palette.textSecondary;
    final hintColor = isDark ? const Color(0xFFB0B0B0) : const Color(0xFF9CA3AF);
    final unselectedEmojiBorder = isDark ? const Color(0xFF9E9E9E) : const Color(0xFFD1D5DB);
    const tealColor = Color(0xFF00897B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: textPrimary,
            size: 26,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Help',
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contact Us',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 12),

                // Large text area
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? Colors.transparent : inputBorderColor,
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: TextField(
                    controller: _queryController,
                    focusNode: _queryFocusNode,
                    maxLines: null,
                    expands: true,
                    style: GoogleFonts.outfit(
                      color: textPrimary,
                      fontSize: 15,
                    ),
                    cursorColor: tealColor,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Tell us what's going on",
                      hintStyle: GoogleFonts.outfit(
                        color: hintColor,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Category Dropdown
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? bgColor : cardBgColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: inputBorderColor, width: 1.2),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      dropdownColor: isDark ? const Color(0xFF383838) : Colors.white,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: textPrimary,
                        size: 28,
                      ),
                      hint: Text(
                        "Tell us why you're reaching us",
                        style: GoogleFonts.outfit(
                          color: textSecondary,
                          fontSize: 15,
                        ),
                      ),
                      style: GoogleFonts.outfit(
                        color: textPrimary,
                        fontSize: 15,
                      ),
                      items: _categories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat,
                          child: Text(
                            cat,
                            style: GoogleFonts.outfit(
                              color: textPrimary,
                              fontSize: 15,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _selectedCategory = val);
                      },
                    ),
                  ),
                ),
                // Account deletion notice
                if (_selectedCategory == _deleteAccountCategory) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: isDark ? 0.15 : 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.6),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'This request will take up to 7 days to process. '
                            'Once processed, your account and all associated data '
                            'will be permanently deleted.',
                            style: GoogleFonts.outfit(
                              color: textPrimary,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Sentiment Section
                Text(
                  'How do you feel? (Optional)',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 16),

                // Emoji Row with circular outlines
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(_emojis.length, (index) {
                    final item = _emojis[index];
                    final isSelected = _selectedEmojiIndex == index;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (_selectedEmojiIndex == index) {
                            _selectedEmojiIndex = null;
                          } else {
                            _selectedEmojiIndex = index;
                          }
                        });
                      },
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? tealColor : unselectedEmojiBorder,
                            width: isSelected ? 2.5 : 1.2,
                          ),
                          color: isSelected
                              ? tealColor.withValues(alpha: isDark ? 0.2 : 0.12)
                              : (isDark ? Colors.transparent : Colors.white),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          item['emoji'] as String,
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 180),

                // SEND button at bottom
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 140,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitHelpRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tealColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'SEND',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
