import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import 'package:allomom/allowear/device_raw_vitals_storage.dart';
import 'package:allomom/models/vital_sync_item.dart';

class DeviceRawVitalsPage extends StatefulWidget {
  const DeviceRawVitalsPage({super.key});

  @override
  State<DeviceRawVitalsPage> createState() => _DeviceRawVitalsPageState();
}

class _DeviceRawVitalsPageState extends State<DeviceRawVitalsPage> {
  List<VitalSyncItem> _allVitals = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // 'all', 'heart_rate', 'blood_oxygen', 'hrv', 'stress'
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRawVitals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRawVitals() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final vitals = await DeviceRawVitalsStorage.getRawVitals();
      setState(() {
        _allVitals = vitals;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading device raw vitals: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading device raw vitals: $e'.tr)),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteVital(VitalSyncItem vital) async {
    try {
      await DeviceRawVitalsStorage.deleteRawVital(vital.id);
      setState(() {
        _allVitals.removeWhere((item) => item.id == vital.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed ${vital.key.tr} record'.tr),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting vital: $e'.tr)),
        );
      }
    }
  }

  Future<void> _clearAllVitals() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All Device Raw Vitals'.tr),
        content: Text(
            'Are you sure you want to permanently clear all stored raw vitals? This cannot be undone.'
                .tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Clear All'.tr),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await DeviceRawVitalsStorage.clearRawVitals();
        setState(() {
          _allVitals = [];
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('All device raw vitals cleared'.tr),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error clearing raw vitals: $e'.tr)),
          );
        }
      }
    }
  }

  List<VitalSyncItem> _getFilteredVitals() {
    return _allVitals.where((vital) {
      final matchesFilter =
          _selectedFilter == 'all' || vital.key == _selectedFilter;
      final matchesSearch = _searchQuery.isEmpty ||
          vital.key.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          vital.value.toString().contains(_searchQuery) ||
          (vital.createdAt != null &&
              DateFormat('MMM dd, yyyy hh:mm a')
                  .format(vital.createdAt!)
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()));
      return matchesFilter && matchesSearch;
    }).toList();
  }

  Map<String, int> _getSplitCounts() {
    final counts = <String, int>{
      'heart_rate': 0,
      'blood_oxygen': 0,
      'hrv': 0,
      'stress': 0,
      'steps': 0,
      'sleep_data': 0,
    };
    for (final vital in _allVitals) {
      if (counts.containsKey(vital.key)) {
        counts[vital.key] = counts[vital.key]! + 1;
      } else {
        counts[vital.key] = 1;
      }
    }
    return counts;
  }

  IconData _getIconForVital(String key) {
    switch (key) {
      case 'heart_rate':
        return Icons.favorite_rounded;
      case 'blood_oxygen':
        return Icons.opacity_rounded;
      case 'hrv':
        return Icons.electric_bolt_rounded;
      case 'stress':
        return Icons.psychology_rounded;
      case 'steps':
        return Icons.directions_walk_rounded;
      case 'sleep_data':
        return Icons.bedtime_rounded;
      default:
        return Icons.sensors_rounded;
    }
  }

  Color _getColorForVital(String key) {
    switch (key) {
      case 'heart_rate':
        return Colors.redAccent;
      case 'blood_oxygen':
        return Colors.blueAccent;
      case 'hrv':
        return Colors.purpleAccent;
      case 'stress':
        return Colors.orangeAccent;
      case 'steps':
        return Colors.greenAccent;
      case 'sleep_data':
        return Colors.indigoAccent;
      default:
        return Colors.tealAccent;
    }
  }

  String _getDisplayNameForVital(String key) {
    switch (key) {
      case 'heart_rate':
        return 'Heart Rate';
      case 'blood_oxygen':
        return 'Blood Oxygen';
      case 'hrv':
        return 'HRV';
      case 'stress':
        return 'Stress';
      case 'steps':
        return 'Steps';
      case 'sleep_data':
        return 'Sleep';
      default:
        return key.capitalizeFirst ?? key;
    }
  }

  void _showVitalDetails(VitalSyncItem vital) {
    final primaryColor = Theme.of(context).primaryColor;
    final jsonStr = JsonEncoder.withIndent('  ').convert(vital.toJson());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 10,
                spreadRadius: 5,
              )
            ],
          ),
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            maxChildSize: 0.9,
            minChildSize: 0.4,
            builder: (context, scrollController) {
              return SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: _getColorForVital(vital.key)
                                  .withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _getIconForVital(vital.key),
                              color: _getColorForVital(vital.key),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getDisplayNameForVital(vital.key),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Device Raw Vital Record'.tr,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      _buildDetailRow('Record ID', vital.id),
                      _buildDetailRow('Key', vital.key),
                      _buildDetailRow('Value', '${vital.value} ${vital.unit}'),
                      _buildDetailRow(
                        'Timestamp',
                        vital.createdAt != null
                            ? DateFormat('MMMM dd, yyyy hh:mm:ss a')
                                .format(vital.createdAt!)
                            : 'N/A',
                      ),
                      if (vital.data != null && vital.data!.isNotEmpty)
                        _buildDetailRow('Metadata', jsonEncode(vital.data)),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Raw JSON Data'.tr,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: jsonStr));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Copied raw data to clipboard'.tr),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy, size: 16),
                            label: Text('Copy'.tr),
                            style: TextButton.styleFrom(
                              foregroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[900]
                              : Colors.grey[100],
                          border: Border.all(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.grey[800]!
                                    : Colors.grey[300]!,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          jsonStr,
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _deleteVital(vital);
                              },
                              icon: const Icon(Icons.delete_forever),
                              label: Text('Delete Record'.tr),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label.tr,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredVitals = _getFilteredVitals();
    final counts = _getSplitCounts();

    return Scaffold(
      appBar: AppBar(
        title: Text('Device Raw Vitals'.tr),
        elevation: 0,
        actions: [
          if (_allVitals.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded),
              tooltip: 'Clear All'.tr,
              onPressed: _clearAllVitals,
            ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh'.tr,
            onPressed: _loadRawVitals,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Stats Card Panel
                _buildStatsPanel(counts),

                // Search & Filter Panel
                _buildFilterAndSearchPanel(counts),

                // Vitals List
                Expanded(
                  child: filteredVitals.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadRawVitals,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredVitals.length,
                            itemBuilder: (context, index) {
                              final vital = filteredVitals[index];
                              final color = _getColorForVital(vital.key);
                              final icon = _getIconForVital(vital.key);
                              final displayName =
                                  _getDisplayNameForVital(vital.key);
                              final timeStr = vital.createdAt != null
                                  ? DateFormat('MMM dd, yyyy · hh:mm a')
                                      .format(vital.createdAt!)
                                  : 'N/A';

                              return Dismissible(
                                key: Key(vital.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20.0),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                onDismissed: (direction) {
                                  _deleteVital(vital);
                                },
                                child: Card(
                                  elevation: 0,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: theme.brightness == Brightness.dark
                                          ? Colors.grey[800]!
                                          : Colors.grey[200]!,
                                      width: 1,
                                    ),
                                  ),
                                  color: theme.brightness == Brightness.dark
                                      ? Colors.grey[900]?.withOpacity(0.5)
                                      : Colors.white,
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(icon, color: color, size: 24),
                                    ),
                                    title: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          displayName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(
                                          '${vital.value} ${vital.unit}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: color,
                                          ),
                                        ),
                                      ],
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            timeStr,
                                            style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 12,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: theme.primaryColor
                                                  .withOpacity(0.12),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'Raw Device'.tr,
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: theme.primaryColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    onTap: () => _showVitalDetails(vital),
                                    trailing: const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatsPanel(Map<String, int> counts) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: theme.brightness == Brightness.dark
              ? [
                  Colors.teal.withOpacity(0.2),
                  theme.primaryColor.withOpacity(0.1),
                ]
              : [theme.primaryColor.withOpacity(0.08), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? theme.primaryColor.withOpacity(0.2)
              : theme.primaryColor.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Device Raw Buffer'.tr,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[500],
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${_allVitals.length}',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: theme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'records'.tr,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.sensors_rounded,
                  color: theme.primaryColor,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1),
          const SizedBox(height: 16),
          // Split Breakdown Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniBreakdown(
                  'HR', counts['heart_rate'] ?? 0, Colors.redAccent),
              _buildMiniBreakdown(
                  'O2', counts['blood_oxygen'] ?? 0, Colors.blueAccent),
              _buildMiniBreakdown(
                  'HRV', counts['hrv'] ?? 0, Colors.purpleAccent),
              _buildMiniBreakdown(
                  'Stress', counts['stress'] ?? 0, Colors.orangeAccent),
              _buildMiniBreakdown(
                  'Steps', counts['steps'] ?? 0, Colors.greenAccent),
              _buildMiniBreakdown(
                  'Sleep', counts['sleep_data'] ?? 0, Colors.indigoAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBreakdown(String label, int val, Color color) {
    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$val',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label.tr,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[500],
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterAndSearchPanel(Map<String, int> counts) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search by value or date...'.tr,
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[950]
                  : Colors.grey[100],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Filter chips list
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildFilterChip('All'.tr, 'all', _allVitals.length),
              _buildFilterChip(
                  'Heart Rate'.tr, 'heart_rate', counts['heart_rate'] ?? 0),
              _buildFilterChip('Blood Oxygen'.tr, 'blood_oxygen',
                  counts['blood_oxygen'] ?? 0),
              _buildFilterChip('HRV'.tr, 'hrv', counts['hrv'] ?? 0),
              _buildFilterChip('Stress'.tr, 'stress', counts['stress'] ?? 0),
              _buildFilterChip('Steps'.tr, 'steps', counts['steps'] ?? 0),
              _buildFilterChip('Sleep'.tr, 'sleep_data', counts['sleep_data'] ?? 0),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFilterChip(String label, String key, int count) {
    final isSelected = _selectedFilter == key;
    final theme = Theme.of(context);
    final chipColor = _getColorForVital(key);

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = key;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (key == 'all' ? theme.primaryColor : chipColor)
                : (theme.brightness == Brightness.dark
                    ? Colors.grey[950]
                    : Colors.grey[100]),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : (theme.brightness == Brightness.dark
                      ? Colors.grey[900]!
                      : Colors.grey[300]!),
            ),
          ),
          child: Row(
            children: [
              if (key != 'all') ...[
                Icon(
                  _getIconForVital(key),
                  size: 14,
                  color: isSelected ? Colors.white : chipColor,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : theme.textTheme.bodyMedium?.color,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.2)
                      : (theme.brightness == Brightness.dark
                          ? Colors.grey[900]
                          : Colors.grey[300]),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : theme.textTheme.bodySmall?.color,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.sensors_off_rounded,
                size: 64,
                color: Colors.blueGrey,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Device Raw Vitals'.tr,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Raw sensor readings will appear here whenever health data is collected from the device prior to verification.'
                  .tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
