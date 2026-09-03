import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/local_notification/models/local_reminder.dart';
import 'package:allomom/local_notification/controller/local_reminder_controller.dart';

class ReminderSetupBottomSheet extends StatefulWidget {
  final LocalReminderType type;

  const ReminderSetupBottomSheet({
    super.key,
    required this.type,
  });

  static Future<void> show(BuildContext context, LocalReminderType type) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReminderSetupBottomSheet(type: type),
    );
  }

  @override
  State<ReminderSetupBottomSheet> createState() => _ReminderSetupBottomSheetState();
}

class _ReminderSetupBottomSheetState extends State<ReminderSetupBottomSheet> {
  late LocalReminderConfig _config;

  final List<int> _intervalOptions = [30, 45, 60, 90, 120, 180, 240];

  @override
  void initState() {
    super.initState();
    _config = LocalReminderController.instance.getConfig(widget.type);
  }

  String _formatInterval(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) return 'Every $hours hr${hours > 1 ? "s" : ""}';
      return 'Every $hours hr $mins min';
    }
    return 'Every $minutes mins';
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _config.hour, minute: _config.minute),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF3B5C),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E2024),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _config = _config.copyWith(hour: picked.hour, minute: picked.minute);
      });
      await LocalReminderController.instance.updateTime(widget.type, picked.hour, picked.minute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.type.label,
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E2024),
                  ),
                ),
              ),
              Switch(
                value: _config.enabled,
                activeThumbColor: const Color(0xFFFF3B5C),
                onChanged: (val) async {
                  setState(() {
                    _config = _config.copyWith(enabled: val);
                  });
                  await LocalReminderController.instance.toggleReminder(widget.type, val);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.type.defaultMessage,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),

          if (widget.type.isIntervalBased) ...[
            Text(
              'Reminder Frequency',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E2024),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _intervalOptions.map((mins) {
                final isSelected = _config.intervalMinutes == mins;
                return ChoiceChip(
                  label: Text(_formatInterval(mins)),
                  selected: isSelected,
                  selectedColor: const Color(0xFFFF3B5C),
                  labelStyle: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                  ),
                  backgroundColor: const Color(0xFFF8FAFC),
                  onSelected: (sel) async {
                    if (sel) {
                      setState(() {
                        _config = _config.copyWith(intervalMinutes: mins);
                      });
                      await LocalReminderController.instance.updateInterval(widget.type, mins);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Text(
              'Active Hours: ${_config.formattedActiveHours}',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ] else ...[
            Text(
              'Reminder Time',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E2024),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickTime,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time_rounded, color: Color(0xFFFF3B5C), size: 22),
                        const SizedBox(width: 12),
                        Text(
                          _config.formattedTime,
                          style: GoogleFonts.manrope(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E2024),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Change',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFF3B5C),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF3B5C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                'Done',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
