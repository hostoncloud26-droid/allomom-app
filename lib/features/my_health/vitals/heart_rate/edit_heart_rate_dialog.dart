import 'package:flutter/material.dart';

import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/models/vitals_stream_model.dart';

/// Opens the heart-rate entry dialog.
///
/// With [item] it edits that reading in place; without it, it logs a new
/// reading at the current time (AlloConnect's manual add, minus the camera).
/// Resolves `true` when a reading was saved.
Future<bool?> showHeartRateEntryDialog(
  BuildContext context, {
  VitalsStreamResponse? item,
  int? initialBpm,
}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => EditHeartRateDialog(item: item, initialBpm: initialBpm),
  );
}

/// Ported from AlloConnect's `EditHeartRateDialog`; also serves as the add
/// dialog when [item] is null.
class EditHeartRateDialog extends StatefulWidget {
  final VitalsStreamResponse? item;
  final int? initialBpm;
  final VoidCallback? onUpdate;

  const EditHeartRateDialog({
    super.key,
    this.item,
    this.initialBpm,
    this.onUpdate,
  });

  @override
  State<EditHeartRateDialog> createState() => _EditHeartRateDialogState();
}

class _EditHeartRateDialogState extends State<EditHeartRateDialog> {
  late int _value;
  final HealthVitalsController _controller = HealthVitalsController.instance;
  bool _loading = false;

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    final latest = double.tryParse(_controller.heartRateValue)?.round() ?? 0;
    final int seed =
        widget.item?.value.toInt() ??
        widget.initialBpm ??
        (latest > 0 ? latest : 75);
    _value = seed.clamp(30, 200).toInt();
  }

  Future<void> _save() async {
    if (_value < 30 || _value > 200) return;

    setState(() => _loading = true);

    try {
      final VitalsStreamResponse? saved;
      final item = widget.item;
      if (item != null) {
        saved = await _controller.updateVitalEntry(
          vitalId: item.id,
          key: item.key,
          value: _value.toDouble(),
          unit: item.unit.isNotEmpty ? item.unit : 'bpm',
          createdAt: item.createdAt,
          data: {...?item.data, 'heartRate': _value},
        );
      } else {
        saved = await _controller.addHeartRateEntry(
          bpm: _value,
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
                  ? 'Unable to save heart rate right now.'
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
            _isEdit
                ? 'Updated to $_value BPM'
                : 'Heart rate saved: $_value BPM',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _getStatus() {
    if (_value < 60) return "Low";
    if (_value <= 100) return "Normal";
    return "High";
  }

  Color _getStatusColor() {
    if (_value < 60) return Colors.orange;
    if (_value <= 100) return Colors.green;
    return Colors.red;
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
              "Heart Rate",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              _isEdit ? "Adjust your BPM" : "Enter your BPM",
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
                  const Icon(Icons.favorite, color: Colors.red, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    "$_value",
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text("BPM", style: TextStyle(color: Colors.grey)),
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
                min: 30,
                max: 200,
                divisions: 170,
                activeColor: primary,
                onChanged: (v) => setState(() => _value = v.toInt()),
              ),
            ),

            /// RANGE LABELS
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("30", style: TextStyle(color: Colors.grey)),
                Text("200", style: TextStyle(color: Colors.grey)),
              ],
            ),

            const SizedBox(height: 12),

            /// INFO
            const Text(
              "Normal resting: 60 - 100 BPM",
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
