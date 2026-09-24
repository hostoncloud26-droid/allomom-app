import 'package:flutter/material.dart';

import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/models/vitals_stream_model.dart';
import 'package:allomom/services/sq_lite/services/vitals_sqlite_service.dart';

/// AlloConnect's drink type ('tea', 'coffee', 'beverages') for a `drinks` row
/// or a name such as 'Tea' / 'Coffee' / 'Other'.
String drinkTypeOf({Map<String, dynamic>? data, String? name}) {
  String? norm(dynamic raw) {
    final s = raw?.toString().trim().toLowerCase();
    if (s == null || s.isEmpty) return null;
    if (s.contains('tea') || s.contains('chai')) return 'tea';
    if (s.contains('coffee')) return 'coffee';
    if (s == 'other' || s == 'beverages' || s == 'beverage') {
      return 'beverages';
    }
    return null;
  }

  return norm(name) ??
      norm(data?['drink_type']) ??
      norm(data?['drink']) ??
      norm(data?['type']) ??
      'beverages';
}

/// Allomom's drink name for an AlloConnect drink type.
String drinkNameOf(String type) => switch (type) {
  'tea' => 'Tea',
  'coffee' => 'Coffee',
  _ => 'Other',
};

/// Opens AlloConnect's Hot & Cold Drinks sheet. [initialType] takes 'tea',
/// 'coffee', 'beverages' or Allomom's 'Tea' / 'Coffee' / 'Other';
/// [initialTemp] is 'hot' or 'cold'. Pass [vital] to edit an existing
/// `drinks` row. Resolves to true when something was saved.
Future<bool?> showDrinksEntrySheet(
  BuildContext context, {
  VitalsStreamResponse? vital,
  String? userId,
  String? initialTemp,
  String? initialType,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DrinksEntryBottomSheet(
      userId: userId,
      vital: vital,
      initialTemp: initialTemp,
      initialType: initialType,
    ),
  );
}

class DrinksEntryBottomSheet extends StatefulWidget {
  final String? userId;
  final VitalsStreamResponse? vital;
  final String? initialTemp;
  final String? initialType;

  const DrinksEntryBottomSheet({
    super.key,
    this.userId,
    this.vital,
    this.initialTemp,
    this.initialType,
  });

  @override
  State<DrinksEntryBottomSheet> createState() => _DrinksEntryBottomSheetState();
}

class _DrinksEntryBottomSheetState extends State<DrinksEntryBottomSheet> {
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedTemp = 'hot'; // 'hot', 'cold'
  String _selectedType = 'tea'; // 'tea', 'coffee', 'beverages'
  int _selectedPreset = 60;
  bool _saving = false;

  // Presets based on (temperature, type)
  final Map<String, Map<String, List<int>>> _temperaturePresets = {
    'hot': {
      'tea': [30, 60, 90],
      'coffee': [40, 90, 150],
      'beverages': [50, 80, 120], // representing Other Hot
    },
    'cold': {
      'coffee': [80, 120, 180],
      'beverages': [100, 150, 220], // representing Other Cold
    },
  };

  final Map<String, Map<String, String>> _defaultDetails = {
    'hot': {'tea': 'Hot Tea', 'coffee': 'Hot Coffee', 'beverages': 'Hot Drink'},
    'cold': {'coffee': 'Cold Coffee', 'beverages': 'Cold Drink'},
  };

  @override
  void initState() {
    super.initState();

    final vital = widget.vital;
    if (vital != null) {
      final val = vital.value.toInt();
      _caloriesController.text = val.toString();
      final detailsText = vital.data?['details']?.toString() ?? '';
      _detailsController.text = detailsText;
      _selectedType = drinkTypeOf(data: vital.data);

      // Temperature as recorded, else guessed from details or calorie values.
      final recordedTemp = vital.data?['temperature']?.toString();
      if (recordedTemp == 'hot' || recordedTemp == 'cold') {
        _selectedTemp = recordedTemp!;
      } else if (detailsText.toLowerCase().contains('cold') ||
          (_selectedType == 'beverages' && val >= 100) ||
          (_selectedType == 'coffee' &&
              val >= 80 &&
              !detailsText.toLowerCase().contains('hot'))) {
        _selectedTemp = 'cold';
      } else {
        _selectedTemp = 'hot';
      }

      // Tea isn't a cold option.
      if (_selectedTemp == 'cold' && _selectedType == 'tea') {
        _selectedType = 'coffee';
      }

      final presetsForType =
          _temperaturePresets[_selectedTemp]?[_selectedType] ?? [];
      _selectedPreset = presetsForType.contains(val) ? val : -1; // custom
    } else {
      // Default state: check initial parameters, fallback to Hot Tea
      _selectedTemp = widget.initialTemp == 'cold' ? 'cold' : 'hot';
      _selectedType = widget.initialType == null
          ? 'tea'
          : drinkTypeOf(name: widget.initialType);
      if (_selectedTemp == 'cold' && _selectedType == 'tea') {
        _selectedType = 'coffee';
      }

      final presetsForType =
          _temperaturePresets[_selectedTemp]?[_selectedType] ?? [30, 60, 90];
      _selectedPreset = presetsForType.isNotEmpty ? presetsForType[1] : 60;
      _caloriesController.text = _selectedPreset.toString();
      if (_selectedType == 'beverages') {
        _detailsController.text = '';
      } else {
        _detailsController.text =
            _defaultDetails[_selectedTemp]?[_selectedType] ?? '';
      }
    }
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(message)));
  }

  void _onTempSelected(String temp) {
    setState(() {
      _selectedTemp = temp;
      if (temp == 'cold' && _selectedType == 'tea') {
        _selectedType = 'coffee';
      }
      _updatePresetsAndDetails();
    });
  }

  void _onTypeSelected(String type) {
    setState(() {
      _selectedType = type;
      _updatePresetsAndDetails();
    });
  }

  void _updatePresetsAndDetails() {
    final presetsForType =
        _temperaturePresets[_selectedTemp]?[_selectedType] ?? [];
    if (presetsForType.isNotEmpty) {
      _selectedPreset = presetsForType[1]; // default to middle preset
      _caloriesController.text = _selectedPreset.toString();
    }
    if (_selectedType == 'beverages') {
      _detailsController.text = '';
      _caloriesController.text = '';
    } else {
      _detailsController.text =
          _defaultDetails[_selectedTemp]?[_selectedType] ?? '';
    }
  }

  Future<void> _saveDrinksData() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    final calories = double.tryParse(_caloriesController.text) ?? 0.0;
    final details = _detailsController.text.trim().isNotEmpty
        ? _detailsController.text.trim()
        : (_defaultDetails[_selectedTemp]?[_selectedType] ?? 'Warm Sip');

    setState(() => _saving = true);
    try {
      final existing = widget.vital;
      final recordedCount = existing?.data?['count'];
      final count = recordedCount is num && recordedCount > 0
          ? recordedCount.round()
          : 1;
      final userId = widget.userId?.trim().isNotEmpty == true
          ? widget.userId!.trim()
          : MainController.instance.userId;

      // Same shape Allomom's drink logs write (kcal in the value, cups in
      // data['count']), plus AlloConnect's temperature and drink type.
      final result = await HealthVitalsController.instance.addVitalEntry(
        key: 'drinks',
        value: calories,
        unit: 'kcal',
        createdAt: existing?.createdAt ?? DateTime.now(),
        userId: userId,
        data: {
          'details': details,
          'type': 'drinks',
          'drink': drinkNameOf(_selectedType),
          'drink_type': _selectedType,
          'temperature': _selectedTemp,
          'count': count,
          'count_unit': 'cups',
        },
      );

      if (result != null && existing != null) {
        // No in-place update in Allomom: re-logged at the original time, then
        // the old row is soft-deleted (which syncs).
        await VitalsSqLiteService().deleteVital(existing.id);
        await HealthVitalsController.instance.fetchLatestVitals(
          showLoading: false,
        );
      }

      if (!mounted) return;
      if (result != null) {
        _toast(
          existing != null
              ? 'Drink updated successfully'
              : 'Drink tracked successfully',
        );
        Navigator.of(context).pop(true);
      } else {
        _toast(
          HealthVitalsController.instance.error.isNotEmpty
              ? HealthVitalsController.instance.error
              : 'Error saving drink log',
        );
      }
    } catch (e) {
      if (mounted) _toast('Error saving drink log');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final drinksColor = _selectedTemp == 'hot'
        ? Colors.amber.shade800
        : Colors.blue.shade600;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2433) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.shade700
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: drinksColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _selectedTemp == 'hot'
                            ? Icons.coffee_rounded
                            : Icons.ac_unit_rounded,
                        color: drinksColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      widget.vital != null ? 'Edit Drink' : 'Hot & Cold Drinks',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Temperature Selector Segment
                _sectionLabel('Select Temperature', isDark),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      _buildTempSegmentButton(
                        temp: 'hot',
                        label: 'Hot Drink',
                        icon: Icons.wb_sunny_rounded,
                        activeColor: Colors.amber.shade800,
                        isDark: isDark,
                      ),
                      _buildTempSegmentButton(
                        temp: 'cold',
                        label: 'Cold Drink',
                        icon: Icons.ac_unit_rounded,
                        activeColor: Colors.blue.shade600,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Visual Type Selector Cards
                _sectionLabel('Select Drink Type', isDark),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (_selectedTemp == 'hot') ...[
                      _buildTypeCard(
                        type: 'tea',
                        label: 'Tea',
                        icon: Icons.emoji_food_beverage_rounded,
                        activeColor: Colors.teal.shade600,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildTypeCard(
                        type: 'coffee',
                        label: 'Coffee',
                        icon: Icons.coffee_rounded,
                        activeColor: Colors.amber.shade900,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildTypeCard(
                        type: 'beverages',
                        label: 'Other',
                        icon: Icons.local_drink_rounded,
                        activeColor: Colors.orange.shade700,
                        isDark: isDark,
                      ),
                    ] else ...[
                      _buildTypeCard(
                        type: 'coffee',
                        label: 'Coffee',
                        icon: Icons.coffee_rounded,
                        activeColor: Colors.blue.shade800,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildTypeCard(
                        type: 'beverages',
                        label: 'Other',
                        icon: Icons.local_bar_rounded,
                        activeColor: Colors.indigo.shade600,
                        isDark: isDark,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),

                // Drink Details
                _sectionLabel('Drink Details', isDark),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _detailsController,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: _selectedType == 'tea'
                        ? 'e.g. Ginger Chai, Green Tea'
                        : _selectedType == 'coffee'
                        ? 'e.g. Espresso, Latte, Cappuccino'
                        : 'e.g. Lemonade, Fresh Juice, Shake',
                    hintStyle: TextStyle(
                      color: isDark
                          ? Colors.grey.shade600
                          : Colors.grey.shade400,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                    prefixIcon: Icon(
                      Icons.edit_note_rounded,
                      color: drinksColor,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Bottom action area ──────────────────────────────────
                if (_selectedType != 'beverages') ...[
                  // TEA / COFFEE: presets + calorie input
                  _buildPresetSection(isDark, drinksColor),
                  const SizedBox(height: 24),
                ],
                _buildCalorieInput(isDark, drinksColor),
                const SizedBox(height: 32),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
      ),
    );
  }

  // ── Helper: Calorie preset chips (Tea / Coffee) ────────────────────────────
  Widget _buildPresetSection(bool isDark, Color drinksColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Calorie Presets', isDark),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: (_temperaturePresets[_selectedTemp]?[_selectedType] ?? [])
              .map((preset) {
                final isSelected = _selectedPreset == preset;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPreset = preset;
                        _caloriesController.text = preset.toString();
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? drinksColor
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.grey.shade100),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? drinksColor : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$preset kcal',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              })
              .toList(),
        ),
      ],
    );
  }

  // ── Helper: Calorie text input ──────────────────────────────────────────────
  Widget _buildCalorieInput(bool isDark, Color drinksColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Calories (kcal)', isDark),
        const SizedBox(height: 8),
        TextFormField(
          controller: _caloriesController,
          keyboardType: TextInputType.number,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          onChanged: (value) {
            final parsed = int.tryParse(value);
            setState(() {
              if (parsed != null &&
                  (_temperaturePresets[_selectedTemp]?[_selectedType] ?? [])
                      .contains(parsed)) {
                _selectedPreset = parsed;
              } else {
                _selectedPreset = -1;
              }
            });
          },
          decoration: InputDecoration(
            hintText: 'e.g. 80',
            hintStyle: TextStyle(
              color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
            prefixIcon: Icon(Icons.bolt_rounded, color: drinksColor, size: 20),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter calories';
            }
            final parsed = double.tryParse(value);
            if (parsed == null || parsed < 0) {
              return 'Please enter a valid non-negative number';
            }
            return null;
          },
        ),
      ],
    );
  }

  // ── Helper: Save / Update button ────────────────────────────────────────────
  Widget _buildSaveButton() {
    final primary = Theme.of(context).primaryColor;
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _saving ? null : _saveDrinksData,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          disabledBackgroundColor: primary.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
        ),
        child: _saving
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                widget.vital != null ? 'Update Drink' : 'Log Drink',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildTempSegmentButton({
    required String temp,
    required String label,
    required IconData icon,
    required Color activeColor,
    required bool isDark,
  }) {
    final isSelected = _selectedTemp == temp;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTempSelected(temp),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white60 : Colors.black54),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeCard({
    required String type,
    required String label,
    required IconData icon,
    required Color activeColor,
    required bool isDark,
  }) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTypeSelected(type),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor
                : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? activeColor : Colors.transparent,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white54 : Colors.black54),
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
