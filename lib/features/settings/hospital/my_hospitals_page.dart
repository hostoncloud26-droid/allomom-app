import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:allomom/api/hospital_api.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/config/colors.dart';
import 'package:allomom/features/settings/hospital/hospital_detail_page.dart';
import 'package:allomom/features/settings/hospital/hospital_find_page.dart';
import 'package:allomom/models/my_hospital.dart';

/// Hospitals the mother added herself. Tapping one opens its details.
class MyHospitalsPage extends StatefulWidget {
  const MyHospitalsPage({super.key});

  @override
  State<MyHospitalsPage> createState() => _MyHospitalsPageState();
}

class _MyHospitalsPageState extends State<MyHospitalsPage> {
  static final _dateFmt = DateFormat('dd MMM yyyy');

  Color get _ink => context.palette.textPrimary;
  Color get _inkSoft => context.palette.textSecondary;
  Color get _pinkWash => context.palette.tint(primaryColor, accentLight);

  bool _loading = true;
  List<MyHospital> _hospitals = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await HospitalApi.getMyHospitals();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success && res.items is List) {
        _hospitals = (res.items as List)
            .map((e) => MyHospital.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
    });
    if (!res.success) _toast('Failed to load hospitals');
  }

  Future<void> _addHospital() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const HospitalFindPage()),
    );
    if (added == true) await _load();
  }

  Future<void> _remove(MyHospital hospital) async {
    if (await removeHospitalWithConfirm(context, hospital)) await _load();
  }

  Future<void> _openDetails(MyHospital hospital) async {
    final removed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => HospitalDetailPage(hospital: hospital)),
    );
    if (removed == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.scaffoldSoft,
      appBar: AppBar(
        backgroundColor: context.palette.scaffoldSoft,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: _ink, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Hospital',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addHospital,
        backgroundColor: primaryColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Add hospital',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _loading && _hospitals.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _hospitals.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [_empty()],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                      itemCount: _hospitals.length,
                      itemBuilder: (_, i) => _hospitalCard(_hospitals[i]),
                    ),
            ),
    );
  }

  Widget _empty() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 96),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(color: _pinkWash, shape: BoxShape.circle),
            child: const Icon(
              Icons.local_hospital_rounded,
              size: 38,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'No hospital added yet',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add the hospital where you are getting your pregnancy care.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: _inkSoft,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _hospitalCard(MyHospital hospital) {
    final left = hospital.leftAt?.toLocal();
    return Opacity(
      opacity: hospital.hasLeft ? 0.7 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: context.palette.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.palette.divider),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _openDetails(hospital),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 4, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _pinkWash,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_hospital_rounded,
                      color: primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hospital.name,
                          style: GoogleFonts.outfit(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                          ),
                        ),
                        if (hospital.address?.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Text(
                            hospital.address!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: _inkSoft,
                              height: 1.4,
                            ),
                          ),
                        ],
                        if (hospital.contact?.isNotEmpty == true) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.call_outlined,
                                size: 13,
                                color: _inkSoft,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                hospital.contact!,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: _inkSoft,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 8),
                        _statusChip(left),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, color: _inkSoft),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    onSelected: (value) {
                      if (value == 'remove') _remove(hospital);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'remove',
                        child: Text(
                          'Remove',
                          style: TextStyle(color: dangerRed),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusChip(DateTime? left) {
    final isCurrent = left == null;
    final color = isCurrent ? successGreen : _inkSoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: context.palette.tint(color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isCurrent ? 'Current hospital' : 'Left on ${_dateFmt.format(left)}',
        style: GoogleFonts.poppins(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
