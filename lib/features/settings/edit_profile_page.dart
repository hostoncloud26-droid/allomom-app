import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/repositories/user_session_manager.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  late TextEditingController _adline1Controller;
  late TextEditingController _adline2Controller;
  late TextEditingController _cityController;
  late TextEditingController _pincodeController;
  late TextEditingController _macController;

  // Selected State
  String _gender = 'Female';
  DateTime? _dob;
  String _pregnancyStatus = 'pregnant';
  DateTime? _lmpDate;
  DateTime? _eddDate;
  String? _bloodGroup;
  String? _imageUrl;
  bool _isSaving = false;

  final List<String> _bloodGroups = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  @override
  void initState() {
    super.initState();
    final session = UserSessionManager.instance;
    _nameController = TextEditingController(text: session.userName);
    _emailController = TextEditingController(text: session.userEmail);
    _phoneController = TextEditingController(text: session.userPhone);
    _bioController = TextEditingController(text: session.bio);
    _adline1Controller = TextEditingController(text: session.adline1);
    _adline2Controller = TextEditingController(text: session.adline2);
    _cityController = TextEditingController(text: session.city);
    _pincodeController = TextEditingController(text: session.pincode);
    _macController = TextEditingController(text: session.allowearMacAddress ?? '');

    _gender = session.gender.isNotEmpty ? (session.gender[0].toUpperCase() + session.gender.substring(1).toLowerCase()) : 'Female';
    _dob = session.dob;
    _pregnancyStatus = session.pregnancyStatus;
    _lmpDate = session.lmpDate;
    _eddDate = session.eddDate;
    _bloodGroup = session.bloodGroup;
    _imageUrl = session.image;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _adline1Controller.dispose();
    _adline2Controller.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    _macController.dispose();
    super.dispose();
  }

  Future<void> _selectDate({
    required BuildContext context,
    required DateTime? initialDate,
    required ValueChanged<DateTime> onDateSelected,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(1950),
      lastDate: lastDate ?? DateTime(2100),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF4E6A),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E2024),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onDateSelected(picked);
    }
  }

  Future<void> _handleSave() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name'),
          backgroundColor: Color(0xFFFF4E6A),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final success = await UserSessionManager.instance.updateProfile(
      name: _nameController.text.trim(),
      email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      gender: _gender.toLowerCase(),
      dob: _dob,
      bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
      city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
      pincode: _pincodeController.text.trim().isEmpty ? null : _pincodeController.text.trim(),
      adline1: _adline1Controller.text.trim().isEmpty ? null : _adline1Controller.text.trim(),
      adline2: _adline2Controller.text.trim().isEmpty ? null : _adline2Controller.text.trim(),
      bloodGroup: _bloodGroup,
      pregnancyStatus: _pregnancyStatus,
      lmpDate: _lmpDate,
      eddDate: _eddDate,
      image: _imageUrl,
      allowearMacAddress: _macController.text.trim().isEmpty ? null : _macController.text.trim(),
    );

    if (_pregnancyStatus == 'pregnant' && _lmpDate != null) {
      await UserSessionManager.instance.saveOrUpdatePregnancy(
        lmpDate: _lmpDate!,
        eddDate: _eddDate,
      );
    } else if (_pregnancyStatus == 'notpregnant') {
      await UserSessionManager.instance.deleteActivePregnancy();
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully! ✨'),
          backgroundColor: Color(0xFFFF4E6A),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update profile remotely, saved locally.'),
          backgroundColor: Color(0xFFFFA500),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF6F7),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverHeader(context),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─── 1. PERSONAL INFORMATION ───
                      _buildSectionCard(
                        title: 'Personal Information',
                        icon: Icons.person_rounded,
                        children: [
                          _buildTextField(
                            controller: _nameController,
                            label: 'Full Name',
                            hint: 'Your name',
                            icon: Icons.badge_outlined,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _emailController,
                            label: 'Email Address',
                            hint: 'email@example.com',
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _phoneController,
                            label: 'Contact Number',
                            hint: 'Mobile number',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDropdownField<String>(
                                  label: 'Gender',
                                  value: _gender,
                                  items: const ['Female', 'Male', 'Other'],
                                  icon: Icons.female_rounded,
                                  onChanged: (val) {
                                    if (val != null) setState(() => _gender = val);
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildDateTile(
                                  label: 'Date of Birth',
                                  date: _dob,
                                  hint: 'Select DOB',
                                  icon: Icons.cake_outlined,
                                  onTap: () => _selectDate(
                                    context: context,
                                    initialDate: _dob ?? DateTime(1995, 1, 1),
                                    firstDate: DateTime(1940),
                                    lastDate: DateTime.now(),
                                    onDateSelected: (d) => setState(() => _dob = d),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _bioController,
                            label: 'Bio / Notes',
                            hint: 'A little about your maternal journey...',
                            icon: Icons.edit_note_rounded,
                            maxLines: 3,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ─── 2. MATERNAL & PREGNANCY CARE ───
                      _buildSectionCard(
                        title: 'Maternal & Pregnancy Care',
                        icon: Icons.child_care_rounded,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Pregnancy Status:',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E2024),
                                ),
                              ),
                              const Spacer(),
                              ChoiceChip(
                                label: Text('Pregnant', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                                selected: _pregnancyStatus == 'pregnant',
                                selectedColor: const Color(0xFFFF4E6A),
                                labelStyle: TextStyle(color: _pregnancyStatus == 'pregnant' ? Colors.white : const Color(0xFF4B5563)),
                                backgroundColor: const Color(0xFFF3F4F6),
                                onSelected: (sel) {
                                  if (sel) setState(() => _pregnancyStatus = 'pregnant');
                                },
                              ),
                              const SizedBox(width: 8),
                              ChoiceChip(
                                label: Text('Not Pregnant', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                                selected: _pregnancyStatus == 'notpregnant',
                                selectedColor: const Color(0xFFFF4E6A),
                                labelStyle: TextStyle(color: _pregnancyStatus == 'notpregnant' ? Colors.white : const Color(0xFF4B5563)),
                                backgroundColor: const Color(0xFFF3F4F6),
                                onSelected: (sel) {
                                  if (sel) setState(() => _pregnancyStatus = 'notpregnant');
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          if (_pregnancyStatus == 'pregnant') ...[
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDateTile(
                                    label: 'LMP Date',
                                    date: _lmpDate,
                                    hint: 'Last Period',
                                    icon: Icons.calendar_today_rounded,
                                    onTap: () => _selectDate(
                                      context: context,
                                      initialDate: _lmpDate ?? DateTime.now().subtract(const Duration(days: 90)),
                                      firstDate: DateTime.now().subtract(const Duration(days: 300)),
                                      lastDate: DateTime.now(),
                                      onDateSelected: (d) {
                                        setState(() {
                                          _lmpDate = d;
                                          _eddDate ??= d.add(const Duration(days: 280));
                                        });
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildDateTile(
                                    label: 'Due Date (EDD)',
                                    date: _eddDate,
                                    hint: 'Expected Due',
                                    icon: Icons.event_available_rounded,
                                    onTap: () => _selectDate(
                                      context: context,
                                      initialDate: _eddDate ?? DateTime.now().add(const Duration(days: 190)),
                                      firstDate: DateTime.now().subtract(const Duration(days: 60)),
                                      lastDate: DateTime.now().add(const Duration(days: 320)),
                                      onDateSelected: (d) => setState(() => _eddDate = d),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],

                          Text(
                            'Blood Group:',
                            style: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E2024),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _bloodGroups.map((bg) {
                              final isSelected = _bloodGroup == bg;
                              return ChoiceChip(
                                label: Text(bg, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold)),
                                selected: isSelected,
                                selectedColor: const Color(0xFFFF5277),
                                labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF374151)),
                                backgroundColor: Colors.white,
                                side: BorderSide(
                                  color: isSelected ? const Color(0xFFFF5277) : const Color(0xFFE5E7EB),
                                  width: 1.2,
                                ),
                                onSelected: (sel) {
                                  setState(() => _bloodGroup = sel ? bg : null);
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ─── 3. ADDRESS & LOCATION ───
                      _buildSectionCard(
                        title: 'Address & Location',
                        icon: Icons.home_rounded,
                        children: [
                          _buildTextField(
                            controller: _adline1Controller,
                            label: 'Address Line 1',
                            hint: 'Flat / House / Street',
                            icon: Icons.location_on_outlined,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _adline2Controller,
                            label: 'Address Line 2',
                            hint: 'Area / Landmark',
                            icon: Icons.map_outlined,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: _buildTextField(
                                  controller: _cityController,
                                  label: 'City / District',
                                  hint: 'City',
                                  icon: Icons.location_city_rounded,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: _buildTextField(
                                  controller: _pincodeController,
                                  label: 'Pincode',
                                  hint: '600001',
                                  icon: Icons.pin_drop_outlined,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ─── 4. ALLOWEAR SMART BAND ───
                      _buildSectionCard(
                        title: 'Allowear Smart Device',
                        icon: Icons.watch_rounded,
                        children: [
                          _buildTextField(
                            controller: _macController,
                            label: 'Allowear MAC Address',
                            hint: 'AA:BB:CC:11:22:33',
                            icon: Icons.bluetooth_searching_rounded,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Pair with Allowear to sync maternal vitals, heart rate, and temperature continuously.',
                            style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        // Floating Save Button
        bottomNavigationBar: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5277),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Save Profile Changes',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── SLIVER HEADER WITH COVER & AVATAR ───
  Widget _buildSliverHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: const Color(0xFFFF4E6A),
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.black.withValues(alpha: 0.25),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Pink Gradient Cover
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFF7E95),
                    Color(0xFFFF4E6A),
                    Color(0xFFFF3366),
                  ],
                ),
              ),
            ),

            // Soft decorative circles
            Positioned(
              right: -30,
              top: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
            ),

            // Centered Avatar
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Container(
                        color: const Color(0xFFFDECEF),
                        child: _imageUrl != null && _imageUrl!.isNotEmpty
                            ? Image.network(
                                _imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.face_3_rounded,
                                  size: 50,
                                  color: Color(0xFFFF4E6A),
                                ),
                              )
                            : Image.asset(
                                'assets/allobaby/woman.png',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.face_3_rounded,
                                  size: 50,
                                  color: Color(0xFFFF4E6A),
                                ),
                              ),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF4E6A),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 16,
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

  // ─── REUSABLE SECTION CARD ───
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFFFF4E6A)),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E2024),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  // ─── REUSABLE TEXT FIELD ───
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4B5563),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1E2024),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF9CA3AF)),
              prefixIcon: Icon(icon, color: const Color(0xFF6B7280), size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  // ─── REUSABLE DROPDOWN FIELD ───
  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<T> items,
    required IconData icon,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4B5563),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF6B7280)),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e.toString(), style: GoogleFonts.poppins(fontSize: 14)))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day.toString().padLeft(2, '0')} ${months[d.month - 1]} ${d.year}';
  }

  // ─── REUSABLE DATE TILE ───
  Widget _buildDateTile({
    required String label,
    required DateTime? date,
    required String hint,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF4B5563),
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: const Color(0xFFFF4E6A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    date != null ? _formatDate(date) : hint,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: date != null ? FontWeight.w600 : FontWeight.normal,
                      color: date != null ? const Color(0xFF1E2024) : const Color(0xFF9CA3AF),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
