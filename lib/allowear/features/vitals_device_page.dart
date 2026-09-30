import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:allomom/allowear/compat/user_api.dart';
import 'package:allomom/services/sq_lite/services/vitals_sqlite_service.dart';
import 'package:allomom/services/health_vital_sync_service.dart';
import 'package:get/get.dart';
import 'dart:convert';

class VitalsDevicePage extends StatefulWidget {
  const VitalsDevicePage({super.key});

  @override
  State<VitalsDevicePage> createState() => _VitalsDevicePageState();
}

class _VitalsDevicePageState extends State<VitalsDevicePage> {
  late VitalsSqLiteService _vitalsService;
  List<Map<String, dynamic>> _allVitals = [];
  bool _isLoading = true;
  String _selectedVitalType = 'all'; // Filter by vital type
  Map<String, int> _syncStatusCounts = {};

  @override
  void initState() {
    super.initState();
    _vitalsService = VitalsSqLiteService();
    _loadVitals();
  }

  Future<void> _loadVitals() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = Userapi.getUserID();
      if (userId == null || userId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
        return;
      }

      // Get all vitals for this user
      final allVitals = await _vitalsService.getAllVitalsForUser(userId);

      setState(() {
        _allVitals = allVitals;
        _calculateSyncCounts();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading vitals: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading vitals: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _calculateSyncCounts() {
    _syncStatusCounts = {
      'synced': _allVitals.where((v) => (v['synced'] as int) == 1).length,
      'unsynced': _allVitals.where((v) => (v['synced'] as int) == 0).length,
    };
  }

  List<Map<String, dynamic>> _getFilteredVitals() {
    if (_selectedVitalType == 'all') {
      return _allVitals;
    } else if (_selectedVitalType == 'synced') {
      return _allVitals.where((v) => (v['synced'] as int) == 1).toList();
    } else if (_selectedVitalType == 'unsynced') {
      return _allVitals.where((v) => (v['synced'] as int) == 0).toList();
    }
    return _allVitals.where((v) => v['vital_key'] == _selectedVitalType).toList();
  }

  List<String> _getUniqueVitalTypes() {
    return _allVitals
        .map((v) => v['vital_key'] as String)
        .toSet()
        .toList();
  }

  Future<void> _deleteVital(String id) async {
    try {
      await _vitalsService.deleteVital(id);
      _loadVitals();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vital record deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting vital: $e')),
      );
    }
  }

  void _showVitalDetails(Map<String, dynamic> vital) {
    final additionalData = vital['data'] != null
        ? jsonDecode(vital['data'] as String) as Map<String, dynamic>
        : <String, dynamic>{};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
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
                    Text(
                      'Vital Details',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildDetailRow('Type', vital['vital_key'] ?? 'N/A'),
                    _buildDetailRow('Value', '${vital['value']} ${vital['unit']}'),
                    _buildDetailRow(
                      'Timestamp',
                      DateFormat('MMM dd, yyyy hh:mm a').format(
                        vital['createdAt'],
                      ),
                    ),
                    _buildDetailRow(
                      'Sync Status',
                      (vital['synced'] as int) == 1 ? 'Synced ✓' : 'Not Synced ✗',
                      valueColor: (vital['synced'] as int) == 1
                          ? Colors.green
                          : Colors.orange,
                    ),
                    _buildDetailRow('User ID', vital['user_id'] ?? 'N/A'),
                    if (additionalData.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Additional Data',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          JsonEncoder.withIndent('  ').convert(additionalData),
                          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _deleteVital(vital['id'] as String);
                        },
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredVitals = _getFilteredVitals();
    final uniqueTypes = _getUniqueVitalTypes();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Vitals'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            tooltip: 'Sync Unsynced Vitals',
            onPressed: () async {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator()),
              );
              await Get.find<HealthVitalSyncService>().syncUnsyncedVitals();
              if (mounted) {
                Navigator.pop(context); // Close loading dialog
                _loadVitals(); // Refresh UI
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Synchronization complete')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVitals,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Stats Cards
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Total',
                          count: _allVitals.length,
                          icon: Icons.medical_information,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Synced',
                          count: _syncStatusCounts['synced'] ?? 0,
                          icon: Icons.cloud_done,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Pending',
                          count: _syncStatusCounts['unsynced'] ?? 0,
                          icon: Icons.cloud_upload,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                // Filter Chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All', 'all'),
                        _buildFilterChip('Synced', 'synced'),
                        _buildFilterChip('Unsynced', 'unsynced'),
                        ...uniqueTypes.map((type) => _buildFilterChip(type, type)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Vitals List
                Expanded(
                  child: filteredVitals.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox,
                                size: 64,
                                color: Colors.grey[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No vitals to display',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadVitals,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredVitals.length,
                            itemBuilder: (context, index) {
                              final vital = filteredVitals[index];
                              final isSynced = (vital['synced'] as int) == 1;
                              final timestamp = vital['createdAt'];
                              final timeStr = DateFormat('MMM dd · hh:mm a')
                                  .format(timestamp);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: isSynced
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      isSynced ? Icons.check_circle : Icons.pending,
                                      color: isSynced ? Colors.green : Colors.orange,
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${vital['vital_key']} · ${vital['value']} ${vital['unit']}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSynced
                                              ? Colors.green.withOpacity(0.1)
                                              : Colors.orange.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          isSynced ? 'Synced' : 'Pending',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: isSynced
                                                ? Colors.green
                                                : Colors.orange,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      timeStr,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  onTap: () => _showVitalDetails(vital),
                                  trailing: PopupMenuButton(
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        child: const Text('View Details'),
                                        onTap: () => _showVitalDetails(vital),
                                      ),
                                      PopupMenuItem(
                                        child: const Text('Delete'),
                                        onTap: () =>
                                            _deleteVital(vital['id'] as String),
                                      ),
                                    ],
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

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String filterValue) {
    final isSelected = _selectedVitalType == filterValue;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedVitalType = selected ? filterValue : 'all';
          });
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Theme.of(context).primaryColor,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
