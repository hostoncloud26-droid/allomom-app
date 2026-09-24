import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/services/sq_lite/services/reminder_db_service.dart';
import 'package:allomom/local_notification/models/local_reminder.dart';
import 'package:allomom/local_notification/controller/local_reminder_controller.dart';
import 'package:allomom/local_notification/ui/reminder_setup_bottom_sheet.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/features/background_audio/widgets/baby_narration.dart';

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
  AppPalette get _p => context.palette;

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
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => speak(NarrationKeys.pgRemindersOpen),
    );
  }

  /// The line for turning [type] on, and the one confirming it.
  ///
  /// Water, medicine, meals and sleep each have their own pair; the rest of
  /// the list shares the plain "your reminder is set" confirmation and gets no
  /// explanation, because none was recorded for them.
  static ({String? explain, String confirm}) _narrationFor(
    LocalReminderType? type,
  ) {
    switch (type) {
      case LocalReminderType.drinkWater:
        return (
          explain: NarrationKeys.pgRemindersWater,
          confirm: NarrationKeys.pgConfReminderWater,
        );
      case LocalReminderType.medicineReminder:
        return (
          explain: NarrationKeys.pgRemindersMedicine,
          confirm: NarrationKeys.pgConfReminderMedicine,
        );
      case LocalReminderType.sleepReminder:
        return (explain: null, confirm: NarrationKeys.pgConfReminderSleep);
      case LocalReminderType.breakfast:
      case LocalReminderType.lunch:
      case LocalReminderType.dinner:
        return (explain: null, confirm: NarrationKeys.pgConfReminderMeal);
      default:
        return (explain: null, confirm: NarrationKeys.pgConfReminderSet);
    }
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
      final targetUserId = widget.userId ?? MainController.instance.userId;
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

  /// Removes one of her own reminders, after asking.
  Future<void> _deleteCustomReminder(ReminderItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Remove reminder?',
          style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
        ),
        content: Text(
          '"${item.title}" will stop reminding you.',
          style: GoogleFonts.manrope(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ReminderDbService.instance.deleteReminder(item.id);
    } catch (e) {
      debugPrint('Error deleting reminder ${item.id}: $e');
    }

    if (!mounted) return;
    setState(() => _pregnancyReminders.removeWhere((r) => r.id == item.id));
    speak(NarrationKeys.pgConfReminderDeleted, force: true);
  }

  static String? _formatReminderTime(int? hour, int? minute) {
    if (hour == null || minute == null) return null;
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  void _showAddCustomReminderDialog() {
    speak(NarrationKeys.pgRemindersAdd, force: true);
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
              decoration: BoxDecoration(
                color: _p.card,
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
                        color: _p.pick(const Color(0xFFE2E8F0), _p.divider),
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
                      color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Reminder Name',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _p.pick(const Color(0xFF475569), _p.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    style: TextStyle(color: _p.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'e.g. Fetal Kick Counting, Doctor Appointment',
                      filled: true,
                      fillColor: _p.pick(const Color(0xFFF8FAFC), _p.inputFill),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: _p.pick(const Color(0xFFE2E8F0), _p.border)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: _p.pick(const Color(0xFFE2E8F0), _p.border)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Time',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _p.pick(const Color(0xFF475569), _p.textSecondary),
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
                        color: _p.pick(const Color(0xFFF8FAFC), _p.inputFill),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _p.pick(const Color(0xFFE2E8F0), _p.border)),
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
                                  color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
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
                              MainController.instance.userId;
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

                        speak(NarrationKeys.pgConfReminderSet, force: true);
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
      backgroundColor: _p.scaffoldSoft,
      appBar: AppBar(
        backgroundColor: _p.scaffoldSoft,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: _p.pick(const Color(0xFF2D3142), _p.textPrimary), size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Manage Reminders',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
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
                  color: _p.card,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _p.pick(const Color(0xFFF0F1F5), _p.border), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: _p.pick(Colors.black.withValues(alpha: 0.02), _p.shadow),
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
                        color: _p.tint(r.iconColor, r.iconBg),
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
                              color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            r.subtitle,
                            style: GoogleFonts.manrope(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: _p.pick(const Color(0xFF64748B), _p.textSecondary),
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
                        icon: Icon(Icons.tune_rounded, color: _p.pick(const Color(0xFF94A3B8), _p.textMuted), size: 19),
                        onPressed: () {
                          final explain = _narrationFor(r.localType).explain;
                          if (explain != null) speak(explain);
                          ReminderSetupBottomSheet.show(context, r.localType!);
                        },
                      )
                    else
                      // Only her own reminders can go. The built-in pregnancy
                      // ones are switched off, not deleted — there would be no
                      // way to get them back.
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: _p.pick(const Color(0xFF94A3B8), _p.textMuted),
                          size: 19,
                        ),
                        onPressed: () => _deleteCustomReminder(r),
                      ),

                    Switch(
                      value: r.isEnabled,
                      activeThumbColor: const Color(0xFFFF3B5C),
                      onChanged: (val) async {
                        setState(() => r.isEnabled = val);

                        final lines = _narrationFor(r.localType);
                        speak(
                          val ? lines.confirm : NarrationKeys.pgConfReminderOff,
                          force: true,
                        );

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
