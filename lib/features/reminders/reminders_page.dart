import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/services/sq_lite/services/reminder_db_service.dart';
import 'package:allomom/local_notification/models/local_reminder.dart';
import 'package:allomom/local_notification/controller/local_reminder_controller.dart';
import 'package:allomom/local_notification/ui/reminder_setup_bottom_sheet.dart';
import 'package:allomom/repositories/user_session_manager.dart';

class ReminderItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final LocalReminderType? localType;
  bool isEnabled;
  final String frequency;

  ReminderItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.localType,
    this.isEnabled = true,
    this.frequency = 'Daily',
  });
}

class RemindersPage extends StatefulWidget {
  final String? userId;

  const RemindersPage({
    super.key,
    this.userId,
  });

  @override
  State<RemindersPage> createState() => _RemindersPageState();
}

typedef ManageRemindersScreen = RemindersPage;

class _RemindersPageState extends State<RemindersPage> {
  final List<ReminderItem> _pregnancyReminders = [
    ReminderItem(
      id: 'r_water',
      title: 'Water Hydration',
      subtitle: 'Every 2 hours • 8 to 10 glasses daily',
      icon: Icons.water_drop_rounded,
      iconColor: const Color(0xFF0284C7),
      iconBg: const Color(0xFFE0F2FE),
      localType: LocalReminderType.drinkWater,
      isEnabled: true,
      frequency: 'Every 2 hrs',
    ),
    ReminderItem(
      id: 'r_med',
      title: 'Medication & Supplements',
      subtitle: 'Iron, Calcium, Folic Acid & Vitamin D',
      icon: Icons.medication_rounded,
      iconColor: const Color(0xFFFF3B5C),
      iconBg: const Color(0xFFFFECEF),
      localType: LocalReminderType.medicineReminder,
      isEnabled: true,
      frequency: '8:00 AM & 9:00 PM',
    ),
    ReminderItem(
      id: 'r_sleep',
      title: 'Pregnancy Sleep & Wind Down',
      subtitle: 'Consistent rest for maternal well-being',
      icon: Icons.bedtime_rounded,
      iconColor: const Color(0xFF6366F1),
      iconBg: const Color(0xFFEEF2FF),
      localType: LocalReminderType.sleepReminder,
      isEnabled: true,
      frequency: '10:00 PM',
    ),
    ReminderItem(
      id: 'r_wake',
      title: 'Morning Wake-Up',
      subtitle: 'Gentle wake-up and hydration reminder',
      icon: Icons.wb_sunny_rounded,
      iconColor: const Color(0xFFF59E0B),
      iconBg: const Color(0xFFFEF3C7),
      localType: LocalReminderType.wakeUpReminder,
      isEnabled: true,
      frequency: '6:30 AM',
    ),
    ReminderItem(
      id: 'r_breakfast',
      title: 'Nutritious Breakfast',
      subtitle: 'Healthy morning fuel for baby growth',
      icon: Icons.egg_alt_rounded,
      iconColor: const Color(0xFFFF9800),
      iconBg: const Color(0xFFFFF7ED),
      localType: LocalReminderType.breakfast,
      isEnabled: true,
      frequency: '8:00 AM',
    ),
    ReminderItem(
      id: 'r_lunch',
      title: 'Wholesome Lunch',
      subtitle: 'Proteins, greens, and complex grains',
      icon: Icons.lunch_dining_rounded,
      iconColor: const Color(0xFF10B981),
      iconBg: const Color(0xFFECFDF5),
      localType: LocalReminderType.lunch,
      isEnabled: true,
      frequency: '1:00 PM',
    ),
    ReminderItem(
      id: 'r_dinner',
      title: 'Light & Healthy Dinner',
      subtitle: 'Digestive-friendly evening dinner',
      icon: Icons.dinner_dining_rounded,
      iconColor: const Color(0xFF8B5CF6),
      iconBg: const Color(0xFFF3E8FF),
      localType: LocalReminderType.dinner,
      isEnabled: true,
      frequency: '7:30 PM',
    ),
    ReminderItem(
      id: 'r_yoga',
      title: 'Prenatal Yoga & Pelvic Stretches',
      subtitle: 'Gentle mobility and breathing exercises',
      icon: Icons.self_improvement_rounded,
      iconColor: const Color(0xFFEC4899),
      iconBg: const Color(0xFFFDF2F8),
      localType: LocalReminderType.morningExercise,
      isEnabled: false,
      frequency: '7:00 AM',
    ),
    ReminderItem(
      id: 'r_walk',
      title: 'Evening Gentle Walk',
      subtitle: 'Promotes circulation and baby positioning',
      icon: Icons.directions_walk_rounded,
      iconColor: const Color(0xFF14B8A6),
      iconBg: const Color(0xFFCCFBF1),
      localType: LocalReminderType.eveningExercise,
      isEnabled: true,
      frequency: '5:30 PM',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _syncWithLocalController();
    _loadCustomReminders();
  }

  void _syncWithLocalController() {
    final ctrl = LocalReminderController.instance;
    for (final item in _pregnancyReminders) {
      if (item.localType != null) {
        item.isEnabled = ctrl.isEnabled(item.localType!);
      }
    }
  }

  /// Loads the user's saved custom reminders from the local Drift database
  /// and appends them to the built-in pregnancy reminder list.
  Future<void> _loadCustomReminders() async {
    try {
      final targetUserId = widget.userId ?? UserSessionManager.instance.userId;
      if (targetUserId.isEmpty) return;

      final saved = await ReminderDbService.instance.getReminders(targetUserId);
      if (!mounted || saved.isEmpty) return;

      setState(() {
        for (final r in saved) {
          if (_pregnancyReminders.any((item) => item.id == r.id)) continue;
          _pregnancyReminders.add(
            ReminderItem(
              id: r.id,
              title: r.title,
              subtitle: 'Custom daily health reminder',
              icon: Icons.alarm_rounded,
              iconColor: const Color(0xFFFF3B5C),
              iconBg: const Color(0xFFFFECEF),
              isEnabled: r.enabled,
              frequency: _formatReminderTime(r.hour, r.minute) ?? r.frequency,
            ),
          );
        }
      });
    } catch (e) {
      debugPrint('Error loading reminders from local database: $e');
    }
  }

  static String? _formatReminderTime(int? hour, int? minute) {
    if (hour == null || minute == null) return null;
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  void _showAddCustomReminderDialog() {
    final nameCtrl = TextEditingController();
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
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

                  Text(
                    'Add Custom Reminder',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E2024),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Reminder Name',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. Fetal Kick Counting, Doctor Appointment',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Time',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showTimePicker(context: context, initialTime: selectedTime);
                      if (picked != null) {
                        setModalState(() => selectedTime = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded, color: Color(0xFFFF3B5C), size: 20),
                              const SizedBox(width: 10),
                              Text(
                                selectedTime.format(context),
                                style: GoogleFonts.manrope(
                                  fontSize: 15,
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
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        final text = nameCtrl.text.trim();
                        if (text.isEmpty) return;

                        final timeLabel = selectedTime.format(context);

                        // Local-only: saved to SQLite with synced = 0.
                        String reminderId =
                            'custom_${DateTime.now().millisecondsSinceEpoch}';
                        try {
                          final targetUserId = widget.userId ??
                              UserSessionManager.instance.userId;
                          if (targetUserId.isNotEmpty) {
                            reminderId = await ReminderDbService.instance
                                .createReminder(
                              userId: targetUserId,
                              title: text,
                              reminderType: 'custom',
                              frequency: 'Daily',
                              hour: selectedTime.hour,
                              minute: selectedTime.minute,
                            );
                          }
                        } catch (e) {
                          debugPrint('Error saving custom reminder: $e');
                        }

                        if (mounted) {
                          setState(() {
                            _pregnancyReminders.add(
                              ReminderItem(
                                id: reminderId,
                                title: text,
                                subtitle: 'Custom daily health reminder',
                                icon: Icons.alarm_rounded,
                                iconColor: const Color(0xFFFF3B5C),
                                iconBg: const Color(0xFFFFECEF),
                                isEnabled: true,
                                frequency: timeLabel,
                              ),
                            );
                          });
                        }

                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF3B5C),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text(
                        'Save Reminder',
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
          },
        );
      },
    );
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
          'Manage Reminders',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E2024),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Color(0xFFFF3B5C), size: 26),
            tooltip: 'Add Custom Reminder',
            onPressed: _showAddCustomReminderDialog,
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: LocalReminderController.instance,
        builder: (context, _) {
          _syncWithLocalController();

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            physics: const BouncingScrollPhysics(),
            itemCount: _pregnancyReminders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final r = _pregnancyReminders[index];
              final config = r.localType != null ? LocalReminderController.instance.getConfig(r.localType!) : null;
              final timeLabel = config != null
                  ? (config.type.isIntervalBased ? config.formattedInterval : config.formattedTime)
                  : r.frequency;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFF0F1F5), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: r.iconBg,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(r.icon, color: r.iconColor, size: 22),
                      ),
                    ),
                    const SizedBox(width: 14),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r.title,
                            style: GoogleFonts.manrope(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E2024),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            r.subtitle,
                            style: GoogleFonts.manrope(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timeLabel,
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFF3B5C),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (r.localType != null)
                      IconButton(
                        icon: const Icon(Icons.tune_rounded, color: Color(0xFF94A3B8), size: 19),
                        onPressed: () => ReminderSetupBottomSheet.show(context, r.localType!),
                      ),

                    Switch(
                      value: r.isEnabled,
                      activeThumbColor: const Color(0xFFFF3B5C),
                      onChanged: (val) async {
                        setState(() => r.isEnabled = val);
                        if (r.localType != null) {
                          await LocalReminderController.instance.toggleReminder(r.localType!, val);
                        } else {
                          // Custom reminder: persist the toggle locally.
                          try {
                            await ReminderDbService.instance
                                .setEnabled(r.id, val);
                          } catch (e) {
                            debugPrint(
                                'Error updating reminder ${r.id}: $e');
                          }
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
