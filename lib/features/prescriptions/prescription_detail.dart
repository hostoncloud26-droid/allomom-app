import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:allomom/models/prescription_timing.dart';
import 'package:allomom/services/sq_lite/services/prescription_db_service.dart';

class PrescriptionDetailPage extends StatefulWidget {
  final String prescriptionId;
  final PrescriptionModel? prescription;

  const PrescriptionDetailPage({
    super.key,
    required this.prescriptionId,
    this.prescription,
  });

  @override
  State<PrescriptionDetailPage> createState() => _PrescriptionDetailPageState();
}

class _PrescriptionDetailPageState extends State<PrescriptionDetailPage> {
  AppPalette get _pal => context.palette;

  PrescriptionModel? _prescription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.prescription != null) {
      _prescription = widget.prescription;
      _isLoading = false;
    } else {
      _loadDetails();
    }
  }

  /// Loads the prescription from the local Drift database.
  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    try {
      final row = await PrescriptionDbService.instance
          .getPrescriptionById(widget.prescriptionId);
      if (row != null) {
        final meds = await PrescriptionDbService.instance
            .getMedicinesForPrescription(row.id);
        if (!mounted) return;
        setState(() {
          _prescription = PrescriptionModel(
            id: row.id,
            description: row.description,
            createdAt: row.createdAt,
            medicines: meds
                .map((m) => PrescriptionMedicineModel(
                      id: m.id,
                      name: m.medicineName,
                      dosage: m.dosage,
                      mealInstruction: m.notes,
                      times: decodeMedicineTimings(m.timings),
                    ))
                .toList(),
          );
        });
      }
    } catch (e) {
      debugPrint('Error loading prescription ${widget.prescriptionId}: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _pal.scaffoldSoft,
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF3B5C)),
        ),
      );
    }

    final p = _prescription;
    final doctor = p?.doctorName ?? 'Gynecologist / Obstetrician';
    final hospital = p?.hospitalName ?? 'Savemom Maternal Care';
    final dateStr = p != null ? DateFormat('dd MMM yyyy').format(p.createdAt) : 'Recently';

    return Scaffold(
      backgroundColor: _pal.scaffoldSoft,
      appBar: AppBar(
        backgroundColor: _pal.scaffoldSoft,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: _pal.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Prescription Details',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _pal.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Doctor & Hospital Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _pal.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _pal.pick(const Color(0xFFF0F1F5), _pal.border), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: _pal.pick(Colors.black.withValues(alpha: 0.03), _pal.shadow),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: _pal.tint(const Color(0xFFFF3B5C), const Color(0xFFFFECEF)),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.medical_services_rounded, color: Color(0xFFFF3B5C), size: 24),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doctor,
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: _pal.textPrimary,
                              ),
                            ),
                            Text(
                              hospital,
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _pal.pick(const Color(0xFF64748B), _pal.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Divider(color: _pal.pick(const Color(0xFFF1F5F9), _pal.divider), height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Prescribed Date',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _pal.textMuted,
                        ),
                      ),
                      Text(
                        dateStr,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _pal.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Medicines List
            Text(
              'Prescribed Medications (${p?.medicines.length ?? 0})',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _pal.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            if (p != null && p.medicines.isNotEmpty) ...[
              ...p.medicines.map((med) => _buildMedicineCard(med)),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _pal.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _pal.pick(const Color(0xFFF0F1F5), _pal.border)),
                ),
                child: Center(
                  child: Text(
                    'No medications found in this prescription.',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _pal.textMuted,
                    ),
                  ),
                ),
              ),
            ],

            if (p?.description != null && p!.description!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Doctor Notes',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _pal.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _pal.pick(const Color(0xFFF8FAFC), _pal.inputFill),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _pal.pick(const Color(0xFFE2E8F0), _pal.border)),
                ),
                child: Text(
                  p.description!,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _pal.pick(const Color(0xFF475569), _pal.textSecondary),
                    height: 1.4,
                  ),
                ),
              ),
            ],

            if (p?.imageUrl != null && p!.imageUrl!.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Attached Prescription',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _pal.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              _buildAttachmentPreview(p.imageUrl!),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentPreview(String url) {
    final isPdf = url.toLowerCase().endsWith('.pdf');
    final fileName = url.split(Platform.pathSeparator).last;

    if (isPdf) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _pal.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE11D48).withValues(alpha: 0.3), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: _pal.pick(Colors.black.withValues(alpha: 0.02), _pal.shadow),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _pal.tint(const Color(0xFFE11D48), const Color(0xFFFFE4E6)),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFE11D48), size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: _pal.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'PDF Document',
                    style: GoogleFonts.manrope(fontSize: 11.5, color: _pal.pick(const Color(0xFF64748B), _pal.textSecondary)),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE11D48),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => OpenFilex.open(url),
              child: Text(
                'Open',
                style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: _pal.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _pal.pick(const Color(0xFFF0F1F5), _pal.border), width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: url.startsWith('http')
          ? Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image)))
          : Image.file(File(url), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image))),
    );
  }

  Widget _buildMedicineCard(PrescriptionMedicineModel med) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _pal.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _pal.pick(const Color(0xFFF0F1F5), _pal.border), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _pal.pick(Colors.black.withValues(alpha: 0.02), _pal.shadow),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _pal.tint(const Color(0xFFFF3B5C), const Color(0xFFFFECEF)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.medication_outlined, color: Color(0xFFFF3B5C), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  med.name,
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _pal.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${med.dosage ?? "1 Tablet"} • ${med.mealInstruction ?? "After Meal"} • For ${med.days} days',
                  style: GoogleFonts.manrope(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _pal.pick(const Color(0xFF64748B), _pal.textSecondary),
                  ),
                ),
                if (med.times.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: med.times.map((t) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _pal.pick(const Color(0xFFF1F5F9), _pal.inputFill),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          t,
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _pal.pick(const Color(0xFF475569), _pal.textSecondary),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
