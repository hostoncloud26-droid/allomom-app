import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:allomom/models/prescription_timing.dart';
import 'package:allomom/services/api/prescription_api.dart';
import 'package:allomom/repositories/user_session_manager.dart';
import 'package:allomom/services/sq_lite/services/prescription_db_service.dart';
import 'package:allomom/features/prescriptions/my_prescription_add.dart';
import 'package:allomom/features/prescriptions/prescription_detail.dart';

class MyPrescriptionList extends StatefulWidget {
  const MyPrescriptionList({super.key});

  @override
  State<MyPrescriptionList> createState() => _MyPrescriptionListState();
}

class _MyPrescriptionListState extends State<MyPrescriptionList> {
  List<PrescriptionModel> _prescriptions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPrescriptions();
  }

  Future<void> _fetchPrescriptions() async {
    setState(() => _isLoading = true);

    try {
      // 1. Try fetching from server API
      final res = await PrescriptionApi.getPrescriptions(skip: 0, limit: 30);
      if (res.success && res.items != null && (res.items as List).isNotEmpty) {
        final list = (res.items as List).map((e) => PrescriptionModel.fromJson(Map<String, dynamic>.from(e as Map))).toList();
        if (mounted) {
          setState(() {
            _prescriptions = list;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (_) {}

    // 2. Fallback to Drift SQLite local database
    try {
      final session = UserSessionManager.instance;
      final healthId = session.currentHealthData?.id ?? (session.userId.isNotEmpty ? session.userId : 'health_me');
      final localRows = await PrescriptionDbService.instance.getPrescriptions(healthId);

      final localList = <PrescriptionModel>[];
      for (final p in localRows) {
        final meds = await PrescriptionDbService.instance.getMedicinesForPrescription(p.id);
        localList.add(
          PrescriptionModel(
            id: p.id,
            description: p.description,
            createdAt: p.createdAt,
            medicines: meds.map((m) => PrescriptionMedicineModel(
              id: m.id,
              name: m.medicineName,
              dosage: m.dosage,
              mealInstruction: m.notes,
              times: m.timings.isNotEmpty ? m.timings.split(',') : const [],
            )).toList(),
          ),
        );
      }

      if (mounted) {
        setState(() {
          _prescriptions = localList;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBFBFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2D3142), size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'All Prescriptions',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E2024),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'all_prescriptions_add_fab',
        backgroundColor: const Color(0xFFFF3B5C),
        elevation: 4,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyPrescriptionAdd()),
          );
          if (result == true) {
            _fetchPrescriptions();
          }
        },
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Add Prescription',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFFFF3B5C),
        onRefresh: _fetchPrescriptions,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF3B5C)))
            : _prescriptions.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    itemCount: _prescriptions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final p = _prescriptions[index];
                      return _buildPrescriptionCard(p);
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFFFECEF),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(Icons.medication_liquid_rounded, color: Color(0xFFFF3B5C), size: 40),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'No Prescriptions Yet',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E2024),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add your doctor prescribed pregnancy medicines and get timely dose reminders.',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyPrescriptionAdd()),
                );
                if (result == true) _fetchPrescriptions();
              },
              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
              label: Text(
                'Add First Prescription',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w800, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF3B5C),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionCard(PrescriptionModel p) {
    final dateStr = DateFormat('dd MMM yyyy').format(p.createdAt);
    final doctor = p.doctorName ?? 'Consulting Obstetrician';
    final hospital = p.hospitalName ?? 'Savemom Maternal Care';
    final medCount = p.medicines.length;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PrescriptionDetailPage(
              prescriptionId: p.id,
              prescription: p,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF0F1F5), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFECEF),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.medical_information_outlined, color: Color(0xFFFF3B5C), size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doctor,
                              style: GoogleFonts.manrope(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1E2024),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              hospital,
                              style: GoogleFonts.manrope(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F9F0),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    'Active',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            if (p.medicines.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: p.medicines.map((m) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.medication_outlined, size: 14, color: Color(0xFFFF3B5C)),
                        const SizedBox(width: 4),
                        Text(
                          m.name,
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],

            const Divider(color: Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$medCount medication${medCount != 1 ? "s" : ""}',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
                Text(
                  dateStr,
                  style: GoogleFonts.manrope(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
