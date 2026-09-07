import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/services/report_db_service.dart';
import 'package:drift/drift.dart' as drift;

class EditReport extends StatefulWidget {
  final Map<String, dynamic> reportDetails;

  const EditReport({super.key, required this.reportDetails});

  @override
  State<EditReport> createState() => _EditReportState();
}

class _EditReportState extends State<EditReport> {
  late String? reportType;
  late TextEditingController descriptionController;
  bool isSaving = false;

  final List<String> reportTypes = [
    'ECG',
    'Blood Test',
    'HCG',
    'Lab Test',
    'x-ray',
    'Ultrasound Scan',
    'CT Scan',
    'Mammogram',
    'MRI',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    reportType = widget.reportDetails['report_type']?.toString();
    descriptionController = TextEditingController(text: widget.reportDetails['description']?.toString() ?? '');
  }

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveReport() async {
    final reportId = widget.reportDetails['id']?.toString() ?? '';
    if (reportId.isEmpty) return;

    setState(() => isSaving = true);
    try {
      // Local-only: written straight to SQLite with synced = 0.
      final rRow = ReportsCompanion(
        id: drift.Value(reportId),
        reportType: drift.Value(reportType ?? 'Report'),
        description: drift.Value(descriptionController.text.trim()),
        imageUrl: widget.reportDetails['imageUrl'] != null ? drift.Value(widget.reportDetails['imageUrl'].toString()) : const drift.Value.absent(),
        detail: widget.reportDetails['detail'] != null
            ? drift.Value(widget.reportDetails['detail'] is String
                ? widget.reportDetails['detail']
                : jsonEncode(widget.reportDetails['detail']))
            : const drift.Value.absent(),
      );
      await ReportDbService.instance.updateReport(rRow);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report updated successfully! ✨'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating report: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFC),
      appBar: AppBar(
        title: Text(
          'Edit Report',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: const Color(0xFF1E2024),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E2024), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report Type',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF0F1F5), width: 1.2),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: reportType,
                  hint: Text('Select Type', style: GoogleFonts.manrope(color: const Color(0xFF94A3B8))),
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  items: reportTypes.map((t) {
                    return DropdownMenuItem<String>(
                      value: t,
                      child: Text(t, style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => reportType = val),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Description / Notes',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF0F1F5), width: 1.2),
              ),
              child: TextFormField(
                controller: descriptionController,
                maxLines: 5,
                style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF1E2024)),
                decoration: InputDecoration(
                  hintText: 'Enter clinical description...',
                  hintStyle: GoogleFonts.manrope(color: const Color(0xFF94A3B8)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF3B5C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 0,
                ),
                onPressed: isSaving ? null : _saveReport,
                child: isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'SAVE CHANGES',
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
