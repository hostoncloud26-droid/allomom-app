import 'package:flutter/material.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/local_notification/controller/local_reminder_controller.dart';
import 'package:allomom/local_notification/ui/reminder_setup_bottom_sheet.dart';

class LocalRemindersSettingsPage extends StatelessWidget {
  const LocalRemindersSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.pick(const Color(0xFFFBFBFC), context.palette.scaffoldSoft),
      appBar: AppBar(
        backgroundColor: context.palette.pick(const Color(0xFFFBFBFC), context.palette.scaffoldSoft),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.palette.pick(const Color(0xFF2D3142), context.palette.textPrimary), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Health Reminders',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: context.palette.pick(const Color(0xFF1E2024), context.palette.textPrimary),
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: LocalReminderController.instance,
        builder: (context, _) {
          final configs = LocalReminderController.instance.configs;

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            physics: const BouncingScrollPhysics(),
            itemCount: configs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final config = configs[index];
              final isInterval = config.type.isIntervalBased;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: context.palette.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.palette.pick(const Color(0xFFF0F1F5), context.palette.border), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: context.palette.pick(
                        Colors.black.withValues(alpha: 0.02),
                        context.palette.shadow,
                      ),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            config.type.label,
                            style: GoogleFonts.manrope(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: context.palette.pick(const Color(0xFF1E2024), context.palette.textPrimary),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isInterval
                                ? '${config.formattedInterval} (${config.formattedActiveHours})'
                                : config.formattedTime,
                            style: GoogleFonts.manrope(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFF3B5C),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.tune_rounded, color: context.palette.pick(const Color(0xFF94A3B8), context.palette.textMuted), size: 20),
                      onPressed: () => ReminderSetupBottomSheet.show(context, config.type),
                    ),
                    Switch(
                      value: config.enabled,
                      activeThumbColor: const Color(0xFFFF3B5C),
                      onChanged: (val) {
                        LocalReminderController.instance.toggleReminder(config.type, val);
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
