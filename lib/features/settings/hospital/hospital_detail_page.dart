import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:allomom/api/hospital_api.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/config/colors.dart';
import 'package:allomom/models/my_hospital.dart';

/// Asks before removing [hospital], then removes it. Returns true once it was
/// removed.
Future<bool> removeHospitalWithConfirm(
  BuildContext context,
  MyHospital hospital,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Remove ${hospital.name}?',
        style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
      ),
      content: const Text(
        'It will be removed from your hospitals. This cannot be undone.',
        style: TextStyle(fontSize: 13.5, height: 1.45),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: TextButton.styleFrom(foregroundColor: dangerRed),
          child: const Text('Remove'),
        ),
      ],
    ),
  );
  if (confirmed != true) return false;

  final res = await HospitalApi.removeHospital(hospital.userEntityId);
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(res.success ? 'Hospital removed' : res.detail),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  return res.success;
}

/// Details of a hospital the mother added. Pops `true` if she removed it.
class HospitalDetailPage extends StatelessWidget {
  final MyHospital hospital;

  const HospitalDetailPage({super.key, required this.hospital});

  static final _dateFmt = DateFormat('dd MMM yyyy');

  @override
  Widget build(BuildContext context) {
    final ink = context.palette.textPrimary;
    final inkSoft = context.palette.textSecondary;
    final added = hospital.addedAt?.toLocal();
    final left = hospital.leftAt?.toLocal();

    return Scaffold(
      backgroundColor: context.palette.scaffoldSoft,
      appBar: AppBar(
        backgroundColor: context.palette.scaffoldSoft,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: ink, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Hospital Details',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: ink,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _card(
            context,
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: context.palette.tint(primaryColor, accentLight),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    color: primaryColor,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  hospital.name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
                if (hospital.category?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    hospital.category!,
                    style: GoogleFonts.poppins(fontSize: 12.5, color: inkSoft),
                  ),
                ],
                if (hospital.rating != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: warningAmber,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${hospital.rating!.toStringAsFixed(1)}'
                        '${hospital.ratingCount != null ? ' (${hospital.ratingCount} reviews)' : ''}',
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          color: inkSoft,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                _statusChip(context, left),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _card(
            context,
            child: Column(
              children: [
                if (hospital.address?.isNotEmpty == true)
                  _infoRow(
                    context,
                    Icons.location_on_outlined,
                    'Address',
                    hospital.address!,
                  ),
                if (hospital.contact?.isNotEmpty == true)
                  _infoRow(
                    context,
                    Icons.call_outlined,
                    'Phone',
                    hospital.contact!,
                  ),
                if (hospital.website?.isNotEmpty == true)
                  _infoRow(
                    context,
                    Icons.language_rounded,
                    'Website',
                    hospital.website!,
                  ),
                if (hospital.mapsUrl?.isNotEmpty == true)
                  _infoRow(
                    context,
                    Icons.map_outlined,
                    'Google Maps',
                    hospital.mapsUrl!,
                  ),
                if (added != null)
                  _infoRow(
                    context,
                    Icons.event_available_outlined,
                    'Added on',
                    _dateFmt.format(added),
                    copyable: false,
                  ),
                if (left != null)
                  _infoRow(
                    context,
                    Icons.event_busy_outlined,
                    'Left on',
                    _dateFmt.format(left),
                    copyable: false,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () async {
                if (await removeHospitalWithConfirm(context, hospital) &&
                    context.mounted) {
                  Navigator.pop(context, true);
                }
              },
              icon: const Icon(Icons.delete_outline_rounded),
              label: Text(
                'Remove hospital',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: dangerRed,
                side: const BorderSide(color: dangerRed),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.palette.divider),
      ),
      child: child,
    );
  }

  /// Tapping a copyable row copies its value, since the app has no way to
  /// open links or dial.
  Widget _infoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    bool copyable = true,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: copyable
          ? () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label copied'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: context.palette.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      color: context.palette.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            if (copyable)
              Icon(
                Icons.copy_rounded,
                size: 16,
                color: context.palette.textMuted,
              ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(BuildContext context, DateTime? left) {
    final isCurrent = left == null;
    final color = isCurrent ? successGreen : context.palette.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.palette.tint(color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isCurrent ? 'Current hospital' : 'Left on ${_dateFmt.format(left)}',
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
