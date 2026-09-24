import 'package:flutter/material.dart';

import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/models/vitals_stream_model.dart';

/// Opens the HRV entry dialog.
///
/// With [item] it edits that reading in place; without it, it logs a new
/// reading (key 'hrv', value in ms) at the current time.
/// Resolves `true` when a reading was saved.
Future<bool?> showHrvEntryDialog(
  BuildContext context, {
  VitalsStreamResponse? item,
  int? initialMs,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => HrvEntryDialog(item: item, initialMs: initialMs),
  );
}

/// Sibling of the heart-rate entry dialog (ported from AlloConnect's
/// `EditHeartRateDialog`) for HRV; adds when [item] is null, edits otherwise.
class HrvEntryDialog extends StatefulWidget {
  final VitalsStreamResponse? item;
  final int? initialMs;
  final VoidCallback? onUpdate;

  const HrvEntryDialog({super.key, this.item, this.initialMs, this.onUpdate});

  @override
  State<HrvEntryDialog> createState() => _HrvEntryDialogState();
}

class _HrvEntryDialogState extends State<HrvEntryDialog> {
  late int _value;
  final HealthVitalsController _controller = HealthVitalsController.instance;
  bool _loading = false;

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    final latest = double.tryParse(_controller.hrvValue)?.round() ?? 0;
    final int seed =
        widget.item?.value.toInt() ??
        widget.initialMs ??
        (latest > 0 ? latest : 48);
    _value = seed.clamp(10, 250).toInt();
  }

  Future<void> _save() async {
    if (_value < 10 || _value > 250) return;

    setState(() => _loading = true);

    try {
      final VitalsStreamResponse? saved;
      final item = widget.item;
      if (item != null) {
        saved = await _controller.updateVitalEntry(
          vitalId: item.id,
          key: item.key,
          value: _value.toDouble(),
          unit: item.unit.isNotEmpty ? item.unit : 'ms',
          createdAt: item.createdAt,
          data: {...?item.data, 'hrv': _value},
        );
      } else {
        saved = await _controller.addHrvEntry(
          hrvMs: _value,
          createdAt: DateTime.now(),
        );
      }

      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      if (saved == null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              _controller.error.isEmpty
                  ? 'Unable to save HRV right now.'
                  : _controller.error,
            ),
          ),
        );
        return;
      }

      Navigator.pop(context, true);
      widget.onUpdate?.call();

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _isEdit ? 'Updated to $_value ms' : 'HRV saved: $_value ms',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _getStatus() {
    if (_value < 30) return "Low";
    if (_value < 50) return "Balanced";
    return "Good";
  }

  Color _getStatusColor() {
    if (_value < 30) return const Color(0xFFFFAB40);
    if (_value < 50) return const Color(0xFF7C4DFF);
    return const Color(0xFF00C896);
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// HEADER
            const Text(
              "Heart Rate Variability",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              _isEdit ? "Adjust your HRV" : "Enter your HRV",
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),

            const SizedBox(height: 24),

            /// VALUE DISPLAY
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.monitor_heart_rounded,
                    color: Color(0xFF7C4DFF),
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "$_value",
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text("ms", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 6),
                  Text(
                    _getStatus(),
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            /// SLIDER
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              ),
              child: Slider(
                value: _value.toDouble(),
                min: 10,
                max: 250,
                divisions: 240,
                activeColor: primary,
                onChanged: (v) => setState(() => _value = v.toInt()),
              ),
            ),

            /// RANGE LABELS
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("10", style: TextStyle(color: Colors.grey)),
                Text("250", style: TextStyle(color: Colors.grey)),
              ],
            ),

            const SizedBox(height: 12),

            /// INFO
            const Text(
              "Typical adult HRV: 30 - 100 ms (higher is better)",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),

            const SizedBox(height: 24),

            /// ACTIONS
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _loading ? null : () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text("Save"),
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
