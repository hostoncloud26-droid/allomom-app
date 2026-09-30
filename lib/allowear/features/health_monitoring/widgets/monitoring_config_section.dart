import 'package:allowear_sdk/allowear_sdk.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:allomom/allowear/allowear_controller.dart';
import 'package:allomom/allowear/allowear_colors.dart';
import 'package:allomom/allowear/features/health_monitoring/widgets/interval_picker.dart';
import 'package:allomom/allowear/features/health_monitoring/widgets/vital_schedule_card.dart';

/// Automatic (timed) measurement schedules for every vital the connected
/// model can schedule, plus a one-tap "apply to all".
/// Drop this into a [SliverToBoxAdapter] above the vitals cards.
class MonitoringConfigSection extends StatefulWidget {
  const MonitoringConfigSection({super.key});

  @override
  State<MonitoringConfigSection> createState() =>
      _MonitoringConfigSectionState();
}

class _MonitoringConfigSectionState extends State<MonitoringConfigSection>
    with SingleTickerProviderStateMixin {
  bool _expanded = true;
  int _allInterval = 60;

  late AnimationController _rotateAnim;
  late Animation<double> _rotateTurn;

  @override
  void initState() {
    super.initState();
    _rotateAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      value: 1.0, // starts expanded
    );
    _rotateTurn = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _rotateAnim, curve: Curves.easeInOut),
    );
    // Show what is on the device now, not what was read at connect time.
    allowear.fetchAllConfigs();
  }

  @override
  void dispose() {
    _rotateAnim.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() => _expanded = !_expanded);
    _expanded ? _rotateAnim.forward() : _rotateAnim.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = getPrimaryColor(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header with collapse toggle ───────────────────────
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleExpanded,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Row(
              children: [
                // Icon badge
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    color: primaryColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),

                // Label
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Monitoring Configuration',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Black800,
                        ),
                      ),
                      Text(
                        'Automatic measurement schedules',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),

                // Animated chevron
                RotationTransition(
                  turns: _rotateTurn,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: isDark ? Colors.white38 : Colors.black38,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Config tiles (animated collapse) ─────────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          child: _expanded
              ? Obx(() {
                  final caps = allowear.capabilities;
                  if (caps == null) return const SizedBox.shrink();
                  final vitals = VitalType.values
                      .where(caps.supportsAutoConfig)
                      .toList();
                  return Column(
                    children: [
                      const SizedBox(height: 4),
                      _buildApplyAll(context, caps, isDark, primaryColor),
                      for (final type in vitals) VitalScheduleCard(type: type),
                      const SizedBox(height: 8),
                    ],
                  );
                })
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  /// One interval for every vital, round the clock.
  Widget _buildApplyAll(BuildContext context, DeviceCapabilities caps,
      bool isDark, Color primaryColor) {
    final connected = allowear.connectedDevice.value != null;
    final busy = allowear.savingSchedules.isNotEmpty ||
        allowear.isLoadingSchedules.value;
    final fixed = caps.fixedAutoIntervals.entries
        .where((e) => caps.supportsAutoConfig(e.key))
        .toList();
    final muted = isDark ? Colors.white38 : Colors.black38;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: primaryColor.withOpacity(isDark ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'All vitals',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Black800,
                ),
              ),
              const Spacer(),
              if (allowear.isLoadingSchedules.value)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: primaryColor),
                )
              else
                InkWell(
                  onTap: connected && !busy ? allowear.fetchAllConfigs : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.refresh_rounded,
                        size: 18, color: connected ? primaryColor : muted),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Measure every supported vital around the clock at one interval.',
            style: TextStyle(fontSize: 11, color: muted),
          ),
          if (fixed.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '${fixed.map((e) => VitalScheduleStyle.of(e.key).label).join(', ')} '
              'always measure every ${fixed.first.value} min on this device.',
              style: TextStyle(fontSize: 11, color: muted),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              IntervalPicker(
                minutes: _allInterval,
                accentColor: primaryColor,
                onChanged: connected && !busy
                    ? (minutes) => setState(() => _allInterval = minutes)
                    : null,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: connected && !busy
                    ? () => allowear.applyScheduleToAll(_allInterval)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Apply to all',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
