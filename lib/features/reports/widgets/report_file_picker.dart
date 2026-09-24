import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import 'package:allomom/config/app_theme.dart';

/// The content type a report file is stored and uploaded as.
///
/// A concrete type, never `image/*`: this is what the view screen renders
/// from and what the upload declares to Drive, and a wildcard is neither a
/// valid media type nor something a viewer can act on.
String reportMimeTypeFor(String path) {
  switch (path.toLowerCase().split('.').last) {
    case 'pdf':
      return 'application/pdf';
    case 'png':
      return 'image/png';
    case 'webp':
      return 'image/webp';
    case 'heic':
      return 'image/heic';
    case 'jpg':
    case 'jpeg':
      return 'image/jpeg';
    default:
      return 'application/octet-stream';
  }
}

enum _ReportFileSource { camera, gallery, files }

/// Asks where the report files come from — Camera, Gallery or Files — and
/// returns what was picked. Empty when the user backs out at any point.
Future<List<File>> pickReportFiles(BuildContext context) async {
  final source = await showModalBottomSheet<_ReportFileSource>(
    context: context,
    backgroundColor: context.palette.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _ReportFileSourceSheet(),
  );
  if (source == null || !context.mounted) return const [];

  try {
    switch (source) {
      case _ReportFileSource.camera:
        final picked = await ImagePicker()
            .pickImage(source: ImageSource.camera, imageQuality: 85);
        return picked == null ? const [] : [File(picked.path)];
      case _ReportFileSource.gallery:
        final picked = await ImagePicker().pickMultiImage(imageQuality: 85);
        return picked.map((item) => File(item.path)).toList();
      case _ReportFileSource.files:
        final result = await FilePicker.pickFiles(
          allowMultiple: true,
          type: FileType.custom,
          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        );
        return (result?.files ?? const <PlatformFile>[])
            .where((f) => f.path != null)
            .map((f) => File(f.path!))
            .toList();
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting files: $e')),
      );
    }
    return const [];
  }
}

class _ReportFileSourceSheet extends StatelessWidget {
  const _ReportFileSourceSheet();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: p.pick(const Color(0xFFE2E8F0), p.divider),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Upload Report Files',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: p.pick(const Color(0xFF1E2024), p.textPrimary),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose photos or PDF documents',
              style: GoogleFonts.manrope(
                fontSize: 12.5,
                color: p.pick(const Color(0xFF94A3B8), p.textMuted),
              ),
            ),
            const SizedBox(height: 24),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _SourceButton(
                  source: _ReportFileSource.camera,
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  sublabel: 'Take photo',
                  color: Color(0xFFFF3B5C),
                ),
                _SourceButton(
                  source: _ReportFileSource.gallery,
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  sublabel: 'Multi images',
                  color: Color(0xFF8B5CF6),
                ),
                _SourceButton(
                  source: _ReportFileSource.files,
                  icon: Icons.folder_open_rounded,
                  label: 'Files',
                  sublabel: 'Images & PDFs',
                  color: Color(0xFF3898EC),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  final _ReportFileSource source;
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;

  const _SourceButton({
    required this.source,
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: () => Navigator.pop(context, source),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              color: p.pick(const Color(0xFF1E2024), p.textPrimary),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sublabel,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w500,
              fontSize: 11,
              color: p.pick(const Color(0xFF94A3B8), p.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
